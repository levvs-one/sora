# Release signatures

The native verifier, Windows/Linux install scripts, in-app updater and Linux
rollback enforce the signature contract below. The privileged Linux helper
repeats verification on its private snapshot before running a package manager.
First installation uses the explicit HTTPS bootstrap boundary below; installed clients require signed updates. S2 still has the owner acceptance items listed below.

The Linux helper now prepares its private pair with the installed core's
`-prepare-update` mode, authenticating metadata before bounded package copies.
See the [privileged snapshot boundary](privileged-update-snapshot.md) for file
descriptor, permissions, cancellation and old-core rejection guarantees. The
core and helper must be distributed together through the reviewed transition.

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

A new user can install with one command:

```sh
curl -fsSL https://github.com/levvs-one/sora/releases/latest/download/install.sh | sh
```

```powershell
irm https://github.com/levvs-one/sora/releases/latest/download/install.ps1 | iex
```

**These commands trust the HTTPS download of the script itself.** The pinned
key inside a freshly downloaded script cannot independently authenticate that
script. For an independently authenticated bootstrap, obtain and review the
script and its pinned key through an independent trusted channel first.

When a modern installed core is available, both scripts retain the strict
native schema 1 verifier and signed artifact-size query. An explicit absolute
`SORA_VERIFIER` selects a separately authenticated build: a missing, downloaded
or rejecting explicit verifier is an error, never a bootstrap fallback.
The default old core without `-verify-release` is treated as a first-install
transition; a modern core rejecting metadata never falls back.

Without a pre-installed verifier the scripts check the exact SHA256SUMS bytes
with the pinned team key using a system OpenSSL (Ed25519 `pkeyutl -rawin`) or
minisign. OpenSSL checks both the payload and global trusted-comment signatures,
the key ID, versioned role and SHA-256 in that comment. `Ed` signs the bounded
payload directly, matching the existing Go signer; `ED` uses the Minisign
BLAKE2b-512 prehash. These are protocol variants, not Ed25519ph. A crypto-tool
failure aborts; it is never retried as unsigned bootstrap. No verifier is
downloaded or executed to authenticate itself.

If neither system crypto tool exists, bootstrap explicitly reports that it
trusts HTTPS plus the downloaded checksum table. Windows PowerShell 5.1 has no
built-in Ed25519/BLAKE2b verifier, and no runtime or module is downloaded to add
one. Install OpenSSL 3 or minisign through a trusted OS channel before running
the command if independent package authentication is required at first install.
This exception applies only to the installation script's bootstrap; in-app
updates, rollback, privileged snapshots and explicit verifier paths stay strict.

Both bootstrap paths require release.json and its matching checksum before
package installation. Windows parses its version/target/size with the built-in
ConvertFrom-Json and streams the selected installer within that size. Linux
bootstrap downloads only the two native package names derived from the requested
version and OS architecture, with a fixed 2 GiB ceiling each, then requires one
matching checksum per package. Full canonical schema/size queries remain the
native verifier's contract when installed. All package hashes are checked
before UAC or a package-manager invocation. SORA_DIST uses the same private
snapshot and verification rules without network access.

The implementation reuses existing shell/coreutils, curl and .NET HttpClient,
SHA256 and JSON APIs. The system crypto tools were compared on 28 October 2026:

| Tool | Latest release | Stars / open incl. PRs | Distribution | License / runtime |
| --- | --- | --- | --- | --- |
| OpenSSL | 4.1.0, 2026-10-23 | 31104 / 1628 | source archive 55738000 B | Apache-2.0; native CLI, required API available since 3.0 |
| minisign | 0.12, 2025-01-15 | 2870 / 0 | Linux archive 271043 B; Windows archive 252505 B | ISC; native standalone CLI |

