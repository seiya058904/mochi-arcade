# Release gates — not release ready

Updated 2026-10-22. Desktop acceptance does not satisfy Android gates.

| Gate | State | Evidence / remaining work |
| --- | --- | --- |
| A01 One app / APK | PASS development / signed runtime pending | All eight in one package; actual bunny launcher entry opens the home screen in 39669849881 |
| A02 Eight complete games | PASS desktop + Android development smoke | Eight implemented loops, natural-action replays and actual Android input/boards; final signed-byte confirmation pending |
| A03 Correct gameplay | PASS desktop | 18 required suites; rules, collision, save, lifecycle and real scene input |
| A04 Valid procedural content | PASS | Independent Trio solver: 1,500 boards; Hop: 2,000 seeds / 50,000 targets |
| A05 Android controls | BLOCKED intermittent background black | Host run 39670759820 passes all eight paths; same-source Lavapipe 39670750928 returns black. Three-return coverage per game is pending; one successful run does not establish stability |
| A06 Cohesive art | PASS desktop + tested Android viewport | Original production art; three desktop ratios; 87 actual 720x1280 Android views reviewed in labeled sheets, with selected original captures retained |
| A07 Audio | PASS tested Android development path / final signed pending | Native first-loop crash repaired and Android loop survives in 39659761708; nine mixer-boundary regressions and real desktop mute/pause/output checks pass |
| A08 Persistence | PASS tested development path / signed pending | All eight freezes/round restores, five settings and exact complete-save preservation after same-signature reinstall; damaged-save recovery suite passes |
| A09 Compatibility / performance | BLOCKED | Intermittent background black remains. Both maximum pools visibly execute; host software-renderer FPS is 6.01 / 8.91, with slower Lavapipe samples retained. Performance is not passed and phone FPS is unverified |
| A10 Security / provenance | PASS bounded candidate audit | Known credential-pattern history scan, documented original art/fonts, bundled offline notices; candidate has only VIBRATE and excludes private/dev files |
| A11 Reproducible build | PASS development | Pinned engine/template, SDK CLI checksum, local + hosted debug export; signed rebuild pending |
| A12 Verified installable APK | PARTIAL | Development APK installs/starts/renders; actual launcher icon verified; intermittent surface recovery and final signed-byte acceptance pending |
| A13 Clean synchronized Git | IN_PROGRESS | Milestone commits/pushes; final clean state pending |
| A14 Final-SHA CI | NOT_RUN final / PASS checkpoint | a032fde host diagnostic 39670759820 passes; same-source Lavapipe comparison fails. Updated/final SHA awaits CI |
| A15 Release | NOT_PUBLISHED | No tag or stable assets until preceding hard gates pass |

Current unresolved release blockers: intermittent Android background black, performance acceptance, exact-final-commit CI/download checks and final signed-package/runtime confirmation.
Secure local release signing and measured desktop audio verification have passed.
Physical-phone performance will remain explicitly unverified if acceptance uses an emulator.
