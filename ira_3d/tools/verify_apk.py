"""Reject a mislabeled IRA 2D APK in the IRA 3D Android workflow."""
from pathlib import Path
import sys
import zipfile

apk = Path(sys.argv[1])
if not apk.is_file() or apk.stat().st_size < 1_000_000:
    raise SystemExit("FAIL: Android APK absent or suspiciously small")
with zipfile.ZipFile(apk) as archive:
    paths = set(archive.namelist())
    required = {"assets/scripts/Main.gdc", "assets/scripts/Hero.gdc", "assets/scripts/FollowCamera.gdc", "assets/scripts/RuinedDistrict.gdc", "assets/scripts/TouchHUD.gdc"}
    missing = required - paths
    if missing:
        raise SystemExit("FAIL: 3D scripts missing: " + str(sorted(missing)))
    if "assets/scripts/Game.gdc" in paths or "assets/scripts/SaveSystem.gdc" in paths:
        raise SystemExit("FAIL: 2D game script found inside 3D APK")
    manifest = archive.read("AndroidManifest.xml")
    if "com.lsnoglos.ira3d".encode("utf-16le") not in manifest:
        raise SystemExit("FAIL: incorrect Android package (expected com.lsnoglos.ira3d)")
    icon_entries = [p for p in paths if p.startswith("res/mipmap") and p.endswith(".png")]
    if not icon_entries:
        raise SystemExit("FAIL: no Android launcher icons found")
    if archive.testzip() is not None:
        raise SystemExit("FAIL: corrupt archive")
print("PASS: 3D scripts, distinct Android package and launcher icons verified:", apk.name)
