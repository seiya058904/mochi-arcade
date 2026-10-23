"""Trusted checked-in expectations; candidate bytes/source are explicit build inputs."""
import json
from pathlib import Path
import re

CONFIG = Path(__file__).resolve().parents[1] / "release_identity.json"


def identity():
    value = json.loads(CONFIG.read_text(encoding="utf-8"))
    assert value["repository"] == "seiya058904/mochi-arcade"
    assert value["package"] == "io.github.seiya058904.mochiarcade"
    assert value["certificate_sha256"] == "de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b"
    candidate = value["candidate"]
    assert re.fullmatch(r"\d+\.\d+\.\d+", candidate["version"])
    assert candidate["tag"] == "v" + candidate["version"]
    for tag, old in value["predecessors"].items():
        assert tag == "v" + old["version"] and old["asset"] == "MochiArcade.apk"
        assert re.fullmatch(r"[0-9a-f]{64}", old["sha256"])
        assert 0 < old["code"] < candidate["code"]
    return value


def build_inputs(sha256, source):
    assert re.fullmatch(r"[0-9a-f]{64}", sha256), "Expected exact APK hash"
    assert re.fullmatch(r"[0-9a-f]{40}", source), "Expected exact build source commit"


def draft_metadata(metadata, release_id, source):
    config = identity()
    repo = config["repository"]
    assert metadata["url"] == f"https://api.github.com/repos/{repo}/releases/{release_id}"
    assert metadata["id"] == release_id and metadata["draft"] and not metadata["prerelease"]
    assert metadata["tag_name"] == config["candidate"]["tag"]
    assert metadata["target_commitish"] == source, "Draft is not bound to the build source"
    assets = {item["name"]: item for item in metadata["assets"]}
    assert len(assets) == len(metadata["assets"]) and set(assets) == {"MochiArcade.apk", "SHA256SUMS"}
    for item in assets.values():
        assert isinstance(item["id"], int) and item["id"] > 0
        assert item["url"] == f"https://api.github.com/repos/{repo}/releases/assets/{item['id']}"
    return assets
