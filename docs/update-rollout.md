# Staged rollout for updates (S11a)

`updates/releases.json` in this repo is the **policy feed** for in-app updates.
The client fetches it from

```
https://raw.githubusercontent.com/levvs-one/sora/main/updates/releases.json
```

on every update check (every 12 h and on manual check), right after reading
the GitHub Releases API.

## What the feed is — and is not

- The feed carries **policy only**: which installs are offered a release
  (`rollout.percent`), and which versions are recalled (`blocked_versions`).
- **Artifacts, hashes and signatures always come from the GitHub release.**
  The feed can never substitute artifact URLs or hashes. A policy whose
  `rollout.version` does not match the release reported by the GitHub API is
  ignored entirely (fail-closed).

## Format (v1)

```json
{
  "format": 1,
  "rollout": {
    "version": "1.2.3",
    "percent": 10
  },
  "blocked_versions": ["1.2.1"]
}
```

- `format` must be `1`. Anything else → the feed is ignored.
- `rollout.version` — the release this policy applies to. Compared
  normalized (`v1.2.3` and `1.2.3` are the same); must be a valid `x.y.z`.
- `rollout.percent` — integer 0–100. Each install has a stable cohort
  (`SHA-256(installUuid) mod 100`, `installUuid` is generated once and stored
  in app settings); the update is offered iff `cohort < percent`.
  `percent: 100` = everyone (status quo), `percent: 0` = nobody (pause).
- `blocked_versions` — recalled versions. A **candidate** in the list is never
  offered to anyone. An **installed** version in the list triggers a persistent,
  calm in-app warning ("this version has been recalled, wait for a fix") —
  no panic, no auto-downgrade.
- Unknown fields are ignored. Any malformed value (bad JSON, wrong types,
  `percent` outside 0–100, unparsable version) invalidates the whole feed.

## Client decision table

| Feed state | Behavior |
|---|---|
| Unreachable (network error, 404, timeout) | Legacy behavior: the update is offered to everyone. Logged as a fallback — a missing feed must not brick updates. |
| Fetched but malformed | **Fail-closed: the update is NOT offered this round.** Logged. A corrupt policy channel must not silently degrade to "offer to all" and bypass an intended kill-switch. Fix the JSON; the next check retries. |
| Parsed, but `rollout.version` ≠ GitHub release | Policy ignored (fail-closed): the update is NOT offered. The feed must not steer a release it does not name. |
| Parsed and version matches | Candidate in `blocked_versions` → never offered (kill-switch). Otherwise offered iff `cohort < percent`. Installed version in `blocked_versions` → persistent "recalled" warning in About. |

Every branch is logged with the `[updates]` tag.

## Owner runbook

### Publishing a release gradually

1. Publish the GitHub release as usual (tag `vX.Y.Z`).
2. In the **same** change, update `updates/releases.json`:
   `rollout.version` = `X.Y.Z` (no `v` needed, tolerated), `percent` = `1`.
3. Watch for crash/error reports, then raise `percent`: `1 → 10 → 50 → 100`.
   Leave hours between steps for a desktop app audience.
4. `percent: 100` means the rollout is complete.

If you publish the release but forget the feed, clients keep the old policy:
a policy naming a different version is ignored and the new release is **not**
offered until the feed names it. This is deliberate (fail-closed).

### Pulling the kill-switch

Add the bad version to `blocked_versions` and push to `main`:

```json
{ "format": 1,
  "rollout": { "version": "1.2.3", "percent": 0 },
  "blocked_versions": ["1.2.3"] }
```

- Clients stop offering `1.2.3` on their next check (≤ 12 h, or immediately on
  manual check).
- Installs already on `1.2.3` see a persistent "this version has been
  recalled, wait for a fix" notice in About. There is no auto-rollback
  (separate workstream S11b).

### Validation checklist before pushing the feed

- `python3 -c "import json; json.load(open('updates/releases.json'))"` parses.
- `"format": 1`.
- `rollout.version` exactly matches the GitHub release tag (modulo the `v`).
- `0 <= percent <= 100`, integer.
- Every `blocked_versions` entry is a valid `x.y.z`.

## Known limitations

- **Metered connections:** not implemented. The codebase has no honest
  metered-link signal on any platform, so a "don't download on metered"
  setting would be unenforceable theater. Cut from scope deliberately.
- The feed is fetched over plain HTTPS from `raw.githubusercontent.com`;
  integrity of the *policy* rests on TLS. This does not weaken artifact
  integrity: hashes/signatures are still verified against the GitHub release.
- Release-signature verification in-app is still pending (key ceremony —
  owner blocker, out of scope here).
