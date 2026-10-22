# Playtest feedback and Bouncy Balls layout revision

Updated 2026-10-22 during takeover. This file records the user's own phone
playtest, the corrected interpretation of the one P1 complaint, the measured
before/after layout change and its evidence boundaries. It never replaces the
gates in `docs/RELEASE_CHECKLIST.md`.

## User phone playtest (2026-10-22)

The user installed a Mochi Arcade APK on a physical Android phone and played all
eight games by hand. The APK SHA-256, build commit, phone model, refresh rate and
frame timings were not supplied, so this is subjective hands-on feedback and not
an install/lifecycle/performance acceptance of any specific signed byte file.

| Game | User feedback | Takeover action |
| --- | --- | --- |
| Fruit Drop | Acceptable ("还可以") | Keep current art and rules; no speculative rework |
| Bubble Garden | Acceptable ("还行") | Keep |
| Cake Stack | Acceptable ("还行") | Keep |
| **Bouncy Balls** | **Balls are clearly too small; the bricks above and the multiplier gates / bouncers in the middle are also too small and not prominent. The user explicitly clarified the bottom paddle is NOT the problem.** | **P1: enlarge the play-field objects and their proportions; keep the paddle size/handling; verify collision, 64-ball behaviour and Android view** |
| Tile Trio | No problems | Keep |
| Mochi Hop | No problems | Keep |
| Number Bloom | No problems | Keep |
| Jelly Slice | No real problems | Keep |

The earlier takeover draft's "widen the paddle by 20-35%" reading is withdrawn:
the paddle was explicitly not the complaint and is unchanged.

## What was wrong (measured on the production code)

Design canvas 720x1280; the play field is 648x886 logical pixels at the tested
720x1280 Android profile (720x1280 at 320 dpi, safe insets applied). Before the
revision:

- Ball: diameter 22 px = 3.40% of the field width, 3.06% of the screen width.
- Bricks: 89.33x37 px in a 6x4 grid; 13.79% of the field width, wall height 175 px
  (19.75% of the field height).
- Multiplier gates: 116x34 px (17.9% of the field width, 3.8% of the field height).
- Bumpers: visible/collision radius 27 px, diameter 54 px (8.33% of the field width).
- Paddle: 172x19 px, y = area.y - 76 (unchanged and kept).
- The lower half of the field was mostly empty: the brick wall ended at y=251 of
  an 886-px field, and the two gates sat at 57%/69% of the field height.

The complaint was therefore a real scale/composition problem, not a paddle-width
problem.

## Revision applied (single coordinated layout change)

Source: `scripts/games/bouncy_balls.gd`, tests: `tests/integration/bouncy_balls.gd`,
evidence capture: `tests/integration/balls_layout.gd`.

| Element | Before | After | Change |
| --- | --- | --- | --- |
| Ball diameter | 22 px (3.40% field width) | **32 px (4.94% field width, 4.44% screen width)** | +45% diameter |
| Brick size | 89.33x37 px, 6x4 grid | **143.75x44 px, 4x6 grid** | +61% width, +19% height |
| Brick wall span | 175 px (19.75% of field height) | **289 px (32.62%)** | +65% covered height |
| Multiplier gate | 116x34 px (17.9% field width) | **150x46 px (23.15% field width)** | +29% width, +35% height |
| Bumper diameter | 54 px (8.33%) | **68 px (10.49%)** | +26% |
| Paddle | 172x19 px, y = area.y - 76 | **172x19 px, y = area.y - 76, same drag clamp** | **Unchanged** |
| Brick count / pool | 24 bricks / 64 balls | 24 bricks / 64 balls | Unchanged |

The 24-brick count is unchanged so the save schema (`health` array of 24) and
wave clearing rules are untouched. Gate/bumper hitboxes are derived from the same
constants used for drawing, so visual and collision geometry stay identical; the
multipliers still create real extra balls, and the fixed 64-slot pool, excess +5
scoring, gate claims, swept collision, anti-trap rebound, save/restore and wave
recall are unchanged. Only the shared small-button hit-region change from the
previous session was also carried forward; it does not change visible layout.

