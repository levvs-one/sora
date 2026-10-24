import json
import os
from pathlib import Path
import re
import secrets
import subprocess
import tempfile
import unittest


class SecretScanExceptions(unittest.TestCase):
    def test_olcrtc_exception_requires_both_the_fixture_and_its_test_path(self):
        root = Path(__file__).resolve().parents[2]
        source = (root / "core/parser/olcrtc_test.go").read_text(encoding="utf-8")
        match = re.search(r'const olcKey = "([0-9a-f]{64})"', source)
        self.assertIsNotNone(match, "OLCRTC fixture changed; review its exception")
        fixture = match.group(1)
        cases = [
            ("core/parser/olcrtc_test.go", fixture, 0),
            ("core/parser/olcrtc_test.go", secrets.token_hex(32), 1),
            ("core/parser/olcrtc.go", fixture, 1),
            ("core/parser/unreviewed_test.go", fixture, 1),
        ]
        for path, value, expected in cases:
            with self.subTest(path=path, expected=expected):
                with tempfile.TemporaryDirectory(prefix="sora-gitleaks-") as tmp:
                    home = Path(tmp)
                    target = home / path
                    target.parent.mkdir(parents=True)
                    target.write_text(f'const key = "{value}"\n', encoding="utf-8")
                    report = home / "results.json"
                    result = subprocess.run(
                        [
                            os.environ.get("GITLEAKS_BIN", "gitleaks"),
                            "dir",
                            ".",
                            "--config", str(root / ".gitleaks.toml"),
                            "--redact=100",
                            "--no-banner",
                            "--log-level", "error",
                            "--report-format", "json",
                            "--report-path", str(report),
                        ],
                        cwd=home,
                        capture_output=True,
                        text=True,
                        timeout=30,
                        check=False,
                    )
                    self.assertEqual(result.returncode, expected, result.stderr)
                    findings = json.loads(report.read_text(encoding="utf-8"))
                    if expected:
                        self.assertIn("generic-api-key", [f["RuleID"] for f in findings])
                    else:
                        self.assertEqual(findings, [])


if __name__ == "__main__":
    unittest.main()
