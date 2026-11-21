#!/usr/bin/env python3
"""Build standalone toolbox CI artifacts, or create an explicitly requested draft."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from urllib.error import HTTPError
from urllib.parse import urljoin, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

from build_toolbox_release import build_release, validate_catalog, version


def repository_name(value):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9_.-]{1,100}", value) or value.split("/")[-1] in (".", ".."):
        raise ValueError("Use a GitHub owner/repository name")
    return value


def manifest(folder):
    path = Path(folder) / "library.json"
    if path.stat().st_size > 1024 * 1024:
        raise ValueError("Manifest exceeds 1 MiB")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or ("private" in data and data["private"] is not False):
        raise ValueError("Private libraries cannot use public publishing workflows")
    identifier = data.get("id")
    if not isinstance(identifier, str) or len(identifier) > 128 or not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", identifier) or identifier == "EquaForgeVC":
        raise ValueError("Invalid or reserved package id")
    if type(data.get("schemaVersion")) is not int or data["schemaVersion"] != 1 or not (Path(folder) / "package.mo").is_file():
        raise ValueError("Expected a schemaVersion 1 toolbox with package.mo")
    version(data.get("version"))
    version(data.get("minAppVersion"))
    return data


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError("GitHub API redirects are not accepted; use the repository's current name")


class PublicRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        target = urlsplit(newurl)
        if target.scheme != "https" or target.username or target.password:
            raise ValueError("Public catalog redirects must use HTTPS without credentials")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def previous_catalog(repository, *, token="", api_open=None, asset_open=None):
    """Return the last public feed; only a confirmed first release returns None."""
    repository = repository_name(repository)
    api_open = api_open or build_opener(NoRedirect()).open
    asset_open = asset_open or build_opener(PublicRedirect()).open

    def api(path):
        headers = {"Accept": "application/vnd.github+json", "User-Agent": "EquaForge-toolbox-publishing"}
        if token:
            headers["Authorization"] = "Bearer " + token
        with api_open(Request("https://api.github.com/repos/" + repository + path, headers=headers), timeout=30) as response:
            raw = response.read(2 * 1024 * 1024 + 1)
        if len(raw) > 2 * 1024 * 1024:
            raise ValueError("GitHub metadata exceeds its limit")
        return json.loads(raw)

    info = api("")
    if not isinstance(info, dict) or info.get("private") is not False:
        raise ValueError("Public toolbox workflows require a public GitHub repository")
    try:
        latest = api("/releases/latest")
    except HTTPError as error:
        if error.code == 404:
            return None
        raise
    if not isinstance(latest, dict) or latest.get("draft") is not False or latest.get("prerelease") is not False:
        raise ValueError("Expected a published stable release")
    assets = latest.get("assets", [])
    if not isinstance(assets, list):
        raise ValueError("Invalid GitHub release assets")
    matches = [a for a in assets if isinstance(a, dict) and a.get("name") == "toolboxes.json"]
    if len(matches) != 1:
        raise ValueError("The latest release has no unique toolboxes.json; migrate its catalog before releasing")
    url = matches[0].get("browser_download_url", "")
    if not isinstance(url, str) or not url.startswith("https://github.com/" + repository + "/releases/download/"):
        raise ValueError("Unexpected catalog asset URL")
    # Published public assets need no authorization header, including on CDN redirects.
    with asset_open(Request(url, headers={"User-Agent": "EquaForge-toolbox-publishing"}), timeout=30) as response:
        raw = response.read(2 * 1024 * 1024 + 1)
    if len(raw) > 2 * 1024 * 1024:
        raise ValueError("Published catalog exceeds 2 MiB")
    document = json.loads(raw)
    validate_catalog(document, False)
    # Keep older relative URLs bound to the original release when moving the feed.
    for package in document["packages"]:
        for release in package["releases"]:
            release["url"] = urljoin(url, release["url"])
    validate_catalog(document, False)
    return json.dumps(document).encode("utf-8")


def prepare(folder, output, repository, *, release_tag="", fetch_previous=False, previous=None):
    folder, output = Path(folder).resolve(), Path(output).resolve()
    data = manifest(folder)
    repository = repository_name(repository)
    if release_tag and release_tag != "v" + data["version"]:
        raise ValueError("The release tag must exactly match v + the manifest version")
    if fetch_previous and not release_tag:
        raise ValueError("Fetching the published catalog requires an explicit release tag")
    if release_tag and data.get("license") in (None, "", "NOASSERTION"):
        raise ValueError("Settle the license before creating a release draft")
    if output.is_relative_to(folder):
        raise ValueError("Keep CI artifacts outside the toolbox source")
    if fetch_previous:
        previous = previous_catalog(repository, token=os.environ.get("GH_TOKEN", ""))
    if previous is not None:
        if len(previous) > 2 * 1024 * 1024:
            raise ValueError("Previous catalog exceeds 2 MiB")
        validate_catalog(json.loads(previous), not bool(release_tag))
    output.mkdir(parents=True, exist_ok=True)
    catalog = output / "toolboxes.json"
    if previous is not None:
        if catalog.exists() and catalog.read_bytes() != previous:
            raise ValueError("Use a fresh output folder when importing a previous catalog")
        catalog.write_bytes(previous)
    result = build_release(folder, output, repository="https://github.com/" + repository,
                           development=not bool(release_tag))
    metadata = {"id": result["id"], "version": result["version"], "tag": release_tag,
                "sha256": result["sha256"], "repository": repository,
                "archive": Path(result["archive"]).name, "development": result["development"]}
    (output / "release.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return result


def draft_command(folder, output, repository, release_tag):
    """Validate downloaded artifacts and return argv; never execute a shell."""
    data = manifest(folder)
    repository = repository_name(repository)
    if release_tag != "v" + data["version"] or data.get("license") in (None, "", "NOASSERTION"):
        raise ValueError("Draft creation requires a matching version tag and settled license")
    output = Path(output)
    if (output / "release.json").stat().st_size > 1024 * 1024:
        raise ValueError("Release metadata exceeds 1 MiB")
    record = json.loads((output / "release.json").read_text(encoding="utf-8"))
    filename = data["id"] + "-" + data["version"] + ".zip"
    if not isinstance(record, dict) or record.get("development") is not False or any(record.get(k) != v for k, v in
        {"id": data["id"], "version": data["version"], "tag": release_tag, "repository": repository, "archive": filename}.items()):
        raise ValueError("Release artifacts do not match the selected toolbox, repository and tag")
    archive = output / filename
    if archive.stat().st_size > 64 * 1024 * 1024:
        raise ValueError("Archive exceeds 64 MiB")
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    catalog = output / "toolboxes.json"
    if catalog.stat().st_size > 2 * 1024 * 1024:
        raise ValueError("Catalog exceeds 2 MiB")
    document = json.loads(catalog.read_text(encoding="utf-8"))
    validate_catalog(document, False)
    releases = [r for p in document["packages"] if p["id"] == data["id"] for r in p["releases"] if r["version"] == data["version"]]
    expected_url = f"https://github.com/{repository}/releases/download/{release_tag}/{filename}"
    if record.get("sha256") != digest or len(releases) != 1 or releases[0]["sha256"] != digest or releases[0]["url"] != expected_url:
        raise ValueError("Release artifacts failed the digest/catalog checks")
    return ["gh", "release", "create", release_tag, str(archive), str(catalog), "--repo", repository,
            "--draft", "--verify-tag", "--title", data["id"] + " " + data["version"],
            "--notes", "Toolbox ZIP and versioned catalog. Review the package license and contents before publishing."]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--repository", required=True, help="GitHub owner/repository")
    parser.add_argument("--release-tag", default="")
    parser.add_argument("--fetch-previous", action="store_true")
    parser.add_argument("--create-draft", action="store_true", help="Explicitly create an unpublished GitHub draft from verified artifacts")
    args = parser.parse_args()
    try:
        if args.create_draft:
            subprocess.run(draft_command(args.folder, args.output_dir, args.repository, args.release_tag), check=True)
        else:
            print(json.dumps(prepare(args.folder, args.output_dir, args.repository, release_tag=args.release_tag,
                                     fetch_previous=args.fetch_previous), indent=2))
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Toolbox CI failed: {error}\n")


if __name__ == "__main__":
    main()
