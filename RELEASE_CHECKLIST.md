# Pocket_f3f v1.0 Beta — publication checklist

- [ ] Test this exact ZIP on a clean TX16S MKIII SD setup (with RF disabled).
- [ ] Verify the sound is audible from `SOUNDS/es/pf3fpass.wav`.
- [x] Confirm the release candidate displays `POCKET F3F BETA` and runs on the test transmitter.
- [ ] Confirm A-start, 30 s entry timing, ten legs, base and penalty sounds, impact, SH reset.
- [ ] Make sure the current source and flyby audio can be redistributed as open source.
- [x] Select MIT license for code and documentation.
- [x] Document the owner's permission to distribute and modify the WAV within Pocket_f3f (`AUDIO_LICENSE.md`).
- [ ] Final audio provenance check before public release.
- [ ] Confirm repository visibility, README and issue reporting.
- [ ] Add release ZIP and video link; publish only after approval.
- [ ] Ask early testers for radio model, EdgeTX version, FPS, issues and a short video.

## Voice update — next release (separate from published beta.1)

The historical checklist above records earlier work; it does not certify the voice update.

- [x] Reviewed upload commits `3bf6e12` (Lua) and `c2f9cd0` (ten new WAVs).
- [x] Corrected voice paths to the existing `/SOUNDS/es/` layout; retained `pf3fpass.wav`.
- [x] Reviewed replacement upload `3a03dbb`: TEST10 reads and applies rudder, alongside aileron/elevator/SH; widget name is F3FRUD10 in WIDGETS/F3FTEST/.
- [ ] Validate rudder direction/centering, vertical-flight recovery and the experimental flight core on the transmitter. This is more than a voice-only update.
- [ ] Document provenance and redistribution permission for all ten new voice files; existing AUDIO_LICENSE.md covers only pf3fpass.wav.
- [ ] Test this exact candidate on a clean SD installation with RF disabled; record radio and EdgeTX version.
- [ ] Hear launch1 and thirty; then ten, five, four, three, two, one during preparation. Enter early and verify subsequent preparation prompts stop.
- [ ] Complete ten legs; verify lastleg after leg 9, finish after leg 10, base/penalty tones and flyby remain audible.
- [ ] Verify late entry, impact, SH reset (including voice state) and FPS.
- [ ] Choose a new, unused prerelease tag after reviewing the mixed internal version labels; do not move v1.0.0-beta.1.
- [ ] Build ZIP from the exact tested commit with WIDGETS/ and SOUNDS/ at archive root, plus README files, LICENSE and AUDIO_LICENSE.md.
- [ ] ZIP must contain WIDGETS/F3FTEST/main.lua and SOUNDS/es/{launch1,thirty,ten,five,four,three,two,one,lastleg,finish,pf3fpass}.wav (11 WAVs).
- [ ] Record commit SHA and archive SHA-256 in release notes; include changes, installation, tested setup and known limitations.
- [ ] Include the new [Rudder TEST10 demonstration](https://youtu.be/IngQQTTQPvE) in the next release notes; retain the previous release's video link.
- [ ] Create a draft prerelease using that commit and attach the verified ZIP. Download and test the attached ZIP before publication.
- [ ] Publish only after approval. Keep the previous beta.1 release, tag and asset intact.
