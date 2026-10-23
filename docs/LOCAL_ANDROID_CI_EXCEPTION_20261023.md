# Local Android retest and hosted CI exception — 2026-10-23

## Result and owner decision

The exact development APK from failed hosted run **39973324265** was retested on
an isolated local Pixel 2 AOSP Android 14 / API 34 x86_64 AVD, 720×1280, using
**AMD Radeon RX 7900 XT host GPU** and AEHD 2.2. SHA-256:
`7d59199cf4a720c29015c0e18b3431a12811110242be26586525ed4a49061d9e`.

**PASS_LOCAL_BACKGROUND_RETURN:** eight games × three background returns,
checkpoint equality, same-process returns, foreground input, force-stop restore,
restart, launcher icon, settings and same-signature reinstall preservation.
101 asserted frames were nonblank, no matched runtime errors. The 24 return
frames were visually reviewed in the [labeled contact sheet](evidence/local-api34-hostgpu-2026-10-23/24-background-returns.png),
with the Bouncy Balls first return also inspected at original resolution.
[Structured result, original report digest and complete raw-file manifest](evidence/local-api34-hostgpu-2026-10-23/background-return.json).

The existing smoke implementation at `c7fedf3` ran unchanged. An external local
wrapper replaced only the hosted ownership check with verified isolated local
AVD ownership, and corrected the output environment label. No app assertions,
visibility threshold, timeout or game coverage were relaxed. Original Pixel AVD
data/configuration and user saves were untouched. Temporary AVD and raw evidence
are retained inside the dashboard repository, at the exact location in the result.
After testing the owned AVD was stopped and AEHD restored to its original stopped
state, with no startup configuration changes.
43 swap warnings occurred without a failed asserted return; those warnings alone
are not proof of the hosted root cause.

The owner instructed: reproduce locally; if local testing passes, exclude the
hosted emulator check from automatic CI. Recorded as
**OWNER_APPROVED_HOSTED_ENVIRONMENT_EXCEPTION**, not an app fix or a retroactive
PASS. The same APK passes locally and fails on hosted software GPU; the exact
underlying Godot/emulator/driver root cause is **UNVERIFIED**.

## CI behavior

- Push and pull-request CI use a single BUILD matrix entry. Required rules,
  integration and Python tool tests still execute, and the development APK builds
  with the existing pinned tools. Test/build failures still fail the workflow.
- Emulator package installation, AVD smoke, process finalization and runtime
  evidence upload run only for explicit manual runtime gates.
- Manual DIAG/U110/U100/CLEAN/LOAD/ALL gates, their strict assertions and signed
  candidate transport remain available. A manually observed failure remains FAIL.
- Existing failed runs and all old evidence are retained. No Release/tag/asset,
  signing material, application code, renderer or dependency was changed.

This retest is of the failed CI **development APK**, not the frozen signed 1.1.1
candidate. Physical-phone coverage, complete visual/play acceptance and signed
CLEAN/U110 acceptance were not newly executed. No stable release is authorized by
this CI configuration change; previous signed failures keep their original status.

## Checks

Local smoke completed successfully; 19 Python tool regressions passed. Candidate
YAML parsed and its actual matrix expression evaluated for push, pull request and
all six manual gate choices; runtime guards and unchanged test/build steps checked.
The subsequent pushed workflow result is recorded separately so this report does
not claim a CI run before it happens.
