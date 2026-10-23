# 1.1.0 iteration — 2026-10-23

Status: **NOT_RELEASED; hosted signed acceptance NOT_RUN, local Android BLOCKED**. The published v1.0.0 remains
the accepted download. No old tag, asset, visibility or history is replaced.
This report separates source validation, development CI and signed-byte acceptance.

## Takeover and success criteria

- Root verified with Git: `D:\xia zai\AI project\Project in Iteration\Mochi Arcade`.
  Initial branch/main/origin/main: `ff9694ad87d6cf7091d356392d2bb008217de035`.
  Clean tracked/untracked status; one worktree, no stash, no open PR. No user
  modifications were moved, hidden or committed. Work branch:
  `codex/v1.1.0-reliability`.
- Existing public repository/default main verified live. v1.0.0 tag remains
  `2d45caf40d8334c4c9cc1567164db749d983c7ee`; anonymous APK download is
  78,467,820 bytes, SHA-256
  `8fcc1ebc83cb9cb8e8947a1a33bef9cba9222b9ac775fafdcd7d3d5cd85d473c`.
- Shared Godot 4.7.2 stable `ed1daf0bf`, JDK 17.0.20.1, Python 3.12.10,
  existing SDK/build-tools and gh 2.95.0 reused. No engine/dependency download.
  Local protected signing directory exists and current-user DPAPI successfully
  opens the original private key. Public certificate SHA-256:
  `de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b`.
- Baseline: original 18/18 suites PASS. New initial fault/terminal fixtures fail
  nine assertions on the old implementation; retained in
  `evidence/iteration-1.1/baseline-reliability.json`.
- Release requires final-source tests, exact signed-byte native runtime,
  v1.0.0 in-place upgrade preserving all eight saves/settings, CI, immutable new
  tag, verified draft and anonymous published downloads. A successful build,
  desktop run or debug CI cannot substitute for missing release-package tests.

## Confirmed findings and decisions

| Severity / location | Trigger and evidence | Change and regression |
| --- | --- | --- |
| P1 `scripts/app/save_manager.gd:116`, mutation methods; `scripts/app/main.gd:476` | Unwritable temp path: old `record` returned no error, UI still claimed records were safe. Backup copied directly over last backup; no short-write verification. Nine old-code fixture failures retained. | All mutation methods return Error; pending memory progress retained with `dirty`/`last_error`; one signal per failure episode, localized feedback, foreground retry and an explicit unsaved-exit choice. Verify temp contents before rotation; stage/verify backup before replacement. Tests cover open, partial-write, backup staging, primary rename, retry, reset, restart and UI. |
| P1 `save_manager.gd:40` | Syntactically valid primary with damaged record/settings discarded valid backed-up values. | Valid primary fields win; malformed existing fields recover individually from a valid backup. Malformed primary never replaces a valid backup. Invalid JSON uses the backup, never an uncommitted temp. Version-1 format retained. |
| P2 `main.gd:408` / `number_bloom.gd:undo` | Real final legal swipe reaches full-board results, but no Undo button despite a valid snapshot. | Add localized result Undo; restores board, score, RNG and won flag, clears stopped/snapshot, checkpoints round, preserves earned best. Verified close/reload and restart. Standard 2048 rules unchanged. |
| P2 four static game callbacks | Number Bloom, Tile Trio, Bubble Garden and READY Mochi Hop rebuilt canvas commands every tick while visually stationary. | Skip effect/draw work only while static; input redraws remain, shots/particles/transitions still run. Camera converges within 0.001 design pixel. Same-machine, same-seed 180-frame comparison: each 180 -> 0 canvas rebuilds; all five RGBA images identical. GPU draw-call counts unchanged. |
| P2 current documentation | AGENTS still said private; PRODUCT said unreleased; BUILD/phase notes mixed superseded blockers with current status. | Correct current public v1.0.0 status, explicitly scope old acceptance, preserve failure history and A14 exception. New iteration remains blocked until its own gates pass. |

