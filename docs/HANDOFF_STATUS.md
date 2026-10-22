# Handoff status — 2026-10-22 takeover

Recorded while taking over the late-stage project from the previous Codex
session. Facts below were re-checked on this Windows machine; nothing is copied
unverified from the earlier conversation.

## Repository and recovery

- Working directory: `D:\xia zai\AI project\Project in Iteration\Mochi Arcade`
  (single worktree; `git rev-parse --show-toplevel` confirms it).
- Remote: `https://github.com/seiya058904/mochi-arcade.git`, private, default
  branch `main`. GitHub CLI authenticated as `seiya058904` with `repo` scope.
- HEAD when the takeover started: `7a48d0eb250f1928685297bab0d6ab3c8b6aa761`
  ("test: repeat Android lifecycle checks on host GLES"); `origin/main` was the
  same commit.
- The worktree was **not clean**: 15 tracked paths modified and 13 untracked
  evidence paths from the previous session's expanded small-button hit regions
  were recovered, including `scripts/app/main.gd`,
  `tests/integration/collection_audit.gd`, `scripts_tools/android_smoke.py`,
  `.github/workflows/ci.yml`, docs/evidence updates and the
  `docs/evidence/android-repeat-7a48d0e/` captures.
- Protection: `.local/handoff-snapshot/` (git-ignored) holds
  `tracked-worktree.patch`, `status-porcelain.txt`, `head.txt`,
  `origin-main.txt` and copies of every untracked evidence file. No
  `git reset --hard`, `git clean`, force-push or overwriting pull was run.
- Validation of the recovered work: all 18 required suites PASS locally
  (`docs/evidence/required-checks.json`), with 995 collection checks and the
  preserved pre-repair hit-target baseline in
  `docs/evidence/touch-target-baseline.json`.

## Toolchain and signing

- Godot `4.7.2.stable.official.ed1daf0bf` at
  `.local/toolchain/godot-4.7.2/Godot_v4.7.2-stable_win64.exe` (official
  archive and export templates retained with `SHA512-SUMS.txt`).
- Temurin OpenJDK 17.0.20.1; Android SDK at
  `%LOCALAPPDATA%\Android\Sdk` with platform-tools, platforms 34/35/36 and
  Build Tools 34.0.0/35.0.1/36.0.0; `adb`, `apksigner`, `aapt2`, `zipalign`
  available.
- Release identity present at `%USERPROFILE%\.mochi-arcade\signing`
  (`mochi-arcade-release.p12`, DPAPI-protected `password.dpapi.xml`,
  `certificate.pem`). Public certificate SHA-256:
  `de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b`.
  The key was not copied, printed or re-initialized, and no second identity was
  created. Signing material stays outside Git.
- Pre-takeover APKs: `dist/MochiArcade-dev.apk` (debug build) and
  `dist/MochiArcade.apk` (78,016,973 bytes, SHA-256
  `3597bc5020d5ec545e87a837b03a7a2a7a375a24cde002d44c0c47d1aaa42901`,
  signed candidate built from `a2a3bd7`; never installed on a device). The
  candidate predates the recovered hit-region change and the Bouncy Balls layout
  revision, so it is superseded.

## Android devices and CI

- `adb devices -l` returns no attached device: physical-phone verification is
  `DEVICE_UNAVAILABLE`.
