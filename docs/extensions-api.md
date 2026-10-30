# `window.soraExt` API reference

The app owns the store, grants and this bridge between a panel and the app. Panels run in a WebView
without Node and without network access (v1); everything below is
allow-listed per granted permission.

TypeScript definitions with full doc comments:
`tools/sora-ext/templates/shared/sora-ext.d.ts` (scaffolded next to every
panel). Normative spec: [extensions.md](extensions.md) §4.

## Methods

All return promises. A rejection is always a `SoraExtError` with a stable
`code`, switch on it, not on `message`:

```js
try {
  await window.soraExt.call('notify', {title: 'Hi', body: '...'});
} catch (e) {
  if (e.code === 'permission-denied') { /* explain, don't retry */ }
}
```

| Method | Permission | Args | Returns |
|---|---|---|---|
| `getConnections` | `connections.read` (sensitive) | none | `[{id, process, host, up_bytes, down_bytes}]` |
| `getServers` | `servers.read` | none | `[{id, name, country, latency_ms}]` (`-1` = unknown) |
| `notify` | `notifications` | `{title, body}` | `void` |
| `getSettings` | none (own settings) | none | object |
| `setSettings` | none (own settings) | object | `void` |
| `getBypass` | `net.hooks` (since 1.1.6) | none | `{available, active, connecting, profile, profiles}` |
| `setBypass` | `net.hooks` (since 1.1.6) | `{active: boolean}` | `void` |

Notes:

- `process` is the process **name** only, no PIDs or paths ever leave the
  core.
- `notify`: title ≤ 120 chars, body ≤ 500 chars, else `invalid-argument`.
- `getSettings` returns schema defaults merged with stored values.
- `setSettings` merges: only the keys given change, unmentioned keys keep
  their stored values. Values are validated against `settings_schema`;
  invalid values reject with `invalid-argument` and change nothing.
  Unknown properties reject too.
- `getBypass` describes the extension's own network hook: whether it can run on
  this computer, whether Sora runs it now (`active`) or is connecting, the
  chosen `profile` setting and the `profiles` its schema offers.
- `setBypass` turns that hook on through the host's own consent and connect
  flow (it may ask the user first) or off. It never stops a session another
  server or extension started. Switch profiles with `setSettings`.
- Calling a method without its permission rejects with
  `permission-denied`. The app bridge checks the installed grants;
  disabling tears down panels and cancels the worker stream.

### Error codes

| Code | Meaning |
|---|---|
| `permission-denied` | permission not granted |
| `invalid-argument` | unknown method or bad args |
| `not-connected` | `getConnections` called with no VPN session up (panel bridge) |
| `internal` | host could not complete the call |

## Events, `onEvent`

```js
const off = window.soraExt.onEvent((kind, detail) => { … });
off(); // unsubscribe
```

| Kind | When |
|---|---|
| `session.connected` | VPN session came up |
| `session.disconnected` | VPN session went down |
| `network.changed` | underlying network changed, reserved: not emitted by the current panel bridge yet |
| `extension.disabled` | this extension was disabled, reserved: the current bridge tears the panel down without delivering this event first |

Needs no permission: every enabled extension may know whether the session
is up.

## Settings

Declare in the manifest; the app auto-generates the settings form:

```json
"settings_schema": {
  "type": "object",
  "properties": {
    "refresh_seconds": {"type": "integer", "minimum": 1, "maximum": 60, "default": 5},
    "theme": {"type": "string", "enum": ["dark", "light"], "default": "dark"}
  }
}
```

Supported types: `string`, `integer`, `number`, `boolean`; optional
`enum`, `minimum`, `maximum`, `minLength`, `maxLength`, `default`.

## Limits (v1)

- No `fetch`/`XMLHttpRequest` from panel JS; navigation outside the
  package is blocked.
- Panels are torn down on `extension.disabled`; persist state via
  `setSettings`, not in-memory globals.
- Keep panels light: they run inside the app process.

## Worker and declarative runtimes

The app starts background workers through the control-authenticated
`ExtensionHost.RunWorker` stream, the sole extension RPC. They execute in
isolated goja processes while the app is open.
They receive the same `window.soraExt.call` API, enforced by granted
permissions and the existing panel bridge. Extension-local settings remain
permissionless. `console.log` writes to the extension log.

Worker-only method: `call('net.fetch', {url, method?, headers?, body?})`,
permission `net.fetch`, returns `{status, headers, body}`. Headers map to
arrays of response header values; request headers map to strings. Body is
text. HTTPS, network_hosts allowlist, redirect/rate/size policy and a live
VPN proxy are all required; without a connected VPN session and its private
authenticated SOCKS inbound it rejects with `not-connected`. This inbound
has a random loopback port and per-session credentials kept inside the core.
Its route is pinned to the selected VPN or chain, ahead of user and extension
rules, even if a matching ordinary route is direct or blocked. DNS over TCP
to `1.1.1.1:53` uses the same VPN path; destination IPs then travel through it
with the original HTTPS identity. Direct/serverless bypass, mixed direct/VPN
groups and opaque Xray profiles are unavailable. Pure TUN needs no ordinary
local proxy. There is no direct-network or OS DNS fallback.
Panel `net.fetch` remains unavailable.

Worker `onEvent` receives a session-state snapshot once per subscription per
run. A worker is a finite scheduled task, not a persistent event listener.
See [runtime budgets and lifecycle](extensions.md#71-background_task).

| Runtime | Status |
|---|---|
| `theme.json` | applied by the app, validated palette and contrast, one conflict winner |
| `rules.json` | merged into the session plan after user rules, deterministic first-match order |
| `worker.js` | scheduled, permission checked, isolated, CPU/memory/wall budgets |
| `network_hook` / `net.hooks` | signed declarative bypass profiles, explicit selection and native capability checks; no arbitrary packet callbacks |
| `tray` / widgets | reserved |

The exact theme tokens, routing match syntax, priorities and reset behavior
are specified in [extensions.md](extensions.md#8-themes-and-routing-rules).
