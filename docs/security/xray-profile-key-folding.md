# Xray profile field aliases

The profile scrubber compared provider-owned and prohibited file keys exactly.
Xray's JSON struct decoding accepts case-insensitive field matches. Renderer and
probe regression tests confirmed that aliases such as `CertificateFile`,
`MASTERKEYLOG` and `Reverſe` survived the old scrubber. The profile credential
extractor likewise missed aliases, leaving those values out of exact-value
redaction.

The pinned [Xray v26.3.27 TLS configuration source](https://github.com/XTLS/Xray-core/blob/v26.3.27/infra/conf/transport_internet.go)
declares certificate/key file tags and reads those fields during certificate
construction. Its TLS and REALITY configs also accept a master-key log path.
The [top-level configuration](https://github.com/XTLS/Xray-core/blob/v26.3.27/infra/conf/xray.go)
declares the reverse, listener and controller fields.
[Go JSON decoding](https://pkg.go.dev/encoding/json#Unmarshal) accepts folded
field matches. These sources establish the mismatch; tests here inspect
rendered JSON rather than opening protected files or executing a hostile engine.

The existing field sets now use standard `strings.EqualFold` comparisons.
All matching top-level provider-owned aliases are removed before adding session
settings. Prohibited file aliases are removed recursively for both the session
renderer and latency probe. Credential aliases enter the existing value-based
redactor. No configuration field is added or renamed, and provider outbounds,
balancers and routing retain their existing rendering contract.

Simple lowercasing is insufficient: Unicode long s and Kelvin sign belong to
case-folding classes used by Go's field matching. Tests cover these alongside
upper/lower/mixed ASCII spelling, canonical file keys and nested arrays/maps.
The new tests failed on the old implementation; existing profile rendering and
redactor tests remain required. No new dependency, JSON parser or runtime engine
installation is introduced.

This closes a field-alias bypass of existing policies. It does not establish
that every Xray setting capable of file/network access is in those policies,
prove a protected-file exploit on a live service, or complete the S3 audit.
Other profile resource, tag/reference and schema boundaries require separate
review. No owner service, TUN, route, protected file or firewall was changed.
