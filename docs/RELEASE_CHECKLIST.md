# Release gates — published v1.0.0 and unreleased 1.1.0

Current iteration (2026-10-23): **1.1.0 NOT_RELEASED; signed acceptance PASS**.
A01-A08/A10-A12 pass the final-source local suites, reviewed layouts and exact
signed API 34 hosted run 39930890985 (upgrade + independent clean lifecycle/load).
Additional native startup-video review is pending; A09 physical phone metrics
remain UNVERIFIED. A13/final-SHA A14 and A15 publication are completed during final
closeout, not inferred from earlier CI. The old A14 exception is not used by the
passing signed run. See [iteration report](ITERATION_1.1.md) for evidence/limits.

The following table and public-download section describe **v1.0.0 only**.

Updated 2026-10-22. Desktop acceptance does not satisfy Android gates. A14
carries an owner-approved, scoped environment exception; it is not a PASS. See
"Owner-approved environment exception" below.

| Gate | State | Evidence / remaining work |
| --- | --- | --- |
| A01 One app / APK | PASS signed runtime | All eight in one package; the final signed SHA-256 `8fcc1ebc...` installed, showed the custom Mochi boot splash and opened the home screen on the hardware-GPU API 34 AVD; launcher entry verified |
| A02 Eight complete games | PASS desktop + signed Android | Eight implemented loops, natural-action replays and actual Android input/boards; the final signed bytes passed eight games x three Android background returns with save restore |
| A03 Correct gameplay | PASS desktop | 18 required suites; rules, collision, save, lifecycle and real scene input |
| A04 Valid procedural content | PASS | Independent Trio solver: 1,500 boards; Hop: 2,000 seeds / 50,000 targets |
| A05 Android controls | PASS hardware-GPU emulator + user-reported phone; hosted software CI still fails | Final signed bytes SHA-256 `8fcc1ebc...` passed on a controlled AOSP API 34 x86_64 AVD with AEHD 2.2 and the AMD RX 7900 XT host GPU on 2026-10-22: eight games x three background returns, 101 non-blank frames, same PID, pause checkpoints equal, force-stop restore, zero-score restart, settings, same-signature reinstall and launcher icon; 43 `EGL_BAD_SURFACE` warnings only during background surface destruction and no runtime errors. The custom splash and cold/warm/first startup were separately verified with video/screenshots. The user also reports no black return on a physical phone (metadata/captures NOT_PROVIDED). Hosted software-rendered runs still reproduce the black return; retain it as an environment-specific infrastructure failure with residual risk, not as a closed hosted gate |
| A06 Cohesive art | PASS desktop + tested Android viewport | Original production art; three desktop ratios; 87 actual 720x1280 Android views reviewed in labeled sheets. Bouncy Balls scale revision measured before/after (22->32 px ball, 4x6 brick wall, 150x46 gates, 68 px bumpers, paddle unchanged) with post-change 720x1280 Android views retained (ready, 64-ball packed and spread); owner reported the enlarged layout acceptable on a phone on 2026-10-22 (no captures supplied), and the signed-byte hardware-GPU API 34 AVD rendered the same enlarged layout at 720x1280 with retained captures |
| A07 Audio | PASS v1.0.0 tested signed path | Native first-loop crash repaired; final signed API 34 acceptance includes first-loop survival. Mixer-boundary and desktop mute/pause/output checks pass; physical speaker quality is not quantified |
| A08 Persistence | PASS v1.0.0 tested signed path | Final signed API 34 acceptance includes all eight freezes/round restores, settings and same-signature reinstall preservation; this was not a v1.0.0-to-1.1.0 upgrade test |
| A09 Compatibility / performance | PARTIAL — hardware-GPU emulator PASS; physical phone UNVERIFIED | Final signed-byte hardware-GPU AVD: 64 Balls 55.43 presented FPS (p95 33.251 ms), Jelly 12 fruit 60.0 FPS (p95 17.243 ms), PSS 175,671 -> 166,479 / 173,708 -> 159,156 KiB, original save and backup restored. These are emulator compositor intervals including ADB load, not phone FPS; no physical thermal/battery/frame data. Earlier hosted software results remain retained. The user reports no stutter, lost touch input or abnormal heating without measurements |
| A10 Security / provenance | PASS bounded candidate audit | Known credential-pattern history scan, documented original art/fonts, bundled offline notices; candidate has only VIBRATE and excludes private/dev files |
| A11 Reproducible build | PASS signed rebuild | Pinned engine/template, SDK CLI checksum, local + hosted debug export; final signed APK rebuilt with the existing identity and re-verified |
| A12 Verified installable APK | PASS controlled emulator / physical automated acceptance unavailable | Final signed APK SHA-256 `8fcc1ebc...`, 78,467,820 bytes, certificate `de1458f3...`, versionName 1.0.0, non-debuggable, v2+v3, zipalign 16 KiB, only VIBRATE; installed and ran the full signed-byte lifecycle, startup and maximum-pool acceptance on the hardware-GPU API 34 AVD on 2026-10-22 (eight games x three returns, force-stop restore, same-signature reinstall, launcher icon, first music loop; first launch 463 ms, cold 408 ms, warm 79 ms). The user reported a physical-phone retest but supplied no device metadata, captures or on-phone hash; physical automated signed-byte acceptance remains DEVICE_UNAVAILABLE |
| A13 Clean synchronized Git | PASS clean sync checkpoint | Release tag v1.0.0 points to `2d45caf40d8334c4c9cc1567164db749d983c7ee`; takeovers, splash rebuild, README and evidence are pushed to origin/main; worktree clean. Post-release documentation-only commits do not change the signed APK or the tag |
| A14 Final-SHA CI | OWNER_APPROVED_ENVIRONMENT_EXCEPTION (not PASS) | Retained hosted failures: 39698026180 (32df767) harness precondition; 39699385661 (28a8a45) black Fruit Drop return; 39700272044 (6240595) black cycle-2 frame; 39701157030 (fd3975d) black cycle-3; 39711487194 (d7f2650) Bouncy restore precondition with no blank; 39716897550 (90ee172) blank Fruit Drop repeat-3 frame `cfc80cc...`; 39724258963 (2d45caf) blank Bouncy repeat-2 frame `cfc80cc...` after 18 suites/APK/load passed. The owner accepted a scoped exception on 2026-10-22 for this hosted Ubuntu + Mesa llvmpipe background-return blank frame only, using the hardware-GPU API 34 signed-byte acceptance as substitute evidence. No assertion was removed and every failed run stays FAIL; see the exception section below |
| A15 Release | RELEASED | `v1.0.0` published on 2026-10-22: https://github.com/seiya058904/mochi-arcade/releases/tag/v1.0.0, tag `v1.0.0` → `2d45caf40d8334c4c9cc1567164db749d983c7ee`, APK SHA-256 `8fcc1ebc...`, certificate `de1458f3...`, repository public; anonymous download, byte/signature and README desktop/mobile checks passed |

