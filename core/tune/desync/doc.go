// Package desync is the Geneva-style "Strategy Tuner" prototype for sora.
//
// Where package tune tries a fixed priority list of opaque strategies,
// desync searches a bounded space of desync parameters (the genome) and
// scores each candidate with a Geneva-like fitness function:
//
//	fitness = (forbidden content received) x (TCP not broken) x (brevity)
//
// The search space covers: desync method, split position, fooling, fake
// variant for TLS/QUIC, TTL/autottl and repeats — the same axes blockcheck
// walks manually and zapret's nfqws exposes. The curated seed population
// (see seed.go) replaces pure random search, which is slow and noisy
// against a live censor.
//
// The package never touches the network itself: probing a candidate is the
// caller's job (see ProbeFunc). All live probing is expected to run only
// from an explicit user action ("Pick a strategy"), rate-limited, and only
// against sora's own canary endpoints — active probing fingerprints
// itself. Passive fitness signals from real traffic are the preferred
// input; see retune.go.
//
// Honest limits, stated once here and repeated where they matter:
//
//   - Nothing here defeats IP-based blocking. If the censor blocks the
//     destination IP, no desync parameter will help and the fitness of
//     every candidate is 0.
//   - A parameter that wins today may die in 5-15 minutes: TSPU
//     reconfigures at night and relearns strategies. The tuner binds
//     winners to the F5 network profile and rotates on silent death
//     (see rotate.go) instead of pretending one strategy lasts.
//   - Fake-packet tricks, TTL/autottl and fooling need nfqws; sora's
//     tpws executor (core/engine/bypass) supports only
//     split/disorder/oob/tlsrec/HTTP reshaping. Params that need nfqws
//     are marked so the caller never asks tpws to run them — and the
//     executor's runtime capability gate (bypass.Capabilities) refuses
//     them honestly on hosts whose kernel cannot queue, instead of
//     the caller having to guess from the OS.
//
// Production status (2026-10-20): WIRED. The user-triggered entry
// point is the control plane's TuneDesync RPC (sora.censor.v1, since
// 1.13; core/control/desync_tune.go), which runs Service (runner.go):
// rate-limited per network, probing only the package's canary
// endpoints, winners bound to the F5 network profile and rotated on
// silent death. Strategies are data: the registry (registry.go) is
// the single source of curated profiles per censor-cascade class,
// versioned like this pool. What is still NOT claimed: a live packet
// run needs nfnetlink_queue, which sandboxes and some kernels lack —
// the capability gate says so at Apply instead of pretending.
package desync
