# 1.1.1 reliability patch — 2026-10-23

Status: **IN_PROGRESS; release gates pending**. Published v1.1.0 and v1.0.0
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
| F3 | P1 confirmed in deterministic Godot callback fixtures; not a claim of observed Android user data loss | Consumed pending bodies were excluded before deferred replacement. Save complete pre-merge pairs; retain pending merges during suspension and commit them once on resume. Each intermediate checkpoint is a coherent prefix of completed merges. | Old implementation fails both boundary/restoration checks. New fixture also exercises physical triple/chain contact; existing all-level/overflow/playthrough suites retained. Local PASS; signed Android pending. |
| F1 | P2 confirmed: real terminal Bloom swipe / generated Trio full tray, WM_CLOSE save failure, actual Stay/Undo buttons | Cancel exit now releases game suspension while retaining results. Focus-in resumes terminal-screen music. | EN/ZH real GUI events restore board/tray/score/RNG/history, retain best, recover disk writes, reload and perform next action. Separate rendered old-code failures confirm audio gap. Local PASS. |
| F2 | P2 confirmed: one malformed top-level section rolls back unrelated newer values | Parse supported version independently from sections; recover only malformed sections or existing malformed fields. Respect absent keys/valid empty sections. Unknown version and I/O failures block overwrite. | Four-section matrix, valid clear/delete, both-bad bounded fallback, reread after repair; existing short-write/backup/rename/read-denial/retry suite retained. Version remains 1. Local PASS. |
| F4 | P2 release engineering | `release_identity.json` defines candidate, package, certificate and both independently verified public hashes. Explicit candidate SHA/source inputs bind draft transport and upgrade reports. Full semantic comparison at first-help freeze; real Undo and continuation checks. | Desktop probe of original isolated v1.0.0 rounds passes all eight full-state comparisons. Negative identity/field-loss tests included. Two exact signed upgrade runs pending. |
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

1. Local gates PASS: 22/22 checks, 126 patch assertions, 84 reviewed views plus six corrected-version settings views, actual mixer output and bounded static audit. Final applicable CI remains required.
2. Commit build source S, export using existing local identity, verify static bytes.
3. Stage new draft and test v1.1.0 → candidate and v1.0.0 → candidate independently
   on disposable API 34 x86_64 hosted AVDs; review all matching captures.
4. Integrate main, verify required CI, publish only after gates, anonymously
   download and verify APK/checksums, confirm old tags/assets, then clean task objects.

ARM64 physical phone, other APIs, 60/120 Hz, thermal and power remain
DEVICE_UNAVAILABLE / UNVERIFIED. Historical FAIL evidence and the narrowly scoped
v1.0.0 A14 exception remain unchanged and cannot waive this candidate's gates.
