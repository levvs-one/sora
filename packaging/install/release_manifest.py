"""Build release metadata and checksums; signing remains outside the CI job."""

import hashlib
from itertools import islice
import json
import os
from pathlib import Path
import re
import stat
import sys

MAX_ARTIFACT_BYTES = 2 * 1024 * 1024 * 1024
MAX_ARTIFACTS = 128
OUTPUT_NAMES = ("release.json", "SHA256SUMS", "SHA256SUMS.minisig")


def artifact_platform(name, version):
    if name == f"Sora-Setup-{version}-x64.exe":
        return "windows", "amd64"
    if name in ("install.ps1", "install.sh"):
        return ("windows" if name.endswith(".ps1") else "linux"), "any"
    for architecture, rpm_arch in (("amd64", "x86_64"), ("arm64", "aarch64")):
        for package in ("sora-core", "sora"):
            if package == "sora" and architecture == "arm64":
                continue
            if name in (f"{package}_{version}_{architecture}.deb",
                        f"{package}-{version}-1.{rpm_arch}.rpm",
                        f"{package}-{version}-1-{rpm_arch}.pkg.tar.zst"):
                return "linux", architecture
    raise ValueError(f"unrecognized artifact or mismatched version: {name}")


def file_identity(info):
    # Windows stat/fstat can disagree on the deprecated creation-time field.
    return info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, (None if os.name == "nt" else info.st_ctime_ns)


def write_release_manifest(directory, version):
    if len(version) > 64 or not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", version):
        raise ValueError("expected a stable three-component version")
    directory = Path(directory).resolve(strict=True)
    for name in OUTPUT_NAMES:
        target = directory / name
        if target.exists() or target.is_symlink():
            raise FileExistsError(f"refusing to replace existing release metadata: {name}")
    with os.scandir(directory) as entries:
        paths = [Path(entry.path) for entry in islice(entries, MAX_ARTIFACTS + 1)]
    if not 1 <= len(paths) <= MAX_ARTIFACTS:
        raise ValueError("expected between 1 and 128 release artifacts")
    paths.sort(key=lambda path: path.name)
    artifacts = []
    for path in paths:
        before = path.lstat()
        if not stat.S_ISREG(before.st_mode):
            raise ValueError(f"artifact must be a regular file: {path.name}")
        operating_system, architecture = artifact_platform(path.name, version)
        if not 1 <= before.st_size <= MAX_ARTIFACT_BYTES:
            raise ValueError(f"artifact size is outside the allowed range: {path.name}")
        with path.open("rb") as stream:
            if file_identity(os.fstat(stream.fileno())) != file_identity(before):
                raise ValueError(f"artifact changed before hashing: {path.name}")
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
            if file_identity(os.fstat(stream.fileno())) != file_identity(before):
                raise ValueError(f"artifact changed during hashing: {path.name}")
        if file_identity(path.lstat()) != file_identity(before):
            raise ValueError(f"artifact changed after hashing: {path.name}")
        artifacts.append({"name": path.name, "os": operating_system, "arch": architecture,
                          "size": before.st_size, "sha256": digest})
    # Compact, sorted ASCII JSON has one reproducible representation for review.
    payload = (json.dumps({"schema": 1, "version": version, "artifacts": artifacts},
                          ensure_ascii=True, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n").encode("ascii")
    checksums = {entry["name"]: entry["sha256"] for entry in artifacts}
    checksums["release.json"] = hashlib.sha256(payload).hexdigest()
    checksum_text = "".join(f"{checksums[name]}  {name}\n" for name in sorted(checksums))
    with (directory / "release.json").open("xb") as stream:
        stream.write(payload)
    with (directory / "SHA256SUMS").open("xb") as stream:
        stream.write(checksum_text.encode("ascii"))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: release_manifest.py DISTRIBUTION VERSION")
    write_release_manifest(*sys.argv[1:])
