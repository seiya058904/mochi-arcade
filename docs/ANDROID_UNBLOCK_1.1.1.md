# 1.1.1 Android acceptance unblock — 2026-10-23

Status: **IN_PROGRESS; publication remains BLOCKED**. The user explicitly asked
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

## Next actions

1. Commit/test the observation and independent-gate tools as T; dispatch E1 once.
2. Review actual renderer, each control, stop/restoration and diagnostic captures.
3. If viable, execute all four full signed gates at one T/profile/hash, review
   native captures/video, and run strict aggregate including manual review hashes.
4. Integrate main and complete final applicable CI. Publish only after every gate;
   otherwise finish evidence/synchronization with precise BLOCKED conditions.
