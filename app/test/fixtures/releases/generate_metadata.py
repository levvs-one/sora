"""Regenerate public cross-language fixtures; the temporary private key is deleted."""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

REPO = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(REPO / "packaging/install"))
from release_manifest import write_release_manifest


def generate():
    with tempfile.TemporaryDirectory(prefix="sora-update-metadata-key-") as temporary:
        root = Path(temporary)
        signer = root / ("sora-ext.exe" if os.name == "nt" else "sora-ext")
        subprocess.run(["go", "build", "-buildvcs=false", "-o", str(signer), "./cmd/sora-ext"],
                       cwd=REPO / "tools/sora-ext", env={**os.environ, "CGO_ENABLED": "0"}, check=True)
        key = root / "ephemeral"
        subprocess.run([str(signer), "keygen", "-o", str(key)], check=True, stdout=subprocess.DEVNULL)
        result = {"public_key": key.with_suffix(".pub").read_text().splitlines()[-1], "releases": {}, "cases": {}, "flows": {}}

        def signed(metadata, version, duplicate=False, package_hashes=None, role=None):
            document = json.loads(metadata)
            hashes = dict(package_hashes) if package_hashes is not None else {
                entry["name"]: entry["sha256"] for entry in document["artifacts"]}
            hashes["release.json"] = hashlib.sha256(metadata.encode("ascii")).hexdigest()
            manifest = "".join(f"{hashes[name]}  {name}\n" for name in sorted(hashes))
            if duplicate:
                manifest += f"{hashes['release.json']}  release.json\n"
            payload = root / "SHA256SUMS"
            payload.write_bytes(manifest.encode("ascii"))
            subprocess.run([str(signer), "sign-file", "--key", str(key.with_suffix(".key")),
                            "--role", role or f"release:v{version}:SHA256SUMS", str(payload)],
                           check=True, stdout=subprocess.DEVNULL)
            return {"metadata": metadata, "manifest": manifest, "signature": payload.with_suffix(".minisig").read_text()}

        for version in ("1.0.4", "1.0.5"):
            distribution = root / version
            distribution.mkdir()
            names = [f"Sora-Setup-{version}-x64.exe", "install.sh", "install.ps1"]
            for arch, machine in (("amd64", "x86_64"), ("arm64", "aarch64")):
                for package in ("sora-core", "sora"):
                    names += [f"{package}_{version}_{arch}.deb", f"{package}-{version}-1.{machine}.rpm",
                              f"{package}-{version}-1-{machine}.pkg.tar.zst"]
            for name in names:
                (distribution / name).write_bytes(b"abc")
            write_release_manifest(distribution, version)
            result["releases"][version] = signed((distribution / "release.json").read_text(), version)
            result["flows"][version] = {}
            for package_format in ("deb", "rpm", "arch", "windows"):
                flow = root / f"flow-{version}-{package_format}"
                flow.mkdir()
                names = [f"Sora-Setup-{version}-x64.exe"] if package_format == "windows" else [
                    f"{package}_{version}_amd64.deb" if package_format == "deb" else
                    f"{package}-{version}-1.x86_64.rpm" if package_format == "rpm" else
                    f"{package}-{version}-1-x86_64.pkg.tar.zst" for package in ("sora-core", "sora")]
                for name in names:
                    prefix = "Old" if version == "1.0.4" else "Test"
                    (flow / name).write_bytes(f"{prefix} bytes for {name}".encode("ascii"))
                write_release_manifest(flow, version)
                metadata = (flow / "release.json").read_text()
                record = signed(metadata, version)
                record["wrong-version-signature"] = signed(metadata, version, role="release:v0.0.0:SHA256SUMS")["signature"]
                record["catalog-signature"] = signed(metadata, version, role="catalog.json")["signature"]
                result["flows"][version][package_format] = record
        base = result["releases"]["1.0.5"]["metadata"]
        previous = json.loads(base)
        previous["artifacts"] = [entry for entry in previous["artifacts"]
                                 if entry["arch"] != "arm64" or entry["name"].startswith("sora-core")]
        result["cases"]["previous-matrix"] = signed(
            json.dumps(previous, ensure_ascii=True, separators=(",", ":"), allow_nan=False) + "\n", "1.0.5")
        for case in ("os", "arch", "zero-size", "oversize", "float-size", "wrong-size", "hash-case",
                     "version", "schema", "empty", "order", "unknown", "duplicate-key", "whitespace", "duplicate-checksum"):
            document = json.loads(base)
            entry = document["artifacts"][0]
            if case == "os":
                entry["os"] = "linux"
            elif case == "arch":
                entry["arch"] = "arm64"
            elif case == "zero-size":
                entry["size"] = 0
            elif case == "oversize":
                entry["size"] = 2 * 1024 * 1024 * 1024 + 1
            elif case == "float-size":
                entry["size"] = 3.0
            elif case == "wrong-size":
                for artifact in document["artifacts"]:
                    artifact["size"] = 4
            elif case == "hash-case":
                entry["sha256"] = entry["sha256"].upper()
            elif case == "version":
                document["version"] = "1.0.6"
            elif case == "schema":
                document["schema"] = 2
            elif case == "empty":
                document["artifacts"] = []
            elif case == "order":
                document["artifacts"].reverse()
            elif case == "unknown":
                document["extra"] = True
            metadata = json.dumps(document, ensure_ascii=True, separators=(",", ":"), allow_nan=False) + "\n"
            if case == "duplicate-key":
                metadata = metadata.replace('"schema":1', '"schema":1,"schema":1')
            elif case == "whitespace":
                metadata += " "
            package_hashes = {entry["name"]: entry["sha256"] for entry in json.loads(base)["artifacts"]}
            result["cases"][case] = signed(metadata, "1.0.5", case == "duplicate-checksum", package_hashes)
        Path(__file__).with_name("metadata.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print("Public fixtures generated; temporary private key deleted")


if __name__ == "__main__":
    generate()
