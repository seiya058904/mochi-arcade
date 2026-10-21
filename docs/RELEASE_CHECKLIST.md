# Release gates — not release ready

Updated 2026-10-22. Desktop acceptance does not satisfy Android gates.

| Gate | State | Evidence / remaining work |
| --- | --- | --- |
| A01 One app / APK | PARTIAL | Development APK contains all eight; final signed package pending |
| A02 Eight complete games | PASS desktop / Android PENDING | Eight implemented loops, natural-action replays, results/retry and 34-screen matrix |
| A03 Correct gameplay | PASS desktop | 18 required suites; rules, collision, save, lifecycle and real scene input |
| A04 Valid procedural content | PASS | Independent Trio solver: 1,500 boards; Hop: 2,000 seeds / 50,000 targets |
| A05 Android controls | FAIL first lifecycle review / fix pending Android | Swangle renders all eight. Back automatic engine exit fixed locally; stronger Trio/pause/resume/restart/background checks await rerun |
| A06 Cohesive art | PASS desktop / Android PENDING | Original AI production art integrated; three ratios, EN/ZH, all games and overlays reviewed |
| A07 Audio | Android FAIL / endpoint fix pending rerun | Native AudioTrack crash identified at first WAV loop; bounded endpoint and nine mixer-boundary regressions pass locally; Android repeat pending |
| A08 Persistence | PASS desktop / Android PARTIAL | Settings/records survive actual force-stop; eight individual round restores and same-signature reinstall await strengthened run |
| A09 Compatibility / performance | PARTIAL | Desktop clipping/lifecycle and bounded-load checks pass; actual Android logs pending |
| A10 Security / provenance | PASS bounded candidate audit | Known credential-pattern history scan, documented original art/fonts, bundled offline notices; candidate has only VIBRATE and excludes private/dev files |
| A11 Reproducible build | PASS development | Pinned engine/template, SDK CLI checksum, local + hosted debug export; signed rebuild pending |
| A12 Verified installable APK | PARTIAL | Development APK installs/starts/renders on actual API 34; lifecycle repair and final signed-byte runtime acceptance pending |
| A13 Clean synchronized Git | IN_PROGRESS | Milestone commits/pushes; final clean state pending |
| A14 Final-SHA CI | NOT_RUN | All-eight checkpoint da1d397 passed 39647458113; current/final SHA awaits CI |
| A15 Release | NOT_PUBLISHED | No tag or stable assets until preceding hard gates pass |

Current unresolved release blockers: Android execution, exact-final-commit CI/download checks and final package/runtime confirmation.
Secure local release signing and measured desktop audio verification have passed.
Physical-phone performance will remain explicitly unverified if acceptance uses an emulator.
