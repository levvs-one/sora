package censor

import (
	"strconv"
	"strings"
	"sync"
	"time"
)

// Whitelist vs full-shutdown classification (T047).
//
// The October 2026 field reality: mobile shutdowns are now routine — the
// internet is switched off region by region — and the "socially
// significant" allow-list registry grew from 57 to 100+ services. Two very
// different network states hide behind "nothing works":
//
//   - WHITELIST (default-deny at the operator): allow-listed destinations
//     pass; everything else dies at the ~16 KB cutoff. The working shape is
//     VLESS+REALITY over XHTTP on TCP/443 with a valid SNI (T004), so the
//     answer is a strategy change, not a retry storm.
//   - FULL SHUTDOWN (segment shutdown): nothing passes at all — not even
//     allow-listed destinations. No protocol, no desync trick, no retry
//     helps; the honest UX is dead-mode (T029/T048): say the network is
//     down and stop hammering it.
//
// The old T004 detector could only name the first. This detector feeds on
// the same DIRECT-path attempts as the whitelist detector (the feeding
// contract is identical: direct path only, one success disproves) and
// adds the hard-down tally: ≥3 distinct destinations failing at TCP/DNS
// with zero successes in the window names a shutdown; the ~16 KB cutoff
// signature names the whitelist. Both verdicts carry an explicit
// confidence and a user-facing explanation; both are "no claim" until the
// evidence bar is met.
//
// Honesty limits, stated in the assessment text: the classifier cannot
// prove the difference between a national shutdown and a local network
// outage (both look like "everything is down") — the verdict says
// "shutdown OR outage" and the UX must not blame the censor for a dead
// Wi-Fi router. It is process-local memory only, like the detectors it
// wraps.
const (
	// shutdownWindow bounds the detector's memory; matches the whitelist
	// detector's window so the two verdicts read off the same evidence.
	shutdownWindow = 10 * time.Minute
	// shutdownMinDests is the evidence bar: distinct hard-down
	// destinations before "everything is down" is claimed.
	shutdownMinDests = 3
)

// PathMode names the classified state of the direct path.
type PathMode int

const (
	// PathNormal means no evidence of a default-deny network.
	PathNormal PathMode = iota
	// PathWhitelist means the operator runs a default-deny whitelist:
	// allow-listed destinations pass, the rest die at ~16 KB.
	PathWhitelist
	// PathShutdown means the segment looks fully down: nothing passes,
	// not even names known to work. Shutdown or local outage — the
	// classifier cannot tell which, and says so.
	PathShutdown
)

// String renders the mode for logs and UI.
func (m PathMode) String() string {
	switch m {
	case PathWhitelist:
		return "whitelist"
	case PathShutdown:
		return "shutdown"
	default:
		return "normal"
	}
}

// ShutdownAssessment is the classifier's answer.
type ShutdownAssessment struct {
	// Mode is the classified state of the direct path.
	Mode PathMode
	// Confidence is 0..1 for Mode != PathNormal; meaningless otherwise.
	Confidence float64
	// Strategy is set when Mode == PathWhitelist: the T004 prescription.
	Strategy WhitelistStrategy
	// DistinctDests counts the destinations behind the verdict.
	DistinctDests int
	// Evidence lists the observations the assessment rests on.
	Evidence []string
	// Explanation is the user-facing account, honest about what cannot be
	// proven (shutdown vs local outage).
	Explanation string
}

// ShutdownDetector distinguishes whitelist mode from a full segment
// shutdown from DIRECT-path attempts. It wraps the T004 whitelist
// detector and adds the hard-down tally. Production status (2026-10-20):
// WIRED — one instance lives on the session Manager; the censorship
// failure watcher feeds it every direct-path probe and publishes its
// network-mode verdicts to the session journal (skipping the T042
// expedite hook on purpose: under a whitelist or a shutdown, refreshing
// subscriptions is not a strategy). The feeding contract in whitelist.go
// applies unchanged.
type ShutdownDetector struct {
	mu      sync.Mutex
	wl      *WhitelistDetector
	down    map[string]time.Time // normalized host -> last hard-down
	success time.Time             // last direct success
	now     func() time.Time
}

// NewShutdownDetector returns a detector with default tuning.
func NewShutdownDetector() *ShutdownDetector {
	return &ShutdownDetector{
		wl:   NewWhitelistDetector(),
		down: map[string]time.Time{},
		now:  time.Now,
	}
}

func normalizeHost(h string) string {
	return strings.ToLower(strings.TrimSuffix(strings.TrimSpace(h), "."))
}

