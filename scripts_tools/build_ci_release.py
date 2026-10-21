"""Build with an explicitly authorized CI signing identity, never log private data.

Used only by a manually dispatched release-candidate run. The decoded keystore is
created exclusively in RUNNER_TEMP and removed in finally before artifact upload.
"""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess

CERTIFICATE_SHA256 = "de1458f30ad0f2a758b9c6f3de82c00b608723eaa75de22d3cf853e351f7657b"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--engine", required=True)
    args = parser.parse_args()
    encoded = os.environ.get("MOCHI_RELEASE_KEYSTORE_BASE64", "")
    password = os.environ.get("MOCHI_RELEASE_PASSWORD", "")
    if not encoded or not password:
        raise RuntimeError("Authorized signing secrets are not configured")
    root = Path(os.environ["RUNNER_TEMP"]).resolve()
    project = Path.cwd().resolve()
    if root == project or project in root.parents:
        raise RuntimeError("Transient signing material must stay outside the repository")
    key_path = root / "mochi-release-signing.p12"
    if key_path.exists() or key_path.is_symlink():
        raise RuntimeError("Refusing to replace existing signing material")
    data = base64.b64decode(encoded, validate=True)
    if not 1000 < len(data) < 32000:
        raise RuntimeError("Unexpected keystore size")
    env = os.environ.copy()
    env.pop("MOCHI_RELEASE_KEYSTORE_BASE64", None)
    env.pop("MOCHI_RELEASE_PASSWORD", None)
    env.update(GODOT_ANDROID_KEYSTORE_RELEASE_PATH=str(key_path),
               GODOT_ANDROID_KEYSTORE_RELEASE_USER="mochi-arcade",
               GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=password)
    apk = Path("dist/MochiArcade.apk")
    apk.parent.mkdir(exist_ok=True)
    created = False
    try:
        descriptor = os.open(key_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        created = True
        with os.fdopen(descriptor, "wb") as output:
            output.write(data)
        subprocess.run([args.engine, "--headless", "--path", ".", "--export-release", "Android", str(apk)], env=env, check=True)
        signer = Path(os.environ["ANDROID_HOME"]) / "build-tools/36.0.0" / ("apksigner.bat" if os.name == "nt" else "apksigner")
        verification = subprocess.check_output([str(signer), "verify", "--verbose", "--print-certs", str(apk)], text=True)
        if f"certificate SHA-256 digest: {CERTIFICATE_SHA256}" not in verification:
            raise RuntimeError("Release signing identity does not match the reviewed certificate")
        Path(".local").mkdir(exist_ok=True)
        Path(".local/release-signature.txt").write_text(verification, encoding="utf-8")
        print(json.dumps({"apk": str(apk), "sha256": hashlib.sha256(apk.read_bytes()).hexdigest(), "certificate_sha256": CERTIFICATE_SHA256}))
    finally:
        if key_path.parent != root:
            raise RuntimeError("Signing path boundary changed")
        if created and key_path.is_file() and not key_path.is_symlink():
            key_path.unlink()  # Exactly the transient file created above; no recursive cleanup.
        env.pop("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD", None)


if __name__ == "__main__":
    main()
