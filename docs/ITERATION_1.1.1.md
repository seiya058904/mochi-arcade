# 1.1.1 reliability patch — 2026-10-23

Status: **BLOCKED; signed Android acceptance failed after hosted emulator crashes**. Published v1.1.0 and v1.0.0
remain unchanged. This iteration does not inherit their runtime PASS results.

## Takeover and scope

Root: `D:\xia zai\AI project\Project in Iteration\Mochi Arcade`; origin
`https://github.com/seiya058904/mochi-arcade.git`. Initial main, upstream and live
default branch were `9d93b74719c8d815d45452dd2ca925473e54bf7a`. Tracked/untracked
status clean; no stash; one worktree and only local main. Work branch:
`codex/v1.1.1-reliability`. No user changes were hidden or overwritten.
Live branch protection returned "Branch not protected" and rulesets were empty;
normal direct main integration is permitted. Existing public releases were
v1.0.0/code 1 and v1.1.0/code 2; candidate is v1.1.1/code 3.

Godot `4.7.2.stable.official.ed1daf0bf`, Python 3.12.10, existing Temurin
17.0.20.1 and Android SDK/build-tools 36 reused. Protected local signing key
successfully reopened; certificate SHA-256
`de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b`.
ADB has no connected devices; AEHD is stopped. No local AVD boot or system
configuration changes. Private material remains outside the repository.

Success requires reproducible before/after behavior, all required suites, actual
rendered EN/ZH layouts/audio, exact original-signed bytes on the isolated hosted
API 34 AVD, both upgrade sources, independent screenshot review, final-source CI,
and anonymous public download/signature verification. No release with an open P1.

## Findings

| ID | Priority / reproduced condition | Root cause / change | Evidence and status |
| --- | --- | --- | --- |
| F3 | P1 confirmed in deterministic Godot callback fixtures; not a claim of observed Android user data loss | Consumed pending bodies were excluded before deferred replacement. Save complete pre-merge pairs; retain pending merges during suspension and commit them once on resume. Each intermediate checkpoint is a coherent prefix of completed merges. | Old implementation fails both boundary/restoration checks. New fixture also exercises physical triple/chain contact; existing all-level/overflow/playthrough suites retained. Local PASS; full signed Android BLOCKED. |
| F1 | P2 confirmed: real terminal Bloom swipe / generated Trio full tray, WM_CLOSE save failure, actual Stay/Undo buttons | Cancel exit now releases game suspension while retaining results. Focus-in resumes terminal-screen music. | EN/ZH real GUI events restore board/tray/score/RNG/history, retain best, recover disk writes, reload and perform next action. Separate rendered old-code failures confirm audio gap. Local PASS. |
| F2 | P2 confirmed: one malformed top-level section rolls back unrelated newer values | Parse supported version independently from sections; recover only malformed sections or existing malformed fields. Respect absent keys/valid empty sections. Unknown version and I/O failures block overwrite. | Four-section matrix, valid clear/delete, both-bad bounded fallback, reread after repair; existing short-write/backup/rename/read-denial/retry suite retained. Version remains 1. Local PASS. |
| F4 | P2 release engineering | `release_identity.json` defines candidate, package, certificate and both independently verified public hashes. Explicit candidate SHA/source inputs bind draft transport and upgrade reports. Full semantic comparison at first-help freeze; real Undo and continuation checks. | Desktop probe of original isolated v1.0.0 rounds passes all eight full-state comparisons. Negative identity/field-loss tests included. Both exact signed runs FAIL after host crashes; only five candidate semantic restorations completed. |
| F5 | Measured write amplification | Stage best record inside the synchronous scoring action and commit with its checkpoint; freeze once and commit once on home/exit. No skipped disk validation or delayed lifecycle durability. | Before/after actual transactions and 100 raw samples per path retained. Balls/Jelly batching unchanged. Local PASS. |
| F6 | P3 maintenance | Four official Actions v4 refs pinned to live official tag SHAs; no major-version upgrade. Describe project retention policy separately from GitHub immutable protection. | Existing releases report `immutable:false`; no governance setting changed. |

## Save measurements

Same Windows machine/headless Godot, fixed seed/board, ten warmups then 100
samples per path. Synchronous action wall time; p50/p95 nearest-rank sorted
samples. Each transaction still serializes/writes/verifies temporary primary and
backup. No unchanged-save skip is introduced. Raw samples are in
`evidence/iteration-1.1.1/transactions-{before,after}.json`.

| Action | Transactions before → after | Writes/serializations | p50 ms before → after | p95 ms before → after |
| --- | --- | --- | --- | --- |
| New-best Bloom swipe | 2 → 1 | 4 → 2 | 16.704 → 6.181 | 17.532 → 9.384 |
| Pause | 1 → 1 | 2 → 2 | 3.565 → 3.567 | 6.600 → 6.464 |
| Return home | 2 → 1 | 4 → 2 | 8.237 → 5.451 | 11.367 → 8.752 |
| Exit | 2 → 1 | 4 → 2 | 6.076 → 2.972 | 9.860 → 6.382 |

These are local I/O observations, not Android FPS, GPU, thermal or battery results.
All six shared add_score users checkpoint in the same synchronous action; finish
commits the staged best with session deletion. Existing Balls/Jelly overrides
retain high-frequency memory updates and two-second/lifecycle commits.

## Evidence interpretation and exact next actions

