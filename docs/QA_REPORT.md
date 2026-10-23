# QA report

## Current 1.1.0 source iteration — 2026-10-23

**NOT_RELEASED; hosted signed acceptance NOT_RUN, local Android BLOCKED.** New evidence is scoped in
[ITERATION_1.1.md](ITERATION_1.1.md) and `evidence/iteration-1.1/`.
Baseline 18/18 PASS; new 19/19 PASS includes 46 failure/retry/recovery/terminal-Undo
assertions. All 64 real-renderer EN/ZH three-ratio layouts plus new failure/exit/Undo
captures reviewed. Four idle canvas rebuild counts: 180 -> 0 over identical
180-frame samples, five exact RGBA comparisons; GPU draws unchanged, no claimed
battery/CPU percentage. Desktop audio mixer passes. None is Android signed proof.

Current local AVD acceleration is unavailable; host and SwiftShader without
acceleration exit 0xC0000005 before usable ADB, acceleration-on exits 1. Signing
identity can be opened but exact signed runtime and v1.0.0 upgrade are BLOCKED.
No system driver/service changes and no new stable publication. Historical
successful and adverse evidence below remains intact and belongs to v1.0.0.

## Historical v1.0.0 acceptance

Status: **v1.0.0 RELEASED** — eight playable games; final signed APK verified and
published; A14 carries an owner-approved scoped environment exception; physical-phone
quantitative performance remains UNVERIFIED and disclosed.

Initial read-only audit on 2026-10-21 confirmed an empty work directory, no Git
root, Java 17, SDK 34 and an offline Android 34 AVD. Since then an actual Godot
project, production art, shared shell, eight playable scenes and a debug APK have
been built. No stable release has been published.

Evidence must include command, actual environment, case counts, pass/fail,
seed/action sequence, screenshot/log path and unresolved limitations.

## Gate register

