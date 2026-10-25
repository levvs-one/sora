# External geodata references in Xray profiles

The previous renderer retained external geodata paths in provider routing and
DNS. Six negative rendering cases accepted `../fixture-outside.dat` through
domain/IP rules, DNS hosts, server domains and expected IPs. Those references
are interpreted by the engine while building its configuration, before traffic
starts.

The pinned [Xray routing parser](https://github.com/XTLS/Xray-core/blob/v26.3.27/infra/conf/router.go)
passes external filenames to its asset reader. The
[DNS configuration](https://github.com/XTLS/Xray-core/blob/v26.3.27/infra/conf/dns.go)
uses the same machinery for hosts, domain lists and IP filters. On Linux,
[asset location lookup](https://github.com/XTLS/Xray-core/blob/v26.3.27/common/platform/others.go)
joins the asset directory with that filename; the
[file reader](https://github.com/XTLS/Xray-core/blob/v26.3.27/common/platform/filesystem/file.go)
opens the result. Removing certificate/key/log file fields alone did not cover
these references.

## Policy and compatibility

The final serialized configuration is checked before it is returned for engine
execution. External references in the recognised routing and DNS fields may name
only exact `geoip.dat` and `geosite.dat`, the two datasets shipped by the current
engine bundle. Other filenames, traversal, absolute/UNC paths, devices, alternate
streams and malformed external references fail the whole render. No routing rule
is silently removed, and no path is rewritten.

Profiles naming a custom `.dat` file are now refused. Sora has no supported
trusted provisioning path for such assets; a future custom-asset feature needs
its own authenticated installation and ownership contract. The guard does not
search the filesystem to decide whether an arbitrary path is safe.

The projection uses Go JSON field matching and the pinned engine's wire forms:
routing lists can be arrays or comma-separated strings, whereas DNS server
domains must be arrays. Commas inside array regexes stay inside that regex.
`sourceIP`/`source` and `expectedIPs`/`expectIPs` retain their distinct fallback
rules. Raw rule/host/server fragments avoid retaining stale decoded fields when
aliases replace earlier values; nullable roots and merged root objects are
covered by tests. Passwords, labels and unrelated strings are not scanned for
`ext:` text.

Latency probes construct their own routing/DNS from the profile's outbounds.
Tests confirm that rejected provider routing/DNS references never enter that
probe configuration. Existing recursive file-key removal continues to apply to
the outbounds used in both modes.

## Reproduction and verification

`TestIsolatedXrayExternalAssetTraversalFixture` runs real Xray in bubblewrap with
no host home, host network or host filesystem mounts. Only the binary and planted
files are mounted read-only; private `/dev`, `/proc` and `/tmp` are created.
There are no listeners, TUN devices or live traffic. A protobuf fixture uses the
upstream GeoSite schema through the already installed protobuf wire library.

The in-root file succeeds, `../outside.dat` also succeeds inside this isolated
fixture, and a missing-file control must reach the engine's asset reader and
fail with the planted filename. A namespace startup error cannot satisfy that
negative control. This proves a fixture read outside the asset subdirectory,
not access to any real protected file. The renderer regression then proves
Sora refuses the path before passing configuration to the engine.

The local native run used official Xray v26.3.27 from the archive pinned in
`packaging/engines/engines.lock`: archive SHA-256
`23cd9af937744d97776ee35ecad4972cf4b2109d1e0fe6be9930467608f7c8ae`;
extracted binary SHA-256
`8255dd939c34cf966cc91517b6324dd3c8d0bcf49ffac8beca049a38c46845ed`.
The Linux package CI uses the existing verified engine bundle and runs the same
fixture in its own namespace. The Windows tests exercise the policy and rendered
configuration, without native engine execution or host network changes.

To repeat the native fixture on an isolated Linux test host with bubblewrap:

```sh
cd core
SORA_ENGINES_DIR=/absolute/path/to/verified/engines \
  go test -race -count=1 ./engine/xray \
  -run '^TestIsolatedXrayExternalAssetTraversalFixture$' -timeout 45s -v
```

## Dependency decision, 25 October 2026

The existing JSON decoder, strings package and installed protobuf library are
reused. Two maintained generic validators were checked before this policy code:

| Candidate | GitHub release publication | Stars / open including PRs | Module ZIP | License / minimum Go |
| --- | --- | --- | --- | --- |
| [santhosh-tekuri/jsonschema](https://github.com/santhosh-tekuri/jsonschema/releases/tag/v6.0.3) v6.0.3 | 2026-08-06 | 1,289 / 47 | 94,453 B | Apache-2.0 / 1.21 |
| [go-playground/validator](https://github.com/go-playground/validator/releases/tag/v10.30.5) v10.30.5 | 2026-09-20 | 20,208 / 348 | 386,651 B | MIT / 1.26.0 |

Both fit the core's Go 1.26.9 directive. JSON Schema needs a schema and custom
Sora asset constraints; struct-tag validation also needs the same wire projection
and custom checks, with an additional validation/translation dependency stack.
Neither supplies this pinned Xray/Sora asset policy. The narrow projection and
filename policy use the existing decoder without adding either dependency or
inventing a complete Xray schema.

This does not finish the profile/S3 audit. Other file-capable options, environment
expansion, resource limits and the integrity/permissions/symlinks of installed
assets require separate checks. A fixed filename is not proof against a writer
who can replace a trusted installed asset or its directory.
