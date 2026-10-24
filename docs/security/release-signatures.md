# Release signatures

The native verifier, Windows/Linux in-app updater and Linux rollback enforce the
signature contract below. The privileged Linux helper repeats verification on
its private snapshot before running a package manager. Initial installers and
authenticated bootstrap remain unfinished; S2 is still open.

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

The app downloads the signature before any package, authenticates the exact
manifest bytes, then persists both files for the helper and rollback. Rollback
rechecks the signature before trusting cached hashes; replacing a package and
its checksum together does not authorize a downgrade. Network and cached metadata
are bounded to the same 1 MiB/8 KiB limits as the native command. Production uses
the compiled team root; tests inject an ephemeral public identity in code, never
from settings, the environment or downloaded assets.

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
Go toolchain and a Windows cross-build. The updater tests verify signatures made
by the Go CLI using the existing Dart implementation.

## Validation and remaining acceptance

Tests generate ephemeral keys and exercise actual signatures: altered payload,
wrong key, untrusted signer, wrong version, catalog replay, missing/oversized
files, non-regular inputs and ambiguous command flags. They also check that
verification does not create core state and that the native trust root agrees
with the application's team key.

The fifteen committed signature fixtures were generated with `sora-ext sign-file`
and one temporary test key, whose private part was deleted. They cover the current
Windows/deb/rpm/Arch test payloads, previous Linux payloads, and signatures for an
incorrect version or catalog role over otherwise identical bytes. No production
key signed those fixtures. The updater rejection matrix exercises every supported
package format and checks that untrusted metadata stops before package download,
elevation, manual-install suggestions or restart. Cached package-plus-manifest
tampering, missing signatures and oversized metadata are also rejected.

The Linux namespace suite checks the private snapshot, installed-verifier
invocation and installer boundary using stubbed OS queries and a verifier stub.
It covers verifier rejection/absence, missing/symlinked signatures and ignores a
downloaded fake verifier. Cryptographic correctness is exercised separately by
the native tests and Go-to-Dart fixtures; this is not a real package installation
or Windows elevation test.

## Signed-release transition

There is no unsigned fallback. Previously published unsigned releases cannot be
installed by this updater or used as rollback targets. Before shipping it, the
release owner must independently authenticate and sign both the new manifest and
the previous Linux rollback release, or establish another reviewed transition.
An older installed native verifier that does not understand the command also
causes the helper to refuse installation. Publishing signatures or re-signing an
old release is a separate release action; this change performs neither.

Still required by S2: enforcement in both initial installers, the reviewed
transition, a publication gate that keeps the private key outside CI, authenticated
bootstrap, key rotation/revocation and real installation/elevation rejection tests
on both platforms. Windows does not yet implement automatic rollback.
