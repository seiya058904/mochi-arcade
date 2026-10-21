# Implementation board

Owner: current Codex. Started 2026-10-21. Goal stays active until delivered or
an evidenced external blocker prevents all meaningful progress.

| Phase | Status | Exit evidence |
| --- | --- | --- |
| 0. Boundary / environment / risk audit | PASS | Empty boundary verified; official engine/template checksums; SDK/JDK/device inventory |
| 1. Git / private remote / CI scaffold | IN_PROGRESS | Private origin/main created and initial commit synced; first full CI queued next |
| 2. Art direction / shared shell / early Android | IN_PROGRESS | Production art and shell rendered; debug APK exported; Android install BLOCKED by offline AVD |
| 3. Cake Stack + Number Bloom vertical slices | PASS (desktop) | 14,278 logic + 47 integration assertions pass; screenshots and native input recheck |
| 4a. Fruit Drop | TODO | Merge/overflow tests, runtime gestures and checkpoint |
| 4b. Bubble Garden | TODO | Hex/attachment/pop/fall/color pool tests and runtime proof |
| 4c. Mochi Hop | TODO | 1000+ seed reachability, hold/cancel/landing tests and runtime proof |
| 4d. Tile Trio | TODO | Solver-verified seed batches, undo/tray/input runtime proof |
| 4e. Bouncy Balls | TODO | Paddle/multiplier/pool/collision/stress proof |
| 4f. Jelly Slice | TODO | Continuous swipe/one-shot/pool/Zen runtime proof |
| 5. Integration / lifecycle / stress audit | TODO | 30 switches, corrupt save, pause/back/restart, adverse samples |
| 6. Complete visual reviews + targeted fixes | TODO | Home + 8 games + overlays + settings + aspect ratio matrix |
| 7. Signed Android acceptance | TODO | Signature, package, ABI, hash, install, touch and lifecycle logs |
| 8. CI / final audit / remote sync | TODO | Clean local/upstream/default SHA match, final-SHA CI green |
| 9. Release and download verification | TODO | Annotated tag, draft assets, independent hash match, publish |

## Current checkpoint

- Initial synchronized commit: d88eaf1 (scope/audit only). Current slice checkpoint being prepared.
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
- Next: commit/push first playable milestone and inspect
  CI; then Fruit Drop (atomic physics merge, overflow grace, art, rules and actual gestures).
- Remaining six games, full visual/performance/security audit, release key and
  final signed APK/Android acceptance/Release are not done. Goal remains active.

## Success criteria

All A01-A15 from `SOURCE_TASK.md` have direct evidence. Eight complete offline
games in one Android APK; no P0/P1 or blocking P2; accurate build/install docs;
matching final local/remote/tag/build commit; verified release-download bytes.
