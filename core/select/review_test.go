// Independent review tests (swarm-review, SW3 Go part). Each test below
// targets a hole found during review; tests 1-5 fail on the pre-review
// code and pass after the review fixes.

package serversel

import (
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"
)

// 1. A NaN weight must be clamped like any other out-of-range value, not
// leak NaN into the total (which would also break the ranking comparator,
// since NaN != NaN).
func TestReviewNaNWeightClamped(t *testing.T) {
	s := NewScorer(ScoreConfig{WeightPing: math.NaN()})
	cands := testCandidates()
	b := s.Score(cands[0], ContextFor(cands), 0.5)
	if math.IsNaN(b.Total) {
		t.Fatal("NaN weight must be clamped; total is NaN")
	}
	wp, wb, wr, wf := s.Config().normalizedWeights()
	for name, w := range map[string]float64{"ping": wp, "bw": wb, "rel": wr, "fresh": wf} {
		if math.IsNaN(w) {
			t.Fatalf("normalized weight %s is NaN", name)
		}
	}
	if math.Abs(wp+wb+wr+wf-1) > 1e-9 {
		t.Fatalf("weights must normalize to 1, got %v", wp+wb+wr+wf)
	}
}

// 2. A NaN reliability input must not escape the breakdown.
func TestReviewNaNScoreInputsClamped(t *testing.T) {
	s := NewScorer(DefaultScoreConfig())
	cands := testCandidates()
	b := s.Score(cands[0], ContextFor(cands), math.NaN())
	if math.IsNaN(b.Reliability) || math.IsNaN(b.Total) {
		t.Fatalf("NaN reliability must be clamped, got %+v", b)
	}
}

// 3. Scoring a candidate against a context it was not part of (e.g. a
// stale context) must not underflow the uint32 latency arithmetic.
func TestReviewPingScoreForeignContext(t *testing.T) {
	s := NewScorer(DefaultScoreConfig())
	c := Candidate{ID: "x", LatencyMs: 10, HasLatency: true}
	ctx := ScoreContext{MinLatencyMs: 100, MaxLatencyMs: 200, HasLatency: true}
	if got := s.pingScore(c, ctx); got != 1 {
		t.Fatalf("candidate faster than the set minimum must score 1, got %v", got)
	}
	slow := Candidate{ID: "y", LatencyMs: 500, HasLatency: true}
	if got := s.pingScore(slow, ctx); got != 0 {
		t.Fatalf("candidate slower than the set maximum must score 0, got %v", got)
	}
}

// 4. The TTL doc promises expired entries are "pruned on save"; the file
// must not accumulate dead entries until the 1MB safety cap drops the
// whole history.
func TestReviewExpiredEntriesPrunedOnSave(t *testing.T) {
	dir := t.TempDir()
	cur := time.Now()
	s := NewReliabilityStore(ReliabilityConfig{
		DataDir:      dir,
		TTL:          time.Hour,
		PriorSuccess: 1,
		PriorFailure: 1,
		Now:          func() time.Time { return cur },
	})
	s.Record("old", true)
	cur = cur.Add(2 * time.Hour)
	s.Record("new", true)

	raw, err := os.ReadFile(filepath.Join(dir, "probe", "reliability.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), `"old"`) {
		t.Fatalf("expired entry must be pruned on save, file = %s", raw)
	}
	if !strings.Contains(string(raw), `"new"`) {
		t.Fatalf("live entry must survive, file = %s", raw)
	}
	// A fresh store over the same file must agree.
	s2 := NewReliabilityStore(ReliabilityConfig{DataDir: dir, TTL: time.Hour})
	if _, _, found := s2.Stats("old"); found {
		t.Fatal("reloaded store must not see the pruned entry")
	}
}

// 5. NaN in the advisor thresholds must fall back to defaults, not turn
// the latency limit into garbage via time.Duration(NaN).
func TestReviewAdvisorNaNConfig(t *testing.T) {
	a := NewAdvisor(AdvisorConfig{LatencyFactor: math.NaN(), ErrorRate: math.NaN()})
	cfg := a.Config()
	d := DefaultAdvisorConfig()
	if cfg.LatencyFactor != d.LatencyFactor || cfg.ErrorRate != d.ErrorRate {
		t.Fatalf("NaN thresholds must take defaults, got %+v", cfg)
	}
	a.Arm("s1", 50*time.Millisecond)
	if sw, _ := feed(a, 40, 50*time.Millisecond, true); sw {
		t.Fatal("healthy traffic must not switch on a NaN-configured advisor")
	}
}

// 6. Locks the documented strict-greater semantics: degradation exactly on
// the threshold is not degradation (matters because window quantization
// makes exact hits common, e.g. 2/4 == 0.5).
func TestReviewExactThresholdNotDegraded(t *testing.T) {
	clk := &fakeClock{t: time.Now()}
	a := NewAdvisor(testAdvisorConfig(clk)) // ErrorRate 0.5, ConfirmWindows 2
	a.Arm("s1", 50*time.Millisecond)

	// Two full windows at exactly 2/4 = 50% errors == the limit.
	for w := 0; w < 2; w++ {
		feed(a, 2, 50*time.Millisecond, false)
		if sw, _ := feed(a, 2, 50*time.Millisecond, true); sw {
			t.Fatalf("exactly-at-threshold must not advise a switch (window %d)", w)
		}
	}
}

// 7. The store claims to be safe for concurrent use; hammer it under -race.
func TestReviewConcurrentStore(t *testing.T) {
	s := NewReliabilityStore(ReliabilityConfig{DataDir: t.TempDir()})
	var wg sync.WaitGroup
	for w := 0; w < 8; w++ {
		wg.Add(1)
		go func(w int) {
			defer wg.Done()
			id := fmt.Sprintf("srv-%d", w%4)
			for i := 0; i < 50; i++ {
				s.Record(id, i%2 == 0)
				_ = s.Rate(id)
				_, _, _ = s.Stats(id)
			}
			_ = s.Prune()
		}(w)
	}
	wg.Wait()
	for i := 0; i < 4; i++ {
		if got := s.Rate(fmt.Sprintf("srv-%d", i)); got < 0 || got > 1 {
			t.Fatalf("rate out of range after concurrent use: %v", got)
		}
	}
}
