package diagnostics

import (
	"math"
	"sort"
	"time"
)

// Differential throttle-vs-block classification (T018, P40-1/P40-7).
//
// The field methodology (OONI throttling-experiment design; Xue et al.
// IMC'21 on the Twitter 2021 throttling) is differential: measure the
// target and a neutral control host as a pair, in the same hour and ASN.
//   - a DPI policer (SNI-III) converges the target to a fixed plateau
//     (~130-150 kbps Twitter, ~128 kbps YouTube) at any hour, while the
//     control stays healthy;
//   - congestion shows high variance on both legs, possibly with a diurnal
//     pattern — and no fixed plateau;
//   - an event (BPLA shutdown, wave) drops both legs synchronously.
//
// Without the pair, "slow in the evening" is misattributed to the VPN and
// the user blames sora. This classifier is pure: it takes two sample
// series and returns a verdict with evidence, never a bare number.

// ThroughputSample is one goodput measurement.
type ThroughputSample struct {
	At  time.Time
	Bps float64
}

// DegradationKind names the classified cause of a slowdown.
type DegradationKind int

const (
	// DegradationUnknown means the series do not support any claim.
	DegradationUnknown DegradationKind = iota
	// DegradationPolicer means the target sits on a stable plateau while
	// the control is healthy: the DPI policer signature.
	DegradationPolicer
	// DegradationCongestion means both legs degrade with high variance:
	// the path is congested, not shaped.
	DegradationCongestion
	// DegradationEvent means both legs collapsed synchronously: an event
	// (shutdown, wave), not a per-service policy.
	DegradationEvent
	// DegradationBlocked means the target is at ~zero while the control
	// is healthy: a block, not a throttle.
	DegradationBlocked
	// DegradationDegraded means the target is slow but the shape is not a
	// clean policer plateau: degraded, cause unproven — never overclaim.
	DegradationDegraded
)

// String renders the kind for logs and the meter UI.
func (k DegradationKind) String() string {
	switch k {
	case DegradationPolicer:
		return "policer"
	case DegradationCongestion:
		return "congestion"
	case DegradationEvent:
		return "event"
	case DegradationBlocked:
		return "blocked"
	case DegradationDegraded:
		return "degraded"
	default:
		return "unknown"
	}
}

// DegradationInput configures one classification run.
type DegradationInput struct {
	// Target is the throttled-service (or VPN-path) series.
	Target []ThroughputSample
	// Control is the neutral-host series measured in the same window.
	Control []ThroughputSample
	// HealthyBps is the control goodput that counts as "healthy".
	// Zero selects the default.
	HealthyBps float64
	// BlockBps bounds "effectively zero" for the target. Zero selects
	// the default.
	BlockBps float64
	// MinSamples is the minimum series length for a claim. Zero selects
	// the default.
	MinSamples int
	// PlateauCV is the max coefficient of variation of the target series
	// that still counts as a policer plateau. Zero selects the default.
	PlateauCV float64
	// SyncWindow bounds "synchronous" for the event detector. Zero
	// selects the default.
	SyncWindow time.Duration
}

// DegradationVerdict is the classification outcome.
type DegradationVerdict struct {
	Kind       DegradationKind
	Confidence float64 // 0..1; below 0.5 the UI must show "unknown"
	Evidence   []string
}

const (
	defaultHealthyBps = 1e6 // 1 Mbps control goodput counts as healthy
	defaultBlockBps   = 8e3 // below 8 kbps the target is effectively dead
	defaultMinSamples = 6
	defaultPlateauCV  = 0.25
	defaultSyncWindow = 90 * time.Second
)

