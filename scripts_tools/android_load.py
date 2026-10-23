"""Observe maximum-pool render bursts on the dedicated Android acceptance AVD.

Synthetic save fixtures use the production restore path. They are not normal
gameplay evidence or physical-phone performance results. No APK hooks are added.
The pre-test save and backup are restored after the experiment, even on failure.
"""
import argparse
import copy
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shlex
import subprocess
import time
from android_capture import capture_png
from android_evidence import AdbEvidence, require_owned, diagnose
from android_restore import SaveRestoration


PACKAGE = "io.github.seiya058904.mochiarcade"


def fixtures(original):
    result = {}
    for name in ("bouncy_balls", "jelly_slice"):
        state = copy.deepcopy(original)
        state["settings"].update(language="en", music=False, sfx=True, reduced_motion=False, haptics=False)
        state["seen"][name] = True
        if name == "bouncy_balls":
            state["sessions"][name] = {
                "seed": 640012, "wave": 7, "score": 0, "paddle": 0.5,
                "balls": [[0.14 + (i % 8) * 0.1, 0.49 + (i // 8) * 0.025,
                           (-1 if i % 2 else 1) * (140 + i % 5 * 20), -380, 3, i % 5] for i in range(64)],
                # Wave 7 gives the four top-row bricks 5 hp and the rest 4; the
                # production restore rejects any hp above the live brick max.
                "health": [5] * 4 + [4] * 20, "clear": 0, "area": [648, 894]}
        else:
            state["sessions"][name] = {
                "seed": 120032, "rng": "640012", "score": 0, "sliced": 0, "missed": 0,
                "launched": 12, "spawn_time": 1.35,
                "fruit": [[i % 4, 0.15 + (i % 4) * 0.23, 0.65 + (i // 4) * 0.045,
                           0, -470, 46, 0, 0.35] for i in range(12)]}
        result[name] = state
    return result


def presentation_summary(present_times):
    stamps = sorted(set(present_times))
    intervals = [(b - a) / 1_000_000 for a, b in zip(stamps, stamps[1:])]
    if len(intervals) < 20:
        return {"status": "UNVERIFIED", "frames": len(stamps), "reason": "Too few SurfaceFlinger presentation timestamps"}
    ordered = sorted(intervals)
    return {"status": "MEASURED", "frames": len(stamps),
            "observed_seconds": round((stamps[-1] - stamps[0]) / 1e9, 3),
            "presented_fps": round(1000 / (sum(intervals) / len(intervals)), 2),
            "interval_ms_p50": round(ordered[len(ordered) // 2], 3),
            "interval_ms_p95": round(ordered[min(len(ordered) - 1, math.ceil(len(ordered) * 0.95) - 1)], 3),
            "interval_ms_max": round(max(intervals), 3),
            "intervals_over_50ms": sum(value > 50 for value in intervals),
            "scope": "Compositor presentation intervals, including ADB load; not simulation step cost or physical-phone FPS"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--release", action="store_true")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    report = {"status": "FAIL", "commit": os.environ.get("GITHUB_SHA", "local"),
              "apk_sha256": hashlib.sha256(args.apk.read_bytes()).hexdigest(),
              "scope": "Synthetic maximum-pool bursts on isolated AOSP API 34 x86_64; inspect emulator.log for actual graphics adapter",
              "graphics_backend_requested": os.environ.get("MOCHI_EMULATOR_GPU", "unrecorded"),
              "timing_source": "https://android.googlesource.com/platform/frameworks/native/+/refs/tags/android-14.0.0_r1/services/surfaceflinger/FrameTracker.cpp",
              "physical_phone_performance": "UNVERIFIED", "loads": {}}
    recorder = AdbEvidence(output, args.serial, timeout=40)
    restoration = None

    def adb(*parts, data=None, binary=False, check=True):
        return recorder(*parts, data=data, binary=binary, check=check)

    def shell(*parts, **kwargs):
        return adb("shell", *parts, **kwargs)

    def private_command(command, filename, **kwargs):
        if filename not in ("save.json", "save.backup.json"):
            raise ValueError("Only this test application's two identified save files are allowed")
        if args.release:
            return shell(command, f"/data/user/0/{PACKAGE}/files/{filename}", **kwargs)
        return shell("run-as", PACKAGE, command, f"files/{filename}", **kwargs)

    def state():
        return json.loads(private_command("cat", "save.json"))

    def write_private(filename, data):
        private_command("tee", filename, data=data)

    def read_original(filename):
        # A failed transport/read is never interpreted as an absent file.
        path = f"/data/user/0/{PACKAGE}/files/{filename}" if args.release else f"files/{filename}"
        command = f'if [ -e {path} ]; then echo PRESENT; else echo ABSENT; fi'
        present = shell("sh", "-c", shlex.quote(command)) if args.release else shell("run-as", PACKAGE, "sh", "-c", shlex.quote(command))
        assert present in ('PRESENT', 'ABSENT'), 'Uncertain original file existence'
        return private_command('cat', filename, binary=True) if present == 'PRESENT' else None

    def stop_confirmed():
        shell('am', 'force-stop', PACKAGE)
        assert shell('pidof', PACKAGE, check=False) == '', 'Application still running'
        assert recorder.last_exit == 1, 'pidof did not positively report absence'
        # Confirm the transport/shell is alive: an offline pidof is not proof of absence.
        assert shell('echo', 'MOCHI_STOPPED') == 'MOCHI_STOPPED'

    def original_metadata(name):
        if args.release:
            return shell('stat', '-c', '%u:%g:%a', f'/data/user/0/{PACKAGE}/files/{name}')
        return shell('run-as', PACKAGE, 'stat', '-c', '%u:%g:%a', f'files/{name}')

    def remove_original(name):
        if read_original(name) is not None:
            private_command('rm', name)

    def tap(x, y):
        shell("input", "tap", x, y)

    def pause():
        pid = shell("pidof", PACKAGE)
        shell("input", "keyevent", "KEYCODE_BACK")
        time.sleep(0.5)
        if shell("pidof", PACKAGE, check=False) != pid:
            raise RuntimeError("Back killed the load-test process")

    def screenshot(name):
        png, frame = capture_png(adb("exec-out", "screencap", binary=True))
        (output / f"{name}.png").write_bytes(png)
        report.setdefault("frame_checks", {})[name] = frame
        if not frame["has_visible_content"]:
            raise RuntimeError(f"Load screenshot {name} is blank: {frame}")

    def memory(name):
        raw = shell("dumpsys", "meminfo", PACKAGE)
        (output / f"{name}-meminfo.txt").write_text(raw, encoding="utf-8")
        match = re.search(r"TOTAL PSS:\s*(\d+)", raw)
        return {"total_pss_kib": int(match.group(1)) if match else None}

    try:
        require_owned(adb)
        report["device"] = shell("getprop", "ro.build.fingerprint")
        installed_path = shell("pm", "path", PACKAGE)
        if not installed_path.startswith("package:") or "\n" in installed_path:
            raise RuntimeError("Expected exactly one installed APK for this test")
        installed_sha = shell("sha256sum", installed_path.removeprefix("package:")).split()[0]
        report["installed_apk_sha256"] = installed_sha
        if installed_sha != hashlib.sha256(args.apk.read_bytes()).hexdigest():
            raise RuntimeError("Installed APK differs from the claimed load-test bytes")
        if args.release:
            if shell("getprop", "ro.build.type") != "userdebug" or shell("id", "-u") != "0":
                raise RuntimeError("Non-debuggable save access requires the already-rooted dedicated userdebug AVD")
        recorder.phase = 'preserve-originals'
        stop_confirmed()
        restoration = SaveRestoration(output, read_original, original_metadata,
                                     write_private, remove_original, stop_confirmed)
        restoration.capture()
        original = restoration.originals['save.json']
        assert original is not None, 'LOAD needs a valid job-created primary baseline'
        cases = fixtures(json.loads(original))
        failed_cases = []
        for name, fixture in cases.items():
            try:
                recorder.phase = name + '-load'
                stop_confirmed()
                fixture_bytes = json.dumps(fixture).encode("utf-8")
                write_private("save.json", fixture_bytes)
                (output / f"{name}-fixture.json").write_bytes(fixture_bytes)
                launch = shell("am", "start", "-W", "-n", f"{PACKAGE}/com.godot.game.GodotAppLauncher")
                if "Status: ok" not in launch:
                    raise RuntimeError(f"Load-test launch failed: {launch}")
                time.sleep(5)
                tap(530, 620 if name == "bouncy_balls" else 1036)
                time.sleep(0.15)
                pause()
                paused = state()["sessions"][name]
                pool = "balls" if name == "bouncy_balls" else "fruit"
                expected = 64 if pool == "balls" else 12
                if len(paused[pool]) != expected or paused["seed"] != fixture["sessions"][name]["seed"]:
                    raise RuntimeError(f"Production restore did not activate the {expected}-item {name} fixture")
                load = report["loads"][name] = {"initial_active": len(paused[pool]), "fixture": "synthetic production save restore", "memory_before": memory(name + "-before")}
                screenshot(name + "-maximum-paused")
                layers = shell("dumpsys", "SurfaceFlinger", "--list")
                (output / f"{name}-layers.txt").write_text(layers, encoding="utf-8")
                candidates = [line for line in layers.splitlines() if PACKAGE in line and "SurfaceView" in line and "BLAST" in line]
                if not candidates:
                    candidates = [line for line in layers.splitlines() if PACKAGE in line and "SurfaceView" in line]
                if not candidates:
                    raise RuntimeError("No actual game SurfaceView found for presentation measurement")
                layer = candidates[-1]
                load["layer"] = layer
                shell("dumpsys", "SurfaceFlinger", "--latency-clear")
                tap(360, 679)  # Resume via the actual pause button.
                stamps = []
                started = time.monotonic()
                # A fixed five-second burst produced only 11 presentations on this
                # software renderer. Observe up to 30 seconds without weakening the
                # minimum sample count or treating slow frames as phone performance.
                for sample in range(80):
                    if pool == "balls":
                        # Real paddle input under the 64-ball starting load.
                        x = [210, 510, 360][sample % 3]
                        shell("input", "swipe", 360, 1060, x, 1060, 180)
                    else:
                        # Real fast sweeps create cut halves, capped trails and particles.
                        y = [620, 740, 880][sample % 3]
                        shell("input", "swipe", 80, y, 640, y, 100)
                    time.sleep(0.12)
                    raw = shell("dumpsys", "SurfaceFlinger", "--latency", shlex.quote(layer))
                    (output / f"{name}-latency-{sample:02d}.txt").write_text(raw, encoding="utf-8")
                    for line in raw.splitlines()[1:]:
                        fields = line.split()
                        if len(fields) == 3 and all(value.isdigit() for value in fields):
                            presented = int(fields[1])
                            if 0 < presented < (1 << 63) - 1:
                                stamps.append(presented)
                    if sample in (0, 2, 5):
                        screenshot(f"{name}-running-{sample:02d}")
                    elapsed = time.monotonic() - started
                    if elapsed >= 30 or (elapsed >= 12 and len(set(stamps)) >= 21):
                        break
                load["input_burst_seconds"] = round(time.monotonic() - started, 3)
                load["input_samples"] = sample + 1
                load["presentation"] = presentation_summary(stamps)
                load["memory_after"] = memory(name + "-after")
                pause()
                after = state()["sessions"].get(name)
                load["natural_round_ended"] = after is None
                if after:
                    load.update(final_active=len(after[pool]), score=after["score"])
                    if pool == "fruit":
                        load["sliced"] = after["sliced"]
                        if after["sliced"] < 1:
                            raise RuntimeError("Jelly stress sweeps never cut a fruit")
                screenshot(name + "-after-load")
                if load["presentation"]["status"] != "MEASURED":
                    raise RuntimeError("Frame presentation measurement is unavailable; inspect raw SurfaceFlinger evidence")
                load["status"] = "PASS_LOAD_EXECUTION_AWAITING_VISUAL_REVIEW"
            except Exception as error:
                load = report["loads"].setdefault(name, {})
                load.update(status="FAIL", error=str(error))
                failed_cases.append(name)
                try:
                    screenshot(name + "-failure")
                except Exception as capture_error:
                    load["capture_error"] = str(capture_error)
        if failed_cases:
            raise RuntimeError("Load cases failed: " + ", ".join(failed_cases))
        report["status"] = "PASS_LOAD_EXECUTION_AWAITING_VISUAL_REVIEW"
    except Exception as error:
        report["error"] = str(error)
    finally:
        recorder.phase = 'restore-originals'
        report['load_execution'] = report['status']
        if restoration is not None:
            restored = restoration.restore()
            report['restoration'] = restoration.phases
            report['original_save_restored'] = restored
            report['original_backup_restored'] = restored
            if not restored:
                report['status'] = 'FAIL'
        else:
            report['restoration'] = {'status': 'NOT_RUN', 'reason': 'Preflight did not complete'}
            report['status'] = 'FAIL'
        recorder.phase = 'collect-final-logs'
        try:
            logs = adb("logcat", "-d", "-v", "threadtime")
            (output / "load-logcat.txt").write_text(logs, encoding="utf-8")
            errors = [line for line in logs.splitlines() if "SCRIPT ERROR:" in line or "FATAL EXCEPTION" in line or "Fatal signal" in line or re.search(r"\bE godot\s*:\s*ERROR:", line)]
            report["runtime_errors"] = errors
            report["graphics_swap_warnings"] = [line for line in logs.splitlines() if "eglSwapBuffers failed" in line]
            report['log_collection'] = 'PASS'
            if errors:
                report["status"] = "FAIL"
        except Exception as error:
            report["status"] = "FAIL"
            report['log_collection'] = {'status': 'FAIL', 'error': str(error)}
        if report['status'] == 'FAIL':
            report['diagnostics'] = diagnose(output/'failure-diagnostics', args.serial)
        report['runner_process_release'] = 'SEPARATE_JOB_FINALIZER'
        (output / "load-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(report, indent=2))
    return 0 if report["status"].startswith("PASS") else 1


if __name__ == "__main__":
    raise SystemExit(main())
