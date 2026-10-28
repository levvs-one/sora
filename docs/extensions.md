# Sora extension manifest v1

This document is the normative spec for Sora extensions (feature F10).
The app owns the extension store and runtime grants (`app/lib/src/ext`).
`core/ext` provides the worker host and the manifest, package and signing
functions used by the `sora-ext` authoring CLI.

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
  "min_app_version": "1.1.0",
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
  build time: `flutter build --dart-define=SORA_VERSION=1.1.0`. Release CI
  passes the tag version. Dev builds without the define skip the gate
  instead of guessing. Extensions first shipped in 1.1.0, so an older
  `min_app_version` gains nothing.
- `permissions`: subset of the registry below, no duplicates.
- `capabilities`: subset of `theme`, `network-hook`, `routing`, `ui-panel`,
  `background`, `widget`.
- Panel `entry`: relative `.html` path, no traversal.
- `settings_schema`: JSON-Schema subset, object with typed properties
  (`string`, `integer`, `number`, `boolean`; optional `enum`, `minimum`,
  `maximum`, `minLength`, `maxLength`, `default`). The app auto-generates the
  settings form from it.
- `background_task`, `network_hosts`: optional v2-runtime keys, see §7.
  Manifest version stays `1`: they are additive, and old manifests without
  them parse exactly as before. Unknown keys, including unknown keys
  *inside* `background_task`, are still rejected.
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
| `getSettings`      | none              | the extension's own settings       |
| `setSettings`      | none              | validated against settings_schema  |

Events: `session.connected`, `session.disconnected` (the two the current
panel bridge emits). `network.changed` and `extension.disabled` are
reserved kinds in the spec: not emitted yet, when an extension is
disabled, the panel is torn down without the event being delivered
first.

Calling a method without the permission rejects the promise. Navigation
outside the package is blocked; `fetch`/`XMLHttpRequest` from panel JS have
no network access in v1.

## 5. Catalog

The published v1.1.2 app uses `catalog.json` and `catalog.json.minisig`.
The compatible host candidate uses `catalog-1.1.3.json` and its `.minisig`.
Both use the team key and the same catalog signature role, with trusted
comment `timestamp:..\tfile:catalog.json\tsha256:..`. The versioned path
separates listings but does not add a cryptographic scope or rollback
protection. The repository seed is a copy of the existing signed catalog;
it does not establish that a new host or extension has been published.
The versioned files must be available and verify at the configured URL before
shipping a host that uses it. See [catalog publishing](../extensions/README.md).
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
      "min_app_version": "1.1.0",
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
  `sha256(install_id | ext id | version)` mod 10000 < fraction * 10000.
  The update button shows only for eligible installs; the listing is never
  gated. A bad version is halted via the revocation list, not a zero
  fraction.
- `screenshots`: ≤ 8 https image URLs for the detail page.
- `changelog`: version/date(RFC3339)/notes rows, newest first.
- `platforms`: optional list of at most 16 distinct lowercase OS identifiers
  (1..32 ASCII letters/digits/underscore/hyphen, starting with a letter).
  Examples: `linux`, `windows`, `macos`, `android`, `ios`. Omitted or empty
  means no catalog OS restriction, preserving earlier entries. Unknown future
  OS identifiers remain listed and are unavailable on other hosts.
  This metadata filters installation, not catalog visibility. It does not
  certify architecture, driver, operating-system edition or backend availability.
- `capabilities`: subset of the manifest capability registry; the store
  filters on these ("Themes", "Bypasses & network hooks", ...).

The rating methodology (Bayesian average, freshness decay, one vote per
account) is specified separately; the catalog carries the finished
`rating` / `ratings_count` / `installs` numbers. Revocation uses
`revocations.json` + `.minisig` (same team key): see the abuse-handling
spec. Both files live in `extensions/` of the repository and are signed
with `sora-ext sign-file` (see extensions/README.md).

## 6. Trust notes

- Sideloaded packages (file/URL) are verified against the **author's own
  key** from the manifest, self-attested. The app shows an explicit
  "not from the catalog" warning.
- Catalog packages are verified against the catalog-pinned author key, and
  the catalog itself against the team key.
- The app verifies the catalog and revocation list with its compiled team
  key. It owns the catalog cache, staged rollout and revocation policy.
- Revocation: removing an entry from the catalog stops new installs, and the
  signed revocation list disables matching installed versions and refuses
  installing, updating, rolling back to or enabling them. An expired list
  blocks new installs until a fresh one is fetched.

