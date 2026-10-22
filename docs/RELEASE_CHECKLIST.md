# Release gates — not release ready

Updated 2026-10-22. Desktop acceptance does not satisfy Android gates.

| Gate | State | Evidence / remaining work |
| --- | --- | --- |
| A01 One app / APK | PASS development / signed runtime pending | All eight in one package; actual bunny launcher entry opens the home screen in 39669849881 |
| A02 Eight complete games | PASS desktop + Android development smoke | Eight implemented loops, natural-action replays and actual Android input/boards; final signed-byte confirmation pending |
| A03 Correct gameplay | PASS desktop | 18 required suites; rules, collision, save, lifecycle and real scene input |
| A04 Valid procedural content | PASS | Independent Trio solver: 1,500 boards; Hop: 2,000 seeds / 50,000 targets |
| A05 Android controls | BLOCKED; intermittent black return reproduced | Run 39699385661 on 28a8a45 reproduces a fully black Fruit Drop background return: still black after 5 s, visible only after a new surface cycle with the same PID, with EGL_BAD_SURFACE in the guest log. Run 39698026180 separately verified the new edge-target taps and four game paths before a Bouncy Balls harness precondition. Run 39673516558 had passed all eight paths and 24 returns. No attached physical device; no release may be tagged while this reproduces |
| A06 Cohesive art | PASS desktop + tested Android viewport | Original production art; three desktop ratios; 87 actual 720x1280 Android views reviewed in labeled sheets. Bouncy Balls scale revision measured before/after (22->32 px ball, 4x6 brick wall, 150x46 gates, 68 px bumpers, paddle unchanged) with post-change 720x1280 Android views retained (ready, 64-ball packed and spread); owner visual acceptance on a phone still pending |
| A07 Audio | PASS tested Android development path / final signed pending | Native first-loop crash repaired and Android loop survives in 39659761708; nine mixer-boundary regressions and real desktop mute/pause/output checks pass |
| A08 Persistence | PASS tested development path / signed pending | All eight freezes/round restores, five settings and exact complete-save preservation after same-signature reinstall; damaged-save recovery suite passes |
| A09 Compatibility / performance | BLOCKED | Runs 39698026180 and 39699385661 both execute both maximum pools on one online AVD with final host state, continuous logcat and exact save restoration: Balls 3.84 / 3.60 FPS, Jelly 7.19 / 5.04 FPS (p95 250-661 ms). These are software-renderer compositor intervals, not phone FPS. Earlier 6.01/8.91 and 3.55/AVD-loss samples remain retained. Intermittent black surface return still reproduces; stable physical performance is unverified |
| A10 Security / provenance | PASS bounded candidate audit | Known credential-pattern history scan, documented original art/fonts, bundled offline notices; candidate has only VIBRATE and excludes private/dev files |
| A11 Reproducible build | PASS development | Pinned engine/template, SDK CLI checksum, local + hosted debug export; signed rebuild pending |
| A12 Verified installable APK | PARTIAL | Development APK installs/starts/renders; actual launcher icon verified; signed candidate rebuilt from the final commit but not installed. Physical-device signed-byte acceptance DEVICE_UNAVAILABLE |
| A13 Clean synchronized Git | IN_PROGRESS | Takeover commits 3a8c7ec and 32df767 pushed to origin/main after recovering and validating the unpushed hit-region work; harness-fix commit and final clean state pending |
| A14 Final-SHA CI | FAIL on current tip | 39698026180 (32df767): 18 suites/APK pass; Android stops at Bouncy Balls harness precondition. 39699385661 (28a8a45, harness fix): 18 suites/APK/edge taps pass; Android stops at a black Fruit Drop background return. The blocker is intermittent; a green run is required on the exact final SHA before release |
| A15 Release | NOT_PUBLISHED | No tag or stable assets until preceding hard gates pass |

Current unresolved release blockers: intermittent Android background black, performance acceptance, exact-final-commit CI/download checks and final signed-package/runtime confirmation.
Secure local release signing and measured desktop audio verification have passed.
Physical-phone performance will remain explicitly unverified if acceptance uses an emulator.
