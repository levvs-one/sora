# Migration: nfqws as the default bypass backend

Status: implemented on Linux (wave A, 2026-10-20). The executor lives
in this package (nfqws.go, nfqws_linux.go) inside the same Engine that
runs tpws; items 1, 2, 4, 5 (executor subset), 6 and 7 are done as
specified below. Remaining: item 3 (Windows winws — discovery and the
interface exist, the executor fails closed naming the pending
WinDivert step), the hostlist args of item 5, item 8 (proto contract —
needs buf regeneration), and the rollout matrix of items 9–10 beyond
the automated tests (the sandbox kernel has no nfnetlink_queue, so
the packet-path integration test self-skips there and must run on a
host that has the module).

## Why

The reference bypass strategy — the set this migration makes the
default — is the modern nfqws/winws desync set
(`fake,split2,disorder2,multisplit` + autottl, TCP 80/443, UDP 443, QUIC
fake — `bypass.DefaultStrategy`). tpws cannot run it: tpws is a
transparent SOCKS proxy, TCP-only, with no packet injection, so no fake
packets, no autottl, no UDP/QUIC desync. With the executor landed,
`applyZapretWithVPN` applies this set when the client sends no
strategy, and any plan carrying a desync strategy runs it.

Non-goals: removing tpws (it stays as the fallback for TCP-only
strategies and for hosts where interception is unavailable), changing the
wire protocol, touching engine drivers.

## Current state (already done)

- `engine.BypassStrategy` carries nfqws fields: `Desync`, `FakeTLS`,
  `FakeQUIC`, `Fooling`, `TTL`, `AutoTTL`, `Repeats`, `FilterTCP`,
  `FilterUDP`, `FilterL7`.
- `bypass.BackendOf` selects tpws/nfqws per strategy; `bypass.NFQWSArgs`
  renders the nfqws/winws command line against the vendored zapret 72.1
  flag set; `bypass.DefaultStrategy` is the modern set, applied by
  `applyZapretWithVPN` when the client sends no strategy.
- `engine` validation covers the new fields (mode/fooling/l7
  whitelists, TTL range, TTL↔autottl exclusivity, QUIC fake needs
  filter-udp, fake names confined to the zapret home).
- The executor runs nfqws strategies (Linux): supervised processes,
  NFQUEUE allocation, the sora_nfqws table lifecycle with a startup
  sweep, per-backend fail-closed errors.
- `tune/desync` models nfqws-only params (`RequiresNFQWS`) and now
  converts genomes for the executor (`Params.BypassStrategy`,
  `Params.NFQWSArgs`).
- Packaging already builds and ships nfqws next to tpws
  (`packaging/zapret/build.sh` → `engines/nfqws`, `engines/zapret/fake/`).

## Work items

### 1. Binary discovery (registry) — done

`core/engine/registry`: discover `nfqws` (Linux) / `winws.exe`
(Windows) in the engines directory next to tpws, with the same
executable-bit and digest checks. `BypassAvailable` gains an
nfqws-capable variant; availability reporting names which backend is
usable. `bypass.Wrap` takes both paths.

### 2. Packet interception — Linux — done, with one deviation

nfqws reads packets from an NFQUEUE; without queue rules it sees
nothing. sora-core already runs with ambient `CAP_NET_ADMIN`
(`service/linux/sora-core.service`), and `core/guard` already manages
nftables, so the service can install the rules itself:

- On nfqws start, add nftables rules sending the strategy's filtered
  traffic to the queue: TCP dports from `FilterTCP`, UDP dports from
  `FilterUDP`, via `nft add rule ... queue num <qnum>`.
  Alternative: mark packets with `--dpi-desync-fwmark` and queue on the
  mark, so one rule set serves all strategies.
- Allocate `<qnum>` per running nfqws instance (kernel queue numbers
  0..65535; keep a small allocator in the bypass package).
- Rule lifecycle is tied to the supervised process: add before
  `waitListening`, remove on stop/crash. A stale rule after a crash
  blackholes traffic into a dead queue — the supervisor must remove
  rules even when nfqws dies unexpectedly (defer + a startup sweep
  that drops rules referencing queue numbers with no live instance).
- Launch: `nfqws --qnum=<n> <NFQWSArgs...>`. No `--socks`: nfqws is not
  a proxy.

Deviation in the shipped implementation: per-rule deletion is not
how the lifecycle is realized — nft deletes rules by handle, not by
description, so the executor replaces the whole sora_nfqws table
atomically on every reconciliation (the same pattern the kill switch
uses for its table), re-syncs it to the survivors when a start fails,
sweeps it once at startup, and removes it when the last instance
stops. The guarantee this item exists for — no rule ever steers into
a dead queue — is the same, and it is pinned by tests.

### 3. Packet interception — Windows — NOT done (interface only)

winws uses WinDivert: no queue rules, but the WinDivert driver must be
installed (admin at install time; `install.ps1` gains the driver step,
using the vendored `nfq/windows/windivert` blobs). The service then runs
`winws <NFQWSArgs...>` unprivileged-ish; verify the driver load fails
closed with a actionable message when absent.

