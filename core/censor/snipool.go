package censor

import (
	"sync"
)

// SNIPool is the "pool of consistent SNIs" T007 demands: the ordered set of
// REALITY dest names the session may rotate through when the freeze
// detector escalates past fingerprint rotation.
//
// "Consistent" is doing real work here: every member must have passed the
// dest checklist (a real site serving TLS 1.3 + H2 with a valid
// certificate, not behind Cloudflare — see core/probe CheckDest), and the
// SNI must be plausible for the hosting infrastructure (T006). The pool
// itself does not validate; it keeps the rotation order stable and tracks
// which members are burned, so the session never flaps between two dead
// SNIs and never retries a burned one until the pool is exhausted.
//
// The pool is safe for concurrent use.
type SNIPool struct {
	mu    sync.Mutex
	snis  []string        // rotation order, normalized
	bad   map[string]bool // burned members
	index int             // next candidate
}

// NewSNIPool builds a pool from candidate dest names. Empty names and
// duplicates are dropped; names are normalized (lowercase, no trailing
// dot). The order is significant: put the most plausible dest first.
func NewSNIPool(candidates []string) *SNIPool {
	p := &SNIPool{bad: map[string]bool{}}
	seen := map[string]bool{}
	for _, c := range candidates {
		n := normalizeSNI(c)
		if n == "" || seen[n] {
			continue
		}
		seen[n] = true
		p.snis = append(p.snis, n)
	}
	return p
}

// Len reports the pool size.
func (p *SNIPool) Len() int {
	p.mu.Lock()
	defer p.mu.Unlock()
	return len(p.snis)
}

// Current returns the SNI the session should use now: the first
// non-burned member in rotation order. Empty when every member is burned.
func (p *SNIPool) Current() string {
	p.mu.Lock()
	defer p.mu.Unlock()
	for _, s := range p.snis {
		if !p.bad[s] {
			return s
		}
	}
	return ""
}

// Rotate advances to the next non-burned member and returns it. It is what
// the session calls when the freeze detector sets RotateSNI. Empty when
// every member is burned — then the session must fail over to another
// server, not keep cycling.
func (p *SNIPool) Rotate() string {
	p.mu.Lock()
	defer p.mu.Unlock()
	if len(p.snis) == 0 {
		return ""
	}
	for i := 0; i < len(p.snis); i++ {
		p.index = (p.index + 1) % len(p.snis)
		if s := p.snis[p.index]; !p.bad[s] {
			return s
		}
	}
	return ""
}

// MarkBad burns sni: the freeze detector confirmed it frozen, or the dest
// checklist failed it. A burned member is skipped by Current and Rotate
// until ResetBad clears it (for example after the operator re-validates
// the dest).
func (p *SNIPool) MarkBad(sni string) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if n := normalizeSNI(sni); n != "" {
		p.bad[n] = true
	}
}

// ResetBad clears all burned marks, e.g. after a wave passes or the dests
// are re-validated.
func (p *SNIPool) ResetBad() {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.bad = map[string]bool{}
}

// IsBad reports whether sni is currently burned.
func (p *SNIPool) IsBad(sni string) bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.bad[normalizeSNI(sni)]
}
