// Package serversel picks the best server for a session: it scores
// candidates from probe history (latency, bandwidth), connection reliability
// and data freshness, filters them by engine capabilities and the active
// network profile, and watches the live session for degradation to advise a
// switch without flapping.
//
// Production status (2026-10-20): NOT WIRED. No production code calls
// this package: the live auto-selection users experience is the Dart
// client's (app/lib/src/sora.dart), fed by probe results over the
// control RPC. The package is kept for its unit tests and the designed
// scoring model; moving selection into the core (or deleting this
// implementation in favour of the Dart one) is an owner decision (SW3).
//
// Pass-2 re-verification (2026-10-20): grep over core/, service/,
// tools/ and app/ still finds zero production importers of this
// package, and Picker.WithSubnets (the T011 consumer) is called only
// by this package's tests. There is no Go production point where
// probe results turn into a server choice to wire it into: Connect
// receives a fully built plan from Dart, and group choices are
// delegated to the engines' own url-test. The T011 unlock checklist
// is: (1) owner picks the selection home (SW3); (2a) if Dart — add a
// subnet-state field to ProbeResult in the proto (needs buf/protoc,
// absent here) and consume it in compareAutoSelect/_fastest; or
// (2b) if core — add a selection RPC/plan step that builds candidates
// from stored specs plus prober history and calls
// NewPicker(...).WithSubnets(prober.Subnets()).
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
