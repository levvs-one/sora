package censor

import (
	"time"

	"github.com/levvs-one/sora-client/core/probe"
)

// Handshake budget: the client-side half of the siberian parallelism
// limit (more than three parallel TLS handshakes sharing one SNI trips
// the freeze — see core/probe/budget.go for the full account).
//
// The implementation lives in core/probe as the single source of truth —
// the same arrangement as the FreezeDetector — because the dial paths
// that must acquire from it (the REALITY dest checker, the endpoint
// prober) live there, and this package imports core/probe, never the
// other way round. The aliases below keep the censor-facing API the
// policy layer and its tests have always used; there is exactly one
// limiter implementation in the tree.
//
// Wired consumers: probe.CheckDest acquires one slot per dest
// handshake, and this package's active Prober acquires around its TLS
// handshake (Prober.Budget, defaulting to DefaultHandshakeBudget).
type HandshakeLimiter = probe.HandshakeLimiter

// NewHandshakeLimiter returns a limiter with explicit tuning.
// Non-positive values select the defaults (3 parallel handshakes per
// SNI, 10 s acquire timeout).
func NewHandshakeLimiter(maxParallel int, acquireTimeout time.Duration) *HandshakeLimiter {
	return probe.NewHandshakeLimiter(maxParallel, acquireTimeout)
}

// DefaultHandshakeBudget is the shared limiter the active censorship
// prober acquires from when Prober.Budget is nil: censorship probes
// from every flow share one per-SNI budget, which is the point — the
// censor counts handshakes per SNI, not per caller.
var DefaultHandshakeBudget = NewHandshakeLimiter(0, 0)
