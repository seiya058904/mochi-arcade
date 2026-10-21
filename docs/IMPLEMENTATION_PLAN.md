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
| 4e. Bouncy Balls | TODO | Paddle/multiplier/pool/collision/stress proof |
| 4f. Jelly Slice | TODO | Continuous swipe/one-shot/pool/Zen runtime proof |
| 5. Integration / lifecycle / stress audit | TODO | 30 switches, corrupt save, pause/back/restart, adverse samples |
| 6. Complete visual reviews + targeted fixes | TODO | Home + 8 games + overlays + settings + aspect ratio matrix |
| 7. Signed Android acceptance | TODO | Signature, package, ABI, hash, install, touch and lifecycle logs |
| 8. CI / final audit / remote sync | TODO | Clean local/upstream/default SHA match, final-SHA CI green |
| 9. Release and download verification | TODO | Annotated tag, draft assets, independent hash match, publish |

## Current checkpoint

- Latest synchronized implementation commit: 7faa254ab169aabb551386cf25b8a679562dbfc8 (Mochi Hop); CI 39640559280 PASS.
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
- Next: commit/push Trio, then Bouncy Balls paddle, swept collisions, real multipliers,
  strict pool cap, natural wave/loss/retry play and sustained load verification.
- Remaining two games, full visual/performance/security audit, release key and
  final signed APK/Android acceptance/Release are not done. Goal remains active.

## Success criteria

All A01-A15 from `SOURCE_TASK.md` have direct evidence. Eight complete offline
games in one Android APK; no P0/P1 or blocking P2; accurate build/install docs;
matching final local/remote/tag/build commit; verified release-download bytes.