## Evidence (before / after)

Desktop Compatibility renderer at the 720x1280 design aspect (450x800 window,
same logical layout), fixed seed 881, the same capture script for both runs and
the equivalent 64-ball fixture adapted to each brick grid:

- `docs/evidence/bouncy-balls-before-opening.png` / `bouncy-balls-after-opening.png`
- `docs/evidence/bouncy-balls-before-gate.png` / `bouncy-balls-after-gate.png`
- `docs/evidence/bouncy-balls-before-full-pool.png` / `bouncy-balls-after-full-pool.png`
- Measurements: `docs/evidence/bouncy-balls-layout-before.json` and
  `bouncy-balls-layout-after.json`.

Actual Android development-build captures at 720x1280 (run 39673516558 on
`7a48d0e`, the pre-change code; from the retained artifact):

- `docs/evidence/bouncy-balls-android-before-ready.png` (initial view)
- `docs/evidence/bouncy-balls-android-before-input.png` (after real ADB input)
- `docs/evidence/bouncy-balls-android-before-full-pool.png` (64-ball load burst)

Post-change Android captures at the same 720x1280 profile come from development
run 39698026180 on `32df767` (Mesa llvmpipe software renderer):

- `docs/evidence/bouncy-balls-android-after-ready.png` (initial enlarged field)
- `docs/evidence/bouncy-balls-android-after-packed-pool.png` (64/64 balls, packed)
- `docs/evidence/bouncy-balls-android-after-full-pool.png` (64/64 balls, spread)

They show the 4x6 large-brick wall, the 150x46 multiplier gates and the 68-px
bumpers on the actual Android viewport, with the paddle unchanged. These are
software-emulated AOSP Android 14 views, not physical-phone captures.

## Regression results after the revision

- `tests/integration/bouncy_balls.gd`: PASS, 236,607 checks. New layout
  invariants assert ball >= 4.5% of field width, bricks >= 18% width / 4.5%
  height, gates >= 20% width / 4.5% height, bumpers >= 9% width, brick wall
  >= 28% of field height, and that the paddle keeps exactly 172x19 at y =
  area.y - 76. Gate multiplication, 64-ball saturation, paddle endpoints at
  30/60/120 Hz, restitution anti-trap, save/reload, changed viewport, clear/loss
  and the 60-second 64-ball stress all pass with zero collision-limit hits.
- `tests/integration/balls_playthrough.gd` (rendered, real mouse input only,
  seed 881): PASS. 4 waves cleared, score 4,975, 126 catches, 233 brick hits,
  225 bumper hits, x2/x3 gate passes 58/80, real 64-ball maximum, 127 recycled,
  natural loss and playable retry; no state injection.
- All 18 required suites: PASS (`docs/evidence/required-checks.json`), with 995
  collection checks.
- Android physical-device recheck of the new sizes: **PHYSICAL_DEVICE_RECHECK_PENDING**
  because no Android phone is attached to this machine. The user's opinion of the
  old APK is not evidence that the new sizes are accepted; no such claim is made.

## Other seven games

No gameplay, layout or art change was made to Fruit Drop, Bubble Garden, Cake
Stack, Tile Trio, Mochi Hop, Number Bloom or Jelly Slice in this revision. Their
required suites and playthrough replays remain unchanged and pass.

## Evidence boundaries

1. The user's installed APK predates this revision and its bytes are unknown; the
   "before" Android images above are the retained CI development build, labelled
   as such.
2. Desktop captures at the 720x1280 aspect and Android 720x1280 captures are
   distinct evidence classes. Neither is a physical-phone performance claim.
3. The measured sizes are logical design pixels. On the tested 720x1280 / 320 dpi
   profile 96 design pixels equal 48 dp; the revision's ball is 32 design px and
   is not described as a universal physical-size guarantee for other densities.
4. A freshly signed `MochiArcade.apk` rebuilt from the final commit must still be
   installed and rechecked on a real device before the stable release gate can
   close. Until then A12/A15 remain open.
