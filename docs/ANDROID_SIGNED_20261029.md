# Signed 1.1.1 acceptance — 2026-10-29

**RELEASE_READY in the tested local Android scope; publication verification follows below.**
The owner requested completion of signed acceptance and publication after the gates.
This fresh signed-byte acceptance replaces the missing local candidate evidence;
it does not change historical hosted failures into passes.

## Frozen identity and environment

- Version 1.1.1, code 3; `io.github.seiya058904.mochiarcade`.
- Original candidate build S: `920f39cfc29fc0d46b03a295f25f1197446a4027`.
- Test tools T: `bf786e1052314345d82e2fc25181f766b8ac510f`.
- APK SHA-256: `09cab2dee4bbcd03f478286fb378eebce59a5edc4b501ba583cad5fb426459f8` (78,471,990 bytes).
- Signing certificate SHA-256: `de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b`.
- Original draft 421777385, asset IDs 668954574 and 668954575. No rebuild or re-signing.
- Independent fresh API 34 x86_64 AVDs, Windows, AEHD 2.2, AMD RX 7900 XT host GPU,
  720×1280. Every run records the actual GLES renderer and terminates its owned AVD.
  Existing user AVD data and service configuration were not changed.

All candidate runtime/export Git blobs match T. The sole added asset is
`assets/art/readme-cover.svg`, referenced only by README; this documentation image
is explicitly excluded from runtime equivalence, not silently treated as identical.
APK versions, release certificate, v2/v3 signature, non-debuggable status, VIBRATE-only
permission, arm64-v8a/x86_64 and 16 KiB alignment were checked on downloaded bytes.

## Four complete gates

| Gate | Result | Run | Reviewed PNG/video files |
| --- | --- | --- | --- |
| U110 | PASS reviewed | local-20261029-attempt3-U110 | 134 |
| U100 | PASS reviewed | local-20261029-attempt4-U100 | 134 |
| CLEAN | PASS reviewed | local-20261029-attempt3-CLEAN | 105 |
| LOAD | PASS reviewed | local-20261029-attempt3-LOAD | 11 |

CLEAN covers eight games × three background returns, process/checkpoint continuity,
actual input, force-stop restore, zero-score restart, settings, launcher and uninstall.
Both upgrades first exercise their original published predecessor, then install the
exact candidate in place and verify all eight semantic round/record restores,
actual terminal Bloom/Trio Undo, subsequent input, damaged JSON/fields/settings
recovery and read-denied preservation. LOAD separately verifies Bouncy Balls and
Jelly Slice maximum-object scenarios and restoration of both primary and backup.
The original `summarize_android_gates.py` accepted all four matching S/T/hash/profile
receipts plus exact visual-file hashes; none of its acceptance assertions were relaxed.

Local transport copies change only explicit owned-process/isolated-AVD authorization,
truthful environment labeling and serial selection. Per-gate diffs are retained.
No hosted-runner identity was fabricated. CLEAN/U110 initially ran alongside an
independent U100; the final U100 repeat and LOAD ran alone. Load numbers therefore
come from the separate LOAD run, not the concurrent smoke runs.

## Test-tool correction and retained failed attempts

Windows ADB returns CRLF. The former exact LF-only package-version assertion rejected
an installed 1.1.0 even though raw dumpsys correctly reported it. Text normalization
now converts CRLF to LF; binary save/screenshot bytes remain untouched. UTF-8 is
explicit for upgrade reports/logs. The added regression failed before the fix and
passed afterward; 20 targeted Python tests passed. Current-tool
[CI 40827126343](https://github.com/seiya058904/mochi-arcade/actions/runs/40827126343)
passed all 24 required suites and built the development APK. That build is not the
signed release artifact. Earlier local 24-suite execution also passed.

An initial process interruption produced no acceptance claim. Attempt 2 CLEAN passed,
but U110 hit the Windows text assertion; neither was reused in the final aggregate.
Attempt 3 U100 failed before candidate installation: the predecessor's Bouncy Balls
round ended during capture, leaving both background/returned sessions null. Native
captures show its normal result screen. This failed test precondition is preserved;
one isolated fresh-AVD repeat used the same tools/assertions and completed the gate.
Concurrent scheduling as the trigger is an inference, not a demonstrated root cause.

## Limits and evidence retention

The [hosted software-GPU environment exception](LOCAL_ANDROID_CI_EXCEPTION_20261023.md)
still applies. Historical CLEAN/U110 black returns and emulator crashes remain FAIL
in [the old audit](ANDROID_UNBLOCK_1.1.1.md); this work does not prove their engine cause
fixed. Local startup footage includes plain transitions and a brief noisy/dark frame
before the custom splash, with Android's first-use full-screen overlay. Stable game
and background-return captures were reviewed; zero startup artifacts are not claimed.

Physical ARM64 phones, other API/device coverage, thermal/battery measurements and
captured/listened Android PCM remain UNVERIFIED. Native audio enable/resume state is
tested separately from audible quality. Emulator compositor measurements are not
phone FPS. These retained limits make the delivery CLOSED_WITH_LIMITATIONS.

[Structured acceptance receipts and reviewed contact sheets](evidence/signed-local-20261029/)
preserve identities, source equivalence, assertions, file hashes, visual reviews,
tool diffs and the relevant failed attempt. Full raw logs/captures and disposable AVD
disks are in the dashboard's current task directory, subject to its scoped retention
rules; this compact formal record is committed in Mochi and has no 48-hour policy.

## Publication verification

Pending publication of the existing draft after this evidence commit is synchronized
and its current CI succeeds. Public-download, latest-release and tag checks must be
recorded before calling A15 complete. Existing v1.0.0/v1.1.0 assets remain unchanged.
