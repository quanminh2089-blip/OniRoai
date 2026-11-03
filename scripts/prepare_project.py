#!/usr/bin/env python3
"""Merge recoverable OniRoai artwork with a GDRE-recovered Godot project.

The APK must be recovered with GDRE Tools first; this script does not
misrepresent the incomplete source archive as a complete Godot project.
"""
from pathlib import Path
from zipfile import ZipFile
import argparse
import re
import shutil
import sys


def set_project_value(text: str, section: str, key: str, value: str) -> str:
    # Keep the original Godot settings, including its singletons and input map.
    header = re.compile(r"(?m)^\[" + re.escape(section) + r"\]\s*$")
    m = header.search(text)
    if not m:
        return text.rstrip() + "\n\n[" + section + "]\n" + key + "=" + value + "\n"
    next_section = re.search(r"(?m)^\[\w[^\]]*\]\s*$", text[m.end():])
    end = m.end() + next_section.start() if next_section else len(text)
    body = text[m.end():end]
    pattern = re.compile(r"(?m)^(?:" + re.escape(key) + r")\s*=.*$")
    if pattern.search(body):
        body = pattern.sub(key + "=" + value, body, count=1)
    else:
        body = "\n" + key + "=" + value + "\n" + body
    return text[:m.end()] + body + text[end:]


def run(root: Path, kit: Path):
    pr = root / "project.godot"
    if not pr.exists():
        raise SystemExit("ERROR: GDRE did not recover project.godot; cannot export the game.")
    scene = root / "scenes" / "boot.tscn"
    if not scene.exists():
        raise SystemExit("ERROR: GDRE did not recover scenes/boot.tscn; game cannot be opened.")
    sources = sorted((root / "scripts").glob("*.gd"))
    if len(sources) < 5:
        raise SystemExit(f"ERROR: only {len(sources)} recovered GDScript sources; need complete recovery.")

    source_zip = kit / "base" / "OniRoai-recovered.zip"
    with ZipFile(source_zip) as z:
        bad = z.testzip()
        if bad:
            raise SystemExit(f"ERROR: ZIP has corrupt member {bad}")
        extracted = 0
        for member in z.infolist():
            prefix = "OniRoai/assets/"
            if member.is_dir() or not member.filename.startswith(prefix):
                continue
            rel = Path(member.filename[len("OniRoai/"):])
            if rel.is_absolute() or ".." in rel.parts:
                raise SystemExit("ERROR: Unsafe ZIP path")
            dst = root / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            with z.open(member) as src, dst.open("wb") as target:
                shutil.copyfileobj(src, target)
            extracted += 1
    for f in ("avatar.png", "loading.png", "key_panel.png"):
        if not (root / "assets" / "oniroai" / f).exists():
            raise SystemExit("ERROR: missing new art: " + f)
    for sub in ("scripts", "scenes"):
        (root / sub).mkdir(exist_ok=True)
    shutil.copy2(kit / "patches/scripts/oniroai_gate.gd", root / "scripts/oniroai_gate.gd")
    shutil.copy2(kit / "patches/scenes/oniroai_gate.tscn", root / "scenes/oniroai_gate.tscn")
    content = pr.read_text(encoding="utf-8")
    content = set_project_value(content, "application", "run/main_scene", '"res://scenes/oniroai_gate.tscn"')
    content = set_project_value(content, "application", "config/name", '"OniRoai"')
    content = set_project_value(content, "application", "config/icon", '"res://assets/oniroai/avatar.png"')
    pr.write_text(content, encoding="utf-8")

    # Export-debug is used so signing works independently of the APK's lost
    # original private signing key. This is a separately installable package.
    preset = '''[preset.0]
name="Android"
platform="Android"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="output/OniRoai-recovered.apk"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=1

[preset.0.options]
gradle_build/use_gradle_build=false
package/unique_name="vn.minhquan.oniroai.recovered"
package/name="OniRoai"
package/signed=true
package/app_category=6
version/code=11
version/name="0.6.0-recovery"
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
screen/immersive_mode=true
screen/edge_to_edge=false
screen/support_small=true
screen/support_normal=true
screen/support_large=true
screen/support_xlarge=true
permissions/internet=false
keystore/debug=""
keystore/debug_user=""
keystore/debug_password=""
keystore/release=""
keystore/release_user=""
keystore/release_password=""
'''  # Some settings are Godot-version specific; unrecognized keys are harmless.
    (root / "export_presets.cfg").write_text(preset, encoding="utf-8")
    print(f"Prepared: {root} | {len(sources)} restored scripts | {extracted} recovered assets")
    print("Gateway scene: res://scenes/oniroai_gate.tscn")

if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("root", type=Path)
    a.add_argument("kit", type=Path)
    args = a.parse_args()
    run(args.root.resolve(), args.kit.resolve())