## 7. Background workers & net.fetch (runtime v2)

Manifest version stays `1`: these are additive optional keys parsed by
`ParseManifestFull` (`core/ext/manifest_v1ext.go`) in the core and CLI,
and by `ExtManifest.parse` in the app.

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
- `entry`: the worker script inside the package, a relative `.js` path,
  no traversal.

The app installs, updates, rolls back, enables and removes extensions,
validates settings, checks signatures and revocations, and stores grants.
Panels call its permission-checked `PanelBridge` directly.

The only extension RPC is the bidirectional `ExtensionHost.RunWorker`
lifecycle stream, authenticated by the app control token and transport.
The first message carries the verified manifest with granted permissions,
script source and resolved background configuration; later messages carry
bridge replies. The core sends bridge calls, bounded logs and run failures.
It has no extension store and never reads the app registry or cache. The service schedules them with
`Scheduler.RegisterConfig` and executes each run in a fresh goja process.
The first run is after the effective interval plus a deterministic stagger
of up to 59 seconds. No runs overlap; ten consecutive failures stop the task
until it is registered again. Workers run while the app is open, including
when its window is hidden in the tray. Closing the app or losing its control
stream unregisters the task. Reopening the app starts a new schedule.

`window.soraExt.call` provides the same permission-checked methods as panels,
including extension-local settings and notifications through `PanelBridge`.
Workers additionally have `net.fetch` and `console.log`. No Node, DOM,
filesystem, process, raw socket, global fetch or timer APIs are exposed.
Source maps are disabled, including in eval, because the default goja
source-map loader can read local files.
Top-level await is supported by the host's async function wrapper; modules
and imports are not. Each run must finish all its work and settle promises.
`onEvent` receives the current session connected/disconnected snapshot once
per subscription per run; subscriptions do not survive runs. Panel event
subscriptions continue to observe live changes while their panel is open.

Budgets per run: 2 CPU seconds, 128 MiB live heap, 30 seconds wall time,
1 MiB source, 256 host calls (including log calls), and stack depth 256. The
worker checks its own heap and CPU time every 20 ms and exits at the budget,
the same way on every platform; rlimits on Linux and a Job Object on Windows
sit at four times the memory budget as a hard backstop. Go's soft heap target
is 64 MiB.
Allocation failure, runaway JS and a blocked bridge end only the disposable
process. The parent kills and reaps it on timeout or cancellation. A JS VM
or native-runtime vulnerability is outside this resource-isolation claim.

`console.log` and every run outcome go to the bounded extension log (256
entries, 1024 bytes per entry). Unhandled errors, rejected promises and
budget failures also produce a localized notification. Disable, uninstall,
worker-off and reconfiguration cancel the lifecycle stream and any in-flight
process or fetch. The kill switch pauses scheduling and cancels active runs.

```js
const settings = await window.soraExt.call('getSettings');
console.log('Background settings keys: ' + Object.keys(settings).join(', '));
const response = await window.soraExt.call('net.fetch', {
  url: 'https://api.example.com/status', method: 'GET'
});
console.log('HTTP ' + response.status);
```

### 7.2 network_hosts, the net.fetch allowlist

Host allowlist for `net.fetch`. Requires the `net.fetch` permission (named
`network` in the wave-4 plan; the v1 permission registry already reserves
`net.fetch` for exactly this, so no new permission was added).

- Entries are lowercase DNS names (`api.example.com`) or wildcards
  (`*.example.com`). Max 64 entries, no duplicates, no IP literals, no
  schemes/ports/paths.
- Matching is strict: `api.example.com` matches **only itself** -
  `sub.api.example.com` is denied. `*.example.com` matches subdomains
  (`a.b.example.com`) but **not** the bare `example.com`, and not
  lookalikes (`evilexample.com`).

Host-side enforcement (`core/ext/netfetch.go`):

- https only; no userinfo; no IP-literal hosts; no explicit ports;
- redirects are re-checked against the allowlist (max 3 hops), a 302
  cannot smuggle the request off-allowlist;
- limits: 30 s timeout, request body ≤ 1 MiB, response ≤ 8 MiB,
  30 req/min sustained with burst 10, per extension;
- **every** request, allowed or denied, is written to the extension
  log: timestamp, method, URL, decision, status/bytes. It is the audit
  trail for extension network activity.
