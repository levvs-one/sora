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
// The app (Flutter) owns the user-facing lifecycle - install, the permission
// prompt, panels in a WebView, settings forms - and mirrors the manifest and
// verification logic in Dart (app/lib/src/ext). Which half of this package
// is which matters, so it is stated plainly:
//
//   - Live in the core binary today: the ExtensionHost service (host.go),
//     mounted by cmd/sora-core on the control socket; the token issuer
//     behind it, backed by the on-disk registry OpenStore loads (the host
//     paths use Get/Issuer, not the install lifecycle); the revocation
//     cache arming at startup; and the background Scheduler plumbing -
//     created and started at startup, its fetch transport wired to the
//     tunnel. Authenticated app lifecycle streams register tasks and run
//     their scripts in resource-limited disposable goja processes.
//   - Reference half: package verification (Package.Verify /
//     VerifyWithKey, including the declared-entry gate), the Store
//     install/update/rollback lifecycle, the catalog fetch/cache, the
//     ratings aggregation and the sideload-consent facts have no
//     production caller inside the core binary - the live install gate
//     is the Dart mirror. This half is not dead weight: the sora-ext CLI
//     calls it directly (ValidatePackage runs Package.Verify, the pack
//     and publish gates run the Store checks), and it is the executable
//     specification the Dart mirror is pinned against by tests on both
//     sides. The app registry remains the source of truth for lifecycle
//     streams; it is separate from the service-owned reference registry.
package ext
