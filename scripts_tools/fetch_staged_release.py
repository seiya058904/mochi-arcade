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
from release_identity import identity, build_inputs, draft_metadata

CONFIG = identity()
REPOSITORY = CONFIG["repository"]
CERTIFICATE = CONFIG["certificate_sha256"]


def verify(path, expected, version, code):
    assert hashlib.sha256(path.read_bytes()).hexdigest() == expected, "APK checksum mismatch"
    build = Path(os.environ["ANDROID_HOME"]) / "build-tools/36.0.0"
    signature = subprocess.check_output([str(build / ("apksigner.bat" if os.name == "nt" else "apksigner")), "verify", "--verbose", "--print-certs", str(path)], text=True)
    assert CERTIFICATE in signature.lower(), "Unexpected release certificate"
    assert "Verified using v2 scheme (APK Signature Scheme v2): true" in signature
    assert "Verified using v3 scheme (APK Signature Scheme v3): true" in signature
    manifest = subprocess.check_output([str(build / ("aapt2.exe" if os.name == "nt" else "aapt2")), "dump", "badging", str(path)], text=True)
    assert f"name='{CONFIG['package']}'" in manifest.splitlines()[0]
    assert f"versionCode='{code}'" in manifest and f"versionName='{version}'" in manifest
    assert "application-debuggable" not in manifest
    assert set(re.findall(r"uses-permission: name='([^']+)'", manifest)) == {"android.permission.VIBRATE"}
    abi = re.search(r"^native-code: (.+)$", manifest, re.MULTILINE)
    assert abi and set(re.findall(r"'([^']+)'", abi.group(1))) == {"arm64-v8a", "x86_64"}
    subprocess.run([str(build / ("zipalign.exe" if os.name == "nt" else "zipalign")), "-c", "-P", "16", "4", str(path)], check=True, capture_output=True)
    return {"sha256": expected, "bytes": path.stat().st_size, "certificate_sha256": CERTIFICATE,
            "version_name": version, "version_code": code, "debuggable": False}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--release-id", type=int, required=True)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--source", required=True)
    parser.add_argument("--predecessor", choices=CONFIG["predecessors"], default="v1.1.0")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--download-only", action="store_true")
    mode.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    assert args.release_id > 0
    build_inputs(args.sha256, args.source)
    Path("dist").mkdir(exist_ok=True)
    metadata = (json.loads(Path("dist/staged-release.json").read_text()) if args.verify_only else
                json.loads(subprocess.check_output(["gh", "api", f"repos/{REPOSITORY}/releases/{args.release_id}"], text=True)))
    assets = draft_metadata(metadata, args.release_id, args.source)
    if not args.verify_only:
        for name in ["MochiArcade.apk", "SHA256SUMS"]:
            with (Path("dist") / name).open("wb") as dest:
                subprocess.run(["gh", "api", "-H", "Accept: application/octet-stream",
                                f"repos/{REPOSITORY}/releases/assets/{assets[name]['id']}"], stdout=dest, check=True)
        Path("dist/staged-release.json").write_text(json.dumps(metadata, indent=2) + "\n")
    assert Path("dist/SHA256SUMS").read_text().strip() == f"{args.sha256}  MochiArcade.apk"
    assert hashlib.sha256(Path("dist/MochiArcade.apk").read_bytes()).hexdigest() == args.sha256
    if args.download_only:
        print("Downloaded checksum-pinned draft APK; signature verification belongs to the read-only test job")
        return
    # Published predecessor is deliberately downloaded without any credential.
    predecessor = CONFIG["predecessors"][args.predecessor]
    candidate = CONFIG["candidate"]
    old = Path("dist/MochiArcade-predecessor.apk")
    with urllib.request.urlopen(f"https://github.com/{REPOSITORY}/releases/download/{args.predecessor}/{predecessor['asset']}", timeout=120) as response:
        old.write_bytes(response.read())
    report = {"status": "PASS_BYTE_IDENTITY", "release_id": args.release_id,
              "build_source": args.source, "predecessor_tag": args.predecessor,
              "candidate": verify(Path("dist/MochiArcade.apk"), args.sha256, candidate["version"], candidate["code"]),
              "predecessor": verify(old, predecessor["sha256"], predecessor["version"], predecessor["code"]),
              "scope": "Downloaded pre-signed APKs; no private key or password in this job"}
    Path(".local/android-runtime").mkdir(parents=True, exist_ok=True)
    Path(".local/android-runtime/staged-byte-identity.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
