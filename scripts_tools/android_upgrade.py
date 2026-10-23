"""Exact signed v1.0.0 -> candidate upgrade on the job's disposable rooted AVD.

The predecessor smoke must already have created real rounds in all eight games.
Only synthetic records and the two explicitly named app saves are modified.
After preserving upgrade/fault evidence, ordinary uninstall prepares the separate
candidate clean-install smoke. Never run this against a phone or shared AVD.
"""
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

from android_capture import capture_png
from android_smoke import GAMES

PACKAGE = "io.github.seiya058904.mochiarcade"
ACTIVITY = PACKAGE + "/com.godot.game.GodotAppLauncher"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--old-evidence", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    report = {"status": "FAIL", "commit": os.environ.get("GITHUB_SHA", "local"),
              "apk_sha256": hashlib.sha256(args.apk.read_bytes()).hexdigest(),
              "scope": "Disposable AOSP API 34 userdebug AVD; real predecessor rounds plus explicit synthetic records; not phone performance",
              "checks": [], "commands": []}
    paths = {name: f"/data/user/0/{PACKAGE}/files/{name}" for name in ["save.json", "save.backup.json"]}

    def adb(*parts, data=None, binary=False, check=True):
        result = subprocess.run(["adb", "-s", "emulator-5554", *map(str, parts)], input=data, capture_output=True, timeout=120)
        report["commands"].append({"args": list(map(str, parts)), "exit": result.returncode})
        if check and result.returncode:
            raise RuntimeError(f"ADB {parts} failed: {result.stderr.decode(errors='replace')}")
        return result.stdout if binary else result.stdout.decode(errors="replace").strip()

    def shell(*parts, **kwargs):
        return adb("shell", *parts, **kwargs)

    def stop():
        shell("am", "force-stop", PACKAGE)

    def read(name="save.json"):
        return shell("cat", paths[name], binary=True)

    def write(name, value):
        shell("tee", paths[name], data=value)

    def fixture(value):
        stop()
        for name in paths:
            shell("chmod", "600", paths[name])
            write(name, json.dumps(value).encode())

    def launch():
        text = shell("am", "start", "-W", "-n", ACTIVITY)
        assert "Status: ok" in text and "Error:" not in text
        time.sleep(5)
        assert shell("pidof", PACKAGE), "App died after launch"

    def tap(x, y):
        shell("input", "tap", x, y)
        time.sleep(0.6)

    def shot(name):
        png, frame = capture_png(adb("exec-out", "screencap", binary=True))
        (out / (name + ".png")).write_bytes(png)
        report.setdefault("frames", {})[name] = frame
        assert frame["has_visible_content"], f"Blank native frame: {name}"

    def passed(name):
        report["checks"].append(name)

    try:
        assert shell("getprop", "ro.kernel.qemu") == "1"
        assert shell("getprop", "ro.build.type") == "userdebug" and shell("id", "-u") == "0"
        report["device"] = shell("getprop", "ro.build.fingerprint")
        old_report = json.loads((args.old_evidence / "report.json").read_text())
        assert old_report["status"] == "PASS_SMOKE_AWAITING_VISUAL_REVIEW" and old_report["release_candidate"]
        assert old_report["apk_sha256"] == "8fcc1ebc83cb9cb8e8947a1a33bef9cba9222b9ac775fafdcd7d3d5cd85d473c"
        stop()
        state = json.loads(read())
        for index, game in enumerate(GAMES):
            prior = json.loads((args.old_evidence / f"{index + 1:02d}-{game}-save.json").read_text())
            state["sessions"][game] = prior["sessions"][game]
            state["records"][game] = max(state["records"].get(game, 0), 1000 + index)
        state["settings"]["language"] = "en"
        fixture(state)
        launch()
        shot("old-en-records")
        assert json.loads(read()) == state
        stop()
        state["settings"]["language"] = "zh"
        fixture(state)
        launch()
        shot("old-zh-records")
        assert json.loads(read()) == state
        stop()
        original = {name: read(name) for name in paths}
        for name, data in original.items():
            (out / ("before-" + name)).write_bytes(data)
        before_package = shell("dumpsys", "package", PACKAGE)
        assert "versionCode=1 " in before_package and "versionName=1.0.0" in before_package
        result = adb("install", "--no-incremental", "-r", str(args.apk.resolve()))
        assert "Success" in result
        after_package = shell("dumpsys", "package", PACKAGE)
        (out / "after-package.txt").write_text(after_package)
        assert "versionCode=2 " in after_package and "versionName=1.1.0" in after_package
        assert all(read(name) == data for name, data in original.items()), "Install -r changed save bytes"
        launch()
        shot("upgraded-zh-records")
        assert json.loads(read()) == state, "Candidate launch lost predecessor data"
        passed("Original signed upgrade preserves both files byte-for-byte and all eight rounds/records/settings after launch")
        for index, game in enumerate(GAMES):
            case = copy.deepcopy(state)
            case["seen"][game] = False  # First-help pauses the restored round before any simulation tick.
            fixture(case)
            launch()
            tap(190 if index % 2 == 0 else 530, 412 + (index // 2) * 208)
            shot("upgraded-" + game + "-restored")
            observed = json.loads(read())
            assert observed["sessions"][game]["seed"] == state["sessions"][game]["seed"]
            assert observed["sessions"][game]["score"] == state["sessions"][game]["score"]
            assert observed["records"] == state["records"] and observed["settings"] == state["settings"]
            tap(360, 775)
            shell("input", "swipe", 350, 700, 430, 700, 300)
            shell("input", "keyevent", "KEYCODE_BACK")
            time.sleep(0.8)
            shot("upgraded-" + game + "-after-input")
            assert shell("pidof", PACKAGE)
            passed(game + " restored seed/score, retained records/settings and accepted native input")
        # Real final legal swipe, then the new three-button result's Undo entry.
        terminal = copy.deepcopy(state)
        terminal["settings"]["language"] = "en"
        terminal["seen"]["number_bloom"] = False
        board = [2, 4, 8, 16, 4, 8, 16, 32, 8, 16, 32, 64, 2, 2, 8, 16]
        terminal["sessions"]["number_bloom"].update(board=board, score=64, undo={}, won=False)
        fixture(terminal)
        launch()
        tap(190, 1036)
        tap(360, 775)
        shell("input", "swipe", 560, 700, 150, 700, 300)
        time.sleep(1)
        shot("bloom-terminal-before-undo")
        tap(360, 679)  # First button of the three-action result: Undo last move.
        time.sleep(0.6)
        undone = json.loads(read())
        assert undone["sessions"]["number_bloom"]["board"] == board
        assert undone["sessions"]["number_bloom"]["score"] == 64
        assert undone["sessions"]["number_bloom"]["undo"] == {}
        assert undone["records"] == terminal["records"]
        shot("bloom-terminal-undone")
        stop()
        launch()
        assert json.loads(read())["sessions"]["number_bloom"] == undone["sessions"]["number_bloom"]
        passed("Actual terminal swipe and result Undo restore board/score and survive process restart")
        for damage in ["invalid-json", "damaged-fields"]:
            fixture(state)
            broken = copy.deepcopy(state)
            broken["records"]["number_bloom"] = "broken"
            broken["sessions"]["number_bloom"]["board"] = ["broken"]
            write("save.json", b'{"interrupted":' if damage == "invalid-json" else json.dumps(broken).encode())
            launch()
            tap(650, 70)
            tap(608, 360)  # A real setting change commits recovered memory.
            shot("recovery-" + damage)
            recovered = json.loads(read())
            assert recovered["records"] == state["records"] and recovered["sessions"] == state["sessions"]
            assert recovered["settings"]["music"] != state["settings"]["music"]
            passed(damage + " recovers all eight records/rounds from valid backup")
        fixture(state)
        unreadable = read()
        shell("chmod", "000", paths["save.json"])
        launch()
        tap(650, 70)
        tap(608, 360)
        shot("read-denied-settings")
        stop()
        assert read() == unreadable, "Unreadable original was replaced"
        shell("chmod", "600", paths["save.json"])
        passed("Read-denied primary survives settings mutation and process stop byte-for-byte")
        logs = adb("logcat", "-d", "-v", "threadtime")
        (out / "logcat.txt").write_text(logs)
        errors = [line for line in logs.splitlines() if "SCRIPT ERROR:" in line or "FATAL EXCEPTION" in line or "Fatal signal" in line or re.search(r"\bE godot\s*:\s*ERROR:", line)]
        report["runtime_errors"] = errors
        assert not errors, "Native/script runtime error during upgrade"
        stop()
        assert "Success" in adb("uninstall", PACKAGE)
        assert not shell("pm", "path", PACKAGE, check=False)
        assert shell("test", "-e", f"/data/user/0/{PACKAGE}", check=False) == ""
        # The shell command's exit status is independently checked here.
        remaining = subprocess.run(["adb", "-s", "emulator-5554", "shell", "test", "-e", f"/data/user/0/{PACKAGE}"], capture_output=True)
        assert remaining.returncode == 1, "Ordinary uninstall retained app data"
        passed("Ordinary uninstall removes package and app data; next smoke is a clean install")
        report["status"] = "PASS_UPGRADE_AWAITING_VISUAL_REVIEW"
    except Exception as error:
        report["error"] = str(error)
    finally:
        if report["status"] == "FAIL":
            try:
                for name in paths:
                    (out / ("failure-" + name)).write_bytes(read(name))
                shot("failure")
                (out / "failure-logcat.txt").write_text(adb("logcat", "-d", "-v", "threadtime"))
            except Exception as capture_error:
                report["failure_capture_error"] = str(capture_error)
        (out / "upgrade-report.json").write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps({key: value for key, value in report.items() if key != "commands"}, indent=2))
    return 0 if report["status"].startswith("PASS") else 1


if __name__ == "__main__":
    raise SystemExit(main())
