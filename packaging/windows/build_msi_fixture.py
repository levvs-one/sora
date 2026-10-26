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


def build(output, service=False):
    version = subprocess.check_output(["wixl", "--version"], text=True, timeout=10).strip()
    if version != "0.106":
        raise RuntimeError(f"Expected the reviewed wixl 0.106 compiler, got {version}")
    output.mkdir(parents=True, exist_ok=False)
    source = Path(__file__).resolve().parent
    upgrade, component, old, new, broken = ["{" + str(uuid.uuid4()).upper() + "}" for _ in range(5)]
    service_name = "SoraMSIFixture-" + uuid.uuid4().hex
    probe = output / "probe.exe"
    subprocess.run(
        ["go", "build", "-trimpath", "-o", str(probe), str(source / "msi_probe.go")],
        env={**os.environ, "GOOS": "windows", "GOARCH": "amd64", "CGO_ENABLED": "0"},
        check=True, timeout=120,
    )
    packages = [("old", "1.0.0", old, "old"), ("new", "2.0.0", new, "new")]
    if service:
        packages.append(("broken", "2.0.0", broken, "new"))
    for name, version, product, text in packages:
        inputs = output / name
        inputs.mkdir()
        (inputs / "payload.txt").write_text(text + "\n", encoding="utf-8")
        (inputs / "probe.exe").write_bytes(probe.read_bytes())
        if service:
            subprocess.run(
                ["go", "build", "-trimpath", "-ldflags", f"-X main.fixtureVersion={text} -X main.failStart={int(name == 'broken')}",
                 "-o", str(inputs / "service.exe"), str(source / "msi_service_probe.go")],
                cwd=source.parent.parent / "core",
                env={**os.environ, "GOOS": "windows", "GOARCH": "amd64", "CGO_ENABLED": "0"},
                check=True, timeout=120,
            )
        package = output / f"{name}.msi"
        command = ["wixl", "-a", "x64", "-o", str(package)]
        for key, value in {
            "Product": product, "Upgrade": upgrade, "Component": component,
            "Version": version, "Expected": text, "Input": str(inputs),
            **({"Service": service_name} if service else {}),
        }.items():
            command += ["-D", f"{key}={value}"]
        template = "msi-service-fixture.wxs" if service else "msi-fixture.wxs"
        compiled = subprocess.run(command + [str(source / template)], capture_output=True, text=True, timeout=60)
        if compiled.returncode or compiled.stderr.strip():
            raise RuntimeError("MSI compiler warning/failure: " + compiled.stdout + compiled.stderr)
        if service:
            # Wixl 0.106 ignores Vital; its companion tool authors the native mandatory-service bit.
            subprocess.run(["msibuild", str(package), "-q", "UPDATE ServiceInstall SET ErrorControl = 32769"],
                           check=True, timeout=10)
        sequence = subprocess.check_output(["msiinfo", "export", str(package), "InstallExecuteSequence"], text=True)
        rows = list(csv.reader(io.StringIO(sequence), delimiter="\t"))[3:]
        actions = {row[0]: int(row[2]) for row in rows if row}
        if not (
            actions["InstallInitialize"] < actions["RemoveExistingProducts"] < actions["ProcessComponents"]
            and actions["InstallFiles"] < actions["ProbeReady"] < actions["InstallFinalize"]
        ):
            raise RuntimeError("Old-product removal or health gate is outside the rollback transaction")
        if service:
            if not actions["StartServices"] < actions["VerifyService"] < actions["ProbeReady"]:
                raise RuntimeError("Readiness must check the running service inside the transaction")
            install = subprocess.check_output(["msiinfo", "export", str(package), "ServiceInstall"], text=True)
            rows = list(csv.reader(io.StringIO(install), delimiter="\t"))[3:]
            if len(rows) != 1 or rows[0][1] != service_name or rows[0][3:6] != ["16", "3", "32769"] or rows[0][8:10] != ["", ""]:
                raise RuntimeError("Fixture requires a demand-start LocalSystem service without a password")
            control = subprocess.check_output(["msiinfo", "export", str(package), "ServiceControl"], text=True)
            rows = list(csv.reader(io.StringIO(control), delimiter="\t"))[3:]
            if len(rows) != 2 or sorted(row[1:5] for row in rows) != sorted([
                [service_name, "1", "", "0"], [service_name, "162", "", "1"],
            ]):
                raise RuntimeError("Fixture must wait for stop/removal, with bounded independent startup readiness")
        custom = subprocess.check_output(["msiinfo", "export", str(package), "CustomAction"], text=True)
        rows = list(csv.reader(io.StringIO(custom), delimiter="\t"))[3:]
        gate = [row for row in rows if row and row[0] == "ProbeReady"]
        if len(gate) != 1 or not int(gate[0][1]) & 0x400 or int(gate[0][1]) & 0x40:
            raise RuntimeError("Health gate must be deferred and reject failures")
        if service:
            health = [row for row in rows if row and row[0] == "VerifyService"]
            if len(health) != 1 or int(health[0][1]) != 3090 or int(gate[0][1]) != 3090:
                raise RuntimeError("Service readiness actions must be deferred, checked and non-impersonating")
        (output / f"{name}-sequence.idt").write_text(sequence, encoding="utf-8")
    metadata = {"old": old, "new": new, "sha256": {
        name + ".msi": hashlib.sha256((output / (name + ".msi")).read_bytes()).hexdigest() for name, _, _, _ in packages
    }}
    if service:
        metadata.update(service=service_name, broken=broken)
    (output / "fixture.json").write_text(json.dumps(metadata, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"products": {"old": old, "new": new}, "sha256": metadata["sha256"]}, sort_keys=True))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("expected a new fixture output directory")
    build(Path(sys.argv[1]).resolve())
    build(Path(sys.argv[1]).resolve() / "service", service=True)
