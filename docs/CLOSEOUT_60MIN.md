# Bounded final closeout — 2026-10-23

Owner-authorized window: **14:46:46–15:46:46 UTC** (22:46:46–23:46:46 Asia/Shanghai).
This replaces the open-ended surface/custom-engine investigation. No new engine,
renderer, local AVD, system setting, feature, storage format or release-gate change.

## Delivered tool correction

Previously the smoke harness read a fixed UIAutomator path after exit 0, even
when no new XML existed. The new collector uses a unique, verified-absent path,
requires a readable, non-empty, parseable hierarchy, removes stale local output,
and retains stdout/stderr, exit/timeout and actual foreground evidence. Missing
XML is a **capture FAIL / icon UNVERIFIED**, never evidence of a broken app icon.
No capture failure is retried or ignored. Independent smoke checks may continue,
but a launcher failure still makes the smoke gate FAIL.

The existing real drawer-icon tap now also requires the application's resumed
activity, a live PID and a visible screenshot. A direct `am start` fallback is
only independent test setup; it cannot satisfy launcher acceptance.

Direct local regressions: 7 UI collector/launcher tests, 6 save restoration tests,
6 release-tool tests. The UI suite covers zero-exit/missing files with stale local
and remote data, empty/malformed/wrong-root XML, command/read/timeout failure,
fresh successful captures, occupied-path preservation, foreground false positives,
and separate diagnostic streams. The suite is included in required CI checks.

## Frozen application and Android scope

This is an **acceptance-tool reliability update**, not an application update.
F1–F3 and runtime/export inputs are unchanged. Retain the original signed,
unpublished 1.1.1/code 3 candidate at `dist/MochiArcade.apk`, SHA-256
`09cab2dee4bbcd03f478286fb378eebce59a5edc4b501ba583cad5fb426459f8`.
Do not rebuild/re-sign it. Published v1.0.0/v1.1.0 tags and assets stay fixed.

Use exactly one final main push's existing hosted API 34 CLEAN/LOAD CI run.
Its automatically built **development APK** is separately identified and cannot
replace signed candidate acceptance. Review home, eight representative games,
Cake/Hop returns and failures actually reached. Retain exact APK hashes, reports,
restoration outcomes and host process release evidence in its existing artifacts.
Historical signed run 39961466842 remains **U100/LOAD PASS; U110/CLEAN FAIL**
(public 1.1.0 Hop and candidate Cake black returns). No stable 1.1.1 release.

## Scoped artifact retention

Initial root total: **1,760,539,817 bytes**, including `.git`, hidden and ignored
regular files, excluding link traversal (no links observed). Initial branches:
local/remote `main` only; one original worktree; clean Git state and no stash.

- Preserve source/assets/licenses, Git, `dist/MochiArcade.apk` and checksum,
  signing material outside Git, unique failures, saves and restoration evidence.
- `.local/iteration-1.1*/` contains historical downloads/observations, not a
  disposable tree. Remove only inventoried redundant APKs, superseded temporary
  candidates/debug builds, or files proven byte-identical to retained evidence.
- Compare SHA-256 before removal. Record exact path, byte count, reason and
  retained counterpart in `.local/closeout-60min/`; use recoverable recycling.
- `.local/closeout-60min/` retains this session's measurements, deletion receipts,
  CI identity, visual review and short final delivery record. It is already
  ignored by `.local/`; ignored status is never automatic deletion authority.
- Shared SDKs/tools, other projects, keys and unknown files are out of scope.
  Existing CI acquires checksum-verified engine/templates/SDK tools as documented
  in `.github/workflows/ci.yml`; no extra project-local tool copy is needed.

## Exact closeout actions and stopping boundary

After this commit, observe the single final CI, complete the explicit cleanup,
fetch/prune and verify HEAD/main/upstream/origin/main plus live remote refs,
zero ahead/behind, clean status, main-only branches, one worktree, and root bytes
below 1,000,000,000. Stop development at minute 40; cancel this round's unfinished
jobs by minute 55, recording CANCELLED/TIMEOUT and any failed restoration.
Record dynamic results locally and in the final reply, without a report-only
commit triggering another CI. End by the deadline; no automatic research round.
