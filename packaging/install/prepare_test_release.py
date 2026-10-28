"""Create signed CI inputs without changing the shipped core or using team keys."""

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

from release_manifest import write_release_manifest


def prepare(distribution, version, output):
    if len(version) > 64 or not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", version):
        raise ValueError("expected a stable version")
    repo = Path(__file__).resolve().parents[2]
    distribution, output = Path(distribution).resolve(), Path(output).resolve()
    if output.is_relative_to(distribution) or distribution.is_relative_to(output):
        raise ValueError("test tools and release inputs must be separate directories")
    packages = sorted(p for p in distribution.iterdir() if p.is_file() and (
        p.name.endswith((".deb", ".rpm", ".pkg.tar.zst")) or re.fullmatch(r"Sora-Setup-.+-x64\.exe", p.name)))
    if not packages:
        raise ValueError("no installer packages found")
    output.mkdir(parents=True, exist_ok=True)
    executable = "sora-verifier.exe" if os.name == "nt" else "sora-verifier"
    verifier = output / executable
    if verifier.exists():
        raise FileExistsError(verifier)
    env = {**os.environ, "CGO_ENABLED": "0"}
    with tempfile.TemporaryDirectory(prefix="sora-installer-test-key-") as temporary:
        private = Path(temporary)
        signer = private / ("sora-ext.exe" if os.name == "nt" else "sora-ext")
        subprocess.run(["go", "build", "-buildvcs=false", "-o", str(signer), "./cmd/sora-ext"], cwd=repo / "tools/sora-ext", env=env, check=True)
        key = private / "ephemeral"
        subprocess.run([str(signer), "keygen", "-o", str(key)], check=True, stdout=subprocess.DEVNULL)
        public = key.with_suffix(".pub").read_text().splitlines()[-1]
        # Cross-built native tests reuse only this public root, never the private identity.
        (output / "fixture-public-key.txt").write_text(public + "\n")
        # Only this temporary source copy trusts the ephemeral fixture identity.
        source = private / "core"
        shutil.copytree(repo / "core", source)
        release = source / "cmd/sora-core/release.go"
        text, count = re.subn(r'const releasePublicKey = "[^"]+"', f'const releasePublicKey = "{public}"', release.read_text())
        if count != 1:
            raise ValueError("test trust-root substitution did not match exactly once")
        release.write_text(text)
        subprocess.run(["go", "build", "-buildvcs=false", "-trimpath", "-ldflags=-s -w", "-o", str(verifier), "./cmd/sora-core"], cwd=source, env=env, check=True)
        sums = distribution / "SHA256SUMS"
        write_release_manifest(distribution, version)
        subprocess.run([str(signer), "sign-file", "--key", str(key.with_suffix(".key")), "--role", f"release:v{version}:SHA256SUMS", str(sums)], check=True, stdout=subprocess.DEVNULL)
        subprocess.run([str(verifier), "-verify-release", str(distribution), "-release-version", version], check=True)
        duplicate = output / "duplicate"
        duplicate.mkdir()
        duplicate_sums = duplicate / "SHA256SUMS"
        duplicate_sums.write_bytes(sums.read_bytes() * 2)
        subprocess.run([str(signer), "sign-file", "--key", str(key.with_suffix(".key")), "--role", f"release:v{version}:SHA256SUMS", str(duplicate_sums)], check=True, stdout=subprocess.DEVNULL)
        original = json.loads((distribution / "release.json").read_bytes())
        for problem in ("os", "arch", "zero-size", "wrong-size", "version", "duplicate-key", "legacy"):
            document = json.loads(json.dumps(original))
            entry = document["artifacts"][0]
            if problem == "os":
                entry["os"] = "other"
            elif problem == "arch":
                entry["arch"] = "other"
            elif problem == "zero-size":
                entry["size"] = 0
            elif problem == "wrong-size":
                for artifact in document["artifacts"]:
                    artifact["size"] += 1
            elif problem == "version":
                document["version"] = "1.2.4"
            variant = output / ("metadata-" + problem)
            variant.mkdir()
            hashes = {artifact["name"]: artifact["sha256"] for artifact in original["artifacts"]}
            if problem != "legacy":
                data = (json.dumps(document, sort_keys=True, separators=(",", ":")) + "\n").encode("ascii")
                if problem == "duplicate-key":
                    data = data.replace(b'"schema":1', b'"schema":1,"schema":1')
                (variant / "release.json").write_bytes(data)
                hashes["release.json"] = hashlib.sha256(data).hexdigest()
            payload = variant / "SHA256SUMS"
            payload.write_bytes("".join(f"{hashes[name]}  {name}\n" for name in sorted(hashes)).encode("ascii"))
            subprocess.run([str(signer), "sign-file", "--key", str(key.with_suffix(".key")), "--role", f"release:v{version}:SHA256SUMS", str(payload)], check=True, stdout=subprocess.DEVNULL)
    print(verifier)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: prepare_test_release.py DISTRIBUTION VERSION TEST_TOOLS")
    prepare(*sys.argv[1:])