A01-A15 details: RELEASE_CHECKLIST.md. Physical Android: a user-reported
hands-on retest on 2026-10-22 found no problems (startup, enlarged Bouncy Balls
layout, eight games' background returns, maximum-pool load); device metadata,
captures and the on-phone hash were not supplied, so this remains user evidence
only. Automated signed-byte acceptance on a controlled device is now PASS: a
local AOSP API 34 x86_64 AVD with Google AEHD 2.2 and the host AMD RX 7900 XT GPU
ran the exact signed bytes (SHA-256 `2b459f5c...`) through all eight games x
three background returns, force-stop restore, zero-score restart, settings,
same-signature reinstall and launcher icon with 101 visible frames and zero blank
frames; maximum-pool load also PASS (64 balls 55.55 FPS, Jelly 60.0 FPS,
compositor intervals). This is an emulator, not a physical phone; physical
performance remains UNVERIFIED. The earlier local `-accel off` attempt is
retained in `local-avd-attempt.json`; the AEHD error 1450 from the first session
was cleared by the 2026-10-22 reboot. Hosted API 34 development run
39670759820 passes all eight input/lifecycle/restore/restart paths, settings,
launcher and same-signature reinstall, with 99 actual captures manually reviewed.
Run 39673516558 passes all eight paths and all 24 background returns but loses
its disposable AVD during the Jelly load. Run 39698026180 on `32df767` passes
the 18 suites, the new footer/dialog edge-target taps, and the full paths for
Fruit, Bubble and Cake, then stops at a Bouncy Balls repeated-return precondition:
the resumed round ends naturally during the slow capture window. Its maximum-pool
phase executes both 64-ball and 12-fruit cases with host-state and continuous
logcat retained. The harness now re-establishes a real paused round through UI
input instead of assuming one survives that window; the failed run stays FAIL.
All hosted runs use explicitly software-rendered host GLES (Mesa llvmpipe). The
same source on Lavapipe still reproduces a black return. Surface stability,
physical performance acceptance and final release-signed byte acceptance remain
unresolved. The earlier Back and audio-loop failures are repaired and their
failed evidence remains below.

Final-SHA run
[39701157030](https://github.com/seiya058904/mochi-arcade/actions/runs/39701157030)
on `fd3975d` is FAIL: 18 suites, the development APK build and the maximum-pool
phase pass; the input smoke stops at the same blank repeated background return
(Fruit Drop cycle 3, blank frame SHA-256
`cfc80ccb6c70119363e7e3da3bbb361f4c4c2628e4856bfdce139ea7b8cdf249`), with
`EGL_BAD_SURFACE` in the guest log and a new surface cycle restoring the visible
pause sheet with the same PID. Run
[39711487194](https://github.com/seiya058904/mochi-arcade/actions/runs/39711487194)
on `d7f2650` is also FAIL, but at the Bouncy Balls force-stop restore harness
precondition rather than a blank return (no blank frame occurred in that run).
The harness fixes verified locally address that timing precondition.

Owner-approved environment exception (2026-10-22): A14 is **not PASS**. The owner
accepted a scoped exception for the GitHub-hosted Ubuntu Mesa llvmpipe
background-return blank frame only, using the signed-byte hardware-GPU API 34
acceptance above as substitute evidence, and declined a self-hosted GPU runner.
The retained failure run
[39716897550](https://github.com/seiya058904/mochi-arcade/actions/runs/39716897550)
on `90ee172` failed at `01-fruit_drop-repeat-3-background-return` with blank
frame `cfc80ccb...`; no assertion was removed and the run remains FAIL. See
`RELEASE_CHECKLIST.md`. Physical-phone quantitative performance remains
UNVERIFIED and is disclosed in the release notes.

## Executed checks

| Check | Result | Evidence |
| --- | --- | --- |
| Official engine / template SHA512 | PASS | Verified downloaded archives against official sums before extraction |
| Godot 4.7.2 import | PASS | Actual headless editor import; all current scripts/scenes/assets |
| Cake / 2048 / save / audio rules | PASS, 14,288 assertions | evidence/logic-tests.json; canonical merges, 625 rows, 10,000 spawns, 1,500 cuts, corrupt save recovery and valid mixer loop endpoints |
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
| Android install / launch / touch | PASS host development path / surface stability unresolved | Run 39670759820 passes all eight lifecycle paths, actual launcher and settings/reinstall; 99 native captures reviewed. Same-source Lavapipe fails on black return. Earlier failed reviews remain retained. |
| Signed-byte Android smoke on hardware-GPU API 34 AVD | PASS (visual review complete) | 2026-10-22 final v1.0.0 run: AOSP API 34 x86_64, AEHD 2.2, AMD RX 7900 XT host GPU, 720x1280, final signed APK SHA-256 `8fcc1ebc...`; eight games x three background returns, 101 non-blank frames, same PID, pause checkpoint equality, force-stop restore, zero-score restart, settings persistence, same-signature reinstall save preservation, launcher icon, edge taps, first music loop; 43 `EGL_BAD_SURFACE` warnings only during background surface destruction; no runtime errors. Evidence: `evidence/android-api34-final-splash-2026-10-22/`. Not a physical phone. |
| Custom Mochi startup experience on hardware-GPU API 34 AVD | PASS | First launch 463 ms, cold start 408 ms, warm start 79 ms; Android splash shows the original bunny icon, followed by the cream Mochi Arcade boot splash; no Godot default logo, blue icon or progress bar, no fake percentage or artificial delay. Screen recordings and contact sheets: `evidence/android-api34-final-splash-2026-10-22/startup-{first,cold,warm}.mp4` and `startup-*.png`. |
| Signed-byte maximum-pool load on hardware-GPU API 34 AVD | PASS execution / phone FPS UNVERIFIED | Final v1.0.0 run: Bouncy Balls 64 balls 55.43 presented FPS (p95 33.251 ms; PSS 175,671 -> 166,479 KiB), Jelly Slice 12 fruit 60.0 FPS (p95 17.243 ms; PSS 173,708 -> 159,156 KiB), original save and backup restored. Compositor intervals including ADB load, not physical-phone FPS. Evidence: `evidence/android-api34-final-splash-2026-10-22/load-report.json`. |
| Physical-device user retest | UNVERIFIED (user-reported PASS) | 2026-10-22 user report: no problems on the four requested checks (startup/home, enlarged Bouncy Balls layout, eight games x three background returns, maximum-pool load). Phone model/OS/resolution, captures, per-check notes and on-phone hash NOT_PROVIDED; not automated or byte-level acceptance. See `PLAYTEST_FEEDBACK.md` and `evidence/physical-device-user-report-2026-10-22.json`. |
| Audio output | PASS measured Windows mixer / phone UNVERIFIED | evidence/audio-output.json: 48 kHz captured output, eight tone peaks 0.101-0.103, eight-voice burst 0.438, music peak 0.0090, muted/paused output exactly zero. No subjective listening or phone-speaker claim. |
| Repository credential/provenance review | PASS bounded static audit | evidence/security-audit.json on the release working tree (base 3efb08c): 37 commits, 535 text blobs; 213 binary/large blobs counted separately; no known credential-pattern findings and no runtime network/process calls; not exhaustive secret detection. Re-audited on the final commit before public visibility. |
| CI / release | PASS a032fde host checkpoint / later runs FAIL / A14 OWNER_APPROVED_ENVIRONMENT_EXCEPTION / v1.0.0 RELEASED | [Run 39670759820](https://github.com/seiya058904/mochi-arcade/actions/runs/39670759820) passes. Runs 39673516558, 39701157030 and 39716897550 retain their Android failures; 39711487194 failed at the Bouncy restore precondition with no blank return and motivated the harness fixes. Final run 39724258963 on 2d45caf passes the 18 suites, development APK build and load phase and fails only at the hosted Bouncy repeat-2 blank frame (owner-approved exception, not PASS). Release v1.0.0 is published. |
| Public release / anonymous download | PASS | Repository public; release v1.0.0 at https://github.com/seiya058904/mochi-arcade/releases/tag/v1.0.0; unauthenticated APK/SHA256SUMS download HTTP 200; downloaded bytes match SHA-256 8fcc1ebc..., certificate de1458f3..., package/version and 16 KiB alignment; README desktop/mobile rendered with all image links HTTP 200. Evidence: `evidence/github-readme-2026-10-22/`. |
| Collection lifecycle / adverse saves | PASS, 995 checks | evidence/collection-audit.json: actual Back notification and root signal, 40 scene switches, immediate primary touch/background freeze, restart/unload, malformed nested sessions/metadata, three layouts and 15 actual-GUI edge-target checks |
| Complete desktop visual matrix | PASS, 34 captures reviewed | evidence/visual-review.json and matrix-*.png; two languages, three screen ratios, eight games, settings, overlays and merge feedback. Not Android proof. |
| Required suite runner | PASS, 18 suites | evidence/required-checks.json on the release working tree; final local run: all 18 scripts PASS with zero runtime errors; runner rejects engine runtime errors even when process exit code is zero |
| Final release verification (v1.0.0 splash build) | PASS for non-hosted-Android gates | 18/18 required suites PASS; bounded security audit PASS (40 commits, 561 history text blobs, no known findings); final APK SHA-256 `8fcc1ebc...`, 78,467,820 bytes, certificate `de1458f3...`, versionName 1.0.0, non-debuggable, v2+v3, only VIBRATE, 16 KiB aligned; custom boot splash and first/cold/warm startup verified; packaged game content unchanged from the previously accepted build. Repository made public and release published after the public-safety audit. A14 hosted Android result is covered by the owner-approved exception, not by this row. |

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

## All eight native lifecycle checks and retained harness limits

Run 39664379571 on source 0f27910 passes the strengthened checks for every game:
actual entry and input, Back process survival and freeze, synchronous background
checkpoint equality, visible Resume/Back transitions, force-stop restore and
UI restart. Settings survive restart; a same-signature development-APK reinstall
preserves the complete save exactly. No native/script crash is recorded. The
unchanged raw report is android-eight-lifecycle.json; full visual review is pending.

The smoke remains FAIL: its final launcher swipe starts at y=1180 beside Android's
navigation boundary. Retained screenshot/XML show Launcher home, not the app drawer.
The revised harness observes the workspace first, swipes through the visible empty
area (540,950 to 540,300), then waits for the actual Mochi Arcade icon node.

The independent synthetic 64-ball restore visibly renders a full pool and responds
to paddle input. At burst end it has 59 balls and score 695; PSS is 195746 to 187539
KiB. The 5.358-second burst yields only 11 unique actual-present timestamps over
4.922 seconds, below the required 20 intervals. This is insufficient measurement,
not a performance pass. All ten raw latency dumps and the failed report are retained
in android-load-short-window*.json; the actual full-pool frame is android-load-64-balls.png.
Jelly was not reached. Sampling now lasts at least 12 seconds, up to 30 seconds,
without reducing the minimum. Each case retains its own failure and the second case
still runs. Restoration now verifies both primary and backup save bytes. These are
software-renderer observations, never evidence of physical-phone frame rate.

Manual review of this run is complete: 87 actual Android captures were inspected
in 12 labeled contact sheets, covering all eight games through ten stages plus
home/settings/licenses/reinstall. All tested views are readable, the pause/Resume
transitions are visible, and no blank return or blocking control overlap appears.
Game state changes agree with the saved observations. The sheets, source-image
digests and 12 unaltered original captures are retained in
evidence/android-lifecycle-0f27910/. This passes visual review of these tested paths;
it does not change the failed overall job or count as final signed-byte acceptance.

## Intermittent surface failure and measured maximum pools

Run 39667082209 (e688600, development APK SHA-256
392fdf015715cf69716a628313a243d486492f918a37ad79f3e07f0521e54d1c)
passes Fruit lifecycle, then Bubble returns completely black. Its failure capture
is also black. Keep android-intermittent-background.* and the selected guest/host
log. The previous full success cannot establish reliable recovery.

At 20:09:29.152 the old buffer queue is abandoned; at .153 the activity resumes;
the GL thread reports EGL_BAD_SURFACE at .154 and !readyToDraw at .291. No later
presentation statistics appear for that process before capture. The emulator
also reports a missing ColorBuffer. Godot 4.7.2's GLSurfaceView sets mSurfaceIsBad
on swap failure and clears it only when its worker observes a lost surface;
surface callbacks asynchronously replace mHasSurface. A lost transition during
slow rendering/quick return is SUSPECTED, not confirmed without internal-state
instrumentation. Primary source:
https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/java/lib/src/main/java/org/godotengine/godot/gl/GLSurfaceView.java .
No engine, native activity or renderer change is introduced. Failure diagnostics
will retain a later passive frame and a new Home/foreground cycle with PID equality;
these observations cannot convert the original failure to a pass.

Both synthetic load cases now complete and their ten captures have been reviewed:
64 balls visibly damage bricks; 12 fruit generate actual halves and combos. Both
original save files are restored byte-for-byte. Actual presentations are slow:
Balls 34 frames/12.102 s, 2.73 FPS, p95 803.792 ms; Jelly 54 frames/11.801 s,
4.49 FPS, p95 434.592 ms. They are execution/measurement evidence, not a smoothness
or phone-performance pass. Raw report and reviewed matrix are android-maximum-load-*.

## Batched ball rendering

Optional real-renderer balls_render_profile.gd observes static synthetic 1/64-ball
scenes, 60 frames each, full/reduced motion. Before repair the full-motion scene
requires 121/247 draw submissions; interleaved trails split the shared-atlas batch.
One multiline pass behind the sprites reduces both counts to 121. Reduced motion
stays at 120/120. The regression fails on the original and passes on the change.
The full 64-ball fixture's before/after RGB pixels are identical and both actual
captures are retained. This proves fewer draw submissions on the desktop GPU,
not Android speed. All 18 required suites pass; hosted timing comparison is pending.

Run 39669849881 tests this change on the same Lavapipe setup. Fruit, Bubble and
Cake lifecycle pass; Balls then returns black. The additional five-second passive
capture remains fully black. A new Home cycle with a five-second background stay
restores the pause sheet with the same PID 3219. This confirms persistent failed
presentation and recovery through a new surface lifecycle, not an app restart or
a merely delayed first capture. The internal mSurfaceIsBad hypothesis remains
SUSPECTED. The overall run stays FAIL; screenshots/report are retained under
android-surface-*. No automatic recovery is added to the product.

The actual AOSP app drawer now exposes the correct bunny icon, and tapping its
observed bounds opens the real home screen. Both original captures and UI XML
were reviewed and retained as android-launcher-bunny/opened-home. Themed mode is
still unverified. Load execution continues to pass, with exact primary/backup save
restoration. Starting from 64 balls, the 12-second burst observes 3.01 FPS / p95
632.010 ms; Jelly observes 4.66 FPS / p95 532.354 ms. These separate hosted runs
are not a controlled phone benchmark or proof that the drawing change fixes
software-emulator smoothness. All slow-frame observations remain visible.

## Same-source host GLES comparison

At a032fde, run 39670750928 on Lavapipe fails at Fruit's first background return.
Five passive seconds remain black; another five-second Home cycle recovers with
the same PID 2307. Run 39670759820 instead uses host GLES, with Mesa software
explicitly forced: OpenGL ES Translator, llvmpipe LLVM 20.1.2, Mesa
25.2.8-0ubuntu0.24.04.4 and preinstalled Xvfb 2:21.1.12-1ubuntu1.8. These builds
have the same source and assertions, but different debug signatures and APK hashes.
No production code or engine changed between them.

Host passes all eight touch/Back/background/restore/restart checks, music-loop
survival, five persisted settings, actual launcher-icon launch and exact save
preservation after reinstall. Manual review covers 89 smoke and ten load captures
in 13 labeled sheets. Boards and controls are readable; all background pause,
Resume and Back transitions are visible. The 64-ball scene damages bricks; the
12-fruit scene produces actual cut halves and combos. Six unaltered originals,
all 99 source hashes, both backends' raw reports and graphics observations are in
evidence/android-host-a032fde/.

Host still records ten EGL_BAD_SURFACE warnings and host ColorBuffer warnings,
despite visible recovery. Its measured maximum-pool presentation is Balls 6.01 FPS,
p95 349.348 ms (74 frames/12.141 s), and Jelly 8.91 FPS, p95 215.874 ms
(107 frames/11.891 s). Both original saves are restored byte-for-byte. These
software/ADB-inclusive timings do not pass smoothness or establish phone FPS.
They also cannot prove an engine race is repaired.

The next bounded run uses host by default, with Lavapipe retained as an explicit
diagnostic choice. Each game now makes three background returns: the first keeps
the full Resume/Back input checks; two further returns start paused and require
visible content, identical checkpoint and the same PID. No failed case is retried
or converted to success. The unresolved black-return release blocker remains.

## Expanded small-button hit regions

The tested Android viewport is 720x1280 at 320dpi. Several painted buttons are
72-88 pixels high, equivalent to 36-44dp, below the task's approximate 48dp target.
The shared button now extends only its hit region to at least 96 design pixels
in each axis, centered on the existing visual rectangle. This is 48dp in the
tested Android profile; no universal physical-size claim is made for untested
display densities. Artwork, positions, visible size and game rules stay unchanged.

Fifteen real Godot GUI input cases cover Settings, a toggle, Back, footer Help
and dialog action at points six pixels outside their painted rectangles, across
three portrait ratios. All 15 fail on the original rectangular hit behavior and
pass with the repair; the preserved baseline is touch-target-baseline.json.
All 18 required suites pass, with 995 collection checks. Actual AMD GPU captures
of Home and Settings are pixel-identical before/after and were visually reviewed;
touch-target-visual.json records this bounded comparison. Android edge taps are
added to the next smoke run and remain pending until that build is installed.

## Repeated returns pass; subsequent AVD loss retained

Run 39673516558 on 7a48d0e passes all eight complete smoke paths and all 24
background returns. Each pair of additional paused returns retains its checkpoint
and PID. The 24 return views, eight input views and five Balls load views were
manually reviewed in five sheets; all are visible and readable. All 110 captured
source hashes are retained, but the other 73 views are not claimed as newly
manually reviewed. See evidence/android-repeat-7a48d0e/.

The overall run is FAIL. Balls starts at 64, reaches score 1290 and ends at 21;
44 actual presentations over 12.104 seconds give 3.55 FPS and p95 499.492 ms.
While writing the next Jelly fixture, ADB times out after 40 seconds, then reports
the device offline. Screenshot, final logcat and save restoration cannot complete.
The original primary/backup remain preserved by the test script in host memory
and the pre-load primary is retained in the raw artifact, but restoration to this
disposable AVD is NOT_COMPLETED. No user device is involved.

The emulator host log ends with gfxstream null-context errors. No retained host
PID/kernel evidence establishes a crash, OOM or root cause, so attribution remains
UNVERIFIED. Future CI now retains a continuous guest log during loads and final
host process/memory/disk/kernel state. It does not reboot or retry failed cases.
The passed return subset does not turn this failed run into release readiness.

## Takeover: recovered work, failure attribution and Bouncy Balls revision

The 2026-10-22 takeover found the worktree dirty on `7a48d0e` with the previous
session's expanded small-button hit regions and repeated-return evidence not yet
pushed. A protected snapshot was saved under `.local/handoff-snapshot/` before any
operation; the material was then validated rather than discarded. All 18 required
suites pass with the recovered code (`required-checks.json`), including 995
collection checks and the 15 real-GUI edge-target cases whose pre-repair baseline
is retained as `touch-target-baseline.json`. The native Android edge taps in
`android_smoke.py` are pending a run on the new build.

### Run 39673516558 failure review (takeover reading of the retained artifact)

The downloaded artifact was re-inspected rather than trusted from the earlier
summary. The smoke phase passes all eight complete paths and all 24 background
returns; each repeated paused return keeps its checkpoint and PID. The Bouncy
Balls maximum-pool case executes with 64 balls, 44 actual SurfaceFlinger
presentations in 12.104 s (3.55 FPS, p95 499.492 ms, software renderer), visible
frames and a memory drop from 196,790 to 187,380 KiB PSS. The Jelly case fails
before it starts: `adb shell run-as io.github.seiya058904.mochiarcade tee
files/save.json` times out after 40 seconds, the following screenshot command
returns `error: closed`, and the cleanup reports the device offline. The retained
`emulator.log` ends with gfxstream `null ctx` delete-texture/buffer errors after
the GL context is gone. No app tombstone, ANR, SIGSEGV or script error was found
in the retained files, and no host PID/kernel/OOM state was captured for that run.

Classification for this failure: **EMULATOR_INFRA_FAILURE (hosted software-rendered
AVD lost its graphics context / ADB channel)**, with the deeper trigger
UNDETERMINED. It is not evidence of an app defect, and it is also not a pass:
the Jelly load case is NOT_RUN and the run stays FAIL. The next CI run was
instrumented beforehand to retain a continuous guest log during load cases and a
final host memory/disk/kernel/process snapshot; no assertion is relaxed, no case
is retried and the disposal AVD is never rebooted to hide a failure.

### Bouncy Balls player-feedback layout revision

The user's phone playtest reported that Bouncy Balls' ball, bricks and mid-field
multiplier gates/bumpers are too small, while explicitly saying the paddle is not
the problem. The measured pre-change field had a 22-px ball (3.40% of the 648-px
field width), 89.33x37 bricks in a 6x4 wall, 116x34 gates and 54-px bumpers.
The revision keeps the 24-brick count, 64-ball pool, gate claims, scoring, waves
and save schema, and the paddle stays exactly 172x19 at `area.y - 76` with the
same drag clamp. The ball is now 32 px (4.94% field width), bricks are 143.75x44
in a 4x6 wall (22.18% width; 32.62% of field height), gates are 150x46 (23.15%
width) and bumpers are 68 px (10.49%). Hitboxes, sweeps and drawn geometry share
the same constants; nothing is a stretched sprite.

Evidence: `PLAYTEST_FEEDBACK.md` holds the measured table, the user-feedback
boundary and the retained pre-change Android 720x1280 views. Desktop before/after
captures are `bouncy-balls-{before,after}-{opening,gate,full-pool}.png` with
`bouncy-balls-layout-{before,after}.json`. The Android post-change captures are
recorded with the new CI run below. The 64-ball saturated view remains readable.

Regression after the revision: `bouncy-balls-tests.json` PASS with 236,607
checks (new layout invariants included; 60-second 64-ball stress, zero
collision-limit hits); rendered ordinary-input `balls-playthrough-rendered.json`
PASS with 4 waves cleared, score 4,975, gates 58/80, real maximum 64 balls,
natural loss and playable retry; the other seven games' suites are unchanged.
A physical-phone recheck of the new sizes was `PHYSICAL_DEVICE_RECHECK_PENDING`
at this checkpoint because no phone was attached; on 2026-10-22 the user later
reported no problems with the enlarged layout on a physical phone, with device
metadata and captures NOT_PROVIDED (see `PLAYTEST_FEEDBACK.md`). The user's
old-APK opinion is not reported as acceptance of the new build.

## Run 39698026180 on 32df767: edge targets, maximum pools and a harness timing defect

This run is the first hosted CI on the takeover commits. Engine import, all 18
required suites and the development APK build pass before Android. The Android
step then fails overall and its failed report is retained as
`android-smoke-39698026180.json` with `android-load-39698026180.json` and
`android-host-state-39698026180.txt`.

What actually passed before the stop:

- Install, cold launch, fullscreen-tip dismissal, actual launcher-icon tap and
  the new expanded-hit-region edge taps all pass. In Fruit Drop the footer Help
  tap six pixels above the painted edge opens the help sheet, and the dialog
  action six pixels above its painted top dismisses it
  (`footer_and_dialog_edge_taps: true`); both frames are retained and differ.
- Fruit Drop, Bubble Garden and Cake Stack complete every check: real input,
  system Back survival and freeze, three background return cycles with equal
  checkpoints and the same PID, force-stop round restore and zero-score restart.
- Bouncy Balls enters with real input, its round ends naturally (the ADB swipes
  do not play the paddle), One more go restarts a playable round, and the first
  paused background return passes with visible transition and equal checkpoint.
- The final real-Android captures of the enlarged play field are retained:
  `bouncy-balls-android-after-ready.png` (initial 4x6 wall, large gates and
  bumpers) and `bouncy-balls-android-after-{packed,full}-pool.png` (64/64
  balls at RALLY 7, dense and individually readable).

Failure and attribution: the step aborts with
`bouncy_balls background cycle 2 changed its paused round or process`. The
retained `04-bouncy_balls-after-input` frame and `failure-screen.png` show the
natural result sheet and the home screen, and the cycle-2 file contains no
before/after sessions because the harness reads a missing paused round before
the assertion. The game behaved correctly: on the enlarged, lower brick wall the
single ball returns to the paddle sooner, and the resumed round ended during the
software renderer's screenshot turnaround. The harness had assumed a paused
round always survives that ~1 s window. Classification: **TEST_HARNESS_DEFECT
(precondition assumption)**, not an application defect.

Fix (test-only): before the Resume/Back transition and before each repeated
return, if no paused session exists the harness now force-stops, relaunches,
enters through the real home card and presses system Back to create a paused
round, then runs the unchanged visible-transition, checkpoint-equality and
same-PID assertions. The re-establishment is bounded to one attempt; a failure
still fails. No game code, assertion strength, retry policy or APK behaviour was
changed for this.

Maximum-pool phase (executes even when smoke fails): both cases complete with
exact primary and backup save restoration and continuous guest logcat plus final
host state.

| Pool case | Fixture | Presentation | p95 | PSS before -> after | Final state |
| --- | --- | --- | --- | --- | --- |
| Bouncy Balls | 64 balls, wave 7 | 48 frames / 12.248 s = **3.84 FPS** | 536.197 ms | 196,740 -> 187,610 KiB | score 1,940, 54 active |
| Jelly Slice | 12 fruit | 88 frames / 12.092 s = **7.19 FPS** | 250.021 ms | 194,564 -> 180,032 KiB | sliced 32, score 640 |

These are SurfaceFlinger compositor intervals on a hosted software-rendered AVD
including ADB input; they are **not** physical-phone FPS and are not a smoothness
pass. The run also records 13 `EGL_BAD_SURFACE` warnings across the session,
which remain product-risk evidence, not a repaired engine race. The following
commit carries the harness fix plus this documentation; the next CI run is the
validation of the fix. A physical-device recheck of the enlarged Bouncy Balls
layout was still `PHYSICAL_DEVICE_RECHECK_PENDING` at this checkpoint; the
2026-10-22 user report later found no problems (metadata and captures
NOT_PROVIDED).

## Run 39699385661 on 28a8a45: black background return reproduced, maximum pools pass

This independent session on the harness-fix commit re-ran the whole pipeline.
Engine import, all 18 required suites and the development APK build pass, and the
Android step again reaches gameplay. The expanded edge-target taps pass
(`footer_and_dialog_edge_taps: true`). Fruit Drop enters, its system Back keeps
the process and freezes the round, but the first background-return screenshot is
**completely black**:

- Error: `Android screenshot 01-fruit_drop-background-return is blank` with
  `sampled_colors: 1`, `non_dark_fraction: 0.0`, 720x1280.
- Required diagnostics: the screen is still black after an additional 5 seconds
  (`visible_after_extra_5_seconds: false`); a new Home/foreground cycle restores
  the visible pause sheet with the same PID 2308
  (`visible_after_new_surface_cycle: true`, `same_process: true`).
- The guest log records `eglSwapBuffers failed: EGL_BAD_SURFACE` at 00:27:29 and
  00:28:08 for the same process; no app tombstone, ANR or script error appears.
- Raw evidence: `android-smoke-39699385661.json`, `android-black-return-28a8a45.png`,
  `android-black-return-delayed-28a8a45.png`,
  `android-black-return-new-surface-28a8a45.png` and
  `android-host-state-39699385661.txt`.

This is the same **unresolved intermittent engine/emulator surface failure** that
has been retained since the earlier runs, now reproduced on the takeover code in
an independent session. It is not attributable to the harness fix (the run never
reaches Bouncy Balls) and it is not repairable by adding hidden restarts or
silently dropping progress. A05 and A09 stay BLOCKED; no release may be tagged
while this reproduces. The Bouncy Balls repeated-return harness fix added in this
commit remains unverified on Android until a run passes Fruit Drop's return.

The maximum-pool phase again executes both cases on the same online AVD and
restores the exact primary and backup saves:

| Pool case | Fixture | Presentation | p95 | PSS before -> after | Final state |
| --- | --- | --- | --- | --- | --- |
| Bouncy Balls | 64 balls, wave 7 | 45 frames / 12.30 s = **3.60 FPS** | 661.448 ms | 196,770 -> 187,293 KiB | score 1,460, 24 active |
| Jelly Slice | 12 fruit | 62 frames / 12.30 s = **5.04 FPS** | 415.789 ms | 194,656 -> 179,969 KiB | score 600, 4 active |

These are compositor intervals on a hosted Mesa llvmpipe software renderer with
ADB input; they are not phone FPS and not a smoothness pass. The two independent
failures differ (harness precondition vs black surface), so neither is a flaky
one-off that a retry may erase.

## Run 39700272044 on 6240595: black return reproduced a second time

Session 3 on the documentation SHA repeats the pipeline. The 18 suites and the
APK build pass, the native edge-target taps pass, and Fruit Drop enters, survives
system Back and completes its first paused background return. Its cycle-2
background return is again a completely black 720x1280 frame:

- `sampled_colors: 1`, `non_dark_fraction: 0.0`; the PNG is byte-identical
  (sha256 `cfc80ccb6c70119363e7e3da3bbb361f4c4c2628e4856bfdce139ea7b8cdf249`)
  to the black frame retained from run 39699385661.
- It remains black after an extra 5 s. A new Home/foreground cycle restores the
  visible Fruit Drop pause sheet with the same PID 2326; `EGL_BAD_SURFACE`
  warnings are retained in the guest log.
- Raw evidence: `android-smoke-39700272044.json`,
  `android-black-return-new-surface-6240595.png`,
  `android-load-39700272044.json`, `android-host-state-39700272044.txt`.

The maximum-pool phase again passes both cases with exact primary and backup save
restoration: Bouncy Balls 64 balls -> 3.62 FPS / p95 643.104 ms / score 1,460;
Jelly Slice 12 fruit -> 5.10 FPS / p95 397.828 ms / score 670. Software rendering
only; not phone performance.

Two independent sessions on the takeover code now reproduce the same black-surface
failure at different lifecycle points, with identical black output and
PID-preserving recovery only through a new surface cycle. That is a reproducible
product-risk blocker on the hosted software emulator, not a one-off. The Bouncy
Balls repeated-return harness fix could not be exercised on Android because both
sessions fail earlier at Fruit Drop. Classification stays ENGINE/SURFACE RACE
(suspected Godot 4.7.2 `GLSurfaceView` bad-surface handling; not internally
instrumented) on hosted Mesa llvmpipe. A05/A09 remain BLOCKED, no tag or Release
is created, and a physical phone or hardware-GPU host is the next meaningful
diagnostic.
