package probe

import (
	"context"
	"sync"
	"time"
)

// Handshake budget: the client-side half of the siberian parallelism
// limit.
//
// The freeze triggers on more than three parallel TLS handshakes sharing
// one SNI. Multiplexing (one TLS connection carrying many streams) is the
// structural fix for tunneled traffic, but the core also opens TLS
// connections itself — probes, dest checks, DoH bootstrap — and a burst of
// those can trip the same counter. HandshakeLimiter caps concurrent
// handshakes per SNI at three, which is the highest count the field
// reports leave unflagged.
//
// This limiter cannot see inside the engines: Xray/sing-box open their own
// connections. For engine traffic the defense is mux-by-default (see
// engine/mux.go), not this semaphore. The limiter is for core-initiated
// dials only, and its doc comment says so wherever it is used.
//
// The limiter lives in this package for the same reason the
// FreezeDetector does: it is the single source of truth the policy layer
// (core/censor, which re-exports it as censor.HandshakeLimiter) and the
// dial paths share, and core/censor imports core/probe, never the other
// way round. Wired consumers: the REALITY dest checker in this package
// (CheckDest acquires one slot per handshake) and the active censorship
// prober (censor.Prober acquires around its TLS handshake). The endpoint
// Prober in probe.go acquires through the same limiter once that file's
// in-flight rework lands — see the CENSOR-SURV report for the seam spec.
// Deliberately exempt: FreezeProber's parallel burst, whose whole point
// is to exceed the threshold and measure the freeze, and DialQUIC's
// grease Initials, which perform no handshake at all.
//
// The zero value is ready to use.
type HandshakeLimiter struct {
	mu   sync.Mutex
	sems map[string]chan struct{}
	// max is the per-SNI parallelism cap; zero means defaultHandshakeLimit.
	max int
	// timeout bounds how long Acquire waits for a slot; zero means
	// defaultHandshakeAcquireTimeout. A stuck holder must not wedge the
	// caller forever.
	timeout time.Duration
}

const (
	// defaultHandshakeLimit is the censor's trigger threshold: more than
	// three parallel handshakes with one SNI.
	defaultHandshakeLimit = 3
	// defaultHandshakeAcquireTimeout bounds slot acquisition. Handshakes
	// are short; waiting longer means the budget is saturated by stuck
	// dials, and the caller should fail fast instead of queueing behind
	// them.
	defaultHandshakeAcquireTimeout = 10 * time.Second
)

// NewHandshakeLimiter returns a limiter with explicit tuning. Non-positive
// values select the defaults.
func NewHandshakeLimiter(maxParallel int, acquireTimeout time.Duration) *HandshakeLimiter {
	return &HandshakeLimiter{sems: map[string]chan struct{}{}, max: maxParallel, timeout: acquireTimeout}
}

// DefaultHandshakeLimiter is THE process-wide handshake budget: the
// single instance every production dial path acquires from. The
// censor counts handshakes per SNI across the whole client, not per
// caller, so two independent default instances would silently double
// the cap (CheckDest's limiter plus censor.Prober's budget allowed
// up to 6 parallel handshakes on one SNI against a limit of 3 —
// CENSOR-SURV review, Medium 2). probe's dest checker uses this
// instance (destHandshakeLimiter defaults to it) and core/censor
// re-exports it as censor.DefaultHandshakeBudget; both names denote
// this one object. Tests may still build their own limiters with
// NewHandshakeLimiter — that is a test seam, not a second budget.
var DefaultHandshakeLimiter = NewHandshakeLimiter(0, 0)

func (l *HandshakeLimiter) limit() int {
	if l.max > 0 {
		return l.max
	}
	return defaultHandshakeLimit
}

func (l *HandshakeLimiter) acquireTimeout() time.Duration {
	if l.timeout > 0 {
		return l.timeout
	}
	return defaultHandshakeAcquireTimeout
}

func (l *HandshakeLimiter) sem(key string) chan struct{} {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.sems == nil {
		l.sems = map[string]chan struct{}{}
	}
	s, ok := l.sems[key]
	if !ok {
		s = make(chan struct{}, l.limit())
		l.sems[key] = s
	}
	return s
}

// Acquire takes one handshake slot for sni, or returns an error when the
// context expires or the acquire timeout elapses. The returned release
// function must be called when the handshake finishes, even on failure.
// Slots are per normalized SNI; different SNIs never contend.
func (l *HandshakeLimiter) Acquire(ctx context.Context, sni string) (release func(), err error) {
	key := normalizeFreezeSNI(sni)
	sem := l.sem(key)
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	// Fast path: a free slot is taken without arming the acquire
	// timer. time.NewTimer costs 248 B / 3 allocs on this path
	// (measured, [opt40]) while the uncontended acquire — the norm,
	// since the limiter only bites under a >3-way burst on one SNI —
	// needs no deadline at all: 264 B / 4 allocs -> 16 B / 1 alloc.
	// The contended path below is unchanged, timer and all. The
	// ctx.Err pre-check keeps a cancelled caller from taking a slot
	// the old three-way select would only randomly have refused.
	select {
	case sem <- struct{}{}:
		return func() { <-sem }, nil
	default:
	}
	timer := time.NewTimer(l.acquireTimeout())
	defer timer.Stop()
	select {
	case sem <- struct{}{}:
		return func() { <-sem }, nil
	case <-timer.C:
		return nil, errHandshakeBudgetTimeout{key}
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

// InFlight reports the current slot usage for sni, for diagnostics.
func (l *HandshakeLimiter) InFlight(sni string) int {
	l.mu.Lock()
	sem, ok := l.sems[normalizeFreezeSNI(sni)]
	l.mu.Unlock()
	if !ok {
		return 0
	}
	return len(sem)
}

type errHandshakeBudgetTimeout struct{ sni string }

func (e errHandshakeBudgetTimeout) Error() string {
	// The SNI is masked, never raw: this error text lands in
	// censorship-event details and diagnostics, which follow the
	// masked-name dictionary (MaskedName) — the raw name here put
	// the very identifier the dictionary exists to hide into
	// censor.Event.Detail (CENSOR-SURV review, §6).
	return "handshake budget: no slot for " + MaskedName(e.sni) + " within the acquire timeout"
}
