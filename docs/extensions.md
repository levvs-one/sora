# Sora extension manifest v1

This document is the normative spec for Sora extensions (feature F10).
Reference implementation: `core/ext` (Go). The app mirrors it in Dart
(`app/lib/src/ext`).

**Developer guides:** [your first extension in 10
minutes](extensions-quickstart.md), [`window.soraExt` API
reference](extensions-api.md), [cookbook](extensions-cookbook.md), [dev
mode](extensions-devmode.md). Tooling: `tools/sora-ext` (`sora-ext
scaffold|validate|pack|sign|keygen|publish|dev|serve`).

## 1. Package layout

A `.soraext` file is a ZIP archive:

```
sora-extension.json   # manifest v1 (this document)
checksums.txt         # "sha256hex  path" per line, paths sorted
signature.minisig     # minisign signature over checksums.txt
panel.html            # first panel entry (example)
assets/...            # icons, css, images
```

Limits: archive ≤ 64 MiB, ≤ 4096 files, ≤ 256 MiB uncompressed, one file
≤ 32 MiB. Paths must be relative, forward-slash, without `..`.

### 1.1 checksums.txt

One line per content file: `<lowercase sha256 hex><two spaces><path>`,
sorted by path (the reference packager emits sorted order; verification
accepts any order). It lists every file **except** itself and
`signature.minisig` (neither can checksum itself).

### 1.2 signature.minisig

A minisign-format signature made with the author's key. The signed trusted
comment is:

```
timestamp:<unix-seconds>\tfile:checksums.txt\tsha256:<hex of checksums.txt>
```

Verification (see `core/ext/sign.go`):

1. Parse the minisig (untrusted comment line + base64 blob).
2. Parse the trusted comment; require `file:checksums.txt`.
3. `sha256(checksums.txt bytes)` must equal the claimed sha256 (constant time).
4. Ed25519-verify the trusted comment bytes with the author's public key
   from the manifest.

Flipping any byte anywhere breaks step 3 or 4. The minisign public key
format is the standard one: base64 of `"Ed" || key_id(8) || pubkey(32)`.

## 2. Manifest fields

```json
{
  "manifest_version": 1,
  "id": "com.example.speedstats",
  "name": "Speed Stats",
  "version": "1.2.0",
  "min_app_version": "1.9.0",
  "description": "Live connection statistics in a panel.",
  "author": {
    "name": "Jane Doe",
    "identity": "github:janedoe",
    "public_key": "RWR...base64 of Ed||keyid||pubkey..."
  },
  "permissions": ["connections.read", "notifications"],
  "capabilities": ["ui-panel"],
  "ui": {
    "panels": [
      {"id": "main", "title": "Statistics", "entry": "panel.html"}
    ]
  },
  "settings_schema": {
    "type": "object",
    "properties": {
      "refresh_seconds": {"type": "integer", "minimum": 1, "maximum": 60, "default": 5},
      "theme": {"type": "string", "enum": ["dark", "light"], "default": "dark"}
    }
  }
}
```

Rules:

- `manifest_version` must be `1`. Unknown top-level fields are rejected.
- `id`: reverse-DNS, at least two labels (`com.example.stats`).
- `version`, `min_app_version`: semver `MAJOR.MINOR.PATCH`.
- The app enforces `min_app_version` against its own version, injected at
  build time: `flutter build --dart-define=APP_VERSION=$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d+ -f1)`.
  Dev builds without the define skip the gate instead of guessing.
- `permissions`: subset of the registry below, no duplicates.
- `capabilities`: subset of `theme`, `network-hook`, `routing`, `ui-panel`,
  `background`, `widget`.
- Panel `entry`: relative `.html` path, no traversal.
- `settings_schema`: JSON-Schema subset — object with typed properties
  (`string`, `integer`, `number`, `boolean`; optional `enum`, `minimum`,
  `maximum`, `minLength`, `maxLength`, `default`). The app auto-generates the
  settings form from it.
- `background_task`, `network_hosts`: optional v2-runtime keys, see §7.
  Manifest version stays `1`: they are additive, and old manifests without
  them parse exactly as before. Unknown keys — including unknown keys
  *inside* `background_task` — are still rejected.
- `theme`, `network_hook`, `routing`: optional capability-contract pointers,
  see §8. Same additive rules: manifest version stays `1`, unknown inner
  keys are rejected, and each requires its capability + permission.

## 3. Permissions (v1 registry)

| Permission         | Sees / can do                                  | Risk       |
|--------------------|------------------------------------------------|------------|
| `connections.read` | Live connection list (process, host, counters) | sensitive  |
| `servers.read`     | Server list (names, countries, latency)        | normal     |
| `settings.read`    | Read app settings                              | normal     |
| `settings.write`   | Change app settings                            | sensitive  |
| `notifications`    | Show notifications                             | normal     |
| `tray`             | Tray menu entries (runtime v2)                 | normal     |
| `ui.panel`         | Embed panels in the app                        | normal     |
| `theme.apply`      | Apply theme assets                             | sensitive  |
| `routing.rules`    | Contribute routing rules                       | dangerous  |
| `net.hooks`        | Network hooks / DPI-bypass modules             | dangerous  |
| `net.fetch`        | Fetch URLs (host allowlist, runtime v2)        | sensitive  |
| `background`       | Background tasks (runtime v2)                  | sensitive  |

