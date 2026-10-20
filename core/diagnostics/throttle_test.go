package diagnostics

import (
	"testing"
	"time"
)

func series(t *testing.T, bps []float64) []ThroughputSample {
	t.Helper()
	base := time.Now().Add(-time.Duration(len(bps)) * 10 * time.Second)
	out := make([]ThroughputSample, len(bps))
	for i, b := range bps {
		out[i] = ThroughputSample{At: base.Add(time.Duration(i) * 10 * time.Second), Bps: b}
	}
	return out
}

func healthy(n int) []float64 {
	s := make([]float64, n)
	for i := range s {
		s[i] = 10e6 // 10 Mbps control
	}
	return s
}

func TestClassifyPolicerPlateau(t *testing.T) {
	// The Twitter/YouTube signature: target pinned at ~128 kbps with tiny
	// variance while the control is healthy.
	target := []float64{128e3, 131e3, 126e3, 129e3, 130e3, 127e3, 132e3, 128e3}
	v := ClassifyDegradation(DegradationInput{
		Target:  series(t, target),
		Control: series(t, healthy(len(target))),
	})
	if v.Kind != DegradationPolicer {
		t.Errorf("kind = %v, want policer (evidence: %v)", v.Kind, v.Evidence)
	}
}

func TestClassifyBlocked(t *testing.T) {
	// Target effectively at zero (but with nonzero samples so the series
	// is not discarded as sparse) while the control is healthy.
	target := []float64{500, 1200, 300, 800, 400, 900, 600, 200}
	v := ClassifyDegradation(DegradationInput{
		Target:  series(t, target),
		Control: series(t, healthy(len(target))),
	})
	if v.Kind != DegradationBlocked {
		t.Errorf("kind = %v, want blocked (evidence: %v)", v.Kind, v.Evidence)
	}
}

func TestClassifyCongestion(t *testing.T) {
	// Both legs degrade with high variance: no plateau, no sync collapse.
	target := []float64{5e6, 2e6, 4e6, 1e6, 3e6, 1.5e6, 2.5e6, 900e3}
	control := []float64{6e6, 3e6, 5e6, 2e6, 4e6, 2.5e6, 3e6, 1.8e6}
	v := ClassifyDegradation(DegradationInput{
		Target:     series(t, target),
		Control:    series(t, control),
		HealthyBps: 8e6, // control median is below this: not healthy
	})
	if v.Kind != DegradationCongestion {
		t.Errorf("kind = %v, want congestion (evidence: %v)", v.Kind, v.Evidence)
	}
}

func TestClassifyEvent(t *testing.T) {
	// Synchronous cliff on both legs: an event, not shaping.
	target := []float64{9e6, 9.2e6, 8.8e6, 9.1e6, 50e3, 40e3, 30e3, 20e3}
	control := []float64{10e6, 10.2e6, 9.8e6, 10.1e6, 60e3, 45e3, 35e3, 25e3}
	v := ClassifyDegradation(DegradationInput{
		Target:     series(t, target),
		Control:    series(t, control),
		HealthyBps: 50e6, // force the "control unhealthy" branch
	})
	if v.Kind != DegradationEvent {
		t.Errorf("kind = %v, want event (evidence: %v)", v.Kind, v.Evidence)
	}
}

func TestClassifyDegradedNotPolicer(t *testing.T) {
	// Target slow but noisy: must not be overclaimed as a policer.
	target := []float64{400e3, 90e3, 300e3, 60e3, 250e3, 110e3, 200e3, 80e3}
	v := ClassifyDegradation(DegradationInput{
		Target:  series(t, target),
		Control: series(t, healthy(len(target))),
	})
	if v.Kind != DegradationDegraded {
		t.Errorf("kind = %v, want degraded (evidence: %v)", v.Kind, v.Evidence)
	}
}

func TestClassifySparseInput(t *testing.T) {
	v := ClassifyDegradation(DegradationInput{
		Target:  series(t, []float64{1e6, 2e6}),
		Control: series(t, healthy(2)),
	})
	if v.Kind != DegradationUnknown {
		t.Errorf("kind = %v, want unknown for sparse input", v.Kind)
	}
	v = ClassifyDegradation(DegradationInput{})
	if v.Kind != DegradationUnknown {
		t.Errorf("kind = %v, want unknown for empty input", v.Kind)
	}
}

func TestClassifyHealthyTarget(t *testing.T) {
	// Nothing wrong: target as fast as control must not classify.
	v := ClassifyDegradation(DegradationInput{
		Target:  series(t, healthy(8)),
		Control: series(t, healthy(8)),
	})
	if v.Kind != DegradationUnknown {
		t.Errorf("kind = %v, want unknown for a healthy pair", v.Kind)
	}
}

func TestClassifyMildSlowdownNotOverclaimed(t *testing.T) {
	// Target at 60% of a healthy control: below the healthy line but not
	// a target-specific collapse — must not be named policer or block.
	target := make([]float64, 8)
	for i := range target {
		target[i] = 6e6
	}
	v := ClassifyDegradation(DegradationInput{
		Target:  series(t, target),
		Control: series(t, healthy(8)),
	})
	if v.Kind == DegradationPolicer || v.Kind == DegradationBlocked {
		t.Errorf("kind = %v, want unknown for a mild slowdown", v.Kind)
	}
}
