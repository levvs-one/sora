package desync

import (
	"context"
	"errors"
	"fmt"
	"io/fs"
	"sort"
	"strings"
	"time"
)

// Bounds for every search. A search against a live censor must stay
// quiet: few candidates, short per-attempt timeouts, a hard total budget.
const (
	MinCandidates  = 1
	MaxCandidates  = 64
	MinAttempt     = time.Second
	MaxAttempt     = 30 * time.Second
	MaxTotalBudget = 5 * time.Minute
	DefaultParents = 3
	DefaultMutPer  = 4
)

// ErrNoWorking is returned when no candidate scored above zero: either
// every genome failed the canaries or the censor is not fooled by any of
// them (or the block is IP-based, which no desync defeats).
var ErrNoWorking = errors.New("desync: no candidate evaded without breaking TCP")

// ErrBudget is returned when the total budget ran out mid-search.
var ErrBudget = errors.New("desync: search budget exhausted")

// ProbeFunc applies one genome and measures it against the canary
// endpoints, returning the report. It must honor ctx: the search cancels
// it on per-attempt timeout and when the caller cancels the run.
type ProbeFunc func(ctx context.Context, p Params) ProbeReport

// Options tunes the search.
type Options struct {
	// MaxCandidates caps total probe attempts across both generations.
	MaxCandidates int
	// AttemptTimeout bounds one probe.
	AttemptTimeout time.Duration
	// TotalBudget caps the whole search.
	TotalBudget time.Duration
	// Parents is how many winners seed the mutation generation.
	Parents int
	// MutationsPerParent caps children per parent.
	MutationsPerParent int
	// Engine filters seeds to what the executor can run: "tpws" or "nfqws".
	Engine string
}

// DefaultOptions is the recommended starting point: up to 24 probes,
// 10 seconds each, 3 minutes total, mutate around the top 3 winners.
func DefaultOptions() Options {
	return Options{
		MaxCandidates:      24,
		AttemptTimeout:     10 * time.Second,
		TotalBudget:        3 * time.Minute,
		Parents:            DefaultParents,
		MutationsPerParent: DefaultMutPer,
		Engine:             "tpws",
	}
}

// Normalize clamps every option into its allowed range.
func (o Options) Normalize() Options {
	if o.MaxCandidates < MinCandidates {
		o.MaxCandidates = MinCandidates
	}
	if o.MaxCandidates > MaxCandidates {
		o.MaxCandidates = MaxCandidates
	}
	if o.AttemptTimeout < MinAttempt {
		o.AttemptTimeout = MinAttempt
	}
	if o.AttemptTimeout > MaxAttempt {
		o.AttemptTimeout = MaxAttempt
	}
	if o.TotalBudget < o.AttemptTimeout {
		o.TotalBudget = o.AttemptTimeout
	}
	if o.TotalBudget > MaxTotalBudget {
		o.TotalBudget = MaxTotalBudget
	}
	if o.Parents < 1 {
		o.Parents = 1
	}
	if o.MutationsPerParent < 0 {
		o.MutationsPerParent = 0
	}
	if o.Engine == "" {
		o.Engine = "tpws"
	}
	return o
}

// SearchResult describes a finished search.
type SearchResult struct {
	// Best is the highest-fitness candidate. Zero Score when none worked.
	Best Scored
	// Ranked lists every probed candidate, best first.
	Ranked []Scored
	// Attempts is how many probes ran.
	Attempts int
	// BindErr is a non-fatal failure to persist or bind the winner
	// (set by Service.Tune, mirroring tune.Result.CacheErr): the
	// winner still applies to this session.
	BindErr error
}

// Succeeded reports whether any candidate worked.
func (r SearchResult) Succeeded() bool { return r.Best.Working() }

// Summary renders the one uniform journal line for a finished search,
// in the same shape package tune uses: strategy id, attempts, and the
// bind warning when persistence failed. It carries no probe content —
// no canary payloads, no latencies, no network identifiers — so every
// caller logs strategies the same way and nothing beyond the outcome
// reaches the log.
//
// The bind warning is a fixed category, never the error's text: the
// binder's errors quote profile values (gateway and DNS addresses
// from profiles validation) and the binding store's quote filesystem
// paths, and a journal line that interpolates them leaks the user's
// network identifiers into the log the redactors never see. The full
// error stays available programmatically in BindErr for the caller.
func (r SearchResult) Summary() string {
	var b strings.Builder
	if r.Succeeded() {
		fmt.Fprintf(&b, "desync: strategy %q worked", r.Best.Params.ID())
	} else {
		b.WriteString("desync: no working strategy")
	}
	fmt.Fprintf(&b, " after %d attempt(s)", r.Attempts)
	if r.BindErr != nil {
		fmt.Fprintf(&b, "; binding not saved: %s", bindErrKind(r.BindErr))
	}
	return b.String()
}

// bindErrKind classifies a bind/persist failure into one of a few
// fixed, content-free tokens for the journal line (see Summary). It
// never echoes the error's own text.
func bindErrKind(err error) string {
	switch {
	case errors.Is(err, fs.ErrPermission):
		return "permission denied"
	case errors.Is(err, fs.ErrNotExist):
		return "storage path missing"
	case errors.Is(err, fs.ErrExist):
		return "storage path conflict"
	default:
		return "bind error"
	}
}

