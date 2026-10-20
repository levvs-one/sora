# Feature log — Wave 3, F10 Extensions MVP

Branch `bugfix/audit-2026-10-19`. Commits `[feature][ext]`, no push.
Vision: `reports/EXTENSIONS-VISION.md` (best among commercial, full-power
extensions, signed creators with stars, own store style, no compromises).

## Go — `core/ext` (new package)

| Commit | Content |
|---|---|
| `7413d53` | manifest v1 (`manifest.go`), permission registry (`permissions.go`, 12 permissions, 3 risk levels), minisign verify (`sign.go`, pure-Go ed25519, team key placeholder + fail-closed), `.soraext` open/verify (`package.go`: zip-slip/size limits, checksums.txt, signature over checksums), lifecycle store (`store.go`: install/update/rollback/enable/disable/uninstall, settings validated against settings_schema, in-memory scoped token issuer), signed catalog (`catalog.go`: fetch + team-signature verify, entry validation, badges), ExtensionHost service (`host.go`: per-extension tokens scoped to permissions) |
| `98d299b` | `docs/extensions/manifest-v1.md` (normative spec), `examples/hello-panel/` (real signed example, verified end-to-end), hyphenated reverse-DNS ids allowed |

- Proto `proto/sora/ext/v1/ext_host.proto` → Go codegen via buf (`core/gen/sora/ext/v1/`). Dart codegen unavailable (no protoc-gen-dart) — hand-written stubs NOT added; the app talks to panels via the WebView bridge, ExtensionHost wiring is documented for `core/control/server.go`.
- Tests: 30+ cases (manifest accept/reject incl. unknown fields, sign roundtrip/tamper/wrong-key, team fail-closed, package verify/tamper/extra-file/bad-sig, store lifecycle incl. downgrade-reject and settings validation, catalog validation, host permission scoping). `go build ./...`, `go vet`, `gofmt` clean.
- Wiring note for the parent: register the service in the core gRPC server —
  `extv1.RegisterExtensionHostServer(grpcServer, ext.NewHost(store.Issuer(), ext.Deps{...}))`
  with Deps adapted from the session state. `core/ext/host.go` documents this.

## Dart — `app/lib/src/ext/` + `app/lib/src/ui/extensions/`

- `ext/`: `manifest.dart` (parse/validate mirror), `permissions.dart` (registry + l10n blurb keys), `verifier.dart` (minisign in Dart via `cryptography` ed25519 + `crypto` sha256; team fail-closed), `package.dart` (open/verify via `archive`), `catalog.dart` (fetch + verify), `store.dart` (ExtensionStore ChangeNotifier: data-dir layout, installed.json, N-1 rollback, settings with schema validation), `bridge.dart` (panel JS bridge, permission allowlist).
- `ui/extensions/`: `store_screen.dart` (Catalog/Installed tabs, search, category chips, sort, install-from-file/URL, honest "catalog soon" state until the key ceremony), `detail_screen.dart` (creator + stars + badges, permissions in plain language, settings form auto-generated from settings_schema, install/update/enable/disable/rollback/uninstall, open panel), `panel_screen.dart` (WebView panel host: loopback server with bootstrap injection, navigation locked to the origin, soraExt channel, session events, teardown on disable), `permissions_sheet.dart` (install prompt; dangerous permissions need explicit ack; sideload warning), `widgets.dart` (cards, stars, badges — ink-based design system).
- `shell.dart`: the "coming soon" stub (T1 shadow feature) replaced with the real section.
- l10n: 86 `ext*` keys in `app_en.arb`/`app_ru.arb` (+ English fallback for 29 languages), dead `extensionsSoon` removed; consistency script-checked.
- pubspec: `archive: ^4.0.7`, `cryptography: ^2.8.1` added.
- No Flutter SDK in this environment: every file triple-reviewed (syntax, null-safety, brace balance via tokenizer, kit/palette/S API cross-checked). 

## Trust model (as implemented)

- Every `.soraext`: checksums.txt verified file-by-file + minisign over checksums.txt (trusted comment carries sha256 → byte flips fail).
- Catalog installs: catalog.json team-signed (fail-closed until ceremony) + download sha256 pinned to the entry.
- Sideload: verified against the author's self-attested key + explicit "not from the catalog" warning.
- Runtime: panels get only the `soraExt` JS channel, allow-listed by granted permission; no Node/ffi/network from JS; navigation locked to the loopback origin; disabling kills the panel immediately.

## Deferred / needs the dev machine

1. `flutter analyze` (0 warnings), `flutter pub get`, build — esp. new deps and hand-touched l10n.
2. Manual: install hello-panel from file → panel shows connections → disable one-tap → panel gone; tampered zip → friendly signature error.
3. `protoc-gen-dart` regen for `ext_host.proto` when the core wiring lands.
4. Owner: minisign key ceremony → replace `TeamPublicKey` (Go + Dart) and publish the real catalog URL.
5. Wave 4: background workers, `net.fetch`, theme/routing/net-hook runtimes, revocation list.
