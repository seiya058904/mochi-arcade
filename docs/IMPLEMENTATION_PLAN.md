# Implementation board

Owner: current Codex. Started 2026-10-21. Goal stays active until delivered or
an evidenced external blocker prevents all meaningful progress.

| Phase | Status | Exit evidence |
| --- | --- | --- |
| 0. Boundary / environment / risk audit | PASS | Empty boundary verified; official engine/template checksums; SDK/JDK/device inventory |
| 1. Git / private remote / CI scaffold | PASS | Private origin/main synced; full CI 39638293273 green on 3099316 including Android debug build |
| 2. Art direction / shared shell / early Android | PASS | Production art and shell rendered; actual hosted Android install and eight rendered views confirmed |
| 3. Cake Stack + Number Bloom vertical slices | PASS (desktop) | 14,278 logic + 47 integration assertions pass; screenshots and native input recheck |
| 4a. Fruit Drop | PASS (desktop) | 29 physics/rule checks PASS; 251 normal-action drops reach tier 7 and natural overflow; rendered art and native aim/release checked |
| 4b. Bubble Garden | PASS (desktop) | 1,364 checks; 5 gardens cleared in 33 hinted shots; 73 shots reach natural loss; alpha art and footer reviewed |
| 4c. Mochi Hop | PASS (desktop) | 2,000 seeds / 50,000 platforms; 550,008 rule + 47 runtime assertions; 40-hop real-scene input replay, natural miss/retry, screenshots |
| 4d. Tile Trio | PASS (desktop) | 1,500 solver-verified boards, 439,506 rule + 23 runtime checks; 5 shops / 187 input picks / natural full tray / free result undo / restart; actual screenshots |
| 4e. Bouncy Balls | PASS (desktop) | 236,650 checks; real x2/x3 gates; 60-second 64-ball stress; normal input clears 4 waves, reaches 64 balls, naturally loses/retries; rendered captures |
| 4f. Jelly Slice | PASS (desktop) | 7,224 checks; 108,000 stress swipe events; real-input 60-second Zen round slices 150 fruit, naturally misses 7, finishes/retries via buttons; original whole/half art reviewed |
| 5. Integration / lifecycle / stress audit | PASS (desktop) | 18 required suites; 935 full-collection checks, 40 switches, damaged-save recovery and three viewport profiles |
| 6. Complete visual reviews + targeted fixes | PASS (desktop) | 34 actual renderer captures; EN/ZH, home, eight games, settings, help/pause; board fit, mipmaps and text contrast fixed |
| 7. Signed Android acceptance | IN_PROGRESS | Secure local signing verified; Android swangle rendering PASS; stronger Back/lifecycle plus maximum-pool acceptance pending; signing secret approval pending |
| 8. CI / final audit / remote sync | TODO | Clean local/upstream/default SHA match, final-SHA CI green |
| 9. Release and download verification | TODO | Annotated tag, draft assets, independent hash match, publish |

## Current checkpoint

- All-eight-game checkpoint da1d397c29134fd18ec29b26a8cbfdeedeae0f4c passed CI 39647458113. Later hosted Android attempts 39648255774 and 39649666572 passed build/tests/KVM but failed on emulator disk allocation. Current changes add the collection audit and adjust the runtime environment.
- Engine verified: 4.7.2.stable.official.ed1daf0bf; official Android templates;
  JDK 17.0.20.1; SDK/Build Tools 36 for the actual target-36 template.
- Two concepts generated; cream stationery selected; transparent card atlas and
  bunny adopted and inspected in the real renderer. English/Chinese weights fixed.
- Cake and 2048 actual scenes, shared shell, atomic save/backup, audio pool, undo,
  restore and 30-switch integration are implemented. Tests: 14,278 + 47 PASS.
- Native desktop play revealed a lifecycle race; deferred pause creation fixed
  it, regression added, native Number Bloom upward merge now scores 4 correctly.
- Android AVD remains offline in three boot configurations; no hypervisor driver.
  User asked about a USB-debugging phone; Android proof stays BLOCKED, not passed.
- First CI on 75b0573 passed Godot import and all then-current tests, failed because
  sdkmanager was absent from runner PATH. Workflow now installs a pinned official
  CLI archive (build 16111833) with verified SHA256; next push will exercise it.
- Fruit Drop implemented: atomic contact claims, actual circle physics, eight original
  sprites, overflow grace, seeded drop stream and mid-round persistence. 29 tests PASS.
  Normal-action seed 817 / input seed 4182: 251 drops, score 23220, tier 7, natural
  overflow, max 45 fruit, restart empty. Actual rendered captures reviewed.
- Bubble Garden: hex-grid sweep collisions, true rebounds, triple pops, roof-connectivity
  drops, live-color pool, free hint and persistent stages. 1,364 checks PASS, including
  15 angle/frame-rate pairs. Rendered/headless normal-action reports agree exactly.
  Fixed expanded-viewport side gaps; downsampled production sprites and footer reviewed.
- CI run 39638293273 is fully green after moving runner context to step env.
- Hop: original bunny/four sweet platform art, 2D projected-foot landing, capped
  hold distance, deterministic generation, soft edge/perfect scoring, camera and
  robust cancel/pause/restore. 2,000 seeds / 50,000 platforms passed, minimum valid
  hold interval 0.385934 s. 40-hop replay scored 130 then naturally missed and retried.
  Shared touch cancel and toast placement fixes passed current game regressions.
