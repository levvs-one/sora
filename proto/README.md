# proto

The versioned `sora.core.v1` gRPC contract is in `sora/core/v1/core_control.proto`.

From the repository root, install Buf and the generators, then run:

```sh
cd proto
buf lint
buf generate
```

Go output is written to `core/gen`. Dart output is written to `app/lib/src/generated`.
The repository workflow and the pull request autofix workflow use the pinned generator versions.

Contract 1.6 adds authenticated `GetSubscriptionLink` for opening a subscription page.
Subscription states omit the bearer link; clients request it only for this action and never cache or log it.

Contract 1.7 adds an explicit TUN stack to SessionPlan. Clients negotiate 1.7
before sending it; older peers remain usable for plans without this field.

Contract 1.8 adds `CheckDnsLeaks`: which resolvers the session uses versus the
OS, and whether the kill switch covers DNS.

Contract 1.9 adds `BenchmarkServers`/`GetBenchmarks` (throughput benchmarks)
and the subscription override layer (`SaveSubscriptionOverride`/
`GetSubscriptionOverride`).

Contract 1.10 adds network profiles with auto-detect (`ListProfiles`,
`SaveProfile`, `DeleteProfile`, `GetNetworkFingerprint`), proxy-chain probing
(`ProbeChain`), `SessionPlan.chain`, `SessionPlan.zapret_with_vpn`, and the
`sora.ext.v1.ExtensionHost` service.

Contract 1.12 adds `SelectServer` (fast in-session server switch over a
select group, no engine restart) and `GroupSpec.selected` (the member a
select group starts on, honoured by every engine at Connect).

Contract 1.13 adds `GetDeviceIdentity`/`SetDeviceIdentity` (the provider
device identity settings surface, C1): the interface reads the HWID,
toggles whether subscription fetches carry it, resets it, and supplies
the companion platform facts (`ver_os`, `device_model`) the core stores
with the identity.

Contract 1.11 adds `sora.obfs.v1.ObfsControl` (uTLS, TLS fragmentation,
jitter), `sora.leak.v1.LeakService` (egress self-tests),
`sora.censor.v1.CensorControl` (censorship diagnosis), and
`sora.custom.v1.CustomServers` (user-added servers).

Every service file carries its own "Since 1.x" marker. Clients gate calls on
the negotiated minor; see `core/control/version.go` and the app's
`apiVersion` in `app/lib/src/core/link.dart`, which must agree with the
contract the core serves (`core/cmd/sora-core/main.go`).
