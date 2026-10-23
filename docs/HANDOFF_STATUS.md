# Handoff status

## Current 1.1.1 patch — 2026-10-23

**IN_PROGRESS; new signed Android and release gates NOT_RUN.** See
[ITERATION_1.1.1.md](ITERATION_1.1.1.md) for F1–F6, exact next actions and
current evidence. The v1.1.0 sections below describe the previous delivery.

## Historical iteration — 2026-10-23

**v1.1.0 RELEASED; original signed runtime/upgrade and anonymous bytes PASS.**
The public v1.0.0 tag/assets remain unchanged. See [ITERATION_1.1.md](ITERATION_1.1.md)
for audit, full artifact identity and raw evidence. Runtime source is 5672e409;
subsequent changes concern acceptance tools, documents and evidence only.

Local 19/19 suites (48 reliability assertions), 64 EN/ZH layout captures and
failure/Undo screens pass. Hosted exact-byte run 39930890985 passes predecessor,
in-place upgrade, eight restored games, corrupt/read-denied recovery, clean
candidate 8 x 3 lifecycle, audio loop and maximum pools. All 240 captures reviewed.
The additional startup recording has closed the brief Godot splash sampling gap.

Published Release: https://github.com/seiya058904/mochi-arcade/releases/tag/v1.1.0.
New immutable tag 4f5d7f78159497f6f6d53d06d4acc16685c25c72 has the same runtime
and packaging as APK source 5672e40968f2169dddce72d82460b7a2bfdfa7c9. Anonymous
APK/checksum download, byte/signature/version and latest resolution pass.
Post-release main changes only document acceptance; final SHA/CI and clean sync
are independently recorded in the delivery report and local closeout JSON.
No private signing material went to GitHub. The owner declined AEHD startup;
keep it stopped. Physical device and quantitative phone metrics remain unavailable.

## Historical 2026-10-22 takeover and v1.0.0 release

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

