# Pocket_f3f — Simulador F3F para EdgeTX

**Software beta.** La [beta.1 publicada](https://github.com/guilleclos-pixel/Pocket_f3f/releases/tag/v1.0.0-beta.1) se conserva. La actualización de voces de `main` es posterior y está pendiente de validación en la emisora.

Pocket_f3f es un simulador 3D de vuelo en ladera que se ejecuta **directamente en la emisora**, con sus sticks y pantalla. Nació de las pruebas de un piloto de F3F y se desarrolló con asistencia de ChatGPT (OpenAI).

## Compatibilidad comprobada
- RadioMaster TX16S MKIII con EdgeTX. Otros modelos **no verificados**.
- Rendimiento observado en la unidad de pruebas: 11–14 FPS según la ladera visible.
- **No es compatible directamente con Jeti**: requiere adaptación del código.

## Instalación
1. Haz copia de seguridad de los archivos y de la SD.
2. Copia `WIDGETS/F3FTEST/main.lua` a esa misma ruta en la SD.
3. Copia los **11 WAV** de `SOUNDS/es/` a `/SOUNDS/es/` en la SD: el sonido de pasada existente y las diez voces nuevas. Conserva los nombres; no añadas una subcarpeta `POCKETF3F`. La ruta `es` es fija aunque la emisora use otro idioma. Compara archivos del mismo nombre antes de sustituirlos y conserva el resto de la SD.
4. Selecciona un **modelo de pruebas con los módulos RF desactivados**.
5. Añade el widget `F3FTEST` a una pantalla configurable de EdgeTX. El interruptor momentáneo **SH** reinicia el vuelo.

## Funciones
Ladera, cornisa, playa, mar, bases a 100 m, diez largos, cuenta atrás, avisos acústicos, penalizaciones, colisiones y sonido de pasada. No sustituye un cronometraje oficial ni un modelo aerodinámico completo.

## Vídeo
[Demostración](https://youtu.be/gHABmrnJCOM)

## Créditos
Idea, validación y ajustes como piloto: piloto de F3F. Programación asistida mediante ChatGPT (OpenAI), con sucesivas pruebas y correcciones.

## Actualización de voces e instalación completa
- Avisos de lanzamiento y preparación de 30 segundos; cuenta atrás de 10, 5, 4, 3, 2 y 1; última recta y final de manga. Se conservan los tonos de bases, penalización y final.
- El código actual lee alerones, profundidad y SH. **Esta revisión no incorpora Rudder**, aunque lo mencione el título del commit de subida.
- La pantalla muestra `POCKET F3F BETA` y la cabecera del código `1.2 Voice TEST`; no indican una nueva release publicada.
- Para probar el desarrollo actual: **Code → Download ZIP**, descomprime y copia el contenido de `WIDGETS` y `SOUNDS` a la raíz de la SD. No copies la carpeta contenedora del repositorio como raíz.
- La subida a `main` no actualiza la etiqueta ni el ZIP de beta.1. Prepara una release separada siguiendo [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).
- Queda por probar esta actualización en instalación limpia: voces audibles, cancelación de cuenta atrás, diez largos, penalizaciones, SH y rendimiento. Las pruebas anteriores no validan esta revisión.
- Código y documentación: licencia MIT. El permiso de [AUDIO_LICENSE.md](AUDIO_LICENSE.md) cubre el sonido de pasada; falta documentar el permiso de redistribución de las diez voces nuevas antes de una nueva publicación.
