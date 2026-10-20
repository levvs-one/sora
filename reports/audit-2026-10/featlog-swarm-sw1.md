# featlog — swarm SW1: obfuscation suite (proto + control plane)

Coordination log for the obfuscation-suite swarm. Writers: append, don't
rewrite.

## SW1b (proto + control plane) — 2026-10-19

Done, commit `[swarm] obfuscation suite: proto sora.obfs.v1 + control-plane handlers (SW1)`.

### Contract (NEW proto, existing protos untouched)
- `proto/sora/obfs/v1/obfs.proto`, package `sora.obfs.v1`, service
  `ObfsControl` with `ApplyObfsProfile` + `GetObfsCapabilities`
  ("Since 1.11" — API minor bumped 1.10 → 1.11 in
  `core/cmd/sora-core/main.go`; `MinSupportedMinor` stays 1, additive).
- Messages: `ObfuscationProfile` (preset enum OFF/LIGHT/BALANCED/
  AGGRESSIVE, `UtlsProfile` enum, `frag_sizes`, `frag_delay_ms`,
  `jitter_ms`, `fake_sni`), `EngineObfsCapabilities`.
- Go regenerated via buf (`core/gen/sora/obfs/v1/`); Dart stubs
  deliberately NOT generated — Dart agent's job.

### Control plane (`core/control/obfs.go`)
- `ApplyObfsProfile`: validates (13 negative cases tested), expands
  preset (explicit fields win), stores as the active profile, persists
  atomically to `DataDir/obfs_profile.json` (0600), returns normalized
  profile + `compatible_engines` + `warnings`. Control-auth only
  (fail-closed default).
- `GetObfsCapabilities`: per-engine flags read from the renderers.
  Added to `readOnlyMethods` (no personal data).
- `MergeObfsProfile(plan, profile)` — **the seam**: the single mapping
  from profile to `engine.Plan` (fragment → `Options.Fragment`,
  uTLS → per-outbound `TLS.Fingerprint`, fake_sni →
  `TLS.ServerName` except REALITY outbounds). Exported so `core/obfs`
  (SW1a) and any other consumer reuse it instead of duplicating.
- `Connect` merges the stored profile into the plan after
  `planFromProto`; capability `obfs-profiles` added to `Capabilities()`.
- Registered in `main.go` next to CoreControl.

### Capability matrix (verified against renderers, not docs)
| engine | uTLS | fragmentation | frag params | jitter | fake_sni |
|---|---|---|---|---|---|
| sing-box | ✓ 10 parrots | ✓ on/off only | ✗ | ✗ | ✓ via server_name |
| xray | ✓ 10 + versioned | ✓ packets/length/interval | ✓ | ✓ (interval range) | ✓ via serverName |
| mihomo | ✓ 9 (no randomized) | ✗ | ✗ | ✗ | ✓ via SNI |

### Notes for other agents
- **SW1a (`core/obfs`)**: reviewed 2026-10-19 — your package masks
  handshakes the core initiates itself (probes, DoH, fetches) via
  conn wrappers; my layer (SW1b) is the control plane for proxied
  user sessions (proto + RPCs + `engine.Plan` merge). No overlap, no
  shared code needed. Follow-up opportunity (NOT implemented, per the
  slop directive): a converter `obfsv1.ObfuscationProfile` →
  `obfs.Profile` so the one active control-plane profile also masks
  core-initiated traffic. That's a product decision for the parent;
  the mapping is field-by-field trivial when wanted.
- **Censor agent**: saw `censor/types.go` referencing
  `obfsv1.ObfsPreset` in `ProfileRef` — good synergy: your suggested
  preset → client calls `ObfsControl.ApplyObfsProfile`. I added the
  missing `censorv1.UnimplementedCensorControlServer` embedding to
  `Server` (your handler was in flight, package didn't compile).
- **Leak agent**: `main.go` registers `leakv1` but `RunLeakTests`
  isn't implemented — `cmd/sora-core` doesn't link yet. Also
  `core/ext/host.go:204` (`undefined: g`) is broken in flight.
- **Version**: if another agent also bumped to 1.11, merge by taking
  the max minor and renumbering "Since" comments.
- Env note: `go` toolchain installed at `~/workspace/tools/go`
  (go1.25.4); `TestTunAndFakeIPAvoidLANAndEachOther` fails in this
  sandbox only (host0 has 198.19.0.2/30 overlapping the test pool).

### Slop filter (owner directive) — cut or narrowed
- Cut: `dry_run` flag on Apply (speculative); full Xray versioned-parrot
  list in capabilities (noise → one bool); hand-rolled
  `slicesContains`/`joinStrings` (stdlib exists).
- Narrowed: `fake_sni` kept (task-required field) but never applied to
  REALITY outbounds and always returned with a risk warning — blind
  application breaks handshakes.
- Kept deliberately: `DataDir` persistence — a security setting that
  silently vanishes on restart is a defect, not minimalism.
