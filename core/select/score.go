package serversel

import (
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// ScoreConfig tunes the composite server score. Every field is clamped by
// NewScorer; the zero value is usable and means defaults.
type ScoreConfig struct {
	// Weights of the composite score. Defaults: ping 0.35, bandwidth 0.35,
	// reliability 0.20, freshness 0.10. Each is clamped to [0, 1] and the
	// set is normalized to sum 1; an all-zero set falls back to defaults.
	WeightPing        float64
	WeightBandwidth   float64
	WeightReliability float64
	WeightFreshness   float64
	// FreshnessTTL is how long a measurement counts as fresh. Older data
	// decays linearly to zero at the TTL. Clamped to [1h, 720h].
	FreshnessTTL time.Duration
	// PriorSuccess and PriorFailure are the Beta prior pseudo-counts for
	// reliability, so a server with no history scores neutrally instead of
	// perfectly or terribly. Zero disables the prior (pure empirical
	// rate). Clamped to [0, 1000].
	PriorSuccess float64
	PriorFailure float64
	// Now is overridden in tests.
	Now func() time.Time
}

// DefaultScoreConfig returns the reference tuning.
func DefaultScoreConfig() ScoreConfig {
	return ScoreConfig{
		WeightPing:        0.35,
		WeightBandwidth:   0.35,
		WeightReliability: 0.20,
		WeightFreshness:   0.10,
		FreshnessTTL:      24 * time.Hour,
		PriorSuccess:      1,
		PriorFailure:      1,
	}
}

// clamped applies every documented bound. Zero weights fall back to the
// defaults; a zero TTL means the default.
func (c ScoreConfig) clamped() ScoreConfig {
	c.WeightPing = clampFloat(c.WeightPing, 0, 1)
	c.WeightBandwidth = clampFloat(c.WeightBandwidth, 0, 1)
	c.WeightReliability = clampFloat(c.WeightReliability, 0, 1)
	c.WeightFreshness = clampFloat(c.WeightFreshness, 0, 1)
	if c.WeightPing+c.WeightBandwidth+c.WeightReliability+c.WeightFreshness <= 0 {
		d := DefaultScoreConfig()
		c.WeightPing, c.WeightBandwidth = d.WeightPing, d.WeightBandwidth
		c.WeightReliability, c.WeightFreshness = d.WeightReliability, d.WeightFreshness
	}
	if c.FreshnessTTL == 0 {
		c.FreshnessTTL = DefaultScoreConfig().FreshnessTTL
	}
	if c.FreshnessTTL < time.Hour {
		c.FreshnessTTL = time.Hour
	}
	if c.FreshnessTTL > 720*time.Hour {
		c.FreshnessTTL = 720 * time.Hour
	}
	c.PriorSuccess = clampFloat(c.PriorSuccess, 0, 1000)
	c.PriorFailure = clampFloat(c.PriorFailure, 0, 1000)
	return c
}

// normalizedWeights returns the four weights scaled to sum 1.
func (c ScoreConfig) normalizedWeights() (ping, bw, rel, fresh float64) {
	sum := c.WeightPing + c.WeightBandwidth + c.WeightReliability + c.WeightFreshness
	return c.WeightPing / sum, c.WeightBandwidth / sum, c.WeightReliability / sum, c.WeightFreshness / sum
}

// Candidate is one server the session may connect to.
type Candidate struct {
	ID       string
	Protocol engine.Protocol
	// Via is the id of the outbound this one dials through; empty means a
	// direct connection. Chains need the "chains" engine feature.
	Via string
	// Engine is the engine kind this candidate is planned to run on.
	Engine engine.Kind
	// Country is the ISO country code; empty means unknown.
	Country string

	LatencyMs    uint32
	HasLatency   bool
	BandwidthBps uint64
	HasBandwidth bool
	// MeasuredAt is the freshest measurement time of the data above.
	MeasuredAt time.Time
}

// ScoreContext carries the per-set reference values the relative ping and
// bandwidth components are normalized against. Build it with ContextFor.
type ScoreContext struct {
	MinLatencyMs    uint32
	MaxLatencyMs    uint32
	HasLatency      bool
	MaxBandwidthBps uint64
	HasBandwidth    bool
}

// ContextFor derives the reference values from the candidate set.
func ContextFor(cands []Candidate) ScoreContext {
	var ctx ScoreContext
	for _, c := range cands {
		if c.HasLatency {
			if !ctx.HasLatency {
				ctx.HasLatency = true
				ctx.MinLatencyMs, ctx.MaxLatencyMs = c.LatencyMs, c.LatencyMs
			} else {
				if c.LatencyMs < ctx.MinLatencyMs {
					ctx.MinLatencyMs = c.LatencyMs
				}
				if c.LatencyMs > ctx.MaxLatencyMs {
					ctx.MaxLatencyMs = c.LatencyMs
				}
			}
		}
		if c.HasBandwidth {
			ctx.HasBandwidth = true
			if c.BandwidthBps > ctx.MaxBandwidthBps {
				ctx.MaxBandwidthBps = c.BandwidthBps
			}
		}
	}
	return ctx
}

// Breakdown explains one composite score. Every component is in [0, 1];
// Total is the weighted sum with normalized weights.
type Breakdown struct {
	Total       float64
	Ping        float64
	Bandwidth   float64
	Reliability float64
	Freshness   float64
}

// Scorer computes composite server scores.
type Scorer struct {
	cfg ScoreConfig
	now func() time.Time
}

// NewScorer clamps the config and returns a scorer.
func NewScorer(cfg ScoreConfig) *Scorer {
	cfg = cfg.clamped()
	now := cfg.Now
	if now == nil {
		now = time.Now
	}
	return &Scorer{cfg: cfg, now: now}
}

// Config returns the clamped configuration in effect.
func (s *Scorer) Config() ScoreConfig { return s.cfg }

// neutralComponent is the score for "no data": neither rewarded nor punished.
const neutralComponent = 0.5

// Score rates one candidate. reliability is the connection success rate in
// [0, 1] (e.g. from ReliabilityStore.Rate); it is clamped defensively.
func (s *Scorer) Score(c Candidate, ctx ScoreContext, reliability float64) Breakdown {
	wp, wb, wr, wf := s.cfg.normalizedWeights()
	b := Breakdown{
		Ping:        s.pingScore(c, ctx),
		Bandwidth:   s.bandwidthScore(c, ctx),
		Reliability: clamp01(reliability),
		Freshness:   s.freshnessScore(c),
	}
	b.Total = clamp01(wp*b.Ping + wb*b.Bandwidth + wr*b.Reliability + wf*b.Freshness)
	return b
}

// pingScore is relative to the candidate set: the fastest scores 1, the
// slowest 0. A lone or dataless candidate scores neutrally.
func (s *Scorer) pingScore(c Candidate, ctx ScoreContext) float64 {
	if !c.HasLatency || !ctx.HasLatency {
		return neutralComponent
	}
	span := ctx.MaxLatencyMs - ctx.MinLatencyMs
	if span == 0 {
		return 1
	}
	return clamp01(1 - float64(c.LatencyMs-ctx.MinLatencyMs)/float64(span))
}

// bandwidthScore is relative to the fastest measured candidate.
func (s *Scorer) bandwidthScore(c Candidate, ctx ScoreContext) float64 {
	if !c.HasBandwidth || ctx.MaxBandwidthBps == 0 {
		return neutralComponent
	}
	return clamp01(float64(c.BandwidthBps) / float64(ctx.MaxBandwidthBps))
}

// freshnessScore decays linearly from 1 (just measured) to 0 at the TTL.
// A candidate with no measurements at all scores neutrally.
func (s *Scorer) freshnessScore(c Candidate) float64 {
	if !c.HasLatency && !c.HasBandwidth {
		return neutralComponent
	}
	age := s.now().Sub(c.MeasuredAt)
	if age < 0 {
		age = 0
	}
	return clamp01(1 - float64(age)/float64(s.cfg.FreshnessTTL))
}