State: discovery finds and digest-verifies winws.exe, and the
executor's platform seam is in place; starting winws is not wired —
Apply on Windows fails closed naming this item. Do not read the
interface as support.

### 4. Engine model change — done

The current `Engine` assumes one loopback SOCKS5 proxy per strategy and
rewrites bypass outbounds to `127.0.0.1:<port>`. That model is tpws-only.
nfqws works at the packet layer: there is no per-outbound proxy.

- One nfqws instance per distinct filter set (dedupe by `NFQWSArgs`),
  not per outbound; `Rewrite` leaves nfqws-bound outbounds as
  `direct`-routed (desync happens below the engine).
- `zapret_with_vpn` (F11) currently retargets "direct" rules at a
  synthetic SOCKS outbound. With nfqws the synthetic outbound goes away:
  direct traffic is desynced by the packet filter while the tunnel
  carries the rest. `applyZapretWithVPN` must stop appending the
  synthetic outbound when the strategy selects nfqws.
- Keep per-strategy tpws proxies for tpws-bound outbounds in the same
  plan; a plan may mix both backends.

### 5. Arg rendering gaps — partial

`NFQWSArgs` covers the strategy model. The executor adds `--qnum`.
Still missing: `--hostlist`/`--hostlist-exclude` (targeted desync;
hostlist files live under the zapret home) and `--dpi-desync-fwmark`
(not needed while one table serves all instances); `--pidfile` is
unnecessary — supervise owns the process. `--dpi-desync-split-pos`
already renders from `SplitPos`.

### 6. Failure policy — done

Fail closed, never silently degrade: if nfqws is requested but the
binary, the queue rules, or (Windows) the driver are missing, `Apply`
returns an error naming the missing piece. Optional tpws fallback must
be an explicit user choice, not automatic — automatic fallback would
reintroduce the exact silent lie this spec removes (a QUIC strategy
"running" on tpws desyncs nothing).

### 7. Tuner integration — done (executor-facing half)

`tune/desync.Params.RequiresNFQWS` already gates candidates. Once the
executor exists, the tuning caller may feed nfqws genomes to it;
`Params.Args` (tpws subset) stays for the tpws path, and a new
`Params.NFQWSArgs` renders the full genome. `Candidates` ordering is
unchanged.

### 8. Proto contract (client → core) — NOT done

`BypassStrategy` in `proto/sora/core/v1/core_control.proto` still
exposes only the 7 legacy fields, and `applyZapretWithVPN` maps only
those. Add: `desync`, `fake_tls`, `fake_quic`, `fooling`, `ttl`,
`auto_ttl`, `repeats`, `filter_tcp`, `filter_udp`, `filter_l7` — plus the
currently unmapped tpws fields (`disorder_scope`, `oob_scope`,
`host_dot`, `host_tab`, `host_nospace`, `method_space`, `unix_eol`,
`split_any_protocol`, `tamper_start`, `tamper_cutoff`, `oob_data`,
`mss`). Regenerate Go (`buf`) and Dart protos, extend the mapping, keep
field numbers stable. The UI gains a strategy editor on top.

### 9. Testing — automated parts done

- Unit: arg rendering per backend (done), rule add/remove lifecycle
  with a fake nftables backend (done: fake interceptor + fake nft
  binary), executor lifecycle with fake and real binaries (done:
  start/stop/dedupe/fail-closed matrix; the real nfqws accepts the
  rendered args and its startup death fails the Apply closed).
- Integration (Linux VM, service user): the packet-path test exists
  (nfqws_integration_test.go, env-gated) and self-skips where the
  kernel lacks nfnetlink_queue or UDP is sandbox-blocked; the
  sweep/atomicity half runs against the real nft wherever root is
  available. Still owed on a capable host: QUIC handshake to a
  filtered host succeeds with fake+autottl; TCP 443 SNI split still
  works; non-matching traffic untouched (counters); kill -9 of nfqws
  removes queue rules (no blackhole); restart reuses the port/model.
- Windows VM: driver-present and driver-absent paths.
- Soak: autottl path estimation under route changes; fake TTL expiry
  verified by packet capture (fake dies before the server).
- Negative: strategy needing nfqws on a tpws-only host errors before
  any process starts (done, unit).

### 10. Rollout — default flipped on Linux; matrix pending

Behind the existing bypass availability flag; default flips to the
nfqws set only after the Linux and Windows paths pass the matrix
above. tpws remains for legacy strategies.

## Risks

- Stale NFQUEUE rules blackhole traffic: mitigated by lifecycle tying
  and the startup sweep (item 2).
- WinDivert driver signing on Windows: verify the vendored driver
  loads on current Windows; else the Windows path stays tpws-only.
- Fake packets are more intrusive than splits: some networks throttle
  or flag them; the tuner must be able to fall back to tpws strategies
  per network (cached strategy IDs already support this).
