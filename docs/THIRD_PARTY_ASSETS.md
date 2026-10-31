# Asset sources and licensing — IRA 3D v0.5

The following GLB objects are **real 3D models**, not screenshots or sprites. They are imported into Godot from `assets/kenney/` and instanced by `scripts/UrbanAssets.gd`.

## Kenney — CC0 1.0 Universal

Source: https://kenney.nl

| Pack | Files included | Official licence page |
| --- | ---: | --- |
| City Kit (Commercial) | 7 building variants | https://kenney.nl/assets/city-kit-commercial |
| City Kit (Roads) | 6 road fixtures / street props | https://kenney.nl/assets/city-kit-roads |
| Car Kit | 3 car / wreck props | https://kenney.nl/assets/car-kit |

The included GLB models were retrieved from the public Kenney CC0 model distribution at https://github.com/Hidencod/tge-assets , which supplies self-contained GLB models. Underlying authorship and CC0 grant are Kenney's. See that repository's README/catalog for source package filenames. Kenney's assets are CC0 1.0: commercial redistribution and modifications are permitted; creator credit is included voluntarily.

**Do not attribute original IRA character designs, names, scripts or lore to Kenney.** The IRA protagonist, original corrupted humanoid enemy and combat effects remain separate art/code created for this project.

## Controller research

- Jeheno's MIT third-person movement controller: https://github.com/Jeh3no/Godot-Third-Person-Controller
- The current `scripts/Hero.gd` and `scripts/FollowCamera.gd` are original IRA implementations. We evaluated the controller's architecture and retained IRA's touch input/camera integration rather than blindly mixing incompatible addon input maps.

## Engine constraints

Godot 4.4.1 with Compatibility renderer and OpenGL ES 3.0. Models are imported from glTF binary through Godot's importer. Mesh colliders are simplified boxes, not per-triangle collision. Imported building objects are reused from seven base mesh resources. The city is a small vertical slice; expand only after checking FPS on physical Android hardware.

## Art still pending

A high-fidelity anatomically modeled IRA protagonist with real skeleton and AnimationTree, detailed infected characters, PBR damage textures, unique boss arena, and high-quality sound remain future tasks. This v0.5 adds genuine third-party modular city geometry and **a playable first combat prototype**, not final commercial-quality art.
