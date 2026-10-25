# Release signatures

The native verifier, Windows/Linux install scripts, in-app updater and Linux
rollback enforce the signature contract below. The privileged Linux helper
repeats verification on its private snapshot before running a package manager.
The first-install trust prerequisites below are mandatory; S2 is still open.

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
path for those prerequisites. No production key was created, copied or used to
sign test data here.

## Initial installation

Use a previously authenticated local copy of the installer script. Both scripts
require a previously trusted `sora-core` verifier, defaulting to
`/usr/bin/sora-core` or `%ProgramFiles%\Sora\core\sora-core.exe`. An absolute
`SORA_VERIFIER` path can select a separately authenticated build. It is never
downloaded automatically and cannot come from the `SORA_DIST` directory.

For a first installation, build the verifier from an independently authenticated,
reviewed source checkout with the pinned root, or obtain it through another
authenticated distribution channel. Compiling arbitrary freshly downloaded
source does not establish that trust. An older installed core without this
verification command is also rejected. For an already authenticated checkout:

```sh
(cd core && go build -trimpath -o ../trusted-verifier ./cmd/sora-core)
SORA_VERIFIER="$PWD/trusted-verifier" sh packaging/install/install.sh
```

```powershell
Push-Location core
go build -trimpath -o ../trusted-verifier.exe ./cmd/sora-core
if ($LASTEXITCODE -ne 0) { throw 'Verifier build failed' }
Pop-Location
$env:SORA_VERIFIER = (Resolve-Path ./trusted-verifier.exe).Path
& ./packaging/install/install.ps1
```

These are bootstrap prerequisites for reviewed distributions, not a consumer
one-command trust solution. A signed Windows installer or trusted Linux package
channel still needs release-owner provisioning before a general release.

The scripts first copy/download bounded manifest and detached signature files,
and `release.json` when the checksum table declares it. That declaration may
cause only a bounded metadata fetch before authentication. The trusted verifier
then checks the requested stable version, signature and declared JSON. A rejection
stops before package download, UAC or package-manager execution. Packages are
copied into the private working snapshot and hashed; missing or duplicate
checksum entries are rejected. An authenticated artifact query checks the selected
OS/architecture and returns its signed byte size before copying or streaming that
package. An exact length check also runs before installation. No unsigned
compatibility fallback is provided.

Network installation on Linux requires curl 8.4 or later: earlier versions do
not enforce `--max-filesize` on chunked responses. Older curl is rejected before
downloads; authenticated local `SORA_DIST` installation remains supported. Local
copies use bounded `head` reads, and network transfers require HTTPS redirects,
size and time limits. Windows uses the existing .NET HttpClient with response
headers first, a separately timed bounded stream, and the same loop for local
inputs. No extra PowerShell module or runtime is downloaded.

CI prepares separate test inputs with a short-lived key, builds a verifier from
a temporary source copy with that test root and deletes the private key. The
repository and shipped core retain the production root. These tools and signed
test manifests are outside the uploaded release assets. The rejection suite uses
actual Minisign verification and intercepts only the final installation boundary
(a Linux namespace or PowerShell process-launch interception); full package
installation is exercised separately by the platform jobs.

The Linux suite requires a working network namespace and asserts that its
sandbox started in every case, including rejection cases. A namespace setup
failure is a test failure, not an accepted signature rejection. The hosted
Ubuntu job runs the suite with sudo to permit namespace setup; it keeps network
isolation and the read-only host mount instead of disabling those boundaries.
Only the private fixture directory is mounted writable inside the sandbox.

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

The command verifies the manifest signature and any declared metadata, not the
package files. Callers must subsequently check each package's hash,
expected name, platform and architecture before installation. Signature checking
does not authorize a downgrade; the caller's version policy remains required.

The native command accepts the two required flags, optionally with both
`-release-artifact NAME -release-target OS/ARCH`. This query repeats authentication
and prints only the signed size as a decimal integer. Zero identifies a signed
legacy manifest without JSON; callers retain a 2 GiB ceiling and verify its
checksum, never interpret zero as an unlimited download. An unknown artifact,
missing checksum or target mismatch fails. A verifier predating the query refuses
the flags and cannot silently authorize an installation.

Empty or incomplete verification/query flags and unrelated operator flags are
rejected. Verification exits before core construction, token access, service registration
or network configuration. Manifest and signature inputs must be nonempty regular
files, at most 1 MiB and 8 KiB respectively. Use a private snapshot of downloads;
this command is not a replacement for privileged caller ownership/TOCTOU checks.

## Complete snapshot verification before publication

The manifest-only command above intentionally works before packages have been
downloaded. To check the complete release snapshot with a previously authenticated
verifier, use the stricter profile:

