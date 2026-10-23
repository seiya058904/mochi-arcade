"""Execute required Godot checks; script errors also fail even if exit code is zero."""
import argparse
import json
import re
from pathlib import Path
import subprocess
import time
import sys

SUITES = [
    ("tests/logic/run_tests.gd", False),
    ("tests/logic/hop_reachability.gd", False),
    ("tests/logic/trio_solver.gd", False),
    ("tests/integration/vertical_slices.gd", False),
    ("tests/integration/vertical_playthrough.gd", True),
    ("tests/integration/fruit_drop.gd", False),
    ("tests/integration/bubble_garden.gd", True),
    ("tests/integration/bubble_playthrough.gd", True),
    ("tests/integration/mochi_hop.gd", False),
    ("tests/integration/hop_playthrough.gd", True),
    ("tests/integration/tile_trio.gd", False),
    ("tests/integration/trio_playthrough.gd", True),
    ("tests/integration/bouncy_balls.gd", False),
    ("tests/integration/balls_playthrough.gd", True),
    ("tests/integration/jelly_slice.gd", False),
    ("tests/integration/jelly_playthrough.gd", True),
    ("tests/integration/fruit_playthrough.gd", True),
    ("tests/integration/collection_audit.gd", True),
    ("tests/integration/reliability.gd", False),
    ("tests/integration/patch_reliability.gd", False),
    ("tests/integration/upgrade_restore.gd", False),
    ("scripts_tools/test_release_tools.py", False),
    ("scripts_tools/test_android_restore.py", False),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--engine", required=True)
    args = parser.parse_args()
    logs = Path(".local/check-logs")
    logs.mkdir(parents=True, exist_ok=True)
    reports = []
    for script, fixed in SUITES:
        command = [args.engine, "--headless", "--path", "."]
        if fixed:
            command += ["--fixed-fps", "60"]
        command += ["--script", script]
        if script.endswith(".py"):
            command = [sys.executable, script]
        start = time.monotonic()
        result = subprocess.run(command, capture_output=True, encoding="utf-8", errors="replace", timeout=180)
        combined = result.stdout + result.stderr
        (logs / (Path(script).stem + ".log")).write_text(combined, encoding="utf-8")
        errors = re.findall(r"^(?:SCRIPT ERROR:|ERROR:).*$", combined, flags=re.MULTILINE)
        status = "PASS" if result.returncode == 0 and not errors else "FAIL"
        report = {"script": script, "status": status, "exit_code": result.returncode,
                  "runtime_errors": errors, "seconds": round(time.monotonic() - start, 3)}
        reports.append(report)
        print(json.dumps(report), flush=True)
        if status == "FAIL":
            print(combined[-6000:], flush=True)
            break
    summary = {"status": "PASS" if len(reports) == len(SUITES) and all(r["status"] == "PASS" for r in reports) else "FAIL",
               "suite_count": len(SUITES), "executed": len(reports), "results": reports}
    Path("docs/evidence/required-checks.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    return 0 if summary["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
