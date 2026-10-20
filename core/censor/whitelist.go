package censor

import (
	"strconv"
	"strings"
	"sync"
	"time"
)

// Whitelist-mode (default-deny) runtime detector.
//
// T004: on some mobile networks the censor runs a default-deny whitelist —
// only ~63k allow-listed addresses pass; everything else is dropped by an
// L3+L7 pipeline with a characteristic ~16 KB cutoff (16101 bytes observed,
// P44). No desync trick passes it: the packets are simply never delivered.
// The only working shape the field reports is VLESS+REALITY over XHTTP on
// TCP/443 with a valid (allow-listed) SNI.
//
// The client-observable signature is differential and narrow: connections
// to *arbitrary* destinations stall after roughly 16 KB outbound with
// nothing coming back, across several distinct destinations, while no
// direct connection succeeds. One working direct destination disproves the
// mode — that is targeted blocking, not default-deny.
//
// Feeding rules (the session layer must honor these, or the verdict is
// meaningless):
//   - feed only DIRECT-path attempts (no tunnel, no proxy). A stall inside
//     the VPN tunnel is not path evidence.
//   - feed direct successes via ObserveSuccess: a single success to an
//     arbitrary destination clears the verdict.
//
// The detector names the strategy, not just the mode: TCP/443-first,
// valid-SNI-only (from the allow-listed registry / SNIPool), SNI rotation.
// Applying it is the control plane's job.
const (
	// whitelistWindow bounds the detector's memory.
	whitelistWindow = 10 * time.Minute
	// whitelistMinDests is the evidence bar: this many distinct
	// destinations stalled at the cutoff.
	whitelistMinDests = 3
	// whitelistCutoffLo/Hi bracket the observed 16101-byte pipeline
	// cutoff. The range is honest: the exact number varies by operator
	// and measurement, the signature is "stall right after ~16 KB".
	whitelistCutoffLo = 14000
	whitelistCutoffHi = 18000
	// whitelistMaxInbound caps the "silent" in the silent drop: if the
	// far end sent real data before the stall, something else happened.
	whitelistMaxInbound = 2048
)

// WhitelistStrategy is the recommended shape of connections under
// default-deny: the T004 prescription.
type WhitelistStrategy struct {
	// TCP443First: open TCP/443 before anything else; other ports and UDP
	// are dead in whitelist mode.
	TCP443First bool
	// ValidSNIOnly: use only SNIs known to be on the allow-list (the
	// registry / SNIPool of validated dests). Arbitrary SNIs never pass.
	ValidSNIOnly bool
	// RotateSNI: rotate the valid SNIs over time; a single SNI burned
	// into the (subnet, SNI) triple can still be frozen.
	RotateSNI bool
}

// WhitelistAssessment is the detector's answer.
type WhitelistAssessment struct {
	// WhitelistMode reports that the path looks default-deny.
	WhitelistMode bool
	// Confidence is 0..1 for WhitelistMode=true; meaningless otherwise.
	Confidence float64
	// Strategy is set when WhitelistMode is true.
	Strategy WhitelistStrategy
	// DistinctDests counts the stalled destinations behind the verdict.
	DistinctDests int
	// Evidence lists the observations the assessment rests on.
	Evidence []string
	// Explanation is the user-facing account.
	Explanation string
}

type whitelistMark struct {
	at time.Time
}

// WhitelistDetector tracks direct-path stalls at the ~16 KB cutoff.
//
// Production status (2026-10-20): NOT WIRED. Nothing feeds it (the
// feeding rules above describe the session-layer contract, which no
// production code honors yet) and nothing consumes its
// WhitelistAssessment: the strategy it names (TCP/443-first, valid-SNI,
// SNI rotation) would have to be applied by the control plane, which
// has no such hook today. Kept for its unit tests and the designed
// policy; wiring it end-to-end is an owner decision (SW4 tier 2).
type WhitelistDetector struct {
	mu      sync.Mutex
	stalled map[string]whitelistMark // normalized host -> last cutoff stall
	success time.Time                // last direct success
	now     func() time.Time
}

// NewWhitelistDetector returns a detector with default tuning.
func NewWhitelistDetector() *WhitelistDetector {
	return &WhitelistDetector{stalled: map[string]whitelistMark{}, now: time.Now}
}

func (d *WhitelistDetector) prune(now time.Time) {
	cutoff := now.Add(-whitelistWindow)
	for host, m := range d.stalled {
		if m.at.Before(cutoff) {
			delete(d.stalled, host)
		}
	}
	if d.success.Before(cutoff) {
		d.success = time.Time{}
	}
}

// Observe records one finished DIRECT-path attempt. Only the cutoff
// signature counts: ~16 KB went out, (almost) nothing came back, then our
// own deadline expired. Anything else — refused SYNs, DNS lies, early
// resets — is somebody else's problem.
func (d *WhitelistDetector) Observe(a Attempt) {
	if a.Target.Host == "" {
		return
	}
	t, sawBytesIn := terminalScan(a)
	if t == nil || t.What != WhatLocalTimeout {
		return
	}
	if t.BytesOut < whitelistCutoffLo || t.BytesOut > whitelistCutoffHi {
		return
	}
	if sawBytesIn || t.BytesIn > whitelistMaxInbound {
		return
	}
	host := strings.ToLower(strings.TrimSuffix(strings.TrimSpace(a.Target.Host), "."))
	d.mu.Lock()
	defer d.mu.Unlock()
	now := d.now()
	d.prune(now)
	d.stalled[host] = whitelistMark{at: now}
}

// ObserveSuccess records a working DIRECT-path connection. One success to
// an arbitrary destination disproves default-deny: the path passes
// non-allow-listed traffic.
func (d *WhitelistDetector) ObserveSuccess(t Target) {
	d.mu.Lock()
	defer d.mu.Unlock()
	now := d.now()
	d.prune(now)
	d.success = now
	d.stalled = map[string]whitelistMark{}
}

// Assess answers whether the path looks default-deny.
func (d *WhitelistDetector) Assess() WhitelistAssessment {
	d.mu.Lock()
	defer d.mu.Unlock()
	now := d.now()
	d.prune(now)
	n := len(d.stalled)
	if n < whitelistMinDests {
		return WhitelistAssessment{}
	}
	if !d.success.IsZero() {
		// A direct success inside the window disproves the mode. (Older
		// successes were pruned.)
		return WhitelistAssessment{}
	}
	conf := 0.55 + 0.05*float64(n-whitelistMinDests)
	if conf > 0.8 {
		conf = 0.8
	}
	return WhitelistAssessment{
		WhitelistMode: true,
		Confidence:    conf,
		Strategy:      WhitelistStrategy{TCP443First: true, ValidSNIOnly: true, RotateSNI: true},
		DistinctDests: n,
		Evidence: []string{
			strconv.Itoa(n) + " different destinations stalled right after ~16 KB with no response in the last 10 minutes",
			"the ~16 KB cutoff matches the whitelist pipeline's 16101-byte signature; no desync technique passes it",
		},
		Explanation: "Your network appears to allow only pre-approved destinations (default-deny whitelist): connections to anything else are silently dropped after about 16 KB. The working shape here is a valid allow-listed destination name over TCP/443 — arbitrary servers and tricks will not pass.",
	}
}
