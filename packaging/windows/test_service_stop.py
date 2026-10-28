"""Compile the shipped stop gate; only a temporary payload and inert core run."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipUnless(os.name == "nt", "requires native Inno Setup")
class ServiceStopGateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix="sora-stop-gate-")
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.root = Path(cls.temporary.name)
        cls.compiler = shutil.which("iscc") or str(
            Path(os.environ["ProgramFiles(x86)"]) / "Inno Setup 6" / "ISCC.exe"
        )
        if not Path(cls.compiler).is_file():
            raise RuntimeError("Inno Setup is required; the stop gate was not tested")
        source = Path(__file__).with_name("sora.iss").read_text(encoding="utf-8")
        marker = "function PrepareToInstall(var NeedsRestart: Boolean): String;"
        _, separator, body = source.rpartition(marker)
        if not separator or not body.rstrip().endswith("end;"):
            raise RuntimeError("Cannot extract the complete shipped preparation event")
        cls.gate = marker + body
        fixture = cls.root / "core.go"
        fixture.write_text(
            'package main\nimport("os";"strconv")\nfunc main(){\n'
            'if len(os.Args)!=2 || os.Args[1]!="-stop-service" {os.Exit(93)}\n'
            'code,err:=strconv.Atoi(os.Getenv("SORA_STOP_TEST_EXIT"));'
            'if err!=nil {os.Exit(94)};os.Exit(code)\n}\n',
            encoding="utf-8",
        )
        cls.core = cls.root / "fixture-core.exe"
        build = subprocess.run(
            ["go", "build", "-o", str(cls.core), str(fixture)],
            capture_output=True, text=True, timeout=120,
        )
        if build.returncode:
            raise RuntimeError(build.stdout + build.stderr)

    def test_preparation_outcome_controls_file_replacement(self):
        for variant in ("stopped", "refused", "cannot-launch", "cannot-extract"):
            with self.subTest(variant=variant):
                case = self.root / variant
                case.mkdir()
                target = case / "installed"
                target.mkdir()
                old = target / "payload.txt"
                old.write_bytes(b"previous verified payload\n")
                payload = case / "payload.txt"
                payload.write_bytes(b"replacement payload\n")
                core = case / "sora-core.exe"
                if variant == "cannot-launch":
                    core.write_bytes(b"not an executable\n")
                else:
                    shutil.copyfile(self.core, core)
                core_entry = 'Source: "sora-core.exe"; Flags: dontcopy\n'
                if variant == "cannot-extract":
                    core_entry = ""
                script = case / "fixture.iss"
                script.write_text(
                    "[Setup]\nAppName=Sora stop gate fixture\nAppVersion=1.0\n"
                    "DefaultDirName={tmp}\\unused-sora-stop-fixture\n"
                    "PrivilegesRequired=lowest\nUninstallable=no\n"
                    "CloseApplications=no\nRestartApplications=no\n"
                    "DisableWelcomePage=yes\nDisableDirPage=yes\n"
                    "DisableProgramGroupPage=yes\nDisableReadyPage=yes\n"
                    "OutputDir=.\nOutputBaseFilename=fixture\n"
                    "[Files]\n" + core_entry
                    + 'Source: "payload.txt"; DestDir: "{app}"; Flags: ignoreversion\n'
                    + "[CustomMessages]\nServiceStopFailed=fixture stop failed\n"
                    + "[Code]\n" + self.gate,
                    encoding="utf-8",
                )
                compiled = subprocess.run(
                    [self.compiler, "/Qp", str(script)],
                    capture_output=True, text=True, timeout=60,
                )
                self.assertEqual(compiled.returncode, 0, compiled.stdout + compiled.stderr)
                result = subprocess.run(
                    [str(case / "fixture.exe"), "/VERYSILENT", "/SUPPRESSMSGBOXES",
                     "/NORESTART", "/SP-", f"/DIR={target}", f"/LOG={case / 'install.log'}"],
                    env={**os.environ, "SORA_STOP_TEST_EXIT": "0" if variant == "stopped" else "42"},
                    capture_output=True, timeout=60,
                )
                log = (case / "install.log").read_text(encoding="utf-8-sig", errors="replace")
                if variant == "stopped":
                    self.assertEqual(result.returncode, 0, log)
                    self.assertEqual(old.read_bytes(), payload.read_bytes(), log)
                else:
                    self.assertNotEqual(result.returncode, 0, log)
                    self.assertEqual(old.read_bytes(), b"previous verified payload\n", log)


if __name__ == "__main__":
    unittest.main(verbosity=2)
