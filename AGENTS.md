# Mochi Arcade

Follow the user's global rules and `docs/SOURCE_TASK.md` (adopted master task v1.1).
The user's overrides are authoritative: app **Mochi Arcade**, repository **mochi-arcade**,
release artifact **MochiArcade.apk**. G06 is **Mochi Hop**, never Color Maze.

- Work only in this repository. No subagents. Preserve unrelated work.
- One Godot 4.7.2 stable GDScript project, Compatibility renderer, portrait Android.
- Eight isolated game scenes/state machines, shared shell/settings/save/audio.
- Follow the phases in `docs/IMPLEMENTATION_PLAN.md`; complete and verify each game
  before starting the next. Never replace playable content with a screenshot.
- Use real image generation for concepts and production art; record provenance.
- Existing remote is public: seiya058904/mochi-arcade, default branch main.
  v1.0.0, v1.1.0 and v1.1.1 are recorded as published; never replace their tags or assets.
  Verify current release metadata when relevant. Historical task authorization does not authorize a new push, release or other remote change; follow the user's current scope.
- Stable Release is authorized only after all A01-A15 gates and Android runtime
  acceptance. Never publish a debug signature as a stable release.
- Keep keys/passwords outside Git; use environment overrides for export signing.
- README is English only. Logs must distinguish PASS, FAIL, NOT_RUN, BLOCKED,
  DEVICE_UNAVAILABLE and UNVERIFIED. Desktop evidence is not Android evidence.
- Before stopping, update the phase board and QA evidence with exact next actions.

## Android Development

For any Android-related build, debugging, device automation, or testing task, read `docs/ANDROID_WORKFLOW.md` before proceeding. Use the shared Windows toolchain, Mobile MCP, scrcpy and ADB as documented. Prefer physical-device testing for daily work and cloud emulator tests when specifically required. Follow repository-specific instructions and safety requirements.
