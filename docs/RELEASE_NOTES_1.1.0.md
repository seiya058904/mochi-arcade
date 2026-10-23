# Mochi Arcade 1.1.0 — unreleased candidate

**NOT_RELEASED:** exact signed-package Android runtime and v1.0.0 in-place upgrade
acceptance are currently blocked by the local emulator acceleration environment.
These notes do not announce a published release.

- Save failures are explained in English or Simplified Chinese. Pending progress
  stays in memory for a later retry; exiting after a failed save requires an
  explicit choice. Temporary writes and backup replacement are verified first.
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
must be installed over v1.0.0 without uninstalling to preserve local data; the
upgrade must still be verified before publishing. Uninstalling removes app data.
Physical-phone thermal/battery/60/120 Hz metrics remain unverified. The prior
scoped hosted llvmpipe A14 exception and all historical failed evidence remain.
