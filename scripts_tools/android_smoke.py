"""ADB integration smoke on a dedicated 720x1280 Android test emulator.

This never changes an existing user's app data. The caller supplies a newly
created test AVD. Screenshots and saved-state observations require review before
claiming Android visual/touch acceptance; command success alone is insufficient.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time


GAMES = ["fruit_drop", "bubble_garden", "cake_stack", "bouncy_balls",
         "tile_trio", "mochi_hop", "number_bloom", "jelly_slice"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--emulator-pid", type=int)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    package = "io.github.seiya058904.mochiarcade"
    commands = []
    report = {"status": "FAIL", "commit": os.environ.get("GITHUB_SHA", "local"),
              "apk_sha256": hashlib.sha256(args.apk.read_bytes()).hexdigest(),
              "environment": "Dedicated GitHub-hosted Android API 34 x86_64 emulator; not a physical phone",
              "visual_review": "PENDING", "commands": commands}

    def adb(*parts, binary=False, timeout=30, check=True):
        command = ["adb", "-s", args.serial, *map(str, parts)]
        started = time.monotonic()
        result = subprocess.run(command, capture_output=True, timeout=timeout)
        commands.append({"args": command[3:], "exit": result.returncode,
                         "seconds": round(time.monotonic() - started, 3)})
        if check and result.returncode:
            raise RuntimeError(f"ADB failed: {parts}: {result.stderr.decode(errors='replace')}")
        return result.stdout if binary else result.stdout.decode(errors="replace").strip()

    def shell(*parts, **kwargs):
        return adb("shell", *parts, **kwargs)

    def tap(x, y):
        shell("input", "tap", x, y)
        time.sleep(0.18)

    def swipe(x1, y1, x2, y2, duration=300):
        shell("input", "swipe", x1, y1, x2, y2, duration)
        time.sleep(0.15)

    def screenshot(name):
        data = adb("exec-out", "screencap", "-p", binary=True)
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise RuntimeError("Invalid Android screenshot")
        (output / f"{name}.png").write_bytes(data)

    def launch():
        # Godot 4.7 exposes this launcher alias; the target activity is private.
        result = shell("am", "start", "-W", "-n", f"{package}/com.godot.game.GodotAppLauncher")
        if "Error:" in result or "Status: ok" not in result:
            raise RuntimeError(f"Launch did not succeed: {result}")
        time.sleep(2)
        if not shell("pidof", package):
            raise RuntimeError("App process exited after launch")
        return result

    def park():
        shell("input", "keyevent", "KEYCODE_HOME")
        time.sleep(0.6)  # Actual background notification must checkpoint first.
        shell("am", "force-stop", package)

    def saved_state():
        raw = adb("exec-out", "run-as", package, "cat", "files/save.json")
        return json.loads(raw)

    try:
        deadline = time.monotonic() + 240
        while time.monotonic() < deadline:
            if args.emulator_pid:
                try:
                    os.kill(args.emulator_pid, 0)
                except ProcessLookupError:
                    raise RuntimeError("Emulator process exited before boot; inspect emulator.log")
            boot = shell("getprop", "sys.boot_completed", timeout=10, check=False)
            if boot == "1":
                break
            time.sleep(3)
        else:
            raise RuntimeError("Android did not finish booting within 240 seconds")
        report["device"] = {key: shell("getprop", key) for key in
                            ["ro.product.model", "ro.build.version.release", "ro.build.version.sdk", "ro.product.cpu.abi", "ro.build.fingerprint"]}
        report["display"] = shell("wm", "size")
        if "720x1280" not in report["display"]:
            raise RuntimeError("This explicit coordinate test requires a 720x1280 dedicated AVD")
        shell("input", "keyevent", "KEYCODE_WAKEUP")
        shell("wm", "dismiss-keyguard")
        adb("logcat", "-c")
        install = adb("install", "-r", str(args.apk.resolve()), timeout=120)
        if "Success" not in install:
            raise RuntimeError(f"Install failed: {install}")
        report["install"] = install
        report["cold_launch"] = launch()
        screenshot("00-home")
        for index, game in enumerate(GAMES):
            if index:
                launch()
            tap(190 if index % 2 == 0 else 530, 412 + (index // 2) * 208)
            time.sleep(0.3)
            screenshot(f"{index + 1:02d}-{game}-help")
            tap(360, 775)
            time.sleep(0.3)
            screenshot(f"{index + 1:02d}-{game}-ready")
            if index == 0:
                for x in [280, 440, 280]:
                    swipe(360, 520, x, 520)
                    time.sleep(0.5)
            elif index == 1:
                swipe(360, 1030, 280, 520)
                time.sleep(1.5)
            elif index == 2:
                tap(360, 620)
            elif index == 3:
                for x in [500, 230, 430]:
                    swipe(360, 1060, x, 1060, 650)
            elif index == 4:
                for point in [(310, 430), (410, 430), (310, 530)]:
                    tap(*point)
                    time.sleep(0.25)
            elif index == 5:
                swipe(360, 700, 360, 700, 600)
                time.sleep(1)
            elif index == 6:
                for _ in range(3):
                    swipe(560, 700, 150, 700)
                    swipe(360, 950, 360, 500)
            elif index == 7:
                for _ in range(8):
                    swipe(80, 720, 640, 720, 120)
                    swipe(640, 900, 80, 900, 120)
                tap(470, 1190)  # Actual Finish break control.
            time.sleep(0.5)
            screenshot(f"{index + 1:02d}-{game}-after-input")
            shell("input", "keyevent", "KEYCODE_BACK")
            time.sleep(0.3)
            screenshot(f"{index + 1:02d}-{game}-after-back")
            park()
            state = saved_state()
            if not state.get("seen", {}).get(game):
                raise RuntimeError(f"The real home tap never entered {game}")
            (output / f"{index + 1:02d}-{game}-save.json").write_text(json.dumps(state, indent=2), encoding="utf-8")
        launch()
        tap(650, 70)
        tap(608, 360)  # Music off.
        tap(360, 810)  # Chinese.
        screenshot("09-settings-zh")
        park()
        launch()
        screenshot("10-restarted-home-zh")
        state = saved_state()
        if state["settings"]["music"] is not False or state["settings"]["language"] != "zh":
            raise RuntimeError("Settings did not survive background + force-stop + launch")
        if set(GAMES) - set(state["seen"]):
            raise RuntimeError("Not all eight games were actually entered")
        report["seen_games"] = list(state["seen"])
        report["records"] = state["records"]
        report["settings_persisted"] = True
        (output / "meminfo.txt").write_text(shell("dumpsys", "meminfo", package), encoding="utf-8")
        logs = adb("logcat", "-d", "-v", "threadtime")
        (output / "logcat.txt").write_text(logs, encoding="utf-8")
        errors = [line for line in logs.splitlines() if
                  ("SCRIPT ERROR:" in line or "FATAL EXCEPTION" in line or "Fatal signal" in line)]
        report["runtime_errors"] = errors
        if errors:
            raise RuntimeError("Android runtime errors were recorded")
        report["status"] = "PASS_SMOKE_AWAITING_VISUAL_REVIEW"
    except Exception as error:
        report["error"] = str(error)
        try:
            screenshot("failure-screen")
            (output / "logcat.txt").write_text(adb("logcat", "-d", "-v", "threadtime"), encoding="utf-8")
        except Exception as capture_error:
            report["capture_error"] = str(capture_error)
    finally:
        (output / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        summary = {key: value for key, value in report.items() if key != "commands"}
        print(json.dumps(summary, indent=2))
    return 0 if report["status"].startswith("PASS") else 1


if __name__ == "__main__":
    raise SystemExit(main())
