# Team catalog and revocation list

The app and the core download these files from the main branch and verify
them with the team key compiled into both (`core/ext/sign.go`,
`app/lib/src/ext/verifier.dart`):

- `catalog.json` and `catalog.json.minisig`: the extensions offered in the
  store;
- `revocations.json` and `revocations.json.minisig`: versions the app must
  disable and refuse;
- `packages/`: the signed `.soraext` files the catalog points at.

## Publishing an extension

1. Build and sign the package with its author key: `sora-ext pack` and
   `sora-ext sign`, then `sora-ext publish` prints the catalog entry.
2. Copy the package into `packages/`, add the entry to `catalog.json` with
   `download_url` pointing at it, and set `updated_at`.
3. Sign the catalog with the team key:
   `sora-ext sign-file --key sora-team.key --role catalog.json extensions/catalog.json`

`core/ext` test `TestPublishedTeamDocumentsVerify` and the app test
`ext_revocation_catalog_test.dart` check the signatures and that every
entry matches its committed package.

## Revoking

Add an entry (`id`, `versions` as `*`, `=x.y.z`, `<x.y.z` or `<=x.y.z`,
`reason`), set `updated_at`, and sign with `--role revocations.json`.

## Renewal

The revocation list carries `expires_at`; once it passes, the app refuses
new installs until it gets a fresh list, because a stale list may miss a
revocation. Re-sign before it expires: bump `updated_at` and `expires_at`
and run the `--role revocations.json` command above. The core test fails
two weeks before expiry as a reminder.
