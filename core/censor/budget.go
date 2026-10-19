package censor

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
	key := normalizeSNI(sni)
	sem := l.sem(key)
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
	sem, ok := l.sems[normalizeSNI(sni)]
	l.mu.Unlock()
	if !ok {
		return 0
	}
	return len(sem)
}

type errHandshakeBudgetTimeout struct{ sni string }

func (e errHandshakeBudgetTimeout) Error() string {
	return "handshake budget: no slot for " + e.sni + " within the acquire timeout"
}
