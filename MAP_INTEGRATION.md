# Low-poly FPS Map integration (OniRoai v1.4.3)

- Imported `assets/maps/low_poly_fps_map.glb` (user-supplied GLB).
- Instantiated by `scripts/round_map.gd` in `_add_fps_district()`.
- Original model bounding box approximately 200 x 6.25 x 69.75 meters.
- Scale 0.35; origin (60, 0.12, 2), resulting X bounds approximately 29.2 to 99.2 meters.
- Existing playable arena occupies approximately X -23..23 and Z -27..27. New district is positioned outside the east fence so it does not overlap the existing arena, spawns, or NPC routes.
- This is an **exterior visual district**, not a new walkable combat area. Existing collision and A* pathing are retained. To make the new district playable, arena boundaries, ground collision, spawns, nav grid, and model collision must be redesigned.
- The imported model is ~11 MB and may affect mobile GPU performance. Test Android build and in-game appearance; no Godot runtime test was performed here.
- Check the original model's license/attribution before distributing the game.