No confirmed new P0. No claim of a llvmpipe product fix. Original Bouncy Balls
32px balls, 4x6 wall, 150x46 gates, 68px bumpers and paddle are unchanged.

## Eight-game and shared-code review

| Area | Review / current test coverage | Gameplay change |
| --- | --- | --- |
| Fruit Drop | Atomic contact claims precede deferred merge, consumed bodies removed once; velocity bound/overflow grace; seeded natural overflow/retry, physical save restoration and merge regression suite | None |
| Bubble Garden | Swept wall/hex attachment, floating groups, live color pool, 65-angle bounded hint; ordinary-input clears and bounce/frame-rate cases | Idle drawing only |
| Cake Stack | Overlap conservation/perfect tolerance, capped speed, 24-layer retention/camera; natural placement/miss/retry and lifecycle checkpoint | None |
| Bouncy Balls | Gate bits claimed before clones; fixed 64 pool, swept collisions, normal correction, bounded speed, normalized restore and two-second saves; natural four-wave replay/max pool | None |
| Tile Trio | 36 tiles, seven-slot tray, atomic history, 8,000-node hint budget and independent 1,500-board solver; natural loss/Undo and stage clears | Idle drawing only |
| Mochi Hop | 2,000 seeds/50,000 reachable targets; hold/release/cancel, projected landing, camera, pause/restore, natural miss/retry | Idle drawing only |
| Number Bloom | Single-merge move rules, 90/10 spawn checks, RNG Undo replay; actual terminal swipe/recover/reload | Result Undo and idle drawing |
| Jelly Slice | Segment sweep sorted by hit time; claim before scoring; 12 fruit/32 halves/24 trail bounds, Zen and voluntary Finish; no per-hit disk write | None |
| Shared shell | Owned pointer release/cancel, overlay/Back/lifecycle, 40 switches, 995 geometry/schema checks; three portrait ratios and both languages | Save failure/quit feedback |
| Audio | Existing loop endpoint remains bounded; mute/pause/output and shutdown checks; no new resources or networking | None |
| Security/build | Known-secret scan, runtime external-call scan, OFL notices/provenance, export exclusions and existing CI read-only permissions reviewed | No new dependencies/permissions |

Mutable major-version Actions tags remain a supply-chain limitation (P3, no
dependency updates in this iteration); engine/SDK archive checksum checks remain.
Cloud sync, accounts, payment and backend database checks: N/A. Tests use synthetic
isolated save directories, never a user's real primary/backup files.

## Measurement and evidence limits

Idle comparison uses the RX 7900 XT real Compatibility renderer at a 60 FPS cap,
same seed/viewport and 180 sampled frames after 90 settling frames. Reports include
OS process CPU/RSS, frame intervals and engine monitors. Short CPU samples are
noisy and engine monitors can include earlier loading spikes; retain those tails,
do not claim a percentage battery/CPU improvement. Canvas rebuild elimination and
unchanged pixels are the supported result; GPU submissions are unchanged.
No active game is capped to 30 FPS. Physical 60/120 Hz, temperature and power:
DEVICE_UNAVAILABLE / UNVERIFIED.

APK opportunity review: retain both ABIs, complete CJK font, art and notices.
Compressed segment sizes are in the APK report. Font subsetting would reduce
character coverage and require a separate font/render acceptance pass; no
unverified size optimization is shipped in this iteration.

## Android and CI boundary

