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
//     current tpws executor (core/engine/bypass) supports only
//     split/disorder/oob/tlsrec/HTTP reshaping. Params that need nfqws
//     are marked so the caller never asks tpws to run them.
package desync