- Tile Trio now passes full desktop acceptance: 36 layered tiles, seven-slot tray,
  exact triples, persistent atomic undo and solver-backed free hints. Five shops clear
  for 2100 points; 187 actual input picks reach full-tray results and recover via Undo.
  Audio shutdown warnings were identified as pending WAV playbacks and fixed by mixer drain.
- Bouncy Balls: exact rounded-rectangle sweeps, responsive paddle, two circle bumpers,
  actual multiplier clones in a fixed 64-slot pool, excess-to-score feedback, bounded
  speed, two-second/lifecycle saves, persistent waves. Stress exposed a grazing-bumper
  correction pointing inward; regression retained and fixed. Rendered ordinary-input
  run clears four waves, catches 134 times, reaches 64 balls, scores 4820 and retries.
- Jelly Slice: four original whole/left/right fruit sets, exact segment swipes,
  claimed-before-feedback single cuts, bounded 12 fruit / 32 halves / 24 trail samples,
  capped combo, analytic flight, Zen misses without penalty, voluntary result/retry.
  All eight now playable; shared clipping contains moving objects inside the play area.
  Earlier stress outliers 321/208 ms remain recorded; two isolated follow-ups had no
  >16.667 ms sample. Cause is unverified; no Android performance inference is made.
- Collection audit: 934 checks / 40 switches pass. Structurally invalid nested rounds
  now fall back safely without losing records; fixed wide-screen 2048 board clipping.
  Test save folders use wall-clock microseconds plus PID, avoiding process-relative collisions.
- Visual matrix: 34 desktop captures at 450x800, 360x800 and 640x800. All layouts
  reviewed; original art mipmaps, tall-home spacing and 4.58:1 minimum muted-text
  contrast on the eight theme surfaces verified. This is not a full accessibility audit.
- Hosted API 34 now boots, installs and starts the app. Legacy SwiftShader GLES
  fails shader linking, retained in android-first-launch.json and real screenshots.
  Next: swangle (ANGLE/Vulkan) rerun, actual fullscreen-tip dismissal, offline input.
- The Google APIs image
  required at least 7,372.80 MB despite the requested 2 GB partition. Standard AOSP
  retains full graphics without Google apps; only three extracted job-owned download
  archives are removed to make room. No local files or unrelated runner tools are deleted.
- Release key and signed 1.0.0 local candidate now exist. Actual mixer output and
  bounded history scan pass; offline font/engine/component notices are available in
  settings. Final signed Android acceptance, final-SHA CI and Release are not done.
  Goal remains active.

## Success criteria

All A01-A15 from `SOURCE_TASK.md` have direct evidence. Eight complete offline
games in one Android APK; no P0/P1 or blocking P2; accurate build/install docs;
matching final local/remote/tag/build commit; verified release-download bytes.

- Prepared a manual-only signed CI path and tested its certificate/temporary-key
  cleanup locally. Awaiting user approval to upload two encrypted repository secrets;
  no private material has left this computer. Developer APK Android QA continues.
- Run 39654367634 passed its automated smoke but manual review rejected Back and
  Trio coverage. All eight rendered views were real Android captures. Fixed the
  missing `SceneTree.quit_on_go_back = false` and deferred notification UI changes;
  935 collection checks and all 18 required suites pass locally. Stronger ADB
  lifecycle/restart/restore/reinstall assertions now await hosted execution.
- Run 39655181653 failed its first launch during initial AVD input-device setup;
  retained separately. Allow first boot to settle and use complete non-incremental
  installs. Do not count the previous green smoke as full Android acceptance.
- Run 39657194383 now starts reliably but caught a delayed fullscreen overlay:
  the first game tap was consumed while the system prompt closed. Wait for its
  actual UI disappearance and verify saved scene entry before sending gestures.
- Maximum-pool Android harness prepared: production restore of 64 balls / 12 fruit,
  actual ADB swipes, SurfaceFlinger presentation timestamps and per-load memory.
  Synthetic fixtures and pre-test save restoration are explicit. Fixture restore
  and timing-unit checks pass locally; Android load measurements remain NOT_RUN.
- Run 39658177429 passed actual entry but exposed a native AudioTrack SIGSEGV at
  the first music loop. The source endpoint was one frame beyond allocated PCM;
  the crash address and sample-index register match that exact boundary. Changed
  `loop_end` to the final valid frame. Regression fails on old code, passes on the
  fix; all 18 suites pass, including 14,288 logic/audio assertions. Android rerun
  now explicitly waits through the first complete music loop before gameplay.
- Packaged themed-icon inspection found the template Godot glyph despite the
  correct normal icon. Added the original bunny's matching monochrome mark and
  explicit export setting; actual packaged before/after resources are retained.
- Run 39659761708 verifies Android music-loop survival and all strengthened lifecycle
  checks for Fruit, Bubble, Cake and Balls. Trio's second test tap arrived during
  its tile-flight animation; three picks were visible. Preserve the failed run,
  observe each actual mask/history change, and space inputs after animation.
  Remaining Android games/settings/reinstall/load and signed-byte acceptance are pending.
