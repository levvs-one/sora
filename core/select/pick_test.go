package serversel

import (
	"errors"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

func pickCandidates() []Candidate {
	now := time.Now()
	return []Candidate{
		{ID: "de-fast", Protocol: engine.ProtocolVLESS, Engine: engine.KindSingBox, Country: "DE",
			LatencyMs: 20, HasLatency: true, BandwidthBps: 100 << 20, HasBandwidth: true, MeasuredAt: now},
		{ID: "de-slow", Protocol: engine.ProtocolVLESS, Engine: engine.KindSingBox, Country: "DE",
			LatencyMs: 200, HasLatency: true, BandwidthBps: 10 << 20, HasBandwidth: true, MeasuredAt: now},
		{ID: "nl-mid", Protocol: engine.ProtocolVMess, Engine: engine.KindXray, Country: "NL",
			LatencyMs: 60, HasLatency: true, BandwidthBps: 50 << 20, HasBandwidth: true, MeasuredAt: now},
	}
}

func TestPickBestEmpty(t *testing.T) {
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)
	if _, err := p.PickBest(nil, Constraints{}); !errors.Is(err, ErrNoCandidates) {
		t.Fatalf("want ErrNoCandidates, got %v", err)
	}
}

func TestPickBestPicksFastest(t *testing.T) {
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)
	pick, err := p.PickBest(pickCandidates(), Constraints{})
	if err != nil {
		t.Fatal(err)
	}
	if pick.Candidate.ID != "de-fast" {
		t.Fatalf("want de-fast, got %s", pick.Candidate.ID)
	}
	if pick.Pinned {
		t.Fatal("must not be pinned without a profile hint")
	}
	if pick.Eligible != 3 || len(pick.Rejected) != 0 {
		t.Fatalf("eligible=%d rejected=%d, want 3/0", pick.Eligible, len(pick.Rejected))
	}
}

func TestPickBestAllFiltered(t *testing.T) {
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)
	// xray-profile runs only on Xray: nothing is eligible for mihomo.
	cands := []Candidate{{ID: "a", Protocol: engine.ProtocolXrayProfile, Engine: engine.KindMihomo}}
	_, err := p.PickBest(cands, Constraints{Kind: engine.KindMihomo})
	if !errors.Is(err, ErrNoEligible) {
		t.Fatalf("want ErrNoEligible, got %v", err)
	}
}

func TestPickBestRejectionsListed(t *testing.T) {
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)
	cands := []Candidate{
		{ID: "bad-proto", Protocol: engine.ProtocolXrayProfile, Engine: engine.KindMihomo},
		{ID: "bypass", Protocol: engine.ProtocolBypass},
		{ID: "good", Protocol: engine.ProtocolVLESS, Engine: engine.KindMihomo},
	}
	pick, err := p.PickBest(cands, Constraints{Kind: engine.KindMihomo})
	if err != nil {
		t.Fatal(err)
	}
	if pick.Candidate.ID != "good" {
		t.Fatalf("want good, got %s", pick.Candidate.ID)
	}
	if len(pick.Rejected) != 2 {
		t.Fatalf("want 2 rejections, got %+v", pick.Rejected)
	}
	byID := map[string]string{}
	for _, r := range pick.Rejected {
		byID[r.ID] = r.Reason
		if r.Reason == "" {
			t.Fatalf("rejection of %s needs a reason", r.ID)
		}
	}
	if _, ok := byID["bad-proto"]; !ok {
		t.Fatalf("bad-proto not rejected: %+v", pick.Rejected)
	}
	if _, ok := byID["bypass"]; !ok {
		t.Fatalf("bypass is never a pickable server: %+v", pick.Rejected)
	}
}

