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
  recalled, wait for a fix" notice in About. A recalled version is **not**
  rolled back automatically while it runs fine — recall is a warning, not a
  failure signal. Automatic rollback (S11b, below) only fires when a freshly
  installed update fails its post-update health check.

## Post-update health check and automatic rollback (S11b, Linux)

Every in-app update on Linux is rollback-protected. The mechanism is honest
by construction: it only ever claims what it verified, and every failure
mode degrades to "do nothing + tell the user" instead of a silent downgrade.

### The marker

After the privileged helper reports a successful install — right before the
app restarts into the new build — `AppUpdater.install()` writes a
`pendingUpdate` marker to settings:

```json
{"from": "1.2.3", "to": "1.3.0", "atMs": 1729471234567}
```

- `from` — the version being replaced, `to` — the version being installed,
  `atMs` — wall-clock time just before the restart.
- The marker is written **only** after the helper exited 0. It is deliberately
  not written before the handoff: on a slow machine installing two packages
  can take minutes, and a pre-handoff timestamp would look "stale" to the new
  build and trigger a bogus auto-rollback of a working install. Any earlier
  failure (no elevation, failed download, failed rollback-cache preparation,
  failed handoff) leaves no marker behind.
- A settings reset preserves the marker: it is a safety mechanism, not a
  preference, and resetting must not silently disarm it.

### The 60-second health check

After the restart, the new build sees the marker and opens a 60-second
window (`AppUpdater.healthCheckWindow`):

- **Health signal.** The app considers the core alive when `Sora.run()`
  completes the control-channel handshake: `CoreLink.open` plus successful
  `getStatus` and `getAbout` gRPC round-trips. A bare TCP connect is not
  enough — the core must actually answer the control channel. This is the
  same signal the app itself uses to leave the offline phase, so the check
  cannot "pass" while the UI still shows the core as down.
- If the signal arrives in time, the marker is cleared and the update is
  accepted. The check is silent on success.
- If the app crashed before clearing the marker, the next launch finds a
  **stale** marker (`now - atMs > 60 s`) and goes straight to rollback —
  no fresh window, no waiting.
- A corrupt marker, or a marker naming a build other than the running one
  (update never landed, manual reinstall), is cleared silently: its premise
  is void and it must never trigger a downgrade.

### The rollback

When the window expires (or the marker is stale), the app rolls back to
`from`:

1. The pre-update packages come from a **rollback cache** prepared at update
   time: `~/.cache/sora/rollback/<from>/` (or `$XDG_CACHE_HOME`), holding
   both packages plus that release's `SHA256SUMS` and `SHA256SUMS.minisig`.
   The cache is hash-verified when downloaded, so the rollback works
   **offline** — re-downloading at rollback time would fail exactly when
   the network is unusable.
2. Before invoking the helper, the app **re-verifies** every cached package
   against the cached manifest (fail-closed: the cache lived on
   user-writable disk since download). Any mismatch → no rollback, error
   plus a manual reinstall command in About.
3. The install goes through the same privileged helper with
   `--allow-downgrade`; the helper re-verifies the manifest **signature as
   root** before trusting any hash (SORA-H1), same as for upgrades.
4. On success the marker is cleared, a persistent "rolled back to X" notice
   is stored, and the app restarts into the old build.

Fail-closed rules:

- No verified cache → no rollback (error + manual command, no pkexec).
- No elevation → no rollback (manual command shown instead).
- Helper failure → no retry loop: the marker is cleared so a broken updater
  cannot downgrade on every launch; the error stays visible in About.
- A rollback never fires for a healthy install: the core-health gate is
  re-checked immediately before invoking the helper.

Preparing the cache is mandatory: if the previous release's packages cannot
be downloaded and hash-verified, the **update itself is aborted** with
`updateRollbackCacheError`. Installing without a rollback path is not an
option once the safety net is promised. Cost: the update downloads roughly
twice the packages (old + new), and the cache occupies disk until the next
update replaces it.

### Known limitations

- **The app must be able to start.** If the new build crashes before
  `checkPendingUpdate` runs, no automatic rollback happens — a program that
  cannot run cannot repair itself. This is a documented limitation, not a
  gap to paper over.
- **Manual rollback** (when auto-rollback cannot run): download the previous
  release's packages from the GitHub Releases page, verify `SHA256SUMS`
  (and the `.minisig` signature once the key ceremony is done), then install
  for your distro — e.g. `sudo dpkg -i sora-core_<ver>_amd64.deb
  sora_<ver>_amd64.deb`, `sudo dnf install ./sora-core-<ver>-1.x86_64.rpm
  ./sora-<ver>-1.x86_64.rpm`, or `sudo pacman -U
  sora-core-<ver>-1-x86_64.pkg.tar.zst sora-<ver>-1-x86_64.pkg.tar.zst`.
  The stale `pendingUpdate` marker is harmless: the reinstalled old build
  sees `marker.to != version` and clears it silently.
- **Windows:** the in-app update path is blocked fail-closed (A2), so no
  marker is ever written and rollback does not apply. Reinstall the previous
  `Sora-Setup-<ver>-x64.exe` by hand if needed.

### Validation checklist before pushing the feed

- `python3 -c "import json; json.load(open('updates/releases.json'))"` parses.
- `"format": 1`.
- `rollout.version` exactly matches the GitHub release tag (modulo the `v`).
- `0 <= percent <= 100`, integer.
- Every `blocked_versions` entry is a valid `x.y.z`.

## Known limitations

- **Manual install on openSUSE (zypper):** when the privileged helper is not
  available, the app prints a manual fallback command built from the same
  arguments the helper uses — plain `zypper --non-interactive install` with
  GPG signature verification intact, matching the helper (SORA-H1). The app
  does not silently weaken verification on the fallback path, so the RPMs
  must be GPG-signed; the release-signing key ceremony is still pending
  (owner blocker). Until it is done, installing on openSUSE requires either
  the privileged helper or a deliberate manual `zypper install
  --allow-unsigned-rpm` by the user.
- **Metered connections:** not implemented. The codebase has no honest
  metered-link signal on any platform, so a "don't download on metered"
  setting would be unenforceable theater. Cut from scope deliberately.
- The feed is fetched over plain HTTPS from `raw.githubusercontent.com`;
  integrity of the *policy* rests on TLS. This does not weaken artifact
  integrity: hashes/signatures are still verified against the GitHub release.
- Release-signature verification in-app is still pending (key ceremony —
  owner blocker, out of scope here).
