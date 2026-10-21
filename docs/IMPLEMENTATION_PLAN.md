# Implementation board

Owner: current Codex. Started 2026-10-21. Goal stays active until delivered or
an evidenced external blocker prevents all meaningful progress.

| Phase | Status | Exit evidence |
| --- | --- | --- |
| 0. Boundary / environment / risk audit | PASS | Empty boundary verified; official engine/template checksums; SDK/JDK/device inventory |
| 1. Git / private remote / CI scaffold | PASS | Private origin/main synced; full CI 39638293273 green on 3099316 including Android debug build |
| 2. Art direction / shared shell / early Android | IN_PROGRESS | Production art and shell rendered; debug APK exported; Android install BLOCKED by offline AVD |
| 3. Cake Stack + Number Bloom vertical slices | PASS (desktop) | 14,278 logic + 47 integration assertions pass; screenshots and native input recheck |
| 4a. Fruit Drop | PASS (desktop) | 29 physics/rule checks PASS; 251 normal-action drops reach tier 7 and natural overflow; rendered art and native aim/release checked |
| 4b. Bubble Garden | PASS (desktop) | 1,364 checks; 5 gardens cleared in 33 hinted shots; 73 shots reach natural loss; alpha art and footer reviewed |
| 4c. Mochi Hop | PASS (desktop) | 2,000 seeds / 50,000 platforms; 550,008 rule + 47 runtime assertions; 40-hop real-scene input replay, natural miss/retry, screenshots |
| 4d. Tile Trio | PASS (desktop) | 1,500 solver-verified boards, 439,506 rule + 23 runtime checks; 5 shops / 187 input picks / natural full tray / free result undo / restart; actual screenshots |
| 4e. Bouncy Balls | PASS (desktop) | 236,650 checks; real x2/x3 gates; 60-second 64-ball stress; normal input clears 4 waves, reaches 64 balls, naturally loses/retries; rendered captures |
| 4f. Jelly Slice | PASS (desktop) | 7,224 checks; 108,000 stress swipe events; real-input 60-second Zen round slices 150 fruit, naturally misses 7, finishes/retries via buttons; original whole/half art reviewed |
| 5. Integration / lifecycle / stress audit | PASS (desktop) | 17 required suites; 934 full-collection checks, 40 switches, damaged-save recovery and three viewport profiles |
| 6. Complete visual reviews + targeted fixes | PASS (desktop) | 33 actual renderer captures; EN/ZH, home, eight games, settings, help/pause; board fit, mipmaps and text contrast fixed |
| 7. Signed Android acceptance | TODO | Signature, package, ABI, hash, install, touch and lifecycle logs |
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
- Visual matrix: 33 desktop captures at 450x800, 360x800 and 640x800. All layouts
  reviewed; original art mipmaps, tall-home spacing and 4.58:1 minimum muted-text
  contrast on the eight theme surfaces verified. This is not a full accessibility audit.
- Next: execute the revised hosted API 34 standard AOSP AVD. The Google APIs image
  required at least 7,372.80 MB despite the requested 2 GB partition. Standard AOSP
  retains full graphics without Google apps; only three extracted job-owned download
  archives are removed to make room. No local files or unrelated runner tools are deleted.
- Full visual/performance/security audit, release key and
  final signed APK/Android acceptance/Release are not done. Goal remains active.

## Success criteria

All A01-A15 from `SOURCE_TASK.md` have direct evidence. Eight complete offline
games in one Android APK; no P0/P1 or blocking P2; accurate build/install docs;
matching final local/remote/tag/build commit; verified release-download bytes.
