# Mochi Arcade

Follow `docs/SOURCE_TASK.md` (v1.1) and user overrides: app **Mochi Arcade**, repo **mochi-arcade**, release artifact **MochiArcade.apk**; G06 is **Mochi Hop** (never Color Maze).

- One Godot 4.7.2 stable GDScript project, Compatibility renderer, portrait Android; 8 isolated game scenes/state machines with shared shell/settings/save/audio.
- Follow phases in `docs/IMPLEMENTATION_PLAN.md`; complete and verify each game before starting the next. Never replace playable content with a screenshot; use real image generation with provenance.
- Public remote `seiya058904/mochi-arcade` (`main`): `v1.0.0`, `v1.1.0`, `v1.1.1` are published — **never replace their tags or assets**. Historical authorization grants no new push/release.
- Stable Release requires all A01–A15 gates and Android runtime acceptance; **never publish a debug signature as a stable release**. Keep signing keys/passwords outside Git (env overrides only).
- README is English only. Logs must distinguish `PASS`, `FAIL`, `NOT_RUN`, `BLOCKED`, `DEVICE_UNAVAILABLE`, `UNVERIFIED` (desktop evidence ≠ Android evidence). Update phase board and QA evidence with exact next actions before stopping.
- Android device build/debug/testing: read `docs/ANDROID_WORKFLOW.md` (or load global `android-device-workflow` skill).
