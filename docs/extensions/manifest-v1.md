# Sora extension manifest v1

This document is the normative spec for Sora extensions (feature F10).
Reference implementation: `core/ext` (Go). The app mirrors it in Dart
(`app/lib/src/ext`).

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
sorted by path. It lists every file **except** itself and
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
- `permissions`: subset of the registry below, no duplicates.
- `capabilities`: subset of `theme`, `network-hook`, `routing`, `ui-panel`,
  `background`, `widget`.
- Panel `entry`: relative `.html` path, no traversal.
- `settings_schema`: JSON-Schema subset — object with typed properties
  (`string`, `integer`, `number`, `boolean`; optional `enum`, `minimum`,
  `maximum`, `minLength`, `maxLength`, `default`). The app auto-generates the
  settings form from it.

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
      "permissions": ["connections.read"],
      "download_url": "https://...",
      "sha256": "<hex of the .soraext>",
      "size": 48210,
      "min_app_version": "1.9.0"
    }
  ]
}
```

Badges: `verified` (reviewed by the Sora team), `top` (top of the week),
`new`, `staff` (built by the Sora team). URLs must be https. Catalog
installs verify the downloaded `.soraext` sha256 against the entry, then run
the normal package verification.

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
