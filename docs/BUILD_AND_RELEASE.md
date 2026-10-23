# Build and release

Current source: 1.1.0 / Android versionCode 2, **NOT_RELEASED**. The public
v1.0.0 release is intact. See [iteration status](ITERATION_1.1.md) for the current
Android host blocker and exact release continuation. Local signing works; private
material must stay local. Nineteen suites are now required (the original 18 plus
the save-failure/terminal-Undo suite).

## Verified local toolchain

- Godot `4.7.2.stable.official.ed1daf0bf`, standard GDScript Windows x86_64.
- Official Windows archive and export templates checked against the release's
  SHA512-SUMS.txt before extraction; only matching Android templates installed.
- Temurin OpenJDK 17.0.20.1; Android SDK platforms 34/35/36 and Build Tools
  34.0.0/35.0.1/36.0.0 now available.
- The actual 4.7.2 APK template declares target/compile SDK 36 and min SDK 24.
  This differs from the online 4.7 export page's SDK 35 example; actual template
  metadata governs and Build Tools 36 was installed after inspecting the APK.
- Prebuilt APK export, Compatibility renderer, arm64-v8a + x86_64.

## Windows PowerShell

Set `MOCHI_GODOT` to the absolute path of the official 4.7.2 executable.
Python 3.12+ runs the required suite driver; it fails on runtime errors as well
as nonzero process exits. The driver retains individual logs under `.local/check-logs`. Configure
Godot Editor Settings > Export > Android with the installed JDK and SDK paths.

```powershell
./scripts_tools/godot.ps1 --headless --editor --import
python scripts_tools/run_checks.py --engine $env:MOCHI_GODOT
./scripts_tools/godot.ps1 --fixed-fps 60 --script tests/integration/visual_matrix.gd
./scripts_tools/godot.ps1 --headless --export-debug Android dist/MochiArcade-dev.apk
```

The capture script opens a real renderer and uses a separate temporary user-save
directory. It records desktop viewport images, not Android installation proof.

## Android verification

```powershell
adb devices -l
adb install -r dist/MochiArcade-dev.apk
adb shell am start -n io.github.seiya058904.mochiarcade/com.godot.game.GodotAppLauncher
```

Historical development tests encountered SwiftShader shader failures and
Lavapipe/host llvmpipe intermittent black background returns. Keep the original
raw FAIL reports in QA_REPORT; a later green run does not erase them. v1.0.0's
exact signed bytes passed API 34 hardware-GPU lifecycle/load acceptance on
2026-10-22 before publication, under the explicitly scoped hosted A14 exception.
The 2026-10-23 environment currently lacks working emulator acceleration;
unaccelerated host/SwiftShader processes fail before usable ADB. No system driver
or service was changed in this iteration. New signed-byte runtime/upgrade tests
remain BLOCKED; old and development APK acceptance do not satisfy those gates.

Actual audio mixer checks require a non-headless run:

```powershell
./scripts_tools/godot.ps1 --script tests/integration/audio_output.gd
python scripts_tools/audit_repository.py
```

## Stable publication gates

The release identity has been created outside Git under the current Windows user's
`.mochi-arcade/signing` directory. ACL inheritance is disabled; only that user and
SYSTEM have access. The random 256-bit password is stored using Windows DPAPI
CurrentUser protection. The key is reusable and must be preserved for updates.
Do not move the DPAPI file to another account and expect it to decrypt; a secure
external backup/recovery arrangement remains the owner's responsibility.

Public certificate SHA-256:
`de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b`

```powershell
# Reopen the existing protected key and export; never reinitialize an existing key.
./scripts_tools/sign_release.ps1 -Build
```

The helper supports `-SigningDirectory` and `-Keytool` for an explicitly selected
secure location/tool. `-InitializeKey` refuses existing material and is only for
first-time setup of a new signing identity. It restores all process environment
variables after use and does not persist plaintext credentials. Never add the
key or protected password to Git, logs, APK assets or release attachments.
v1.0.0 is already published. Any newly built 1.1.0 candidate still needs its own
exact-byte runtime and v1.0.0 upgrade acceptance before publication.

All eight games, Android touch/lifecycle acceptance and final-SHA CI must pass
before tagging. Then export the final SHA, compute SHA256SUMS, create a draft
release, independently download/verify bytes and signature, and publish.
Never replace an existing published tag or APK silently.

## Optional manual CI signing path (not authorized for secret upload)

The checked-in workflow defaults to development builds. Its optional manual
`release_candidate` input would consume two repository encrypted secrets:
`MOCHI_RELEASE_KEYSTORE_BASE64` and `MOCHI_RELEASE_PASSWORD`. Neither has been
uploaded. This task explicitly excludes uploading private signing material to
GitHub. Use the existing local key and DPAPI password instead.

The reviewed `build_ci_release.py` creates an exclusive mode-0600 temporary key,
exports a non-debuggable release APK, checks the expected public certificate, then
removes only that transient key in `finally`. It never writes the password to disk
or logs. The same helper was exercised locally, producing an APK signed by the
expected identity and leaving no transient keystore. The Android `--release`
verification path keeps the APK non-debuggable. Only the dedicated AOSP userdebug
emulator uses `adb root` to inspect its test saves; ordinary developer builds use
`run-as`. All eight captures still require visual review in addition to save checks.
No workflow or script creates a tag or publishes a Release automatically.

## Emulator graphics diagnostic

The default `graphics_backend=host` uses the emulator's host GLES route. Manual
runs can select `lavapipe` to reproduce the retained failing comparison. Both
remain software-rendered on the hosted runner. Host starts the image's existing Xvfb and
sets Mesa's `LIBGL_ALWAYS_SOFTWARE=true` and `GALLIUM_DRIVER=llvmpipe`; it installs
no new package, preserves all runtime assertions, and records the requested mode
plus actual adapter details in emulator.log. Host's a032fde comparison passed all
native paths and visual review, but still emitted EGL warnings; this is not proof
of a product fix or physical-GPU performance. Each game now requires three
background returns; final signed-byte acceptance must be repeated for each new release.
It does not enable release signing or consume signing secrets by default.

Sources: [Android emulator graphics modes](https://developer.android.com/studio/run/emulator-acceleration),
[Mesa environment variables](https://docs.mesa3d.org/envvars.html), and the
[hosted Ubuntu image inventory](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md).


## Authorized locally signed draft transport (2026-10-23)

For the 1.1.0 iteration the owner explicitly allowed an unpublished draft to
stage the locally signed APK before upgrade acceptance. Stable publication still
requires every applicable gate. This sequence exception changes no runtime gate
and uploads no private key, password or DPAPI material.

Dispatch `ci.yml` with `staged_release_id` and `staged_apk_sha256`. The isolated
`staged_bytes` job uses `contents:write` only because GitHub requires push-level
access to read an unpublished draft (the retained read-only attempt returned
HTTP 403). Checkout credentials are not persisted; the helper performs GET and
download operations only. The verification job remains `contents:read` and checks
the expected hash, original certificate, non-debuggable manifest and version.
It separately downloads the immutable public v1.0.0 APK and checks its hash.

On the disposable API 34 AOSP userdebug AVD it executes the full predecessor
smoke, an actual `adb install -r` upgrade with byte-preserved saves and eight
restored games, terminal Number Bloom Undo, damaged/read-denied save recovery,
ordinary uninstall, then an independent candidate clean-install smoke and load.
All eight games still require three background returns. Raw screenshots must be
reviewed; no assertion is skipped, failed guest is restarted or failure converted
to PASS. The historical A14 exception is unchanged. The local AEHD service must
remain stopped under the owner's explicit decision.
