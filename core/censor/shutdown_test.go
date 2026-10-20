package censor

import (
	"strings"
	"testing"
	"time"
)

// tcpTimeoutAttempt builds a direct attempt whose SYN died silently.
func tcpTimeoutAttempt(host string) Attempt {
	now := time.Now()
	return Attempt{
		Target:    Target{Host: host, Port: 443},
		StartedAt: now,
		Events: []Event{
			{At: now, Stage: StageDNS, What: WhatResolved, Detail: "203.0.113.9"},
			{At: now.Add(time.Second), Stage: StageTCP, What: WhatLocalTimeout},
		},
	}
}

// cutoffStallAttempt builds the whitelist ~16 KB cutoff signature.
func cutoffStallAttempt(host string) Attempt {
	now := time.Now()
	return Attempt{
		Target:    Target{Host: host, Port: 443},
		StartedAt: now,
		Events: []Event{
			{At: now, Stage: StageDNS, What: WhatResolved, Detail: "203.0.113.9"},
			{At: now.Add(100 * time.Millisecond), Stage: StageTCP, What: WhatConnected},
			{At: now.Add(time.Second), Stage: StageApp, What: WhatLocalTimeout,
				BytesOut: 16101, BytesIn: 0},
		},
	}
}

func TestShutdownFullSegment(t *testing.T) {
	d := NewShutdownDetector()
	for _, h := range []string{"a.example.com", "b.example.com", "c.example.com"} {
		d.Observe(tcpTimeoutAttempt(h))
	}
	a := d.Assess()
	if a.Mode != PathShutdown {
		t.Fatalf("Mode = %v, want shutdown (%+v)", a.Mode, a)
	}
	if !strings.Contains(a.Explanation, "local outage") {
		t.Fatalf("shutdown verdict must confess it cannot rule out a local outage: %q", a.Explanation)
	}
}

func TestShutdownWhitelistWins(t *testing.T) {
	d := NewShutdownDetector()
	for _, h := range []string{"a.example.com", "b.example.com", "c.example.com"} {
		d.Observe(cutoffStallAttempt(h))
	}
	a := d.Assess()
	if a.Mode != PathWhitelist {
		t.Fatalf("Mode = %v, want whitelist", a.Mode)
	}
	if !a.Strategy.TCP443First || !a.Strategy.ValidSNIOnly {
		t.Fatalf("whitelist verdict must carry the T004 strategy, got %+v", a.Strategy)
	}
}

func TestShutdownBelowBarIsNormal(t *testing.T) {
	d := NewShutdownDetector()
	d.Observe(tcpTimeoutAttempt("a.example.com"))
	d.Observe(tcpTimeoutAttempt("b.example.com"))
	if a := d.Assess(); a.Mode != PathNormal {
		t.Fatalf("two dead destinations are not a shutdown, got %v", a.Mode)
	}
}

func TestShutdownRefusalIsPathAlive(t *testing.T) {
	d := NewShutdownDetector()
	now := time.Now()
	refused := Attempt{
		Target:    Target{Host: "alive.example.com", Port: 443},
		StartedAt: now,
		Events: []Event{
			{At: now, Stage: StageDNS, What: WhatResolved, Detail: "203.0.113.9"},
			{At: now, Stage: StageTCP, What: WhatError, Detail: "refused"},
		},
	}
	d.Observe(tcpTimeoutAttempt("a.example.com"))
	d.Observe(tcpTimeoutAttempt("b.example.com"))
	d.Observe(tcpTimeoutAttempt("c.example.com"))
	d.Observe(refused)
	if a := d.Assess(); a.Mode != PathNormal {
		t.Fatalf("a refusal proves the path answers: Mode = %v, want normal", a.Mode)
	}
}

func TestShutdownKnownGoodDNSFailureCounts(t *testing.T) {
	d := NewShutdownDetector()
	now := time.Now()
	dnsDead := func(host string) Attempt {
		return Attempt{
			Target:        Target{Host: host, Port: 443},
			KnownGoodHost: true,
			StartedAt:     now,
			Events: []Event{
				{At: now, Stage: StageDNS, What: WhatError, Detail: "resolve failed: server misbehaving"},
			},
		}
	}
	d.Observe(dnsDead("a.example.com"))
	d.Observe(dnsDead("b.example.com"))
	d.Observe(dnsDead("c.example.com"))
	if a := d.Assess(); a.Mode != PathShutdown {
		t.Fatalf("Mode = %v, want shutdown", a.Mode)
	}
}

func TestShutdownUnknownHostDNSFailureDoesNotCount(t *testing.T) {
	d := NewShutdownDetector()
	now := time.Now()
	nx := func(host string) Attempt {
		return Attempt{
			Target:    Target{Host: host, Port: 443},
			StartedAt: now,
			Events: []Event{
				{At: now, Stage: StageDNS, What: WhatError, Detail: "nxdomain"},
			},
		}
	}
	d.Observe(nx("a.example.com"))
	d.Observe(nx("b.example.com"))
	d.Observe(nx("c.example.com"))
	if a := d.Assess(); a.Mode != PathNormal {
		t.Fatalf("NXDOMAIN for unknown hosts is not a shutdown signature, got %v", a.Mode)
	}
}

func TestShutdownWindowExpiry(t *testing.T) {
	d := NewShutdownDetector()
	base := time.Now()
	now := base
	d.now = func() time.Time { return now }
	for _, h := range []string{"a.example.com", "b.example.com", "c.example.com"} {
		a := tcpTimeoutAttempt(h)
		a.StartedAt = base
		d.Observe(a)
	}
	now = base.Add(2 * shutdownWindow)
	if a := d.Assess(); a.Mode != PathNormal {
		t.Fatalf("stale evidence must expire, got %v", a.Mode)
	}
}
