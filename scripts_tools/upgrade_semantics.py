"""Compare all persistent game fields at first-help freeze, before simulation.

Only the existing restore normalizations below are allowed. Numeric tolerance is
for Godot Vector2 float32 round trips, not elapsed simulation or lost objects.
"""
import copy
import math


def compare(expected, observed, path="state"):
    if isinstance(expected, dict):
        assert isinstance(observed, dict) and set(expected) == set(observed), f"{path}: keys differ"
        for key in expected:
            compare(expected[key], observed[key], f"{path}.{key}")
    elif isinstance(expected, list):
        assert isinstance(observed, list) and len(expected) == len(observed), f"{path}: length differs"
        for index, (a, b) in enumerate(zip(expected, observed)):
            compare(a, b, f"{path}[{index}]")
    elif isinstance(expected, bool) or isinstance(expected, str):
        assert expected == observed, f"{path}: {observed!r} != {expected!r}"
    elif isinstance(expected, (int, float)):
        assert isinstance(observed, (int, float)) and math.isfinite(observed)
        assert math.isclose(expected, observed, rel_tol=0, abs_tol=0.001), f"{path}: {observed} != {expected}"
    else:
        assert expected == observed, path


def restored(game, prior, observed, area=(648, 894)):
    expected = copy.deepcopy(prior)
    notes = []
    if game == "fruit_drop":
        radii = [22, 29, 37, 47, 59, 73, 90, 109]
        for fruit in expected["fruit"]:
            radius = radii[int(fruit["level"])]
            fruit["x"] = min(max(fruit["x"], 20 + radius), area[0] - 20 - radius)
            fruit["y"] = min(fruit["y"], area[1] - 60 - radius)
        notes.append("Spawn clamps each restored circle to jar bounds; level/count/velocity/angle/next/RNG/score retained")
    elif game == "bubble_garden":
        expected["grid"].sort()
        observed = copy.deepcopy(observed)
        observed["grid"].sort()
    elif game == "bouncy_balls":
        assert prior["area"] == list(area), "This same-resolution acceptance forbids untested aspect-ratio recall"
        speed = min(540, 400 + (prior["wave"] - 1) * 14)
        for ball in expected["balls"]:
            ball[0] = min(max(ball[0] * area[0], 34), area[0] - 34) / area[0]
            ball[1] = max(73, ball[1] * area[1]) / area[1]
            length = math.hypot(ball[2], ball[3])
            assert length > 0.001
            ball[2], ball[3] = ball[2] / length * speed, ball[3] / length * speed
            if abs(ball[3]) < speed * 0.26:
                ball[3] = speed * 0.26 * (-1 if ball[3] <= 0 else 1)
                ball[2] = math.sqrt(speed**2 - ball[3]**2) * (-1 if ball[2] < 0 else 1)
        expected["clear"] = min(max(prior["clear"], 0), 0.65)
        if not any(prior["health"]):
            expected["clear"] = max(0.01, expected["clear"])
        notes.append("Same-area survivor positions bounded and velocities normalized by existing safe_velocity; all gate bits/health/wave/paddle/clear retained")
    elif game == "mochi_hop":
        current = expected["current"]
        if math.dist(expected["foot"], current["center"]) > current["radius"]:
            expected["foot"] = current["center"][:]
        distance = math.dist(expected["foot"], expected["target"]["center"])
        assert max(70, distance - expected["target"]["radius"] - 6) <= min(350, distance + expected["target"]["radius"] + 6), "Restored next Hop target unreachable"
        notes.append("Restart returns to READY, clamps unsafe foot to current center; target/RNG/landed/combo/score retained and charge interval nonempty")
    elif game == "jelly_slice":
        expected["spawn_time"] = min(max(expected["spawn_time"], 0.05), 1.35)
        expected["launched"] = max(expected["launched"], expected["sliced"] + expected["missed"] + len(expected["fruit"]))
        for fruit in expected["fruit"]:
            fruit[3] = min(max(fruit[3], -500), 500)
            fruit[4] = min(max(fruit[4], -1400), 1400)
        notes.append("Existing spawn timer/velocity bounds; combo and held finger intentionally absent from save and reset; all persistent fruit/RNG/counters retained")
    compare(expected, observed, game)
    return {"fields": sorted(expected), "normalizations": notes, "expected": expected, "observed": observed, "status": "PASS"}
