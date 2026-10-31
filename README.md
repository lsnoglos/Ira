# IRA — El Purificador

**Entrega 1: videojuego de acción 2D para Android (Stage 1).** Motor: Godot 4.4 GDScript; diseño horizontal 1280×720; funcionamiento sin internet.

## Contenido jugable

- Menú **Continuar partida / Nueva partida / Armas y progreso / Salir**.
- 4 puntos de control con guardado real en `user://ira_stage_save_v1.json`, reanudación y reinicio.
- Heroe biomecánico con sprites de idle, carrera, salto, ataque, daño y señal de seguimiento.
- Ataque de garra y pulso energético, mejoras de arma por puntuación.
- Primera ciudad en ruinas con paralaje, aves con cola, bidones ácidos, neblina y ruinas en el horizonte.
- Enemigos corredores y escupidores, puntuación, daño y partículas.
- Jefe final: **El Ojo** con venas/latigazos y oleadas de proyectiles.
- Cartelas negras: `STAGE 1`, `SUPERASTE EL STAGE 1.` y `STAGE 2 — LA PRIMERA CURA`.
- Stage 2 queda como transición y pantalla de continuación (no incluye jugabilidad del Stage 2).

## Controles

| Acción | Android | Teclado para pruebas |
|---|---|---|
| Izquierda/derecha | Flechas en pantalla | A/D o ←/→ |
| Saltar | SALTO | Espacio / W / ↑ |
| Disparar | PULSO (mantener) | J / F |
| Ataque de garra | GARRA | K / G |
| Pausa | II | P / Esc |

## Abrir proyecto

1. Instalar **Godot 4.4.1** (editor estándar, no .NET).
2. Abrir esta carpeta usando `project.godot`.
3. Ejecutar con F6/F5 para probar con teclado. En Android los botones táctiles aparecen durante la partida.

## Compilar APK Android

Desde Godot: Editor > Configuración del editor > Exportar > Android: indicar el SDK de Android y JDK 17. Después Proyecto > Exportar > Android > Exportar proyecto. Elegir APK de depuración para pruebas personales. Para Google Play usar AAB y firma propia.

En GitHub, el workflow `.github/workflows/android-apk.yml` importa recursos, valida errores de scripts y exporta APK de depuración firmado. Una vez ejecutado, el APK queda en **Actions → Build IRA Android APK → Artifacts → IRA-Stage1-Android-APK**.

**Atención:** el workflow solo generará el APK cuando el código y los assets de este proyecto estén subidos al repositorio. El archivo ZIP de la entrega contiene los sprites procesados. No incluya contraseñas ni keystores privados en Git.

## Estructura

- `scenes/main.tscn`: escena principal.
- `scripts/Game.gd`: escenas del menú, jugabilidad, enemigos, UI y jefe.
- `scripts/SaveSystem.gd`: persistencia local (JSON, versión 1).
- `assets/sprites/`: 172 sprites extraídos de las ilustraciones originales, con fondo transparente.
- `tools/build_sprites.py`: reproduce la extracción desde las hojas creadas en ChatGPT.
- `export_presets.cfg`: preset de exportación Android ARM64.
- `.github/workflows/android-apk.yml`: compilación automatizada.

## Alcance de esta entrega

La primera versión es una **vertical slice** 2D y no un juego terminado. Las animaciones están extraídas automáticamente de hojas conceptuales y precisan recorte manual para un acabado comercial perfecto. Las personas refugiadas están preparadas como recursos visuales, pero el sistema de escolta y contaminación de civiles pertenece a una siguiente fase. El Stage 2 no está implementado.

La entrega incluye código y recursos, **no un APK verificado** hasta que se ejecute correctamente una exportación con Godot y las pruebas en Android.

En GitHub, los 172 sprites están almacenados en `assets_sprites.tar.gz` para que el sistema de compilación los descomprima antes de importar el proyecto. En el ZIP local ya vienen en `assets/sprites/`.