```sh
sora-core -verify-release /path/to/private-release-snapshot \
  -release-version 1.2.3 -verify-release-files
```

This mode requires schema 1 metadata and its complete current matrix: the Windows
amd64 installer, both installation scripts, six Linux amd64 packages and three
Linux arm64 core packages. Legacy manifests and an otherwise correctly signed
partial matrix fail this publication preflight. An artifact/target query cannot
be combined with this mode, and explicitly disabling its boolean flag is rejected.

Every artifact must be a regular file of exactly the signed length. Hashing uses
a bounded stream, checks file identity when opening and size/modification time
after reading, and compares SHA-256. Cancellation closes the active input file
instead of leaving Ctrl+C waiting for every large package hash. Metadata bytes
must still equal those that were authenticated. Directory enumeration reads at most the expected count plus
one and rejects missing or unlisted entries, including an extra report or nested
directory. Keep generated reports outside the private snapshot.

The command reads files and exits before constructing the core; it does not
download, sign, install or publish anything. Its success message explicitly says
that all twelve artifact files were verified. General install and rollback paths
continue to use their existing signature and selected-artifact policies.

This is the file-verification component of a publication gate, not enforcement of
repository publishing permissions or a complete independent gate. The supported
publication workflow still needs to invoke it with an independently trusted
verifier and protect the verified asset set until publication. Use an owned,
private snapshot without concurrent writers; these checks do not make an arbitrary
shared directory immutable. Declared OS/architecture are not independent PE/ELF
inspection. Consumer bootstrap, release-owner approval and the signed-release
transition remain required before any public release.

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

### Native metadata dependencies

On 25 October 2026, the existing Go module requires Go 1.26.9 with toolchain
1.27.3. Standard `encoding/json`, `crypto/sha256` and `sort` provide decoding,
hashing and canonical table ordering with zero new dependencies. Protocol-specific
target/size rules and a byte-for-byte re-encoding check reject ambiguity left by
the general JSON decoder, including duplicate or case-folded keys. No JSON parser
or cryptography is implemented locally.

