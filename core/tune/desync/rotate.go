package desync

import (
	"sync"
	"time"
)

// The zapret2 practice this mirrors: strategies die quietly and get
// re-blocked in 5-15 minutes, so deployments rotate them in a circle
// (circular:fails=3:maxtime=60). The Rotator is that idea as a small
// state machine over the tuner's ranked winners: it serves the current
// strategy, counts consecutive failures, and advances to the next
// candidate when the strategy looks dead — either by failing too many
// times in a row or by outliving its maximum age.
type Rotator struct {
	mu sync.Mutex
	// ranked are the working candidates, best first. Only scored > 0
	// entries are kept: rotating onto a known-dead strategy helps nobody.
	ranked []Scored
	cur    int
	fails  int
	// maxFails rotates after this many consecutive failures.
	maxFails int
	// maxAge rotates a strategy older than this even without failures:
	// the censor may have learned it silently ("quiet death").
	maxAge time.Duration
	// born is when the current strategy was adopted.
	born time.Time
	// rotations counts how many times the ring advanced, for the journal.
	rotations int
}

// NewRotator builds the ring over ranked candidates (best first). Entries
// with Score 0 are dropped. maxFails <= 0 means 3, maxAge <= 0 means
// 15 minutes — the TSPU re-block window from field practice.
func NewRotator(ranked []Scored, maxFails int, maxAge time.Duration) *Rotator {
	alive := make([]Scored, 0, len(ranked))
	for _, s := range ranked {
		if s.Working() {
			alive = append(alive, s)
		}
	}
	if maxFails <= 0 {
		maxFails = 3
	}
	if maxAge <= 0 {
		maxAge = 15 * time.Minute
	}
	return &Rotator{ranked: alive, maxFails: maxFails, maxAge: maxAge, born: time.Now()}
}

// Empty reports whether the ring holds no working strategy.
func (r *Rotator) Empty() bool {
	r.mu.Lock()
	defer r.mu.Unlock()
	return len(r.ranked) == 0
}

// Current returns the strategy to use right now. If the current strategy
// outlived maxAge it is rotated first: a strategy the censor learned
// silently looks exactly like a working one until it doesn't.
func (r *Rotator) Current() (Scored, bool) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if len(r.ranked) == 0 {
		return Scored{}, false
	}
	if time.Since(r.born) >= r.maxAge {
		r.advanceLocked()
	}
	return r.ranked[r.cur], true
}

// Success resets the consecutive-failure counter: the strategy is alive.
func (r *Rotator) Success() {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.fails = 0
}

// Fail records one failed connection attempt. When the consecutive
// failures reach maxFails the ring advances and Fail returns the new
// strategy (rotated=true). A lone failure never rotates — networks
// glitch; censors kill in streaks.
func (r *Rotator) Fail() (next Scored, rotated bool) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if len(r.ranked) == 0 {
		return Scored{}, false
	}
	r.fails++
	if r.fails < r.maxFails {
		return r.ranked[r.cur], false
	}
	r.advanceLocked()
	return r.ranked[r.cur], true
}

// Rotations reports how many times the ring advanced.
func (r *Rotator) Rotations() int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.rotations
}

func (r *Rotator) advanceLocked() {
	r.cur = (r.cur + 1) % len(r.ranked)
	r.fails = 0
	r.born = time.Now()
	r.rotations++
}
