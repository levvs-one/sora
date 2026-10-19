package serversel

import (
	"fmt"
	"sort"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

// ProfileHint carries the bits of the active F5 network profile that steer
// server selection: the profile's preferred server pins the pick when it is
// eligible, and the preferred engine grants a score bonus.
type ProfileHint struct {
	// PreferredServerID pins the pick when that server passes the filters.
	PreferredServerID string
	// PreferredEngine grants a bonus to candidates planned for this engine.
	PreferredEngine engine.Kind
}

// Constraints are the hard filters applied before scoring.
type Constraints struct {
	// Kind is the engine the session will use. "" disables engine gating.
	Kind engine.Kind
	// Caps is the capability matrix to gate against. When Kind is set but
	// Caps is zero, the upstream matrix from engine.Catalog is used.
	Caps engine.Capabilities
	// Profile steers the pick from the active network profile (F5).
	Profile ProfileHint
	// Countries limits candidates to these ISO codes; empty means any.
	Countries []string
	// ExcludeIDs skips these candidates, e.g. the server that just failed.
	ExcludeIDs []string
}

// PickConfig tunes soft preferences. The zero value is usable and disables
// pinning; DefaultPickConfig enables it.
type PickConfig struct {
	// ProfileEngineBonus is added to the total of candidates planned for
	// the profile's preferred engine. Clamped to [0, 0.5].
	ProfileEngineBonus float64
	// PinPreferredServer pins the profile's preferred server when it is
	// eligible. Zero value disables pinning.
	PinPreferredServer bool
}

// DefaultPickConfig returns the reference tuning.
func DefaultPickConfig() PickConfig {
	return PickConfig{ProfileEngineBonus: 0.05, PinPreferredServer: true}
}

func (c PickConfig) clamped() PickConfig {
	c.ProfileEngineBonus = clampFloat(c.ProfileEngineBonus, 0, 0.5)
	return c
}

// Rejection explains why one candidate was filtered out.
type Rejection struct {
	ID     string
	Reason string
}

// Pick is the outcome of PickBest.
type Pick struct {
	Candidate Candidate
	Breakdown Breakdown
	// Pinned is true when the active network profile pinned this server.
	Pinned bool
	// Reason is a human-readable explanation of the choice.
	Reason string
	// Eligible is how many candidates passed the filters.
	Eligible int
	// Rejected lists every filtered candidate with its reason.
	Rejected []Rejection
}

// Picker scores and ranks candidates. It is safe for concurrent use; the
// reliability store may be nil, in which case every server scores the prior
// rate.
type Picker struct {
	score  ScoreConfig
	pick   PickConfig
	scorer *Scorer
	rel    *ReliabilityStore
}

// NewPicker clamps both configs. rel may be nil.
func NewPicker(score ScoreConfig, pick PickConfig, rel *ReliabilityStore) *Picker {
	score = score.clamped()
	pick = pick.clamped()
	return &Picker{score: score, pick: pick, scorer: NewScorer(score), rel: rel}
}

// PickBest filters the candidates by the constraints, scores the survivors
// and returns the best one. Ties break by lower latency, then higher
// bandwidth, then id, so the result is deterministic.
func (p *Picker) PickBest(cands []Candidate, cons Constraints) (Pick, error) {
	if len(cands) == 0 {
		return Pick{}, ErrNoCandidates
	}
	caps := resolveGate(cons)
	excluded := excludeSet(cons.ExcludeIDs)
	countries := countrySet(cons.Countries)

	var eligible []Candidate
	var rejected []Rejection
	for _, c := range cands {
		if why := eligibleCandidate(c, caps, excluded, countries); why != "" {
			rejected = append(rejected, Rejection{ID: c.ID, Reason: why})
			continue
		}
		eligible = append(eligible, c)
	}
	if len(eligible) == 0 {
		return Pick{Rejected: rejected}, fmt.Errorf("%w (%d rejected)", ErrNoEligible, len(rejected))
	}

	if p.pick.PinPreferredServer && cons.Profile.PreferredServerID != "" {
		for _, c := range eligible {
			if c.ID == cons.Profile.PreferredServerID {
				b := p.breakdown(c, eligible)
				return Pick{
					Candidate: c,
					Breakdown: b,
					Pinned:    true,
					Reason:    fmt.Sprintf("pinned by the active network profile (score %.2f)", b.Total),
					Eligible:  len(eligible),
					Rejected:  rejected,
				}, nil
			}
		}
		// Preferred server absent or filtered out: fall through to scoring.
	}

	ranked := p.rank(eligible, cons.Profile.PreferredEngine)
	best := ranked[0]
	return Pick{
		Candidate: best.c,
		Breakdown: best.b,
		Reason:    fmt.Sprintf("highest composite score %.2f among %d eligible servers", best.b.Total, len(eligible)),
		Eligible:  len(eligible),
		Rejected:  rejected,
	}, nil
}

// resolveGate picks the capability matrix: explicit Caps win, otherwise the
// upstream catalog entry for Kind. A zero Kind means no gating.
func resolveGate(cons Constraints) engine.Capabilities {
	if cons.Caps.Kind != "" {
		return cons.Caps
	}
	if cons.Kind != "" {
		if caps, ok := engine.Catalog[cons.Kind]; ok {
			return caps
		}
	}
	return engine.Capabilities{}
}

// eligibleCandidate returns "" when the candidate passes every filter.
func eligibleCandidate(c Candidate, caps engine.Capabilities, excluded, countries map[string]bool) string {
	if c.ID == "" {
		return "empty id"
	}
	if excluded[c.ID] {
		return "excluded by the caller"
	}
	if len(countries) > 0 && !countries[strings.ToUpper(c.Country)] {
		return fmt.Sprintf("country %q not wanted", c.Country)
	}
	// Bypass needs no server at all; it is never a pickable candidate,
	// regardless of the engine gate.
	if c.Protocol == engine.ProtocolBypass {
		return "bypass needs no server"
	}
	if caps.Kind == "" {
		return ""
	}
	if !caps.SupportsProtocol(c.Protocol) {
		return fmt.Sprintf("engine %s has no protocol %s", caps.Kind, c.Protocol)
	}
	if c.Via != "" && !caps.Supports(engine.FeatureChains) {
		return fmt.Sprintf("engine %s cannot chain through %s", caps.Kind, c.Via)
	}
	return ""
}

func excludeSet(ids []string) map[string]bool {
	set := make(map[string]bool, len(ids))
	for _, id := range ids {
		set[id] = true
	}
	return set
}

func countrySet(countries []string) map[string]bool {
	set := make(map[string]bool, len(countries))
	for _, cc := range countries {
		set[strings.ToUpper(cc)] = true
	}
	return set
}

type ranked struct {
	c Candidate
	b Breakdown
}

// rank scores every candidate and sorts best-first.
func (p *Picker) rank(eligible []Candidate, preferredEngine engine.Kind) []ranked {
	ctx := ContextFor(eligible)
	out := make([]ranked, 0, len(eligible))
	for _, c := range eligible {
		b := p.scorer.Score(c, ctx, p.reliability(c.ID))
		if preferredEngine != "" && c.Engine == preferredEngine {
			b.Total = clamp01(b.Total + p.pick.ProfileEngineBonus)
		}
		out = append(out, ranked{c: c, b: b})
	}
	sort.SliceStable(out, func(i, j int) bool {
		a, z := out[i], out[j]
		if a.b.Total != z.b.Total {
			return a.b.Total > z.b.Total
		}
		// Tie-breaks: known latency beats unknown, lower beats higher.
		if a.c.HasLatency != z.c.HasLatency {
			return a.c.HasLatency
		}
		if a.c.HasLatency && a.c.LatencyMs != z.c.LatencyMs {
			return a.c.LatencyMs < z.c.LatencyMs
		}
		if a.c.HasBandwidth != z.c.HasBandwidth {
			return a.c.HasBandwidth
		}
		if a.c.HasBandwidth && a.c.BandwidthBps != z.c.BandwidthBps {
			return a.c.BandwidthBps > z.c.BandwidthBps
		}
		return a.c.ID < z.c.ID
	})
	return out
}

// breakdown scores one candidate against the eligible set.
func (p *Picker) breakdown(c Candidate, eligible []Candidate) Breakdown {
	return p.scorer.Score(c, ContextFor(eligible), p.reliability(c.ID))
}

// reliability reads the store rate, or the prior when there is no store.
func (p *Picker) reliability(id string) float64 {
	if p.rel == nil {
		return priorRate(p.score.PriorSuccess, p.score.PriorFailure)
	}
	return p.rel.Rate(id)
}