func TestPickBestChainNeedsChainFeature(t *testing.T) {
	noChains := engine.Capabilities{
		Kind:      engine.KindSingBox,
		Protocols: map[engine.Protocol]bool{engine.ProtocolVLESS: true},
		Features:  map[engine.Feature]bool{}, // no FeatureChains
	}
	withChains := noChains
	withChains.Features = map[engine.Feature]bool{engine.FeatureChains: true}

	cands := []Candidate{{ID: "chain", Protocol: engine.ProtocolVLESS, Via: "hop-1"}}
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)

	if _, err := p.PickBest(cands, Constraints{Caps: noChains}); !errors.Is(err, ErrNoEligible) {
		t.Fatalf("chain without chain support must be rejected, got %v", err)
	}
	pick, err := p.PickBest(cands, Constraints{Caps: withChains})
	if err != nil {
		t.Fatalf("chain with chain support must be eligible: %v", err)
	}
	if pick.Candidate.ID != "chain" {
		t.Fatalf("want chain, got %s", pick.Candidate.ID)
	}
}

func TestPickBestProfilePin(t *testing.T) {
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)
	cons := Constraints{Profile: ProfileHint{PreferredServerID: "de-slow"}}
	pick, err := p.PickBest(pickCandidates(), cons)
	if err != nil {
		t.Fatal(err)
	}
	if !pick.Pinned || pick.Candidate.ID != "de-slow" {
		t.Fatalf("profile pin failed: %+v", pick.Candidate)
	}
}

func TestPickBestPinFallsBackWhenAbsent(t *testing.T) {
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)
	cons := Constraints{Profile: ProfileHint{PreferredServerID: "ghost"}}
	pick, err := p.PickBest(pickCandidates(), cons)
	if err != nil {
		t.Fatal(err)
	}
	if pick.Pinned || pick.Candidate.ID != "de-fast" {
		t.Fatalf("absent pin must fall back to best: %+v", pick.Candidate)
	}
}

func TestPickBestPinRespectsFilters(t *testing.T) {
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)
	// de-slow is excluded: the pin must not resurrect it.
	cons := Constraints{
		Profile:    ProfileHint{PreferredServerID: "de-slow"},
		ExcludeIDs: []string{"de-slow"},
	}
	pick, err := p.PickBest(pickCandidates(), cons)
	if err != nil {
		t.Fatal(err)
	}
	if pick.Pinned || pick.Candidate.ID != "de-fast" {
		t.Fatalf("filtered pin must fall back: %+v", pick.Candidate)
	}
}

func TestPickBestProfileEngineBonus(t *testing.T) {
	now := time.Now()
	// Fixed clock: microsecond freshness drift must not break the tie.
	score := ScoreConfig{Now: func() time.Time { return now }}
	mk := func(id string, eng engine.Kind) Candidate {
		return Candidate{ID: id, Protocol: engine.ProtocolVLESS, Engine: eng,
			LatencyMs: 50, HasLatency: true, MeasuredAt: now}
	}
	// Identical measurements: without the bonus the tie breaks by id.
	cands := []Candidate{mk("b-xray", engine.KindXray), mk("a-singbox", engine.KindSingBox)}
	p := NewPicker(score, DefaultPickConfig(), nil)
	plain, err := p.PickBest(cands, Constraints{})
	if err != nil {
		t.Fatal(err)
	}
	if plain.Candidate.ID != "a-singbox" {
		t.Fatalf("tie should break by id, got %s", plain.Candidate.ID)
	}
	bonus, err := p.PickBest(cands, Constraints{Profile: ProfileHint{PreferredEngine: engine.KindXray}})
	if err != nil {
		t.Fatal(err)
	}
	if bonus.Candidate.ID != "b-xray" {
		t.Fatalf("engine bonus should win the tie, got %s", bonus.Candidate.ID)
	}
}

