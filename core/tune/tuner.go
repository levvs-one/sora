package tune

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/profiles"
)

// Bounds for every tuning run. All options are clamped into these ranges.
const (
	MinStrategies = 1
	MaxStrategies = 32
	MinAttempt    = time.Second
	MaxAttempt    = 2 * time.Minute
	MaxBudget     = 10 * time.Minute
)

// ErrNoStrategy is returned when every tried strategy failed. The message
// lists the strategies that were tried, in order.
var ErrNoStrategy = errors.New("tune: no obfuscation strategy succeeded")

// ErrBudget is returned when the total time budget ran out before the
// candidates were exhausted.
var ErrBudget = errors.New("tune: time budget exhausted")

// Options tunes the tuner's aggression.
type Options struct {
	// MaxStrategies caps how many candidates one run tries.
	MaxStrategies int
	// AttemptTimeout is the per-strategy timeout.
	AttemptTimeout time.Duration
	// TotalBudget caps the whole run across all attempts.
	TotalBudget time.Duration
}

// DefaultOptions is the recommended starting point: up to 8 strategies
// (the full candidate list), 15 seconds each, 2 minutes total.
func DefaultOptions() Options {
	return Options{MaxStrategies: 8, AttemptTimeout: 15 * time.Second, TotalBudget: 2 * time.Minute}
}

// Normalize clamps every option into its allowed range. The zero value is
// valid and means minimal aggression; use DefaultOptions for the
// recommended starting point.
func (o Options) Normalize() Options {
	if o.MaxStrategies < MinStrategies {
		o.MaxStrategies = MinStrategies
	}
	if o.MaxStrategies > MaxStrategies {
		o.MaxStrategies = MaxStrategies
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
	if o.TotalBudget > MaxBudget {
		o.TotalBudget = MaxBudget
	}
	return o
}

// AttemptFunc applies one strategy and probes the connection, returning nil
// on success. It must honor ctx: the tuner cancels it on per-attempt
// timeout and when the caller cancels the run.
type AttemptFunc func(ctx context.Context, s Strategy) error

// AttemptRecord is the outcome of a single strategy attempt.
type AttemptRecord struct {
	Strategy Strategy
	// Duration is how long the attempt took.
	Duration time.Duration
	// Err is nil on success.
	Err error
}

// Result describes a finished tuning run.
type Result struct {
	// Winner is the first strategy that connected. Zero when no strategy
	// worked or the run was cancelled.
	Winner Strategy
	// Attempts records every strategy tried, in order.
	Attempts []AttemptRecord
	// NetworkKey is the fingerprint key the run was cached under.
	NetworkKey string
	// KnownNetwork reports whether the network had a remembered strategy.
	KnownNetwork bool
	// CacheErr is a non-fatal failure to persist the winning strategy.
	CacheErr error
}

// Succeeded reports whether a strategy connected.
func (r Result) Succeeded() bool { return r.Winner.ID != "" }

// Summary renders one honest line for the session journal: which strategy
// worked (or that none did), how many attempts it took and how long it took.
func (r Result) Summary() string {
	var b strings.Builder
	if r.Succeeded() {
		fmt.Fprintf(&b, "tune: strategy %q worked", r.Winner.ID)
	} else {
		b.WriteString("tune: no working strategy")
	}
	var total time.Duration
	for _, a := range r.Attempts {
		total += a.Duration
	}
	fmt.Fprintf(&b, " after %d attempt(s) in %s", len(r.Attempts), total.Round(100*time.Millisecond))
	if r.KnownNetwork {
		b.WriteString(" (known network)")
	}
	if r.CacheErr != nil {
		fmt.Fprintf(&b, "; cache not saved: %v", r.CacheErr)
	}
	return b.String()
}

// Tuner tries obfuscation strategies in priority order until one connects.
// It is safe for concurrent use; run one Tune at a time per network.
type Tuner struct {
	opts  Options
	cache *Cache
}

// New builds a Tuner. A nil cache disables remembering; options are
// normalized.
func New(opts Options, cache *Cache) *Tuner {
	return &Tuner{opts: opts.Normalize(), cache: cache}
}

// Tune tries strategies until one connects, the candidates or the time
// budget run out, or ctx is cancelled. The winner is remembered for the
// network. A nil attempt func is a programmer error and fails fast.
func (t *Tuner) Tune(ctx context.Context, fp profiles.Fingerprint, current Strategy, attempt AttemptFunc) (Result, error) {
	res := Result{NetworkKey: networkKey(fp)}
	if attempt == nil {
		return res, errors.New("tune: nil attempt func")
	}
	if current.ID == "" {
		current = CurrentStrategy()
	}
	var cached *Strategy
	if t.cache != nil {
		if s, ok := t.cache.Lookup(fp); ok {
			cached = &s
			res.KnownNetwork = true
		}
	}
	candidates := Candidates(current, cached)
	if len(candidates) > t.opts.MaxStrategies {
		candidates = candidates[:t.opts.MaxStrategies]
	}
	deadline := time.Now().Add(t.opts.TotalBudget)
	for _, s := range candidates {
		if err := ctx.Err(); err != nil {
			return res, err
		}
		remaining := time.Until(deadline)
		if remaining <= 0 {
			return res, fmt.Errorf("%w after %d attempt(s)", ErrBudget, len(res.Attempts))
		}
		timeout := t.opts.AttemptTimeout
		if remaining < timeout {
			timeout = remaining
		}
		attemptCtx, cancel := context.WithTimeout(ctx, timeout)
		start := time.Now()
		err := attempt(attemptCtx, s)
		dur := time.Since(start)
		cancel()
		res.Attempts = append(res.Attempts, AttemptRecord{Strategy: s, Duration: dur, Err: err})
		if err == nil {
			res.Winner = s
			if t.cache != nil {
				res.CacheErr = t.cache.Remember(fp, s)
			}
			return res, nil
		}
		// The attempt may have failed because the caller cancelled the
		// run; report that honestly instead of "no strategy worked".
		if ctx.Err() != nil {
			return res, ctx.Err()
		}
	}
	ids := make([]string, len(res.Attempts))
	for i, a := range res.Attempts {
		ids[i] = a.Strategy.ID
	}
	last := res.Attempts[len(res.Attempts)-1]
	return res, fmt.Errorf("%w: tried %d (%s); last error from %q: %v",
		ErrNoStrategy, len(res.Attempts), strings.Join(ids, ", "), last.Strategy.ID, last.Err)
}