No dependency is downloaded by the installer. Reusing available system tools
keeps the one-command flow; the existing Go verifier stays authoritative for
installed clients. See the [OpenSSL Ed25519 API](https://docs.openssl.org/3.0/man1/openssl-pkeyutl/)
and [Minisign wire format](https://jedisct1.github.io/minisign/#signature-format).

The scripts first copy/download bounded manifest and detached signature files,
and require `release.json` in the checksum table. That declaration may
cause only a bounded metadata fetch before authentication. When installed, the trusted verifier
then checks the requested stable version, signature and declared JSON. A rejection
stops before package download, UAC or package-manager execution. Packages are
copied into the private working snapshot and hashed; missing or duplicate
checksum entries are rejected. An authenticated artifact query checks the selected
OS/architecture and returns its signed byte size before copying or streaming that
package. An exact length check also runs before installation. The installed-verifier path provides no unsigned
compatibility fallback; the explicit first-install trust boundary is described above.

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

The command verifies the manifest signature and required schema 1 metadata, not the
package files. Callers must subsequently check each package's hash,
expected name, platform and architecture before installation. Signature checking
does not authorize a downgrade; the caller's version policy remains required.

The native command accepts the two required flags, optionally with both
`-release-artifact NAME -release-target OS/ARCH`. This query repeats authentication
and prints only the positive signed size as a decimal integer. Signed manifests
without authenticated schema 1 JSON are refused; zero is no longer a supported
size response. The scripts/helper reject zero even from an older verifier,
without substituting an API size or a generic ceiling. An unknown artifact,
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
amd64 installer, both installation scripts, six Linux amd64 packages and six
Linux arm64 packages (core and app). Legacy manifests and an otherwise correctly signed
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
that all fifteen artifact files were verified. General install and rollback paths
continue to use their existing signature and selected-artifact policies.

This is the file-verification component of a publication gate, not enforcement of
repository publishing permissions or a complete independent gate. The supported
publication workflow still needs to invoke it with an independently trusted
verifier and protect the verified asset set until publication. Use an owned,
private snapshot without concurrent writers; these checks do not make an arbitrary
shared directory immutable. Declared OS/architecture are not independent PE/ELF
inspection. Release-owner approval and the signed-release transition remain required;
the explicit 1.1.3 bootstrap boundary is described above.

## Protected GitHub publication path

`.github/workflows/release-gate.yml` supplies a manual, two-phase publication
path; `packaging/release/gate.py` is its policy and transport entry point. The
workflow builds the pinned-root native verifier from the reviewed workflow
commit on `main`, never from release assets or the release tag. A private
temporary snapshot holds downloads, separately from that verifier. The signing
key remains outside CI. Nothing in this path signs a release.

The read-only preflight requires the repository's immutable-release setting,
an existing `release` environment with explicit User reviewers and self-review
disabled, and a custom deployment policy selecting only the `main` branch.
Missing policy or credentials fail before package downloads. Teams are refused
because this path does not have permission to prove their current membership.
The policy API needs Administration(read), which `GITHUB_TOKEN` cannot request.
Provision a separate, narrowly scoped `SORA_RELEASE_POLICY_TOKEN` with repository
Administration(read) and Actions(read), using the owner's approved credential
management. Do not copy a developer's existing CLI token into Actions.

The publishing job additionally requires a recorded environment approval by a
different configured reviewer. Bypassing an environment does not create that
approval. The REST environment representation does not expose the admin-bypass
setting; this code does not invent or claim to inspect it. Configure bypass
restrictions separately as defence in depth. Review history does not bind an
approval to a run attempt, so write operations refuse reruns: use a new manual
dispatch, with a new approval, after any failure. The workflow also verifies its
repository, main-branch source, path, run SHA and initiating actor through the API.

Each dispatch specifies the stable version tag, the independently approved full
source commit and one stage:

1. `verify` only authenticates policy, tag and complete signed snapshot.
2. `publish-prerelease` repeats verification after approval, publishes a draft
   with `prerelease=true` and `make_latest=false`, then requires an immutable
   result with the same asset IDs, names, sizes and digests and the expected tag
   commit. An already frozen, matching prerelease is checked without another write.
3. `promote` accepts only an already immutable release, downloads and verifies
   every signed file again, then sets the stable/latest flags after a separate
   approval. A matching immutable stable release is an idempotent success.

GitHub draft uploads and publication are not atomic. A concurrent change after
the last draft check can enter the initial prerelease. The postcondition detects
it and refuses stable promotion; it cannot retract already published bytes.
No automatic deletion, retry, repair or stable fallback occurs. A failed freeze
needs release-owner investigation. Immutability must be enabled before the
freeze; old mutable releases are refused rather than being retroactively trusted.
GitHub permits prerelease/latest changes on immutable releases while keeping
their tag and assets locked. See [immutable release guarantees](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases).

Downloads use the existing authenticated `gh api` for metadata queries
and curl 8.4+ for bounded HTTPS asset streams. Asset URLs are constructed from
validated numeric GitHub IDs, not supplied URLs. The token header goes through
curl's stdin configuration, stays out of process arguments, and is not forwarded
to another origin. Metadata bounds are fixed; package bounds come from the
authenticated JSON. API digests bind the snapshot to the frozen asset identity;
the independent Minisign signature and native full profile authenticate bytes.
The Python standard library handles orchestration, JSON and hashing; there is
no new HTTP, authentication, retry or cryptography implementation/dependency.
The gate rejects gh output above 2 MiB after the client returns, and projects at
most nineteen assets to reject an oversized matrix. This is not a transport-level
memory bound on gh's own JSON decoder; package streams have the enforced curl
byte limit described above.

Upstream snapshot on 25 October 2026 (open counts include PRs):

| Candidate | Latest release | Stars / open | Distribution | License / runtime |
| --- | --- | --- | --- | --- |
| [GitHub CLI](https://github.com/cli/cli) | v2.103.2, 2026-10-23 | 46738 / 1098 | Linux amd64 archive 15031001 B | MIT; standalone |
| [curl](https://github.com/curl/curl) | 8.23.0, 2026-10-14 | 43240 / 88 | source archive 2990916 B | curl permissive license; standalone |
| [Requests](https://github.com/psf/requests) | 2.34.2, 2026-05-14 | 54651 / 244 | wheel 73075 B | Apache-2.0; Python >=3.10 |

Reuse the existing gh/curl clients and Python 3.12+ standard library: Requests
would add four runtime dependencies without replacing gh's existing authentication
or curl's streaming limit. Tests use actual native Minisign/file verification
with the public fixture root in a temporary source copy; GitHub API/write and
transport boundaries are simulated. They do not publish or configure anything.

On 25 October 2026, the repository policy endpoint reported immutable releases
disabled and no environments existed. This workflow is prepared code, not a
provisioned or live-tested production gate. Do not dispatch a publishing stage
until the owner explicitly approves configuration and the software publication.
After approved setup, first run `verify` and review its outcome. A YAML environment
name alone is not protection and may create an unprotected environment.

This is the supported publication path, not a claim that all GitHub writers are
technically restricted to it. Existing draft-build workflow permissions and
repository administrators remain separate write channels. Protect workflow/source
changes and inventory/restrict other writers before claiming repository-wide
enforcement. The tag/commit comparison is not build provenance: schema 1 does not
sign the build source commit, and this gate does not prove how binaries were built.
Consumer bootstrap, unsigned transition, rotation/revocation, Authenticode and the
remaining failure/elevation matrix remain open S2 requirements.

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
packages for amd64/arm64, and the two installation scripts. Both Linux
architectures include core and app packages. Script architecture is `any`; executable/package architecture is
derived from the existing build filename contract. This is a declared target,
not an independent PE/ELF architecture inspection. Unknown names or a mixture of
versions fail instead of being silently assigned a platform.

The ARM64 build adds three app package names to the existing schema 1 allowlist
in the Python producer, Go verifier and Dart parser. Complete publication now
requires fifteen artifacts plus three metadata files; the API projection reads
at most nineteen assets so an extra asset is refused. Authenticated older
twelve-artifact metadata remains valid for selected-artifact installation, but
does not satisfy the new complete publication matrix. Public cross-language
fixtures include both cases, signed only by a temporary test identity. The
production root and all signature/role/canonical/size/target checks are retained.
This metadata compatibility does not by itself implement the ARM64 installer,
desktop update selection or privileged snapshot/helper path described below.

Inputs must be regular, nonempty files, at most 2 GiB each and 128 files total.
Symlinks/directories and changes detected during hashing are rejected. Existing
metadata or a detached signature is never overwritten. Tests cover all current
artifact names, deterministic output, standard sha256sum compatibility, metadata
tampering, invalid inputs, stale outputs and a file mutation during hashing.

### In-app metadata enforcement

After authenticating SHA256SUMS, the app requires its `release.json` entry;
absence is rejected before any package request. Removing the JSON asset from
the GitHub API or supplying unlisted JSON cannot select a legacy format.
The app fetches at most 1 MiB of JSON, verifies
its listed hash, and validates schema 1, the requested version, current artifact
names, declared OS/architecture, positive sizes up to 2 GiB, lowercase hashes,
and a sorted, unique artifact list of at most 128 entries. Re-encoding with the
producer's canonical rules rejects duplicate or unknown keys, alternative
encodings and unexpected field order. The reconstructed checksum table must
equal the entire signed SHA256SUMS, including the metadata entry.

Selected packages must match Windows amd64 or the native Linux amd64/arm64 target. Their signed
sizes bound streaming downloads and replace the untrusted API package sizes;
both truncated and oversized responses fail before installer handoff. Local
package verification also checks bounded length and SHA-256. The app uses the
standard Dart VM ABI to select Linux package filenames and the same signed target
for current downloads, rollback-cache preparation and offline rollback. Unsupported
ABIs are refused before package download or installer handoff. Windows still selects the
existing amd64 installer; no native Windows ARM64 release is authorized by this mapping.

The app saves the exact JSON bytes with the signed manifest in its working
snapshot and Linux rollback cache. Offline rollback reauthenticates the cached
manifest and JSON and enforces target and size again before invoking the helper.
The root-owned Linux helper requires JSON in its private snapshot and in the
signed checksum table, and checks its nonempty, bounded contents
against that table before the package manager runs. An unlisted JSON is rejected.
The helper now invokes the installed native verifier to parse schema 1 and query
each package's signed size and expected native Linux target on that root-owned
snapshot. It also retains its own checksum, length and package-manager metadata
checks. Initial-install scripts use the same native query with the detected target,
including both Linux arm64 packages; Windows selects the existing amd64 build.

The privileged snapshot derives its architecture from the installed Go binary,
and the helper derives its package names, target query and package-header checks
from a fixed uname whitelist. There is no user-selectable architecture option.
Mixed-architecture/emulated setups are not a verified contract; disagreement or
an absent native package fails rather than downloading an alternative. Existing
signature, canonical metadata, positive size, hash and private-snapshot checks
remain required. ARM64 CI runs the Go snapshot, signed Dart metadata/rollback
matrix and namespace helper contracts. Package managers and OS queries in those
contract tests are intercepted; this is not a real system upgrade or power-loss
rollback proof.

The draft signed format without JSON is retired on all consumer paths: native
verification/size queries, both initial scripts, in-app downloads, preparation
of a rollback cache, offline rollback and privileged Linux snapshots. A valid
Minisign signature alone does not satisfy the current metadata contract. Stray
unlisted JSON does not upgrade the format. The 2 GiB per-artifact maximum still
applies to positive signed sizes; it is not a fallback for missing metadata.
Existing legacy cache entries cannot be used for a downgrade or suggested as a
manual-install pair. Update preparation fails before privileged handoff if the
previous release cannot supply a trusted schema 1 rollback cache.

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

The fifteen older signature fixtures remain as genuine cryptographic negative
inputs for the retired format. Current lifecycle fixtures are regenerated by the
production metadata producer and Go signer with a separate ephemeral identity,
including previous schema 1 packages and incorrect version/catalog roles. Their
private keys are deleted, never copied or committed. No production key signed
those fixtures. The updater rejection matrix exercises every supported
package format and checks that untrusted metadata stops before package download,
elevation, manual-install suggestions or restart. Cached package-plus-manifest
tampering, missing signatures and oversized metadata are also rejected.

The Linux namespace suite checks the private snapshot, installed-verifier
invocation and installer boundary using stubbed OS queries and a verifier stub.
It covers verifier rejection/absence, missing/symlinked signatures and ignores a
downloaded fake verifier. An additional namespace case uses the real temporary-key
native verifier for valid, tampered and retired signed snapshots. This is not a real package installation
or Windows elevation test.

## Signed-release transition

### Published v1.1.2 update boundary

The published [v1.1.2 updater](https://github.com/levvs-one/sora/blob/v1.1.2/app/lib/src/updates.dart)
does not authenticate release signatures. Its Windows install path downloads
`SHA256SUMS` and the expected installer, compares their hashes and then hands
the installer to its launcher. When the rollout feed is unreachable it falls
back to offering the latest release. A signed 1.1.3 candidate does not add
signature verification to that already installed client.

On 27 October 2026, the existing `windows install: success` test was run from
an archive of the v1.1.2 tag using mocked HTTP and a fake launch callback: it
accepted checksum-only test bytes without requesting a signature. Its existing
rollout test also confirmed the unavailable-feed fallback. Current candidate
tests separately rejected missing and corrupt signatures before the install
handoff. These are controlled code-path tests, not real Windows installations
or proof of a completed migration.

The protected workflow first freezes a prerelease; the old parser rejects
prerelease records during normal operation. This helps stage a candidate but is
not an authenticated migration for v1.1.2 users. GitHub permits changing
prerelease/latest flags even for immutable releases, so immutability alone does
not give the legacy updater an independent signature check. A release plan must
cover the legacy clients, an independently authenticated bootstrap channel and
a reviewed rollback baseline before stable publication. Do not assume that a
rollout feed or a new package signature protects the old updater.

On 28 October 2026, the published v1.1.2 Windows installer was checked without
running it. Its size and SHA-256 matched the GitHub release API, and Windows
Get-AuthenticodeSignature returned NotSigned. Matching metadata from the same
distribution service does not independently authenticate the file. The
annotated v1.1.2 tag has no tag signature; GitHub reports the underlying commit
signature as valid, but that service assertion is not an independently pinned
signer identity. These checks do not cover other distributions or every bundled
binary, and do not establish a consumer bootstrap or a rollback baseline.

On 25 October 2026, the authenticated GitHub release API returned eleven visible
release records. None listed `SHA256SUMS.minisig`, `release.json` or a separate
`.sig`/`.asc`/`.minisig` asset. The latest stable releases v1.1.2, v1.1.1 and
v1.1.0 carried checksum manifests and the expected package matrix. This inventory
checks asset metadata, not package provenance, embedded Authenticode signatures
or releases distributed outside GitHub. It provides no evidence of an existing
production population that requires the draft legacy signed-manifest format.
The draft compatibility path is now explicitly retired in code. This inventory
does not prove that no externally distributed client ever used it; assess any
such population during the release-owner transition. Fixture compatibility is
not evidence of deployed-client compatibility.

There is no unsigned fallback. Previously published unsigned releases cannot be
installed by this updater or used as rollback targets. Before shipping it, the
release owner must provision an independently authenticated schema 1 baseline
and a reviewed rollback path. One option is a trusted manual/bootstrap installation
of a new signed baseline; subsequent updates can cache that baseline. Another
requires independently authenticating historical payloads, generating complete
schema 1 metadata and authorizing its signing/publication through a reviewed
transition. Merely attaching a signature to an old checksum-only release is
insufficient. For 1.1.3, the owner selected the HTTPS installation-script bootstrap above
to establish the first schema 1 baseline. This does not retrofit provenance
to old releases or add signature checks to an already installed v1.1.2 updater.
An older installed native verifier that does not understand the command also
causes the helper to refuse installation. Publishing signatures or re-signing an
old release is a separate release action; this change performs neither.

Still required by S2: the reviewed transition, provisioning/approval of the prepared
publication gate with its key outside CI, key rotation/revocation and the
remaining real installation/elevation rejection matrix. Windows does not yet
implement automatic rollback. For 1.1.3, install the new signed baseline through the bootstrap script;
subsequent updates can cache 1.1.3 for verified Linux rollback. Do not promise
rollback to unsigned 1.1.2. The Windows tag build also requires Authenticode
provisioning independently of Minisign; without it the release cannot build.
