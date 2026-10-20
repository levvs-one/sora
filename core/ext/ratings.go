// Honest aggregated ratings: the reference implementation of the published
// methodology (see the ratings methodology spec and "How ratings work" in the
// app). The team server computes the per-extension aggregates; the catalog
// carries the finished numbers (rating, ratings_count, installs). This file
// is the normative math both sides must agree on, with tests pinning it.
//
// The methodology, in one paragraph: a plain arithmetic mean is trivially
// gamed — one 5-star vote puts a fresh extension above a 4.8 with two
// thousand votes. So the published rating is a Bayesian average pulled
// toward a prior, recent votes weigh more than old ones, and exactly one
// vote per account per extension counts. The constants below are part of
// the published formula: changing them changes what users see, so they
// change only with an announced catalog format bump, never silently.
package ext

import (
	"math"
	"sort"
	"time"
)

// Published methodology constants. These are load-bearing: the server and
// every client must use the same values, or "4.7" means different things in
// different places.
const (
	// RatingPriorMean is the score an extension with no votes shows.
	// The midpoint of the 1..5 scale: neutrality, not optimism.
	RatingPriorMean = 3.0
	// RatingPriorWeight is the number of phantom prior votes. An extension
	// needs on the order of this many real votes before its own average
	// dominates the prior — a single 5-star review moves 3.0 to ~3.15,
	// not to 5.0.
	RatingPriorWeight = 12.0
	// RatingHalfLife is the freshness half-life: a vote cast this long ago
	// counts half as much as a vote cast today. Old brigades fade.
	RatingHalfLife = 180 * 24 * time.Hour
	// MinVotesForTop is the minimum vote count for "top" badge eligibility.
	// A top extension must have a real electorate, not three friends.
	MinVotesForTop = 25
)

// TimedVote is one account's rating of one extension.
type TimedVote struct {
	// Account is the opaque, stable account id. Exactly one vote per
	// account per extension counts (see DeduplicateVotes).
	Account string
	// Stars is 1..5.
	Stars int
	// At is when the vote was cast.
	At time.Time
}

// BayesianAverage returns the honest aggregate for sum over n votes:
// (n/(n+C))*mean + (C/(n+C))*prior. Few votes -> near the prior; many
// votes -> near the true mean. n == 0 returns the prior, never NaN.
func BayesianAverage(sum float64, n int) float64 {
	if n <= 0 {
		return RatingPriorMean
	}
	mean := sum / float64(n)
	w := float64(n) / (float64(n) + RatingPriorWeight)
	return w*mean + (1-w)*RatingPriorMean
}

// DecayWeight returns the freshness weight of a vote of the given age:
// 2^(-age/halfLife). A vote today weighs 1, at one half-life 0.5, at two
// 0.25. Future timestamps are treated as now (clock skew must not amplify
// a vote).
func DecayWeight(age time.Duration) float64 {
	if age < 0 {
		age = 0
	}
	return math.Pow(2, -float64(age)/float64(RatingHalfLife))
}

// DeduplicateVotes keeps exactly one vote per account — the latest — and
// drops malformed votes (stars outside 1..5, empty account). This is the
// cheapest anti-bribery primitive: a sock-puppet farm still needs one
// account per vote, and accounts are the expensive identity, not votes.
// It does not stop a determined attacker; velocity and account-age checks
// live server-side (see the methodology spec).
func DeduplicateVotes(votes []TimedVote) []TimedVote {
	latest := map[string]TimedVote{}
	for _, v := range votes {
		if v.Account == "" || v.Stars < 1 || v.Stars > 5 {
			continue
		}
		if cur, ok := latest[v.Account]; !ok || v.At.After(cur.At) {
			latest[v.Account] = v
		}
	}
	out := make([]TimedVote, 0, len(latest))
	for _, v := range latest {
		out = append(out, v)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Account < out[j].Account })
	return out
}

// Aggregate computes the published (rating, count) pair from raw votes at
// time now: deduplicate, freshness-weight, then the Bayesian average over
// the effective vote count. The effective count (sum of weights) is what
// the UI shows as ratings_count — an old 100-vote brigade honestly reads
// as fewer effective votes than 100 fresh ones.
func Aggregate(votes []TimedVote, now time.Time) (rating float64, count float64) {
	uniq := DeduplicateVotes(votes)
	var sumW, sumWS float64
	for _, v := range uniq {
		w := DecayWeight(now.Sub(v.At))
		sumW += w
		sumWS += w * float64(v.Stars)
	}
	if sumW <= 0 {
		return RatingPriorMean, 0
	}
	// The Bayesian average over effective votes: treat the weighted sum as
	// sumW votes with mean sumWS/sumW.
	mean := sumWS / sumW
	w := sumW / (sumW + RatingPriorWeight)
	return w*mean + (1-w)*RatingPriorMean, sumW
}

// RankScore is the client-side sort key for "by rating": the published
// Bayesian rating blended with a logarithmic installs term. Log installs
// break ties between equally-rated extensions without letting a huge
// install base bury a better-rated newcomer: 10x installs are worth the
// same as +0.05 rating, not an automatic win.
func RankScore(rating float64, installs int) float64 {
	if installs < 0 {
		installs = 0
	}
	return rating + 0.05*math.Log10(float64(installs)+1)
}
