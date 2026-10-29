# Implementation board

## Current signed acceptance — 2026-10-29

**All four local original-signed gates PASS reviewed; release-ready in the tested scope.**
See [the current signed-byte report](ANDROID_SIGNED_20261029.md) for exact package,
source/tool identities, independent CLEAN/U110/U100/LOAD results, current CI, preserved
failed attempts and device limits. Publication verification is tracked there.
The dated material below is historical and does not override that current record.

## Historical record (through 2026-10-28)

## Evidence housekeeping — 2026-10-28

Owner-authorized one-time cleanup completed locally: historical raw logs and
screenshots were recycled; current README images and product files were retained.
See [the retention record](EVIDENCE-RETIREMENT-20261028.md). This changes no gate
result or release approval; any future release still requires the existing gates.

## Current local retest and CI policy — 2026-10-23

The owner authorized a fresh local Android retest, superseding the prior closed
window for this specific investigation. The exact failing CI development APK
passed eight games × three background returns on a local Pixel 2 API 34 AVD with
AMD host GPU; no black return reproduced. Automatic CI now retains source checks
and APK construction, with hosted software-GPU runtime gates available manually.
This is an owner-approved hosted-environment exception, not a proven engine fix
or signed-candidate release approval. [Exact result, evidence and limits](LOCAL_ANDROID_CI_EXCEPTION_20261023.md).

## Previous bounded closeout — 2026-10-23

The owner replaced open-ended Android diagnosis with a 60-minute final closeout.
See [scope, tool regression evidence, retention rules and exact stopping actions](CLOSEOUT_60MIN.md).
Launcher XML freshness/validity and actual icon foreground proof are the only
new tool work; application/candidate bytes and signed FAIL results stay unchanged.
One final main push CI and local delivery record supply dynamic outcomes; no
automatic next research round. Release remains BLOCKED.

## Previous signed acceptance (historical)

Current signed run 39961466842: **U100 and LOAD PASS reviewed; U110 and CLEAN FAIL**.
The complete v1.0.0 upgrade includes eight semantic states, real terminal Undo and
fault recovery. The v1.1.0 upgrade and independent new-install gates remain incomplete.

## Current Android unblock board — 2026-10-23

**BLOCKED.** Tools/diagnostic retention and four isolated gate orchestration are
implemented; signed LOAD restoration PASS reviewed. Full CLEAN/U110 lifecycle
rendering FAIL remains a hard release blocker. Complete current results and next
conditions are centralized in [the unblock audit](ANDROID_UNBLOCK_1.1.1.md).

## Historical 1.1.1 patch board before continuation — 2026-10-23

**BLOCKED; both signed upgrade runs FAIL after hosted emulator SIGSEGV.** See
[ITERATION_1.1.1.md](ITERATION_1.1.1.md) for F1–F6, exact next actions and
current evidence. The v1.1.0 sections below describe the previous delivery.

Current continuation: [Android unblock audit and four-gate board](ANDROID_UNBLOCK_1.1.1.md).
Tools now preserve both original load-test files, retain independent diagnostic
phases, and isolate U110/U100/CLEAN/LOAD. Original candidate bytes remain frozen;
none of the new tools or desktop checks substitutes for complete signed gates.

## Historical 1.1.0 iteration — 2026-10-23

| Phase | Status | Exit evidence / next action |
| --- | --- | --- |
| Takeover / baseline / audit | PASS | Clean unique root; live public remote/tag/download; original signing identity opened; baseline 18/18; eight-game review in ITERATION_1.1.md |
| Confirmed repairs | PASS local | Save failure/recovery, terminal Bloom Undo, four idle canvas guards; 19/19 suites including 48 new regression checks |
| Desktop rendering / audio | PASS reviewed | 64 EN/ZH captures across three ratios; terminal/failure UI; same-seed idle pixels exact; actual audio mixer checks |
| New signed Android / upgrade | PASS signed hosted API 34 | Run 39930890985: original-cert upgrade, all eight restored rounds, clean 8 x 3 lifecycle/audio/load, 240 captures reviewed. Additional native boot video reviewed; local AEHD stays stopped |
| Remote integration / development CI | PASS release source 4f5d7f7 | Direct main integration; development run 39934851867 and exact signed run 39934863776 pass with separate screenshot/video review. Post-release documentation SHA is checked independently |
| New stable Release / public download | PASS | Published v1.1.0, project-retained tag 4f5d7f7, exact signed APK 9676db2f... and checksum anonymously re-downloaded and verified. v1.0.0 unchanged |

