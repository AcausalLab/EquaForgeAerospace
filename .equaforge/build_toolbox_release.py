#!/usr/bin/env python3
"""Build a toolbox ZIP and static catalog entry. This command never uploads files."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
from urllib.parse import urlsplit, urlunsplit
import zipfile

from package_toolbox import package_toolbox


def version(value):
    if not isinstance(value, str) or not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", value):
        raise ValueError("Versions must be stable major.minor.patch numbers")
    result = tuple(map(int, value.split(".")))
    if any(v > 2**32 - 1 for v in result):
        raise ValueError("Version number exceeds the app's supported range")
    return result


def https_url(value):
    parsed = urlsplit(value)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError("Use an HTTPS URL without embedded credentials")
    return parsed


def validate_catalog(document, development):
    def public(record):
        return "private" not in record or record["private"] is False

    def text(record, key, maximum, required=True):
        value = record.get(key, "")
        return isinstance(value, str) and len(value) <= maximum and (not required or bool(value.strip()))

    if not isinstance(document, dict) or type(document.get("schemaVersion")) is not int or document["schemaVersion"] != 1 or not isinstance(document.get("packages"), list) or not public(document):
        raise ValueError("Expected a public schemaVersion 1 catalog")
    if not text(document, "name", 256, False):
        raise ValueError("Invalid catalog name")
    if len(document["packages"]) > 256:
        raise ValueError("Too many catalog packages")
    ids = set()
    count = 0
    for package in document["packages"]:
        if not isinstance(package, dict) or not public(package) or not isinstance(package.get("releases"), list) or not 1 <= len(package["releases"]) <= 128:
            raise ValueError("Invalid or private catalog package")
        identifier = package.get("id", "")
        if not isinstance(identifier, str) or len(identifier) > 128 or not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", identifier) or identifier == "EquaForgeVC" or identifier.casefold() in ids:
            raise ValueError("Invalid or duplicate catalog package id")
        if not text(package, "name", 256) or not text(package, "description", 4096, False) or not text(package, "repository", 8192, False):
            raise ValueError("Invalid catalog package metadata")
        if package.get("repository"):
            https_url(package["repository"])
        ids.add(identifier.casefold())
        seen = set()
        for release in package["releases"]:
            count += 1
            if count > 4096 or not isinstance(release, dict) or not public(release):
                raise ValueError("Invalid or private catalog release")
            version(release.get("version"))
            version(release.get("minAppVersion"))
            if release["version"] in seen or not text(release, "sha256", 64) or not re.fullmatch(r"[a-fA-F0-9]{64}", release["sha256"]):
                raise ValueError("Duplicate version or invalid catalog digest")
            seen.add(release["version"])
            if not text(release, "license", 256) or (not development and release["license"] == "NOASSERTION"):
                raise ValueError("Public catalog releases need settled licenses")
            deps = release.get("dependencies", [])
            if not isinstance(deps, list) or len(deps) > 64 or any(
                not isinstance(d, str) or len(d) > 128 or not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", d) or d == identifier for d in deps
            ) or len(set(deps)) != len(deps):
                raise ValueError("Invalid release dependencies")
            if not text(release, "url", 8192):
                raise ValueError("Invalid catalog download URL")
            asset = urlsplit(release.get("url", ""))
            local = development and ((asset.scheme == "file" and not asset.netloc and not asset.path.startswith("//")) or
                                     (asset.scheme == "http" and asset.hostname in ("localhost", "127.0.0.1", "::1")))
            if asset.username or asset.password or (asset.scheme and asset.scheme != "https" and not local) or (asset.scheme == "https" and not asset.hostname) or (not asset.scheme and asset.netloc):
                raise ValueError("Invalid catalog download URL")


def build_release(folder, output_dir, *, repository="", download_url="", catalog=None,
                  description="", catalog_name="EquaForge toolboxes", development=False):
    root, output = Path(folder).resolve(), Path(output_dir).resolve()
    if output.is_relative_to(root):
        raise ValueError("Build release files outside the source library")
    manifest_path = root / "library.json"
    if manifest_path.stat().st_size > 1024 * 1024:
        raise ValueError("Manifest exceeds 1 MiB")
    metadata = json.loads(manifest_path.read_text(encoding="utf-8"))
    if not isinstance(metadata, dict) or ("private" in metadata and metadata["private"] is not False):
        raise ValueError("Private libraries cannot be added to a public catalog")
    package_id = metadata["id"]
    if not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", package_id) or len(package_id) > 128 or package_id == "EquaForgeVC":
        raise ValueError("Invalid or reserved package id")
    release_version = metadata["version"]
    version(release_version)
    version(metadata["minAppVersion"])
    if not metadata.get("license") or len(metadata["license"]) > 256:
        raise ValueError("The manifest needs a license identifier")
    if not metadata.get("name") or len(metadata["name"]) > 256 or len(description) > 4096:
        raise ValueError("Invalid package name or description")
    if not development and metadata["license"] == "NOASSERTION":
        raise ValueError("Settle the package license before building a public catalog")
    dependencies = metadata.get("dependencies", [])
    if not isinstance(dependencies, list) or len(dependencies) > 64 or any(
        not isinstance(d, str) or not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", d) or len(d) > 128 or d == package_id
        for d in dependencies
    ) or len(set(dependencies)) != len(dependencies):
        raise ValueError("Invalid dependency list")
    if repository:
        repo = https_url(repository)
        repository = urlunsplit((repo.scheme, repo.netloc, repo.path.rstrip("/").removesuffix(".git"), "", ""))
    filename = f"{package_id}-{release_version}.zip"
    archive = output / filename
    if not download_url:
        if repository:
            download_url = f"{repository}/releases/download/v{release_version}/{filename}"
        elif development:
            download_url = archive.as_uri()
        else:
            raise ValueError("Specify --repository or --download-url for the published ZIP")
    if urlsplit(download_url).scheme == "file" and development:
        if urlsplit(download_url).netloc:
            raise ValueError("Development file URLs must be local")
    else:
        https_url(download_url)
    catalog_path = Path(catalog).resolve() if catalog else output / "toolboxes.json"
    if catalog_path == archive:
        raise ValueError("The catalog and ZIP must have different output paths")
    if catalog_path.is_relative_to(root):
        raise ValueError("Keep the catalog outside the source library")
    if catalog_path.exists():
        if catalog_path.stat().st_size > 2 * 1024 * 1024:
            raise ValueError("Existing catalog exceeds 2 MiB")
        document = json.loads(catalog_path.read_text(encoding="utf-8"))
    else:
        document = {"schemaVersion": 1, "name": catalog_name, "packages": []}
    validate_catalog(document, development)
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=output) as staging:
        temporary_zip = Path(staging) / filename
        package_toolbox(root, temporary_zip, release=not development)
        with zipfile.ZipFile(temporary_zip) as contents:
            entries = contents.infolist()
            if temporary_zip.stat().st_size > 64 * 1024**2 or len(entries) > 10000 or sum(e.file_size for e in entries) > 256 * 1024**2 or any(e.file_size > 64 * 1024**2 for e in entries):
                raise ValueError("Package exceeds the app installer's archive limits")
            if any(Path(e.filename).suffix.lower() in {".exe", ".dll", ".fmu", ".so", ".dylib", ".com", ".scr", ".msi"} for e in entries):
                raise ValueError("Native payloads are not supported by the toolbox installer")
        digest = hashlib.sha256(temporary_zip.read_bytes()).hexdigest()
        if archive.exists() and hashlib.sha256(archive.read_bytes()).hexdigest() != digest:
            raise ValueError("This release filename already has different contents; bump the version or use another output folder")
        packages = document["packages"]
        matches = [p for p in packages if p.get("id", "").casefold() == package_id.casefold()]
        if len(matches) > 1 or (matches and matches[0]["id"] != package_id):
            raise ValueError("Duplicate or case-conflicting catalog package id")
        package = matches[0] if matches else {"id": package_id, "releases": []}
        if package.get("private") or not isinstance(package.get("releases"), list):
            raise ValueError("Invalid or private existing catalog package")
        release = dict(version=release_version, minAppVersion=metadata["minAppVersion"],
                       license=metadata["license"], dependencies=dependencies,
                       url=download_url, sha256=digest)
        for existing in package["releases"]:
            if existing["version"] == release_version and existing["sha256"].lower() != digest:
                raise ValueError("The catalog already contains different bytes for this version")
        package.update(name=metadata["name"], description=description, repository=repository)
        package["releases"] = [r for r in package["releases"] if r["version"] != release_version] + [release]
        package["releases"].sort(key=lambda r: version(r["version"]), reverse=True)
        if not matches:
            packages.append(package)
        validate_catalog(document, development)
        if len(packages) > 256 or any(len(p["releases"]) > 128 for p in packages) or sum(len(p["releases"]) for p in packages) > 4096:
            raise ValueError("Catalog exceeds the app's package/release limits")
        encoded = (json.dumps(document, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
        if len(encoded) > 2 * 1024 * 1024:
            raise ValueError("Catalog exceeds 2 MiB")
        catalog_path.parent.mkdir(parents=True, exist_ok=True)
        # Do not expose a catalog entry until the complete immutable archive exists.
        os.replace(temporary_zip, archive)
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=catalog_path.parent, delete=False) as stream:
                temporary = Path(stream.name)
                stream.write(encoded)
            os.replace(temporary, catalog_path)
        finally:
            if temporary and temporary.exists():
                temporary.unlink()
    return {"verdict": "PASSED", "archive": str(archive), "catalog": str(catalog_path),
            "id": package_id, "version": release_version, "sha256": digest,
            "development": development, "uploaded": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--repository", default="", help="GitHub-compatible repository HTTPS URL")
    parser.add_argument("--download-url", default="", help="Override the stable published ZIP URL")
    parser.add_argument("--catalog", type=Path, help="Create/update this catalog; preserves older releases")
    parser.add_argument("--description", default="")
    parser.add_argument("--catalog-name", default="EquaForge toolboxes")
    parser.add_argument("--development", action="store_true", help="Allow NOASSERTION and default to local-file URLs; still excludes private packages")
    args = parser.parse_args()
    try:
        print(json.dumps(build_release(args.folder, args.output_dir, repository=args.repository,
                         download_url=args.download_url, catalog=args.catalog, description=args.description,
                         catalog_name=args.catalog_name, development=args.development), indent=2))
    except (OSError, ValueError, KeyError, TypeError, zipfile.BadZipFile) as error:
        parser.exit(1, f"Release build failed: {error}\n")


if __name__ == "__main__":
    main()
