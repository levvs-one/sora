"""Verify signed assets; only the protected manual workflow may publish/promote."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

REPOSITORY = "levvs-one/sora"
PREFIX = f"repos/{REPOSITORY}"
ENVIRONMENT = "release"
METADATA = {"SHA256SUMS": 1048576, "SHA256SUMS.minisig": 8192, "release.json": 1048576}
RELEASE_FIELDS = "{id,tag_name,draft,prerelease,immutable,assets:[.assets[:19][]|{id,name,size,digest}]}"


def api(path, projection, *, policy=False, update=None):
    token = os.environ.get("SORA_RELEASE_POLICY_TOKEN" if policy else "GH_TOKEN", "")
    if not token:
        raise RuntimeError("required GitHub credential is not provisioned")
    command = ["gh", "api", "--hostname", "github.com", path, "--jq", projection]
    if update is not None:
        command += ["--method", "PATCH", "--input", "-"]
    result = subprocess.run(command, input=None if update is None else json.dumps(update).encode(),
                            env={**os.environ, "GH_TOKEN": token}, capture_output=True, timeout=30)
    if result.returncode or len(result.stdout) > 2 * 1024 * 1024:
        raise RuntimeError("GitHub could not confirm the required release policy or state")
    return json.loads(result.stdout)


def policy():
    repository = api(PREFIX, "{full_name,default_branch}")
    if repository != {"full_name": REPOSITORY, "default_branch": "main"}:
        raise RuntimeError("publication source must be the reviewed main branch of Sora")
    immutable = api(f"{PREFIX}/immutable-releases", "{enabled}", policy=True)
    if immutable.get("enabled") is not True:
        raise RuntimeError("release immutability is not enabled")
    environment = api(f"{PREFIX}/environments/{ENVIRONMENT}",
                      "{id,name,protection_rules,deployment_branch_policy}", policy=True)
    rules = [r for r in environment.get("protection_rules", []) if r.get("type") == "required_reviewers"]
    if (type(environment.get("id")) is not int or environment["id"] < 1 or environment.get("name") != ENVIRONMENT
            or len(rules) != 1 or rules[0].get("prevent_self_review") is not True):
        raise RuntimeError("release environment requires reviewers with self-review disabled")
    reviewers = rules[0].get("reviewers", [])
    if not 1 <= len(reviewers) <= 6 or any(r.get("type") != "User" or
            type(r.get("reviewer", {}).get("id")) is not int or r["reviewer"]["id"] < 1 for r in reviewers):
        raise RuntimeError("release reviewers must be explicit GitHub users")
    branches = api(f"{PREFIX}/environments/{ENVIRONMENT}/deployment-branch-policies",
                   "{total_count,branch_policies:[.branch_policies[]|{name,type}]}", policy=True)
    if (environment.get("deployment_branch_policy") != {"protected_branches": False, "custom_branch_policies": True}
            or branches != {"total_count": 1, "branch_policies": [{"name": "main", "type": "branch"}]}):
        raise RuntimeError("release deployment policy must select only the main branch")
    return environment["id"], {r["reviewer"]["id"] for r in reviewers}


def approved_run(environment_id, reviewers):
    if (os.environ.get("GITHUB_ACTIONS") != "true" or os.environ.get("GITHUB_REPOSITORY") != REPOSITORY
            or os.environ.get("GITHUB_REF") != "refs/heads/main"
            or os.environ.get("GITHUB_EVENT_NAME") != "workflow_dispatch"
            or os.environ.get("GITHUB_RUN_ATTEMPT") != "1"):
        raise RuntimeError("publication requires the first attempt of the protected manual workflow")
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    if not re.fullmatch(r"[1-9][0-9]{0,19}", run_id):
        raise RuntimeError("workflow run identity is missing")
    run = api(f"{PREFIX}/actions/runs/{run_id}", "{event,path,head_branch,head_sha,run_attempt,actor:{id:.actor.id}}")
    if (run.get("event") != "workflow_dispatch" or run.get("path") != ".github/workflows/release-gate.yml"
            or run.get("head_branch") != "main" or run.get("head_sha") != os.environ.get("GITHUB_SHA")
            or run.get("run_attempt") != 1 or type(run.get("actor", {}).get("id")) is not int
            or run["actor"]["id"] < 1):
        raise RuntimeError("workflow source or attempt could not be confirmed")
    reviews = api(f"{PREFIX}/actions/runs/{run_id}/approvals",
                  "[.[]|{state,environments:[.environments[]|{id}],user:{id:.user.id}}]")
    relevant = [r for r in reviews if any(e.get("id") == environment_id for e in r.get("environments", []))]
    if (any(r.get("state") == "rejected" for r in relevant) or not any(r.get("state") == "approved"
            and r.get("user", {}).get("id") in reviewers and r["user"]["id"] != run["actor"]["id"] for r in relevant)):
        raise RuntimeError("publication requires an actual approval by a different configured reviewer")


def tag_commit(tag):
    reference = api(f"{PREFIX}/git/ref/tags/{tag}", ".object|{type,sha}")
    for _ in range(5):
        sha = reference.get("sha", "")
        if not isinstance(sha, str) or not re.fullmatch(r"[0-9a-f]{40}", sha):
            break
        if reference.get("type") == "commit":
            return sha
        if reference.get("type") != "tag":
            break
        reference = api(f"{PREFIX}/git/tags/{sha}", ".object|{type,sha}")
    raise RuntimeError("release tag does not resolve to a bounded commit reference")


def asset_map(release):
    assets = release.get("assets")
    if not isinstance(assets, list) or len(assets) != 18:
        raise RuntimeError("release must contain exactly fifteen artifacts and three metadata files")
    result = {}
    for asset in assets:
        name, identifier, size, digest = (asset.get(k) for k in ("name", "id", "size", "digest"))
        if (not isinstance(name, str) or not 1 <= len(name) <= 255 or name in result
                or "/" in name or "\\" in name or type(identifier) is not int or identifier < 1
                or type(size) is not int or not 1 <= size <= 2147483648
                or not isinstance(digest, str) or not re.fullmatch(r"sha256:[0-9a-f]{64}", digest)):
            raise RuntimeError("release asset identity is invalid or ambiguous")
        result[name] = asset
    if len({a["id"] for a in result.values()}) != 18:
        raise RuntimeError("release asset IDs are not unique")
    return result


def download(asset, target, limit):
    token = os.environ.get("GH_TOKEN", "")
    if not re.fullmatch(r"[A-Za-z0-9_.-]{1,512}", token):
        raise RuntimeError("asset credential is missing or malformed")
    # curl drops Authorization across origins; never enable --location-trusted.
    config = f'header = "Authorization: Bearer {token}"\nheader = "Accept: application/octet-stream"\n'
    command = ["curl", "-q", "-fsSL", "--proto", "=https", "--proto-redir", "=https", "--connect-timeout", "15",
               "--max-time", "600", "--max-filesize", str(limit), "--config", "-", "--output", str(target),
               f"https://api.github.com/{PREFIX}/releases/assets/{asset['id']}"]
    result = subprocess.run(command, input=config.encode(), capture_output=True, timeout=615)
    if result.returncode or not target.is_file() or not 1 <= target.stat().st_size <= limit:
        raise RuntimeError("asset download failed or exceeded its bound")
    with target.open("rb") as stream:
        digest = "sha256:" + hashlib.file_digest(stream, "sha256").hexdigest()
    if digest != asset["digest"]:
        raise RuntimeError("downloaded bytes disagree with the GitHub asset identity")


def release_state(release, tag, stage):
    if (type(release.get("id")) is not int or release["id"] < 1 or release.get("tag_name") != tag
            or any(type(release.get(k)) is not bool for k in ("draft", "prerelease", "immutable"))):
        raise RuntimeError("release state is malformed")
    draft, prerelease, immutable = (release[k] for k in ("draft", "prerelease", "immutable"))
    if draft and immutable:
        raise RuntimeError("an immutable release cannot be a draft")
    if stage == "publish-prerelease" and not (draft or (prerelease and immutable)):
        raise RuntimeError("prerelease publication requires a draft or an already immutable prerelease")
    if stage == "promote" and (draft or not immutable):
        raise RuntimeError("promotion requires an already immutable published release")
    if stage == "verify" and not (draft or immutable):
        raise RuntimeError("a mutable published release cannot pass this gate")


def run(tag, commit, verifier, stage="verify", execute=False):
    version = tag[1:] if tag.startswith("v") else ""
    if (len(version) > 64 or not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", version)
            or not re.fullmatch(r"[0-9a-f]{40}", commit) or stage not in ("verify", "publish-prerelease", "promote")
            or (execute and stage == "verify")):
        raise RuntimeError("invalid release version, commit or publication mode")
    verifier = Path(verifier)
    if not verifier.is_absolute() or not verifier.is_file() or verifier.is_symlink():
        raise RuntimeError("a separately trusted absolute verifier path is required")
    curl = subprocess.run(["curl", "--version"], capture_output=True, text=True, check=True, timeout=10)
    match = re.match(r"curl ([0-9]+)\.([0-9]+)\.", curl.stdout)
    if not match or tuple(map(int, match.groups())) < (8, 4):
        raise RuntimeError("curl 8.4 or later is required for chunked-response bounds")
    environment_id, reviewers = policy()
    if execute:
        approved_run(environment_id, reviewers)
    if tag_commit(tag) != commit:
        raise RuntimeError("tag does not identify the approved source commit")
    release = api(f"{PREFIX}/releases/tags/{tag}", RELEASE_FIELDS)
    release_state(release, tag, stage)
    assets = asset_map(release)
    with tempfile.TemporaryDirectory(prefix="sora-release-gate-") as temporary:
        snapshot = Path(temporary)
        if verifier.resolve().is_relative_to(snapshot.resolve()):
            raise RuntimeError("a release cannot supply its own verifier")
        for name, bound in METADATA.items():
            if name not in assets:
                raise RuntimeError("signed release metadata is missing")
            download(assets[name], snapshot / name, bound)
        base = [str(verifier), "-verify-release", str(snapshot), "-release-version", version]
        checked = subprocess.run(base, capture_output=True, timeout=30)
        if checked.returncode:
            raise RuntimeError("native release authentication failed")
        metadata = json.loads((snapshot / "release.json").read_bytes())
        artifacts = metadata["artifacts"]
        if len(artifacts) != 15 or set(assets) != set(METADATA) | {a["name"] for a in artifacts}:
            raise RuntimeError("API asset set differs from the authenticated release matrix")
        for artifact in artifacts:
            download(assets[artifact["name"]], snapshot / artifact["name"], artifact["size"])
        checked = subprocess.run(base + ["-verify-release-files"], capture_output=True, timeout=600)
        if checked.returncode:
            raise RuntimeError("native full snapshot verification failed")
        current = api(f"{PREFIX}/releases/{release['id']}", RELEASE_FIELDS)
        if current != release or tag_commit(tag) != commit:
            raise RuntimeError("draft or tag changed during verification")
        if not execute:
            return "verified"
        # Recheck policy/approval immediately before any write. Draft races are
        # closed for stable promotion by checking the immutable result below.
        environment_id, reviewers = policy()
        approved_run(environment_id, reviewers)
        update = None
        if stage == "publish-prerelease" and release["draft"]:
            update = {"draft": False, "prerelease": True, "make_latest": "false"}
        elif stage == "promote" and release["prerelease"]:
            update = {"prerelease": False, "make_latest": "true"}
        if update is not None:
            api(f"{PREFIX}/releases/{release['id']}", RELEASE_FIELDS, update=update)
        frozen = api(f"{PREFIX}/releases/{release['id']}", RELEASE_FIELDS)
        if (frozen.get("id") != release["id"] or frozen.get("tag_name") != tag or frozen.get("draft") is not False
                or frozen.get("immutable") is not True or asset_map(frozen) != assets or tag_commit(tag) != commit
                or frozen.get("prerelease") is not (stage == "publish-prerelease")):
            raise RuntimeError("published state was not the verified immutable release; stable promotion refused")
    return "published immutable prerelease" if stage == "publish-prerelease" else "verified stable release"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--verifier", required=True)
    parser.add_argument("--stage", choices=("verify", "publish-prerelease", "promote"), default="verify")
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    try:
        result = run(args.tag, args.commit, args.verifier, args.stage, args.execute)
    except (RuntimeError, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        message = str(error) if isinstance(error, RuntimeError) else "release input or required tool failed validation"
        parser.exit(1, f"release gate refused: {message}\n")
    print(f"{REPOSITORY} {args.tag}: {result}")


if __name__ == "__main__":
    main()