See [ITERATION_1.1.md](ITERATION_1.1.md) for exact continuation and evidence.
The following phase board and checkpoints are **historical v1.0.0 development**;
their former pending/blocker statements describe those dates, not today's release.

## Historical v1.0.0 phase board

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
| 4e. Bouncy Balls | PASS (desktop) | 236,607 checks incl. player-feedback layout invariants; real x2/x3 gates; 60-second 64-ball stress; rendered input clears 4 waves, score 4,975, gates 58/80, real 64-ball max, natural loss/retry; measured before/after captures |
| 4f. Jelly Slice | PASS (desktop) | 7,224 checks; 108,000 stress swipe events; real-input 60-second Zen round slices 150 fruit, naturally misses 7, finishes/retries via buttons; original whole/half art reviewed |
| 5. Integration / lifecycle / stress audit | PASS (desktop) | 18 required suites; 995 full-collection checks, 40 switches, immediate lifecycle persistence, damaged-save recovery, three viewport profiles and actual edge-button input |
| 6. Complete visual reviews + targeted fixes | PASS (desktop) | 34 actual renderer captures; EN/ZH, home, eight games, settings, help/pause; board fit, mipmaps and text contrast fixed |
| 7. Signed Android acceptance | PASS controlled hardware-GPU emulator; hosted CI on scoped exception | Host GLES development runs pass the launcher, edge-target taps and large parts of the lifecycle; same-source Lavapipe still black. Repeated-return run passes all 24 returns but the AVD goes offline during the Jelly load. Run 39698026180 stops at a Bouncy Balls harness precondition (fixed); run 39699385661 then reproduces a fully black Fruit Drop background return that only a new surface cycle recovers with the same PID. Both maximum pools execute on one online AVD in both runs (3.60-3.84 / 5.04-7.19 FPS, software). The final-SHA run 39701157030 is FAIL at the same blank repeated return; run 39711487194 (d7f2650) fails at the Bouncy restore precondition with no blank return. On 2026-10-22 the exact signed bytes passed a hardware-GPU AOSP API 34 AVD acceptance (8 games x 3 returns, 101 non-blank frames, force-stop restore, reinstall; 64 Balls 55.55 FPS, Jelly 60.0 FPS) with evidence in `docs/evidence/android-api34-hostgpu-2026-10-22/`; this is an emulator, not a physical phone, and does not satisfy A14. User-reported phone retest: no problems, metadata/captures NOT_PROVIDED |
| 8. CI / final audit / remote sync | PASS WITH OWNER-APPROVED A14 ENVIRONMENT EXCEPTION | Final local verification on the v1.0.0 splash working tree: 18/18 suites PASS, security audit PASS, final signed APK static checks PASS, startup and hardware-GPU Android acceptance PASS. Final run 39724258963 passed suites/APK/load and failed only at the hosted software-rendered black frame (A14 exception, not PASS). Public-safety audit and public visibility switch completed |
| 9. Release and download verification | PASS | v1.0.0 published at https://github.com/seiya058904/mochi-arcade/releases/tag/v1.0.0; tag v1.0.0 → 2d45caf; unauthenticated APK/SHA256SUMS download, byte/signature/package/version checks and README desktop/mobile rendering passed. A09 phone performance remains UNVERIFIED and disclosed |

## Current checkpoint

- 2026-10-22 follow-up: `dist/MochiArcade.apk` and the delivered
  `D:\下载\MochiArcade-1.0.0-signed.apk` are byte-identical (SHA-256
  2b459f5c...); the user reported no problems on a physical-phone retest (device
  metadata, captures and on-phone hash NOT_PROVIDED). After the user reboot,
  AEHD 2.2 + the AMD RX 7900 XT booted a CI-matching API 34 AVD; the exact signed
  bytes passed 8 games x 3 background returns (101 non-blank frames, restore,
  reinstall) and maximum-pool load (64 Balls 55.55 FPS, Jelly 60.0 FPS). This is
  a controlled emulator, not a phone. Hosted runs 39701157030 (black return) and
  39711487194 (Bouncy restore precondition, no blank return) remain FAIL. See
  `HANDOFF_STATUS.md`.
