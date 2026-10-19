package serversel

import (
	"math"
	"testing"
	"time"
)

func testCandidates() []Candidate {
	now := time.Now()
	return []Candidate{
		{ID: "fast", LatencyMs: 20, HasLatency: true, BandwidthBps: 100 << 20, HasBandwidth: true, MeasuredAt: now},
		{ID: "mid", LatencyMs: 100, HasLatency: true, BandwidthBps: 50 << 20, HasBandwidth: true, MeasuredAt: now},
		{ID: "slow", LatencyMs: 300, HasLatency: true, BandwidthBps: 10 << 20, HasBandwidth: true, MeasuredAt: now},
	}
}

func TestScoreRelativeComponents(t *testing.T) {
	s := NewScorer(DefaultScoreConfig())
	cands := testCandidates()
	ctx := ContextFor(cands)

	fast := s.Score(cands[0], ctx, 0.5)
	slow := s.Score(cands[2], ctx, 0.5)
	if fast.Ping != 1 || slow.Ping != 0 {
		t.Fatalf("ping not relative: fast=%v slow=%v", fast.Ping, slow.Ping)
	}
	if fast.Bandwidth != 1 {
		t.Fatalf("fastest bandwidth should score 1, got %v", fast.Bandwidth)
	}
	if slow.Bandwidth >= fast.Bandwidth {
		t.Fatalf("slower bandwidth must score lower: %v >= %v", slow.Bandwidth, fast.Bandwidth)
	}
	if fast.Total <= slow.Total {
		t.Fatalf("fast must outscore slow: %v <= %v", fast.Total, slow.Total)
	}
}

func TestScoreSingleCandidate(t *testing.T) {
	s := NewScorer(DefaultScoreConfig())
	now := time.Now()
	c := Candidate{ID: "only", LatencyMs: 50, HasLatency: true, BandwidthBps: 10, HasBandwidth: true, MeasuredAt: now}
	b := s.Score(c, ContextFor([]Candidate{c}), 0.9)
	if b.Ping != 1 || b.Bandwidth != 1 {
		t.Fatalf("lone candidate must top relative scales: %+v", b)
	}
	if b.Freshness < 0.99 {
		t.Fatalf("just-measured data must be fresh: %v", b.Freshness)
	}
	if b.Total < 0 || b.Total > 1 {
		t.Fatalf("total out of range: %v", b.Total)
	}
}

func TestScoreNoDataIsNeutral(t *testing.T) {
	s := NewScorer(DefaultScoreConfig())
	c := Candidate{ID: "new"}
	b := s.Score(c, ContextFor([]Candidate{c}), 0.5)
	for name, v := range map[string]float64{"ping": b.Ping, "bw": b.Bandwidth, "fresh": b.Freshness} {
		if v != neutralComponent {
			t.Fatalf("%s without data must be neutral, got %v", name, v)
		}
	}
}

func TestScoreFreshnessDecay(t *testing.T) {
	fixed := time.Now()
	s := NewScorer(ScoreConfig{FreshnessTTL: time.Hour, Now: func() time.Time { return fixed }})
	fresh := Candidate{ID: "f", LatencyMs: 10, HasLatency: true, MeasuredAt: fixed}
	stale := Candidate{ID: "s", LatencyMs: 10, HasLatency: true, MeasuredAt: fixed.Add(-2 * time.Hour)}
	if got := s.Score(fresh, ContextFor([]Candidate{fresh}), 0.5).Freshness; got < 0.99 {
		t.Fatalf("fresh data scored %v, want ~1", got)
	}
	if got := s.Score(stale, ContextFor([]Candidate{stale}), 0.5).Freshness; got != 0 {
		t.Fatalf("data past TTL scored %v, want 0", got)
	}
}

func TestScoreWeightsNormalized(t *testing.T) {
	// Equal weights must average the components.
	s := NewScorer(ScoreConfig{WeightPing: 2, WeightBandwidth: 2, WeightReliability: 0, WeightFreshness: 0})
	cands := testCandidates()
	b := s.Score(cands[0], ContextFor(cands), 0.9) // reliability weight is 0
	want := (b.Ping + b.Bandwidth) / 2
	if math.Abs(b.Total-want) > 1e-9 {
		t.Fatalf("total %v != mean of components %v", b.Total, want)
	}
	// Reliability must not leak in when its weight is zero.
	if b.Reliability != 0.9 {
		t.Fatalf("reliability component should pass through, got %v", b.Reliability)
	}
}

func TestScoreZeroWeightsFallBackToDefaults(t *testing.T) {
	s := NewScorer(ScoreConfig{})
	cands := testCandidates()
	b := s.Score(cands[0], ContextFor(cands), 0.5)
	if math.IsNaN(b.Total) || b.Total < 0 || b.Total > 1 {
		t.Fatalf("all-zero weights must fall back to defaults, got total %v", b.Total)
	}
	wp, wb, wr, wf := s.Config().normalizedWeights()
	if math.Abs(wp+wb+wr+wf-1) > 1e-9 {
		t.Fatalf("weights must normalize to 1, got %v", wp+wb+wr+wf)
	}
}

func TestScoreConfigClamps(t *testing.T) {
	s := NewScorer(ScoreConfig{
		WeightPing:      -5,
		WeightFreshness: 99,
		FreshnessTTL:    10000 * time.Hour,
		PriorSuccess:    -1,
	})
	cfg := s.Config()
	if cfg.WeightPing != 0 || cfg.WeightFreshness != 1 {
		t.Fatalf("weights not clamped: %+v", cfg)
	}
	if cfg.FreshnessTTL != 720*time.Hour {
		t.Fatalf("TTL not clamped: %v", cfg.FreshnessTTL)
	}
	if cfg.PriorSuccess != 0 {
		t.Fatalf("prior not clamped: %v", cfg.PriorSuccess)
	}
	// Reliability input outside [0,1] must not escape the breakdown.
	cands := testCandidates()
	b := s.Score(cands[0], ContextFor(cands), 42)
	if b.Reliability != 1 {
		t.Fatalf("reliability not clamped: %v", b.Reliability)
	}
}
