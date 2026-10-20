package ext

import (
	"math"
	"testing"
	"time"
)

func TestBayesianAveragePullsToPrior(t *testing.T) {
	// One 5-star vote must not read as a perfect extension.
	if got := BayesianAverage(5, 1); math.Abs(got-3.0) > 0.25 {
		t.Fatalf("one vote: got %.3f, want near the 3.0 prior", got)
	}
	// Many votes converge to the true mean.
	if got := BayesianAverage(4.8*2000, 2000); math.Abs(got-4.8) > 0.02 {
		t.Fatalf("many votes: got %.3f, want ~4.8", got)
	}
	// No votes: the prior, never NaN.
	if got := BayesianAverage(0, 0); got != RatingPriorMean || math.IsNaN(got) {
		t.Fatalf("no votes: got %v", got)
	}
}

func TestDecayWeight(t *testing.T) {
	if w := DecayWeight(0); w != 1 {
		t.Fatalf("now: got %v, want 1", w)
	}
	if w := DecayWeight(RatingHalfLife); math.Abs(w-0.5) > 1e-9 {
		t.Fatalf("one half-life: got %v, want 0.5", w)
	}
	if w := DecayWeight(2 * RatingHalfLife); math.Abs(w-0.25) > 1e-9 {
		t.Fatalf("two half-lives: got %v, want 0.25", w)
	}
	// Future votes (clock skew) must not count extra.
	if w := DecayWeight(-time.Hour); w != 1 {
		t.Fatalf("future: got %v, want 1", w)
	}
}

func TestDeduplicateVotes(t *testing.T) {
	now := time.Now()
	votes := []TimedVote{
		{Account: "a", Stars: 5, At: now.Add(-time.Hour)},
		{Account: "a", Stars: 1, At: now}, // later vote wins
		{Account: "b", Stars: 0, At: now}, // invalid stars dropped
		{Account: "", Stars: 5, At: now},  // empty account dropped
		{Account: "c", Stars: 6, At: now}, // invalid stars dropped
		{Account: "c", Stars: 4, At: now},
	}
	got := DeduplicateVotes(votes)
	if len(got) != 2 {
		t.Fatalf("got %d votes, want 2", len(got))
	}
	for _, v := range got {
		if v.Account == "a" && v.Stars != 1 {
			t.Fatalf("account a: kept stars=%d, want the latest (1)", v.Stars)
		}
	}
}

func TestAggregateFreshBeatsStale(t *testing.T) {
	now := time.Now()
	stale := make([]TimedVote, 100)
	for i := range stale {
		stale[i] = TimedVote{Account: string(rune('a'+i%26)) + string(rune('0'+i/26)), Stars: 5, At: now.Add(-4 * RatingHalfLife)}
	}
	fresh := []TimedVote{{Account: "x", Stars: 1, At: now}}
	rStale, cStale := Aggregate(stale, now)
	rFresh, _ := Aggregate(fresh, now)
	// 100 ancient 5-star votes must not outrank honest math: their
	// effective count decayed to ~6, so the rating stays near the prior.
	if cStale > 10 {
		t.Fatalf("stale effective count %.1f, want decayed well below 100", cStale)
	}
	if rStale > 4.0 {
		t.Fatalf("stale brigade rating %.2f, want pulled toward the prior", rStale)
	}
	// A single fresh 1-star vote is honest too: near the prior, not 1.0.
	if math.Abs(rFresh-RatingPriorMean) > 0.3 {
		t.Fatalf("single fresh vote rating %.2f, want near prior", rFresh)
	}
}

func TestRankScore(t *testing.T) {
	// 10x installs are worth +0.05, so a better-rated extension keeps its lead.
	a := RankScore(4.8, 1000)   // log10(1001) ~ 3.0 -> +0.15
	b := RankScore(4.6, 100000) // log10(100001) ~ 5.0 -> +0.25
	if a <= b {
		t.Fatalf("4.8/1k (%.3f) should outrank 4.6/100k (%.3f)", a, b)
	}
	if got := RankScore(4.0, -5); got != RankScore(4.0, 0) {
		t.Fatalf("negative installs must clamp, got %v", got)
	}
}