- 2026-10-22 v1.0.0 closeout: the owner approved the scoped A14 hosted
  software-renderer exception; the final APK was rebuilt with the existing
  identity and a custom cream Mochi boot splash (SHA-256 `8fcc1ebc...`); 18/18
  suites, hardware-GPU Android smoke/load, startup and static APK checks passed;
  README/license/release notes are ready. Final commit/CI, public-safety audit,
  draft upload, repository public switch, publish and anonymous download
  verification are in progress.
- Latest reviewed development checkpoint a032fde passes host-GLES CI 39670759820 and all 99 native views; same-source Lavapipe 39670750928 fails on black background return. Next run strengthens repeat coverage; signing-secret approval or a connected Android device is still required for signed-byte acceptance.
- Earlier all-eight-game checkpoint da1d397c29134fd18ec29b26a8cbfdeedeae0f4c passed CI 39647458113. Hosted attempts 39648255774 and 39649666572 then exposed and retained emulator disk-allocation failures.
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
  save-state checks for Fruit, Bubble, Cake and Balls. Trio's second test tap arrived during
  its tile-flight animation; three picks were visible. Preserve the failed run,
  observe each actual mask/history change, and space inputs after animation.
  Remaining Android games/settings/reinstall/load and signed-byte acceptance are pending.
- Further review rejects background return: all four images are black, with
  EGL_BAD_SURFACE and host color-buffer errors. The state-only check was too weak.
  Retain all adverse evidence, add blank-frame and resumed-input checks, and compare
  the same pinned emulator's documented Lavapipe backend. No app-code workaround is
  assumed. Run 39661719966 stopped at an interrupted SDK download, before Android tests.
- Run 39662679600 on Lavapipe restores visible Fruit/Bubble views and accepts Resume
  then Back. Cake exposes deferred lifecycle persistence: the background snapshot
  differs from the returned one. Freeze/checkpoint now execute in the notification;
  only pause-overlay tree mutation is deferred. All 45 new regression checks fail
  on the old code and pass on the repair; all 18 suites pass (980 collection checks).
  Native rerun and later games remain pending. Maximum-load checks now run even
  after an independent smoke failure, while preserving that failed job result.
- Run 39664379571 passes all eight Android input/lifecycle/round-restore/restart
  assertions, settings persistence and identical-save preservation after reinstall.
  Overall smoke still fails at launcher navigation: the app drawer never opened.
  Wait for actual Launcher workspace, swipe within its observed empty area, then
  inspect the actual icon. All game screenshots still require full manual review.
  The 64-ball load visibly runs; its 5.358-second burst supplies only 11 presentation
  timestamps. Keep the failed sample, extend observation to 12-30 seconds without
  lowering the sample minimum, and execute Jelly independently even if Balls fails.
  Latest local signed candidate is built from 0f27910 and statically verified;
  it has not been installed. No signing secret has been uploaded.
- The 87-view native review is complete. Ten stages per game and seven shared
  pages show readable controls, expected boards/records and visible lifecycle
  transitions. Preserve 12 labeled review sheets, all source digests and 12 original
  PNGs; README now uses actual Android screenshots. Run 39667082209 is testing
  launcher/load harness changes on e688600; no production code changed afterward.
- Run 39667082209 reproduces a black Bubble background return on Lavapipe after
  the previous complete success. Treat this as an intermittent blocker. Preserve
  the black frame and guest/host logs; the engine GL thread stops presenting after
  EGL_BAD_SURFACE. Next failure diagnostics wait without input, then observe a new
  surface lifecycle with the same process; the original run must remain FAIL.
  Move the independent launcher check before game testing, retaining any failure.
- Both maximum-pool tests now execute with visible movement/cut halves and exact
  primary/backup restoration. Software-emulator presentation: Balls 2.73 FPS,
  Jelly 4.49 FPS; this is not a performance pass. A desktop render diagnostic
  identifies interleaved ball trails/sprites: 247 draw calls at 64 balls versus
  121 at one ball. Batch trails behind shared-atlas sprites: 121 at both counts,
  unchanged full fixture pixels; reduced-motion remains 120. All 18 suites pass.
