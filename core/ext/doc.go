// Package ext implements the Sora extension platform: the .soraext package
// format, the manifest v1 schema, minisign signature verification, the
// permission model, the install/update/rollback lifecycle, the signed team
// catalog, and the ExtensionHost gRPC service (proto/sora/ext/v1).
//
// Trust model, in short:
//   - Every .soraext is signed by its author (minisign over a checksums
//     manifest). Sideloaded packages show an explicit "not from the catalog"
//     warning because the author key is self-attested.
//   - The team catalog is signed with the Sora team key. Catalog installs
//     additionally verify the downloaded archive hash against the catalog
//     entry. The team key is a placeholder until the owner completes the key
//     ceremony; every team-signature check fails closed until then (same rule
//     as packaging/install/install.sh).
//   - At runtime an enabled extension only reaches the core through
//     ExtensionHost with a per-extension token scoped to its granted
//     permissions. Disabling an extension revokes the token.
//
// The app (Flutter) owns the user-facing lifecycle — install, the permission
// prompt, panels in a WebView, settings forms — and mirrors the manifest and
// verification logic in Dart (app/lib/src/ext). This package is the reference
// implementation plus the core-side host service.
package ext
