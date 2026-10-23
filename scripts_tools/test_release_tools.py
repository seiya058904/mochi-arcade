"""Behavioral rejection tests for untrusted transport and semantic regressions."""
import copy
import json
import hashlib
import os
from pathlib import Path
import unittest
from unittest.mock import patch

from release_identity import identity, draft_metadata, build_inputs
from fetch_staged_release import verify
from upgrade_semantics import restored


class ReleaseTools(unittest.TestCase):
    def test_export_matches_config(self):
        config = identity()["candidate"]
        text = Path("export_presets.cfg").read_text(encoding="utf-8")
        self.assertIn(f'version/code={config["code"]}\n', text)
        self.assertIn(f'version/name="{config["version"]}"', text)
        self.assertIn(f'config/version="{config["version"]}"', Path("project.godot").read_text(encoding="utf-8"))

    def test_transport_rejects_wrong_identity(self):
        repo = identity()["repository"]
        source = "1" * 40
        metadata = {"url": f"https://api.github.com/repos/{repo}/releases/123", "id": 123,
                    "draft": True, "prerelease": False, "tag_name": "v1.1.1", "target_commitish": source,
                    "assets": [{"name": name, "id": i, "url": f"https://api.github.com/repos/{repo}/releases/assets/{i}"}
                               for i, name in enumerate(["MochiArcade.apk", "SHA256SUMS"], 1)]}
        self.assertEqual(len(draft_metadata(metadata, 123, source)), 2)
        for key, value in [("url", "https://api.github.com/repos/attacker/fake/releases/123"),
                           ("id", 321), ("draft", False), ("prerelease", True), ("tag_name", "v1.1.0"),
                           ("target_commitish", "main")]:
            with self.subTest(key=key):
                bad = copy.deepcopy(metadata)
                bad[key] = value
                with self.assertRaises(AssertionError):
                    draft_metadata(bad, 123, source)
        for field, value in [("name", "wrong.apk"), ("url", "https://evil.example/asset"), ("id", "1; echo unsafe")]:
            bad = copy.deepcopy(metadata)
            bad["assets"][0][field] = value
            with self.assertRaises(AssertionError):
                draft_metadata(bad, 123, source)
        for checksum, sha in [("x" * 64, source), ("0" * 64, "main"), ("0" * 64, "1" * 40 + "; command")]:
            with self.assertRaises(AssertionError):
                build_inputs(checksum, sha)

    def test_apk_rejects_bad_hash_before_tools(self):
        with patch.object(Path, "read_bytes", return_value=b"bad bytes"):
            with self.assertRaisesRegex(AssertionError, "checksum"):
                verify(Path("untrusted.apk"), "0" * 64, "1.1.1", 3)

    def test_apk_rejects_wrong_certificate_manifest_and_abi(self):
        signature = f"{identity()['certificate_sha256']}\nVerified using v2 scheme (APK Signature Scheme v2): true\nVerified using v3 scheme (APK Signature Scheme v3): true"
        manifest = "package: name='io.github.seiya058904.mochiarcade' versionCode='3' versionName='1.1.1'\nuses-permission: name='android.permission.VIBRATE'\nnative-code: 'arm64-v8a' 'x86_64'\n"
        digest = hashlib.sha256(b"fixture").hexdigest()
        for sig, text in [("wrong certificate", manifest),
                          (signature, manifest.replace("versionCode='3'", "versionCode='2'")),
                          (signature, manifest.replace("versionName='1.1.1'", "versionName='1.1.0'")),
                          (signature, manifest.replace("io.github.seiya058904.mochiarcade", "wrong.package")),
                          (signature, manifest + "application-debuggable\n"),
                          (signature, manifest.replace(" 'x86_64'", "")),
                          (signature, manifest + "uses-permission: name='android.permission.INTERNET'\n")]:
            with patch.object(Path, "read_bytes", return_value=b"fixture"), patch.dict(os.environ, {"ANDROID_HOME": "/sdk"}), patch("subprocess.check_output", side_effect=[sig, text]):
                with self.assertRaises(AssertionError):
                    verify(Path("fixture.apk"), digest, "1.1.1", 3)

    def test_real_restore_probe(self):
        prior = json.loads(Path("tests/integration/fixtures/upgrade-v1.0.0.json").read_text())["save"]["sessions"]
        observed = json.loads(Path(".local/iteration-1.1.1/upgrade-restore.json").read_text())
        for game in prior:
            with self.subTest(game=game):
                restored(game, prior[game], observed[game])

    def test_semantics_reject_every_persistent_field_loss(self):
        fixture = json.loads(Path("tests/integration/fixtures/upgrade-v1.0.0.json").read_text())
        for game, before in fixture["save"]["sessions"].items():
            # All top-level field losses must fail, including board/fruit/history/RNG.
            for field in before:
                bad = copy.deepcopy(before)
                del bad[field]
                with self.subTest(game=game, field=field), self.assertRaises((AssertionError, KeyError)):
                    restored(game, before, bad)


if __name__ == "__main__":
    unittest.main()
