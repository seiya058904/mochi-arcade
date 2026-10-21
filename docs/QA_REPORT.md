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
Local Android emulator: BLOCKED by absent acceleration. Hosted API 34 now renders
all eight games with swangle. Manual review rejected its first green smoke result:
system Back exited instead of pausing, and Trio tapped covered tiles. The Back
fix passes all 18 desktop suites; strengthened Android acceptance is pending.
The next run exposed a native audio-loop overread. Its endpoint repair is locally
verified; Android acceptance is still blocked until the repaired mixer survives.

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
| Android install / launch / touch | PASS rendering / FAIL first lifecycle review | Run 39654367634 renders all eight with swangle; manual review found Back process exit and ineffective Trio test taps. See evidence/android-first-rendered-review.json. |
| Audio output | PASS measured Windows mixer / phone UNVERIFIED | evidence/audio-output.json: 48 kHz captured output, eight tone peaks 0.101-0.103, eight-voice burst 0.438, music peak 0.0090, muted/paused output exactly zero. No subjective listening or phone-speaker claim. |
| Repository credential/provenance review | PASS bounded static audit | evidence/security-audit.json: 13 commits, 259 text blobs, known credential patterns; 80 binary/large blobs counted separately. No findings or runtime network/process calls; not exhaustive secret detection. |
| CI / release | PASS for da1d397 / NOT_PUBLISHED | [Run 39647458113](https://github.com/seiya058904/mochi-arcade/actions/runs/39647458113): all eight-game checks and debug Android build passed. Later hosted runtime attempts fail on disk, as retained below. |
| Collection lifecycle / adverse saves | PASS, 935 checks | evidence/collection-audit.json: actual Back notification and root signal, 40 scene switches, primary touch and background freeze, restart/unload, malformed nested sessions/metadata, three layouts |
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

## Android first actual execution and retained failure

[Run 39653014044](https://github.com/seiya058904/mochi-arcade/actions/runs/39653014044)
booted Android 14 / API 34 (AOSP x86_64), installed its actual development APK
successfully and cold-started the exported launcher in 2,149 ms. KVM/disk/tool
setup now work. The black frame and fullscreen-tip captures are retained under
`evidence/android-first-launch-*`; `android-first-launch.json` links the exact
commit/APK digest. No game-entry or persistence success is claimed from these taps.

Logcat shows SceneShaderGLES3 and CanvasShaderGLES3 failing the legacy SwiftShader
GLES uniform limit (261). This matches [Godot issue 109550](https://github.com/godotengine/godot/issues/109550),
including a report for 4.7.2. The next runner uses the documented
[swangle graphics mode](https://developer.android.com/studio/run/emulator-acceleration),
which routes GLES through ANGLE and SwiftShader's Vulkan driver. Production still
uses Compatibility; no gameplay or engine version is changed to hide the failure.
The smoke now inspects/dismisses the actual Android fullscreen tip through UI XML,
waits for rendering beyond native activity visibility, disables Wi-Fi/mobile data,
and fails on Godot renderer errors as well as script crashes. Save reads use the
ADB shell exit status, so missing files cannot be reported as successful reads.

## Vertical games ordinary-action completion

Rendered and headless reports agree: Cake reaches 60 consecutive perfect layers,
350 points and exactly 24 retained layers; three ordinary trims then a natural
miss give 353 points. The actual result button starts a fresh playable round.
2048 seed 2048 / input seed 44 makes 63 legal swipes, reaches score 368 / tile 32,
then naturally has no moves and retries. No board, moving position, score or
terminal state is injected. The first harness observed at 0.20 s, before the
production 0.22 s result delay; its unchanged action trace passes with a 0.267 s
observation. This was a fixture timing correction, not a gameplay fix.
Tall Cake review found layers behind the bottom instruction; a paper backing now
keeps that instruction readable. `vertical_playthrough.gd` is the 18th required suite.

## Android rendered review and Back regression

[Run 39654367634](https://github.com/seiya058904/mochi-arcade/actions/runs/39654367634)
rendered all eight games on Android 14, 720x1280, AOSP x86_64 with swangle.
Its script reported PASS_SMOKE_AWAITING_VISUAL_REVIEW. Review rejected full
acceptance: Trio history remained empty (covered tiles), and system Back
terminated foreground processes instead of displaying pause. Home, adverse Back,
and adverse Trio PNGs plus the reviewed report are retained in evidence/.

Godot 4.7.2 defaults SceneTree.quit_on_go_back to true; auto_accept_quit controls
a different desktop close path. Source: https://github.com/godotengine/godot/blob/4.7.2-stable/scene/main/scene_tree.h .
The app now disables automatic Back exit and defers overlay changes until the
notification traversal finishes. The strengthened regression first failed on the
old app, then passed 935 assertions including root Back signal delivery. All 18
required suites pass. This remains desktop regression evidence until ADB reruns.

[Run 39655181653](https://github.com/seiya058904/mochi-arcade/actions/runs/39655181653)
failed its initial cold launch: input devices were still registering during first
AVD boot, activity recreation preceded engine initialization, then Godot reported
cleanup before _start_success. A boot/configuration race is suspected; no claim
of a physical-device defect. The harness waits for boot settling and disables
incremental installation; the failure report is retained. No automatic retries
or ignored errors turn failed app launches into success.

The new ADB path checks process survival, paused-state freeze, UI resume/restart,
background return, every round after force-stop, settings and same-signature
reinstall. Release-APK saves can be inspected via adb root only on the isolated
AOSP userdebug emulator; the installed APK remains non-debuggable. Signing-secret
transfer still awaits explicit user approval.

Run 39657194383 passed cold launch after boot settling, but failed before entering
Fruit: its fullscreen confirmation remained visible after ADB acknowledged the
dismissal tap. The next tap was consumed by that system layer. Its screenshot and
report are retained as android-fullscreen-dismissal-delay.png and
android-overlay-timing-failure.json. The harness now polls the actual system UI
until the prompt is gone and waits for each first entry to appear in saved state.
This run does not validate the Back fix, since gameplay was never entered.

The maximum-load harness uses synthetic saves through unchanged production restore:
64 balls and 12 fruit, verified against actual Godot scene construction locally.
It gathers Android SurfaceFlinger actual-present timestamps, memory and screenshots
during genuine ADB paddle/slicing input, then restores the original test save bytes.
Timestamp parsing/deduplication/units and Python/YAML/Bash syntax pass locally.
Hosted measurements and visual review remain NOT_RUN. Software-rendered emulator
presentation is explicitly separated from physical-phone performance.

## First music-loop crash and bounded endpoint fix

Run 39658177429 entered Fruit correctly, then crashed in the native AudioTrack
thread after 24 seconds of process uptime. The retained tombstone excerpt is
evidence/android-audio-crash.txt; the corresponding report records the APK hash.
Register RSI contains 0x56220 (352800 frames), exactly the generated 16-second
22050 Hz music length. The fault address minus the PCM buffer base is 705600,
exactly its allocated byte count. The source assigned loop_end = count.

Godot 4.7.2's WAV mixer uses loop_end as an inclusive decode limit, computes a
limit-inclusive sample count, then reads p_src[pos]. Consequently that endpoint
reads one sample past this buffer. Source inspection:
https://github.com/godotengine/godot/blob/4.7.2-stable/scene/resources/audio_stream_wav.cpp .
The related upstream boundary inconsistency is recorded at
https://github.com/godotengine/godot/issues/119778 . No engine update is introduced.

The project uses count - 1, keeping every decoded index within the PCM buffer.
The new guard failed against the original code; the repaired engine playback
passes nine rate/block-size boundary combinations, with finite bounded samples.
All 18 suites pass; the logic/audio suite now has 14,288 assertions. Real mixer
capture additionally tests three seek-across-wraps and two uninterrupted full loops.
The Android harness keeps music enabled through its first full loop before entry;
Android repair verification remains PENDING, not inferred from desktop success.

Packaged launcher inspection separately found Godot's default monochrome glyph.
The normal bunny icon was correct. An explicit matching monochrome SVG now replaces
that template resource; raw packaged before/after WebP images are retained. This
is APK resource inspection, not a claim that a phone's themed-icon mode was tested.

## Android music and first four lifecycle repairs verified

Run 39659761708 survives the real first music loop without a native audio crash or script errors.
Fruit, Bubble, Cake and Balls pass actual system Back process survival, paused-state
freeze, saved-state freeze in background, force-stop restore and UI restart. Reviewed Fruit pause
and Balls restored screenshots show the actual three-button pause sheet. Balls also
naturally ends and successfully retries through the result button. This verifies
these repairs on the development APK in the dedicated Android emulator only.

The run stops at Trio: the screenshot shows three top tiles selected, with the
lower center cup still present. The second tap followed the first checkpoint before
its 0.18-second animation finished. Subsequent spaced taps were accepted. The test
now waits for exactly one history/mask change per tap and allows the animation to
finish before proceeding. It retains per-touch observations and a failure save;
the four-top-tile assertion is unchanged. Remaining games, settings/reinstall and
maximum loads still await execution. The failed report and screenshot are retained
as android-trio-animation-timing.json and android-trio-animation-timing.png.

Further visual review rejects foreground recovery: all four background-return PNGs
are entirely black. Saved-state equality alone was insufficient. Each return logs
`eglSwapBuffers failed: EGL_BAD_SURFACE` and an abandoned BufferQueue; the emulator
host also loses color buffers. Pause/force-stop/restart captures remain valid, but
background rendering is a release blocker. The exact failing PNG, host/guest log
excerpts and frame statistics are retained in android-background-surface-failure.*.

The next diagnostic uses the same pinned emulator/image with its documented
Lavapipe backend, without changing gameplay or hiding the swangle failure.
https://developer.android.com/studio/run/emulator-acceleration documents both modes.
Capture now converts the same raw Android frame to PNG and rejects blank frames;
it also records pixel statistics. Eight real-frame roundtrips preserve all RGB
pixels, reject the retained black sample, and three malformed inputs are rejected.
Foreground return additionally exercises Resume then Back, with actual captures.
The visual review is still mandatory. EGL swap warnings are retained for review.

Run 39661719966 passed all 18 suites and APK export, but the emulator download
connection closed before runtime setup. SDK transfers now retry at most three
times and still verify the pinned package version. App launches/tests never retry
automatically. Android input/load execution for that run is NOT_RUN.

## Immediate lifecycle checkpoint regression

Run 39662679600 uses ANGLE over Mesa llvmpipe 25.2.4 / LLVM 21.0.0. Fruit and
Bubble now visibly return to pause, Resume to a live view, and Back to pause;
actual return/resume PNGs are retained. Cake also returns visibly but its saved
background and returned rounds differ. The overall run is still FAIL.

The app deferred both freezing/checkpointing and overlay creation. Android may
halt its rendering loop immediately after the lifecycle notification, leaving that
checkpoint queued until foreground return. Freeze/checkpoint and audio suspension
now happen synchronously; only child-tree mutation is deferred. The latter checks
that the current game is still suspended, and cannot re-suspend resumed home audio.
Forty synchronous freeze assertions and five live Cake clock-persistence assertions
fail against the old code and pass after repair. The adverse 980-check report is
retained in lifecycle-sync-baseline.json. All 18 required suites pass after repair;
collection acceptance now totals 980 checks. Android verification remains pending.

Lavapipe still records EGL_BAD_SURFACE while old surfaces are being destroyed:
for Cake the warning is at 19:39:26.393, before OnResume at 19:39:26.566; valid
presentation then resumes. These warnings remain in the report instead of being
treated as proof of a permanent black screen. Blank captures, unchanged visual
transitions, fatal/native/script failures and checkpoint differences still fail.
The exact before/after background saves and PNG digests will be retained per game.
The independent maximum-pool step now runs even when smoke fails, without changing
the failed smoke/job result or claiming that performance supersedes lifecycle QA.
