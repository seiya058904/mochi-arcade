# 1.1.1 Android acceptance unblock — 2026-10-23

Status: **BLOCKED for publication**. The user explicitly asked
to preserve the candidate and finish bounded environment diagnostics, four
independent acceptance gates and conditional publication. No subagents.

## Takeover and frozen inputs

Clean main/upstream/origin main: `e258bf738a8967dce544dff674872903a50fee4b`.
One worktree, no stash, only local main. Task branch
`codex/v1.1.1-android-unblock`. No pre-existing user edits. AEHD remains stopped;
no local AVD or system configuration changes. User-supplied unblock instructions
were read in full from the named local Markdown file.

APK source S `920f39cfc29fc0d46b03a295f25f1197446a4027`; candidate 1.1.1/code 3,
78,471,990 bytes, SHA-256
`09cab2dee4bbcd03f478286fb378eebce59a5edc4b501ba583cad5fb426459f8`.
Package `io.github.seiya058904.mochiarcade`; certificate
`de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b`.
Draft 421777385 / assets 668954574 and 668954575 unchanged; public latest v1.1.0.
Local APK and independent downloaded copy rechecked for hash, signature v2/v3,
manifest, ABI, permissions and ZIP/ELF 16 KiB alignment. Inspection tool SHA is
distinct from S. Runtime/scripts/scenes/assets/project/export comparison is empty.

Baseline 22 checks PASS; new restoration tests cover missing backup read,
device loss/stop timeout (no write allowed), original absence, byte mismatch and
missing/unreviewed gate aggregation. The unified entry now has 23 checks.
Earlier patch 126 and rendered 119 assertion counts remain separate observations.

## Historical failures retained

Complete job logs for 39948412473, 39948416747 and 39951046417 are archived as
gzip under `evidence/iteration-1.1.1/run-<id>/`. Existing statuses are unchanged.
The final main run's reports, continuous guest logs, emulator log, host state,
112-image review and original source hashes are now versioned as well.

39951046417 completed its two load bodies but `adb ... shell am force-stop
io.github.seiya058904.mochiarcade` timed out at 40 seconds. That was the first
operation in finally: neither original file write-back nor byte comparison ran.
The emulator process and ADB were still present. This is a distinct observed
failure from the two host SIGSEGV runs; neither root cause is established.

## Tool corrections and gate boundaries

Capture both original files, existence, SHA-256 and owner/mode on the host before
any load injection. Refuse injection if preservation fails. Restoration first
confirms stop, absent PID and responsive shell. Independent phase reports retain
write-back/verify failures and collect diagnostics even after an earlier failure.
No data is written if stop is uncertain; no rescue turns an original FAIL to PASS.
Owned runner process release is separate from application data restoration.

Each U110, U100, CLEAN and LOAD matrix member gets its own fresh hosted AVD;
fail-fast is disabled. Each upgrade remains one uninterrupted predecessor/install-r
chain. CLEAN checks package/data absence independently and ordinary uninstall.
LOAD creates its own valid baseline through real settings commits. Original
full smoke, eight-game semantics, fault cases and load thresholds remain required.
The release summary rejects absent, failed, mismatched or unreviewed gates.

## Bounded experiment declaration

| Profile | Unique change | Fixed controls | Status |
| --- | --- | --- | --- |
| E1 explicit `-gpu swiftshader` | Replace host GLES/Mesa llvmpipe profile; remove inherited Mesa/Xvfb overrides for this route | Emulator 37.2.12, AOSP API 34 x86_64 r4, 720x1280/320 dpi, 2 cores/2048 MiB, original APKs, three Bouncy returns and stop per APK, candidate 64-ball/12-jelly load and restoration | FAIL, 39959705397: public v1.1.0 blank home and shader linking errors; candidate/control/load NOT_RUN |
| E2 explicit `-gpu swangle` | Use ANGLE GLES frontend with SwiftShader, supported by installed emulator help; test a different shader compiler/capability route after E1 uniform-limit failure | Same fixed controls and assertions as E1; no seed/timeout relaxation | PASS diagnostic only, 39960486671; 18 native images reviewed |

