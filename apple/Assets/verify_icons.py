#!/usr/bin/env python3
"""Verify AppIcon PNG pixel sizes against AppIcon.appiconset/Contents.json.

Usage: python3 verify_icons.py [--set Media.xcassets/AppIcon.appiconset]
Exit 0 = every declared size matches the file on disk.
Honesty note: the master artwork is 512x512 (docs/images/logo-512.png), so
every PNG above 512 px (512@2x = 1024 and the 1024 marketing icon) is a
Lanczos upscale - correct dimensions, not extra detail. See README.md.
"""
import json, sys
from pathlib import Path
from PIL import Image

s = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent / "Media.xcassets/AppIcon.appiconset")
contents = json.loads((s / "Contents.json").read_text())
bad = 0
for img in contents["images"]:
    pts = float(img["size"].split("x")[0]); scale = int(img["scale"].rstrip("x"))
    want = round(pts * scale)
    f = s / img["filename"]
    got = Image.open(f).size if f.exists() else None
    ok = got == (want, want)
    upscale = "  <- UPSCALED from 512 master (no extra detail)" if want > 512 else ""
    print(f"{'OK ' if ok else 'BAD'} {img['filename']}: declared {want}x{want}, actual {got}{upscale}")
    bad += 0 if ok else 1
print(f"RESULT: {len(contents['images'])} icons, {bad} mismatch(es)")
raise SystemExit(1 if bad else 0)
