"""Read-only, redacted known-secret scan of reachable Git history and current files.

This is a bounded credential-pattern check, not a guarantee against unknown secrets.
Binary blobs and text above 2 MB are counted separately, never dumped to the log.
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess


PATTERNS = {
    "private_key": re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
    "github_token": re.compile(rb"(?:gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{70,})"),
    "aws_access_key": re.compile(rb"(?:AKIA|ASIA)[A-Z0-9]{16}"),
    "google_api_key": re.compile(rb"AIza[A-Za-z0-9_-]{35}"),
    "openai_key": re.compile(rb"sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{40,}"),
}
KEY_EXTENSIONS = {".jks", ".p12", ".keystore", ".pem", ".key"}


def git(*args):
    return subprocess.check_output(["git", *args])


def main():
    findings = []
    counts = {"history_text_blobs": 0, "history_binary_or_large": 0, "working_text_files": 0}

    def scan(data, source):
        if len(data) > 2_000_000 or b"\0" in data[:8192]:
            return False
        for name, pattern in PATTERNS.items():
            if pattern.search(data):
                findings.append({"source": source, "pattern": name, "value": "REDACTED"})
        return True

    entries = git("rev-list", "--objects", "--all").decode().splitlines()
    objects = [line.split(" ", 1)[0] for line in entries]
    names = {line.split(" ", 1)[0]: line.split(" ", 1)[-1] for line in entries}
    metadata = subprocess.check_output(["git", "cat-file", "--batch-check"], input=("\n".join(objects) + "\n").encode()).decode().splitlines()
    for record in metadata:
        oid, kind, size = record.split()
        if kind != "blob":
            continue
        name = names[oid]
        if Path(name).suffix.lower() in KEY_EXTENSIONS or Path(name).name in (".env", "export_credentials.cfg"):
            findings.append({"source": f"history:{oid[:12]}:{name}", "pattern": "credential_file", "value": "REDACTED"})
        if int(size) > 2_000_000:
            counts["history_binary_or_large"] += 1
            continue
        data = git("cat-file", "blob", oid)
        counts["history_text_blobs" if scan(data, f"history:{oid[:12]}:{name}") else "history_binary_or_large"] += 1
    files = git("ls-files", "-z", "--cached", "--others", "--exclude-standard").decode().split("\0")
    for name in filter(None, files):
        path = Path(name)
        if path.is_file() and scan(path.read_bytes(), "working:" + name):
            counts["working_text_files"] += 1
    runtime_network = []
    for path in Path("scripts").rglob("*.gd"):
        if re.search(r"\b(?:HTTPRequest|HTTPClient|WebSocketPeer|TCPServer|PacketPeerUDP)\b|\bOS\.(?:execute|create_process)\b", path.read_text(encoding="utf-8")):
            runtime_network.append(str(path))
    report = {"status": "PASS_BOUNDED_STATIC_AUDIT" if not findings and not runtime_network else "REVIEW_REQUIRED",
              "commit": git("rev-parse", "HEAD").decode().strip(),
              "commits_scanned": int(git("rev-list", "--all", "--count")),
              "counts": counts, "findings": findings, "runtime_network_or_process_calls": runtime_network,
              "fonts": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in Path("assets/fonts").glob("*-OFL.txt")},
              "limitations": ["Known credential patterns only; not entropy or exhaustive secret detection", "Large/binary blobs excluded from textual scan", "AI provenance is recorded, not a trademark or exclusivity guarantee", "Final APK permission/signature checks are separate"]}
    Path("docs/evidence/security-audit.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if report["status"] == "PASS_BOUNDED_STATIC_AUDIT" else 1


if __name__ == "__main__":
    raise SystemExit(main())
