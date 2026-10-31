# Pocket_f3f — EdgeTX F3F slope soaring simulator

**Beta release candidate — repository remains private pending public release.**

Pocket_f3f is a lightweight 3D slope-soaring simulator that runs **on the transmitter itself**, using its sticks and screen. Developed through iterative flight testing by an F3F pilot with programming assistance from ChatGPT (OpenAI).

## Tested hardware
- RadioMaster TX16S MKIII with EdgeTX (tested by the project creator).
- Other EdgeTX radios and Jeti radios **have not been verified**. Jeti requires a port and is not compatible with this EdgeTX widget as-is.
- Observed performance on the tested radio: roughly 11–14 FPS depending on visible terrain. This is not a guarantee for other radios.

## Install
1. Back up your transmitter SD card and the current simulator first.
2. Copy `WIDGETS/F3FTEST/main.lua` to the same path on your transmitter SD card.
3. Copy `SOUNDS/es/pf3fpass.wav` to the same path on the SD card. The current Lua code expects the **Spanish (`es`) sound folder**.
4. Select a **test model with RF modules disabled**; do not test while controlling an aircraft.
5. Add/select the `F3FTEST` widget in an EdgeTX customizable screen. Use **SH** to restart the simulation.

## Included
- Slope, cliff, beach, sea, 100 m course bases, 10-leg F3F practice timer, countdown, base and penalty cues, collision detection and a flyby WAV.
- This is a **training simulator**, not certified competition timing or a realistic aerodynamic solver.

## Video
[Watch the demonstration](https://youtu.be/gHABmrnJCOM)

## Credits
Concept, pilot testing and tuning: an F3F pilot. Lua development: created with assistance from ChatGPT (OpenAI), iterated with pilot feedback.

## Release notes / outstanding checks
- Code taken **unchanged** from the user-approved Pocket_f3f Lua 3.10 ZIP.
- The beta release candidate was tested on a RadioMaster TX16S MKIII; the on-screen label reads `POCKET F3F BETA`.
- Install from a clean SD layout; verify WAV path, ten legs, penalties, reset, FPS, speaker volume.
- Code and documentation are licensed under the MIT License (see `LICENSE`). Confirm the flyby sound's original provenance and redistribution rights before public release.
- Public beta distribution is pending review.