One diagnostic attempt per profile; maximum two new profiles. Read emulator GPU
help and actual SurfaceFlinger renderer before app tests. E1 runs public v1.1.0
control first, then candidate under the same profile. Short diagnostic success
only permits full acceptance; it never substitutes for U110/U100/CLEAN/LOAD.
E2 is now selected for the full gates and default development CI after its complete
diagnostic passed. No more new profiles or unchanged diagnostic retries are planned.

Tool preflight failures are retained separately from renderer experiments:
39958474343 failed workflow validation (job-level `runner` context); 39958584887
failed the version probe before creating or starting an AVD. The windowed QEMU
binary could not load `libpulse.so.0`. The probe now uses `-no-window`, matching
the actual launch. No library installation or environment change was made.
These preflight failures did not launch an AVD and did not consume graphics attempts.

E1 at T `7a44b7aaf34050f817be5adefde6b133be5342b6` actually selected
`Android Emulator OpenGL ES Translator (Google SwiftShader)`, ES 3.0 / SwiftShader
4.0.0.1. The public v1.1.0 home was uniformly cream (native screenshot reviewed).
Godot reported CanvasShaderGLES3 and SceneShaderGLES3 linking failures:
`Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`.
ADB, ActivityManager, SurfaceFlinger and application PID remained responsive;
emulator exited 0 after owned-process termination, no SIGSEGV observed.
This failure is not attributed to the candidate, which was never installed.
Full logs, actual renderer, process state, screenshot and hashes are retained in
`evidence/iteration-1.1.1/unblock/E1-39959705397/`.

E2 is justified by this specific GLES linking failure: the installed help lists
`swangle` as ANGLE with SwiftShader, rather than the direct SwiftShader GLES route.
It is a hypothesis, not a promised fix. It is the second and final new profile in
this bounded task; only a passing diagnosis permits full gates.

E2 at T `bfe653feceb38f2c7efe07fbc652ec972da07180` passed public v1.1.0 and
candidate three-return/stop controls, then both candidate load bodies and complete
primary/backup restoration (bytes/existence/owner/mode). Actual renderer was ANGLE
2.1.17841 / SwiftShader driver-5.0.0, OpenGL ES 3.1, Vulkan 1.3.0. No Godot/runtime
errors or host crash were recorded; owned emulator termination exited 0.
18 native screenshots were reviewed: one initial public home has Android's
immersive tip, all later game/control/load views are unobscured. The original
AWAITING_VISUAL_REVIEW automation report remains unchanged, with a separate
diagnostic review and exact file hashes. Evidence:
`evidence/iteration-1.1.1/unblock/E2-39960486671/`.

Observed load presentation rates were 5.33 and 10.33 FPS on this CPU-rendered
hosted environment including ADB work. These are not phone performance or a
performance improvement claim. This diagnostic does not satisfy the four full
release gates and does not establish the cause of historical host SIGSEGVs.

