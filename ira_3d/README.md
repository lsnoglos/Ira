# IRA 3D — El Purificador

## Entrega 3D 0.1 · Movimiento libre en tercera persona

Vertical slice autónomo en **Godot 4.4**, GDScript, Android horizontal y renderer **Compatibility** (para ampliar el soporte de GPU). No importa ni sustituye el código de IRA 2D alojado en la raíz del repositorio.

### Incluye realmente

- Héroe tridimensional provisional original con armadura biomecánica articulada, visor rojo y garra.
- Movimiento libre 360°, salto con tolerancia de borde (*coyote time*), aceleración, sprint táctil y dash con cooldown.
- Cámara orbitable en tercera persona con **SpringArm3D**, prevención básica de clipping con el entorno, recentrado y seguimiento suavizado.
- Controles táctiles: joystick izquierdo, deslizar mitad derecha para cámara, **SALTO**, **DASH**, **CÁM** y pausa.
- En escritorio: WASD/flechas, espacio para saltar, Mayús para dash, botón derecho para cámara, Esc para pausar.
- Calle original 3D estilizada con edificios y ruinas, postes iluminados, vehículos abandonados, bidones tóxicos y una baliza luminosa.
- Guardado local al tocar baliza (cerca de z=-27), recuperado al iniciar de nuevo (`user://ira3d_checkpoint_v1.json`).
- Símbolo lejano inspirado en El Ojo como decorado; **no es todavía un jefe con IA**.
- FPS objetivo 30–60, a verificar en distintos teléfonos reales.

### No incluye (siguientes entregas)

- Modelos artísticos finales de Blender, rig/skeletal animation profesional, texturas PBR definitivas.
- Combate, enemigos con IA, físicas de proyectiles, misiones de rescate ni el combate contra El Ojo.
- Guardado avanzado de inventario, armas, puntuación y múltiples sectores.
- Pruebas de rendimiento o tactilidad en dispositivos físicos; esta entrega valida primero el movimiento y la exportación.

### Ejecutar

1. Abre la carpeta `ira_3d/` como proyecto independiente en Godot 4.4.1 (o una versión 4.x compatible).
2. Pulsa F6/F5 para iniciar la escena principal.
3. Para Android, ejecuta workflow `.github/workflows/ira-3d-android.yml` o exporta el preset `Android` con SDK y plantilla configurados.
4. No cambies `package/unique_name`: `com.lsnoglos.ira3d` es diferente del paquete 2D y evita reemplazarlo en tu teléfono.

### Recursos y licencias

Todos los meshes y materiales iniciales se construyen por código, sin assets de terceros. No incluye sprites reutilizados de Metal Slug, Mario ni otras franquicias.

Consulta `docs/DISENO_TECNICO.md` para arquitectura, decisiones visuales, límites y roadmap.