- transport: the HTTP transport is injected by the host
  (`NewFetcherForExtensionWithTransport`, wired via
  `Scheduler.SetFetchTransport`). Production uses a separate authenticated
  SOCKS inbound on `127.0.0.1`, with a random free port and a fresh random
  username/password for each session. It is independent of the ordinary
  mixed listener and works in both TUN and system proxy mode. Credentials
  remain inside the core and engine configuration, never in worker messages.
  sing-box and Xray route this inbound to the selected VPN outbound, group
  or chain exit before sniffing, DNS interception and all user/extension
  rules. mihomo pins the listener's `proxy` to that target, overriding
  rule/global/direct mode. Direct, regional and block rules therefore do
  not affect extension fetches.
- DNS: the core resolves destination names using DNS over TCP to
  `1.1.1.1:53` through the same authenticated inbound and VPN target.
  It then sends destination IPs through that inbound, retaining the original
  HTTPS hostname for TLS SNI/certificate verification and HTTP Host.
  Session DNS policy, engine DNS interception and the OS resolver do not
  resolve these destination names. Proxy server hostname bootstrap remains
  an engine responsibility. A failed DNS or VPN connection has no direct
  or system-resolver fallback.
- availability: every request looks up the connected session and a running
  engine with this inbound. No session, reconnecting/recovering engines,
  direct/serverless bypass selections and unsupported inbounds fail closed
  with `ext.netfetch.no-tunnel` (`not-connected` in worker JS). Groups must
  contain only VPN paths, including nested members and chain hops; mixed
  direct/VPN groups and opaque provider Xray profiles fail closed too.
  A nil transport dials direct and is only for tests/dev.
- diagnostics: per-extension counters are available through `Fetcher.Stats()`;
  request decisions and byte counts are visible in the extension log.

## 8. Themes and routing rules

Both declarative runtimes work in the Flutter app. The manifest pointers
require the matching capability and granted permission, safe relative JSON
entry paths, and no unknown pointer fields. Asset files are limited to 1 MiB.
The CLI validates the pointer and package integrity; the app additionally
validates theme colors/contrast and routing semantics before applying them.

```json
{"capabilities":["theme"],"permissions":["theme.apply"],"theme":{"entry":"theme.json"}}
```

### 8.1 Themes

`theme.json` has `name` (1..80 characters), `variant` (`light` or `dark`),
`css_variables` (an object of the color tokens below) and optional
`stylesheet`. Flutter has no CSS: **stylesheet is ignored**, never executed
or fetched. Unknown descriptor fields and tokens are rejected. Values must
be opaque `#RRGGBB` colors, with no CSS expressions, named colors or alpha.
Omitted tokens inherit the selected variant's default palette.

| Token | Palette field |
|---|---|
| `--sora-background` | `background` |
| `--sora-surface` | `surface` |
| `--sora-field` | `field` |
| `--sora-text` | `ink` |
| `--sora-text-secondary` | `ink2` |
| `--sora-text-muted` | `ink3` |
| `--sora-danger` | `danger` |
| `--sora-on-danger` | `onDanger` |
| `--sora-raised` | `raised` |
| `--sora-raised-field` | `raisedField` |
| `--sora-accent` | `accent`, connection glow only |

`shadow` and `scrim` keep variant defaults; hover/pressed colors derive from
`ink`. Without `--sora-accent`, the connection glow keeps its spectrum.
With it, the glow uses that single color; control/text colors do not change.

Contrast must be at least 4.5:1 for `ink`, `ink2`, `ink3` and `danger` on
background/surface/raised, for `ink` on field/raisedField, and for `onDanger`
on danger. An invalid theme is rejected with a localized toast. Invalid
assets found on startup are not applied and produce a notification/log.

Only one enabled, granted theme applies. If several contend, the existing
conflict sheet selects the persisted winner; unresolved conflicts use the
app default. Disabling or uninstalling the winner immediately recomputes the
choice, restoring the app's configured default if no contender remains.
The theme variant overrides the app brightness only while the theme applies.
Fonts, spacing and component geometry stay under the app's control.

### 8.2 Routing

`rules.json` is `{"priority":0,"rules":[{"match":"example.org",
"action":"proxy","comment":"Selected session proxy"}]}`.
Priority is optional (default 0), integer -1000..1000. At most 256 rules
per extension. Unknown fields are rejected. Comment is optional, at most
500 characters. Actions are exactly `direct`, `proxy`, `block`; an extension
can never select or name a server. `proxy` resolves to the current session
proxy/group/chain, and `block` renders as the engine reject target.

