# Midnight Theme — example Sora theme extension

A complete, minimal theme: a dark "midnight" palette as pure data.
Install it from the Extensions section once the theme engine lands; until
then it validates, packs and verifies as a real package.

> **Status: contract per `reports/extensions-40/spec-theme-runtime.md`.**
> The manifest side is real — `sora-ext validate` accepts it and the app
> parses it — but the app-side theme engine that builds `ThemeData` from
> tokens is not implemented yet.

## The contract: a theme is data, not code

Deliberately **no CSS, no JS**. CSS is an executable surface (`url()` →
exfiltration pings, `@import` → network), so the theme engine only accepts
validated tokens from `theme.json`:

- `theme_version: 1`, `name`
- `tokens`: `color.*` (only `#rgb`/`#rrggbb`/`#rrggbbaa`, `transparent`),
  `radius.*` (0..32), `font.scale` (0.8..1.3), `opacity.*` (0..1).
  Unknown token names are rejected — not ignored.
- `dark.tokens` (optional): overrides when the app is in dark brightness.
- **Contrast gate:** every `onX`/`X` pair must pass WCAG AA (4.5:1) at
  install/enable time, or the theme is refused with the reason in the
  extension log. This file's pairs measure 9.36, 16.38 and 6.42 — all pass.

Applying is atomic (validate → build → swap, never half-applied);
disabling the extension instantly restores the app's system theme. The
`theme.apply` permission is sensitive: the install prompt says the theme
changes the whole app's look, and installing never auto-applies it.

## Files

- `sora-extension.json` — manifest v1 (`theme` capability, `theme.apply`
  permission, `theme.entry` → `theme.json`)
- `theme.json` — the tokens (no CSS by design)
- `checksums.txt`, `signature.minisig`, `theme-midnight.soraext` — as usual

## Rebuild

```sh
sora-ext validate
sora-ext pack . -o theme-midnight.soraext
sora-ext sign --key <your.key> theme-midnight.soraext
```

The example is signed with a throwaway example key; it is **not** a trust
anchor. Real themes are signed with the author's offline key.
