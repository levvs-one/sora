package probe

import (
	"sync"
	"time"
)

// PathQuality accumulates local path-quality signals for a transport:
// smoothed RTT, RFC 3550-style jitter, loss streaks, and a stall predicate.
//
// T035 (tspu-analysis/04, /28): the client needs its own measurement of the
// path — RTT/jitter/loss time series per transport — to feed CENSORSHIP-METER
// and to tell "the path died" from "the path is being throttled". This type
// is the sampling core; the meter owns presentation and history.
//
// A PathQuality is safe for concurrent use. The zero value is ready.
type PathQuality struct {
	mu sync.Mutex
	// rtt is the EWMA of successful samples (TCP-style alpha 1/8).
	rtt time.Duration
	// samples counts successful RTT samples.
	samples uint64
	// jitter is the RFC 3550 interarrival-style estimate over RTT deltas.
	jitter time.Duration
	last   time.Duration
	// lossStreak counts consecutive failed samples; maxLossStreak is the
	// worst run seen.
	lossStreak, maxLossStreak int
	// lastOK is the time of the last successful sample.
	lastOK time.Time
	hasOK  bool
}

// Observe records one sample. ok=false marks a failed sample (timeout,
// reset, refused) and leaves the RTT statistics untouched; a non-positive
// rtt with ok=true is a sign of life but not a usable measurement, so it
// updates lastOK without feeding the EWMA. now should be the sample time;
// callers pass it explicitly so tests stay deterministic.
func (q *PathQuality) Observe(rtt time.Duration, ok bool, now time.Time) {
	q.mu.Lock()
	defer q.mu.Unlock()
	if !ok {
		q.lossStreak++
		if q.lossStreak > q.maxLossStreak {
			q.maxLossStreak = q.lossStreak
		}
		return
	}
	q.lossStreak = 0
	q.lastOK, q.hasOK = now, true
	if rtt <= 0 {
		return
	}
	if q.samples == 0 {
		q.rtt = rtt
	} else {
		// EWMA alpha 1/8; jitter per RFC 3550 §A.3 over the delta.
		delta := rtt - q.last
		if delta < 0 {
			delta = -delta
		}
		q.jitter += (delta - q.jitter) / 16
		q.rtt += (rtt - q.rtt) / 8
	}
	q.last = rtt
	q.samples++
}

// RTT returns the smoothed round-trip time, or 0 when no successful sample
// exists yet.
func (q *PathQuality) RTT() time.Duration {
	q.mu.Lock()
	defer q.mu.Unlock()
	return q.rtt
}

// Jitter returns the smoothed absolute RTT delta, or 0 with fewer than two
// samples.
func (q *PathQuality) Jitter() time.Duration {
	q.mu.Lock()
	defer q.mu.Unlock()
	return q.jitter
}

// LossStreak returns the current run of consecutive failed samples.
func (q *PathQuality) LossStreak() int {
	q.mu.Lock()
	defer q.mu.Unlock()
	return q.lossStreak
}

// MaxLossStreak returns the worst loss run observed.
func (q *PathQuality) MaxLossStreak() int {
	q.mu.Lock()
	defer q.mu.Unlock()
	return q.maxLossStreak
}

// Stalled reports whether no successful sample arrived for at least
// threshold. With no successful sample ever, it returns false: absence of
// data is not evidence of a stall. A non-positive threshold never stalls.
func (q *PathQuality) Stalled(threshold time.Duration, now time.Time) bool {
	q.mu.Lock()
	defer q.mu.Unlock()
	return threshold > 0 && q.hasOK && now.Sub(q.lastOK) >= threshold
}