- Local AVD `Codex_Maestro_Android34` exists, but
  `emulator -accel-check` exits 1 with code 6 ("Android Emulator hypervisor
  driver is not installed"). Prior software-only attempts never reached an online
  device, so local Android execution remains `BLOCKED`; no OS driver, boot
  setting or host configuration was changed.
- Remote state at takeover: no GitHub Releases; latest run
  [39673516558](https://github.com/seiya058904/mochi-arcade/actions/runs/39673516558)
  on `7a48d0e` is FAIL (all eight smoke paths and 24 background returns pass;
  the disposable AVD goes offline while writing the Jelly load fixture) and no
  tag exists.

## What the takeover changed

1. Recovered and validated the unpushed expanded hit regions (96 design px
   minimum hit area, 15 real GUI edge cases, 995 collection checks).
2. Added the Bouncy Balls P1 layout revision requested by the user's phone
   playtest: larger ball, 4x6 large-brick wall, larger multiplier gates and
   bumpers, paddle untouched. See `docs/PLAYTEST_FEEDBACK.md`.
3. Added `tests/integration/balls_layout.gd` for measured before/after desktop
   captures plus layout JSON, extended `tests/integration/bouncy_balls.gd` with
   layout invariants, and updated the Android maximum-pool fixture to the new
   brick grid. Full 18-suite regression passes.
4. Retained the pre-change Android 720x1280 Bouncy Balls captures and reviewed
   run 39673516558's failure evidence; the load-fixture ADB timeout plus
   gfxstream null-context host errors are classified as emulator/infrastructure
   failure with no retained app crash evidence (see `docs/QA_REPORT.md`).
5. Instrumented future CI runs to retain a continuous guest log during load
   cases and final host process/memory/disk/kernel state, without retrying or
   weakening any assertion.

## Takeover verification runs

- Run [39698026180](https://github.com/seiya058904/mochi-arcade/actions/runs/39698026180)
  on `32df767`: engine import, 18 suites and the development APK pass; Android
  install/launch/edge-target taps pass; Fruit, Bubble and Cake complete all
  lifecycle checks and Bouncy Balls passes its first paused return; the step
  aborts at Bouncy Balls cycle 2 because the resumed round legitimately ended
  during the slow capture window and the harness assumed a paused round would
  still exist. The maximum-pool step passes with both pools on the same online
  AVD (Balls 3.84 FPS, Jelly 7.19 FPS, software renderer, exact save restoration,
  host state and continuous logcat retained). Full analysis is in
  `docs/QA_REPORT.md`; raw reports are `android-smoke-39698026180.json` and
  `android-load-39698026180.json`.
- Run [39699385661](https://github.com/seiya058904/mochi-arcade/actions/runs/39699385661)
  on `28a8a45` (harness fix): 18 suites, APK build and the new edge-target taps
  pass; Android then reproduces a fully black Fruit Drop background return. The
  screen is still black after an extra 5 s and only a new surface cycle restores
  the visible pause sheet with the same PID, with `EGL_BAD_SURFACE` in the guest
  log. This is the retained release blocker, not a harness-fix regression, and it
  stays BLOCKED. Both maximum pools execute again (Balls 3.60 FPS, Jelly 5.04 FPS,
  software renderer, exact save restoration). Raw evidence is retained under
  `android-black-return-*`, `android-smoke-39699385661.json` and
  `android-load-39699385661.json`.
- Local AVD retry (2026-10-22): a bounded 8-minute software-only boot never left
  `emulator-5554 offline`; retained as `local-avd-attempt.json`. No install was
  attempted and no host configuration was changed.

## Exact next actions (in order)

1. Commit the recovered hit-region work, the Bouncy Balls revision, docs and
   evidence; push `main`; let CI run on the new SHA.
2. Read the new run's artifacts: Android Bouncy Balls 720x1280 captures before/
   after comparison, smoke edge-target taps, maximum-pool behaviour and the new
   host-state/continuous logcat retention.
3. Rebuild `dist/MochiArcade.apk` with `scripts_tools/sign_release.ps1 -Build`
   from the final commit and record size/SHA-256/signature/package evidence.
4. To close A05/A09/A12/A15, either connect a USB-debugging Android phone for
   lifecycle/touch/load/signed-byte acceptance, or explicitly authorize uploading
   the release keystore and DPAPI password to two encrypted GitHub Actions
   secrets so the hosted emulator can test the signed bytes. Until one of those
   happens, no stable tag or Release may be created. The most useful next
   diagnostic for the black return is a physical phone or a hardware-GPU host,
   because the hosted runner only provides Mesa llvmpipe software rendering.
