# Initial audit — 2026-10-21 (Asia/Shanghai)

Owner: current Codex session; no delegated agents.

## Boundary and baseline

- Target: `D:\xia zai\AI project\Project in Iteration\Mochi Arcade`.
- Observed empty directory; no Git root, files or pre-existing changes.
- No claim of auditing nonexistent game code. Initial work is environment/product audit.
- Adopted source: `D:\下载\Mellow_Pocket_Codex_Master_Task_v1.1.md`.
- User overrides: Mochi Arcade / mochi-arcade / MochiArcade.apk.
- GitHub connector and local CLI both identify `seiya058904` (ID 283110290).
- Repository lookup initially returned 404; a new private repository is intended.
- Git 2.54.0.windows.1; GitHub CLI 2.95.0; authenticated via system keyring.
- Local Java re-detected: Temurin OpenJDK 17.0.20.1.
- SDK: `%LOCALAPPDATA%/Android/Sdk`; currently Build Tools 34.0.0 / platform 34.
- Godot export directory 4.7.2.stable exists but lacks Android templates.
- Android AVD `Codex_Maestro_Android34` exists, x86_64 / API 34 /
  1080x2280 / 440 dpi / 4 CPUs / 2 GB. No device running at baseline.
- Image generation built-in tool is available; skill read and concepts requested.

## Risks and planned proof

| Risk | Required mitigation / evidence |
| --- | --- |
| Engine/toolchain mismatch | Execute binary version; match official export templates; early APK install |
| Multiball explosion / tunneling | Fixed-size ball pool; capped splits; swept collisions; stress measurements |
| Tile Trio unsolvable content | Construct valid reverse deals and validate independent solver batches |
| Bubble connectivity / soft locks | Hex-neighbor flood fill and top-connected flood fill; active-color shot pool |
| Hop unreachable targets / interrupted hold | Deterministic world-coordinate landing; 1000+ seeds; cancellation tests |
| 2048 double merge / invalid spawn | Pure deterministic row/board operations; canonical regression cases |
| Fruit duplicate merges | Consume pair atomically before deferred physics mutations |
| Slice missed fast swipes | Segment-circle sweep; one-shot consumed state |
| Art consistency | Compare concepts; alpha/edge checks; two complete runtime visual reviews |
| Save corruption / lifecycle | Atomic temp/backup writes; corrupted-file tests; background/force-stop tests |
| Signing continuity | Private external keystore + OS-protected password; certificate fingerprint |
| Overclaiming emulator results | Label emulator evidence; physical-device performance remains UNVERIFIED |

## Current gaps

Godot executable location, Android templates, SDK 35 tools, runtime boot,
production artwork, all game implementations and release signing still require verification.

## Official references checked

- https://godotengine.org/download/archive/4.7.2-stable/
- https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html

The 4.7 Android guide specifies JDK 17, platform/build tools 35/35.0.1 and
supports signing overrides through environment variables. The simple prebuilt
APK export path is preferred; custom Gradle/NDK work is not required by this app.

