"""Fetch original-signed APK bytes from an owner-authorized unpublished draft.

No signing key is uploaded or used by this workflow. The expected SHA is explicit
workflow input; GitHub authentication is used only by gh, never printed.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import urllib.request

REPOSITORY = "seiya058904/mochi-arcade"
CERTIFICATE = "de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b"
OLD_SHA = "8fcc1ebc83cb9cb8e8947a1a33bef9cba9222b9ac775fafdcd7d3d5cd85d473c"


def verify(path, expected, version, code):
    assert hashlib.sha256(path.read_bytes()).hexdigest() == expected, "APK checksum mismatch"
    build = Path(os.environ["ANDROID_HOME"]) / "build-tools/36.0.0"
    signature = subprocess.check_output([str(build / "apksigner"), "verify", "--verbose", "--print-certs", str(path)], text=True)
    assert CERTIFICATE in signature.lower(), "Unexpected release certificate"
    assert "Verified using v2 scheme (APK Signature Scheme v2): true" in signature
    assert "Verified using v3 scheme (APK Signature Scheme v3): true" in signature
    manifest = subprocess.check_output([str(build / "aapt2"), "dump", "badging", str(path)], text=True)
    assert "name='io.github.seiya058904.mochiarcade'" in manifest
    assert f"versionCode='{code}'" in manifest and f"versionName='{version}'" in manifest
    assert "application-debuggable" not in manifest
    assert set(re.findall(r"uses-permission: name='([^']+)'", manifest)) == {"android.permission.VIBRATE"}
    return {"sha256": expected, "bytes": path.stat().st_size, "certificate_sha256": CERTIFICATE,
            "version_name": version, "version_code": code, "debuggable": False}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--release-id", type=int, required=True)
    parser.add_argument("--sha256", required=True)
    args = parser.parse_args()
    assert args.release_id > 0 and re.fullmatch(r"[0-9a-f]{64}", args.sha256)
    metadata = json.loads(subprocess.check_output(["gh", "api", f"repos/{REPOSITORY}/releases/{args.release_id}"], text=True))
    assert metadata["draft"] and metadata["tag_name"] == "v1.1.0", "Only the authorized unpublished 1.1.0 draft is accepted"
    assets = {item["name"]: item for item in metadata["assets"]}
    Path("dist").mkdir(exist_ok=True)
    for name in ["MochiArcade.apk", "SHA256SUMS"]:
        with (Path("dist") / name).open("wb") as dest:
            subprocess.run(["gh", "api", "-H", "Accept: application/octet-stream",
                            f"repos/{REPOSITORY}/releases/assets/{assets[name]['id']}"], stdout=dest, check=True)
    assert Path("dist/SHA256SUMS").read_text().strip() == f"{args.sha256}  MochiArcade.apk"
    # Published predecessor is deliberately downloaded without any credential.
    old = Path("dist/MochiArcade-v1.0.0.apk")
    with urllib.request.urlopen(f"https://github.com/{REPOSITORY}/releases/download/v1.0.0/MochiArcade.apk", timeout=120) as response:
        old.write_bytes(response.read())
    report = {"status": "PASS_BYTE_IDENTITY", "release_id": args.release_id,
              "candidate": verify(Path("dist/MochiArcade.apk"), args.sha256, "1.1.0", 2),
              "predecessor": verify(old, OLD_SHA, "1.0.0", 1),
              "scope": "Downloaded pre-signed APKs; no private key or password in this job"}
    Path(".local/android-runtime").mkdir(parents=True, exist_ok=True)
    Path(".local/android-runtime/staged-byte-identity.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
