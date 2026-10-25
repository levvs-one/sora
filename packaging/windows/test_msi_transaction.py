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
    if len(set(products)) != 2:
        raise RuntimeError("Fixture product identities must differ")
    for product in products:
        uuid.UUID(product)
    for name in ("old.msi", "new.msi"):
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
        try:
            for phase, name, fail, expected in (
                ("baseline", "old", False, "old\n"),
                ("rejected-new-payload", "new", True, "old\n"),
                ("committed-new-payload", "new", False, "new\n"),
            ):
                if observation.exists():
                    observation.unlink()
                log = logs / f"{phase}.log"
                result = subprocess.run(
                    ["msiexec.exe", "/i", str(directory / f"{name}.msi"), "/qn", "/norestart",
                     "/L*v", str(log), f"INSTALLFOLDER={target}", f"OBSERVATION={observation}",
                     f"PROBEFAIL={int(fail)}"],
                    capture_output=True, timeout=120,
                )
                if (result.returncode == 0) == fail:
                    raise RuntimeError(f"{phase}: unexpected installer exit {result.returncode}; see {log}")
                observed = json.loads(observation.read_text(encoding="utf-8"))
                if observed != {"observed": name + "\n", "expected": name, "failed": fail}:
                    raise RuntimeError(f"{phase}: new payload was not observed before completion")
                if (target / "payload.txt").read_text(encoding="utf-8") != expected:
                    raise RuntimeError(f"{phase}: final bytes do not match the committed installation")
                old_state, new_state = [state(product) for product in products]
                if (old_state, new_state) != ((5, -1) if phase != "committed-new-payload" else (-1, 5)):
                    raise RuntimeError(f"{phase}: inconsistent MSI product states {old_state}/{new_state}")
                print(json.dumps({"phase": phase, "exit": result.returncode, "observed": observed,
                                  "installed": expected, "old_state": old_state, "new_state": new_state}), flush=True)
        finally:
            for index, product in enumerate(products):
                if state(product) in (1, 5):
                    result = subprocess.run(
                        ["msiexec.exe", "/x", product, "/qn", "/norestart", "/L*v", str(logs / f"cleanup-{index}.log")],
                        capture_output=True, timeout=120,
                    )
                    if result.returncode or state(product) == 5:
                        raise RuntimeError("Fixture uninstall did not complete")
        if (target / "payload.txt").exists() or (target / "probe.exe").exists():
            raise RuntimeError("Fixture uninstall retained an installed file")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("expected a validated fixture artifact directory")
    verify(Path(sys.argv[1]).resolve())