Official [graphics modes](https://developer.android.com/studio/run/emulator-acceleration)
list explicit swiftshader; swiftshader_indirect is deprecated. This motivates an
experiment, not a claim that the prior gfxstream failure has been fixed.

## Full signed gate result (not superseded by the short diagnosis)

Run [39961466842](https://github.com/seiya058904/mochi-arcade/actions/runs/39961466842),
T `6d1286a0db86d03786db217b5df3420582ba9ea8`, frozen candidate S/hash and swangle.
All four fresh AVD jobs completed their own 23 required suites before Android.

| Gate | Status | Actual completed scope and failure |
| --- | --- | --- |
| U110 | FAIL | Public v1.1.0 completed five game paths, then Hop background-return was black. Candidate install/upgrade, terminal Undo and recovery matrix NOT_RUN. Additional launcher observation failed because UIAutomator XML was absent. 71 native PNGs and startup video reviewed. |
| U100 | PASS reviewed | Complete v1.0.0 smoke, original-signature install-r with both files preserved, all eight semantic states and native continuation, both terminal background-return/Undo paths, damaged/read-denied recovery and uninstall. 131 PNGs plus all 99 startup video frames (63 unique) reviewed. |
| CLEAN | FAIL | Candidate first two game paths completed; Cake Stack first background-return was black. Remaining paths and clean uninstall NOT_RUN. 39 PNGs and startup video reviewed; no full new-install claim. |
| LOAD | PASS reviewed | 64 balls and 12 fruit restored and exercised. Stop/no PID/live shell, both writes and both read-back byte/metadata comparisons PASS. 11 PNGs reviewed; emulator terminated normally. |

U110 and CLEAN both retain the original black frame after five extra seconds.
A further background/foreground surface cycle restores the pause UI with the same
application PID, solely as diagnosis; the run stays FAIL. ADB, ActivityManager and
SurfaceFlinger responded, no host SIGSEGV was observed, emulator termination exited
0. CLEAN logs around 13:35:19 UTC show abandoned BufferQueue, EGL_BAD_SURFACE and
GLThread `!readyToDraw()` after OnResume. These observations narrow the failure to
the surface/rendering path but do not establish an engine/emulator/driver root cause.
The public predecessor also failing means it is not unique to candidate changes.

Raw automation reports, native captures/video, exact visual hash lists and separate
PASS/FAIL reviews are retained under `evidence/iteration-1.1.1/unblock/gates-39961466842/`.
The review decoded all startup frames (68 each for CLEAN/U110), inspecting all
unique pixel frames; repeated identical frames are indexed, not sampled away.
No third profile, unchanged signed rerun, timeout increase, relaxed assertion,
seed change, app reset within an upgrade or runtime/APK modification is authorized
as a way to erase this failure. The final main CI remains a separate gate and cannot replace these exact-signed failures.

## Remaining external condition and continuation boundary

Two bounded configurations are exhausted. A future continuation needs a specific,
evidence-backed correction for GLES surface recovery or a separately validated
Android acceptance environment that survives the complete lifecycle chain. First
use the retained public-v1.1.0/Cake/Hop traces to isolate engine, emulator and driver
behavior; do not infer a GDScript repair from a black screenshot. Keep Godot 4.7.2,
the original candidate, original signing identity and existing published assets
until a concrete product/export fix is demonstrated. No local AVD, AEHD/system
change, temporary physical-device request or paid runner is part of this task.

F1–F3 repairs, version-1 storage and measured transaction reductions are preserved.
No additional product fix or save optimization was made. The 126-assertion patch
and 119-assertion rendered reports remain distinct historical tests. U100 now independently proves Android terminal Undo and full upgrade semantics for
v1.0.0. U110 remains incomplete. AudioFlinger shows active/advancing output tracks
after terminal return, but no Android PCM recording/listening was performed.
ARM64 devices, other APIs, physical 60/120 Hz, heat/battery and audible Android
output remain UNVERIFIED/DEVICE_UNAVAILABLE; CPU-rendered host rates are not phone FPS.

## Closeout and next actions

The strict four-gate aggregate is **FAIL**: U100 and LOAD PASS with matching native
visual reviews; U110 and CLEAN FAIL. See
[`release-gates.json`](evidence/iteration-1.1.1/unblock/gates-39961466842/release-gates.json).
No v1.1.1 public tag/release or anonymous candidate-download claim is made.

1. Integrate the reviewed tools/evidence into main and run the required final main
   CI (development bytes, separately identified). Record exact final SHA/run in
   the local delivery JSON and retained draft handoff; do not inherit signed PASS.
2. Keep the original candidate draft and published v1.0.0/v1.1.0 assets unchanged.
3. Future work needs the concrete surface-recovery/environment condition above.
   Two configuration experiments are exhausted; do not repeat unchanged full gates.

No additional save optimization was performed. The historical paired Windows
100-sample nearest-rank results remain: record swipe 2→1 commits, p50 16.704→6.181
ms / p95 17.532→9.384; pause 1→1, 3.565→3.567 / 6.600→6.464; home 2→1,
8.237→5.451 / 11.367→8.752; exit 2→1, 6.076→2.972 / 9.860→6.382.
These are prior measured observations, not new Android performance results.