Historical baseline run [39810409461](https://github.com/seiya058904/mochi-arcade/actions/runs/39810409461)
is development APK SHA-256 `e7d755dd7e15f1619f85c42336a488e2f07a11ab0f34e177661b050914c1a9a3`,
not the signed release. Its raw `PASS_SMOKE_AWAITING_VISUAL_REVIEW` report and 99
screenshots were downloaded; all 99 reviewed in this iteration, with visible
boards, pause returns, settings, licenses and launcher. EGL warnings remain;
the raw report is not rewritten, and historical failed black frames remain FAIL.
The earlier owner-approved exception is restricted to hosted Ubuntu Mesa llvmpipe
background return with adequate exact signed-byte hardware-GPU substitute proof.
It cannot waive this iteration's missing signed runtime or upgrade verification.

Local API 34 AVD exists but no online USB phone/AVD is available. Read-only accel
check reports unavailable hypervisor; AEHD service is stopped. Acceleration-on
startup exits 1 with "x86_64 emulation currently requires hardware acceleration".
Both no-acceleration host-GPU and SwiftShader startup attempts exit
`-1073741819` (`0xC0000005`) before usable ADB. Logs retained under
`.local/iteration-1.1/emulator-*.log`. No driver/service, Hyper-V, registry, BIOS
or LDPlayer changes were made. This is an emulator-host blocker before app install,
not a demonstrated new app crash. Do not repeatedly retry identical boot failures.

Exact signed APK install, eight games x three returns, signed load/audio, old APK
upgrade, clean install/uninstall and on-device damaged-save recovery: BLOCKED.
API 24 and other API/device/density profiles: UNVERIFIED. Desktop acceptance and
hosted development-package checks are separately reported.

## Exact next actions

1. Supply an already functioning isolated API 34 AOSP GPU AVD or USB test phone;
   the owner explicitly declined AEHD startup. Keep the system-change
   prohibition in force; no repeated driver-start request is required. Do not replace signing identity or upload secrets.
2. Install the archived anonymous v1.0.0 APK, create/check eight synthetic rounds,
   records and EN/ZH/audio settings, then `adb install -r` the exact new signed
   candidate. Prove preservation and package/version/certificate identity.
3. Run `android_smoke.py --release` and `android_load.py --release` on those exact
   candidate bytes, inspect every raw capture and retain logs, save comparisons,
   startup/icon/audio/load and backup recovery evidence. Rebuild/retest if source
   or packaging changes. Physical quantitative results stay unverified without a phone.
4. Only after the missing gates pass, tag the final release source, create/verify
   draft APK + SHA256SUMS, publish, independently download anonymously and verify
   latest/tag/assets, then perform final clean main/origin sync. v1.0.0 stays fixed.


## Signed candidate and code closeout

- Source commit: `b945bcebaa00df5339ac1b116d411162afdbd19f` (runtime/packaging).
  Later evidence-only commits do not alter the candidate source tree.
- Local artifact: `dist/MochiArcade.apk`, versionName **1.1.0**, versionCode **2**,
  **78,471,916 bytes**, SHA-256
  `fbf636ab9e82b757455b6960274140761d505bde0d80353b1288e53f4c28ab85`.
- Static verification PASS: original certificate, v2/v3, non-debuggable,
  package unchanged, min SDK 24 / target SDK 36, arm64-v8a + x86_64, only VIBRATE,
  zipalign 16 KiB and every ELF PT_LOAD alignment >=16 KiB; font notices and boot
  splash present, no tests/docs/keys/save fixtures in APK. A separate local copy
  is byte-identical; this is NOT an anonymous release-asset download.
- Size is 4,096 bytes above v1.0.0; no size reduction claim. Original compressed
  Godot libraries occupy 49,397,173 bytes and imported CJK font 13,290,643 bytes.
- Full local suite: 19/19 PASS, 48/48 reliability assertions. All seven real-renderer
  replay scripts (covering eight games) PASS; vertical replay includes a retained
  earlier timeout and independent successful rerun. Actual desktop audio PASS.
- Source is integrated directly into existing public main; repository protection
  and rulesets are empty, so no PR/merge approval is required. The temporary local
  work branch was fast-forwarded and removed after integration; no remote branch
  or stash was created. Final per-commit CI is checked separately; the local
  `.local/iteration-1.1/closeout.json` and final delivery report record its exact
  SHA, run, downloaded reports and visual review. Signed Android install, runtime,
  load, old-version upgrade and publication remain BLOCKED, not PASS.
- The owner explicitly declined starting the already-installed AEHD service.
  Keep that service stopped; do not retry this system change or request secrets.
  Resume Android acceptance only in an already functioning test environment.


### Additional P1: unreadable is not empty

A real Windows ACL fixture (read denied, replacement allowed) proved that the
first candidate could load a 9999-point primary as empty and overwrite it with
1 point while returning OK. This is a pre-existing load error distinction bug,
confirmed during the final audit, not a permission change to user files. The
repaired loader records I/O errors separately from missing/malformed JSON and
blocks replacement of unreadable data, including access lost during a session.
An explicit localized message explains checking access and reopening the app;
pending progress is not falsely described as saved. The same ACL experiment now
returns Error 12 and leaves the 9999-point primary intact. ACLs on the task's
synthetic fixture were restored. CI also runs portable fault regressions.
The first signed candidate (source `37c9a87`, SHA-256 `96531cb4bd98712a43b8f76e09236e200a1a84cbdb0af4eb56e0fc1278cbc81c`) is superseded and retained locally; it must not be published.

### Failed-exit cancellation regression

Final review found that Stay here dismissed the failed-save dialog without
resuming an active game. Two actual-button regression cases fail before the
repair and pass afterward: resume an active round, or retain result actions for
a stopped round. The 48-check reliability suite includes both. The earlier
comparison harness timed out because it called a helper absent from the old
implementation; that harness was corrected to click the actual button on both
versions, without weakening either assertion. Raw logs remain local.

### Development CI evidence scope

Run [39922816834](https://github.com/seiya058904/mochi-arcade/actions/runs/39922816834)
passed on `b14091b8445bfa2832d57073abf476f533b892de`; all 99 smoke and 10
maximum-pool Android captures were visually reviewed. The raw reports and EGL
logs are unchanged. This earlier green run does not validate later read-error or
exit-cancellation changes. Final main is independently checked in Actions before
closing this task; its downloadable artifacts are authoritative for that SHA.
No new tag/draft/stable release is created while signed Android gates are blocked.

### Authorized hosted signed-byte acceptance

The owner kept the prohibition on starting AEHD, then explicitly authorized a
sequence exception: an unpublished draft may stage the locally signed APK before
upgrade acceptance. The existing Actions AOSP emulator can fetch the exact
checksum-pinned bytes with its repository token; no private key/DPAPI/password is
uploaded. `fetch_staged_release.py` verifies both APK hashes, original certificate,
versions and non-debuggable manifests. `android_upgrade.py` uses real old-version
rounds plus named synthetic record fixtures, compares both save files across
`install -r`, exercises restored games and damaged/read-denied saves, then checks
ordinary uninstall before the independent candidate clean-install smoke/load.
All raw assertions/black-frame gates remain. A staged draft is not a published release.

Final desktop replay invocation initially omitted the required `--fixed-fps 60`,
causing frame-count-based tests to fail at the wrong simulated time. Those failed
results are retained separately. Re-running all seven real-renderer scripts with
the same fixed simulation clock as `run_checks.py` passes all eight game paths;
this is renderer/input correctness evidence, not real-time performance evidence.

### Validated backup read

A deterministic path-change fault after successful decoding reproduced an empty
backup caused by an unchecked second read. The writer now serializes the already
validated previous dictionary into the verified backup staging file; no second
read can replace the backup with empty data. The pre-fix failing case is retained
and all 48 reliability assertions pass. Same-disk ABBA save-flush timings are in
`evidence/iteration-1.1/save-io-profile.json`; integrity checks add I/O cost, so
this change makes no saving-speed claim. APKs produced before this repair are
superseded, including the first staged candidate; retain their hashes/run scopes.
