# Team catalog and revocation list

The app downloads these files from the main branch and verifies them with
the compiled team key (`core/ext/sign.go`, `app/lib/src/ext/verifier.dart`):

- `catalog.json` and `catalog.json.minisig`: the legacy store catalog used by
  the published v1.1.2 client;
- `catalog-1.1.3.json` and `catalog-1.1.3.json.minisig`: the catalog for
  Sora 1.1.3 to 1.1.5;
- `catalog-1.1.6.json` and `catalog-1.1.6.json.minisig`: the catalog for
  Sora 1.1.6 and later;
- `revocations.json` and `revocations.json.minisig`: versions the app must
  disable and refuse;
- `packages/`: the signed `.soraext` files the catalog points at.

## Publishing an extension

1. Build and sign the package with its author key: `sora-ext pack` and
   `sora-ext sign`, then `sora-ext publish` prints the catalog entry.
2. Copy the package into `packages/`, add the entry to the catalog for the
   supported host with `download_url` pointing at it, and set `updated_at`.
   Review actual host support and set `platforms` explicitly when the extension
   is restricted to specific operating systems. OS metadata does not certify
   architecture, backend, driver or API availability.
3. Sign the chosen catalog with the team key, using the `catalog.json` role
   even when the file has a versioned name:
   `sora-ext sign-file --key sora-team.key --role catalog.json extensions/catalog-1.1.3.json`

Signing adds a signature to the archive and changes its package hash and size.
Use the values reported by `publish` **after** author signing for the catalog;
the command validates and prints an entry but does not upload it. For a catalog
install, package size and hash must match the entry; the signed manifest's id,
version, minimum app version and permissions must also match. When an entry
declares capabilities, they must match the manifest; older entries may omit
them. Verify the signed catalog with the pinned production root before delivering it.

Zapret 1.0.0, ByeDPI 1.0.0 and Hello Panel 1.0.1 require Sora 1.1.3 and are
listed in `catalog-1.1.3.json`. Zapret 1.1.0 and ByeDPI 1.1.0 add panels
that call `getBypass`/`setBypass`, so they require Sora 1.1.6 and are
listed only in `catalog-1.1.6.json`. Zapret and ByeDPI 1.1.1 match the app and
follow its theme. Hello Panel left that catalog. The v1.1.2 client uses the legacy URL and
offers an install action before it checks a package's minimum host version, so
entries that require a newer host stay out of `catalog.json`.

Both catalogs use the same team key and `catalog.json` signature role, so the
file name does not provide a separate cryptographic scope or rollback
protection. A host that points at a new versioned URL ships only after that
catalog and its signature are available and verify there. The existing v1.1.2 updater and the first
signed-release transition have separate trust requirements described in
[release signatures](../docs/security/release-signatures.md#published-v112-update-boundary).

The app test `ext_revocation_catalog_test.dart` checks both catalog signatures
and the revocation signature, then verifies and installs every committed package
against its catalog entry.

## Revoking

Add an entry (`id`, `versions` as `*`, `=x.y.z`, `<x.y.z` or `<=x.y.z`,
`reason`), set `updated_at`, and sign with `--role revocations.json`.

## Renewal

The revocation list carries `expires_at`; once it passes, the app refuses
new installs until it gets a fresh list, because a stale list may miss a
revocation. Re-sign before it expires: bump `updated_at` and `expires_at`
and run the `--role revocations.json` command above.