Matches use `UserRule.destinationOf`, the same parser as the user rule
editor: domain names, `domain:` suffix matches, `full:` exact names,
`process:` names, IPs and CIDRs. Bare names are process matches. URLs use
their host. Invalid values reject the whole rules file.

Order is **user rules first, extension rules by priority DESC,
installed_at ASC, id ASC, engine defaults last**. An extension's own rule
order is preserved. First match wins; routing extensions merge rather than
participating in exclusive conflict resolution. Identical destinations,
domain suffix overlaps and intersecting CIDRs are logged to the contributing
extension's log, including overlaps with user rules. Rules are never removed
because of an overlap: an overlap may be partial.

Enable, disable, update, rollback and uninstall recompute the session plan.
A live session reconnects through the app's serialized selection mechanism
when its resulting plan changes. The extension detail screen lists enabled
contributions with their match, action and comment; disabled extensions have
no active contributions. Logs show overlaps and runtime failures.

Source examples with throwaway public keys and local build/sign guides:
`examples/theme-midnight`, `examples/routing-split`.

### 8.3 Selected bypass profiles

The app consumes version-2 declarative profiles through the existing
`network_hook` pointer, `network-hook` capability and dangerous `net.hooks`
permission. This is not a worker callback on packets.

```json
{
  "hook_version": 2,
  "backend": "tpws",
  "profiles": {
    "TCP+TLS": {"splitPos":["1","midsld"],"disorder":true,"tlsRecord":"1"},
    "HTTP": {"splitPos":["2"],"hostCase":true,"domainCase":true,"methodEol":true}
  }
}
```

Only `tpws` on Linux and `byedpi` on Windows are accepted. These are
installed host backends: an extension never supplies their executable.
The descriptor is at most 1 MiB, contains 1..16 profiles with nonblank
names of at most 64 UTF-8 bytes, and each value is a protobuf-JSON
`BypassStrategy`. Unknown top-level and strategy fields reject the asset.
The extension's schema supplies a string setting named `profile` whose
default names an existing profile. The app rejects unknown selections
before writing settings. The CLI checks descriptor shape and protobuf
types; core plan validation checks native strategy semantics before start.

There are no executable paths, scripts, flags, arbitrary engine fragments,
packet-reading callbacks or new credential APIs. The old proposed version-1
engine-fragment descriptor is not interpreted as version 2. Windows
WinDivert/winws is a separate unfinished adapter, not a SOCKS backend and
not supplied by these profiles.

Installation does not select or connect a profile. Enabled, granted holders
of net.hooks use the existing exclusive conflict decision, including
contenders with invalid assets. The user selects the winning profile in
the mode picker or connects explicitly from its detail screen. Its plan
contains a copy of that strategy, separate from manual bypass settings.
Changing an active profile reuses the serialized authenticated core
Connect flow. A failed replacement retains the old core session. Disabling,
removing, revoking or losing the selected grant/winner stops that session
instead of silently substituting another profile. The selection remains
visible; reconnect fails until it becomes available or the user chooses
another mode. Cancellation cannot undo a request already accepted by the
core; an in-flight connection is followed by Disconnect.

The app owns this grant boundary. The core validates an ordinary control
peer's SessionPlan and does not independently attest the app's extension
registry or grants. A compromised app/control peer remains outside it.

Sources: `extensions/sources/zapret` (Linux built-in settings) and
`extensions/sources/byedpi` (Windows driverless backend).
They are source projects, not published catalog entries. Production
publication must choose the actual first host release with this consumer
and set the matching min_app_version before author/team signing.
The source's minimum version is not deployment evidence.

Catalog bytes and packages are delivered separately from the application.
Opening/refreshing the catalog fetches and verifies its current team
signature; compatible additions require no client rebuild. A new native
backend or API still requires a host that implements it. Catalog visibility
must not imply installability or claim that old clients have new capabilities.
The catalog shows OS/version requirements before download and blocks incompatible
install/update actions without hiding the listing. Signed manifest and runtime
checks still run afterward. Native architecture/backend checks and the actual
minimum published host version still need validation before these sources ship.

No profile promises DPI evasion on every network. Loading a Windows driver
in a disposable test environment proves neither shaping effectiveness nor
support for every Windows edition, architecture and protection configuration.
