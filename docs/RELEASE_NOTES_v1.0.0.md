# Mochi Arcade v1.0.0

Eight cozy, fully offline pocket games in one portrait Android app.

## Artifact

- File: `MochiArcade.apk`
- Package: `io.github.seiya058904.mochiarcade`
- Version: 1.0.0 (versionCode 1), min API 24, target SDK 36
- ABIs: arm64-v8a, x86_64
- SHA-256: `8fcc1ebc83cb9cb8e8947a1a33bef9cba9222b9ac775fafdcd7d3d5cd85d473c`
- Signing certificate SHA-256: `de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b`
- Signature: RSA-3072, v2+v3; non-debuggable; only `android.permission.VIBRATE`; zipalign 16 KiB
- Built with the existing Mochi Arcade release identity from the v1.0.0 release tag tree. The game content is unchanged from the previously accepted candidate; this rebuild adds the custom boot splash and release documentation. The private key never left the owner's machine and was not uploaded to repository secrets.

## Verification

- 18 required Godot suites: PASS on the release working tree, with zero runtime errors.
- Signed-byte acceptance on a controlled AOSP API 34 x86_64 AVD (Google AEHD 2.2, AMD Radeon RX 7900 XT host GPU, 720x1280):
  - eight games x three background/foreground returns, 101 visible frames, zero blank frames, same PID, pause checkpoint equality, force-stop round restore and zero-score restart;
  - settings persistence, same-signature reinstall preserves the save, launcher icon, edge-target taps and the first background-music loop;
  - maximum pools: Bouncy Balls 64 balls at 55.43 presented FPS (p95 33.251 ms); Jelly Slice 12 fruit at 60.0 FPS (p95 17.243 ms); original save and backup restored exactly.
- Custom startup experience: the Android system splash shows the original bunny icon; the app boot splash is a cream Mochi Arcade image with the bunny and macaron. No Godot default logo, blue icon or default progress bar is shown, and there is no fake percentage or artificial delay. First launch 463 ms, cold start 408 ms, warm start 79 ms on the controlled AVD; screenshots and screen recordings are retained in `docs/evidence/android-api34-final-splash-2026-10-22/`.
- Bounded static security audit: PASS, no known credential-pattern findings.
- Physical phone: the owner reported a hands-on retest with no problems. Device metadata, captures and the on-phone hash were not supplied; this is subjective user evidence, not automated byte-level physical-device acceptance.

## Known limitations and disclosed risks

- The GitHub-hosted Ubuntu + Mesa llvmpipe software-rendered Android emulator still intermittently returns a blank frame after a background return (`EGL_BAD_SURFACE`; a new surface cycle recovers the visible pause sheet with the same PID). Retained run 39716897550 failed at `01-fruit_drop-repeat-3-background-return` with blank-frame SHA-256 `cfc80ccb6c70119363e7e3da3bbb361f4c4c2628e4856bfdce139ea7b8cdf249`. Raw failures and FAIL statuses are retained; no assertion was removed or relaxed, and this failure is not reported as PASS.
- The release owner approved a scoped environment exception for that specific hosted software-rendered black return only: `OWNER_APPROVED_ENVIRONMENT_EXCEPTION` (A14), with the hardware-GPU API 34 signed-byte acceptance above as substitute evidence. No self-hosted GPU runner was added. This is not a PASS and does not show that every software renderer is stable.
- Physical-phone quantitative performance is UNVERIFIED: no phone frame-time, thermal, battery or refresh-rate measurements were supplied. Emulator compositor FPS (55-60) is not phone FPS. Physical-device automated signed-byte acceptance is DEVICE_UNAVAILABLE; the physical-phone result is user-reported only.
- Bouncy Balls keeps the enlarged play-field revision (32 px ball, 4x6 brick wall, 150x46 multiplier gates, 68 px bumpers, paddle unchanged). The other seven games keep their previous designs.

## Install

Android 7.0+ (API 24). Open the APK with Android's package installer. Updates must retain the same package name and release signing identity to preserve app data. The repository is public; this release is published from the same repository without a replacement repo.

## License

Copyright (c) 2026 seiya058904. All rights reserved. See the repository `LICENSE` for the repository license and third-party notices. Godot Engine (MIT) and Nunito / Noto Sans SC (SIL OFL 1.1) remain under their own licenses.
