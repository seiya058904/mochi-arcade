# QA report

Status: **PARTIAL** — four playable games, 2026-10-22.

Initial read-only audit on 2026-10-21 confirmed an empty work directory, no Git
root, Java 17, SDK 34 and an offline Android 34 AVD. Since then an actual Godot
project, production art, shared shell, four playable scenes and a debug APK have
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
| Desktop rendering | PASS for current screens | evidence/desktop-*.png files, AMD RX 7900 XT Compatibility renderer |
| Native desktop input | PASS for current four games | Actual home/settings clicks, 2048 left/up swipes and merge score 4, Cake placement/cut and score 1, Fruit aim/release and next preview, focus-loss pause/resume; Bubble real mouse drag/release pops four and scores 40 (desktop-bubble-native.png) |
| Debug APK export | PASS | dist/MochiArcade-dev.apk, local ignored artifact |
| Debug APK signature | PASS, debug only | v2/v3 schemes; certificate 2207476872571c99d83537c73a9e3b38d9b66c5d04bef7ad3ccd5ebbe122b0ab |
| APK metadata | PASS | io.github.seiya058904.mochiarcade, min API 24, target 36, arm64-v8a+x86_64; VIBRATE only |
| Android install / launch / touch | BLOCKED | No online device; not claimed verified |
| Audible quality / physical-device performance | NOT_RUN | Requires actual listening and Android runtime |
| CI / release | FAIL / NOT_PUBLISHED | Run 39633928754 passed import/tests but SDK setup could not find sdkmanager; run 39635500243 failed workflow validation before any job. Runner context moved from job env to supported step env; next push will verify. |

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
- Rendered long-play shutdown still occasionally reports two ObjectDB instances;
  headless runs are clean. This desktop audio/resource teardown warning remains open
  for the integration audit; no crash or persistent in-game node growth observed here.

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
