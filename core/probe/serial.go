package probe

import (
	"context"
	"time"
)

// Serial probing for two-stage blocking (T041/P01-2).
//
// A single probe can lie: the censor's detect→analyze→disseminate cycle
// runs roughly 5–15 minutes, so a block that is already decided may not be
// visible yet when you probe once. The te-st.org methodology this follows:
// probe in a SERIES over 10–15 minutes, and call the path clean only if the
// whole series stays clean. A series that starts clean and turns blocked
// mid-way is itself a signal — two-stage blocking caught in the act — and
// is reported as such instead of being averaged away.

const (
	// DefaultSeriesDuration is the recommended series length: longer than
	// the censor's dissemination cycle, so a decided block has time to
	// become visible.
	DefaultSeriesDuration = 12 * time.Minute
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
	Clean          bool
	FirstFailure   time.Time
	lastAttempt    time.Time
	passesBefore   int
	passAfterFirst bool
}

// RunSeries probes until Duration elapses or ctx is cancelled, then
// reports. It never stops early on failure: quitting at the first failed
// attempt is exactly the single-probe lie this exists to replace. A
// cancelled context returns the partial series, not an error — partial
// evidence is still evidence.
//
// NOT WIRED: no RPC or diagnostic path runs series yet — it is a tested
// primitive waiting for the serial-probe client trigger (T041).
func RunSeries(ctx context.Context, opts SeriesOptions, probe ProbeFunc) SeriesResult {
	opts = opts.normalized()
	var res SeriesResult
	deadline := time.Now().Add(opts.Duration)
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
	return r
}
