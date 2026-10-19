#!/usr/bin/env python3
"""CI gate: uTLS + reference-JA4 freshness (S3).

Fingerprint freshness is a process, not a flag: the pinned
refraction-networking/utls can go stale (Chrome 133 was blocked by TSPU in
Oct 2026 while the "chrome" alias still pointed at it), and a new Chrome
stable release can obsolete the reference JA4 overnight.

Three checks, stdlib only:
  A. utls lag: pinned utls commit (from core/go.mod) vs upstream
     default-branch tip (api.github.com). Fails when the pinned commit is
     older than S3_LAG_LIMIT_DAYS (default 30) behind the tip.
  B. reference JA4: current Chrome stable (Google Version History API) vs
     known_ja4.json chrome_version. Fails when Chrome stable moved past the
     fixture: the "chrome" parrot in utls may now be stale and the JA4
     reference must be re-measured against branded Chrome.
  C. fixture/code consistency: known_ja4.json must agree with
     core/engine/fingerprint.go (CurrentChromeVersion / ReferenceChromeJA4).
     A drift means someone updated one and forgot the other.

Exit 0: fresh. Exit 1: stale (or unknown — an INFRA/network failure is not
a pass, it is a re-run signal). The job is meant to fail loudly, never to
warn silently.

Env overrides (used to simulate a red job locally):
  S3_GOMOD, S3_FINGERPRINT_GO, S3_KNOWN_JA4 — alternate input paths
  S3_LAG_LIMIT_DAYS — alternate lag limit (e.g. -1 forces check A red)

`python3 check.py --selftest` runs offline unit checks, no network.
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))

UTLS_MODULE = "github.com/refraction-networking/utls"
UTLS_TIP_URL = "https://api.github.com/repos/refraction-networking/utls/commits/HEAD"
CHROME_STABLE_URL = (
    "https://versionhistory.googleapis.com/v1/chrome/platforms/linux/"
    "channels/stable/versions?page_size=1"
)

PSEUDO_RE = re.compile(r"^v\d+\.\d+\.\d+-0\.(\d{14})-([0-9a-f]{12,40})$")
VERSION_LINE_RE = re.compile(
    r"(?m)^\s*" + re.escape(UTLS_MODULE) + r"\s+(\S+)"
)
CHROME_VER_RE = re.compile(r"CurrentChromeVersion\s*=\s*(\d+)")
REF_JA4_RE = re.compile(r'ReferenceChromeJA4\s*=\s*"([^"]+)"')


class FreshnessError(Exception):
    """Stale fingerprint knowledge: the job must fail."""


class InfraError(FreshnessError):
    """Could not determine freshness: re-run, do not treat as a pass."""


def get_json(url: str) -> dict:
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "sora-utls-freshness-ci/1.0",
        },
    )
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return json.load(resp)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError,
            OSError) as exc:
        raise InfraError(
            "INFRA: network error fetching %s: %s\n"
            "       Re-run the job; this is NOT a freshness verdict."
            % (url, exc)
        )


def parse_iso8601(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def pinned_utls(gomod_path: str) -> tuple[str, datetime, str]:
    """Return (version, commit_time_utc, short_sha) of the pinned utls."""
    try:
        text = open(gomod_path, encoding="utf-8").read()
    except OSError as exc:
        raise InfraError("INFRA: cannot read %s: %s" % (gomod_path, exc))
    line = VERSION_LINE_RE.search(text)
    if not line:
        raise InfraError("INFRA: %s not found in %s" % (UTLS_MODULE, gomod_path))
    version = line.group(1)
    pseudo = PSEUDO_RE.match(version)
    if not pseudo:
        # A release-tag pin carries no commit timestamp; the lag gate cannot
        # date it. Fail honestly with the fix, do not guess.
        raise InfraError(
            "INFRA: pinned utls version %s is not a pseudo-version, so its "
            "commit time is unknown.\n"
            "       Extend check.py (resolve the tag via the GitHub API) or "
            "pin a pseudo-version." % version
        )
    commit_time = datetime.strptime(pseudo.group(1), "%Y%m%d%H%M%S").replace(
        tzinfo=timezone.utc
    )
    return version, commit_time, pseudo.group(2)


def check_utls_lag(gomod_path: str, limit_days: int) -> str:
    version, pinned_time, pinned_sha = pinned_utls(gomod_path)
    tip = get_json(UTLS_TIP_URL)
    try:
        tip_sha = tip["sha"]
        tip_time = parse_iso8601(tip["commit"]["committer"]["date"])
    except (KeyError, TypeError, ValueError) as exc:
        raise InfraError(
            "INFRA: unexpected GitHub API shape for utls tip: %s" % exc
        )
    lag_days = (tip_time - pinned_time).total_seconds() / 86400
    report = (
        "utls: pinned %s (%s, %s) vs upstream tip %s (%s): lag %.1f days "
        "(limit %d)" % (
            version, pinned_sha, pinned_time.strftime("%Y-%m-%d"),
            tip_sha[:12], tip_time.strftime("%Y-%m-%d"), lag_days, limit_days,
        )
    )
    if lag_days > limit_days:
        raise FreshnessError(
            "FAIL: %s\n"
            "       Pinned utls is stale. Bump %s in core/go.mod (go get "
            "%s@<new>), then re-verify that utls HelloChrome_Auto still "
            "matches the reference JA4 (run the JA4 self-check and, if "
            "Chrome moved, re-measure known_ja4.json against branded "
            "Chrome). See .github/utls-freshness/README.md."
            % (report, UTLS_MODULE, UTLS_MODULE)
        )
    return "ok: " + report


def chrome_major(version: str) -> int:
    major = version.split(".", 1)[0]
    if not major.isdigit():
        raise InfraError("INFRA: cannot parse Chrome version %r" % version)
    return int(major)


def check_chrome_stable(known_ja4_path: str) -> str:
    try:
        fixture = json.load(open(known_ja4_path, encoding="utf-8"))
        recorded = int(fixture["chrome_stable"]["chrome_version"])
        recorded_ja4 = fixture["chrome_stable"]["ja4"]
    except (OSError, KeyError, TypeError, ValueError) as exc:
        raise InfraError(
            "INFRA: cannot parse %s: %s" % (known_ja4_path, exc)
        )
    data = get_json(CHROME_STABLE_URL)
    try:
        stable = data["versions"][0]["version"]
    except (KeyError, TypeError, IndexError) as exc:
        raise InfraError(
            "INFRA: unexpected Version History API shape: %s" % exc
        )
    stable_major = chrome_major(stable)
    report = "chrome: stable %s vs reference fixture %d (JA4 %s)" % (
        stable, recorded, recorded_ja4,
    )
    if stable_major > recorded:
        raise FreshnessError(
            "FAIL: %s\n"
            "       Chrome stable moved past the reference. Re-measure the "
            "reference JA4 against branded Chrome %d, verify upstream utls "
            "has a matching HelloChrome_%d parrot (bump utls if not), then "
            "update known_ja4.json AND core/engine/fingerprint.go "
            "(CurrentChromeParrot/CurrentChromeVersion/ReferenceChromeJA4). "
            "Until then the \"chrome\" fingerprint may be stale — exactly "
            "how Chrome 133 got blocked by TSPU in Oct 2026."
            % (report, stable_major, stable_major)
        )
    return "ok: " + report


def check_fixture_consistency(known_ja4_path: str, fingerprint_go_path: str) -> str:
    try:
        fixture = json.load(open(known_ja4_path, encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise InfraError(
            "INFRA: cannot parse %s: %s" % (known_ja4_path, exc)
        )
    try:
        go_src = open(fingerprint_go_path, encoding="utf-8").read()
    except OSError as exc:
        raise InfraError(
            "INFRA: cannot read %s: %s" % (fingerprint_go_path, exc)
        )
    ver = CHROME_VER_RE.search(go_src)
    ja4 = REF_JA4_RE.search(go_src)
    if not ver or not ja4:
        raise InfraError(
            "INFRA: CurrentChromeVersion/ReferenceChromeJA4 not found in %s"
            % fingerprint_go_path
        )
    problems = []
    if int(ver.group(1)) != int(fixture["chrome_stable"]["chrome_version"]):
        problems.append(
            "chrome_version: fixture=%s vs fingerprint.go=%s"
            % (fixture["chrome_stable"]["chrome_version"], ver.group(1))
        )
    if ja4.group(1) != fixture["chrome_stable"]["ja4"]:
        problems.append(
            "ja4: fixture=%s vs fingerprint.go=%s"
            % (fixture["chrome_stable"]["ja4"], ja4.group(1))
        )
    if problems:
        raise FreshnessError(
            "FAIL: known_ja4.json drifted from core/engine/fingerprint.go:\n"
            "       " + "\n       ".join(problems) + "\n"
            "       Update both together (and engines.lock when the parrot "
            "changes)."
        )
    return "ok: known_ja4.json matches core/engine/fingerprint.go"


def selftest() -> None:
    # Offline: parsing, regexes, and the fixture<->code consistency check.
    sample = (
        "module example\n\nrequire (\n"
        "\tgithub.com/refraction-networking/utls v1.8.3-0.20261006222701-ff1b50fbbe9a\n"
        ")\n"
    )
    assert PSEUDO_RE.match("v1.8.3-0.20261006222701-ff1b50fbbe9a"), "pseudo parse"
    assert not PSEUDO_RE.match("v1.8.3"), "tag must not match pseudo"
    m = VERSION_LINE_RE.search(sample)
    assert m and m.group(1) == "v1.8.3-0.20261006222701-ff1b50fbbe9a", "go.mod line"
    assert chrome_major("155.0.8059.84") == 155, "chrome major"
    assert chrome_major("156.0.1.2") == 156, "chrome major rollover"
    print(check_fixture_consistency(
        os.environ.get("S3_KNOWN_JA4",
                       os.path.join(SCRIPT_DIR, "known_ja4.json")),
        os.environ.get("S3_FINGERPRINT_GO",
                       os.path.join(REPO_ROOT, "core", "engine", "fingerprint.go")),
    ))
    print("selftest OK (offline)")


def main() -> int:
    if "--selftest" in sys.argv[1:]:
        try:
            selftest()
        except FreshnessError as exc:
            print(exc, file=sys.stderr)
            return 1
        return 0

    gomod = os.environ.get("S3_GOMOD",
                           os.path.join(REPO_ROOT, "core", "go.mod"))
    fingerprint_go = os.environ.get("S3_FINGERPRINT_GO",
                                    os.path.join(REPO_ROOT, "core", "engine",
                                                 "fingerprint.go"))
    known_ja4 = os.environ.get("S3_KNOWN_JA4",
                               os.path.join(SCRIPT_DIR, "known_ja4.json"))
    try:
        limit_days = int(os.environ.get("S3_LAG_LIMIT_DAYS", "30"))
    except ValueError:
        print("INFRA: S3_LAG_LIMIT_DAYS is not an integer", file=sys.stderr)
        return 1

    try:
        print(check_fixture_consistency(known_ja4, fingerprint_go))
        print(check_chrome_stable(known_ja4))
        print(check_utls_lag(gomod, limit_days))
    except FreshnessError as exc:
        print(exc, file=sys.stderr)
        return 1
    print("utls freshness: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
