# Anti-DPI — Sora extension

A DPI-bypass control panel for Sora: a curated preset library, a full
`BypassStrategy` editor, per-host bindings, one-click auto-tuning and a
live censorship-event monitor — all driven through the extension bridge
(`window.soraExt.call`) and the core's bypass layer API.

- `sora-extension.json` — manifest v1 (see `docs/extensions.md`)
- `panel.html` / `panel.js` / `panel.css` — the panel (vanilla, no
  external resources; untrusted strings are rendered via `textContent`
  only)
- `presets.json` — the preset library (15 presets, EN+RU)
- `strings.json` — the panel's full EN+RU string table
- `checksums.txt` — sha256 of every content file
- `signature.minisig` — minisign signature over `checksums.txt`
- `anti-dpi.soraext` — the distributable ZIP

## What it does

Tabs: **Overview** (platform, backend availability with the core's own
reasons, layer state), **Presets** (apply or send to the editor),
**Editor** (all 29 `BypassStrategy` fields with hints and
core-mirrored validation), **Bindings** (per match: domain, address or
network), **Auto-tune** (`tuneDesync` through the core), **Monitor**
(`bypass.event` censorship feed), **Profiles** (export/import/reset
the whole layer as JSON via copy-paste — panels have no file dialogs).

## Permissions — and why each one

| Permission | Why |
|---|---|
| `ui.panel` | The panel itself. |
| `bypass.read` | `getBypassCapabilities`, `getBypassState`, `getBypassLayer`: show what the device can do and what is currently applied. Read-only. |
| `bypass.write` | `applyBypassLayer`: send the edited layer (global strategy + bindings) to the core. |
| `bypass.tune` | `tuneDesync`: ask the core to score candidate strategies against the current network. |
| `notifications` | One notification after a layer is applied (best effort; the panel also reports in-place). |

Capabilities: `ui-panel` (the panel) and `network-hook` (this
extension shapes the DPI-bypass network path through the core's bypass
layer — it never runs code on the traffic path itself; the core
compiles the strategy into tpws/nfqws configuration).

Settings (own settings only, via `getSettings`/`setSettings`):
`language` (`auto`/`en`/`ru`, default `auto` → the app/browser
language), `confirm_apply` (default `true`: the Apply action asks for
confirmation), `monitor_limit` (20–200, default 50: how many monitor
events the panel keeps).

## How applying works

- The panel loads the current layer with `getBypassLayer` and edits a
  **local draft**. Nothing reaches the core until **Apply**.
- Apply sends the whole layer in one `applyBypassLayer` call
  (`{global, bindings}`) and the core records it; per the bridge
  contract it **takes effect on the next connection** (the Overview
  shows the core's `pending_apply` state).
- **The user wins:** your in-app bypass rules have priority over this
  extension's bindings. On conflict the app keeps your rule.
- Editor validation mirrors `core/engine/validate.go`
  (`BypassStrategy.validate` + `validateDesync`): ranges, the
  ttl/autottl mutual exclusion, fooling/fake-needs-desync dependencies,
  the tpws-only × desync mixing ban, and so on. A strategy the core
  would reject is flagged in the panel before Apply.
- Auto-tune: when `tuneDesync` returns a `strategy`, one click applies
  it as the global strategy. When it returns `strategy: null` with a
  winner, the core has bound the winner to a network profile — the
  panel says exactly that instead of pretending to apply it.

## Presets

`presets.json` carries all **11** profiles of the core tuner registry
(`core/tune/desync/registry.go` — the task brief said 10; the registry
in this tree has 11, and all of them are included) plus 4 tpws
classics (app-default split/disorder, TLS-record split, HTTP reform,
multisplit at SNI). Registry strategies are **derived, not invented**:
each one is the output of `Params.BypassStrategy()`
(`core/tune/desync/params.go`) for the profile's genome, and each
preset's `source` field names its origin. The `midsni` split position
is the registry marker (`core/engine/bypass.MidSNIMarker`): the core
resolves it against the actual SNI before the strategy runs. Every
preset documents, in EN and RU, what it does, which censorship class
it targets, and its honest cost/risks (from the registry `Note`s and
validation semantics).

## i18n

EN and RU are complete: UI strings, all 29 field labels/hints, preset
texts and censorship-kind labels. `strings.json` is the source of
truth; `panel.js` embeds an identical copy of the string table and of
`presets.json` because panels cannot fetch at runtime under the panel
CSP (`connect-src 'none'`). To regenerate the embedded copy after
editing the JSON files:

```sh
python3 - <<'PY'
import json
strings = json.load(open("strings.json", encoding="utf-8"))
presets = json.load(open("presets.json", encoding="utf-8"))
js = open("panel.js", encoding="utf-8").read()
import re
js = re.sub(r"var STRINGS = .*?;\n", "var STRINGS = " +
  json.dumps({"en": strings["en"], "ru": strings["ru"]}, ensure_ascii=False, indent=1) + ";\n",
  js, count=1, flags=re.S)
js = re.sub(r"var PRESETS = .*?;\n", "var PRESETS = " +
  json.dumps(presets["presets"], ensure_ascii=False, indent=1) + ";\n",
  js, count=1, flags=re.S)
open("panel.js", "w", encoding="utf-8").write(js)
PY
```

No user-visible string in `panel.js` lives outside the string table
(API method names, JSON keys and the English/Russian language names in
the language switcher are the only literals, and they are not prose).

## Platform limits (honest)

- **tpws** is TCP-only (HTTP/TLS); it cannot touch QUIC/UDP.
- **nfqws** strategies (any `desync` method, fake packets, autottl,
  UDP filters) need the nfqws backend: on Linux that means the packet
  queue and elevated privileges; where the core reports the backend as
  unavailable, the Overview shows the core's own reason and the
  editor badges the nfqws-only groups.
- A strategy **cannot mix** the two worlds: core validation rejects
  tpws-only fields alongside desync methods, and the editor mirrors
  that.
- Desync is not magic: full stream reassembly defeats splits, fixed
  TTLs are path guesses, and against a hard whitelist/MITM posture
  (the KZ variant) desync answers only the SNI-kill stage. The preset
  cards say so per preset.

## min_app_version

`1.9.0`, the same floor as every shipped example
(`examples/hello-panel`, `examples/net-hook-dpi`,
`examples/routing-split`, `examples/theme-midnight`): manifest v1 and
the panel runtime this package targets are the ones those examples
pin. The bypass bridge methods additionally need a build whose core
registers the `bypass.*` permissions; on an older build the install
fails closed on the unknown permissions rather than half-working.

## Signing

This package is signed with a **fresh developer key** generated for
this package only (public key in the manifest). The secret key was
kept outside the repository, used once for signing, and **destroyed**
— the same discipline as the examples (whose original keys are
compromised and must never be trusted; see
`examples/net-hook-dpi/README.md`). Signing with a dev key is **not**
publication: catalog listing happens only after the owner's key
ceremony pins the real author key.

Build/verify:

```sh
sora-ext validate
sora-ext pack . -o anti-dpi.soraext
sora-ext sign --key <author.key> anti-dpi.soraext
sora-ext validate anti-dpi.soraext
```

All four pass on this tree. The only warnings are the expected ones:
`bypass.write` and `bypass.tune` are `RiskDangerous` in the registry
(`core/ext/permissions.go`), so the install prompt requires explicit
confirmation for them. The bypass bridge itself (permissions, host
RPCs, Dart seam) is contract 1.14 in `core/ext` /
`app/lib/src/ext/bypass.dart`; the panel's shapes were checked
against that seam field by field.
