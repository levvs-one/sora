// Package censor answers one question for the user: "is someone on the path
// interfering with my connection, and what do I do about it?"
//
// A bare "connection failed" tells the user nothing: a dead server, a dropped
// route, and an SNI-triggered reset all look alike. This package classifies a
// failed connection attempt from its wire signature — how far the attempt got
// (DNS → TCP → TLS → application), how long each step took, and who closed the
// connection (a remote RST, a TLS alert, or our own timeout) — and returns a
// Verdict naming the most likely interference, with a calibrated confidence
// and a pointer to the obfuscation preset most likely to route around it.
//
// The honesty contract is the whole point of this package:
//
//   - A verdict is only as confident as its evidence. One ambiguous signal
//     never produces a confident claim; sparse input yields KindUnknown with
//     low confidence and an explanation that says so plainly.
//   - Some failures are evidence *against* censorship. A server that answers
//     a SYN with RST is alive and refusing — a censor drops packets, it does
//     not run a connection-refusing stack. Those classify as
//     KindNoInterference, never as an attack.
//   - SuggestedProfile is the real sora.obfs.v1.ObfsPreset contract, so the
//     client can apply it directly. Kinds with no honest prescription
//     (Unknown, NoInterference, DNS poisoning, unreachable IP) carry none:
//     suggesting a preset where none helps would be decoration.
//
// The Detector works on an Attempt, which can be built three ways: from
// precisely instrumented events (Prober), from coarse session journal history
// (AttemptFromLog), or from client-supplied wire observations over RPC. Active
// probing is deliberately narrow — one TCP connect plus one TLS handshake with
// tight timeouts — because the goal is a diagnosis, not a measurement campaign.
package censor
