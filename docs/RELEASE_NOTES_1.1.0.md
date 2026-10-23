# Mochi Arcade 1.1.0

A safer save system, a second chance in Number Bloom, and less work while four
puzzles are standing still.

- Explain save failures in English and Simplified Chinese. Keep pending progress
  for retry and make exiting with unsaved progress an explicit choice.
- Verify temporary and backup writes; protect unreadable saves from replacement;
  recover damaged fields from a valid backup while preserving valid newer data.
- Undo the last move directly from Number Bloom's full-board result screen,
  restoring the board, score and random state while retaining the earned best.
- Avoid rebuilding stationary canvases in Number Bloom, Tile Trio, Bubble Garden
  and Mochi Hop. Same-seed desktop comparisons were pixel-identical. No phone
  battery or FPS improvement is claimed.

All eight games, original artwork, English/Simplified Chinese, offline play and
approved Bouncy Balls dimensions remain intact. No ads, account, purchases or
network permission are introduced.

## Install or update

Download **MochiArcade.apk** below. Android 7.0/API 24 or later; arm64-v8a and
x86_64. Package `io.github.seiya058904.mochiarcade`, versionName `1.1.0`,
versionCode `2`. Only the VIBRATE permission is requested.

Install over v1.0.0 **without uninstalling** to retain local progress. The APK uses
the same original certificate; an actual in-place upgrade preserved both save
files, eight game rounds/records and settings on the isolated test emulator.
Uninstalling removes app data. New installs, damaged-save recovery and ordinary
uninstall were also tested.

## Verification and limits

- Godot 4.7.2: 19 suites pass, including 48 save/Undo reliability assertions;
  1,500 Tile Trio boards and 2,000 Mochi Hop seeds / 50,000 targets retained.
- Three portrait ratios in both languages: 64 desktop captures reviewed. Four
  idle canvases rebuilt 0 times instead of 180 over matched 180-frame samples;
  GPU draw calls were unchanged. Integrity checks add disk I/O cost.
- These exact signed bytes passed Android 14/API 34 AOSP x86_64 software-emulator
  installation, v1.0.0 upgrade, eight games with three background returns each,
  input/pause/force-stop restore/restart, settings, first audio-loop survival,
  64-ball/12-fruit loads, backup recovery and uninstall. Native screenshots were
  reviewed separately from the automated reports.
- Hosted software-renderer presentation rates are not phone FPS. No physical
  device was available for this version; phone 60/120 Hz, heat, battery and other
  API/device coverage remain unverified. Android 7+ is the declared minimum,
  not a claim that every supported device was tested.
- Background EGL warnings and earlier failed black-frame/emulator-host runs are
  retained in the repository. This passing signed run does not require or expand
  the historical scoped A14 environment exception and is not a driver-fix claim.

APK: **78,471,916 bytes**, non-debuggable, v2/v3 signed, 16 KiB zip/ELF aligned.
SHA-256: `9676db2f517e9c206317bfce045259294e36c5014b294f155db549b81f263320`

Original certificate SHA-256:
`de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b`

Built from `5672e40968f2169dddce72d82460b7a2bfdfa7c9`. Release source/tag
`4f5d7f78159497f6f6d53d06d4acc16685c25c72` has identical runtime, assets and export
configuration; intervening changes contain acceptance tools and evidence only.
See the [iteration audit](https://github.com/seiya058904/mochi-arcade/blob/main/docs/ITERATION_1.1.md)
and [exact signed acceptance run](https://github.com/seiya058904/mochi-arcade/actions/runs/39930890985).
The [final source signed replay](https://github.com/seiya058904/mochi-arcade/actions/runs/39934863776)
also passes and includes reviewed native custom-startup video.

The immutable v1.0.0 tag and assets are preserved.
