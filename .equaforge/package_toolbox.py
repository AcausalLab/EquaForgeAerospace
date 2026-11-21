#!/usr/bin/env python3
"""Package a library folder without build output, private data, or unlisted files."""
import argparse
import json
from pathlib import Path
import zipfile


def package_toolbox(folder, output, *, release=False):
    root = Path(folder).resolve()
    metadata = json.loads((root / "library.json").read_text(encoding="utf-8"))
    if metadata.get("private"):
        raise ValueError("Private/local library folders cannot be packaged by this command")
    if metadata.get("schemaVersion") != 1 or metadata.get("id") != root.name:
        raise ValueError("Expected a schemaVersion 1 manifest whose id matches the folder")
    if not (root / "package.mo").is_file():
        raise ValueError("Missing package.mo")
    if release and metadata.get("license") in (None, "", "NOASSERTION"):
        raise ValueError("Settle and document the package license before a public release")
    entries = metadata.get("distributionFiles", [])
    if not entries:
        raise ValueError("The manifest must explicitly list distributionFiles")
    files = set()
    for entry in entries:
        path = root / entry
        if Path(entry).is_absolute() or not path.resolve().is_relative_to(root):
            raise ValueError("distributionFiles must stay inside the library")
        if not path.exists():
            raise ValueError(f"Missing distribution entry: {entry}")
        for item in ([path] if path.is_file() else path.rglob("*")):
            if not item.resolve().is_relative_to(root):
                raise ValueError("A package symlink escapes its library folder")
            if item.is_file():
                relative = item.relative_to(root)
                if any(p.startswith(".") or p in ("__pycache__", "local", "original")
                       for p in relative.parts):
                    continue
                if item.name.startswith("winding_case2") or item.name == "winding_scope.csv":
                    raise ValueError("Recorded machine data belongs in the private validation pack")
                if item.suffix in (".pyc", ".bak", ".fmu", ".exe", ".dll"):
                    continue
                files.add(item)
    if root / "library.json" not in files or root / "package.mo" not in files:
        raise ValueError("distributionFiles must include library.json and package.mo")
    output = Path(output).resolve()
    if output.is_relative_to(root):
        raise ValueError("Write archives outside the source library")
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for file in sorted(files):
            info = zipfile.ZipInfo((Path(root.name) / file.relative_to(root)).as_posix(),
                                   date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, file.read_bytes())
    return {"verdict": "PASSED", "archive": str(output), "files": len(files),
            "id": metadata["id"], "version": metadata["version"],
            "license": metadata.get("license"), "release": release}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--release", action="store_true", help="require settled licensing metadata")
    args = parser.parse_args()
    try:
        print(json.dumps(package_toolbox(args.folder, args.output, release=args.release), indent=2))
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        parser.exit(1, f"Toolbox packaging failed: {error}\n")


if __name__ == "__main__":
    main()
