// Package serversel picks the best server for a session: it scores
// candidates from probe history (latency, bandwidth), connection reliability
// and data freshness, filters them by engine capabilities and the active
// network profile, and watches the live session for degradation to advise a
// switch without flapping.
//
// The package is client-side only: it needs no new RPCs. The session feeds
// probe results and connection outcomes in, and asks for a pick or a
// degradation verdict out.
package serversel

import (
	"errors"
	"math"
)

var (
	// ErrNoCandidates reports PickBest called with an empty candidate list.
	ErrNoCandidates = errors.New("serversel: no candidate servers")
	// ErrNoEligible reports that every candidate was filtered out by the
	// constraints. The returned Pick lists the rejection reasons.
	ErrNoEligible = errors.New("serversel: no candidate passes the constraints")
)

// clamp01 pins v to [0, 1]. NaN maps to 0: an unknown input must never
// leak NaN into a score (it would also break the ranking comparator,
// since NaN != NaN).
func clamp01(v float64) float64 {
	if math.IsNaN(v) {
		return 0
	}
	if v < 0 {
		return 0
	}
	if v > 1 {
		return 1
	}
	return v
}

// clampFloat pins v to [lo, hi]. NaN maps to lo.
func clampFloat(v, lo, hi float64) float64 {
	if math.IsNaN(v) {
		return lo
	}
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

// clampInt pins v to [lo, hi].
func clampInt(v, lo, hi int) int {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}
