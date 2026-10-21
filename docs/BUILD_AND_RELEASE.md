# Build and release

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
adb shell am start -n io.github.seiya058904.mochiarcade/com.godot.game.GodotApp
```

The latter two commands have **not yet succeeded**: the available AVD remains
offline. `emulator -accel-check` reports missing hypervisor driver. Hardware
acceleration disabled, software renderer and direct long-running launch were
also tried without obtaining an online Android system. No OS driver or boot
security setting has been changed. A connected Android device can unblock this. CI also prepares a dedicated API 34
standard AOSP emulator with full graphics and KVM; see QA_REPORT for actual outcomes.

## Stable publication gates

No stable release key has been generated yet. Before release, generate and keep
a private external keystore, protect its password using Windows DPAPI, inject
`GODOT_ANDROID_KEYSTORE_RELEASE_PATH/USER/PASSWORD` at export, verify the actual
certificate and never commit keys. The final file must be `dist/MochiArcade.apk`.

All eight games, Android touch/lifecycle acceptance and final-SHA CI must pass
before tagging. Then export the final SHA, compute SHA256SUMS, create a draft
release, independently download/verify bytes and signature, and publish.
Never replace an existing published tag or APK silently.
