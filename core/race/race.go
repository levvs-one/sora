// Package race runs Happy Eyeballs (RFC 9460, v3) connection races: when
// one server is reachable through several candidate transports or
// addresses, the first successful dial wins and the losers are cancelled.
//
// Candidates race in slice order, and the slice order is the preference
// order — it must be deterministic, never shuffled. The race starts the
// first candidate immediately and staggers the rest (the RFC 8305
// "Connection Attempt Delay"), keeping at most Concurrency attempts in
// flight. A single candidate skips the race entirely and dials directly,
// so the common case pays no goroutine or scheduling overhead.
package race

import (
	"context"
	"errors"
	"fmt"
	"net"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Race bounds follow Happy Eyeballs v3: a small parallel set, not a flood.
const (
	// DefaultConcurrency races two candidates at once: enough to dodge a
	// blackholed first address without opening a socket storm.
	DefaultConcurrency = 2
	// MaxConcurrency caps the race at three simultaneous attempts.
	MaxConcurrency = 3
	// DefaultStagger delays each next candidate after the previous one
	// started, so a healthy first candidate wins without spawning the
	// rest. 250ms is the classic connection-attempt delay.
	DefaultStagger = 250 * time.Millisecond
)

// Candidate is one dialable transport or address of a server.
type Candidate struct {
	// Label names the candidate for telemetry: it identifies the
	// winner in Result and may hold an address. Labels never enter
	// error text, so putting addresses here does not leak them into
	// redacted error details.
	Label string
	// Network and Address are the default dial target when Dial is nil.
	Network string
	Address string
	// Dial establishes the connection. Nil dials Network/Address over
	// TCP. It must honor ctx: a Dial that ignores cancellation keeps
	// its goroutine past the race, and the race waits for every
	// attempt before returning.
	Dial func(ctx context.Context) (net.Conn, error)
}

// Options tunes the race. The zero value races two candidates with the
// default stagger and no per-attempt timeout.
type Options struct {
	// Concurrency caps simultaneous attempts. Zero means
	// DefaultConcurrency; values above MaxConcurrency are clamped.
	// Concurrency 1 degrades to sequential dials in slice order.
	Concurrency int
	// Stagger delays each next candidate after the previous one began.
	// Zero means DefaultStagger. A failed attempt frees its slot
	// immediately instead of waiting out the stagger.
	Stagger time.Duration
	// AttemptTimeout bounds one attempt. Zero means no per-attempt
	// timeout beyond the caller's context.
	AttemptTimeout time.Duration
}

// Result is the winning attempt. The caller owns Conn.
type Result struct {
	// Index is the winner's position in the candidates slice. With
	// equal dial latency the lower index wins because it started
	// earlier, so preference order is deterministic.
	Index int
	// Label and Address mirror the winning candidate for telemetry.
	Label   string
	Address string
	// Latency measures the winning dial only.
	Latency time.Duration
	// Conn is the winner's connection.
	Conn net.Conn
}

// Race dials the candidates and returns the first success. Losers are
// cancelled through their attempt context; Race waits for every attempt
// goroutine before returning, so none outlive it. When every candidate
// fails, the error aggregates each attempt's classified failure.
func Race(ctx context.Context, candidates []Candidate, opts Options) (Result, error) {
	o := opts.normalized()
	if len(candidates) == 0 {
		return Result{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"race: at least one candidate is required")
	}
	if err := ctx.Err(); err != nil {
		return Result{}, errs.From(err)
	}
	// One candidate is not a race: dial directly, no goroutines.
	if len(candidates) == 1 {
		return runSingle(ctx, candidates[0], o.AttemptTimeout)
	}
	return runRace(ctx, candidates, o)
}

func (o Options) normalized() Options {
	if o.Concurrency <= 0 {
		o.Concurrency = DefaultConcurrency
	}
	if o.Concurrency > MaxConcurrency {
		o.Concurrency = MaxConcurrency
	}
	if o.Stagger < 0 {
		o.Stagger = 0
	}
	if o.Stagger == 0 {
		o.Stagger = DefaultStagger
	}
	if o.AttemptTimeout < 0 {
		o.AttemptTimeout = 0
	}
	return o
}

// outcome is one attempt's report.
type outcome struct {
	index   int
	conn    net.Conn
	latency time.Duration
	err     error
}

// runSingle dials the only candidate without spawning a goroutine.
func runSingle(ctx context.Context, c Candidate, attemptTimeout time.Duration) (Result, error) {
	r := attempt(ctx, 0, c, attemptTimeout)
	if r.err != nil {
		return Result{}, r.err
	}
	return Result{Index: 0, Label: c.Label, Address: c.Address, Latency: r.latency, Conn: r.conn}, nil
}

// runRace staggers the candidates and takes the first success.
func runRace(ctx context.Context, candidates []Candidate, o Options) (Result, error) {
	raceCtx, cancel := context.WithCancel(ctx)
	defer cancel()

	results := make(chan outcome, len(candidates))
	var wg sync.WaitGroup

	// next and done live only on this goroutine: no races on them.
	next, done := 0, 0
	failures := make([]error, len(candidates))

	stagger := time.NewTimer(0)
	defer stagger.Stop()
	// startNext launches at most one candidate: the next one starts
	// after the stagger, or immediately when a finished attempt frees
	// a slot.
	startNext := func() {
		if next >= len(candidates) || next-done >= o.Concurrency {
			return
		}
		i := next
		next++
		wg.Add(1)
		go func() {
			defer wg.Done()
			results <- attemptGuarded(raceCtx, i, candidates[i], o.AttemptTimeout)
		}()
		// Re-arm the stagger for the candidate after this one,
		// draining a timer that already fired.
		if !stagger.Stop() {
			select {
			case <-stagger.C:
			default:
			}
		}
		stagger.Reset(o.Stagger)
	}
	// drainLate closes connections of attempts that succeeded after the
	// race was already decided: nobody will read their outcomes, and an
	// unread connection would leak.
	drainLate := func() {
		for ; done < next; done++ {
			if r := <-results; r.conn != nil {
				_ = r.conn.Close()
			}
		}
	}

	startNext()
	for done < len(candidates) {
		select {
		case <-raceCtx.Done():
			// The caller's context died: stop launching. Attempts
			// honor the context, so the wait below cannot hang on a
			// well-behaved Dial; then close any connection that won
			// concurrently with the cancellation.
			wg.Wait()
			drainLate()
			return Result{}, errs.From(context.Cause(ctx))
		case r := <-results:
			done++
			if r.err == nil {
				cancel()
				wg.Wait()
				drainLate()
				c := candidates[r.index]
				return Result{Index: r.index, Label: c.Label, Address: c.Address,
					Latency: r.latency, Conn: r.conn}, nil
			}
			failures[r.index] = r.err
			startNext()
		case <-stagger.C:
			startNext()
		}
	}
	wg.Wait()
	return Result{}, joinFailures(failures)
}

// attemptGuarded runs one attempt, converting a panicking Dial into an
// error outcome. A panic must fail its candidate, never hang the race:
// without the guard the panicked goroutine would send no outcome and
// drainLate would block on it forever, even after the caller cancels.
func attemptGuarded(ctx context.Context, index int, c Candidate, attemptTimeout time.Duration) (out outcome) {
	defer func() {
		if p := recover(); p != nil {
			out = outcome{index: index, err: errs.Newf(errs.CodeInternal, errs.KeyInternal,
				"candidate %d panicked: %v", index, p)}
		}
	}()
	return attempt(ctx, index, c, attemptTimeout)
}

// attempt dials one candidate. The error is classified before it leaves,
// so aggregated failures carry codes; the candidate label never enters
// error text (see Candidate.Label).
func attempt(ctx context.Context, index int, c Candidate, attemptTimeout time.Duration) outcome {
	ctx, cancel := withAttemptTimeout(ctx, attemptTimeout)
	defer cancel()
	start := time.Now()
	conn, err := c.dial(ctx)
	if err != nil {
		// Classify first: address-stripping happens in errs.From, so
		// the candidate attribution added afterwards cannot leak an
		// address into redacted details.
		return outcome{index: index, err: fmt.Errorf("candidate %d: %w", index, errs.From(err))}
	}
	if conn == nil {
		return outcome{index: index, err: errs.Newf(errs.CodeUnavailable, errs.KeyNetworkFailed,
			"candidate %d dialed without a connection and without an error", index)}
	}
	return outcome{index: index, conn: conn, latency: time.Since(start)}
}

// dial runs the candidate's Dial, defaulting to a TCP dial of
// Network/Address.
func (c Candidate) dial(ctx context.Context) (net.Conn, error) {
	if c.Dial != nil {
		return c.Dial(ctx)
	}
	network := c.Network
	if network == "" {
		network = "tcp"
	}
	return (&net.Dialer{}).DialContext(ctx, network, c.Address)
}

func withAttemptTimeout(ctx context.Context, d time.Duration) (context.Context, context.CancelFunc) {
	if d > 0 {
		return context.WithTimeout(ctx, d)
	}
	return ctx, func() {}
}

// joinFailures aggregates the per-candidate failures, indexed by
// candidate so the aggregate is deterministic for the same inputs.
// When every attempt failed the same way the aggregate keeps that
// code and key; mixed failures report unavailable.
func joinFailures(failures []error) error {
	errsList := make([]error, 0, len(failures))
	for _, err := range failures {
		if err != nil {
			errsList = append(errsList, err)
		}
	}
	if unanimous, code, key := classifyUnanimous(errsList); unanimous {
		return errs.Wrap(errors.Join(errsList...), code, key)
	}
	return errs.Wrap(errors.Join(errsList...), errs.CodeUnavailable, errs.KeyNetworkFailed)
}

// classifyUnanimous reports whether every failure carries the same code,
// returning that code and key for the aggregate.
func classifyUnanimous(failures []error) (bool, errs.Code, errs.Key) {
	if len(failures) == 0 {
		return false, "", ""
	}
	code, key := errs.CodeOf(failures[0]), errs.KeyOf(failures[0])
	for _, err := range failures[1:] {
		if errs.CodeOf(err) != code || errs.KeyOf(err) != key {
			return false, "", ""
		}
	}
	return true, code, key
}
