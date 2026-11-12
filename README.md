# Pocket_f3f — EdgeTX F3F slope soaring simulator

**Beta software.** [Published beta.1](https://github.com/guilleclos-pixel/Pocket_f3f/releases/tag/v1.0.0-beta.1) is preserved. The voice update on `main` is newer and still needs transmitter validation.

[Español](README_ES.md)

Pocket_f3f is a lightweight 3D slope-soaring simulator that runs **on the transmitter itself**, using its sticks and screen. Developed through iterative flight testing by an F3F pilot with programming assistance from ChatGPT (OpenAI).

## Tested hardware
- RadioMaster TX16S MKIII with EdgeTX (tested by the project creator).
- Other EdgeTX radios and Jeti radios **have not been verified**. Jeti requires a port and is not compatible with this EdgeTX widget as-is.
- Observed performance on the tested radio: roughly 11–14 FPS depending on visible terrain. This is not a guarantee for other radios.

## Install
1. Back up your transmitter SD card and the current simulator first.
2. Copy `WIDGETS/F3FTEST/main.lua` to the same path on your transmitter SD card.
3. Copy all **11 WAV files** from `SOUNDS/es/` to `/SOUNDS/es/` on the SD card, preserving their names. This includes the existing `pf3fpass.wav` and ten new voice files. The paths are fixed to `es`, regardless of the radio language. Do not create an extra `POCKETF3F` subfolder. Compare same-name files before replacing them; preserve unrelated SD files.
4. Select a **test model with RF modules disabled**; do not test while controlling an aircraft.
5. Add/select the `F3FRUD10` widget (stored in `WIDGETS/F3FTEST/`) in an EdgeTX customizable screen. Use **SH** to restart the simulation.

## Included
- Slope, cliff, beach, sea, 100 m course bases, 10-leg F3F practice timer, countdown, base and penalty cues, collision detection and a flyby WAV.
- This is a **training simulator**, not certified competition timing or a realistic aerodynamic solver.

## Video
[Watch the demonstration](https://youtu.be/gHABmrnJCOM)

## Credits
Concept, pilot testing and tuning: an F3F pilot. Lua development: created with assistance from ChatGPT (OpenAI), iterated with pilot feedback.

## Licensing
- Lua source code and documentation: MIT License (`LICENSE`).
- Flyby sound: limited project-specific permission (`AUDIO_LICENSE.md`); attribution required for modified versions of Pocket_f3f.

## Voice update / release status
- Launch and 30-second preparation announcements; countdown voices at 10, 5, 4, 3, 2 and 1 seconds; last-leg and finish announcements. Base, penalty and finish tones remain.
- Controls in TEST10: aileron, elevator, rudder (with a 2.5% center deadband) and SH reset. This revision also introduces an experimental flight core with continuous body axes, inertia/energy integration and vertical-flight recovery; validate its flight behavior on the transmitter.
- On-screen label: `F3F 1.3 RUD TEST10`; source header: `1.3 Rudder TEST10`. These identify the development revision, not a new published release.
- Download the complete source archive from **Code → Download ZIP** for the current development version; extract it and copy the contents of its `WIDGETS` and `SOUNDS` folders to the SD root. The enclosing repository folder must not be copied as the SD root.
- Updating `main` does not update the existing beta.1 tag or attached ZIP. Follow [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) to prepare a separate release.
- Clean installation, audible voices, countdown cancellation, ten legs, penalties, SH reset and FPS still require testing on the transmitter. Earlier hardware/performance observations do not validate this voice update.
- Code/documentation: MIT. Existing flyby permission: [AUDIO_LICENSE.md](AUDIO_LICENSE.md). Confirm and document redistribution permission for the ten new voices before a new public release.
