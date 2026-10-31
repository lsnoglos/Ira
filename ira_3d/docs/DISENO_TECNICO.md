# IRA 3D — Diseño técnico / Vertical Slice V0.1

## Objetivo

Demostrar un personaje 3D controlable en Android con cámara en tercera persona, dentro de una ciudad estilizada que exprese la dirección audiovisual del Stage 1. Mantener completamente la versión 2D del repositorio, sin mezclar sus escenas, partidas guardadas ni identificadores Android.

## Arquitectura del repositorio

- `/` — original 2D, mantenido sin modificaciones en `main`.
- `/ira_3d/` — proyecto independiente Godot 4.4+; propio `project.godot`, presets y paquetes Android.
- `scenes/main.tscn` — boot de la vertical slice.
- `scripts/Main.gd` — bucle de entrada, estado de pausa, autoguardado y montaje.
- `scripts/Hero.gd` — CharacterBody3D, cinemática, coyote time, dash y movimiento de piezas de armadura.
- `scripts/FollowCamera.gd` — cámara orbitable con SpringArm3D y smoothing.
- `scripts/TouchHUD.gd` — controles multitáctiles y HUD en espacio de pantalla.
- `scripts/RuinedDistrict.gd` — escenario modular procedural, luces e hitboxes de edificios/obstáculos.
- `scripts/ModelKit.gd` — materiales y constructores de primitive meshes reutilizables.

## Render y diseño visual

- **Dirección artística:** 3D estilizado de estética postapocalíptica biomecánica, con iluminación fría en sombras, acentos de coral/rojo energético y cian para esperanza.
- **Renderer inicial:** GL Compatibility para priorizar amplitud Android. El modo Mobile/Vulkan se evaluará cuando exista un elenco de teléfonos de prueba. No hay luces volumétricas reales en esta entrega.
- **Perspectiva:** cámara detrás del personaje con pitch limitado, brazo de ~5.7 m, movimiento independiente del vector de avance.
- **Modelo provisional:** construido mediante mallas primitivas de Godot. Preparado para sustituir visualmente por una escena GLB de Blender sin alterar controlador ni colisiones.
- **Escenario:** bloques arquitectónicos con profundidad, oclusión y geometría verdadera, postes cálidos, acentos de contaminación verde y un marcador de jefe futuro.
- **Rendimiento objetivo:** física 60 Hz; medir 30+ FPS en gama media real antes de incrementar número de luces, sombras y objetos. Para la versión artística final implementar distancias de visibilidad, LOD, instancing y streaming de sectores.

## Movimiento

- Cinemática en el plano X/Z controlada por cámara (movimiento 360°).
- Velocidad de caminar 5.3 m/s, correr 8.6 m/s y dash 15 m/s con CD 1.6 s.
- Salto 7.9 m/s bajo gravedad 22 m/s²; coyote time 120 ms y buffer de salto 150 ms.
- Colisión CapsuleShape3D independiente de piezas visuales; `move_and_slide` con floor snap.
- Joystick multitáctil; zona libre de cámara a la derecha; botones fijos en esquinas inferiores.

## Estado y guardado

- Archivo local JSON en `user://ira3d_checkpoint_v1.json`, versión de esquema 1.
- Se guarda al visitar la baliza del primer sector. Al reiniciar aparece en spawn seguro cercano a ese CP.
- La partida 3D **no** toca `user://ira_stage_save_v1.json` del juego 2D.
- La app Android usa el identificador distinto `com.lsnoglos.ira3d`.

## Roadmap por entregas

1. **0.1 Movimiento 3D** — control 360°, salto, dash, cámara y ciudad provisional Android. (esta entrega)
2. **0.2 Héroe artístico** — Blender GLB, rig, animación retargeting, controles afinados y VFX.
3. **0.3 Enemigos/combate** — ataques físicos y de infección, IA y lock-on.
4. **0.4 Rescate** — refugios, seguidores, prevención de contaminación y guardado completo.
5. **0.5 Boss Stage 1** — El Ojo modular con tentáculos articulados, arena y transición Stage 2.
6. **Optimización** — benchmark en teléfonos Android, streaming de geometría, bake de luces y escalabilidad.

## Verificación de esta entrega

- Compilación Godot `--headless --editor --quit` y prueba `--headless --quit-after 80`.
- Exportación `--export-debug Android` con firma de depuración.
- Inspección en teléfono pendiente; foco en rendimiento, controles multitáctiles y visibilidad de escena.