Dangerous permissions need an explicit confirmation on the install prompt.
Updates that widen permissions re-prompt. Extensions can never read
subscription credentials: there is no permission for it.

## 4. Panel runtime (v1)

Panels are plain HTML/JS loaded in a WebView **without** Node and without
`dart:ffi`/`dart:io`. The only bridge to the app is `window.soraExt`:

```js
// Promise-based, methods are allow-listed per granted permission.
const conns = await window.soraExt.call('getConnections');
await window.soraExt.call('notify', {title: 'Hi', body: '...'});
const settings = await window.soraExt.call('getSettings');
await window.soraExt.call('setSettings', {refresh_seconds: 10});
window.soraExt.onEvent((kind, detail) => { /* session.connected ... */ });
```

Available methods and their permissions:

| Method             | Permission         | Notes                              |
|--------------------|--------------------|------------------------------------|
| `getConnections`   | `connections.read` | id, process, host, up/down bytes   |
| `getServers`       | `servers.read`     | id, name, country, latency         |
| `notify`           | `notifications`    | title ≤ 120, body ≤ 500 chars      |
| `getSettings`      | —                  | the extension's own settings       |
| `setSettings`      | —                  | validated against settings_schema  |

Events: `session.connected`, `session.disconnected`, `network.changed`,
`extension.disabled` (the panel is torn down right after).

Calling a method without the permission rejects the promise. Navigation
outside the package is blocked; `fetch`/`XMLHttpRequest` from panel JS have
no network access in v1.

## 5. Catalog

The team catalog is `catalog.json` plus `catalog.json.minisig` (minisign,
team key; trusted comment `timestamp:..\tfile:catalog.json\tsha256:..`).
Shape:

```json
{
  "catalog_version": 1,
  "updated_at": "2026-10-19T12:00:00Z",
  "max_age": 3600,
  "extensions": [
    {
      "id": "com.example.speedstats",
      "name": "Speed Stats",
      "version": "1.2.0",
      "description": "...",
      "author": "Jane Doe",
      "author_identity": "github:janedoe",
      "author_key": "RWR...",
      "icon_url": "https://...",
      "rating": 4.7,
      "ratings_count": 128,
      "installs": 5210,
      "badges": ["verified"],
      "categories": ["tools"],
      "capabilities": ["ui-panel"],
      "permissions": ["connections.read"],
      "download_url": "https://...",
      "sha256": "<hex of the .soraext>",
      "size": 48210,
      "min_app_version": "1.9.0",
      "rollout_fraction": 1.0,
      "screenshots": ["https://.../shot1.png"],
      "changelog": [
        {"version": "1.2.0", "date": "2026-10-19T12:00:00Z", "notes": "..."}
      ]
    }
  ]
}
```

Badges: `verified` (reviewed by the Sora team), `top` (top of the week),
`new`, `staff` (built by the Sora team). URLs must be https. Catalog
installs verify the downloaded `.soraext` sha256 against the entry, then run
the normal package verification.

Additive catalog fields (all optional):

- `max_age` (300..604800 s, default 3600): the server's freshness promise.
  Clients may serve the offline cache within `max_age`; past it they must
  try to revalidate, and say "cached - <date>" when serving stale data.
- `rollout_fraction` (0..1, default 1): staged rollout of a version.
  Eligibility is deterministic per install:
  `sha256(install_id | ext id | version)` mod 10000 < fraction·10000.
  The update button shows only for eligible installs; the listing is never
  gated. A bad version is halted via the revocation list, not a zero
  fraction.
- `screenshots`: ≤ 8 https image URLs for the detail page.
- `changelog`: version/date(RFC3339)/notes rows, newest first.
- `capabilities`: subset of the manifest capability registry; the store
  filters on these ("Themes", "Bypasses & network hooks", ...).

The rating methodology (Bayesian average, freshness decay, one vote per
account) is specified separately; the catalog carries the finished
`rating` / `ratings_count` / `installs` numbers. Revocation uses
`revocations.json` + `.minisig` (same team key): see the abuse-handling
spec. Until the team key ceremony, every team-signature check fails
closed and the app shows an honest "catalog coming soon" state.

## 6. Trust notes

- Sideloaded packages (file/URL) are verified against the **author's own
  key** from the manifest — self-attested. The app shows an explicit
  "not from the catalog" warning.
- Catalog packages are verified against the catalog-pinned author key, and
  the catalog itself against the team key.
- The team key is a placeholder until the owner completes the key ceremony;
  catalog checks fail closed until then.
- Revocation: removing an entry from the catalog stops new installs; the app
  can additionally blocklist ids (wave 4: OCSP-style revocation list).

## 7. Background workers & net.fetch (runtime v2)

Manifest version stays `1`: these are additive optional keys parsed by
`ParseManifestFull` (`core/ext/manifest_v1ext.go`); the frozen v1 decoder is
untouched.

