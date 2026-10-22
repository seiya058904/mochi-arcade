# Release gates — not release ready

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
| A07 Audio | PASS tested Android development path / final signed pending | Native first-loop crash repaired and Android loop survives in 39659761708; nine mixer-boundary regressions and real desktop mute/pause/output checks pass |
| A08 Persistence | PASS tested development path / signed pending | All eight freezes/round restores, five settings and exact complete-save preservation after same-signature reinstall; damaged-save recovery suite passes |
| A09 Compatibility / performance | PARTIAL — hardware-GPU emulator PASS; physical phone UNVERIFIED | Final signed-byte hardware-GPU AVD: 64 Balls 55.43 presented FPS (p95 33.251 ms), Jelly 12 fruit 60.0 FPS (p95 17.243 ms), PSS 175,671 -> 166,479 / 173,708 -> 159,156 KiB, original save and backup restored. These are emulator compositor intervals including ADB load, not phone FPS; no physical thermal/battery/frame data. Earlier hosted software results remain retained. The user reports no stutter, lost touch input or abnormal heating without measurements |
| A10 Security / provenance | PASS bounded candidate audit | Known credential-pattern history scan, documented original art/fonts, bundled offline notices; candidate has only VIBRATE and excludes private/dev files |
| A11 Reproducible build | PASS signed rebuild | Pinned engine/template, SDK CLI checksum, local + hosted debug export; final signed APK rebuilt with the existing identity and re-verified |
| A12 Verified installable APK | PASS controlled emulator / physical automated acceptance unavailable | Final signed APK SHA-256 `8fcc1ebc...`, 78,467,820 bytes, certificate `de1458f3...`, versionName 1.0.0, non-debuggable, v2+v3, zipalign 16 KiB, only VIBRATE; installed and ran the full signed-byte lifecycle, startup and maximum-pool acceptance on the hardware-GPU API 34 AVD on 2026-10-22 (eight games x three returns, force-stop restore, same-signature reinstall, launcher icon, first music loop; first launch 463 ms, cold 408 ms, warm 79 ms). The user reported a physical-phone retest but supplied no device metadata, captures or on-phone hash; physical automated signed-byte acceptance remains DEVICE_UNAVAILABLE |
| A13 Clean synchronized Git | PASS clean sync checkpoint | Takeover history and subsequent docs/evidence commits are pushed to origin/main; worktree clean and HEAD equals origin/main. Final release-SHA acceptance still depends on A09/A14 |
| A14 Final-SHA CI | OWNER_APPROVED_ENVIRONMENT_EXCEPTION (not PASS) | Retained hosted failures: 39698026180 (32df767) harness precondition; 39699385661 (28a8a45) black Fruit Drop return; 39700272044 (6240595) black cycle-2 frame; 39701157030 (fd3975d) black cycle-3; 39711487194 (d7f2650) Bouncy restore precondition with no blank; 39716897550 (90ee172) blank Fruit Drop repeat-3 frame `cfc80cc...` on the hosted software renderer. The owner accepted a scoped exception on 2026-10-22 for this hosted Ubuntu + Mesa llvmpipe background-return blank frame only, using the hardware-GPU API 34 signed-byte acceptance as substitute evidence. No assertion was removed and every failed run stays FAIL; see the exception section below |
| A15 Release | PENDING_PUBLIC_RELEASE | Owner-approved A14 exception recorded; final signed APK, `SHA256SUMS`, README, license and release notes prepared. Remaining steps: final commit/CI, public-safety audit, draft upload, downloaded-asset byte/signature verification, repository public switch, publish, anonymous download verification |

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

Current status: A14 carries the owner-approved scoped environment exception; A09
physical-phone quantitative performance remains UNVERIFIED and is disclosed in the
release notes. Release steps remaining: final commit/CI, public-safety audit,
tag v1.0.0 and draft upload, downloaded-asset byte/signature verification,
repository public switch, publish and anonymous download verification.
Secure local release signing, signed-byte hardware-GPU emulator acceptance and
measured desktop audio verification have passed.
Physical-phone performance will remain explicitly unverified; the 2026-10-22 phone
retest is user-reported only (no device metadata, captures or on-phone hash).
