# OniRoai v1.4.4 — playable Low-poly FPS arena

The supplied GLB is now the **main combat level**, replacing the old procedural ValleyOutpost ground, cover, fences, trees and props. The GLB is scaled to 0.42 and centered at (-5.08, 0.13, 2.1), with an approximately 84 × 29 m footprint. Player and four enemy spawns have been moved inside the new play area. An invisible outer boundary and safety floor prevent leaving the arena or falling through gaps. Imported mesh instances generate static trimesh collision for walls, buildings and props. Existing HUD, weapons, ESP and round rules remain intact.

**Testing required:** Godot editor/runtime was not available here. Collision, spawn clearances, enemy pathfinding and Android performance must be verified on device. The existing A* grid uses approximate routes and does not yet derive obstacle occupancy from GLB mesh collision; enemies may get stuck at some walls. Verify model license/attribution before distribution.
