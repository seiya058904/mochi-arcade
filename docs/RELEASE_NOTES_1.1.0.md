# Mochi Arcade 1.1.0 — unreleased candidate

Prepared release notes; publication follows final startup/CI review. The exact
original-signature APK has passed hosted API 34 runtime and v1.0.0 upgrade tests.

- Save failures are explained in English or Simplified Chinese. Pending progress
  stays in memory for a later retry; exiting after a failed save requires an
  explicit choice. Temporary writes and backup replacement are verified first.
- Unreadable saves are protected from replacement. Check file access and reopen
  the app after a read error; new progress is explicitly marked unsaved.
- Recover damaged record, setting and session fields from the valid backup while
  preserving valid newer fields in the primary save.
- Undo the last move directly from Number Bloom's full-board result screen.
  The previous board/score/random state returns and the earned best is retained.
- Stop rebuilding stationary canvases in Number Bloom, Tile Trio, Bubble Garden
  and Mochi Hop. Same seeded desktop captures are pixel-identical; no phone
  battery or FPS improvement is claimed.

Eight offline games, original artwork, standard 2048 rules and the approved
Bouncy Balls sizes remain unchanged. Android package:
`io.github.seiya058904.mochiarcade`; versionName `1.1.0`, versionCode `2`;
arm64-v8a and x86_64, Android 7.0/API 24 minimum. Only VIBRATE is requested.

The candidate uses the original release signing identity. An official update
must be installed over v1.0.0 without uninstalling to preserve local data; an actual in-place
upgrade has preserved eight rounds, records and settings on the test AVD. Uninstalling removes app data.
Physical-phone thermal/battery/60/120 Hz metrics remain unverified. The prior
scoped hosted llvmpipe A14 exception and all historical failed evidence remain.

Validation: 19 suites, including 48 save/Undo failure-path assertions; 1,500 Tile
Trio boards and 50,000 Mochi Hop targets; 64 bilingual desktop layout captures.
The signed API 34 AOSP software-rendered emulator passed all eight games with
three background returns each, force-stop recovery, first audio-loop survival,
maximum pools, damaged-save recovery and ordinary uninstall. Native captures are
reviewed separately from automated raw reports. These are emulator results; no
physical-phone performance or universal Android-device compatibility is claimed.
EGL background-surface warnings and historical failures remain documented.