// ClassifyDegradation compares target vs control series measured as a pair
// and names the slowdown: policer plateau, congestion, event, block, or
// degraded-but-unproven. Sparse or contradictory input yields Unknown.
func ClassifyDegradation(in DegradationInput) DegradationVerdict {
	healthyBps := orDefaultFloat(in.HealthyBps, defaultHealthyBps)
	blockBps := orDefaultFloat(in.BlockBps, defaultBlockBps)
	minSamples := in.MinSamples
	if minSamples <= 0 {
		minSamples = defaultMinSamples
	}
	plateauCV := orDefaultFloat(in.PlateauCV, defaultPlateauCV)
	syncWindow := in.SyncWindow
	if syncWindow <= 0 {
		syncWindow = defaultSyncWindow
	}

	target := cleanSeries(in.Target)
	control := cleanSeries(in.Control)
	if len(target) < minSamples || len(control) < minSamples {
		return DegradationVerdict{Kind: DegradationUnknown, Evidence: []string{
			"not enough paired samples to classify the slowdown",
		}}
	}
	tMed := median(target)
	cMed := median(control)
	if tMed >= healthyBps {
		return DegradationVerdict{Kind: DegradationUnknown, Evidence: []string{
			"target goodput is healthy: nothing to classify",
		}}
	}
	controlHealthy := cMed >= healthyBps

	if controlHealthy {
		switch {
		case tMed <= blockBps:
			return DegradationVerdict{Kind: DegradationBlocked, Confidence: 0.8, Evidence: []string{
				"the target is effectively at zero while the control path is healthy: a block, not a throttle",
			}}
		case tMed < 0.5*cMed && cv(target) <= plateauCV:
			return DegradationVerdict{Kind: DegradationPolicer, Confidence: 0.75, Evidence: []string{
				"the target converges to a stable plateau while the control is healthy: the DPI policer signature",
			}}
		case tMed < 0.5*cMed:
			return DegradationVerdict{Kind: DegradationDegraded, Confidence: 0.55, Evidence: []string{
				"the target is slow but not on a clean plateau: degraded, the policer claim is unproven",
			}}
		default:
			return DegradationVerdict{Kind: DegradationUnknown, Evidence: []string{
				"no significant target-specific degradation in this window",
			}}
		}
	}

	// Control is not healthy either: the slowdown is not target-specific.
	tDrop, tAt := deepestDrop(target)
	cDrop, cAt := deepestDrop(control)
	if tDrop && cDrop && absDuration(tAt.Sub(cAt)) <= syncWindow {
		return DegradationVerdict{Kind: DegradationEvent, Confidence: 0.7, Evidence: []string{
			"target and control collapsed within the same window: an event, not a per-service policy",
		}}
	}
	return DegradationVerdict{Kind: DegradationCongestion, Confidence: 0.6, Evidence: []string{
		"both legs degrade without a fixed plateau or a synchronous collapse: congestion, not shaping",
	}}
}

// cleanSeries drops non-positive samples and sorts by time.
func cleanSeries(s []ThroughputSample) []ThroughputSample {
	out := make([]ThroughputSample, 0, len(s))
	for _, p := range s {
		if p.Bps > 0 {
			out = append(out, p)
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].At.Before(out[j].At) })
	return out
}

func median(s []ThroughputSample) float64 {
	vals := make([]float64, len(s))
	for i, p := range s {
		vals[i] = p.Bps
	}
	sort.Float64s(vals)
	m := len(vals) / 2
	if len(vals)%2 == 0 {
		return (vals[m-1] + vals[m]) / 2
	}
	return vals[m]
}

// cv is the coefficient of variation: stddev/mean. A policer plateau has
// low cv; congestion has high cv.
func cv(s []ThroughputSample) float64 {
	var sum float64
	for _, p := range s {
		sum += p.Bps
	}
	mean := sum / float64(len(s))
	if mean == 0 {
		return math.Inf(1)
	}
	var sq float64
	for _, p := range s {
		d := p.Bps - mean
		sq += d * d
	}
	return math.Sqrt(sq/float64(len(s))) / mean
}

// deepestDrop reports whether the series collapses to under 20% of its
// early median, and when the minimum occurred.
func deepestDrop(s []ThroughputSample) (bool, time.Time) {
	if len(s) < 4 {
		return false, time.Time{}
	}
	early := median(s[:len(s)/2])
	minIdx := 0
	for i, p := range s {
		if p.Bps < s[minIdx].Bps {
			minIdx = i
		}
	}
	if early > 0 && s[minIdx].Bps < 0.2*early {
		return true, s[minIdx].At
	}
	return false, time.Time{}
}

func absDuration(d time.Duration) time.Duration {
	if d < 0 {
		return -d
	}
	return d
}

func orDefaultFloat(v, def float64) float64 {
	if v <= 0 {
		return def
	}
	return v
}
