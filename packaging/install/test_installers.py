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
        for name in ("Sora-Setup-1.2.3-x64.exe", "sora-core_1.2.3_amd64.deb", "sora_1.2.3_amd64.deb",
                     "sora-core_1.2.3_arm64.deb", "sora_1.2.3_arm64.deb"):
            (cls.inputs / name).write_bytes(b"Installer boundary fixture, never executed or installed\n")
        cls.tools = cls.root / "tools"
        prepare(cls.inputs, "1.2.3", cls.tools)
        cls.script = Path(__file__).with_name("install.ps1" if os.name == "nt" else "install.sh").resolve()

    def run_installer(self, variant, shell="pwsh", architecture=None, expected_packages=None, crypto_available=True, installed_verifier=False):
        bootstrap = variant.startswith("bootstrap-")
        if bootstrap:
            variant = variant.removeprefix("bootstrap-")
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
            elif variant == "modified comment signature":
                signature = distribution / "SHA256SUMS.minisig"
                lines = signature.read_text().splitlines()
                lines[3] = "A" * 86 + "=="
                signature.write_text("\n".join(lines) + "\n")
            elif variant == "wrong version":
                version = "1.2.4"
            elif variant == "bad version":
                version = "1.2.3/../../other"
            elif variant == "duplicate checksum":
                for name in ("SHA256SUMS", "SHA256SUMS.minisig"):
                    shutil.copyfile(self.tools / "duplicate" / name, distribution / name)
            elif variant.startswith("metadata-"):
                prepared = self.tools / variant
                if prepared.is_dir():
                    (distribution / "release.json").unlink()
                    for item in prepared.iterdir():
                        shutil.copyfile(item, distribution / item.name)
                elif variant == "metadata-missing":
                    (distribution / "release.json").unlink()
                elif variant == "metadata-tamper":
                    (distribution / "release.json").write_bytes(b"changed\n")
                elif variant == "metadata-oversize":
                    (distribution / "release.json").write_bytes(b"x" * (1048576 + 1))
                elif variant == "metadata-symlink":
                    (distribution / "release.json").unlink()
                    (distribution / "release.json").symlink_to("SHA256SUMS")
            elif variant == "modified package":
                for package in distribution.iterdir():
                    if package.name.endswith((".exe", ".deb", ".rpm", ".pkg.tar.zst")):
                        package.write_bytes(b"x" * package.stat().st_size)
            elif variant == "missing arm64 app":
                (distribution / "sora_1.2.3_arm64.deb").unlink()
            elif variant == "missing verifier":
                verifier = case / "absent-verifier"
            elif variant == "downloaded verifier":
                target = distribution / verifier.name
                shutil.copyfile(verifier, target)
                target.chmod(0o755)
                verifier = target
            if os.name == "nt":
                env = {**os.environ, "SORA_VERSION": version, "SORA_DIST": str(distribution), "SORA_VERIFIER": str(verifier)}
                if bootstrap or installed_verifier:
                    env.pop("SORA_VERIFIER", None)
                    env["SORA_TEST_PROGRAM_FILES"] = str(case / "no-installed-client")
                    if installed_verifier:
                        installed = Path(env["SORA_TEST_PROGRAM_FILES"]) / "Sora/core/sora-core.exe"
                        installed.parent.mkdir(parents=True)
                        shutil.copyfile(verifier, installed)
                if bootstrap:
                    public = (self.tools / "fixture-public-key.txt").read_text().strip()
                    script = case / "install.ps1"
                    script.write_text(self.script.read_text().replace("RWQZfr8pZOLhNx/81iyyYi91cZMQTyJece9fX9OWIJoUqMPpN7eCYk/+", public))
                else:
                    script = self.script
                # This intercepts only the final OS execution boundary; signature
                # verification runs the real native verifier with the fixture root.
                driver = case / "driver.ps1"
                # Windows reconstructs ProgramFiles when the shell starts; isolate it in that session.
                driver.write_text("if ($env:SORA_TEST_PROGRAM_FILES) { $env:ProgramFiles = $env:SORA_TEST_PROGRAM_FILES }\nfunction Start-Process { [IO.File]::WriteAllText($env:SORA_INSTALL_MARKER, 'reached'); throw 'INSTALL_BOUNDARY_REACHED' }\n& $env:SORA_INSTALL_SCRIPT\n")
                env["SORA_INSTALL_SCRIPT"] = str(script)
                env["SORA_INSTALL_MARKER"] = str(case / "installation")
                result = subprocess.run([shell, "-NoProfile", "-File", str(driver)], env=env, text=True, capture_output=True, timeout=30)
                reached = (case / "installation").exists()
            else:
                command = ["bwrap", "--unshare-all", "--uid", "0", "--gid", "0", "--die-with-parent",
                           "--ro-bind", "/", "/", "--tmpfs", "/usr/bin", "--tmpfs", "/tmp", "--dev", "/dev",
                           "--bind", str(self.root), "/tmp/test"]
                for name in ("sh", "id", "uname", "rm", "grep", "awk", "mktemp", "sha256sum", "readlink", "head", "wc", "openssl", "sed", "dd", "cmp", "cat"):
                    if name == "openssl" and not crypto_available:
                        continue
                    command += ["--ro-bind", str(Path(shutil.which(name)).resolve()), "/usr/bin/" + name]
                if architecture is not None:
                    machine = {"amd64": "x86_64", "arm64": "aarch64"}[architecture]
                    uname = case / "uname"
                    uname.write_text(f"#!/bin/sh\nprintf '%s\\n' '{machine}'\n")
                    uname.chmod(0o755)
                    command += ["--ro-bind", str(uname), "/usr/bin/uname"]
                boundary = case / "apt-get"
                boundary.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > /tmp/test/' + case.name + '/installation\n')
                boundary.chmod(0o755)
                command += ["--ro-bind", str(boundary), "/usr/bin/apt-get"]
                if installed_verifier:
                    command += ["--ro-bind", str(verifier), "/usr/bin/sora-core"]
                mounted = Path("/tmp/test")
                shutil.copyfile(self.script, case / "install.sh")
                if bootstrap:
                    public = (self.tools / "fixture-public-key.txt").read_text().strip()
                    script = case / "install.sh"
                    script.write_text(script.read_text().replace("RWQZfr8pZOLhNx/81iyyYi91cZMQTyJece9fX9OWIJoUqMPpN7eCYk/+", public))
                command += ["--setenv", "PATH", "/usr/bin", "--setenv", "TMPDIR", "/tmp",
                            "--setenv", "SORA_VERSION", version, "--setenv", "SORA_DIST", str(mounted / distribution.relative_to(self.root))]
                command += (["--unsetenv", "SORA_VERIFIER"] if bootstrap or installed_verifier else
                            ["--setenv", "SORA_VERIFIER", str(mounted / verifier.relative_to(self.root))])
                command += ["--", "/usr/bin/sh", "-c",
                            'printf "%s\\n" SORA_INSTALLER_SANDBOX_READY; exec /usr/bin/sh "$1"',
                            "sora-installer-test", str(mounted / case.name / "install.sh")]
                result = subprocess.run(command, text=True, capture_output=True, timeout=30)
                self.assertIn("SORA_INSTALLER_SANDBOX_READY\n", result.stdout, result.stdout + result.stderr)
                reached = (case / "installation").exists()
                if expected_packages is not None:
                    arguments = (case / "installation").read_text().splitlines() if reached else []
                    packages = [Path(item).name for item in arguments if item.endswith(".deb")]
                    self.assertEqual(packages, expected_packages, result.stdout + result.stderr)
            return result, reached

    def test_first_install_without_a_preinstalled_verifier(self):
        result, reached = self.run_installer("bootstrap-valid")
        self.assertTrue(reached, result.stdout + result.stderr)
        for variant in ("missing signature", "modified manifest", "modified signature", "wrong version",
                        "modified package", "metadata-tamper"):
            with self.subTest(variant=variant):
                result, reached = self.run_installer("bootstrap-" + variant)
                self.assertFalse(reached, result.stdout + result.stderr)

    def test_default_installed_verifier_remains_strict(self):
        for variant in ("valid", "modified signature", "metadata-wrong-size"):
            with self.subTest(variant=variant):
                result, reached = self.run_installer(variant, installed_verifier=True)
                self.assertEqual(reached, variant == "valid", result.stdout + result.stderr)

    @unittest.skipIf(os.name == "nt", "Windows without crypto tools deliberately trusts HTTPS bootstrap")
    def test_bootstrap_authenticates_the_comment_signature(self):
        result, reached = self.run_installer("bootstrap-modified comment signature")
        self.assertFalse(reached, result.stdout + result.stderr)
        self.assertIn("comment signature rejected", result.stdout + result.stderr)

    @unittest.skipIf(os.name == "nt", "Linux tool-availability sandbox")
    def test_bootstrap_without_crypto_tools_reports_https_trust_and_still_checks_packages(self):
        result, reached = self.run_installer("bootstrap-valid", crypto_available=False)
        self.assertTrue(reached, result.stdout + result.stderr)
        self.assertIn("first installation trusts HTTPS and checksums", result.stdout)
        result, reached = self.run_installer("bootstrap-modified package", crypto_available=False)
        self.assertFalse(reached, result.stdout + result.stderr)

    @unittest.skipIf(os.name == "nt", "Linux package architecture selection")
    def test_linux_installs_both_native_packages(self):
        for architecture in ("amd64", "arm64"):
            with self.subTest(architecture=architecture):
                result, reached = self.run_installer("valid", architecture=architecture,
                    expected_packages=[f"sora-core_1.2.3_{architecture}.deb", f"sora_1.2.3_{architecture}.deb"])
                self.assertTrue(reached, result.stdout + result.stderr)

    @unittest.skipIf(os.name == "nt", "Linux package architecture selection")
    def test_missing_arm64_app_never_becomes_core_only_success(self):
        result, reached = self.run_installer("missing arm64 app", architecture="arm64")
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(reached, result.stdout + result.stderr)

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
                if variant == "modified package":
                    self.assertIn("does not match SHA256SUMS", result.stdout + result.stderr)

    def test_signed_metadata_rejections_never_reach_installation(self):
        variants = ("os", "arch", "zero-size", "wrong-size", "version", "duplicate-key", "missing", "tamper", "oversize")
        if os.name != "nt":
            variants += ("symlink",)
        for variant in variants:
            with self.subTest(variant=variant):
                result, reached = self.run_installer("metadata-" + variant)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse(reached, result.stdout + result.stderr)

    def test_signed_legacy_format_is_retired_before_installation(self):
        result, reached = self.run_installer("metadata-legacy")
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(reached, result.stdout + result.stderr)

    @unittest.skipUnless(os.name == "nt", "Windows PowerShell 5.1 compatibility")
    def test_windows_powershell_51_bounds_local_streams(self):
        for variant in ("valid", "metadata-wrong-size", "metadata-legacy", "metadata-oversize"):
            with self.subTest(variant=variant):
                result, reached = self.run_installer(variant, shell="powershell.exe")
                self.assertEqual(reached, variant == "valid", result.stdout + result.stderr)
        for variant in ("valid", "modified signature", "metadata-wrong-size"):
            with self.subTest(default_verifier=variant):
                result, reached = self.run_installer(variant, shell="powershell.exe", installed_verifier=True)
                self.assertEqual(reached, variant == "valid", result.stdout + result.stderr)

    @unittest.skipIf(os.name == "nt", "Linux namespace startup control")
    def test_sandbox_setup_failure_is_not_an_installer_rejection(self):
        failure = subprocess.CompletedProcess([], 1, "", "bwrap: namespace setup denied\n")
        with patch("subprocess.run", return_value=failure):
            with self.assertRaisesRegex(AssertionError, "SORA_INSTALLER_SANDBOX_READY"):
                self.run_installer("missing signature")


if __name__ == "__main__":
    unittest.main()
