# Release signatures

The native verifier and signing command implement the signature contract below.
Installation, in-app updates and rollback do not enforce it yet. S2 remains open
until those callers verify signatures before executing downloaded code.

## Trust boundary

An attacker controlling GitHub release assets can replace both a package and its
unsigned SHA256SUMS. HTTPS and a matching checksum do not establish who approved
the package. The signature must come from a key outside the release workflow.

The verifier pins the existing Sora team public key, also used by the app for
extension catalogs. It does not load keys from release assets, environment
variables or command-line arguments. The corresponding private key remains
outside GitHub Actions. Reusing this root shares the compromise scope of team
documents and releases; document roles prevent replay between those uses, but
do not protect against compromise of that private key.

The root must be trusted before running the verifier. A newly downloaded
installer, script or verifier cannot authenticate itself. Never describe
`curl | sh` or `irm | iex` from the same release as authenticated bootstrap.
Initial installation still needs an independently authenticated distribution
path. No production key was created, copied or used to sign test data here.

## Contract

The payload is the exact SHA256SUMS bytes. The detached file is
`SHA256SUMS.minisig`. Its Minisign trusted comment follows the existing Sora
format, with the role `release:vVERSION:SHA256SUMS`. VERSION is a stable,
three-component decimal version without leading zeroes, at most 64 characters.
The payload digest and trusted comment are authenticated by the existing
Minisign implementation. A catalog signature or another version's signature is
rejected even when its payload is identical.

Using a previously trusted build of sora-ext, on the signing machine:

```sh
sora-ext sign-file --key "$SORA_SIGNING_KEY_FILE" \
  --role release:v1.2.3:SHA256SUMS SHA256SUMS
```

Using a previously trusted build of sora-core, before using the manifest:

```sh
sora-core -verify-release /path/to/private-release-snapshot -release-version 1.2.3
```

The command verifies the manifest signature, not the package files. Its success
message says exactly that. Callers must subsequently check each package's hash,
expected name, platform and architecture before installation. Signature checking
does not authorize a downgrade; the caller's version policy remains required.

The native command accepts only these two flags, including when a supplied value
is empty. It exits before core construction, token access, service registration
or network configuration. Manifest and signature inputs must be nonempty regular
files, at most 1 MiB and 8 KiB respectively. Use a private snapshot of downloads;
this command is not a replacement for privileged caller ownership/TOCTOU checks.

## Implementation choice

Snapshot of upstream metadata on 24 October 2026:

| Candidate | Latest release | Stars | Open issues including PRs | Distribution size | License |
| --- | --- | ---: | ---: | --- | --- |
| [Minisign C](https://github.com/jedisct1/minisign) | 0.12, 2025-01-15 | 2864 | 0 | Linux archive 271043 B; Windows archive 252505 B | ISC |
| [Cosign](https://github.com/sigstore/cosign) | v3.1.4, 2026-10-20 | 6381 | 108 | Linux amd64 executable 145688404 B | Apache-2.0 |
| [aead.dev/minisign](https://github.com/aead/minisign) (already installed) | v0.3.0, 2024-05-19 | 140 | 4 | No new distribution or dependency | MIT |

Reuse Sora's existing Minisign Go and Dart implementations: the core already
depends on aead.dev/minisign and the app already verifies team documents with
cryptography. This avoids a second signing format or a bundled external verifier.
The C project's README recommends its successor minizign for new features. The
Go library's release is older than two years: maintenance is a recorded audit
risk, not evidence of an independently audited crypto implementation. No new
dependency is installed. Native compatibility is checked with the repository's
Go toolchain and a Windows cross-build; updater integration still needs Dart
interoperability tests.

## Validation and remaining acceptance

Tests generate ephemeral keys and exercise actual signatures: altered payload,
wrong key, untrusted signer, wrong version, catalog replay, missing/oversized
files, non-regular inputs and ambiguous command flags. They also check that
verification does not create core state and that the native trust root agrees
with the application's team key.

Still required by S2: signature enforcement in both installers and the updater,
signed rollback-cache verification, a publication gate that keeps the private key
outside CI, authenticated bootstrap, key rotation/revocation and a full successful
installation plus rejection matrix on both supported platforms. This change
does not publish or re-sign an existing release.
