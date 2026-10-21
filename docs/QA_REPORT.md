# QA report

Status: **PARTIAL** — six playable games, 2026-10-22.

Initial read-only audit on 2026-10-21 confirmed an empty work directory, no Git
root, Java 17, SDK 34 and an offline Android 34 AVD. Since then an actual Godot
project, production art, shared shell, six playable scenes and a debug APK have
been built. No stable release has been published.

Evidence must include command, actual environment, case counts, pass/fail,
seed/action sequence, screenshot/log path and unresolved limitations.

## Gate register

A01-A15 details: RELEASE_CHECKLIST.md. Physical Android: DEVICE_UNAVAILABLE.
Android emulator: BLOCKED; every observed `adb devices -l` shows offline.

## Executed checks

| Check | Result | Evidence |
| --- | --- | --- |
| Official engine / template SHA512 | PASS | Verified downloaded archives against official sums before extraction |
| Godot 4.7.2 import | PASS | Actual headless editor import; all current scripts/scenes/assets |
| Cake / 2048 / save rules | PASS, 14,278 assertions | evidence/logic-tests.json; canonical merges, 625 rows, 10,000 spawns, 1,500 cuts, corrupt save recovery |
| Current vertical-slice integration | PASS, 47 assertions | evidence/vertical-slices.json; pause, retry, terminal state, undo RNG, session restore, 30 switches, lifecycle regression |
| Fruit physics/rules | PASS, 29 assertions | evidence/fruit-drop-tests.json; actual physics contacts through all 8 tiers, duplicate suppression, pause, save, overflow fixture and retry |
| Fruit normal-action playthrough | PASS | evidence/fruit-playthrough-rendered.json; 251 normal drops, score 23220, highest tier 7, natural overflow, max 45 fruit, immediate empty restart |
| Bubble geometry/runtime | PASS, 1,364 assertions | evidence/bubble-garden-tests.json; hex adjacency, cluster/floating connectivity, active-color pool, continuous shots, save/seed restore, loss/retry, aim/landing agreement at 30/60/120 Hz |
| Bubble normal-action playthrough | PASS, rendered + headless | evidence/bubble-playthrough-*.json; seed 5402, 33 hinted shots clear 5 gardens; random-input seed 3029 reaches natural loss after 73 shots total; 198 pops, 13 drops, 148 wall bounces, score 2740, retry playable. Reports and complete action traces agree between backends. |
| Hop reachability | PASS, 550,008 assertions | evidence/hop-reachability-tests.json; seeds 1-2000, 25 platforms each (50,000), capped difficulty and edge-biased preceding landings; analytic world-circle / projected-ellipse oracle; minimum charge interval 0.385934 s (seed 1844) |
| Hop runtime/input | PASS, 47 checks | evidence/mochi-hop-tests.json; short/center/long holds, explicit edge margin, streak scoring, no airborne duplicate launch, pause/cancel/multitouch/background/reload, three frame rates and three viewport sizes |
| Hop actual scene input replay | PASS, rendered + headless | evidence/hop-playthrough-*.json; seed 1729, real Godot mouse-down/up routing, 40 successful hops / score 130, natural short-hold miss and immediate playable retry. Per-hop measured charge/frame trace retained. |
| Hop native desktop smoke | PASS for entry/short hold/miss/retry | Native window entered from home, mouse drag-hold/release visibly launched, too-short hold naturally missed, One more go restored the ready platform. desktop-hop-native.png retains the miss. Successful calibrated holds are covered by the separate input replay, not claimed as manual phone play. |
| Trio construction/solver | PASS, 439,506 assertions | evidence/trio-solver-tests.json; 500 seeds at levels 1/4/10 (1,500 boards), construction witness plus independent search replay, independent rectangle occlusion and modulo-three tray oracle; max 176 search nodes; seventh matching tile clears before the capacity check |
| Trio runtime/recovery | PASS, 23 checks | evidence/tile-trio-tests.json; covered corners, rapid duplicate taps, paused transit, atomic undo of a completed match, persisted history, solver-confirmed hint, natural full tray, free result-button undo, next level and restart |
| Trio actual input replay | PASS, rendered + headless | evidence/trio-playthrough-*.json; seed 701, 180 normal hinted picks clear five shops for 2100 points; seven further legal low-match picks fill the tray; real result-button click recovers six slots; restart playable. Full trace retained. |
| Audio shutdown | PASS on desktop reruns | evidence/audio-shutdown.json; verbose baseline identified 3 AudioStreamWAV + 8 AudioStreamPlaybackWAV resources. Explicit player stop plus real-time mixer drain produced zero leaked instances on Trio, and no warning on Hop. |
| Desktop rendering | PASS for current screens | evidence/desktop-*.png files, AMD RX 7900 XT Compatibility renderer |
| Native desktop input | PASS for current four games | Actual home/settings clicks, 2048 left/up swipes and merge score 4, Cake placement/cut and score 1, Fruit aim/release and next preview, focus-loss pause/resume; Bubble real mouse drag/release pops four and scores 40 (desktop-bubble-native.png) |
| Debug APK export | PASS | dist/MochiArcade-dev.apk, local ignored artifact |
| Debug APK signature | PASS, debug only | v2/v3 schemes; certificate 2207476872571c99d83537c73a9e3b38d9b66c5d04bef7ad3ccd5ebbe122b0ab |
| APK metadata | PASS | io.github.seiya058904.mochiarcade, min API 24, target 36, arm64-v8a+x86_64; VIBRATE only |
| Android install / launch / touch | BLOCKED | No online device; not claimed verified |
| Audible quality / physical-device performance | NOT_RUN | Requires actual listening and Android runtime |
| CI / release | PASS for 7faa254 / NOT_PUBLISHED | [Run 39640559280](https://github.com/seiya058904/mochi-arcade/actions/runs/39640559280): all five-game checks and debug Android build passed. Trio checkpoint still needs its own CI run. |

## Found and fixed

- Thin Latin/CJK fonts: set numeric OpenType weight tags and explicit CJK variable fallbacks.
- Generated atlas cut the bunny ears: individually inspected sprite bounds replaced uniform grid assumption.
- Long help text overflowed: reapply label extent after enabling word wrapping.
- First Android export failed because ETC2/ASTC import was disabled: enabled required project setting and exported successfully.
- Template targets SDK 36, beyond the documentation example: installed matching SDK/Build Tools 36.
- Live focus change during child setup caused a paused game with no overlay (`add_child` busy).
  Lifecycle changes now run deferred; a regression reproduces nested tree notification
  and requires a visible, recoverable pause. Native focus loss now shows a recoverable pause; Number Bloom swipes merge and score correctly.
- Headless logic shutdown retained active dummy audio playback: headless mode now avoids playback on the dummy audio backend; actual audio remains outside
  headless rule coverage. Desktop/Android playback is unchanged.
- Bubble wide-screen sweep regression found side gaps beyond the fixed nine-column grid.
  Walls now stay beside that grid; all 15 angle/frame-rate pairs hit their predicted cell.
- Bubble first rebound fixture waited 1.4 seconds for a roughly 1.6-second shot; replaced
  the wait with a bounded 240-physics-frame completion loop and retained the collision assertion.
- Seeded replay used to initialize the RNG after the first color was selected. A shared
  optional seed now initializes before scene readiness, and restored sessions preserve
  their original run seed. Rendered/headless bubble action traces now agree exactly.
- Small generated bubbles shimmered when downsampled: enabled mipmaps and inspected
  the actual 450x800 result. Moved the next-shot label above its preview to clear the footer.
- Rendered accelerated runs retained audio resources at shutdown. Trio reproduced
  eleven leaks (3 WAV streams, 8 playbacks). Stopping streams in `_exit_tree` was too late
  for the mixer thread. App exit now stops playback and waits 60-250 ms of actual wall time
  for the mixer before quitting; rendered test harnesses use the same drain. Trio verbose
  and Hop reruns exit cleanly. Pausing stops short sound effects instead of resuming old tails.
- Reproduced canceled-touch launch: `InputEventScreenTouch.canceled` previously took the
  normal release path. Shared input now cancels the owned gesture instead. A right mouse
  button release also cannot terminate an active left-button hold. Regression retained.
- Hop feedback originally overlapped its bottom instructions. Shared toasts now temporarily
  replace the score row with an opaque, wrapped message; gameplay stays unobstructed.
- The reachability test initially compared float32 Vector2's 1.2000000477 endpoint to a
  float64 1.2 literal. Corrected that endpoint comparison with approximate equality;
  unchanged sampled landings, geometric oracle and minimum-window assertions all pass.
- Trio's first runtime fixture incorrectly assumed the independent solver's first three
  picks always form a trio; it may legally mix motifs. The atomic-match fixture now uses
  the known legal constructed triple; the full independent-solver replay remains required.
- Trio's initial result-button assertion ran before deferred GUI activation. The screenshot
  already showed the correct six-slot recovery; the test now waits two scene iterations
  and still requires a dismissed result overlay and a playable six-slot tray.

## Tile Trio construction and recovery

Every board has 36 tiles on three genuinely overlapping layers. A seeded legal removal
order is constructed first, then each consecutive triple receives one motif. The player
does not see that witness. An independent memoized search uses only blockers, occupancy
and tray counts; tests replay both solutions and independently check rectangle overlaps
and modulo-three counts. Levels use 6-8 distinct original motifs. Seven unmatched slots
end the round; a completing trio clears before that limit is evaluated. Free undo restores
the entire preceding board/tray/score snapshot, even after a match or a full-tray result.
History persists across reload. Free hints only mark the first move of a verified solution;
an unsolved/budget-limited state suggests undo rather than inventing a safe move.

## Hop rules and persistence

Hold duration maps linearly from 70 to 350 world units across 0 to 1.2 seconds,
then caps without launching automatically. Platforms shrink from radius 62 to a
floor of 48; six world units of edge forgiveness snap to four units inside the top.
Center error <=14 gives 3, 4, 5, 6, then at most 7 points; ordinary landings give 1
and reset the streak. Altitude is visual only; projected ground-foot position decides
landing. Pause freezes a flight in memory; process reload deliberately returns to
the last safe foot with the same target, score, RNG and seed, with no held input.

Workflow context constraint checked against
[GitHub's context availability reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability).

## Android blocker evidence

Existing API 34 x86_64 AVD; emulator 37.1.11. `-accel-check` exits 1 with
code 6: "Android Emulator hypervisor driver is not installed on this machine".
Default acceleration fails. Software renderer with `-accel off`, no snapshots,
and direct long-running execution all remain offline. No installation or input
claim follows from a successful export. User has been asked whether a USB-debugging
Android phone can be connected; independent development continues.

## Physics replay boundary

The same Fruit seed 817 and input seed 4182 reached natural overflow in both
rendered and headless runs, but chaotic rigid-body contacts diverged: rendered
251 drops / 23220 points / max 45 bodies; headless 344 drops / 36740 points / max 47.
Both reached tier 7 and restarted empty. Separate original reports are preserved
as fruit-playthrough-rendered.json and fruit-playthrough-headless.json. This is
not a claim of bit-identical physics across rendering backends.
