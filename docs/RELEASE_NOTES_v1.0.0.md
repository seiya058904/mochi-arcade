# Mochi Arcade v1.0.0

Eight cozy, offline pocket games in one portrait Android app.

## Artifact

- File: `MochiArcade.apk`
- Package: `io.github.seiya058904.mochiarcade`
- Version: 1.0.0 (versionCode 1), min API 24, target SDK 36
- ABIs: arm64-v8a, x86_64
- SHA-256: `2b459f5cb47242b2e2c9283bc80e30629b413dc76bca4d776b84949f9815b2c5`
- Signing certificate SHA-256: `de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b`
- Signature: RSA-3072, v2+v3; non-debuggable; only `android.permission.VIBRATE`; zipalign 16 KiB
- Packaged content provenance: built from working tree at `3a8c7ec5c0c7a00a5d42d143fcf20dcae3db81d7`; later commits before the release touched only `docs/`, `tests/`, `scripts_tools/` and similar export-excluded paths, so the packaged game content is unchanged. The tag `v1.0.0` points to the release commit that records this release.

## Verification

- 18 required Godot suites: PASS (local run on `90ee172`; CI also passes the suite and development-APK steps).
- Signed-byte acceptance on a controlled AOSP API 34 x86_64 AVD (Google AEHD 2.2, AMD Radeon RX 7900 XT host GPU, 720x1280):
  - eight games x three background/foreground returns, 101 visible frames, zero blank frames, same PID, pause checkpoint equality, force-stop round restore, zero-score restart;
  - settings persistence, same-signature reinstall preserves the save, launcher icon, edge-target taps, first background-music loop;
  - maximum pools: Bouncy Balls 64 balls 55.55 presented FPS (p50 16.679 ms, p95 33.166 ms); Jelly Slice 12 fruit 60.0 FPS (p95 17.199 ms); exact save restoration.
- Bounded static security audit: PASS, no known credential-pattern findings.
- Physical phone: the user reported a hands-on retest with no problems. Device metadata, captures and the on-phone hash were not supplied; this is subjective user evidence, not automated byte-level acceptance.

## Known limitations and disclosed risks

- The GitHub-hosted Ubuntu + Mesa llvmpipe software-rendered Android emulator still intermittently returns a blank frame after a background return (`EGL_BAD_SURFACE`; a new surface cycle recovers the visible pause sheet with the same PID). Final-SHA run 39716897550 failed at `01-fruit_drop-repeat-3-background-return` with blank-frame SHA-256 `cfc80ccb6c70119363e7e3da3bbb361f4c4c2628e4856bfdce139ea7b8cdf249`. The raw failure evidence and FAIL status are retained; no assertion was removed or relaxed, and this failure is not reported as PASS.
- The release owner approved a scoped environment exception for that specific hosted software-rendered black return only: `OWNER_APPROVED_ENVIRONMENT_EXCEPTION` (A14), with the hardware-GPU API 34 signed-byte acceptance above as substitute evidence. No self-hosted GPU runner was added. This is not a PASS and does not show that every software renderer is stable.
- Physical-phone quantitative performance is UNVERIFIED: no phone frame-time, thermal, battery or refresh-rate measurements were supplied. Emulator compositor FPS (55-60) is not phone FPS. Physical-device automated signed-byte acceptance is DEVICE_UNAVAILABLE; the physical-phone result is user-reported only.
- Bouncy Balls keeps the enlarged play-field revision (32 px ball, 4x6 brick wall, 150x46 multiplier gates, 68 px bumpers, paddle unchanged). The other seven games keep their previous designs.

## Install

Android 7.0+ (API 24). Updates must retain the same package name and release signing identity to preserve app data. The APK is signed with the existing Mochi Arcade release certificate; the private key never left the owner's machine and was not uploaded to repository secrets.
