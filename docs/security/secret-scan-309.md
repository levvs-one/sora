# Secret scan #309

Investigated on 24 October 2026 against main
`7dc4e6f0533cafcebc0c2753e12c31a5290d735f`.

## Evidence

[Security #307](https://github.com/levvs-one/sora/actions/runs/40030842096)
passed on a push. The scheduled
[#308](https://github.com/levvs-one/sora/actions/runs/40063369457) and
[#309](https://github.com/levvs-one/sora/actions/runs/40088610366) failed on
the same SHA. The #309 annotation reports detected leaks, and its
`gitleaks-results.sarif` artifact is available as artifact 12557768789.
The original SARIF was downloaded through the owner's existing authenticated
GitHub CLI on the main computer, without transferring its credential. Its
SHA-256 is `47d57cffbb99bd1ca674ce03e872d72fdd2735e1af8fb0232a28001485a6faf4`.
It contains twelve findings: the six main-branch fixtures below and six
findings from other fetched history.

The pinned source of gitleaks-action v2 defaults to Gitleaks 8.24.3. Push
events scan a commit range; scheduled events scan history. Reproducing the
main history scan locally with 8.24.3 and 8.30.1 found the same six
`generic-api-key` findings, all introduced by commit
`22848e22d1068c864a07a85fbd74de293f7cbd3c`:

| File | Line in the introducing commit |
| --- | ---: |
| app/test/live_olcrtc_test.dart | 32 |
| core/control/olcrtc_test.go | 13 |
| core/engine/olcrtc/live_test.go | 106 |
| core/engine/olcrtc/render_test.go | 19 |
| core/engine/registry/olcrtc_test.go | 50 |
| core/parser/olcrtc_test.go | 9 |

All six use the same fixed 64-character hexadecimal OLCRTC test key.
Its references in main are confined to tests. The transport tests use
`meet.example.org` or an explicitly configured local LiveKit SFU;
the import tests also verify that the session material stays out of IPC
responses. The reviewed findings are test fixtures, not deployment credentials.
No credential was revoked as part of this change.

The additional findings were reviewed in their introducing revisions:

| File | Commit | Line | Context |
| --- | --- | ---: | --- |
| core/parser/fuzz_extra_test.go | 94f5829 | 49 | Fixed seed for the OLCRTC parser fuzzer; parsing does not join a room |
| core/engine/olcwrap/render_test.go | 23a094b | 10 | Golden renderer input for meet.example.org |
| core/parser/olcrtc_test.go | 723b1fb | 10 | Documented URI parser examples; covered by the same scoped fixture exception |
| apple/SoraCore/Tests/SoraCoreTests/Config/LibboxConfigBuilderTests.swift | c8597cd | 104 | Header-protection input in a golden configuration test |
| apple/SoraCore/Tests/SoraCoreTests/Config/ProfileFixtures.swift | c8597cd | 9 | REALITY public key in canonical test profiles |
| apple/SoraCore/Tests/SoraCoreTests/Config/ProfileFixtures.swift | c8597cd | 11 | WireGuard peer public key in canonical test profiles |

Scanning all local refs with the original configuration reproduced every
finding in #309. It also found six copies of the reviewed main fixtures in
local development commits, which are already covered by the exact-value/path
exception. No original finding was left unmatched.

## Change and checks

The exception matches both the exact fixture value and one of the six exact
test paths. It applies only to `generic-api-key`; other values, paths and
rules remain checked. The other existing exceptions are unchanged.
The five remaining historical findings are ignored by exact immutable
commit/path/rule/line fingerprints in .gitleaksignore. They do not exempt
those files or values in new commits.

The scanner version is fixed at 8.30.1 and the Gitleaks Action is fixed to
its inspected commit. Every event additionally scans all fetched refs and
saves a redacted SARIF report, so a clean last commit or main-only scan
cannot hide findings in other fetched history.

`python3 packaging/security/test_gitleaks.py` runs the actual scanner against
the reviewed fixture and negative controls: a different key at the allowed
path, the same key in production code, and the same key in an unreviewed test.
It was run successfully with Gitleaks 8.24.3 and 8.30.1 on Windows.

With the updated configuration, Gitleaks 8.30.1 returned exit code 0 for the
main history and current working tree. Reports were generated with full
redaction. Application code was not changed; application/runtime tests were
not run for this scanner configuration change.

The original #309 SARIF comparison is complete. A successful GitHub Actions
run of this branch remains required before closing the CI acceptance criterion.
