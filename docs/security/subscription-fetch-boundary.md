# Subscription retrieval boundary

The privileged core fetches bearer-bearing HTTPS subscription references. A public
provider must not inherit the ability to fetch local services from another
subscription. This review covers retrieval, not the subscription parsers or the
complete S3 audit.

## Reproduced failures

Two real transport tests failed before the change:

- With an HTTP CONNECT proxy, the dial guard inspected the public proxy IP rather
  than the HTTPS destination. A public provider's redirect to a private literal
  returned the fixture's internal response.
- A local-origin subscription opened a connection to a hostname resolving to the
  fixture's private address. A later public-origin fetch reused that connection,
  without invoking the dial guard, and returned the internal response again.

Fixtures only bind loopback. The tests remap simulated public addresses to their
fixtures after invoking the real address policy; they never connect to the
represented external or private services. Fixture certificates are trusted only
by injected test clients.

## Enforced policy

Each initial URL and redirect is validated before a request reaches the transport.
Canonical local IP literals (private, loopback or unicast link-local) explicitly
select the local-origin client. DNS results never grant this permission. Public
and local origins use separate standard `http.Transport` instances and connection
pools, including HTTP/2. Redirect handling stays in the fetcher for both clients.

Public-origin requests reject non-public literal destinations, `localhost` names,
and legacy numeric IPv4 spellings before proxy selection. Hostnames use the
already installed `golang.org/x/net/idna` lookup profile. Normalisation cannot
turn a hostname into a trusted literal. Invalid IDNs and empty DNS labels fail
without a request. Legitimate IDNs retain their HTTPS port, path and bearer query.

Direct TCP dials still check every resolved address. The pinned IANA classifier
rejects special-purpose ranges including CGNAT and documentation/benchmark
networks; those ranges do not acquire local-origin permission. IPv4-mapped IPv6
uses the IPv4 policy. The well-known NAT64 prefix is allowed only if its embedded
IPv4 destination passes the same public-address policy. Custom NAT64 prefixes
and other special IPv6 transition ranges are not implicitly trusted.

An explicitly configured local-IP subscription retains access to local services,
including redirects to local hostnames. This is an existing product permission,
not a sandbox for untrusted local origins. Special-purpose non-local addresses
remain rejected. HTTPS certificate verification, timeout/body/redirect bounds,
environment proxy selection and the absence of direct fallback are preserved.

## Residual proxy trust

For a hostname resolved by a configured proxy, Sora cannot inspect the proxy's
actual destination IP. Checking the TCP proxy endpoint and URL literal is not a
proof about remote DNS answers. Proxy-side destination enforcement remains a
trust requirement. This change deliberately does not resolve names locally and
leak proxy destinations, disable configured proxies, or silently retry directly.
Private network routes behind a public IP are likewise outside IP classification.

`Options.HTTPClient` is a test injection point; production constructs the standard
transport. An arbitrary injected `RoundTripper` is trusted test code and cannot
be cloned or constrained as a standard transport.

## Dependency choice, 25 October 2026

The standard `net/netip` predicates and existing `go4.org/netipx` do not provide
the special-purpose address registry. The existing IDNA dependency and standard
HTTP client/transport are reused. No custom resolver or proxy client is added.

| Candidate | Release | Stars / open issues including PRs | Module ZIP | License / minimum Go | Fit |
| --- | --- | --- | --- | --- | --- |
| [code.dny.dev/ssrf](https://github.com/daenney/ssrf/tree/v0.3.0) | v0.3.0, 2026-07-07 | 10 / 0 | 18,395 B | MIT / 1.21 | Exported address classifier; runtime uses standard library |
| [doyensec/safeurl](https://github.com/doyensec/safeurl/tree/v0.2.5) | v0.2.5, 2026-06-11 | 115 / 1 | 18,648 B | Apache-2.0 / 1.24 | Full client/resolver wrapper; no exported pure classifier |
| [cplieger/ssrf](https://github.com/cplieger/ssrf/tree/v4.4.1) | v4.4.1, 2026-10-23 | 1 / 3 | 115,129 B | Apache-2.0 / 1.27.3 | Higher minimum Go than the core directive; transport changes proxy/port/resolver policy |

`code.dny.dev/ssrf v0.3.0` supplies only the address classification needed here,
without replacing the existing HTTP transport or raising Go 1.26.9. Its small
user base is not evidence of independent security review. The source/API and
license were inspected, the version/checksums are pinned, and regression tests
cover Sora's additional origin, IDNA, mapped-address and NAT64 rules. The MIT
notice is included in the existing packaged third-party notices. Registry data
is a pinned snapshot and must be reviewed with dependency updates.

## Verification

Linux tests use actual CONNECT, TLS and HTTP/1.1 plus HTTP/2 connections: private
redirects fail before CONNECT, the public proxy destination succeeds, and a
local-origin pool cannot warm the public-origin pool. Tests include CGNAT, NAT64,
mapped IPv4, IDNA/numeric aliases, bearer-safe refusals and the existing local
provider, redirect, body and timeout behaviour. Pure policy tests also run as a
native Windows Go test executable; they do not install a service or change host
network settings. Hosted CI remains a separate required check.
