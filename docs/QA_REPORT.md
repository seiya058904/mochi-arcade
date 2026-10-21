# QA report

Status: **PARTIAL** — eight playable games, 2026-10-22.

Initial read-only audit on 2026-10-21 confirmed an empty work directory, no Git
root, Java 17, SDK 34 and an offline Android 34 AVD. Since then an actual Godot
project, production art, shared shell, eight playable scenes and a debug APK have
been built. No stable release has been published.

Evidence must include command, actual environment, case counts, pass/fail,
seed/action sequence, screenshot/log path and unresolved limitations.

## Gate register

A01-A15 details: RELEASE_CHECKLIST.md. Physical Android: DEVICE_UNAVAILABLE.
Local Android emulator: BLOCKED by absent acceleration. Hosted KVM passes; two
boot attempts failed on disk space. Revised standard AOSP environment awaits execution.

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
| Balls collision / pool / lifecycle | PASS, 236,650 checks | evidence/bouncy-balls-tests.json; 1,000 independently checked sweeps, 2,000 outward curved rebounds, x2/x3 actual offspring, claim inheritance, excess +5 scoring, paddle endpoints at 30/60/120 Hz, pause/save/changed viewport/clear/loss/retry/unload; fixed 64-slot pool |
| Balls sustained stress | PASS, Windows simulation | 60 simulated seconds maintaining 64 balls; finite motion, bounded speed/effects, zero exhausted collision iterations, 27 to 28 nodes (one shared toast). Measured headless physics p50 705 us / p95 1726 us / max 4844 us on this run. These are not rendering frame times or Android performance. |
| Balls ordinary-input replay | PASS, rendered + headless | evidence/balls-playthrough-*.json; seed 881, actual Godot mouse press/drag, 4 waves, 134 catches, 241 brick hits, x2/x3 gate crossings 77/67, real max 64 balls, 164 recycled, score 4820, natural loss/retry. Outcomes agree; screenshot synchronization differs by one frame. Five desktop captures visually reviewed. |
| Jelly rules / lifecycle / stress | PASS, 7,224 checks | evidence/jelly-slice-tests.json; 600px single-segment sweep, release-segment multi-cut, one-shot claim, x5 combo cap/expiry, invalid coordinates, pause/cancel/secondary finger, analytic trajectory at 30/60/120 Hz, save/RNG, no-penalty misses, explicit finish/retry, reduced motion, full unload. Saturation: 60 seconds / 108,000 swipe events, exact caps 12 fruit/32 halves/24 trail/64 particles, no node growth. |
| Jelly ordinary-input replay | PASS, rendered + headless | evidence/jelly-playthrough-*.json; seed 2047, 60 seconds, 157 launched / 150 sliced / 7 naturally missed, score 2400, max 7 fruit / 16 halves. Actual Finish break and One more go button clicks succeed. Four rendered captures reviewed, including original matching whole/cut surfaces. |
| Audio shutdown | PASS on desktop reruns | evidence/audio-shutdown.json; verbose baseline identified 3 AudioStreamWAV + 8 AudioStreamPlaybackWAV resources. Explicit player stop plus real-time mixer drain produced zero leaked instances on Trio, and no warning on Hop. |
| Desktop rendering | PASS for current screens | evidence/desktop-*.png files, AMD RX 7900 XT Compatibility renderer |
| Native desktop input | PASS for current four games | Actual home/settings clicks, 2048 left/up swipes and merge score 4, Cake placement/cut and score 1, Fruit aim/release and next preview, focus-loss pause/resume; Bubble real mouse drag/release pops four and scores 40 (desktop-bubble-native.png) |
| Debug APK export | PASS | dist/MochiArcade-dev.apk, local ignored artifact |
| Debug APK signature | PASS, debug only | v2/v3 schemes; certificate 2207476872571c99d83537c73a9e3b38d9b66c5d04bef7ad3ccd5ebbe122b0ab |
| APK metadata | PASS | io.github.seiya058904.mochiarcade, min API 24, target 36, arm64-v8a+x86_64; VIBRATE only |
| Android install / launch / touch | BLOCKED | No online device; not claimed verified |
| Audio output | PASS measured Windows mixer / phone UNVERIFIED | evidence/audio-output.json: 48 kHz captured output, eight tone peaks 0.101-0.103, eight-voice burst 0.438, music peak 0.0090, muted/paused output exactly zero. No subjective listening or phone-speaker claim. |
| Repository credential/provenance review | PASS bounded static audit | evidence/security-audit.json: 13 commits, 259 text blobs, known credential patterns; 80 binary/large blobs counted separately. No findings or runtime network/process calls; not exhaustive secret detection. |
| CI / release | PASS for da1d397 / NOT_PUBLISHED | [Run 39647458113](https://github.com/seiya058904/mochi-arcade/actions/runs/39647458113): all eight-game checks and debug Android build passed. Later hosted runtime attempts fail on disk, as retained below. |
| Collection lifecycle / adverse saves | PASS, 934 checks | evidence/collection-audit.json: 40 scene switches, primary touch and background freeze, restart/unload, malformed nested sessions/metadata, 360x640 / 360x800 / 640x800 layouts |
| Complete desktop visual matrix | PASS, 34 captures reviewed | evidence/visual-review.json and matrix-*.png; two languages, three screen ratios, eight games, settings, overlays and merge feedback. Not Android proof. |
| Required suite runner | PASS, 17 suites | evidence/required-checks.json; rejects engine runtime errors even when process exit code is zero |

## Found and fixed

- Damaged Cake layer objects and non-numeric 2048 cells reproduced script errors.
  Shared structural session validation now rejects them before casts; records survive.
- Wider portrait screens clipped the 2048 board. The board now fits both dimensions.
- First button-tween regression logged missing metadata despite an exit code of zero;
  the strict runner caught it. Explicit metadata presence check fixes the initial press.
- Tall home cards underused space; increased the bounded height. Mipmaps improve
  the actual downsampled home/fruit sprites. Muted text now has contrast 4.578-6.679
  against the eight palette surfaces (previous minimum 2.638).
- Process-relative QA save names could reuse older damaged-save fixtures. Unique
  wall-clock-microsecond/PID folders isolate each run; old evidence was retained.


- Jelly's first multi-finger fixture sent touch-down only to `_input`; the app starts
  gestures in `_unhandled_input`. Corrected the fixture to match the actual event route;
  assertions still require primary ownership and canceled-release suppression.
- Added a shared clipping Control around each game so thrown fruit/halves cannot draw
  over the footer or header. Existing game rule/runtime regressions all pass after the change.
- Jelly headless stress initially measured isolated 321,749 us and 208,727 us maxima.
  Those adverse observations are preserved. Instrumented independent follow-ups measured
  maxima 4,016 us and 3,296 us, with no >16,667 us sample; latest p50/p95 are 257/398 us.
  The initial outlier cause remains UNVERIFIED, not attributed to a code fix. These are
  simulation + synthetic-swipe timings, not Android render frame time or performance acceptance.

- Balls stress initially exhausted collision iterations seven times. A grazing bumper
  reflection had its small vertical speed increased back into the bumper. The original
  normal/velocity are retained in bouncy-balls-tests.json; outward-normal validation and
  separation fix it. Two thousand randomized curved contacts and the unchanged 60-second
  stress pass with zero exhaustion. Stress yields to the real scene loop to drain queued
  toast replacements; its node assertion explicitly permits that one shared UI label.

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

An alternative runtime attempt is now prepared in CI: a dedicated API 34 standard AOSP
x86_64 AVD, 720x1280 / density 320 / 2 cores / 2048 MB, stable emulator 37.2.12 and
system image revision 4. Those revisions were read from Google's repository metadata;
the workflow checks them and fails on drift. The existing pinned SDK CLI installs them.
ADB smoke installs the actual job APK, launches it, taps all eight cards, performs real
Android input, backgrounds/force-stops/restarts, checks persisted settings/seen games,
and retains screenshots, save observations, logcat and memory data. Script syntax has
been checked locally; Android execution and visual acceptance remain PENDING.

First hosted attempt [39648255774](https://github.com/seiya058904/mochi-arcade/actions/runs/39648255774)
passed engine/tests/build/SDK/KVM but the emulator exited before creating a device:
its default userdata partition needed 12,288 MB, while the temporary runner had
4,928.71 MB free. The retained emulator log establishes this disk failure, not a KVM
failure. The dedicated AVD now requests a 2 GB userdata partition, no SD card, and
the smoke detects early emulator process exit instead of waiting the entire boot timeout.

Second attempt [39649666572](https://github.com/seiya058904/mochi-arcade/actions/runs/39649666572)
confirmed the Google APIs image still requires a minimum 7,372.80 MB, with only
4,928.79 MB available. Early process-exit detection worked. The revised environment
uses the normal AOSP API 34 image (official revision 4, archive 720,747,116 bytes)
and removes exactly three verified/extracted archives created by this job. Full
graphics are retained; the ATD image is deliberately avoided because it disables
hardware rendering. No Android success is inferred before actual execution.

This uses [documented hosted Linux KVM support](https://github.blog/changelog/2024-04-02-github-actions-hardware-accelerated-android-virtualization-now-available/)
and the [official emulator CLI](https://developer.android.com/studio/run/emulator-commandline).
KVM permissions change only on the temporary hosted VM, never on the user's computer.
The smoke's success status explicitly requires subsequent screenshot review; issuing
coordinates is not by itself a claim that every gameplay interaction was accepted.

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

## Signing and package candidate

The 1.0.0 local candidate uses the persistent external RSA-3072 release identity,
not the debug certificate. DPAPI password reopening and protected ACLs were verified.
`apksigner` verifies v2/v3; `zipalign -c -P 16 -v 4` passes. Metadata is package
io.github.seiya058904.mochiarcade, version code 1, min 24 / target 36, arm64-v8a and
x86_64, VIBRATE only. Both OFL texts and all eight game scene remaps are present;
tests, docs, source art and private signing files are absent. The external launch
entry is GodotAppLauncher; its target GodotApp is intentionally not exported. The
smoke and build instructions now use the observed alias. Installation is still pending.

The AOSP r04 archive's source.properties declares revision 2, despite repository
metadata revision 4. Runs 39651418664/39651874434 retained this mismatch; validation
now reads the installed package.xml revision. Run 39652355709 failed earlier on a
transient Google HTTP/2 download error; the CLI download now uses HTTP/1.1 and bounded
retry-all-errors. These are environment failures, never counted as Android success.
