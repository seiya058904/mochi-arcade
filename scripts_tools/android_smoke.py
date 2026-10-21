"""ADB integration smoke on a dedicated 720x1280 Android test emulator.

This never changes an existing user's app data. The caller supplies a newly
created test AVD. Screenshots and saved-state observations require review before
claiming Android visual/touch acceptance; command success alone is insufficient.
"""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
import subprocess
import time
import xml.etree.ElementTree as ET
from android_capture import capture_png


GAMES = ["fruit_drop", "bubble_garden", "cake_stack", "bouncy_balls",
         "tile_trio", "mochi_hop", "number_bloom", "jelly_slice"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--emulator-pid", type=int)
    parser.add_argument("--release", action="store_true", help="Inspect a non-debuggable APK on this dedicated userdebug AVD with adb root")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    package = "io.github.seiya058904.mochiarcade"
    commands = []
    report = {"status": "FAIL", "commit": os.environ.get("GITHUB_SHA", "local"),
              "apk_sha256": hashlib.sha256(args.apk.read_bytes()).hexdigest(),
              "environment": "Dedicated GitHub-hosted Android API 34 x86_64 emulator; not a physical phone",
              "graphics_backend_requested": os.environ.get("MOCHI_EMULATOR_GPU", "unrecorded"),
              "visual_review": "PENDING", "commands": commands, "release_candidate": args.release,
              "game_checks": {}}

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

    def screenshot(name, allow_blank=False):
        time.sleep(0.8)  # Capture the committed rendered frame, not just ADB's input acknowledgement.
        data, frame = capture_png(adb("exec-out", "screencap", binary=True))
        (output / f"{name}.png").write_bytes(data)
        frame["sha256"] = hashlib.sha256(data).hexdigest()
        report.setdefault("frame_checks", {})[name] = frame
        if not allow_blank and not frame["has_visible_content"]:
            raise RuntimeError(f"Android screenshot {name} is blank: {frame}")
        return frame["sha256"]

    def launch():
        # Godot 4.7 exposes this launcher alias; the target activity is private.
        result = shell("am", "start", "-W", "-n", f"{package}/com.godot.game.GodotAppLauncher")
        if "Error:" in result or "Status: ok" not in result:
            raise RuntimeError(f"Launch did not succeed: {result}")
        time.sleep(5)  # Native activity visibility precedes first Godot/font rendering.
        if not shell("pidof", package):
            raise RuntimeError("App process exited after launch")
        return result

    def park():
        shell("input", "keyevent", "KEYCODE_HOME")
        time.sleep(0.6)  # Actual background notification must checkpoint first.
        shell("am", "force-stop", package)

    def saved_state():
        raw = (shell("cat", f"/data/user/0/{package}/files/save.json") if args.release else
               shell("run-as", package, "cat", "files/save.json"))
        return json.loads(raw)

    def back():
        pid = shell("pidof", package)
        shell("input", "keyevent", "KEYCODE_BACK")
        time.sleep(1)
        if shell("pidof", package, check=False) != pid:
            raise RuntimeError("System Back exited or replaced the running app process")

    def open_card(index):
        tap(190 if index % 2 == 0 else 530, 412 + (index // 2) * 208)
        time.sleep(0.7)

    def wait_for_entry(game):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            raw = (shell("cat", f"/data/user/0/{package}/files/save.json", check=False) if args.release else
                   shell("run-as", package, "cat", "files/save.json", check=False))
            if raw and json.loads(raw).get("seen", {}).get(game):
                return
            time.sleep(0.5)
        raise RuntimeError(f"Home input did not actually enter {game} within 15 seconds")

    def install_apk():
        # Complete the install before launch; incremental delivery can still change
        # package resources while the activity is starting on a fresh AVD.
        result = adb("install", "--no-incremental", "-r", str(args.apk.resolve()), timeout=120)
        if "Success" not in result:
            raise RuntimeError(f"Install failed: {result}")
        return result

    def dismiss_fullscreen_tip():
        # Inspect the real Android system UI; never tap a presumed overlay blindly.
        deadline = time.monotonic() + 25
        tapped = False
        while time.monotonic() < deadline:
            shell("uiautomator", "dump", "/sdcard/mochi-window.xml")
            document = shell("cat", "/sdcard/mochi-window.xml")
            (output / "fullscreen-window.xml").write_text(document, encoding="utf-8")
            buttons = [node for node in ET.fromstring(document).iter("node")
                       if node.get("text", "").upper() == "GOT IT"]
            if not buttons:
                report["fullscreen_tip_dismissed"] = tapped
                time.sleep(1)
                return
            if not tapped:
                node = buttons[0]
                bounds = [int(n) for n in re.findall(r"\d+", node.attrib["bounds"])]
                tap((bounds[0] + bounds[2]) // 2, (bounds[1] + bounds[3]) // 2)
                tapped = True
            time.sleep(1)
        raise RuntimeError("Android fullscreen instruction stayed visible after its actual button was tapped")

    def check_launcher_icon():
        shell("input", "keyevent", "KEYCODE_HOME")
        deadline = time.monotonic() + 15
        workspace_visible = False
        while time.monotonic() < deadline:
            shell("uiautomator", "dump", "/sdcard/mochi-launcher.xml")
            launcher = shell("cat", "/sdcard/mochi-launcher.xml")
            (output / "launcher-home.xml").write_text(launcher, encoding="utf-8")
            workspace_visible = any(node.get("resource-id") == "com.android.launcher3:id/workspace"
                                    for node in ET.fromstring(launcher).iter("node"))
            if workspace_visible:
                break
            time.sleep(0.5)
        if not workspace_visible:
            raise RuntimeError("Android Home did not show the actual Launcher workspace")
        # This empty workspace area is visible in the retained AOSP home frame.
        # The former y=1180 start was at the bottom navigation boundary.
        swipe(540, 950, 540, 300, 700)
        deadline = time.monotonic() + 15
        icons = []
        while time.monotonic() < deadline:
            shell("uiautomator", "dump", "/sdcard/mochi-launcher.xml")
            launcher = shell("cat", "/sdcard/mochi-launcher.xml")
            (output / "launcher.xml").write_text(launcher, encoding="utf-8")
            icons = [node for node in ET.fromstring(launcher).iter("node")
                     if node.get("text") == "Mochi Arcade" or node.get("content-desc") == "Mochi Arcade"]
            if icons:
                break
            time.sleep(0.5)
        if not icons:
            raise RuntimeError("Actual Android launcher did not expose the Mochi Arcade icon")
        screenshot("15-android-launcher-icon")
        bounds = [int(n) for n in re.findall(r"\d+", icons[0].attrib["bounds"])]
        tap((bounds[0] + bounds[2]) // 2, (bounds[1] + bounds[3]) // 2)
        time.sleep(5)
        if not shell("pidof", package, check=False):
            raise RuntimeError("Launcher icon did not start the app")
        screenshot("16-launcher-icon-opened-app")
        report["launcher_icon_tapped"] = True

    def runtime_errors(logs):
        return [line for line in logs.splitlines() if
                "SCRIPT ERROR:" in line or "FATAL EXCEPTION" in line or "Fatal signal" in line or
                re.search(r"\bE godot\s*:\s*ERROR:", line)]

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
        if not args.serial.startswith("emulator-") or shell("getprop", "ro.kernel.qemu") != "1":
            raise RuntimeError("This fixture must only operate on the dedicated test emulator")
        # sys.boot_completed can precede the first boot's input-device registration.
        # Those configuration changes recreated the activity during run 39655181653.
        time.sleep(15)
        if args.release:
            if shell("getprop", "ro.build.type") != "userdebug":
                raise RuntimeError("Release save inspection requires the dedicated AOSP userdebug image")
            report["adb_root"] = adb("root")
            adb("wait-for-device")
            if shell("id", "-u") != "0":
                raise RuntimeError("Dedicated emulator root did not become available")
            report["save_access"] = "Rooted dedicated test AVD; APK remains non-debuggable"
        shell("input", "keyevent", "KEYCODE_WAKEUP")
        shell("wm", "dismiss-keyguard")
        shell("svc", "wifi", "disable")
        shell("svc", "data", "disable")
        report["network_disabled_for_test"] = True
        adb("logcat", "-c")
        report["install"] = install_apk()
        report["cold_launch"] = launch()
        dismiss_fullscreen_tip()
        screenshot("00-home")
        # The original WAV endpoint crashed AudioTrack on its first 16-second
        # loop. Exercise the real Android mixer before entering any game.
        time.sleep(20)
        if not shell("pidof", package, check=False):
            raise RuntimeError("Android app exited while the first background-music loop played")
        report["first_music_loop_survived"] = True
        initial_errors = runtime_errors(adb("logcat", "-d", "-v", "threadtime"))
        if initial_errors:
            report["runtime_errors"] = initial_errors
            raise RuntimeError("Android renderer or script failed during initial launch")
        # Check the independent launcher path before a later game failure can
        # prevent it. A launcher failure remains an overall failure, even while
        # independent game checks continue from a direct activity launch.
        try:
            check_launcher_icon()
        except Exception as launcher_error:
            report["launcher_error"] = str(launcher_error)
            screenshot("launcher-failure", allow_blank=True)
            launch()
        for index, game in enumerate(GAMES):
            if index:
                launch()
            open_card(index)
            wait_for_entry(game)
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
                # The generated top layer can shift one column. The common
                # center column is always exposed; its removed bit identifies
                # which other column is visible, without modifying the board.
                picks = report["trio_touch_observations"] = []

                def pick_trio(x, y):
                    before = saved_state()["sessions"][game]
                    tap(x, y)
                    deadline = time.monotonic() + 5
                    while time.monotonic() < deadline:
                        after = saved_state()["sessions"][game]
                        if len(after["history"]) != len(before["history"]):
                            break
                        time.sleep(0.2)
                    removed = int(before["mask"]) ^ int(after["mask"])
                    picks.append({"point": [x, y], "before_mask": before["mask"],
                                  "after_mask": after["mask"], "removed_bits": removed,
                                  "history_count": len(after["history"])})
                    if len(after["history"]) != len(before["history"]) + 1 or removed.bit_count() != 1:
                        raise RuntimeError(f"Trio touch at {(x, y)} did not select exactly one tile: {picks[-1]}")
                    # The checkpoint precedes the 0.18-second flight animation.
                    # Give the software-rendered AVD time to commit that animation
                    # before the next touch; an ADB acknowledgement is not readiness.
                    time.sleep(0.6)
                    return after

                first_mask = int(pick_trio(360, 510)["mask"])
                other_x = 460 if not first_mask & (1 << 32) else 260
                for point in [(360, 610), (other_x, 510), (other_x, 610)]:
                    pick_trio(*point)
                trio = saved_state()["sessions"][game]
                if len(trio["history"]) != 4 or int(trio["mask"]) >> 32:
                    raise RuntimeError("Trio touches did not remove the four exposed top tiles")
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
            time.sleep(0.5)
            screenshot(f"{index + 1:02d}-{game}-after-input")
            state = saved_state()
            game_check = report["game_checks"][game] = {"entered": bool(state.get("seen", {}).get(game))}
            if not game_check["entered"]:
                raise RuntimeError(f"The real home tap never entered {game}")
            if game not in state["sessions"]:
                game_check["natural_result_seen"] = True
                tap(360, 727)  # One more go on the two-button result sheet.
                time.sleep(0.6)
            back()
            screenshot(f"{index + 1:02d}-{game}-after-back")
            paused = saved_state()["sessions"].get(game)
            time.sleep(0.8)
            if not paused or saved_state()["sessions"].get(game) != paused:
                raise RuntimeError(f"{game} did not checkpoint and freeze after system Back")
            game_check["system_back_keeps_process_and_freezes_round"] = True
            tap(360, 679)  # Keep playing on the three-button pause sheet.
            screenshot(f"{index + 1:02d}-{game}-resumed")
            shell("input", "keyevent", "KEYCODE_HOME")
            time.sleep(1)
            background = saved_state()["sessions"].get(game)
            (output / f"{index + 1:02d}-{game}-background-save.json").write_text(json.dumps(background, indent=2), encoding="utf-8")
            launch()  # Bring the existing activity back; it must show a pause.
            returned_frame = screenshot(f"{index + 1:02d}-{game}-background-return")
            returned = saved_state()["sessions"].get(game)
            (output / f"{index + 1:02d}-{game}-returned-save.json").write_text(json.dumps(returned, indent=2), encoding="utf-8")
            if not background or returned != background:
                raise RuntimeError(f"{game} background and returned checkpoints differ; inspect both retained saves")
            game_check["background_freeze"] = True
            # Prove that the returned activity still accepts UI input, not just
            # that its saved state stopped changing after the surface vanished.
            tap(360, 679)
            resumed_frame = screenshot(f"{index + 1:02d}-{game}-background-resumed")
            if resumed_frame == returned_frame:
                raise RuntimeError(f"{game} foreground Resume produced no rendered transition")
            back()
            if screenshot(f"{index + 1:02d}-{game}-background-paused-again") == resumed_frame:
                raise RuntimeError(f"{game} foreground Back produced no rendered transition")
            game_check["background_render_and_input"] = True
            park()
            state = saved_state()
            (output / f"{index + 1:02d}-{game}-save.json").write_text(json.dumps(state, indent=2), encoding="utf-8")
            launch()
            open_card(index)
            back()
            restored = saved_state()["sessions"].get(game, {})
            if restored.get("seed") != background.get("seed") or restored.get("score", -1) < background["score"]:
                raise RuntimeError(f"{game} lost its round across force-stop and reopen")
            screenshot(f"{index + 1:02d}-{game}-restored")
            game_check["round_restored_after_force_stop"] = True
            tap(360, 775)  # Start again from the actual pause sheet.
            back()
            fresh = saved_state()["sessions"].get(game, {})
            if fresh.get("score") != 0:
                raise RuntimeError(f"{game} did not restart with zero score")
            screenshot(f"{index + 1:02d}-{game}-restarted")
            game_check["restart_zero_score"] = True
            print(json.dumps({"game": game, "checks": game_check}), flush=True)
            tap(360, 871)  # Back to my pocket from pause.
            park()
        launch()
        tap(650, 70)
        tap(608, 360)  # Music off.
        tap(608, 466)  # SFX off.
        tap(608, 572)  # Reduced motion on.
        tap(608, 678)  # Haptics off.
        tap(360, 810)  # Chinese.
        screenshot("09-settings-zh")
        park()
        launch()
        screenshot("10-restarted-home-zh")
        tap(650, 70)
        screenshot("11-restarted-settings-zh")
        state = saved_state()
        expected_settings = {"music": False, "sfx": False, "reduced_motion": True, "haptics": False, "language": "zh"}
        if state["settings"] != expected_settings:
            raise RuntimeError("Settings did not survive background + force-stop + launch")
        if set(GAMES) - set(state["seen"]):
            raise RuntimeError("Not all eight games were actually entered")
        report["seen_games"] = list(state["seen"])
        report["records"] = state["records"]
        report["settings_persisted"] = True
        tap(360, 1030)
        screenshot("12-offline-licenses-zh")
        back()
        screenshot("13-license-back-to-settings")
        park()
        report["reinstall"] = install_apk()
        launch()
        if saved_state() != state:
            raise RuntimeError("Same-signature reinstall did not preserve app data")
        report["same_signature_reinstall_preserves_save"] = True
        screenshot("14-reinstalled-home-zh")
        (output / "meminfo.txt").write_text(shell("dumpsys", "meminfo", package), encoding="utf-8")
        logs = adb("logcat", "-d", "-v", "threadtime")
        (output / "logcat.txt").write_text(logs, encoding="utf-8")
        errors = runtime_errors(logs)
        report["runtime_errors"] = errors
        report["graphics_swap_warnings"] = [line for line in logs.splitlines() if "eglSwapBuffers failed" in line]
        if errors:
            raise RuntimeError("Android runtime errors were recorded")
        if report.get("launcher_error"):
            raise RuntimeError(report["launcher_error"])
        report["status"] = "PASS_SMOKE_AWAITING_VISUAL_REVIEW"
    except Exception as error:
        report["error"] = str(error)
        try:
            screenshot("failure-screen", allow_blank=True)
            try:
                (output / "failure-save.json").write_text(json.dumps(saved_state(), indent=2), encoding="utf-8")
            except Exception as save_error:
                report["failure_save_error"] = str(save_error)
            if "background-return is blank" in str(error):
                # Diagnostics cannot turn the original failed return into PASS.
                # Observe without input first, then test a new surface lifecycle
                # while retaining PID continuity and every adverse frame.
                diagnostic = report["surface_failure_diagnostic"] = {}
                try:
                    diagnostic["pid_before"] = shell("pidof", package, check=False)
                    time.sleep(5)
                    screenshot("diagnostic-delayed-return", allow_blank=True)
                    diagnostic["visible_after_extra_5_seconds"] = report["frame_checks"]["diagnostic-delayed-return"]["has_visible_content"]
                    (output / "failure-surface-layers.txt").write_text(shell("dumpsys", "SurfaceFlinger", "--list"), encoding="utf-8")
                    shell("input", "keyevent", "KEYCODE_HOME")
                    time.sleep(5)
                    launch()
                    screenshot("diagnostic-new-surface-return", allow_blank=True)
                    diagnostic["visible_after_new_surface_cycle"] = report["frame_checks"]["diagnostic-new-surface-return"]["has_visible_content"]
                    diagnostic["same_process"] = diagnostic["pid_before"] == shell("pidof", package, check=False)
                except Exception as diagnostic_error:
                    diagnostic["error"] = str(diagnostic_error)
            logs = adb("logcat", "-d", "-v", "threadtime")
            (output / "logcat.txt").write_text(logs, encoding="utf-8")
            report["runtime_errors"] = runtime_errors(logs)
            report["graphics_swap_warnings"] = [line for line in logs.splitlines() if "eglSwapBuffers failed" in line]
        except Exception as capture_error:
            report["capture_error"] = str(capture_error)
    finally:
        (output / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        summary = {key: value for key, value in report.items() if key != "commands"}
        print(json.dumps(summary, indent=2))
    return 0 if report["status"].startswith("PASS") else 1


if __name__ == "__main__":
    raise SystemExit(main())
