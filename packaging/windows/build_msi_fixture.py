"""Build and inspect the native-transaction probe, never a Sora release package."""

import csv
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import uuid


def build(output):
    output.mkdir(parents=True, exist_ok=False)
    source = Path(__file__).resolve().parent
    upgrade, component, old, new = ["{" + str(uuid.uuid4()).upper() + "}" for _ in range(4)]
    probe = output / "probe.exe"
    subprocess.run(
        ["go", "build", "-trimpath", "-o", str(probe), str(source / "msi_probe.go")],
        env={**os.environ, "GOOS": "windows", "GOARCH": "amd64", "CGO_ENABLED": "0"},
        check=True, timeout=120,
    )
    for name, version, product, text in (("old", "1.0.0", old, "old"), ("new", "2.0.0", new, "new")):
        inputs = output / name
        inputs.mkdir()
        (inputs / "payload.txt").write_text(text + "\n", encoding="utf-8")
        (inputs / "probe.exe").write_bytes(probe.read_bytes())
        package = output / f"{name}.msi"
        command = ["wixl", "-a", "x64", "-o", str(package)]
        for key, value in {
            "Product": product, "Upgrade": upgrade, "Component": component,
            "Version": version, "Expected": text, "Input": str(inputs),
        }.items():
            command += ["-D", f"{key}={value}"]
        compiled = subprocess.run(command + [str(source / "msi-fixture.wxs")], capture_output=True, text=True, timeout=60)
        if compiled.returncode or compiled.stderr.strip():
            raise RuntimeError("MSI compiler warning/failure: " + compiled.stdout + compiled.stderr)
        sequence = subprocess.check_output(["msiinfo", "export", str(package), "InstallExecuteSequence"], text=True)
        rows = list(csv.reader(io.StringIO(sequence), delimiter="\t"))[3:]
        actions = {row[0]: int(row[2]) for row in rows if row}
        if not (
            actions["InstallInitialize"] < actions["RemoveExistingProducts"] < actions["ProcessComponents"]
            and actions["InstallFiles"] < actions["ProbeReady"] < actions["InstallFinalize"]
        ):
            raise RuntimeError("Old-product removal or health gate is outside the rollback transaction")
        custom = subprocess.check_output(["msiinfo", "export", str(package), "CustomAction"], text=True)
        rows = list(csv.reader(io.StringIO(custom), delimiter="\t"))[3:]
        gate = [row for row in rows if row and row[0] == "ProbeReady"]
        if len(gate) != 1 or not int(gate[0][1]) & 0x400 or int(gate[0][1]) & 0x40:
            raise RuntimeError("Health gate must be deferred and reject failures")
        (output / f"{name}-sequence.idt").write_text(sequence, encoding="utf-8")
    metadata = {"old": old, "new": new, "sha256": {
        name: hashlib.sha256((output / name).read_bytes()).hexdigest() for name in ("old.msi", "new.msi")
    }}
    (output / "fixture.json").write_text(json.dumps(metadata, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"products": {"old": old, "new": new}, "sha256": metadata["sha256"]}, sort_keys=True))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("expected a new fixture output directory")
    build(Path(sys.argv[1]).resolve())
