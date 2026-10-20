package probe

import (
	"context"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// Serial probing for two-stage blocking (T041/P01-2, T055).
//
// A single probe can lie: the censor's detect→analyze→disseminate cycle
// runs roughly 5–15 minutes, so a block that is already decided may not be
// visible yet when you probe once. The te-st.org methodology this follows:
// probe in a SERIES, and call the path alive only if a series covering the
// whole dissemination cycle stays clean (see SeriesResult.Liveness). A
// single probe — or a shorter series — proves only "alive for now". A
// series that starts clean and turns blocked mid-way is itself a signal —
// two-stage blocking caught in the act — and is reported as such instead
// of being averaged away.
//
// Wiring (T055): Prober.ProbeSeries runs a series through the prober's
// own dial path, and the sora-core binary exposes it as the
// -series-probe diagnostic (cmd/sora-core/seriesprobe.go). What remains
// unwired is the in-app trigger: ProbeResult carries no series-verdict
// field, so the Dart client cannot request or display a series verdict
// until the proto gains one — this repo has no buf/protoc to add it.

const (
	// SeriesConfirmationWindow is the minimum clean coverage before a
	// series may call a path alive: the full length of the censor's
	// detect→analyze→disseminate cycle (5–15 min, T055). Shorter clean
	// evidence is "alive for now", never "alive".
	SeriesConfirmationWindow = 15 * time.Minute
	// DefaultSeriesDuration is the recommended series length: exactly the
	// confirmation window, so a default series can confirm liveness.
	DefaultSeriesDuration = SeriesConfirmationWindow
	// DefaultSeriesInterval is the pause between attempts: frequent enough
	// to catch the transition, sparse enough not to look like a scan.
	DefaultSeriesInterval = time.Minute
)

// ProbeFunc is one probe attempt: nil means the path looked clean.
type ProbeFunc func(ctx context.Context) error

// SeriesOptions tunes a probe series.
type SeriesOptions struct {
	// Duration is the total series length. Zero means the default.
	Duration time.Duration
	// Interval is the pause between attempts. Zero means the default.
	Interval time.Duration
	// AttemptTimeout bounds one attempt; a hanging attempt counts as a
	// failure. Zero means Interval.
	AttemptTimeout time.Duration
}

func (o SeriesOptions) normalized() SeriesOptions {
	if o.Duration <= 0 {
		o.Duration = DefaultSeriesDuration
	}
	if o.Interval <= 0 {
		o.Interval = DefaultSeriesInterval
	}
	if o.AttemptTimeout <= 0 {
		o.AttemptTimeout = o.Interval
	}
	return o
}

// SeriesResult is the verdict of one probe series.
type SeriesResult struct {
	Attempts int
	Failures int
	// TwoStage is true when early attempts passed and every attempt after
	// the first failure also failed: the block landed mid-series and
	// stayed. This is the two-stage signature. Interleaved pass/fail
	// (flakiness) does not qualify — it looks different and means
	// something different.
	TwoStage bool
	// Clean is true only when every attempt passed. A single-attempt
	// "clean" is not clean; use a series.
	Clean        bool
	FirstFailure time.Time
	// StartedAt is when the first attempt ran.
	StartedAt time.Time
	// Covered is the span from the first to the last attempt: how much of
	// the censor's dissemination cycle this series actually observed.
	// Liveness compares it against SeriesConfirmationWindow.
	Covered        time.Duration
	lastAttempt    time.Time
	passesBefore   int
	passAfterFirst bool
}

// Liveness is the honest claim a series supports (T055). The scale is
// deliberately asymmetric: "alive" is the strong claim and needs a full
// confirmation window of clean attempts; everything weaker says exactly
// how weak it is.
type Liveness int

const (
	// LivenessUnknown means no attempt completed: nothing is proven.
	LivenessUnknown Liveness = iota
	// LivenessAliveForNow means every attempt so far passed, but the
	// series covered less than SeriesConfirmationWindow: a decided block
	// may simply not have been disseminated yet.
	LivenessAliveForNow
	// LivenessAliveConfirmed means a clean series covered the whole
	// confirmation window: the path is alive, not just alive so far.
	LivenessAliveConfirmed
	// LivenessTwoStageBlocked means the series started clean and then
	// every attempt failed: the two-stage block landed mid-series.
	LivenessTwoStageBlocked
	// LivenessFailing means attempts failed without the two-stage
	// signature (blocked from the start, or intermittently): the path
	// is not alive either way.
	LivenessFailing
)

// String renders the verdict for reports.
func (l Liveness) String() string {
	switch l {
	case LivenessAliveForNow:
		return "alive-for-now"
	case LivenessAliveConfirmed:
		return "alive"
	case LivenessTwoStageBlocked:
		return "two-stage-blocked"
	case LivenessFailing:
		return "failing"
	default:
		return "unknown"
	}
}

// Liveness returns the claim this series supports. A clean result is
// "alive" only when Covered reaches SeriesConfirmationWindow; below
// that it is "alive for now", however many attempts passed.
func (r SeriesResult) Liveness() Liveness {
	switch {
	case r.Attempts == 0:
		return LivenessUnknown
	case r.TwoStage:
		return LivenessTwoStageBlocked
	case r.Failures > 0 || !r.Clean:
		return LivenessFailing
	case r.Covered >= SeriesConfirmationWindow:
		return LivenessAliveConfirmed
	default:
		return LivenessAliveForNow
	}
}

// RunSeries probes until Duration elapses or ctx is cancelled, then
// reports. It never stops early on failure: quitting at the first failed
// attempt is exactly the single-probe lie this exists to replace. A
// cancelled context returns the partial series, not an error — partial
// evidence is still evidence, and Liveness says how partial it is.
func RunSeries(ctx context.Context, opts SeriesOptions, probe ProbeFunc) SeriesResult {
	opts = opts.normalized()
	var res SeriesResult
	res.StartedAt = time.Now()
	deadline := res.StartedAt.Add(opts.Duration)
	ticker := time.NewTicker(opts.Interval)
	defer ticker.Stop()
	for {
		res.Attempts++
		actx, cancel := context.WithTimeout(ctx, opts.AttemptTimeout)
		err := probe(actx)
		cancel()
		now := time.Now()
		res.lastAttempt = now
		if err != nil {
			res.Failures++
			if res.FirstFailure.IsZero() {
				res.FirstFailure = now
			}
		} else if res.Failures == 0 {
			res.passesBefore++
		} else {
			res.passAfterFirst = true
		}
		if !now.Before(deadline) {
			break
		}
		select {
		case <-ctx.Done():
			return res.finalize()
		case <-ticker.C:
		}
	}
	return res.finalize()
}

func (r SeriesResult) finalize() SeriesResult {
	r.TwoStage = r.passesBefore > 0 && r.Failures > 0 && !r.passAfterFirst
	r.Clean = r.Attempts > 0 && r.Failures == 0
	if r.Attempts > 0 && !r.StartedAt.IsZero() {
		r.Covered = r.lastAttempt.Sub(r.StartedAt)
	}
	return r
}

// ProbeSeries runs a probe series against one endpoint through this
// prober's own dial path (the same dial Probe uses: address racing,
// TLS when configured, freeze observation), so a series attempt is
// exactly the measurement the single-probe path makes — repeated over
// the window. It is the production entry point for the T055 verdict
// rule: callers must read the outcome through SeriesResult.Liveness,
// never through a single attempt.
func (p *Prober) ProbeSeries(ctx context.Context, endpoint *corev1.Endpoint, opts SeriesOptions) (SeriesResult, error) {
	host, port, err := addressOf(endpoint)
	if err != nil {
		return SeriesResult{}, err
	}
	return RunSeries(ctx, opts, func(actx context.Context) error {
		_, _, derr := p.dial(actx, host, port)
		return derr
	}), nil
}
