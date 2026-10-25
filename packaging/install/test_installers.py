"""Real signatures, isolated installer boundary; no host installation or services."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from prepare_test_release import prepare


class InstallerSignatureTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix="sora-install-signatures-")
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.root = Path(cls.temporary.name)
        cls.inputs = cls.root / "inputs"
        cls.inputs.mkdir()
        for name in ("Sora-Setup-1.2.3-x64.exe", "sora-core_1.2.3_amd64.deb", "sora_1.2.3_amd64.deb"):
            (cls.inputs / name).write_bytes(b"Installer boundary fixture, never executed or installed\n")
        cls.tools = cls.root / "tools"
        prepare(cls.inputs, "1.2.3", cls.tools)
        cls.script = Path(__file__).with_name("install.ps1" if os.name == "nt" else "install.sh").resolve()

    def run_installer(self, variant):
        with tempfile.TemporaryDirectory(prefix="case-", dir=self.root) as directory:
            case = Path(directory)
            distribution = case / "distribution"
            shutil.copytree(self.inputs, distribution)
            verifier = self.tools / ("sora-verifier.exe" if os.name == "nt" else "sora-verifier")
            version = "1.2.3"
            if variant == "missing signature":
                (distribution / "SHA256SUMS.minisig").unlink()
            elif variant == "modified manifest":
                (distribution / "SHA256SUMS").write_text("a" * 64 + "  changed.exe\n")
            elif variant == "modified signature":
                (distribution / "SHA256SUMS.minisig").write_text("untrusted signature\n")
            elif variant == "wrong version":
                version = "1.2.4"
            elif variant == "bad version":
                version = "1.2.3/../../other"
            elif variant == "duplicate checksum":
                for name in ("SHA256SUMS", "SHA256SUMS.minisig"):
                    shutil.copyfile(self.tools / "duplicate" / name, distribution / name)
            elif variant == "modified package":
                for package in distribution.iterdir():
                    if package.name not in ("SHA256SUMS", "SHA256SUMS.minisig"):
                        package.write_bytes(b"tampered package\n")
            elif variant == "missing verifier":
                verifier = case / "absent-verifier"
            elif variant == "downloaded verifier":
                target = distribution / verifier.name
                shutil.copyfile(verifier, target)
                target.chmod(0o755)
                verifier = target
            if os.name == "nt":
                env = {**os.environ, "SORA_VERSION": version, "SORA_DIST": str(distribution), "SORA_VERIFIER": str(verifier)}
                # This intercepts only the final OS execution boundary; signature
                # verification runs the real native verifier with the fixture root.
                driver = case / "driver.ps1"
                driver.write_text("function Start-Process { throw 'INSTALL_BOUNDARY_REACHED' }\n& $env:SORA_INSTALL_SCRIPT\n")
                env["SORA_INSTALL_SCRIPT"] = str(self.script)
                result = subprocess.run(["pwsh", "-NoProfile", "-File", str(driver)], env=env, text=True, capture_output=True, timeout=30)
                reached = "INSTALL_BOUNDARY_REACHED" in result.stdout + result.stderr
            else:
                command = ["bwrap", "--unshare-all", "--uid", "0", "--gid", "0", "--die-with-parent",
                           "--ro-bind", "/", "/", "--tmpfs", "/usr/bin", "--tmpfs", "/tmp", "--dev", "/dev",
                           "--bind", str(self.root), "/tmp/test"]
                for name in ("sh", "id", "uname", "cp", "rm", "grep", "awk", "mktemp", "sha256sum", "readlink"):
                    command += ["--ro-bind", str(Path(shutil.which(name)).resolve()), "/usr/bin/" + name]
                boundary = case / "apt-get"
                boundary.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > /tmp/test/' + case.name + '/installation\n')
                boundary.chmod(0o755)
                command += ["--ro-bind", str(boundary), "/usr/bin/apt-get"]
                mounted = Path("/tmp/test")
                shutil.copyfile(self.script, case / "install.sh")
                command += ["--setenv", "PATH", "/usr/bin", "--setenv", "TMPDIR", "/tmp",
                            "--setenv", "SORA_VERSION", version, "--setenv", "SORA_DIST", str(mounted / distribution.relative_to(self.root)),
                            "--setenv", "SORA_VERIFIER", str(mounted / verifier.relative_to(self.root)), "--", "/usr/bin/sh", "-c",
                            'printf "%s\\n" SORA_INSTALLER_SANDBOX_READY; exec /usr/bin/sh "$1"',
                            "sora-installer-test", str(mounted / case.name / "install.sh")]
                result = subprocess.run(command, text=True, capture_output=True, timeout=30)
                self.assertIn("SORA_INSTALLER_SANDBOX_READY\n", result.stdout, result.stdout + result.stderr)
                reached = (case / "installation").exists()
            return result, reached

    def test_signed_input_reaches_only_the_isolated_install_boundary(self):
        result, reached = self.run_installer("valid")
        self.assertTrue(reached, result.stdout + result.stderr)

    def test_rejections_never_reach_installation(self):
        for variant in ("missing signature", "modified manifest", "modified signature", "wrong version", "bad version",
                        "duplicate checksum", "modified package", "missing verifier", "downloaded verifier"):
            with self.subTest(variant=variant):
                result, reached = self.run_installer(variant)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse(reached, result.stdout + result.stderr)

    @unittest.skipIf(os.name == "nt", "Linux namespace startup control")
    def test_sandbox_setup_failure_is_not_an_installer_rejection(self):
        failure = subprocess.CompletedProcess([], 1, "", "bwrap: namespace setup denied\n")
        with patch("subprocess.run", return_value=failure):
            with self.assertRaisesRegex(AssertionError, "SORA_INSTALLER_SANDBOX_READY"):
                self.run_installer("missing signature")


if __name__ == "__main__":
    unittest.main()
