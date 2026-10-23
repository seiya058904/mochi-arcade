"""Exact signed public predecessor -> candidate upgrade on an owned rooted AVD.

The predecessor smoke must already have created real rounds in all eight games.
Only synthetic records and the two explicitly named app saves are modified.
After preserving upgrade/fault evidence, ordinary uninstall verifies removal.
Candidate clean-install smoke uses its own AVD. Never target a phone/shared AVD.
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
from release_identity import identity, build_inputs
from fetch_staged_release import verify
from upgrade_semantics import restored, compare
from android_evidence import AdbEvidence

PACKAGE = "io.github.seiya058904.mochiarcade"
ACTIVITY = PACKAGE + "/com.godot.game.GodotAppLauncher"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--old-evidence", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--predecessor", choices=identity()["predecessors"], required=True)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--source", required=True)
    args = parser.parse_args()
    config = identity()
    candidate = config["candidate"]
    predecessor = config["predecessors"][args.predecessor]
    build_inputs(args.sha256, args.source)
    verify(args.apk, args.sha256, candidate["version"], candidate["code"])
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    report = {"status": "FAIL", "commit": os.environ.get("GITHUB_SHA", "local"),
              "apk_sha256": hashlib.sha256(args.apk.read_bytes()).hexdigest(),
              "scope": "Disposable AOSP API 34 userdebug AVD; real predecessor rounds plus explicit synthetic records; not phone performance",
              "checks": [], "commands": []}
    report.update(build_source=args.source, predecessor_tag=args.predecessor, predecessor_sha256=predecessor["sha256"], semantics={})
    paths = {name: f"/data/user/0/{PACKAGE}/files/{name}" for name in ["save.json", "save.backup.json"]}

    recorder = AdbEvidence(out, timeout=120)
    report['command_timeline'] = 'adb-timeline.jsonl'

    def adb(*parts, data=None, binary=False, check=True):
        return recorder(*parts, data=data, binary=binary, check=check)

    def shell(*parts, **kwargs):
        return adb("shell", *parts, **kwargs)

    def stop():
        shell("am", "force-stop", PACKAGE)

    def read(name="save.json"):
        return shell("cat", paths[name], binary=True)

    def write(name, value):
        shell("tee", paths[name], data=value)

    def fixture(value):
        recorder.phase = 'upgrade-fixture'
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
        recorder.phase = name
        png, frame = capture_png(adb("exec-out", "screencap", binary=True))
        (out / (name + ".png")).write_bytes(png)
        report.setdefault("frames", {})[name] = frame
        assert frame["has_visible_content"], f"Blank native frame: {name}"

    def passed(name):
        report["checks"].append(name)

    log_stream = None
    log_file = None
    try:
        # Require the job-owned AVD identity, not merely an emulator port.
        assert os.environ.get("GITHUB_ACTIONS") == "true", "Destructive fixtures require the isolated hosted job"
        avd_name = adb("emu", "avd", "name").splitlines()[0]
        assert avd_name == "Mochi_CI_API34"
        assert Path(os.environ["ANDROID_AVD_HOME"]).resolve().is_relative_to(Path(os.environ["RUNNER_TEMP"]).resolve())
        assert shell("getprop", "ro.kernel.qemu") == "1"
        assert shell("getprop", "ro.build.type") == "userdebug" and shell("id", "-u") == "0"
        report["device"] = shell("getprop", "ro.build.fingerprint")
        log_file = (out / "stream-logcat.txt").open("wb")
        log_stream = subprocess.Popen(["adb", "-s", "emulator-5554", "logcat", "-v", "threadtime"],
                                      stdout=log_file, stderr=subprocess.STDOUT)
        old_report = json.loads((args.old_evidence / "report.json").read_text())
        assert old_report["status"] == "PASS_SMOKE_AWAITING_VISUAL_REVIEW" and old_report["release_candidate"]
        assert old_report["apk_sha256"] == predecessor["sha256"]
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
        assert f"versionCode={predecessor['code']} " in before_package and f"versionName={predecessor['version']}\n" in before_package
        result = adb("install", "--no-incremental", "-r", str(args.apk.resolve()))
        assert "Success" in result
        after_package = shell("dumpsys", "package", PACKAGE)
        (out / "after-package.txt").write_text(after_package)
        assert f"versionCode={candidate['code']} " in after_package and f"versionName={candidate['version']}\n" in after_package
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
            report["semantics"][game] = restored(game, state["sessions"][game], observed["sessions"][game])
            assert observed["records"] == state["records"] and observed["settings"] == state["settings"]
            tap(360, 775)
            before = observed["sessions"][game]
            if game in ["number_bloom", "tile_trio"]:
                tap(430, 1210)  # Real footer Undo from restored history.
                undone = json.loads(read())["sessions"][game]
                if game == "number_bloom":
                    assert before["undo"], "Predecessor must supply a real Undo snapshot"
                    for key in ["board", "score", "rng", "won"]:
                        compare(before["undo"][key], undone[key], "Bloom Undo " + key)
                    assert undone["undo"] == {}
                    shell("input", "swipe", 560, 700, 150, 700, 300)
                else:
                    assert before["history"], "Predecessor must supply real tile history"
                    for key in ["mask", "tray", "score"]:
                        compare(before["history"][-1][key], undone[key], "Trio Undo " + key)
                    assert undone["history"] == before["history"][:-1]
                    report["semantics"][game]["continuation"] = "Actual native Undo restores the last tile and reduces history by one"
                report["semantics"][game]["undo"] = "PASS"
            elif game == "mochi_hop":
                import math
                hold = (math.dist(before["foot"], before["target"]["center"]) - 70) / 280 * 1200
                shell("input", "swipe", 360, 700, 360, 700, round(hold))
                time.sleep(1.5)
            elif game == "fruit_drop":
                shell("input", "swipe", 360, 520, 280, 520, 300)
            elif game == "bubble_garden":
                shell("input", "swipe", 360, 1030, 280, 520, 300)
                time.sleep(1.5)
            elif game == "cake_stack":
                # Time progression itself demonstrates resumed moving platform;
                # avoid guessing a safe landing at an arbitrary saved phase.
                time.sleep(0.6)
            elif game == "bouncy_balls":
                shell("input", "swipe", 360, 1060, 430, 1060, 300)
            else:
                shell("input", "swipe", 80, 720, 640, 720, 120)
            shell("input", "keyevent", "KEYCODE_BACK")
            time.sleep(0.8)
            shot("upgraded-" + game + "-after-input")
            assert shell("pidof", PACKAGE)
            after = json.loads(read())["sessions"].get(game)
            assert after is not None, game + " unexpectedly ended during continuation"
            if game == "cake_stack":
                assert after["time"] > before["time"]
            elif game == "mochi_hop":
                assert after["landed"] == before["landed"] + 1 and after["score"] > before["score"]
            elif game == "fruit_drop":
                assert after["rng"] != before["rng"]
            elif game == "bubble_garden":
                assert after["grid"] != before["grid"] or after["stage"] != before["stage"]
            elif game == "bouncy_balls":
                assert after["paddle"] != before["paddle"] or after["balls"] != before["balls"]
            elif game == "jelly_slice":
                assert after["fruit"] != before["fruit"] or after["launched"] > before["launched"]
            elif game == "number_bloom":
                assert after["undo"], "Actual swipe after restored Undo must produce a new history snapshot"
            report["semantics"][game]["continued_state"] = after
            passed(game + " full persistent semantics and native continuation; records/settings retained")
        # Real final legal swipe, then the new three-button result's Undo entry.
        terminal = copy.deepcopy(state)
        terminal["settings"]["language"] = "en"
        terminal["settings"]["music"] = True
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
        (out/'bloom-terminal-audio-before.txt').write_text(shell('dumpsys','media.audio_flinger'),encoding='utf-8')
        terminal_pid = shell("pidof", PACKAGE)
        shell("input", "keyevent", "KEYCODE_HOME")
        time.sleep(0.8)
        launch()
        assert shell("pidof", PACKAGE) == terminal_pid
        shot("bloom-terminal-background-return")
        (out/'bloom-terminal-audio-return.txt').write_text(shell('dumpsys','media.audio_flinger'),encoding='utf-8')
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
        trio = json.loads(Path('tests/integration/fixtures/terminal-trio.json').read_text(encoding='utf-8'))
        terminal = copy.deepcopy(state)
        terminal['settings'].update(language='en', music=True)
        terminal['seen']['tile_trio'] = False
        terminal['sessions']['tile_trio'] = trio['initial']
        fixture(terminal);launch();tap(190,828);tap(360,775)
        for x,y in trio['taps']:
            tap(round(x),round(y))
        time.sleep(.8)
        assert 'tile_trio' not in json.loads(read())['sessions'], 'Seven real inputs did not reach terminal tray'
        shot('trio-terminal-before-undo')
        terminal_pid=shell('pidof',PACKAGE)
        shell('input','keyevent','KEYCODE_HOME');time.sleep(.8);launch()
        assert shell('pidof',PACKAGE)==terminal_pid
        shot('trio-terminal-background-return')
        (out/'trio-terminal-audio-return.txt').write_text(shell('dumpsys','media.audio_flinger'),encoding='utf-8')
        tap(360,679)
        restored_trio=json.loads(read())
        compare(trio['before_last'],restored_trio['sessions']['tile_trio'],'Native terminal Trio Undo')
        assert restored_trio['records']==terminal['records']
        shot('trio-terminal-undone')
        # Repeat the real final selection to prove resumed input remains functional.
        tap(*map(round,trio['taps'][-1]));time.sleep(.8)
        assert 'tile_trio' not in json.loads(read())['sessions']
        passed('Seven native Trio picks reach full tray; terminal background return, actual Undo and next input pass')
        report['terminal_audio_scope']='Enabled music and retained AudioFlinger state; Android output not captured/listened. Desktop mixer evidence remains separate.'
        for damage in ["invalid-json", "damaged-fields", "settings-section"]:
            fixture(state)
            broken = copy.deepcopy(state)
            broken["records"]["number_bloom"] = "broken"
            broken["sessions"]["number_bloom"]["board"] = ["broken"]
            expected_records = state["records"]
            if damage == "settings-section":
                broken = copy.deepcopy(state)
                broken["settings"] = []
                broken["records"]["number_bloom"] = 9999
                expected_records = broken["records"]
            write("save.json", b'{"interrupted":' if damage == "invalid-json" else json.dumps(broken).encode())
            launch()
            tap(650, 70)
            tap(608, 360)  # A real setting change commits recovered memory.
            shot("recovery-" + damage)
            recovered = json.loads(read())
            assert recovered["records"] == expected_records and recovered["sessions"] == state["sessions"]
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
        if log_stream is not None:
            if log_stream.poll() is None:
                log_stream.terminate()
                try:
                    log_stream.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    log_stream.kill()
                    log_stream.wait(timeout=10)
            report["log_stream_exit"] = log_stream.returncode
        if log_file is not None:
            log_file.close()
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
