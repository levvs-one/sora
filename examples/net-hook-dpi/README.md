# DPI Bypass Example — example Sora network-hook extension

A minimal network-hook: declarative DPI-bypass fragments (fragment the TLS
ClientHello toward one blocked domain) for sing-box and xray.

> **Status: contract per `reports/extensions-40/spec-net-hooks.md`.** The
> manifest side is real — `sora-ext validate` accepts it and the app parses
> it — but core-side compilation of fragments into the engine config is not
> implemented yet.

## The contract: two levels, no code on the hot path

The one mistake this design refuses to make is running extension code on
every packet. So:

- **L1 — declarative engine fragments** (this example): `hook.json`
  describes match + action; the engine compiles them into its own config.
  Extension code never touches the traffic path.
- **L2 — observer API** (`onRequest`/`onResponse` for the extension's own
  HTTP traffic): specified in the spec, not shown here.

`hook.json`:

- `hook_version: 1`
- `engine_fragments[]`: each has `engines` (e.g. `sing-box`), a `match`
  (`domain_suffix` here), and `params` — strictly per-engine (allowlisted,
  typed, ranged). An unknown param rejects the whole fragment, not just
  the param.
- Fragments merge into the session plan as a named extension layer; on
  conflict with user settings **the user wins**, with a log entry.
- Disabling the extension removes its fragments; no code of the extension
  ever runs in the engine process.

## Trust

The `net.hooks` permission is **dangerous**: the install prompt requires an
explicit confirmation, and updates that add it re-prompt the user. A hook
shapes the traffic path, so treat hook extensions like VPN profiles:
install only from authors you trust, preferably via the signed catalog.
No MITM is possible by design: a hook gets no keys, installs no CA, and
never decrypts anything.

## Files

- `sora-extension.json` — manifest v1 (`network-hook` capability,
  `net.hooks` permission, `network_hook.entry` → `hook.json`)
- `hook.json` — the L1 fragments
- `checksums.txt`, `signature.minisig`, `net-hook-dpi.soraext` — as usual

## Rebuild

```sh
sora-ext validate
sora-ext pack . -o net-hook-dpi.soraext
sora-ext sign --key <your.key> net-hook-dpi.soraext
```

Signed with a throwaway example key — **not** a trust anchor.

Pass-2 audit note (2026-10-20): the first shipped packages mistakenly
embedded the example secret key (`author.key`) inside the .soraext.
Those keys are public and burned — never trust a package signed with
them. The packages were rebuilt from these sources and re-signed with
fresh throwaway keys whose secrets were destroyed and are shipped
nowhere; `sora-ext pack` now refuses to include key files at all.
