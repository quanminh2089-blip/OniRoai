# Tiền Đồn 0.2.0 — tactical asset credits

The following files are external assets, not extractions from a commercial game.
Redistributed/converted copies were obtained from the public asset directory of
https://github.com/cktang88/3d-fps on 2026-11-02. That project's README explicitly
identifies the first-person weapon files as CC BY 4.0 and lists the underlying
authors. Its complete credits are retained in Tactical-upstream-credits.md.
No game source code, Fab animation archives or Fab motion-data files were reused.
Reload, input, map arrangement and UI code are original to this Godot project.

## MP5 A5 and first-person arms — CC BY 4.0

- MP5: **Rotuma**, “MP5 Submachine Gun”:
  https://sketchfab.com/3d-models/mp5-submachine-gun-a73b61932a0e4eecb5db5c63c158aa24
- Gloved arms: **bumstrum / DJMaesen**, “Fps arms”:
  https://sketchfab.com/3d-models/fps-arms-9452ce4cddde4110a4fd73e555a8e412
- Arm rig/grip templates: **ccransh**, “FPS AK-74m animations”:
  https://sketchfab.com/3d-models/fps-ak-74m-animations-94be8385c402474cacd39bc096c6ca14
- First-person assembly, rig adaptation and AO bake: the asset pipeline of
  cktang88/3d-fps, published there as CC BY 4.0 weapon files.
- Modified here: decoded Meshopt compression, removed quantization, converted
  for Godot, changed runtime framing, added hand IK and authored magazine/charging
  handle motions. No source animation set from a paid template is included.

## Optics — CC BY 4.0

Combined asset contains these models, with original assembly/marking-removal
modifications documented by its upstream distributor:

- **Argentavisss**, “Advanced Combat Optical Gunsight | Game Ready” (used optic):
  https://sketchfab.com/3d-models/advanced-combat-optical-gunsight-game-ready-4675fc83ccc54c018d4d03ee1709e8f5
- **valterjherson1**, “Generic Red Dot Scope / Rifle Attachment Lowpoly”:
  https://sketchfab.com/3d-models/generic-red-dot-scope-rifle-attachment-lowpoly-8bf2794c30d04fa0aed1e3df92cd8a9e
- **valterjherson1**, “EoTech EXPS3-0 Holographic Weapon Sight Lowpoly”:
  https://sketchfab.com/3d-models/eotech-exps3-0-holographic-weapon-sight-lowpoly-45e4fcdfb1b34756ab9e866564a12f66
- **ense7en**, “Nightforce ATACR 4-20x50 F1 Riflescope”:
  https://sketchfab.com/3d-models/nightforce-atacr-4-20x50-f1-riflescope-2ae2ddbc7ee049e3afcc3117f4ce6aa5

Modified here: compression decoded, flip covers added, attachment framing changed.
ADS narrows the main world camera and draws a scope mask; it does not use a second
picture-in-picture camera. This saves a second full scene render on phones.

## NPC model / motion

- **BAMEN**, “FREE [Military Soldier] RIGGED” — CC BY 4.0:
  https://sketchfab.com/3d-models/free-military-soldier-rigged-e9c56308a67d4a3db62e914fafa4d198
- **Quaternius**, Universal Animation Library 1 & 2 Standard — CC0:
  https://quaternius.com
- **Ian Mason, Sebastian Starke, Taku Komura**, 100STYLE — CC BY 4.0:
  https://zenodo.org/records/8127870
- Upstream converted/retargeted the clips; conversion here removes compression
  and uses selected run/melee/death clips. The separate unused soldier_tac asset
  is excluded from the APK/source bundle.

## Industrial map props and PBR surfaces — CC0

**Poly Haven** (https://polyhaven.com/license): old_military_crate,
concrete_road_barrier, Barrel_01, portable_generator,
modular_industrial_pipes_01; corrugated_iron and weathered_planks textures.

**ambientCG** (https://ambientcg.com): Asphalt031, Concrete047A, Metal063.

The distributor simplified/re-encoded these assets; this project decodes the
models, adjusts material parameters, enables mipmaps and limits textures to 1K
for mobile. Buildings, containers, racks, fences and signs are original geometry
assembled in Godot, dressed using these external PBR materials and scan props.

## Audio / fonts

- MP5 shot and firearm foley: **The Free Firearm Sound Library** — CC0:
  https://github.com/buddingmonkey/FreeFirearmsSFXLibrary
  OGG conversions supplied via the upstream project.
- Remaining footsteps/impact/UI sounds: **Kenney** — CC0; see previous credits.
- **DejaVu Sans**: see DejaVu.txt.

CC BY 4.0 license: https://creativecommons.org/licenses/by/4.0/
Full legal text is included as CC-BY-4.0.txt. Attribution is not an endorsement.