## Owner-approved environment exception (A14)

- State: `OWNER_APPROVED_ENVIRONMENT_EXCEPTION`, not PASS.
- Owner decision: 2026-10-22. The owner explicitly accepted a scoped exception for
  the GitHub-hosted Ubuntu + Mesa llvmpipe software-rendered Android emulator
  background-return blank frame, and declined a self-hosted GPU runner.
- Scope: only the intermittent blank frame after a background return on that
  hosted software renderer. Every other gate remains in force; raw failures,
  blank-frame hashes, logs and FAIL statuses are retained, and no assertion was
  deleted or relaxed.
- Substitute evidence: the final signed bytes (SHA-256 `8fcc1ebc...`) passed the
  controlled AOSP API 34 x86_64 hardware-GPU run (Google AEHD 2.2 + AMD RX 7900 XT,
  720x1280) on 2026-10-22: eight games x three background returns, 101 non-blank
  frames, same PID, pause checkpoint equality, force-stop restore, zero-score
  restart, settings, same-signature reinstall, launcher icon, first music loop;
  maximum pools 64 Balls 55.43 presented FPS / Jelly 60.0 FPS with exact save
  restoration. Custom startup (first/cold/warm) was separately verified with
  screenshots and recordings. Evidence:
  `docs/evidence/android-api34-final-splash-2026-10-22/`.
- Retained failure: run
  [39716897550](https://github.com/seiya058904/mochi-arcade/actions/runs/39716897550)
  on `90ee172` failed at `01-fruit_drop-repeat-3-background-return` with blank
  frame SHA-256 `cfc80ccb6c70119363e7e3da3bbb361f4c4c2628e4856bfdce139ea7b8cdf249`,
  `EGL_BAD_SURFACE`, recovered only by a new surface cycle with the same PID.
- Residual risk: the hosted software-renderer black return is not fully
  root-caused and may share a Godot/emulator surface race. Hardware-GPU and
  user-phone evidence do not prove the hosted environment or every software
  renderer is safe. Physical-phone quantitative performance remains UNVERIFIED.
- Not claimed: A14 PASS, stability on all software renderers, or physical-phone
  performance.

## Public release verification (2026-10-22)

- Repository: https://github.com/seiya058904/mochi-arcade — `PUBLIC`.
- Release: https://github.com/seiya058904/mochi-arcade/releases/tag/v1.0.0 — tag
  `v1.0.0` → `2d45caf40d8334c4c9cc1567164db749d983c7ee`.
- Assets: `MochiArcade.apk` (78,467,820 bytes, SHA-256
  `8fcc1ebc83cb9cb8e8947a1a33bef9cba9222b9ac775fafdcd7d3d5cd85d473c`) and
  `SHA256SUMS`.
- Unauthenticated public download: APK and SHA256SUMS HTTP 200; downloaded APK
  byte-identical, correct RSA-3072 release certificate, package
  `io.github.seiya058904.mochiarcade`, version 1.0.0, non-debuggable, 16 KiB
  aligned; `releases/latest` redirects to v1.0.0.
- README rendered on GitHub at 1440x2200 and 390x844; all 12 relative image
  resources and documentation links returned HTTP 200; top download link and
  README screenshots render correctly.
- Evidence: `docs/evidence/github-readme-2026-10-22/`.

Current status: **v1.0.0 RELEASED**; A14 carries the owner-approved scoped
environment exception; A09 physical-phone quantitative performance remains
UNVERIFIED and is disclosed in the release notes.
Secure local release signing, signed-byte hardware-GPU emulator acceptance and
measured desktop audio verification have passed.
Physical-phone performance will remain explicitly unverified; the 2026-10-22 phone
retest is user-reported only (no device metadata, captures or on-phone hash).