- Godot `4.7.2.stable.official.ed1daf0bf` from the single shared copy at
  `D:\tools\godot\4.7.2\Godot_v4.7.2-stable_win64.exe` (deduplicated on
  2026-10-22 so two Godot projects do not each carry 173 MB; `scripts_tools/godot.ps1`
  uses it by default and `MOCHI_GODOT` still overrides). The local
  `.local/toolchain/...` path remains a fallback; official archive and export
  templates are retained with `SHA512-SUMS.txt`.
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
- Run [39700272044](https://github.com/seiya058904/mochi-arcade/actions/runs/39700272044)
  on `6240595`: 18 suites, APK build and edge-target taps pass; Fruit Drop
  completes Back and its first paused return, then the cycle-2 background return
  is again a fully black frame, byte-identical to the run-2 black PNG. Still
  black after 5 s; a new surface cycle recovers the visible pause sheet with the
  same PID. Two independent takeover-code sessions now reproduce the same blocker,
  and both maximum pools pass again (Balls 3.62 FPS, Jelly 5.10 FPS, saves
  restored). Release remains BLOCKED; the next useful evidence needs a physical
  phone or hardware-GPU host.
- Local AVD retry (2026-10-22): a bounded 8-minute software-only boot never left
  `emulator-5554 offline`; retained as `local-avd-attempt.json`. No install was
  attempted.
- Second AVD attempt (2026-10-22, later): Hyper-V/WHPX features are Disabled and
  no AEHD driver was installed. Google AEHD 2.2 was downloaded and installed with
  UAC consent, but the driver fails to start with error 1450 (insufficient
  resources) because `hvservice` holds the virtualization state (`sc stop
  hvservice` returns 1052; stopping the LDPlayer `Ld9BoxSup` driver did not clear
  the failure). No reboot was run. AEHD was changed to DEMAND_START so it will not preempt LDPlayer
  at boot. During diagnosis the LDPlayer service and `Ld9BoxSup`/`Ld9BoxNetLwf`
  drivers were stopped; they did not restart at runtime and the LDPlayer instance
  did not launch, so a reboot is required to restore LDPlayer and to test AEHD
  after the virtualization state is reset. AVD automation stayed NOT_RUN; the user
  deferred it.
- Physical-device retest (2026-10-22): the user reported no problems on the four
  requested checks; phone/OS/resolution, captures, per-check notes and the on-phone
  hash were not supplied. Recorded as user evidence in `PLAYTEST_FEEDBACK.md` and
  `docs/evidence/physical-device-user-report-2026-10-22.json`; A05/A09/A12 are not
  marked PASS by it alone.
- Hardware-GPU API 34 signed-byte acceptance (2026-10-22, this session): after the
  user reboot, the second AVD attempt was resolved by starting AEHD 2.2
  (`sc start aehd`, exit 0) and booting a CI-matching AOSP API 34 x86_64 AVD
  (`Mochi_CI_API34`, default image, pixel_2 profile, 720x1280/320, 2 GB, 2 cores)
  with `-gpu host` on the AMD RX 7900 XT. The exact signed bytes (SHA-256
  `2b459f5c...`) passed `scripts_tools/android_smoke.py --release`: eight games x
  three background returns, 101 non-blank frames, same PID, pause checkpoints equal,
  force-stop restore, zero-score restart, settings, same-signature reinstall save
  preservation, launcher icon, edge taps and the first music loop; 43
  `EGL_BAD_SURFACE` warnings occurred only while backgrounded and no runtime error
  was recorded. `android_load.py --release` also passed: 64 Balls 55.55 presented
  FPS (p50 16.679 ms, p95 33.166 ms) and Jelly 60.0 FPS (p95 17.199 ms) with exact
  save restoration. Evidence: `docs/evidence/android-api34-hostgpu-2026-10-22/`.
  This is a controlled emulator, not a physical phone; physical FPS/thermal
  acceptance is UNVERIFIED.
- Harness timing fixes: `scripts_tools/android_smoke.py` now re-establishes a
  paused Bouncy Balls round with a fast system Back while the served ball is still
  rising, proves foreground input with Resume followed by the in-game pause button,
  and refreshes the paused-round baseline after a natural result before the
  force-stop restore check. All visibility, blank-frame, save and PID assertions
  are unchanged; the hosted `d7f2650` run failed at the old restore precondition
  and did not reproduce a blank return.

## Owner-approved A14 exception, splash rebuild and v1.0.0 public release (2026-10-22)

- Owner decision: accept a scoped exception for the GitHub-hosted Ubuntu Mesa
  llvmpipe Android emulator background-return blank frame; no self-hosted GPU
  runner. A14 is recorded as `OWNER_APPROVED_ENVIRONMENT_EXCEPTION`, not PASS.
  Retained failure: run 39716897550 on `90ee172` failed at
  `01-fruit_drop-repeat-3-background-return` with blank frame
  `cfc80ccb...`; raw evidence and FAIL status are kept.
- Final signed APK rebuilt with the existing release identity after adding the
  custom Mochi boot splash: SHA-256
  `8fcc1ebc83cb9cb8e8947a1a33bef9cba9222b9ac775fafdcd7d3d5cd85d473c`,
  78,467,820 bytes; certificate unchanged. The custom splash uses
  `assets/art/boot-splash.png` (bunny, macaron, cream background), the
  `project.godot` boot-splash settings and cream splash/window colors in
  `export_presets.cfg`. No Godot default logo, progress bar, fake percentage or
  artificial delay was observed.
- Final verification: 18/18 required suites PASS; hardware-GPU API 34 signed-byte
  smoke PASS (8 games x 3 returns, 101 non-blank frames, restore/reinstall,
  first music loop) and load PASS (64 Balls 55.43 FPS, Jelly 60.0 FPS, save and
  backup restored); first launch 463 ms, cold start 408 ms, warm start 79 ms,
  with screenshots and screen recordings retained in
  `docs/evidence/android-api34-final-splash-2026-10-22/`. Physical-phone
  quantitative performance remains UNVERIFIED.
- Public release: README replaced with the illustrated English version
  (real screenshots, install, build, license, release link), `LICENSE` added,
  release notes updated; public-safety audit covered history, Actions logs and
  artifacts (no keys/tokens/PII; debug-only dev APKs), and the repository was
  switched to public in place. Final run 39724258963 on `2d45caf` failed only at
  the hosted software-rendered black frame (A14 exception); the suites, APK build
  and load phase passed.
- Published release: https://github.com/seiya058904/mochi-arcade/releases/tag/v1.0.0
  — tag `v1.0.0` → `2d45caf40d8334c4c9cc1567164db749d983c7ee`, assets
  `MochiArcade.apk` (78,467,820 bytes, SHA-256 `8fcc1ebc...`) and
  `SHA256SUMS`. Unauthenticated download, byte/signature/package/version checks
  and GitHub README desktop/mobile rendering passed. Physical-phone quantitative
  performance remains UNVERIFIED and disclosed.

## Exact next actions (post-release)

1. Keep the release tag `v1.0.0` fixed at `2d45caf`; any further documentation
   commit after this one must be labelled post-release and must not be described
   as changing the signed APK.
2. If a physical USB-debugging phone becomes available, run the automated
   signed-byte/frame-time acceptance and update A09 from UNVERIFIED.
3. If a hosted software-rendered black-return fix is later proven, remove the
   A14 exception only with new retained evidence; do not delete the historical
   failed runs.
4. Do not upload the release private key to repository secrets; keep the existing
   local signing identity for any future update.
