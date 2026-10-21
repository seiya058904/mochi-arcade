# Release gates — not release ready

| Gate | State | Evidence / remaining work |
| --- | --- | --- |
| A01 One app / APK | PARTIAL | Early debug APK has one package; not all games implemented |
| A02 Eight complete games | NOT_RUN | Three playable games; five pending |
| A03 Correct gameplay | PARTIAL | 14,278 logic + 47 slice + 29 Fruit checks; normal-drop playthroughs |
| A04 Valid procedural content | NOT_RUN | Tile solver / Hop reachability pending |
| A05 Android controls | BLOCKED | Existing AVD offline; no connected device |
| A06 Cohesive art | PARTIAL | Two concepts, production sprites, first desktop review |
| A07 Audio | PARTIAL | Original synthesis and settings; audible verification pending |
| A08 Persistence | PARTIAL | Atomic-save/recovery and 2048 session/undo tests pass |
| A09 Compatibility / performance | NOT_RUN | Desktop aspect checks only; Android pending |
| A10 Security / provenance | PARTIAL | Original art/fonts documented; full audit pending |
| A11 Reproducible build | PARTIAL | Local debug export succeeds; CI pending |
| A12 Verified installable APK | BLOCKED | APK metadata inspected, Android install not run |
| A13 Clean synchronized Git | IN_PROGRESS | Milestone synchronization in progress |
| A14 Final-SHA CI | NOT_RUN | First run failed SDK setup; pinned tool installation fix pending rerun |
| A15 Release | NOT_PUBLISHED | Withheld until all preceding gates pass |
