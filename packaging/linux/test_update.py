"""Exercise the privileged helper in a mount/user namespace with no host writes."""

import hashlib
import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest


class UpdateHelperTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="sora-helper-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.downloads = self.root / "downloads"
        self.downloads.mkdir()
        shutil.copyfile(pathlib.Path(__file__).with_name("sora-update"), self.root / "sora-update")

    def script(self, name, body):
        target = self.root / name
        target.write_text("#!/bin/sh\nset -eu\n" + body + "\n")
        target.chmod(0o755)
        return target

    def prepare(self, format):
        files = {
            "deb": ["sora-core_1.0.5_amd64.deb", "sora_1.0.5_amd64.deb"],
            "rpm": ["sora-core-1.0.5-1.x86_64.rpm", "sora-1.0.5-1.x86_64.rpm"],
            "arch": ["sora-core-1.0.5-1-x86_64.pkg.tar.zst", "sora-1.0.5-1-x86_64.pkg.tar.zst"],
        }[format]
        checksums = []
        for name in files:
            data = ("Package fixture " + name).encode()
            (self.downloads / name).write_bytes(data)
            checksums.append(hashlib.sha256(data).hexdigest() + "  " + name + "\n")
        metadata = b'{"schema":1}\n'
        (self.downloads / "release.json").write_bytes(metadata)
        checksums.append(hashlib.sha256(metadata).hexdigest() + "  release.json\n")
        (self.downloads / "SHA256SUMS").write_text("".join(checksums))
        # Crypto is exercised by the native/Dart signature tests. This suite
        # isolates the helper's snapshot, invocation and installer boundary.
        (self.downloads / "SHA256SUMS.minisig").write_text("verifier contract fixture\n")
        return files

    def run_helper(self, format, version="1.0.5", bad_metadata=False, zypper=False, dependency_failure=False,
                   installed="1.0.4", extra=(), signature_failure=False, missing_verifier=False, signed_size=None, old_verifier=False,
                   native_verifier=False):
        recorder = '[ -f /tmp/test/verification ] && printf "%s\\n" "$@" > /tmp/test/calls'
        # The query fakes also report the installed sora-core version
        # (TEST_INSTALLED) for the helper's downgrade protection.
        scripts = {
            "sora-core": 'if [ "$1" = -prepare-update ]; then [ "${TEST_OLD_VERIFIER:-0}" = 0 ];'
                         ' [ "$3" = -release-version ] && [ "$4" = 1.0.5 ];'
                         ' [ "${TEST_SIGNATURE_FAILURE:-0}" = 0 ]; case "$6" in /var/tmp/sora-update.*) ;; *) exit 1;; esac;'
                         ' case "$2" in deb) files="sora-core_1.0.5_amd64.deb sora_1.0.5_amd64.deb";;'
                         ' rpm) files="sora-core-1.0.5-1.x86_64.rpm sora-1.0.5-1.x86_64.rpm";;'
                         ' arch) files="sora-core-1.0.5-1-x86_64.pkg.tar.zst sora-1.0.5-1-x86_64.pkg.tar.zst";; *) exit 1;; esac;'
                         ' if [ -e "$5/release.json" ] || [ -L "$5/release.json" ]; then files="$files release.json"; fi;'
                         ' for name in SHA256SUMS SHA256SUMS.minisig $files; do'
                         ' [ -f "$5/$name" ] && [ ! -L "$5/$name" ]; cp -P -- "$5/$name" "$6/$name"; done; exit 0; fi;'
                         ' [ "$1" = -verify-release ] && [ "$3" = -release-version ] &&'
                         ' [ "$4" = 1.0.5 ]; case "$2" in /var/tmp/sora-update.*) ;; *) exit 1;; esac;'
                         ' [ -f "$2/SHA256SUMS" ] && [ -f "$2/SHA256SUMS.minisig" ];'
                         ' [ "${TEST_SIGNATURE_FAILURE:-0}" = 0 ]; case "$#" in'
                         ' 4) printf "%s\\n" "$@" > /tmp/test/verification;;'
                         ' 8) [ "$5" = -release-artifact ] && [ "$7" = -release-target ] && [ "$8" = linux/amd64 ];'
                         ' if [ "$TEST_SIGNED_SIZE" = auto ]; then wc -c <"$2/$6"; else printf "%s\\n" "$TEST_SIGNED_SIZE"; fi;; *) exit 1;; esac',
            "dpkg-query": 'case "$1" in -S) echo "sora: /usr/lib/sora/app/sora";; -W) case "$2" in'
                          " -f='${Version}') echo \"$TEST_INSTALLED\";; *) echo installed;; esac;;"
                          " *) exit 1;; esac",
            "dpkg-deb": 'case "$3" in Package) name=${2##*/}; echo "${name%%_*}";; Version) echo "${TEST_VERSION:-1.0.5}";; Architecture) echo amd64;; esac',
            "rpm": 'case "$1" in -qf) echo sora;; -q) case "$2" in --qf) echo "$TEST_INSTALLED";;'
                   ' *) printf "sora\\nsora-core\\n";; esac;; -qp) name=${4##*/};'
                   ' printf "%s %s-1 x86_64\\n" "${name%-1.0.5-1.x86_64.rpm}" "${TEST_VERSION:-1.0.5}";;'
                   " *) exit 1;; esac",
            "pacman": 'case "$1" in -Qoq) echo sora;; -Q) if [ "$#" = 2 ]; then echo "sora-core ${TEST_INSTALLED}-1";'
                      ' else printf "sora\\nsora-core\\n"; fi;; -Qp) name=${2##*/};'
                      ' printf "%s %s-1\\n" "${name%-1.0.5-1-x86_64.pkg.tar.zst}" "${TEST_VERSION:-1.0.5}";;'
                      ' -S) printf "%s\\n" "$@" > /tmp/test/dependencies; [ "${TEST_DEPENDENCY_FAILURE:-0}" = 0 ];;'
                      " -U) " + recorder + ";; *) exit 1;; esac",
            "apt-get": recorder,
            "zypper" if zypper else "dnf": recorder,
        }
        if missing_verifier:
            del scripts["sora-core"]
        if native_verifier:
            scripts["sora-core"] = '/tmp/test/test-tools/sora-verifier "$@"; if [ "$1" = -verify-release ] && [ "$#" = 4 ]; then' \
                                   ' printf "%s\\n" "$@" > /tmp/test/verification; fi'
        command = [
            "bwrap", "--unshare-all", "--share-net", "--uid", "0", "--gid", "0", "--die-with-parent",
            "--ro-bind", "/", "/", "--tmpfs", "/run", "--tmpfs", "/tmp",
            "--dev", "/dev",
            "--tmpfs", "/var/tmp", "--tmpfs", "/usr/bin", "--bind", str(self.root), "/tmp/test",
        ]
        command += ["--setenv", "TEST_INSTALLED", installed]
        command += ["--setenv", "TEST_SIGNED_SIZE", "auto" if signed_size is None else signed_size]
        for name in ["sh", "id", "uname", "cp", "rm", "grep", "awk", "mktemp", "sha256sum", "sed", "cut", "wc"]:
            command += ["--ro-bind", str(pathlib.Path(shutil.which(name)).resolve()), "/usr/bin/" + name]
        for name, body in scripts.items():
            command += ["--ro-bind", str(self.script(name, body)), "/usr/bin/" + name]
        if bad_metadata:
            command += ["--setenv", "TEST_VERSION", "1.0.4"]
        if dependency_failure:
            command += ["--setenv", "TEST_DEPENDENCY_FAILURE", "1"]
        if signature_failure:
            command += ["--setenv", "TEST_SIGNATURE_FAILURE", "1"]
        if old_verifier:
            command += ["--setenv", "TEST_OLD_VERIFIER", "1"]
        command += ["--", "/bin/sh", "/tmp/test/sora-update", format, version, "/tmp/test/downloads", *extra]
        return subprocess.run(command, capture_output=True, text=True, timeout=10)

    def test_downgrade_needs_the_explicit_flag(self):
        for format, zypper, flag in [("deb", False, "--allow-downgrades"), ("rpm", False, "downgrade"),
                                     ("rpm", True, "--oldpackage"), ("arch", False, "-U")]:
            with self.subTest(format=format, zypper=zypper):
                self.prepare(format)
                refused = self.run_helper(format, zypper=zypper, installed="1.0.6")
                self.assertNotEqual(refused.returncode, 0)
                self.assertIn("downgrade from 1.0.6 to 1.0.5 refused", refused.stderr)
                self.assertFalse((self.root / "calls").exists())
                allowed = self.run_helper(format, zypper=zypper, installed="1.0.6", extra=("--allow-downgrade",))
                self.assertEqual(allowed.returncode, 0, allowed.stderr)
                self.assertIn(flag, (self.root / "calls").read_text().splitlines())
                (self.root / "calls").unlink()
                for item in self.downloads.iterdir():
                    item.unlink()

    def test_unknown_fourth_argument_is_refused(self):
        self.prepare("deb")
        result = self.run_helper("deb", extra=("--force",))
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "calls").exists())

    def test_pair_in_one_transaction_for_every_manager(self):
        for format, zypper in [("deb", False), ("rpm", False), ("rpm", True), ("arch", False)]:
            with self.subTest(format=format, zypper=zypper):
                files = self.prepare(format)
                result = self.run_helper(format, zypper=zypper)
                self.assertEqual(result.returncode, 0, result.stderr)
                arguments = (self.root / "calls").read_text().splitlines()
                packages = [item for item in arguments if item.startswith("/var/tmp/")]
                self.assertEqual([pathlib.Path(item).name for item in packages], files)
                self.assertEqual(len(packages), 2)
                verification = (self.root / "verification").read_text().splitlines()
                self.assertEqual(verification[0], "-verify-release")
                self.assertTrue(verification[1].startswith("/var/tmp/sora-update."))
                self.assertEqual(verification[2:], ["-release-version", "1.0.5"])
                (self.root / "calls").unlink()

    def test_arch_dependency_failure_leaves_the_installed_pair_untouched(self):
        self.prepare("arch")
        result = self.run_helper("arch", dependency_failure=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "calls").exists())
        arguments = (self.root / "dependencies").read_text().splitlines()
        self.assertEqual(arguments, ["-S", "--noconfirm", "--needed", "gst-plugins-good"])

    def test_reject_corrupt_missing_duplicate_and_symlink_inputs(self):
        for problem in ["corrupt", "missing", "duplicate", "symlink", "missing-signature", "signature-symlink", "metadata", "version", "format"]:
            with self.subTest(problem=problem):
                for item in self.downloads.iterdir():
                    item.unlink()
                files = self.prepare("deb")
                sums = self.downloads / "SHA256SUMS"
                if problem == "corrupt":
                    (self.downloads / files[0]).write_bytes(b"corrupt")
                elif problem == "missing":
                    (self.downloads / files[1]).unlink()
                elif problem == "duplicate":
                    sums.write_text(sums.read_text() * 2)
                elif problem == "symlink":
                    target = self.downloads / files[0]
                    target.unlink()
                    target.symlink_to(files[1])
                elif problem == "missing-signature":
                    (self.downloads / "SHA256SUMS.minisig").unlink()
                elif problem == "signature-symlink":
                    target = self.downloads / "SHA256SUMS.minisig"
                    target.unlink()
                    target.symlink_to("SHA256SUMS")
                result = self.run_helper(
                    "unknown" if problem == "format" else "deb",
                    version="1.0.5;touch /tmp/test/escaped" if problem == "version" else "1.0.5",
                    bad_metadata=problem == "metadata",
                )
                self.assertNotIn("bwrap:", result.stderr)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertFalse((self.root / "calls").exists())
                self.assertFalse((self.root / "escaped").exists())

    def test_untrusted_release_or_missing_installed_verifier_never_installs(self):
        self.prepare("deb")
        downloaded = self.downloads / "sora-core"
        downloaded.write_text("#!/bin/sh\nprintf used > /tmp/test/escaped\nexit 0\n")
        downloaded.chmod(0o755)
        for arguments in ({"signature_failure": True}, {"missing_verifier": True}, {"old_verifier": True}):
            with self.subTest(arguments=arguments):
                result = self.run_helper("deb", **arguments)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("release snapshot verification failed", result.stderr)
                self.assertFalse((self.root / "calls").exists())
                self.assertFalse((self.root / "escaped").exists())

    def test_declared_release_metadata_is_snapshotted_and_hash_checked(self):
        for problem in ("valid", "empty", "missing", "corrupt", "symlink", "oversize", "unlisted"):
            with self.subTest(problem=problem):
                for item in self.downloads.iterdir():
                    item.unlink()
                self.prepare("deb")
                metadata = self.downloads / "release.json"
                sums = self.downloads / "SHA256SUMS"
                if problem == "unlisted":
                    sums.write_text("".join(line for line in sums.read_text().splitlines(keepends=True) if not line.endswith("  release.json\n")))
                elif problem == "empty":
                    metadata.write_bytes(b"")
                elif problem == "missing":
                    metadata.unlink()
                elif problem == "corrupt":
                    metadata.write_bytes(b"changed\n")
                elif problem == "symlink":
                    metadata.unlink()
                    metadata.symlink_to("SHA256SUMS")
                elif problem == "oversize":
                    metadata.write_bytes(b"x" * (1048576 + 1))
                result = self.run_helper("deb")
                self.assertNotIn("bwrap:", result.stderr)
                self.assertEqual(result.returncode == 0, problem == "valid", result.stdout + result.stderr)
                self.assertEqual((self.root / "calls").exists(), problem == "valid")
                if (self.root / "calls").exists():
                    (self.root / "calls").unlink()

    def test_size_query_is_required_and_enforced_before_installation(self):
        self.prepare("deb")
        for size in ("0", "1", "999", "2147483649", "", "verified", "1;touch /tmp/test/escaped"):
            with self.subTest(size=size):
                result = self.run_helper("deb", signed_size=size)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse((self.root / "calls").exists())
                self.assertFalse((self.root / "escaped").exists())

    def test_real_native_snapshot_and_signature_before_package_manager(self):
        self.prepare("deb")
        for name in ("SHA256SUMS", "SHA256SUMS.minisig", "release.json"):
            (self.downloads / name).unlink()
        tools = self.root / "test-tools"
        builder = pathlib.Path(__file__).resolve().parents[1] / "install/prepare_test_release.py"
        prepared = subprocess.run(["python3", "-B", str(builder), str(self.downloads), "1.0.5", str(tools)],
                                  capture_output=True, text=True, timeout=180, env={**os.environ, "CGO_ENABLED": "0"})
        self.assertEqual(prepared.returncode, 0, prepared.stdout + prepared.stderr)
        result = self.run_helper("deb", native_verifier=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.root / "calls").exists())
        (self.root / "calls").unlink()
        (self.root / "verification").unlink()
        package = self.downloads / "sora_1.0.5_amd64.deb"
        original_package = package.read_bytes()
        package.write_bytes(b"tampered")
        refused = self.run_helper("deb", native_verifier=True)
        self.assertNotEqual(refused.returncode, 0, refused.stdout + refused.stderr)
        self.assertIn("release snapshot verification failed", refused.stderr)
        self.assertFalse((self.root / "calls").exists())
        package.write_bytes(original_package)
        for stray in (False, True):
            with self.subTest(retired_signed_legacy=True, stray_json=stray):
                for name in ("SHA256SUMS", "SHA256SUMS.minisig"):
                    shutil.copyfile(tools / "metadata-legacy" / name, self.downloads / name)
                metadata = self.downloads / "release.json"
                if not stray:
                    metadata.unlink()
                else:
                    metadata.write_bytes(b'{"schema":1}\n')
                refused = self.run_helper("deb", native_verifier=True)
                self.assertNotEqual(refused.returncode, 0, refused.stdout + refused.stderr)
                self.assertIn("release snapshot verification failed", refused.stderr)
                self.assertFalse((self.root / "calls").exists())


if __name__ == "__main__":
    unittest.main()