Baseline 19/19 required suites PASS. `baseline-headless.json` and
`baseline-rendered.json` execute the final behavioral fixture against the exact
four original runtime files from the audit SHA, restored immediately afterward.
Earlier baseline-patch files retain the initial fixture's numeric-comparison
false positives; the later baseline files supersede those assertions, without
deleting the earlier raw failure. Real rendering is RX 7900 XT Compatibility;
headless audio flags alone are not mixer evidence.

Local gates PASS: 22/22 checks, 126 patch assertions, 84 reviewed views plus six
corrected-version settings views, actual mixer output and bounded static audit.
Both hosted runs independently passed all 22 suites at build source S.

## Fixed candidate and hosted results

Build source S: `920f39cfc29fc0d46b03a295f25f1197446a4027`.
Candidate **1.1.1 / code 3**, package `io.github.seiya058904.mochiarcade`,
78,471,990 bytes; APK SHA-256
`09cab2dee4bbcd03f478286fb378eebce59a5edc4b501ba583cad5fb426459f8`.
Original certificate above, v2/v3 signature, non-debuggable, arm64-v8a/x86_64,
VIBRATE only, 16 KiB ZIP/ELF alignment and export/license audit PASS.
An independent authenticated draft download matches size/hash/signature/version.
Draft release ID **421777385**, APK asset **668954574**, checksum **668954575**;
no stable v1.1.1 tag or publication. Anonymous candidate download is NOT_RUN:
draft transport is not a public release. Public latest remains v1.1.0.

Both runs used isolated Android 14/API 34 x86_64 userdebug, 720x1280/320 dpi,
emulator 37.2.12, host GLES/Mesa llvmpipe (software), original signed bytes.

| Source upgrade | Exact run | Result and completed scope |
| --- | --- | --- |
| v1.1.0/code 2 → candidate | [39948412473](https://github.com/seiya058904/mochi-arcade/actions/runs/39948412473) | FAIL: host emulator SIGSEGV while running the published predecessor after Bouncy background returns; candidate installation/upgrade/clean smoke NOT_RUN. Load and cleanup FAIL offline. 50 partial predecessor captures reviewed (47 stable and three startup observations). |
| v1.0.0/code 1 → candidate | [39948416747](https://github.com/seiya058904/mochi-arcade/actions/runs/39948416747) | FAIL overall: predecessor smoke completed; original-signature install-r preserved both files byte-for-byte. Fruit, Bubble, Cake, Bouncy and Trio full semantics/native continuation PASS, including actual Trio Undo. Emulator SIGSEGV before Hop restoration; remaining three games, fault matrix and clean candidate smoke NOT_RUN. Load and cleanup FAIL offline. 104 predecessor and 13 upgrade captures reviewed. |

The shell identifies an emulator process segmentation fault in each run. Emulator
logs contain gfxstream null-context and libunwind messages; root cause remains
UNVERIFIED. Host memory/disk observations do not establish OOM. No assertion was
removed, timeout enlarged, seed changed, environment restarted, or historical A14
exception applied. No unchanged-condition signed rerun was attempted. The five
successful upgrades do not establish a passing eight-game upgrade.

Full reports, load/cleanup failures, host diagnostics, source manifests and visual
review records are under `evidence/iteration-1.1.1/run-39948412473/` and
`run-39948416747/`. Raw downloaded artifacts remain in `.local/iteration-1.1.1/`.
Post-S observer-only tooling adds continuous smoke/upgrade logcat so a future host failure
does not lose all guest logs; this cannot retroactively diagnose these runs.
Post-S commits change documents/evidence/observation tools only, not runtime,
assets, scenes, version/export configuration or the tested APK.

## Exact remaining actions

Main was fast-forward integrated through evidence commit
`ff349f74552cc1b5d70e91ba1a8f172ac2f49e67` and pushed normally. Runtime/source
comparison against S is empty for scripts, scenes, assets and project/export
configuration. The subsequent closeout commit is documentation/evidence only.
The delivery report records the final applicable main CI URL and conclusion;
[main checks](https://github.com/seiya058904/mochi-arcade/actions/workflows/ci.yml?query=branch%3Amain)
remain the authoritative remote result, not historical green runs. Integration is
complete; the required signed release gates remain BLOCKED independently of CI.
Old release/tag/asset identities were rechecked unchanged in
`evidence/iteration-1.1.1/release-preservation.json`. Initial worktree was clean;
no user changes, stash, existing worktree or branch were modified. Task branches
are removed after merge; raw `.local` evidence and the unpublished candidate are
retained deliberately. No local AVD or Godot process remains; AEHD stays stopped.
Archived text diagnostics normalize trailing whitespace only; raw artifacts and
their original SHA-256 manifests remain available locally.

1. Inspect the final main CI separately; a development APK CI cannot replace the
   missing signed acceptance above. Do not treat a partial run as a passing gate.
2. Diagnose the hosted emulator crash with retained host/guest diagnostics. Only
   retry signed acceptance after a specific cause is addressed or a documented,
   verifiable environment change; keep all original FAIL reports.
3. Complete both full upgrades, fault recovery, independent clean candidate
   eight-game/24-return/audio/restore acceptance and 64-ball/12-jelly loads,
   including cleanup and matching native screenshot/video review.
4. If candidate bytes change, rebuild from a new fixed S and redo affected gates.
   Only after all gates pass create the new tag/release and verify anonymous public
   APK/checksum download. Do not move old tags or replace their assets.

ARM64 physical phone, other APIs, 60/120 Hz, thermal and power remain
DEVICE_UNAVAILABLE / UNVERIFIED. Historical FAIL evidence and the narrowly scoped
v1.0.0 A14 exception remain unchanged and cannot waive this candidate's gates.
