"""Native MSI rollback probe; run only in the disposable Windows CI runner."""

import ctypes
from ctypes import wintypes
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import uuid


def verify(directory):
    if os.name != "nt" or os.environ.get("GITHUB_ACTIONS") != "true":
        raise RuntimeError("MSI installations are restricted to the disposable Windows CI runner")
    metadata = json.loads((directory / "fixture.json").read_text(encoding="utf-8"))
    products = [metadata[name] for name in ("old", "new")]
    service = metadata.get("service")
    if service:
        if not service.startswith("SoraMSIFixture-") or len(bytes.fromhex(service.removeprefix("SoraMSIFixture-"))) != 16:
            raise RuntimeError("Refusing to inspect any non-fixture service")
        products.append(metadata["broken"])
        if subprocess.run(["sc.exe", "query", service], capture_output=True, timeout=10).returncode != 1060:
            raise RuntimeError("Refusing to touch an existing or unqueryable service")
    if len(set(products)) != len(products):
        raise RuntimeError("Fixture product identities must differ")
    for product in products:
        uuid.UUID(product)
    for name in (["old.msi", "new.msi", "broken.msi"] if service else ["old.msi", "new.msi"]):
        if hashlib.sha256((directory / name).read_bytes()).hexdigest() != metadata["sha256"][name]:
            raise RuntimeError("Fixture artifact changed after table validation")
    msi = ctypes.WinDLL(str(Path(os.environ["SystemRoot"]) / "System32" / "msi.dll"))
    state = msi.MsiQueryProductStateW
    state.argtypes = [wintypes.LPCWSTR]
    state.restype = ctypes.c_int
    if any(state(product) != -1 for product in products):
        raise RuntimeError("Refusing to overwrite an existing fixture registration")
    logs = directory / "logs"
    logs.mkdir()
    with tempfile.TemporaryDirectory(prefix="sora msi rollback ") as temporary:
        root = Path(temporary)
        target = root / "installation"
        observation = root / "observation.json"
        phases = [
            ("baseline", "old", False, False, "old\n", True),
            ("rejected-new-payload", "new", True, True, "old\n", True),
            ("committed-new-payload", "new", False, False, "new\n", True),
        ]
        if service:
            phases.insert(1, ("failed-service-start", "broken", False, True, "old\n", False))
        try:
            for phase, name, fail, refused, expected, has_observation in phases:
                if observation.exists():
                    observation.unlink()
                log = logs / f"{phase}.log"
                # Msiexec quotes property values, unlike the CRT's whole-argument quoting.
                command = subprocess.list2cmdline([
                    "msiexec.exe", "/i", str(directory / f"{name}.msi"), "/qn", "/norestart", "/L*v!", str(log),
                ]) + f' INSTALLFOLDER="{target}" OBSERVATION="{observation}" PROBEFAIL={int(fail)}'
                (logs / f"{phase}-command.txt").write_text(command + "\n", encoding="utf-8")
                try:
                    result = subprocess.run(command, capture_output=True, timeout=120)
                except subprocess.TimeoutExpired:
                    if service:
                        snapshot = subprocess.run(["sc.exe", "queryex", service], capture_output=True, timeout=10)
                        (logs / f"{phase}-scm.txt").write_bytes(snapshot.stdout + snapshot.stderr)
                    raise
                if (result.returncode == 0) == refused:
                    raise RuntimeError(f"{phase}: unexpected installer exit {result.returncode}; see {log}")
                observed = json.loads(observation.read_text(encoding="utf-8")) if observation.exists() else None
                if has_observation and observed != {"observed": name + "\n", "expected": name, "failed": fail}:
                    raise RuntimeError(f"{phase}: new payload was not observed before completion")
                if not has_observation and observed is not None:
                    raise RuntimeError("Failed service startup reached the post-readiness commit action")
                if (target / "payload.txt").read_text(encoding="utf-8") != expected:
                    raise RuntimeError(f"{phase}: final bytes do not match the committed installation")
                states = [state(product) for product in products]
                wanted = [-1, 5] if phase == "committed-new-payload" else [5, -1]
                if states != wanted + ([-1] if service else []):
                    raise RuntimeError(f"{phase}: inconsistent MSI product states {states}")
                health = None
                if service:
                    ready = subprocess.run([str(target / "service.exe"), "check", service, expected.strip()],
                                           capture_output=True, text=True, timeout=15)
                    (logs / f"{phase}-health.txt").write_text(ready.stdout + ready.stderr, encoding="utf-8")
                    ready.check_returncode()
                    health = json.loads(ready.stdout)
                    if health["version"] != expected.strip() or not health["pipe_pid"] or health["pipe_pid"] != health["scm_pid"]:
                        raise RuntimeError("Readiness did not identify the restored/committed service")
                evidence = {"phase": phase, "exit": result.returncode, "observed": observed,
                            "installed": expected, "product_states": states, "health": health}
                (logs / f"{phase}.json").write_text(json.dumps(evidence) + "\n", encoding="utf-8")
                print(json.dumps(evidence), flush=True)
        finally:
            for index, product in enumerate(products):
                if state(product) in (1, 5):
                    result = subprocess.run(
                        ["msiexec.exe", "/x", product, "/qn", "/norestart", "/L*v!", str(logs / f"cleanup-{index}.log")],
                        capture_output=True, timeout=120,
                    )
                    if result.returncode or state(product) == 5:
                        raise RuntimeError("Fixture uninstall did not complete")
        if (target / "payload.txt").exists() or (target / "probe.exe").exists():
            raise RuntimeError("Fixture uninstall retained an installed file")
        if service and (target / "service.exe").exists():
            raise RuntimeError("Fixture uninstall retained the service executable")
        if service and subprocess.run(["sc.exe", "query", service], capture_output=True, timeout=10).returncode != 1060:
            raise RuntimeError("Fixture uninstall retained the service registration")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("expected a validated fixture artifact directory")
    verify(Path(sys.argv[1]).resolve())
    verify(Path(sys.argv[1]).resolve() / "service")