// Search runs the bounded two-generation search: score the seed
// population, then mutate around the winners and score the children.
// It returns the best candidate even when nothing worked (Best.Score 0),
// so the caller can log what was tried; ErrNoWorking is returned alongside.
func Search(ctx context.Context, seeds []Params, opts Options, probe ProbeFunc) (SearchResult, error) {
	var res SearchResult
	if probe == nil {
		return res, errors.New("desync: nil probe func")
	}
	opts = opts.Normalize()
	deadline := time.Now().Add(opts.TotalBudget)
	tried := map[string]bool{}

	eval := func(p Params) (Scored, error) {
		id := p.ID()
		if tried[id] {
			return Scored{}, nil // duplicate: not counted, not an error
		}
		if err := ctx.Err(); err != nil {
			return Scored{}, err
		}
		if remaining := time.Until(deadline); remaining <= 0 {
			return Scored{}, ErrBudget
		} else if remaining < opts.AttemptTimeout {
			// Not enough time left for a full attempt: stop honestly
			// instead of probing with a sliver of timeout.
			return Scored{}, ErrBudget
		}
		tried[id] = true
		pctx, cancel := context.WithTimeout(ctx, opts.AttemptTimeout)
		report := probe(pctx, p)
		cancel()
		sc := Scored{Params: p, Report: report, Score: Score(report)}
		res.Ranked = append(res.Ranked, sc)
		res.Attempts++
		return sc, ctx.Err()
	}

	// Generation 0: the curated seeds, filtered to the executor.
	for _, p := range seeds {
		if res.Attempts >= opts.MaxCandidates {
			break
		}
		if opts.Engine == "tpws" && p.RequiresNFQWS() {
			continue
		}
		if _, err := eval(p); err != nil {
			return res, err
		}
	}
	// Generation 1: mutate around the winners. Only winners (score > 0)
	// become parents — mutating around failures just burns probes.
	sort.Slice(res.Ranked, func(i, j int) bool { return res.Ranked[i].Score > res.Ranked[j].Score })
	parents := 0
	for _, s := range res.Ranked {
		if parents >= opts.Parents || res.Attempts >= opts.MaxCandidates {
			break
		}
		if !s.Working() {
			break // ranked best-first: the rest are failures too
		}
		parents++
		for _, child := range mutate(s.Params, opts.MutationsPerParent) {
			if res.Attempts >= opts.MaxCandidates {
				break
			}
			if opts.Engine == "tpws" && child.RequiresNFQWS() {
				continue
			}
			if _, err := eval(child); err != nil {
				return res, err
			}
		}
	}
	sort.Slice(res.Ranked, func(i, j int) bool { return res.Ranked[i].Score > res.Ranked[j].Score })
	if len(res.Ranked) > 0 {
		res.Best = res.Ranked[0]
	}
	if !res.Succeeded() {
		return res, fmt.Errorf("%w: probed %d candidate(s)", ErrNoWorking, res.Attempts)
	}
	return res, nil
}

// mutation axes: single-field tweaks a human would try next. The pools
// are small on purpose — every child costs a live probe against a censor.
var (
	mutateSplitPos = []string{"1", "2", "3", "sniext+1", "midsld+2", "method+1"}
	mutateFooling  = []string{"", "badseq", "md5sig", "ts"}
	mutateTTL      = []int{0, 2, 3, 5, 8}
)

// mutate generates up to n single-field children of p. It changes one
// axis at a time so a fitness delta stays attributable — the Geneva
// brevity term then keeps the winner minimal.
//
// A child is only emitted when it converts faithfully to a strategy
// plan validation accepts (Params.convertsValidly): a single-field
// tweak can otherwise cross into a combination with no rendering at
// all — a TTL on a non-fake parent, fooling on an OOB parent — and
// every probe spent on such a child is wasted on a genome that could
// only fail closed.
func mutate(p Params, n int) []Params {
	var out []Params
	add := func(c Params) {
		if len(out) >= n || c.ID() == p.ID() || !c.convertsValidly() {
			return
		}
		out = append(out, c)
	}
	for _, pos := range mutateSplitPos {
		if len(out) >= n {
			break
		}
		c := p
		c.SplitPos = pos
		add(c)
	}
	for _, f := range mutateFooling {
		if len(out) >= n {
			break
		}
		c := p
		c.Fooling = f
		add(c)
	}
	for _, ttl := range mutateTTL {
		if len(out) >= n {
			break
		}
		c := p
		c.TTL, c.AutoTTL = ttl, false
		add(c)
	}
	if len(out) < n {
		c := p
		c.AutoTTL, c.TTL = true, 0
		add(c)
	}
	if len(out) < n && p.Scope == "" {
		for _, s := range []Scope{ScopeTLS, ScopeHTTP} {
			c := p
			c.Scope = s
			add(c)
			if len(out) >= n {
				break
			}
		}
	}
	return out
}
