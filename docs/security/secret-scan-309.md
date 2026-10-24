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
Downloading the original report and logs still requires GitHub authentication;
it has not been compared with the local reports.

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

## Change and checks

The exception matches both the exact fixture value and one of the six exact
test paths. It applies only to `generic-api-key`; other values, paths and
rules remain checked. The other existing exceptions are unchanged.

The scanner version is fixed at 8.30.1 and the Gitleaks Action is fixed to
its inspected commit. Every event additionally scans the complete current
branch history and saves a redacted SARIF report, so a clean last commit
cannot hide findings in its ancestors.

`python3 packaging/security/test_gitleaks.py` runs the actual scanner against
the reviewed fixture and negative controls: a different key at the allowed
path, the same key in production code, and the same key in an unreviewed test.
It was run successfully with Gitleaks 8.24.3 and 8.30.1 on Windows.

With the updated configuration, Gitleaks 8.30.1 returned exit code 0 for the
main history and current working tree. Reports were generated with full
redaction. Application code was not changed; application/runtime tests were
not run for this scanner configuration change.

The original #309 SARIF comparison and a successful GitHub Actions run of
this branch remain outstanding. This local result does not close those
acceptance criteria.
