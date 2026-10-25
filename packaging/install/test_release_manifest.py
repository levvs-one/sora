"""Exercise the real release producer with files, including malformed inputs."""

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import release_manifest


class ReleaseManifestTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="sora-release-metadata-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def artifact(self, name, content=b"abc"):
        path = self.root / name
        path.write_bytes(content)
        return path

    def test_catalog_covers_every_current_platform_and_standard_checksums(self):
        expected = {"Sora-Setup-1.2.3-x64.exe": ("windows", "amd64"),
                    "install.ps1": ("windows", "any"), "install.sh": ("linux", "any")}
        for arch, machine in (("amd64", "x86_64"), ("arm64", "aarch64")):
            for package in ("sora-core", "sora") if arch == "amd64" else ("sora-core",):
                for name in (f"{package}_1.2.3_{arch}.deb", f"{package}-1.2.3-1.{machine}.rpm",
                             f"{package}-1.2.3-1-{machine}.pkg.tar.zst"):
                    expected[name] = ("linux", arch)
        for name in reversed(expected):
            self.artifact(name)
        release_manifest.write_release_manifest(self.root, "1.2.3")
        payload = (self.root / "release.json").read_bytes()
        document = json.loads(payload)
        self.assertEqual(document["schema"], 1)
        self.assertEqual(document["version"], "1.2.3")
        self.assertEqual([entry["name"] for entry in document["artifacts"]], sorted(expected))
        digest = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        for entry in document["artifacts"]:
            self.assertEqual((entry["os"], entry["arch"]), expected[entry["name"]])
            self.assertEqual(entry["size"], 3)
            self.assertEqual(entry["sha256"], digest)
            self.assertEqual((self.root / entry["name"]).read_bytes(), b"abc")
        checksums = (self.root / "SHA256SUMS").read_text().splitlines()
        self.assertEqual(len(checksums), len(expected) + 1)
        self.assertIn(hashlib.sha256(payload).hexdigest() + "  release.json", checksums)
        if shutil.which("sha256sum"):
            subprocess.run(["sha256sum", "--strict", "--check", "SHA256SUMS"], cwd=self.root,
                           check=True, capture_output=True)
            (self.root / "release.json").write_bytes(payload + b" ")
            changed = subprocess.run(["sha256sum", "--strict", "--check", "SHA256SUMS"], cwd=self.root,
                                     capture_output=True)
            self.assertNotEqual(changed.returncode, 0)

    def test_metadata_is_independent_of_directory_creation_order(self):
        first, second = self.root / "first", self.root / "second"
        first.mkdir()
        second.mkdir()
        names = ["install.sh", "Sora-Setup-1.2.3-x64.exe", "sora-core_1.2.3_arm64.deb"]
        for directory, order in ((first, names), (second, list(reversed(names)))):
            for name in order:
                (directory / name).write_bytes(b"abc")
            release_manifest.write_release_manifest(directory, "1.2.3")
        for name in ("release.json", "SHA256SUMS"):
            self.assertEqual((first / name).read_bytes(), (second / name).read_bytes())

    def test_invalid_versions_are_rejected_before_outputs(self):
        self.artifact("install.sh")
        for version in ("v1.2.3", "1.2", "01.2.3", "1.2.3-beta", "1.2.3/../other", "1" * 65 + ".2.3"):
            with self.subTest(version=version), self.assertRaises(ValueError):
                release_manifest.write_release_manifest(self.root, version)
        self.assertFalse((self.root / "release.json").exists())

    def test_unknown_or_wrong_platform_names_are_rejected(self):
        for name in ("sora_1.2.3_arm64.deb", "Sora-Setup-1.2.4-x64.exe", "Sora-Setup-1.2.3-arm64.exe", "payload.exe"):
            with self.subTest(name=name):
                path = self.artifact(name)
                with self.assertRaises(ValueError):
                    release_manifest.write_release_manifest(self.root, "1.2.3")
                path.unlink()

    def test_nonregular_and_empty_inputs_are_rejected(self):
        with self.assertRaises(ValueError):
            release_manifest.write_release_manifest(self.root, "1.2.3")
        path = self.root / "install.sh"
        path.mkdir()
        with self.assertRaises(ValueError):
            release_manifest.write_release_manifest(self.root, "1.2.3")
        path.rmdir()
        self.artifact("install.sh", b"")
        with self.assertRaises(ValueError):
            release_manifest.write_release_manifest(self.root, "1.2.3")

    def test_symlinks_are_rejected(self):
        link = self.root / "install.sh"
        try:
            link.symlink_to(self.root / "absent-target")
        except OSError as error:
            self.skipTest(str(error))
        with self.assertRaises(ValueError):
            release_manifest.write_release_manifest(self.root, "1.2.3")

    def test_oversized_inputs_are_rejected_without_large_allocations(self):
        self.artifact("install.sh", b"1234")
        with patch.object(release_manifest, "MAX_ARTIFACT_BYTES", 3):
            with self.assertRaises(ValueError):
                release_manifest.write_release_manifest(self.root, "1.2.3")

    def test_too_many_files_are_rejected_before_hashing(self):
        self.artifact("install.sh")
        self.artifact("install.ps1")
        with patch.object(release_manifest, "MAX_ARTIFACTS", 1):
            with patch.object(release_manifest.hashlib, "file_digest") as hashing:
                with self.assertRaises(ValueError):
                    release_manifest.write_release_manifest(self.root, "1.2.3")
                hashing.assert_not_called()

    def test_existing_metadata_is_never_replaced(self):
        self.artifact("install.sh")
        for name in release_manifest.OUTPUT_NAMES:
            with self.subTest(name=name):
                path = self.artifact(name, b"existing")
                with self.assertRaises(FileExistsError):
                    release_manifest.write_release_manifest(self.root, "1.2.3")
                self.assertEqual(path.read_bytes(), b"existing")
                path.unlink()

    def test_a_change_during_hashing_prevents_metadata_creation(self):
        path = self.artifact("install.sh")
        original = hashlib.file_digest

        def change_file(stream, algorithm):
            digest = original(stream, algorithm)
            path.write_bytes(b"changed artifact")
            return digest

        with patch.object(release_manifest.hashlib, "file_digest", side_effect=change_file):
            with self.assertRaisesRegex(ValueError, "changed"):
                release_manifest.write_release_manifest(self.root, "1.2.3")
        self.assertFalse((self.root / "release.json").exists())
        self.assertFalse((self.root / "SHA256SUMS").exists())


if __name__ == "__main__":
    unittest.main()