// isHardDown reports whether the attempt is a "nothing got through"
// outcome at the TCP/DNS layer: our SYN died silently, the host was
// unreachable, or a name known to work stopped resolving. A refusal, a
// RST, or a TLS alert is the path ANSWERING — that is evidence the
// network is up, not down.
func isHardDown(a Attempt) bool {
	if a.Target.Host == "" {
		return false
	}
	var sawConnected, sawAnswer bool
	for _, e := range a.Events {
		switch e.Stage {
		case StageTCP:
			switch e.What {
			case WhatConnected:
				sawConnected = true
			case WhatLocalTimeout:
				// Silence at TCP: keep looking, it may still be a
				// targeted block — the tally needs company.
			case WhatRemoteReset, WhatRemoteClose:
				sawAnswer = true
			case WhatError:
				if strings.Contains(strings.ToLower(e.Detail), "unreachable") {
					return !sawConnected && !sawAnswer
				}
			}
		case StageDNS:
			if e.What == WhatError && a.KnownGoodHost {
				// A name that used to resolve stopped resolving: the
				// resolver itself is gone, not the name.
				return !sawConnected && !sawAnswer
			}
		case StageTLS:
			if e.What == WhatTLSAlert || e.What == WhatRemoteReset {
				sawAnswer = true
			}
		}
	}
	// TCP silence with no answer from anyone: hard down at the path.
	if !sawConnected && !sawAnswer {
		for _, e := range a.Events {
			if e.Stage == StageTCP && e.What == WhatLocalTimeout {
				return true
			}
		}
	}
	return false
}

// isPathAlive reports whether the attempt proves the direct path works:
// a completed TCP connect, or a refusal/RST (the far end or the path
// answered).
func isPathAlive(a Attempt) bool {
	for _, e := range a.Events {
		if e.Stage == StageTCP && e.What == WhatConnected {
			return true
		}
		if e.What == WhatRemoteReset || e.What == WhatRemoteClose {
			return true
		}
		if e.Stage == StageTCP && e.What == WhatError &&
			strings.Contains(strings.ToLower(e.Detail), "refused") {
			return true
		}
	}
	return false
}

// isCutoffStall reports whether the attempt carries the whitelist ~16 KB
// cutoff signature (the whitelist detector's own predicate). Such an
// attempt connected fine — which is exactly why it must NOT count as a
// path success: the pipeline let it in and then cut it.
func isCutoffStall(a Attempt) bool {
	t, sawBytesIn := terminalScan(a)
	if t == nil || t.What != WhatLocalTimeout {
		return false
	}
	if t.BytesOut < whitelistCutoffLo || t.BytesOut > whitelistCutoffHi {
		return false
	}
	return !sawBytesIn && t.BytesIn <= whitelistMaxInbound
}

// Observe records one finished DIRECT-path attempt.
func (d *ShutdownDetector) Observe(a Attempt) {
	d.wl.Observe(a) // the cutoff signature feeds the whitelist verdict
	if a.Target.Host == "" {
		return
	}
	if isPathAlive(a) && !isCutoffStall(a) {
		d.ObserveSuccess(a.Target)
		return
	}
	if !isHardDown(a) {
		return
	}
	host := normalizeHost(a.Target.Host)
	d.mu.Lock()
	defer d.mu.Unlock()
	now := d.now()
	d.pruneLocked(now)
	d.down[host] = now
}

// ObserveSuccess records a working DIRECT-path connection. One success
// disproves both whitelist and shutdown: the path passes arbitrary
// traffic.
func (d *ShutdownDetector) ObserveSuccess(t Target) {
	d.wl.ObserveSuccess(t)
	d.mu.Lock()
	defer d.mu.Unlock()
	now := d.now()
	d.pruneLocked(now)
	d.success = now
	d.down = map[string]time.Time{}
}

func (d *ShutdownDetector) pruneLocked(now time.Time) {
	cutoff := now.Add(-shutdownWindow)
	for host, at := range d.down {
		if at.Before(cutoff) {
			delete(d.down, host)
		}
	}
	if d.success.Before(cutoff) {
		d.success = time.Time{}
	}
}

// Assess classifies the direct path. The whitelist verdict wins on a tie
// only when its own evidence bar is met; otherwise the hard-down tally is
// read: several distinct destinations down and nothing working means the
// segment is gone, not the servers.
func (d *ShutdownDetector) Assess() ShutdownAssessment {
	if wa := d.wl.Assess(); wa.WhitelistMode {
		return ShutdownAssessment{
			Mode:          PathWhitelist,
			Confidence:    wa.Confidence,
			Strategy:      wa.Strategy,
			DistinctDests: wa.DistinctDests,
			Evidence:      wa.Evidence,
			Explanation: "Your network allows only pre-approved destinations (default-deny whitelist). " +
				"The working shape here is TCP/443 to a valid allow-listed name with VLESS+REALITY — " +
				"retrying other servers or tricks will not pass.",
		}
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	now := d.now()
	d.pruneLocked(now)
	n := len(d.down)
	if n < shutdownMinDests || !d.success.IsZero() {
		return ShutdownAssessment{Mode: PathNormal}
	}
	conf := 0.6 + 0.05*float64(n-shutdownMinDests)
	if conf > 0.85 {
		conf = 0.85
	}
	return ShutdownAssessment{
		Mode:          PathShutdown,
		Confidence:    conf,
		DistinctDests: n,
		Evidence: []string{
			strconv.Itoa(n) + " different destinations failed at the TCP/DNS layer with nothing answering in the last 10 minutes",
			"no direct connection succeeded in the same window",
		},
		Explanation: "Nothing reaches the network at all: " + strconv.Itoa(n) +
			" different destinations failed and none worked. This looks like a full shutdown of the " +
			"network segment (or a local outage — the client cannot tell those apart). No protocol or " +
			"server change helps until connectivity returns; retrying would only hammer a dead path.",
	}
}
