# IRA 3D — El Purificador

**Proyecto principal del repositorio: videojuego 3D de exploración y movimiento en tercera persona para Android, construido con Godot 4.4.**

> Versión de prueba v0.4: demuestra movimiento libre, cámara, salto, dash, ciudad 3D y checkpoint. **Todavía no** incluye combate, enemigos, jefe jugable ni modelos artísticos definitivos.

## Abrir en Godot

1. Clonar el repositorio y abrir directamente su carpeta raíz en Godot 4.4.1 o 4.x compatible.
2. Ejecutar `python3 tools/build_icon.py` una vez para generar los iconos Android (`assets/icon_192.png` y `assets/icon_432.png`), si aún no existen.
3. Iniciar con F5. En ordenador: WASD/flechas para mover, ratón derecho para cámara, espacio para saltar, Mayús para dash, Esc para pausa.
4. En Android: joystick izquierdo, arrastre táctil derecho para orientar cámara, SALTO, DASH, CÁM y pausa.

## Compilar APK

El workflow único `.github/workflows/android-3d.yml` importa el proyecto **desde la raíz**, comprueba la ejecución, genera el APK y valida que contiene scripts de IRA 3D y el identificador Android `com.lsnoglos.ira3d`. Artefacto: `IRA-3D-EXCLUSIVO-v0.4-APK`.

El proyecto se conserva independiente de la instalación 2D anterior. En Android comprueba que estás abriendo **IRA 3D EXCLUSIVO**, no la app antigua **IRA / El Purificador**.

## Estructura

- `project.godot`, `export_presets.cfg`: configuración raíz del proyecto 3D.
- `scenes/main.tscn`: escena inicial.
- `scripts/`: personaje, cámara, modelado provisional, ciudad, HUD y guardado.
- `tools/`: generador de iconos y verificador de APK.
- `docs/DISENO_TECNICO.md`: arquitectura y próximas entregas.

## Respaldo de IRA 2D

La última versión del juego 2D se conserva en la rama [archive/ira-2d-stage1](https://github.com/lsnoglos/Ira/tree/archive/ira-2d-stage1). **La rama principal ya no debe contener ningún archivo ni workflow 2D.**

## Limitaciones de esta entrega

Personajes y edificios aún son mallas 3D provisionales; no es un juego final con combate. El movimiento en móvil y el FPS real requieren pruebas en teléfonos físicos. El progreso 3D se guarda localmente en `user://ira3d_checkpoint_v1.json` al llegar a la baliza.

## Verificación del instalador correcto

El instalador IRA 3D v0.4 se obtiene exclusivamente del workflow `IRA 3D - Android Main` y se identifica como `IRA-3D-EXCLUSIVO-v0.4-APK`; nunca utilices los artefactos históricos `IRA-Stage1-Android-APK`, que corresponden a la versión 2D. Para verificar que el APK es realmente 3D, el archivo debe contener `Hero.gdc`, `FollowCamera.gdc` y `RuinedDistrict.gdc`, y no debe contener `Game.gdc` ni los sprites del juego 2D. En pantalla debe aparecer `IRA 3D EXCLUSIVO · V0.4 · NO 2D`.