- Run 39669849881 tests the batching change on the unchanged Lavapipe backend.
  A separate manual host-GLES/Mesa diagnostic is prepared with preinstalled Xvfb,
  explicit software rendering, identical APK/acceptance paths and recorded adapter
  details. Default CI remains Lavapipe until evidence warrants a change. No engine
  patch, dependency update or signing-secret upload is introduced.
  The fresh local a2a3bd7 release export is 78016973 bytes, SHA-256
  3597bc5020d5ec545e87a837b03a7a2a7a375a24cde002d44c0c47d1aaa42901;
  signature/package/static alignment checks pass, exact-byte Android runtime pending.
- Run 39669849881 verifies the actual bunny launcher entry and icon-tap launch.
  Balls then reproduces the black return: five further passive seconds stay black;
  a new five-second Home cycle restores visible pause with the same PID. Preserve
  both states, keep the original job failed, and retain the suspected engine-surface
  race classification. Load observations are 3.01 / 4.66 FPS, still software-only.
  Same-source a032fde comparisons are running: Lavapipe 39670750928 and explicit
  software host GLES 39670759820. No result is assumed before their logs/captures.
- Same-source comparison is complete: Lavapipe fails on Fruit; host GLES passes
  all eight game paths, launcher, settings/reinstall and load execution. All 99
  host captures are reviewed, with unchanged originals and both raw results retained.
  Actual host adapter is Mesa llvmpipe, not a hardware GPU. EGL/ColorBuffer warnings
  remain and 6.01/8.91 FPS is not a performance pass. Use host for the next bounded
  run and require three returns per game; keep the unresolved black-return blocker.
- Small buttons in the tested 720px/320dpi profile had 36-44dp hit heights.
  Expand shared hit regions to 96 design pixels without changing rendered bounds.
  All 15 new actual-GUI edge taps fail on the original and pass after repair across
  three ratios; all 18 suites pass (995 collection checks). Actual Home/Settings
  GPU pixels are identical before/after. Native edge taps and fresh signing follow
  after the repeated-lifecycle run; the earlier signed candidate predates this change.
- Run 39700272044 on 6240595 reproduces the black Fruit Drop background return
  a second time (cycle 2; byte-identical black frame to 39699385661), with the
  same PID-preserving recovery only through a new surface cycle. Both maximum
  pools pass again (Balls 3.62 FPS, Jelly 5.10 FPS, saves restored). The surface
  blocker is now reproducible on the takeover code, so the project stops here as
  BLOCKED for release; no tag/Release is created. Next evidence requires a
  physical phone or hardware-GPU host.
- Run 39699385661 on 28a8a45: 18 suites, APK build and edge-target taps pass;
  Fruit Drop enters and freezes on Back, then its background return is fully black,
  still black after 5 s and visible only after a new surface cycle with the same
  PID (EGL_BAD_SURFACE retained). The black-return blocker is therefore reproduced
  on the takeover code; A05/A09 stay BLOCKED. Both pools execute again (Balls
  3.60 FPS, Jelly 5.04 FPS, exact save restoration). The harness fix is not yet
  validated because this run stops before Bouncy Balls.
- Run 39698026180 on 32df767: 18 suites and APK build pass; Android edge-target
  taps pass; Fruit/Bubble/Cake complete; Bouncy Balls stops at cycle 2 because the
  resumed round naturally ended during the capture window. The harness now
  re-establishes a real paused round before the unchanged assertions. Both
  maximum pools execute (Balls 3.84 FPS, Jelly 7.19 FPS, software renderer,
  exact save restoration, host state and continuous logcat retained).
- Takeover 2026-10-22 recovered the unpushed expanded hit regions, added the
  Bouncy Balls player-feedback layout revision (ball 22->32 px, 6x4 -> 4x6 bricks,
  gates 116x34 -> 150x46, bumpers 54 -> 68 px, paddle unchanged) and measured
  before/after at the 720x1280 aspect. All 18 required suites pass; the Android
  maximum-pool fixture was updated to the 4-column brick grid. See
  `PLAYTEST_FEEDBACK.md`, `HANDOFF_STATUS.md` and the takeover section of
  `QA_REPORT.md`.
- Run 39673516558 passes the complete smoke and all 24 returns; 37 relevant
  captures are manually reviewed and all 110 hashes retained. The AVD then goes
  offline writing the Jelly load fixture, preventing cleanup. Keep the entire run
  FAIL; cause is UNVERIFIED. Add continuous load logcat and final host diagnostics
  to the next run, alongside the new edge-target inputs. Do not retry/reboot away
  the failure. Remaining gates still include reliable load execution, performance,
  signed-byte acceptance and final CI/release checks.
