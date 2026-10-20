# Localizations — Apple clients

## Files

- `Localizable.xcstrings` — the Xcode String Catalog used by all Apple
  targets. Generated; do not hand-edit (edit ARB or the converter's
  `EXTRA_KEYS`, then regenerate).
- `arb_to_xcstrings.py` — converter: main app ARBs → this catalog.
- `check_glossary.py` — terminology consistency check (see `GLOSSARY.md`).
- `GLOSSARY.md` — fixed EN/RU term pairs and the empty-state/error style.

## Coverage (generated 2026-10-20)

- Source: all 32 ARB files in `app/lib/l10n/` (`app_*.arb`). They collapse
  to **31 BCP 47 locales**: `app_zh.arb` and `app_zh_Hans.arb` are the same
  locale (`zh-Hans`); the converter merges them.
  ar az be bn de en es fa fr hi hy id it ja ka kk ko ky pl pt ru tg th tk
  tr uk ur uz vi zh-Hans zh-Hant.
- **711 keys** from the main app (onboarding, servers, subscriptions,
  import/QR, settings, statistics, connection errors, kill switch, split
  tunnel — the full ARB set, not a subset), each present in **all 31
  locales at 100%** (the ARBs themselves are complete; nothing was
  fabricated — locales that lack a key in a future ARB drop simply get no
  localization for that key and Xcode falls back to `en`, and the
  converter prints the per-locale percentage).
- **49 Apple-only keys** in `EXTRA_KEYS` of the converter, with full EN +
  RU and `en` fallback for the other 29 locales:
  - 31 `state.*` honest system states (VPN profile not approved/missing,
    extension not approved / needs restart / missing / failed, reconnect
    after network change, offline network, launch-at-login unavailable,
    kill switch needs extension, captive portal, IPv6 unavailable, app
    group / keychain unavailable, low-power delayed reconnect, stale
    widget, intent needs approval, empty-state hint, approval paths for
    iOS and macOS);
  - names cross-checked by grep against the app departments' code:
    `state.<TunnelPhase.rawValue>` (macOS `TunnelStatus.swift`),
    `TunnelState.swift` (iOS), `SystemExtensionManager.swift`;
  - plus the dotted keys those departments reference: `alert.*` (5),
    `notify.*` (10), `app.name`, `error.core_unavailable`,
    `error.import_empty`.
- ICU plurals: 7 ARB keys (e.g. `expiresIn`, `groupOrdered`) are converted
  to String Catalog substitutions with per-category variations; ICU
  `select` would abort the converter (none exist today).
- Placeholders: ARB `{name}` → `%@` / `%lld` / `%lf` by the ARB `@`-metadata
  type; plural variables are forced to `%lld` (the generated
  `strings_en.dart` confirms `int` for all 7, the ARB metadata omits it).

Total catalog size at generation: **760 keys**.

## Wiring into targets

`project.yml` already lists `Localizations/Localizable.xcstrings` in the
sources of `SoraIOS` and `SoraMac`; the widget/intent extensions read the
host app's catalog via their bundle. In code:

```swift
String(localized: "state.vpnProfileNotApproved")
Text("state.extensionNotApproved")
```

Keys are the ARB names verbatim (camelCase), so a string that exists in
the Flutter app keeps the same identifier on Apple.

## Adding or updating locales

1. Update/add `app/lib/l10n/app_<locale>.arb` in the main app (that is the
   single source of truth for the 711 shared keys).
2. Run: `python3 arb_to_xcstrings.py` (defaults resolve the repo layout;
   `--arb-dir` / `--out` override).
3. Run: `python3 check_glossary.py` — must exit 0.
4. Validate: `python3 -m json.tool Localizable.xcstrings > /dev/null`.
5. For Apple-only keys, add EN + RU to `EXTRA_KEYS` in the converter and
   regenerate; other locales fall back to EN until translated — that is
   deliberate and visible in the converter's coverage report, not a silent
   gap.