func TestPickBestAllStaleStillPicks(t *testing.T) {
	// Every measurement is older than the freshness TTL: the pick must
	// degrade gracefully instead of failing.
	now := time.Now()
	stale := now.Add(-48 * time.Hour)
	cands := []Candidate{
		{ID: "a", Protocol: engine.ProtocolVLESS, LatencyMs: 20, HasLatency: true, MeasuredAt: stale},
		{ID: "b", Protocol: engine.ProtocolVLESS, LatencyMs: 200, HasLatency: true, MeasuredAt: stale},
	}
	score := ScoreConfig{Now: func() time.Time { return now }}
	p := NewPicker(score, DefaultPickConfig(), nil)
	pick, err := p.PickBest(cands, Constraints{})
	if err != nil {
		t.Fatalf("all-stale candidates must still yield a pick: %v", err)
	}
	if pick.Candidate.ID != "a" {
		t.Fatalf("want the faster stale server, got %s", pick.Candidate.ID)
	}
	if pick.Breakdown.Freshness != 0 {
		t.Fatalf("stale data must score zero freshness, got %v", pick.Breakdown.Freshness)
	}
}

func TestPickBestCountryFilter(t *testing.T) {
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)
	pick, err := p.PickBest(pickCandidates(), Constraints{Countries: []string{"nl"}})
	if err != nil {
		t.Fatal(err)
	}
	if pick.Candidate.ID != "nl-mid" {
		t.Fatalf("want nl-mid, got %s", pick.Candidate.ID)
	}
	if pick.Eligible != 1 {
		t.Fatalf("eligible=%d, want 1", pick.Eligible)
	}
}

func TestPickBestExcludeCurrent(t *testing.T) {
	rel := NewReliabilityStore(ReliabilityConfig{})
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), rel)
	pick, err := p.PickBest(pickCandidates(), Constraints{ExcludeIDs: []string{"de-fast"}})
	if err != nil {
		t.Fatal(err)
	}
	if pick.Candidate.ID == "de-fast" {
		t.Fatal("excluded server must not be picked")
	}
	if pick.Candidate.ID != "nl-mid" {
		t.Fatalf("want nl-mid as the runner-up, got %s", pick.Candidate.ID)
	}
}

func TestPickBestReliabilityMatters(t *testing.T) {
	rel := NewReliabilityStore(ReliabilityConfig{PriorSuccess: 1, PriorFailure: 1})
	// de-fast is flaky: 0 successes against 20 failures.
	for i := 0; i < 20; i++ {
		rel.Record("de-fast", false)
	}
	// nl-mid is solid: 20 successes.
	for i := 0; i < 20; i++ {
		rel.Record("nl-mid", true)
	}
	// Reliability carries half the weight, so trust beats raw speed.
	score := ScoreConfig{WeightPing: 0.2, WeightBandwidth: 0.2, WeightReliability: 0.5, WeightFreshness: 0.1}
	p := NewPicker(score, DefaultPickConfig(), rel)
	pick, err := p.PickBest(pickCandidates(), Constraints{})
	if err != nil {
		t.Fatal(err)
	}
	if pick.Candidate.ID != "nl-mid" {
		t.Fatalf("reliable runner-up should beat flaky fastest, got %s", pick.Candidate.ID)
	}
}

func TestPickConfigClamps(t *testing.T) {
	p := NewPicker(DefaultScoreConfig(), PickConfig{ProfileEngineBonus: 99}, nil)
	now := time.Now()
	mk := func(id string, eng engine.Kind) Candidate {
		return Candidate{ID: id, Protocol: engine.ProtocolVLESS, Engine: eng,
			LatencyMs: 50, HasLatency: true, MeasuredAt: now}
	}
	cands := []Candidate{mk("a", engine.KindXray), mk("b", engine.KindSingBox)}
	pick, err := p.PickBest(cands, Constraints{Profile: ProfileHint{PreferredEngine: engine.KindXray}})
	if err != nil {
		t.Fatal(err)
	}
	if pick.Breakdown.Total > 1 {
		t.Fatalf("bonus must not push the total past 1: %v", pick.Breakdown.Total)
	}
}
