package session

import (
	"math/rand/v2"
	"time"
)

// RehandshakePolicy bounds how long one transport handshake may live.
//
// T017 (tspu-analysis/39): session age is now − SYN. Keepalives, TLS
// KeyUpdates and WireGuard rekeys do NOT reset it — only a fresh handshake
// does, so duration is a cheap correlatable feature for the censor. A fixed
// re-handshake interval is itself a fingerprint, hence the jitter.
//
// The zero value disables planned re-handshakes.
type RehandshakePolicy struct {
	// MaxAge is the nominal session lifetime before a planned
	// re-handshake, e.g. 45m. Zero disables the policy.
	MaxAge time.Duration
	// Jitter spreads the actual deadline uniformly over
	// [MaxAge−Jitter, MaxAge+Jitter]. Values above MaxAge are clamped to
	// MaxAge so the deadline never goes negative.
	Jitter time.Duration
}

// Deadline returns the planned re-handshake time for a session whose
// transport handshake completed at establishedAt. The jitter draw comes
// from r, which must be session-local: sharing one global source across
// sessions reintroduces correlatable timing. A nil r means zero jitter.
func (p RehandshakePolicy) Deadline(establishedAt time.Time, r *rand.Rand) time.Time {
	if p.MaxAge <= 0 || establishedAt.IsZero() {
		return time.Time{}
	}
	jitter := p.Jitter
	if jitter < 0 {
		jitter = 0
	}
	if jitter > p.MaxAge {
		jitter = p.MaxAge
	}
	offset := time.Duration(0)
	if r != nil && jitter > 0 {
		// Uniform in [−jitter, +jitter].
		offset = time.Duration(r.Int64N(int64(2*jitter)+1)) - jitter
	}
	return establishedAt.Add(p.MaxAge + offset)
}

// Overdue reports whether now reached the planned re-handshake time. A
// zero deadline (disabled policy) is never overdue.
func (p RehandshakePolicy) Overdue(now, deadline time.Time) bool {
	return !deadline.IsZero() && !now.Before(deadline)
}

// KeepaliveInterval jitters base by ±25% with a session-local source.
// A metronomic keepalive (the classic 25 s) is itself a fingerprint
// (tspu-analysis/39); the wire must not tick on a grid. Non-positive base
// disables keepalives and returns 0.
func KeepaliveInterval(base time.Duration, r *rand.Rand) time.Duration {
	if base <= 0 {
		return 0
	}
	if r == nil {
		return base
	}
	// Uniform in [0.75·base, 1.25·base].
	quarter := int64(base) / 4
	return base - time.Duration(quarter) + time.Duration(r.Int64N(2*quarter+1))
}
