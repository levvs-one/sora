"""GitHub boundaries are simulated; the native signature/file verifier is real."""

import copy
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import gate


class ReleaseGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix="sora-gate-test-")
        cls.addClassCleanup(cls.temporary.cleanup)
        private = Path(cls.temporary.name)
        repo = Path(__file__).resolve().parents[2]
        fixture = json.loads((repo / "app/test/fixtures/releases/metadata.json").read_bytes())
        signed = fixture["releases"]["1.0.5"]
        cls.data = {"SHA256SUMS": signed["manifest"].encode(), "SHA256SUMS.minisig": signed["signature"].encode(),
                    "release.json": signed["metadata"].encode()}
        cls.data.update({a["name"]: b"abc" for a in json.loads(signed["metadata"])["artifacts"]})
        source = private / "core"
        shutil.copytree(repo / "core", source)
        release = source / "cmd/sora-core/release.go"
        text, count = re.subn(r'const releasePublicKey = "[^"]+"',
                             f'const releasePublicKey = "{fixture["public_key"]}"', release.read_text())
        if count != 1:
            raise ValueError("temporary public fixture root did not match exactly once")
        release.write_text(text)
        cls.verifier = private / ("verifier.exe" if os.name == "nt" else "verifier")
        subprocess.run(["go", "build", "-buildvcs=false", "-o", str(cls.verifier), "./cmd/sora-core"],
                       cwd=source, env={**os.environ, "CGO_ENABLED": "0"}, check=True, timeout=180)

    def setUp(self):
        self.commit = "a" * 40
        self.repository = {"full_name": gate.REPOSITORY, "default_branch": "main"}
        self.immutable = {"enabled": True}
        self.environment = {"id": 7, "name": "release", "protection_rules": [{"type": "required_reviewers",
                            "prevent_self_review": True, "reviewers": [{"type": "User", "reviewer": {"id": 2}}]}],
                            "deployment_branch_policy": {"protected_branches": False, "custom_branch_policies": True}}
        self.branches = {"total_count": 1, "branch_policies": [{"name": "main", "type": "branch"}]}
        self.workflow = {"event": "workflow_dispatch", "path": ".github/workflows/release-gate.yml",
                         "head_branch": "main", "head_sha": "b" * 40, "run_attempt": 1, "actor": {"id": 1}}
        self.reviews = [{"state": "approved", "environments": [{"id": 7}], "user": {"id": 2}}]
        self.release = {"id": 99, "tag_name": "v1.0.5", "draft": True, "prerelease": False, "immutable": False,
                        "assets": [{"id": i, "name": n, "size": len(d), "digest": "sha256:" + hashlib.sha256(d).hexdigest()}
                                   for i, (n, d) in enumerate(sorted(self.data.items()), 1)]}
        self.writes, self.downloads = [], []
        self.copies = dict(self.data)
        self.freeze_immutable = True
        self.change_draft = False

    def api(self, path, projection, *, policy=False, update=None):
        prefix = gate.PREFIX
        responses = {prefix: self.repository, f"{prefix}/immutable-releases": self.immutable,
                     f"{prefix}/environments/release": self.environment,
                     f"{prefix}/environments/release/deployment-branch-policies": self.branches,
                     f"{prefix}/actions/runs/123": self.workflow,
                     f"{prefix}/actions/runs/123/approvals": self.reviews,
                     f"{prefix}/git/ref/tags/v1.0.5": {"type": "commit", "sha": self.commit}}
        if path.startswith(f"{prefix}/environments/") or path.endswith("/immutable-releases"):
            self.assertTrue(policy)
        if path in (f"{prefix}/releases/tags/v1.0.5", f"{prefix}/releases/99"):
            if update is not None:
                self.writes.append(copy.deepcopy(update))
                self.release.update({k: v for k, v in update.items() if k != "make_latest"})
                self.release["immutable"] = self.freeze_immutable
            elif path.endswith("/99") and self.change_draft:
                self.release["assets"][0]["id"] += 100
            return copy.deepcopy(self.release)
        return copy.deepcopy(responses[path])

    def download(self, asset, target, limit):
        self.downloads.append((asset["name"], limit))
        target.write_bytes(self.copies[asset["name"]])

    def invoke(self, stage="verify", execute=False):
        environment = {"GITHUB_ACTIONS": "true", "GITHUB_REPOSITORY": gate.REPOSITORY,
                       "GITHUB_REF": "refs/heads/main", "GITHUB_EVENT_NAME": "workflow_dispatch",
                       "GITHUB_RUN_ATTEMPT": "1", "GITHUB_RUN_ID": "123", "GITHUB_SHA": "b" * 40}
        with patch.dict(os.environ, environment), patch.object(gate, "api", side_effect=self.api), \
                patch.object(gate, "download", side_effect=self.download):
            return gate.run("v1.0.5", "a" * 40, self.verifier, stage, execute)

    def test_real_signature_and_complete_snapshot(self):
        self.assertEqual(self.invoke(), "verified")
        self.assertEqual(len(self.downloads), 15)
        self.assertEqual(self.downloads[:3], list(gate.METADATA.items()))
        self.assertTrue(all(limit == 3 for _, limit in self.downloads[3:]))
        self.assertEqual(self.writes, [])

    def test_freeze_then_separate_promotion_and_idempotent_dispatch(self):
        self.assertEqual(self.invoke("publish-prerelease", True), "published immutable prerelease")
        self.assertEqual(self.writes, [{"draft": False, "prerelease": True, "make_latest": "false"}])
        self.writes.clear()
        self.assertEqual(self.invoke("publish-prerelease", True), "published immutable prerelease")
        self.assertEqual(self.writes, [])
        self.assertEqual(self.invoke("promote", True), "verified stable release")
        self.assertEqual(self.writes, [{"prerelease": False, "make_latest": "true"}])
        self.writes.clear()
        self.assertEqual(self.invoke("promote", True), "verified stable release")
        self.assertEqual(self.writes, [])

    def test_unprotected_policy_and_approvals_never_write(self):
        changes = {
            "immutability disabled": lambda: self.immutable.update(enabled=False),
            "wrong repo": lambda: self.repository.update(full_name="attacker/sora"),
            "self review allowed": lambda: self.environment["protection_rules"][0].update(prevent_self_review=False),
            "no reviewers": lambda: self.environment.update(protection_rules=[]),
            "team membership unverified": lambda: self.environment["protection_rules"][0]["reviewers"][0].update(type="Team"),
            "tag deployment allowed": lambda: self.branches["branch_policies"][0].update(type="tag"),
            "wildcard branch": lambda: self.branches["branch_policies"][0].update(name="*"),
            "bypassed approval": lambda: self.reviews.clear(),
            "self approval": lambda: self.reviews[0].update(user={"id": 1}),
            "unconfigured approver": lambda: self.reviews[0].update(user={"id": 3}),
            "other environment": lambda: self.reviews[0].update(environments=[{"id": 8}]),
            "rejected": lambda: self.reviews[0].update(state="rejected"),
            "rerun": lambda: self.workflow.update(run_attempt=2),
            "other workflow": lambda: self.workflow.update(path=".github/workflows/attacker.yml"),
            "other source": lambda: self.workflow.update(head_sha="c" * 40),
            "changed tag": lambda: setattr(self, "commit", "c" * 40),
            "mutable promotion": lambda: self.release.update(draft=False, prerelease=True),
        }
        for name, change in changes.items():
            with self.subTest(name=name):
                self.setUp()
                change()
                with self.assertRaises(RuntimeError):
                    self.invoke("promote" if name == "mutable promotion" else "publish-prerelease", True)
                self.assertEqual(self.writes, [])

    def test_real_crypto_rejections_stop_before_any_publication(self):
        for name in ("SHA256SUMS", "SHA256SUMS.minisig", "release.json", "install.sh"):
            with self.subTest(name=name):
                self.setUp()
                self.copies[name] += b"tampered"
                with self.assertRaises(RuntimeError):
                    self.invoke("publish-prerelease", True)
                self.assertEqual(self.writes, [])
                if name in gate.METADATA:
                    self.assertEqual(len(self.downloads), 3)

    def test_missing_extra_duplicate_and_malformed_assets_never_write(self):
        for problem in ("missing", "extra", "duplicate id", "duplicate name", "bad digest", "oversize", "directory"):
            with self.subTest(problem=problem):
                self.setUp()
                assets = self.release["assets"]
                if problem == "missing":
                    assets.pop()
                elif problem == "extra":
                    assets.append(copy.deepcopy(assets[0]))
                elif problem == "duplicate id":
                    assets[0]["id"] = assets[1]["id"]
                elif problem == "duplicate name":
                    assets[0]["name"] = assets[1]["name"]
                elif problem == "bad digest":
                    assets[0]["digest"] = None
                elif problem == "oversize":
                    assets[0]["size"] = 2147483649
                else:
                    assets[0]["name"] = "../evil"
                with self.assertRaises(RuntimeError):
                    self.invoke("publish-prerelease", True)
                self.assertEqual(self.writes, [])

    def test_mutation_and_unlocked_publication_cannot_promote(self):
        self.change_draft = True
        with self.assertRaisesRegex(RuntimeError, "changed during"):
            self.invoke("publish-prerelease", True)
        self.assertEqual(self.writes, [])
        self.setUp()
        self.freeze_immutable = False
        with self.assertRaisesRegex(RuntimeError, "immutable release"):
            self.invoke("publish-prerelease", True)
        self.assertEqual(self.writes, [{"draft": False, "prerelease": True, "make_latest": "false"}])
        with self.assertRaises(RuntimeError):
            self.invoke("promote", True)
        self.assertEqual(len(self.writes), 1)

    def test_invalid_request_cannot_reach_github(self):
        for tag, commit, verifier, stage, execute in (
                ("v01.0.5", "a" * 40, self.verifier, "verify", False),
                ("v1.0.5", "HEAD", self.verifier, "verify", False),
                ("v1.0.5", "a" * 40, "downloaded-verifier", "verify", False),
                ("v1.0.5", "a" * 40, self.verifier, "verify", True)):
            with self.subTest(tag=tag, commit=commit, verifier=verifier, execute=execute), \
                    patch.object(gate, "api") as api, self.assertRaises(RuntimeError):
                gate.run(tag, commit, verifier, stage, execute)
            api.assert_not_called()

    def test_policy_revocation_just_before_write(self):
        original = self.api
        reads = 0

        def revoked(path, projection, **kwargs):
            nonlocal reads
            if path.endswith("/immutable-releases"):
                reads += 1
                if reads == 2:
                    self.immutable["enabled"] = False
            return original(path, projection, **kwargs)

        with patch.object(self, "api", side_effect=revoked), self.assertRaisesRegex(RuntimeError, "not enabled"):
            self.invoke("publish-prerelease", True)
        self.assertEqual(len(self.downloads), 15)
        self.assertEqual(self.writes, [])

    def test_changed_tag_after_freeze_never_promotes(self):
        original = self.api

        def replaced(path, projection, **kwargs):
            result = original(path, projection, **kwargs)
            if kwargs.get("update") is not None:
                self.commit = "c" * 40
            return result

        with patch.object(self, "api", side_effect=replaced), self.assertRaisesRegex(RuntimeError, "promotion refused"):
            self.invoke("publish-prerelease", True)
        self.assertEqual(self.writes, [{"draft": False, "prerelease": True, "make_latest": "false"}])

    def test_annotated_tags_are_resolved_with_a_depth_bound(self):
        values = [{"type": "tag", "sha": "d" * 40}, {"type": "commit", "sha": self.commit}]
        with patch.object(gate, "api", side_effect=values):
            self.assertEqual(gate.tag_commit("v1.0.5"), self.commit)
        with patch.object(gate, "api", return_value={"type": "tag", "sha": "d" * 40}) as api, \
                self.assertRaises(RuntimeError):
            gate.tag_commit("v1.0.5")
        self.assertEqual(api.call_count, 6)


