package probe

import (
	"fmt"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// BrutalCalibrator is the caller-facing Hysteria2 brutal calibration
// seam (CENSOR-P3, spec 21-hysteria2.md §4). It turns a measured
// download rate — produced by a Benchmarker run somebody explicitly
// started, on this network, through the server in question — into
// plan caps, with the bookkeeping the spec demands:
//
//   - Manual caps are data, not a hint: an outbound whose plan
//     already carries UpMbps or DownMbps (from the share link, the
//     credential document or a user edit) is returned untouched and
//     reported as SourceManual. Calibration never overwrites them.
//   - Results are cached per outbound id for CalibrationCooldown
//     (7 days): re-applying a fresh-enough result costs no traffic.
//   - A stale or missing entry needs a fresh measurement; the
//     calibrator never measures by itself (no background traffic,
//     per the spec) — the caller passes the Benchmarker figure in.
//
// When no measurement is available and no manual caps exist, Apply
// says so (SourceNone) instead of inventing caps: BBR stays in
// charge, which is the honest degradation — a fabricated brutal cap
// is worse than none, because brutal with a wrong cap throttles or
// floods the path.
type BrutalCalibrator struct {
	mu    sync.Mutex
	cache map[string]brutalEntry
	now   func() time.Time
}

type brutalEntry struct {
	up, down    int
	upEstimated bool
	at          time.Time
}

// BrutalSource names where an outbound's caps came from.
type BrutalSource int

const (
	// SourceNone: no caps applied (no measurement, no manual caps).
	SourceNone BrutalSource = iota
	// SourceManual: the plan's own caps, left untouched.
	SourceManual
	// SourceMeasured: caps calibrated from a fresh measurement.
	SourceMeasured
	// SourceCached: caps from a measurement still inside the cooldown.
	SourceCached
)

// BrutalResult reports what Apply decided for one outbound.
type BrutalResult struct {
	Source      BrutalSource
	UpMbps      int
	DownMbps    int
	UpEstimated bool
	MeasuredAt  time.Time
}

// NewBrutalCalibrator returns an empty calibrator.
func NewBrutalCalibrator() *BrutalCalibrator {
	return &BrutalCalibrator{cache: map[string]brutalEntry{}, now: time.Now}
}

// Apply resolves the brutal caps for one Hysteria2 outbound.
// measuredDownMbps is the download goodput of an explicit benchmark
// of this outbound through the tunnel, in Mbps; zero (or negative)
// means "no measurement available". userUpMbps is the user's stated
// upload tariff when the calibration should use it instead of the
// estimate (the plan's own UpMbps is a manual cap and wins earlier —
// see SourceManual — so this is for callers calibrating before a
// plan exists). The returned outbound is a copy; the input is never
// mutated.
func (c *BrutalCalibrator) Apply(o engine.Outbound, measuredDownMbps float64, userUpMbps int) (engine.Outbound, BrutalResult, error) {
	if o.Protocol != engine.ProtocolHysteria2 {
		return o, BrutalResult{Source: SourceNone}, nil
	}
	if o.UpMbps > 0 || o.DownMbps > 0 {
		return o, BrutalResult{Source: SourceManual, UpMbps: o.UpMbps, DownMbps: o.DownMbps}, nil
	}
	now := c.now()
	c.mu.Lock()
	entry, ok := c.cache[o.ID]
	c.mu.Unlock()
	if ok && now.Sub(entry.at) < CalibrationCooldown {
		out := o
		out.UpMbps, out.DownMbps = entry.up, entry.down
		return out, BrutalResult{Source: SourceCached, UpMbps: entry.up, DownMbps: entry.down, UpEstimated: entry.upEstimated, MeasuredAt: entry.at}, nil
	}
	if measuredDownMbps <= 0 {
		// No fresh measurement and nothing fresh in cache: refuse
		// honestly rather than degrading to invented caps.
		return o, BrutalResult{Source: SourceNone}, nil
	}
	up, down, estimated, err := CalibrateBrutal(measuredDownMbps, userUpMbps)
	if err != nil {
		return o, BrutalResult{Source: SourceNone}, fmt.Errorf("probe: brutal calibration for %s: %w", o.ID, err)
	}
	c.mu.Lock()
	c.cache[o.ID] = brutalEntry{up: up, down: down, upEstimated: estimated, at: now}
	c.mu.Unlock()
	out := o
	out.UpMbps, out.DownMbps = up, down
	return out, BrutalResult{Source: SourceMeasured, UpMbps: up, DownMbps: down, UpEstimated: estimated, MeasuredAt: now}, nil
}

// Forget drops one outbound's cached calibration (e.g. the server was
// edited or removed), so the next Apply needs a fresh measurement.
func (c *BrutalCalibrator) Forget(outboundID string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	delete(c.cache, outboundID)
}
