# Split Routing Example — example Sora routing extension

A minimal routing extension: keep LAN/private traffic direct, route one
example domain through the VPN.

> **Status: contract per `reports/extensions-40/spec-routing-hooks.md`.**
> The manifest side is real — `sora-ext validate` accepts it and the app
> parses it — but core-side compilation of rules into the routing table is
> not implemented yet.

## The contract: rules are data, not code

No JS/WASM callbacks on the traffic path — declarative rules are enough,
and they can be audited. `routing.json`:

- `routing_version: 1`
- `rules[]`: each has an `id` (unique, `^[a-z0-9-]{1,32}$`), exactly one
  match type (`domain`, `domain_suffix`, `domain_keyword`, `ip_cidr`,
  `port` only paired with domain/ip — a bare `port: 443 → proxy` is
  forbidden as too broad), an `action` (`direct`|`proxy`|`block`), and a
  `priority` (0..100, default 50).
- Limits: ≤ 512 rules; `0.0.0.0/0` is forbidden (an extension may not grab
  all traffic).
- One bad rule fails the **whole file** — silently dropping rules would be
  theater.

Evaluation order for a connection:

1. The user's own rules — always above extensions.
2. Extension rules, sorted by `(priority DESC, installed_at ASC, id ASC)`
   — fully deterministic.
3. Engine defaults.

First match wins. Overlaps are logged to the extension log so the user sees
why traffic went the way it did. Disabling the extension removes its rules
instantly; the compiled table is rebuilt atomically on every change.

Note: `action: proxy` means "proxy it" — *which* proxy stays the user's /
engine's choice. An extension never names its own server.

## Trust

The `routing.rules` permission is **dangerous**: the install prompt requires
an explicit confirmation, and updates that add it re-prompt the user. A
routing extension decides what goes through the tunnel — install only from
authors you trust, preferably via the signed catalog.

## Files

- `sora-extension.json` — manifest v1 (`routing` capability,
  `routing.rules` permission, `routing.entry` → `routing.json`)
- `routing.json` — the rules
- `checksums.txt`, `signature.minisig`, `routing-split.soraext` — as usual

## Rebuild

```sh
sora-ext validate
sora-ext pack . -o routing-split.soraext
sora-ext sign --key <your.key> routing-split.soraext
```

Signed with a throwaway example key — **not** a trust anchor.