| Considered library | Latest release | Stars | Open issues including PRs | Go module zip | License | Minimum Go |
| --- | --- | ---: | ---: | ---: | --- | --- |
| [jsonschema/v6](https://github.com/santhosh-tekuri/jsonschema) | v6.0.3, 2026-08-06 | 1289 | 47 | 94453 B | Apache-2.0 | 1.21 |
| [go-json](https://github.com/goccy/go-json) | v0.11.2, 2026-09-30 | 3753 | 19 | 643927 B | MIT | 1.23 |

Both are active and compatible with the toolchain. JSON Schema adds a schema
compiler and two declared module requirements but cannot replace the wire-format
byte comparison; go-json replaces a parser that is already available and still
needs the same domain checks. Standard JSON is sufficient; no package is added
or experimental JSON implementation enabled. Figures come from the repositories'
release/license/go.mod metadata and proxy.golang.org module archives.

The existing curl client and .NET HttpClient are reused for transport. See the
[curl size-limit contract](https://curl.se/docs/manpage.html#--max-filesize) and
[HttpCompletionOption timeout scope](https://learn.microsoft.com/en-us/dotnet/api/system.net.http.httpcompletionoption).
The latter requires a separate content-read deadline when using response headers
first; relying on HttpClient.Timeout alone would leave that read unbounded.

## Validation and remaining acceptance

### Release metadata producer

The release-draft workflow generates `release.json` and `SHA256SUMS` with
`python3 -B packaging/install/release_manifest.py DIST VERSION`. It does not
sign or publish anything. Signing the resulting SHA256SUMS with the independent
key also binds the exact `release.json` bytes through their listed SHA-256.

Schema 1 contains `schema`, `version` and `artifacts`. Each artifact records
`name`, `os`, `arch`, `size` in bytes and lowercase `sha256`. Artifact names are
sorted; JSON uses sorted keys, compact separators, ASCII and one final newline.
There are no timestamps or absolute paths in the document. `release.json` is
listed in SHA256SUMS and is not recursively listed in its own artifact array.

The producer recognizes the existing Windows x64 installer, Linux deb/rpm/Arch
packages for amd64/arm64, and the two installation scripts. ARM64 has only the
core package. Script architecture is `any`; executable/package architecture is
derived from the existing build filename contract. This is a declared target,
not an independent PE/ELF architecture inspection. Unknown names or a mixture of
versions fail instead of being silently assigned a platform.

Inputs must be regular, nonempty files, at most 2 GiB each and 128 files total.
Symlinks/directories and changes detected during hashing are rejected. Existing
metadata or a detached signature is never overwritten. Tests cover all current
artifact names, deterministic output, standard sha256sum compatibility, metadata
tampering, invalid inputs, stale outputs and a file mutation during hashing.

### In-app metadata enforcement

After authenticating SHA256SUMS, the app decides whether `release.json` is
required from that signed payload. Removing the JSON asset from the GitHub API
cannot select a legacy format. The app fetches at most 1 MiB of JSON, verifies
its listed hash, and validates schema 1, the requested version, current artifact
names, declared OS/architecture, positive sizes up to 2 GiB, lowercase hashes,
and a sorted, unique artifact list of at most 128 entries. Re-encoding with the
producer's canonical rules rejects duplicate or unknown keys, alternative
encodings and unexpected field order. The reconstructed checksum table must
equal the entire signed SHA256SUMS, including the metadata entry.

Selected packages must match the local Windows/Linux amd64 target. Their signed
sizes bound streaming downloads and replace the untrusted API package sizes;
both truncated and oversized responses fail before installer handoff. Local
package verification also checks bounded length and SHA-256. ARM64 is not added
to the desktop updater by this change.

The app saves the exact JSON bytes with the signed manifest in its working
snapshot and Linux rollback cache. Offline rollback reauthenticates the cached
manifest and JSON and enforces target and size again before invoking the helper.
The root-owned Linux helper snapshots any supplied JSON, requires it when the
signed checksum table declares it, and checks its nonempty, bounded contents
against that table before the package manager runs. An unlisted JSON is rejected.
The helper now invokes the installed native verifier to parse schema 1 and query
each package's signed size and expected Linux/amd64 target on that root-owned
snapshot. It also retains its own checksum, length and package-manager metadata
checks. Initial-install scripts use the same native query with the detected target,
including Linux arm64 core packages; Windows selects the existing amd64 build.

Previously signed manifests without a JSON reference remain accepted by the
existing signature and version policies, including Linux rollback. In the app,
their size comes from the API with a hard 2 GiB ceiling, not authenticated metadata.
This is explicit signed-format compatibility, not unsigned fallback. New producer
output always declares JSON in the signed checksum table. The release transition
must determine when legacy signed formats can be retired before claiming that
every supported installation path requires schema 1.

The metadata fixtures are generated by the production Python producer and signed
by the Go CLI with a temporary key. Its private part is deleted. Go-to-Dart tests
check canonical interoperability, signed malformed documents, metadata omission
and tampering, incorrect API package sizes, chunked-response overflow and offline
rollback cache failures. Tests intercept only the final privileged handoff. The
same metadata tests also run in the native Windows CI job; helper contract tests
cover valid, empty, missing, corrupt, symlinked, oversized and unlisted snapshots.

Native Go tests consume the same producer/signer fixtures as Dart and reject
signed malformed documents and missing, replaced, oversized or linked JSON.
The initial-install rejection matrix uses real signatures and intercepts only
the final package-manager/Windows process boundary; a separate marker records
actual entry into that boundary. Windows PowerShell 5.1 and PowerShell 7 exercise
the bounded local-copy path. Package hashing uses .NET SHA-256 directly, including
environments where the optional Get-FileHash command is unavailable.

A Linux Go test serves the fixture bytes over loopback TLS with a temporary
test CA trusted only by that curl process. It forces chunked transfer without
Content-Length and checks valid, truncated/oversized package, tampered/oversized/
missing JSON and old-curl rejection cases. Packages cannot be requested before
metadata authentication. These tests perform no host installation, sudo, service
or network-configuration changes. Windows HTTP response timing and real elevation
failures still need separate isolated validation.

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

On 25 October 2026, the authenticated GitHub release API returned eleven visible
release records. None listed `SHA256SUMS.minisig`, `release.json` or a separate
`.sig`/`.asc`/`.minisig` asset. The latest stable releases v1.1.2, v1.1.1 and
v1.1.0 carried checksum manifests and the expected package matrix. This inventory
checks asset metadata, not package provenance, embedded Authenticode signatures
or releases distributed outside GitHub. It provides no evidence of an existing
production population that requires the draft legacy signed-manifest format.
Retiring that temporary compatibility path needs an explicit transition policy;
do not confuse fixture compatibility with deployed-client compatibility.

There is no unsigned fallback. Previously published unsigned releases cannot be
installed by this updater or used as rollback targets. Before shipping it, the
release owner must independently authenticate and sign both the new manifest and
the previous Linux rollback release, or establish another reviewed transition.
An older installed native verifier that does not understand the command also
causes the helper to refuse installation. Publishing signatures or re-signing an
old release is a separate release action; this change performs neither.

Still required by S2: the reviewed transition, a publication gate that keeps the
private key outside CI, a provisioned consumer bootstrap channel, key rotation/revocation and the
remaining real installation/elevation rejection matrix. Windows does not yet
implement automatic rollback. Do not publish a release before the signed-release
transition is ready.