```json
{
  "manifest_version": 1,
  "id": "com.example.syncer",
  "...": "...",
  "capabilities": ["background"],
  "permissions": ["background", "net.fetch"],
  "background_task": {"interval_minutes": 60, "entry": "worker.js"},
  "network_hosts": ["api.example.com", "*.cdn.example.com"]
}
```

### 7.1 background_task

Declares one periodic background task. Requires the `background`
capability **and** the `background` permission; without either the manifest
is rejected.

- `interval_minutes`: desired period in whole minutes, 1..10080 (7 days).
  The runtime **clamps** the effective interval into [15 min, 7 days]:
  a manifest asking for 1 minute runs every 15 minutes. The 15-minute
  floor keeps a buggy or hostile extension from hot-looping the device.
- `entry`: the worker script inside the package — a relative `.js` path,
  no traversal.

The worker runs in a deliberately small environment (`WorkerEnv`): it can
append to the extension log and — only when the extension also holds
`net.fetch` — make allowlisted HTTP requests through its own `Fetcher`.
No filesystem, no process control, no raw sockets. (The Go `WorkerFunc` is
the seam where the host plugs its JS runner in. Implementation status:
the scheduler and `net.fetch` enforcement exist in `core/ext`, but no
host — neither the app nor the service — schedules workers yet, so worker
scripts do not execute in practice; the app currently only persists the
`background_task` config the user edits in the extension details screen.)

Every run's outcome — ok, failed, or panicked (recovered) — is written to
the extension log, which the app shows in the extension details screen.

### 7.2 network_hosts — the net.fetch allowlist

Host allowlist for `net.fetch`. Requires the `net.fetch` permission (named
`network` in the wave-4 plan; the v1 permission registry already reserves
`net.fetch` for exactly this, so no new permission was added).

- Entries are lowercase DNS names (`api.example.com`) or wildcards
  (`*.example.com`). Max 64 entries, no duplicates, no IP literals, no
  schemes/ports/paths.
- Matching is strict: `api.example.com` matches **only itself** —
  `sub.api.example.com` is denied. `*.example.com` matches subdomains
  (`a.b.example.com`) but **not** the bare `example.com`, and not
  lookalikes (`evilexample.com`).

Host-side enforcement (`core/ext/netfetch.go`):

- https only; no userinfo; no IP-literal hosts; no explicit ports;
- redirects are re-checked against the allowlist (max 3 hops) — a 302
  cannot smuggle the request off-allowlist;
- limits: 30 s timeout, request body ≤ 1 MiB, response ≤ 8 MiB,
  30 req/min sustained with burst 10, per extension;
- **every** request — allowed or denied — is written to the extension
  log: timestamp, method, URL, decision, status/bytes. It is the audit
  trail for extension network activity.
- transport: the HTTP transport is injected by the host
  (`NewFetcherForExtensionWithTransport`, wired via
  `Scheduler.SetFetchTransport`). Production must pass a transport bound
  to the core's tunnel (local proxy), so extension traffic follows the
  VPN and never leaks direct; a nil transport dials direct and is only
  for tests/dev.
- diagnostics: per-extension counters (requests, denied, bytes out/in)
  via `Fetcher.Stats()`, surfaced in the extension details screen next
  to the log.

## 8. Capability contracts: theme, network-hook, routing (v0, proposed)

Three capabilities exist in the v1 registry without a runtime yet. Their
manifest side is real: `ParseManifestFull` (`core/ext/manifest_v1ext.go`)
and the app's `ExtManifest.parse` accept three optional top-level keys,
each a pointer to an asset file inside the package:

```json
{
  "capabilities": ["theme"],
  "permissions": ["theme.apply"],
  "theme": {"entry": "theme.json"}
}
```

| Key | Capability | Permission (risk) | Entry |
|---|---|---|---|
| `theme` | `theme` | `theme.apply` (sensitive) | theme descriptor |
| `network_hook` | `network-hook` | `net.hooks` (dangerous) | hook module descriptor |
| `routing` | `routing` | `routing.rules` (dangerous) | routing rules file |

Rules, enforced on both sides:

- each key requires its capability **and** its permission; without either
  the manifest is rejected;
- `entry` is a relative `.json` path without traversal (same rule as
  worker scripts);
- unknown keys *inside* the pointer objects are rejected;
- manifest version stays `1`: the keys are additive.

The asset files' own schemas are **contract v0 (proposed)** — only the
pointers are enforced, not the asset contents. The proposals, with
working signed example packages:

- theme: `examples/theme-midnight` (`theme.json`: `name`, `variant`,
  `css_variables`, `stylesheet`);
- network-hook: `examples/net-hook-dpi` (`hook.json`: `module`,
  `strategies[]` with `id`/`title`/`description`/`transports`);
- routing: `examples/routing-split` (`rules.json`: `rules[]` with
  `match`/`action`/`comment`, first match wins).

Each example README states the proposed status explicitly. The runtime
side (theme engine, hook loading, rule merging) is planned; until it
lands, these packages validate, pack, sign and verify exactly like any
other extension.
