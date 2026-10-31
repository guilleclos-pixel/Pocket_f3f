# Pocket_f3f — Simulador F3F para EdgeTX

**Paquete candidato para pruebas; aún no publicado.**

Pocket_f3f es un simulador 3D de vuelo en ladera que se ejecuta **directamente en la emisora**, con sus sticks y pantalla. Nació de las pruebas de un piloto de F3F y se desarrolló con asistencia de ChatGPT (OpenAI).

## Compatibilidad comprobada
- RadioMaster TX16S MKIII con EdgeTX. Otros modelos **no verificados**.
- Rendimiento observado en la unidad de pruebas: 11–14 FPS según la ladera visible.
- **No es compatible directamente con Jeti**: requiere adaptación del código.

## Instalación
1. Haz copia de seguridad de los archivos y de la SD.
2. Copia `WIDGETS/F3FTEST/main.lua` a esa misma ruta en la SD.
3. Copia `SOUNDS/es/pf3fpass.wav` a esa misma ruta. El programa actual busca el sonido en `es`.
4. Selecciona un **modelo de pruebas con los módulos RF desactivados**.
5. Añade el widget `F3FTEST` a una pantalla configurable de EdgeTX. El interruptor momentáneo **SH** reinicia el vuelo.

## Funciones
Ladera, cornisa, playa, mar, bases a 100 m, diez largos, cuenta atrás, avisos acústicos, penalizaciones, colisiones y sonido de pasada. No sustituye un cronometraje oficial ni un modelo aerodinámico completo.

## Vídeo
[Demostración](https://youtu.be/gHABmrnJCOM)

## Créditos
Idea, validación y ajustes como piloto: piloto de F3F. Programación asistida mediante ChatGPT (OpenAI), con sucesivas pruebas y correcciones.

## Antes de publicar
- Los archivos Lua y WAV proceden sin modificaciones del ZIP Pocket_f3f 3.10 aprobado en la emisora.
- **Detalle visual pendiente:** la pantalla muestra `POCKET F3F 3.9` aunque el paquete es 3.10.
- Verificar una instalación limpia, sonidos, cronometraje, reset y rendimiento.
- Elegir una licencia de software tras revisar autoría y permisos de distribución del sonido.
