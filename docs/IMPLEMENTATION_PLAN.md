# Implementation board

Owner: current Codex. Started 2026-10-21. Goal stays active until delivered or
an evidenced external blocker prevents all meaningful progress.

| Phase | Status | Exit evidence |
| --- | --- | --- |
| 0. Boundary / environment / risk audit | IN_PROGRESS | Executable versions, device inventory, risk plan |
| 1. Git / private remote / CI scaffold | TODO | Initial commit, verified private origin/upstream |
| 2. Art direction / shared shell / early Android | TODO | Generated art, home/settings, installed APK and touch proof |
| 3. Cake Stack + Number Bloom vertical slices | TODO | Playable loops, rules tests, runtime screenshots |
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

- Latest verified implementation commit: none (empty initial directory).
- Engine version requested: 4.7.2.stable; Java 17 present; Android templates missing.
- Two independent image-generation concept directions requested.
- Next: locate engine, boot existing AVD, fill matching Android template/tool gap,
  initialize repository and private remote; select art direction then implement shell.
- All gameplay / visual / Android / release acceptance: NOT_RUN.

## Success criteria

All A01-A15 from `SOURCE_TASK.md` have direct evidence. Eight complete offline
games in one Android APK; no P0/P1 or blocking P2; accurate build/install docs;
matching final local/remote/tag/build commit; verified release-download bytes.

