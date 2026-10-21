# `window.soraExt` API reference

The only bridge between a panel and the app. Panels run in a WebView
without Node and without network access (v1); everything below is
allow-listed per granted permission.

TypeScript definitions with full doc comments:
`tools/sora-ext/templates/shared/sora-ext.d.ts` (scaffolded next to every
panel). Normative spec: [extensions.md](extensions.md) §4.

## Methods

All return promises. A rejection is always a `SoraExtError` with a stable
`code` — switch on it, not on `message`:

```js
try {
  await window.soraExt.call('notify', {title: 'Hi', body: '...'});
} catch (e) {
  if (e.code === 'permission-denied') { /* explain, don't retry */ }
}
```

| Method | Permission | Args | Returns |
|---|---|---|---|
| `getConnections` | `connections.read` (sensitive) | — | `[{id, process, host, up_bytes, down_bytes}]` |
| `getServers` | `servers.read` | — | `[{id, name, country, latency_ms}]` (`-1` = unknown) |
| `notify` | `notifications` | `{title, body}` | `void` |
| `getSettings` | — (own settings) | — | object |
| `setSettings` | — (own settings) | object | `void` |
| `getBypassCapabilities` | `bypass.read` (sensitive) | — | `{platform, backends: [{kind, available, reason}]}` |
| `getBypassState` | `bypass.read` (sensitive) | — | `{platform, global_source, global_from, session_active, pending_apply, bindings_count}` |
| `getBypassLayer` | `bypass.read` (sensitive) | — | `{global: strategy\|null, bindings: [{match, strategy}], updated_at}` |
| `applyBypassLayer` | `bypass.write` (dangerous) | `{global: strategy\|null, bindings: [{match, strategy}]}` | `{updated_at}` |
| `tuneDesync` | `bypass.tune` (dangerous) | `{engine}` | `{winner_id, winner_describe, score, attempts, strategy: strategy\|null}` |

Notes:

- `process` is the process **name** only — no PIDs or paths ever leave the
  core.
- `notify`: title ≤ 120 chars, body ≤ 500 chars, else `invalid-argument`.
- `getSettings` returns schema defaults merged with stored values.
- `setSettings` merges: only the keys given change, unmentioned keys keep
  their stored values. Values are validated against `settings_schema`;
  invalid values reject with `invalid-argument` and change nothing.
  Unknown properties reject too.
- Calling a method without its permission rejects with
  `permission-denied`. There is no way to escalate: the token is scoped at
  install time, and disabling the extension revokes it.

### Bypass (Anti-DPI) methods

The five `*Bypass*` / `tuneDesync` methods are the Anti-DPI surface. They
ride a per-extension ExtensionHost token the app mints when the panel
opens (scoped to the extension's granted permissions, revoked when the
panel closes); panels never see the token itself.

A **strategy** is a JSON object with the snake_case field names of
`sora.core.v1.BypassStrategy` — all 29 fields: `split_pos`, `disorder`,
`oob`, `tls_record`, `host_case`, `domain_case`, `method_eol`,
`disorder_scope`, `oob_scope`, `host_dot`, `host_tab`, `host_no_space`,
`method_space`, `unix_eol`, `split_any_protocol`, `tamper_start`,
`tamper_cutoff`, `oob_data`, `mss`, `desync`, `fake_tls`, `fake_quic`,
`fooling`, `ttl`, `auto_ttl`, `repeats`, `filter_tcp`, `filter_udp`,
`filter_l7`. Reads always return the full shape (defaults included);
writes may omit fields (they take proto defaults), but unknown fields or
wrong types reject with `invalid-argument`.

A **layer** is `{global, bindings}`: one global strategy (or `null` for
none) plus per-destination bindings `{match, strategy}`, where `match`
uses the core's destination form (e.g. `domain:example.com`).

- `getBypassCapabilities` reports the host platform and which desync
  backends can actually run here (`available: false` carries the
  `reason`).
- `getBypassState` reports where the current global strategy came from
  (`global_source` / `global_from`), whether a session is live
  (`session_active`), whether an applied layer is still waiting for the
  next connect (`pending_apply`), and how many bindings the layer has.
- `getBypassLayer` returns the current layer plus `updated_at`.
- `applyBypassLayer` replaces the layer wholesale and returns the new
  `updated_at`.
- `tuneDesync` runs the core's desync tuner once for `{engine}`
  (`"nfqws"` or `"tpws"`; empty means the core's default) and returns the
  winner. `strategy` is the winning strategy, or `null` when no
  candidate worked — that is an outcome, not an error.

**How an applied layer takes effect.** Applying is not retroactive: the
layer applies from the **next connect** (`pending_apply` says so until
then). On a successful `applyBypassLayer` the app also writes the
layer's global strategy through to its own settings (the
`antidpiStrategyJson` slot, owned by the applying extension), so the
session plan the app builds carries the complete strategy to the zapret
outbounds. Two things take it back:

- **The user wins.** Editing any legacy zapret field in the app's
  settings (split positions, disorder, TLS record, host case) clears
  the slot immediately; the user's own strategy applies from then on.
- **The owner goes away.** Disabling or uninstalling the extension
  clears the slot, and the core drops a disabled extension's layer from
  its plan merge.

### Error codes

| Code | Meaning |
|---|---|
| `permission-denied` | permission not granted |
| `invalid-argument` | unknown method or bad args |
| `not-connected` | `getConnections` called with no VPN session up (panel bridge) |
| `internal` | host could not complete the call |

## Events — `onEvent`

```js
const off = window.soraExt.onEvent((kind, detail) => { … });
off(); // unsubscribe
```

| Kind | When |
|---|---|
| `session.connected` | VPN session came up |
| `session.disconnected` | VPN session went down |
| `network.changed` | underlying network changed — reserved: not emitted by the current panel bridge yet |
| `extension.disabled` | this extension was disabled — reserved: the current bridge tears the panel down without delivering this event first |
| `bypass.event` | the core detected censorship relevant to this panel; `detail` is a JSON string `{kind: "censorship", censorship_kind, explanation, at}` (`at` is RFC 3339 UTC). Needs a bypass permission: the panel subscribes while it is open and the events stop when it closes. A core without the bypass event stream simply never sends it. |

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

## Planned (not in v1)

| API | Status |
|---|---|
| Theme engine applying `theme.json` | contract v0 proposed ([example](../examples/theme-midnight)) |
| Network-hook module loading (`hook.json`) | contract v0 proposed ([example](../examples/net-hook-dpi)) |
| Routing-rule merging (`rules.json`) | contract v0 proposed ([example](../examples/routing-split)) |
| Background worker JS runner (`worker.js`) | Go seam exists (`core/ext` `WorkerFunc`); app-side runner pending |
| `tray` permission / widgets | reserved |

"Planned" means: the manifest side parses and validates today, the
runtime does not consume it yet. Examples above are valid, signed packages
showing the exact shape the runtime will consume — their READMEs say so.
