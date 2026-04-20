#!/usr/bin/env python3
"""Extract UI test screenshot attachments from an xcresult bundle.

Usage:
    extract_screenshots.py <xcresult path> <output dir>

Uses `xcrun xcresulttool export attachments` (Xcode 16+) to dump every
attachment + a manifest.json, then renames the ones whose attachment
name starts with `NN_` (our screenshot prefix) into `NN_Name.png` in
the output directory. Other attachments are discarded.
"""

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def run(args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def export_all(xcresult: str, staging: Path) -> Path:
    run([
        "xcrun", "xcresulttool", "export", "attachments",
        "--path", xcresult,
        "--output-path", str(staging),
    ])
    manifest = staging / "manifest.json"
    if not manifest.exists():
        raise RuntimeError(f"No manifest at {manifest}")
    return manifest


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)

    xcresult = sys.argv[1]
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        staging = Path(tmp)
        manifest_path = export_all(xcresult, staging)
        manifest = json.loads(manifest_path.read_text())

        # Manifest is a list of { "testIdentifier": ..., "attachments":
        # [{ "name": ..., "exportedFileName": ... }, ...] }.
        exported = 0
        seen: set[str] = set()
        for test in manifest:
            for att in test.get("attachments", []):
                # XCTest prefixes attachment names with a UUID suffix like
                # "01_MisFortalezas_0_<uuid>.png". Strip that back to
                # "01_MisFortalezas" for a clean file on disk.
                suggested = att.get("suggestedHumanReadableName") or att.get("name") or ""
                filename = att.get("exportedFileName") or ""
                if not suggested or not filename:
                    continue
                base = suggested.rsplit(".", 1)[0]
                # Drop the "_0_<uuid>" suffix XCTest appends.
                if "_0_" in base:
                    base = base.split("_0_", 1)[0]
                if not (len(base) >= 3 and base[:2].isdigit() and base[2] == "_"):
                    continue
                if base in seen:
                    continue
                seen.add(base)
                src = staging / filename
                if not src.exists():
                    print(f"  ! missing source file: {src}", file=sys.stderr)
                    continue
                dst = out_dir / f"{base}.png"
                shutil.copyfile(src, dst)
                exported += 1
                print(f"  • {dst.name}")

    if exported == 0:
        print("No prefixed screenshots found in manifest.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
