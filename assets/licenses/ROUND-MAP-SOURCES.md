# Tiền Đồn 0.4.0 — Thung Lũng / Trạm 04

External models and materials downloaded from their original sources on
2026-11-03. All resources here are CC0. Their original source material is kept
in `assets/citadel`; no download is performed by the installed game.

| Asset | Author | Source |
| --- | --- | --- |
| Rock Moss Set 01, six scanned stones | Kless Gyzen | https://polyhaven.com/a/rock_moss_set_01 |
| Fern 02, four scanned plant clumps | Rico Cilliers (model), Rob Tuytel (scan) | https://polyhaven.com/a/fern_02 |
| Tree (tree-24) | musdasch; collaborators Yughues and para | https://opengameart.org/content/tree-24 |
| Forest Ground 04 | Rob Tuytel; minor adjustments by Rico Cilliers | https://polyhaven.com/a/forest_ground_04 |
| Medieval Blocks 03 | Rob Tuytel | https://polyhaven.com/a/medieval_blocks_03 |
| Leafy Grass | Charlotte Baglioni | https://polyhaven.com/a/leafy_grass |

Poly Haven license: https://polyhaven.com/license
CC0: https://creativecommons.org/publicdomain/zero/1.0/

Preparation and changes:

- Poly Haven files use the 1K glTF/JPEG export. Downloads were compared with
  the MD5 values published by `https://api.polyhaven.com/files/<asset>`.
- The OpenGameArt archive's `tree.glb` is stored as `forest_tree.glb`.
- Separate rocks and fern variants are centered, grounded and resized at runtime.
  Only their mesh/material resources are shared; unrelated catalogue offsets are
  removed. The fern's separate alpha map is applied in a cutout shader because
  its supplied glTF base-color JPEG has no alpha channel.
- Textures use mipmaps, mobile ETC2 compression and a 1024px import limit.
  Roughness and normal strength are adjusted for consistent lighting.
- Trees and ferns have small shader wind motions. The ground mixes two original
  PBR texture sets. Stone arches, guardhouse, fence, flags, map layout, collision,
  paths and water animation are original procedural work for this project.
- Repeated geometry is grouped into spatial MultiMeshes. Playable scanned rocks
  retain real triangle collisions. Decorative plants do not block players/bullets.
- `assets/sounds/outpost_wind.wav` is an original 8-second synthesized wind bed,
  generated for this project, not a field recording.
- Existing gun, soldier, props, optics, animation and sound credits remain in
  `TACTICAL-SOURCES.md` and `Tactical-upstream-credits.md`. The NPC's MP5 is the
  already credited weapon mesh with first-person arms removed; two IK hand
  targets and reload/muzzle effects are authored here.

This is an original fictional FPS arena, not a map extracted from PUBG or another
commercial game. The project does not contain game modification hooks or offsets.