class TransportTests(unittest.TestCase):
    def test_untrusted_workflow_context_cannot_reach_github(self):
        expected = {"GITHUB_ACTIONS": "true", "GITHUB_REPOSITORY": gate.REPOSITORY,
                    "GITHUB_REF": "refs/heads/main", "GITHUB_EVENT_NAME": "workflow_dispatch",
                    "GITHUB_RUN_ATTEMPT": "1", "GITHUB_RUN_ID": "123"}
        for field in expected:
            with self.subTest(field=field), patch.dict(os.environ, {**expected, field: "untrusted"}), \
                    patch.object(gate, "api") as api, self.assertRaises(RuntimeError):
                gate.approved_run(7, {2})
            api.assert_not_called()

    def test_bounded_https_transport_keeps_token_out_of_arguments(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "asset"
            asset = {"id": 15, "digest": "sha256:" + hashlib.sha256(b"abc").hexdigest()}

            def curl(command, **kwargs):
                self.assertEqual(command[:4], ["curl", "-q", "-fsSL", "--proto"])
                self.assertNotIn("--location-trusted", command)
                self.assertIn("--proto-redir", command)
                self.assertEqual(command[command.index("--max-filesize") + 1], "3")
                self.assertNotIn("fixture-token", " ".join(command))
                self.assertIn(b"Authorization: Bearer fixture-token", kwargs["input"])
                self.assertEqual(command[-1], f"https://api.github.com/{gate.PREFIX}/releases/assets/15")
                target.write_bytes(b"abc")
                return subprocess.CompletedProcess(command, 0, b"", b"")

            with patch.dict(os.environ, GH_TOKEN="fixture-token"), patch.object(gate.subprocess, "run", side_effect=curl):
                gate.download(asset, target, 3)
            asset["digest"] = "sha256:" + "0" * 64
            with patch.dict(os.environ, GH_TOKEN="fixture-token"), patch.object(gate.subprocess, "run", side_effect=curl), \
                    self.assertRaisesRegex(RuntimeError, "identity"):
                gate.download(asset, target, 3)


if __name__ == "__main__":
    unittest.main()
