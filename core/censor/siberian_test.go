package censor

import (
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/probe"
)

// tlsStallAttempt builds a failed attempt whose TLS handshake stalled with
// no server bytes: the canonical freeze observation.
func tlsStallAttempt(sni string, at time.Time) Attempt {
	start := at.Add(-2 * time.Second)
	return Attempt{
		ServerID:  "srv1",
		Target:    Target{Host: "203.0.113.7", Port: 443, SNI: sni, TLS: true, Protocol: "vless"},
		StartedAt: start,
		Events: []Event{
			{At: start, Stage: StageDNS, What: WhatResolved, Detail: "203.0.113.7"},
			{At: start.Add(100 * time.Millisecond), Stage: StageTCP, What: WhatConnected},
			{At: start.Add(150 * time.Millisecond), Stage: StageTLS, What: WhatSent, BytesOut: 600},
			{At: at, Stage: StageTLS, What: WhatLocalTimeout, Detail: "timeout"},
		},
	}
}

// freezeDetWithClock returns a probe.FreezeDetector whose Now is pinned to
// base (advanced by the caller), so sample windows are deterministic.
func freezeDetWithClock(base *time.Time) *probe.FreezeDetector {
	return &probe.FreezeDetector{Now: func() time.Time { return *base }}
}

// feedDifferential feeds the recognizer's own signature: stalled parallel
// handshakes (concurrency above the freeze threshold) plus sequential
// successes proving the endpoint is alive.
func feedDifferential(det *probe.FreezeDetector, sni string, stalled, seqOK int, at time.Time) {
	for i := 0; i < stalled; i++ {
		det.Observe(probe.FreezeSample{SNI: sni, Concurrent: 4, Stalled: true, At: at})
	}
	for i := 0; i < seqOK; i++ {
		det.Observe(probe.FreezeSample{SNI: sni, Concurrent: 1, Stalled: false, At: at})
	}
}

// newPolicy wires a FreezePolicy to a fresh recognizer sharing the base
// clock. nowPtr lets tests advance both clocks together.
func newPolicy(t *testing.T, base time.Time) (*FreezePolicy, *probe.FreezeDetector, *time.Time) {
	t.Helper()
	b := base
	det := freezeDetWithClock(&b)
	p := NewFreezePolicy(det)
	p.now = func() time.Time { return b }
	return p, det, &b
}

func TestSiberianFreezeDetected(t *testing.T) {
	now := time.Now()
	p, det, _ := newPolicy(t, now)
	sni := "dest.example.com"
	feedDifferential(det, sni, 2, 1, now)
	a := p.Assess(Target{SNI: sni, TLS: true}, "chrome")
	if !a.Freeze {
		t.Fatal("expected freeze after the differential pattern on one SNI")
	}
	// The freeze is hot: the only correct action is the backoff, not a
	// fingerprint rotation.
	if a.SuggestedFingerprint != "" {
		t.Fatalf("no fingerprint may be suggested during the hot freeze, got %q", a.SuggestedFingerprint)
	}
	if a.RetryAfter.IsZero() || time.Until(a.RetryAfter) < 119*time.Second {
		t.Fatalf("backoff must be >= 120s, got %v", time.Until(a.RetryAfter))
	}
	if until, ok := p.BackoffUntil(sni); !ok || time.Until(until) < 119*time.Second {
		t.Fatal("BackoffUntil must report the hot backoff")
	}
	if len(a.Evidence) == 0 || a.Explanation == "" {
		t.Fatal("assessment must carry evidence and an explanation")
	}
	if a.Confidence <= 0 || a.Confidence > 0.85 {
		t.Fatalf("confidence = %v, must be within (0, 0.85]", a.Confidence)
	}
}

func TestSiberianRotationAfterBackoff(t *testing.T) {
	base := time.Now()
	p, det, clock := newPolicy(t, base)
	sni := "dest.example.com"
	feedDifferential(det, sni, 2, 1, base)
	if a := p.Assess(Target{SNI: sni, TLS: true}, "chrome"); a.SuggestedFingerprint != "" {
		t.Fatal("hot freeze must not suggest a fingerprint")
	}
	*clock = base.Add(3 * time.Minute)
	a := p.Assess(Target{SNI: sni, TLS: true}, "chrome")
	if a.SuggestedFingerprint != "firefox" {
		t.Fatalf("after the backoff the rotation should start at firefox, got %q", a.SuggestedFingerprint)
	}
	if a.RotateSNI || a.Failover {
		t.Fatal("2 stalled parallels should suggest only a fingerprint rotation, not SNI rotation or failover")
	}
	if _, ok := p.BackoffUntil(sni); ok {
		t.Fatal("backoff must have expired")
	}
}

func TestSiberianEscalationLadder(t *testing.T) {
	base := time.Now()
	p, det, clock := newPolicy(t, base)
	sni := "dest.example.com"
	// Six stalled parallels: the SNI itself looks burned.
	feedDifferential(det, sni, 6, 1, base)
	*clock = base.Add(3 * time.Minute) // let the backoff expire so the ladder is visible
	a := p.Assess(Target{SNI: sni, TLS: true}, "firefox")
	if !a.Freeze || !a.RotateSNI {
		t.Fatal("6 stalled parallels should escalate to SNI rotation")
	}
	if a.Failover {
		t.Fatal("no rotation was applied yet: failover is premature")
	}
	// The session applies the suggested fingerprint twice; failures
	// continue anyway.
	p.NoteRotation(sni)
	feedDifferential(det, sni, 3, 1, *clock)
	p.NoteRotation(sni)
	feedDifferential(det, sni, 3, 1, *clock)
	*clock = base.Add(6 * time.Minute)
	a = p.Assess(Target{SNI: sni, TLS: true}, "edge")
	if !a.Failover {
		t.Fatal("two rotations without relief should escalate to failover")
	}
	if a.SuggestedFingerprint != "" {
		t.Fatal("failover assessment must not suggest another fingerprint")
	}
}

func TestSiberianNegativeCases(t *testing.T) {
	now := time.Now()
	t.Run("parallel stalls without a sequential success are a dead endpoint", func(t *testing.T) {
		p, det, _ := newPolicy(t, now)
		feedDifferential(det, "a.example", 2, 0, now)
		if a := p.Assess(Target{SNI: "a.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("no sequential success means the endpoint may be dead, not frozen")
		}
	})
	t.Run("sequential stalls alone never name a freeze", func(t *testing.T) {
		p, _, _ := newPolicy(t, now)
		for i := 0; i < 6; i++ {
			p.ObserveAttempt(tlsStallAttempt("b.example", now.Add(time.Duration(i)*time.Second)))
		}
		if a := p.Assess(Target{SNI: "b.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("sequential stalls are the control group, not the freeze signature")
		}
	})
	t.Run("a lifted freeze clears the policy bookkeeping", func(t *testing.T) {
		base := now
		p, det, clock := newPolicy(t, base)
		feedDifferential(det, "c.example", 2, 1, base)
		if a := p.Assess(Target{SNI: "c.example", TLS: true}, "chrome"); !a.Freeze {
			t.Fatal("setup: expected freeze")
		}
		*clock = base.Add(31 * time.Minute) // past the sample TTL: the evidence is gone
		if a := p.Assess(Target{SNI: "c.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("expired evidence must not keep the freeze named")
		}
		if _, ok := p.BackoffUntil("c.example"); ok {
			t.Fatal("a lifted freeze must clear the backoff")
		}
	})
	t.Run("server bytes veto the freeze", func(t *testing.T) {
		p, _, _ := newPolicy(t, now)
		for i := 0; i < 6; i++ {
			at := now.Add(time.Duration(i) * time.Second)
			a := tlsStallAttempt("d.example", at)
			a.Events[3].BytesIn = 1200 // the far end spoke: not a freeze
			p.ObserveAttempt(a)
		}
		if a := p.Assess(Target{SNI: "d.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("failures with server bytes must not count as freeze evidence")
		}
	})
	t.Run("TLS alerts are the server's voice", func(t *testing.T) {
		p, _, _ := newPolicy(t, now)
		for i := 0; i < 6; i++ {
			at := now.Add(time.Duration(i) * time.Second)
			p.ObserveAttempt(Attempt{
				ServerID:  "srv1",
				Target:    Target{Host: "203.0.113.7", Port: 443, SNI: "e.example", TLS: true},
				StartedAt: at.Add(-time.Second),
				Events: []Event{
					{At: at, Stage: StageTLS, What: WhatTLSAlert, Detail: "handshake_failure"},
				},
			})
		}
		if a := p.Assess(Target{SNI: "e.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("TLS alerts must not feed the freeze verdict")
		}
	})
	t.Run("kills after ClientHello are the SNI-blocking signature, not a freeze", func(t *testing.T) {
		p, _, _ := newPolicy(t, now)
		for i := 0; i < 6; i++ {
			at := now.Add(time.Duration(i) * time.Second)
			start := at.Add(-300 * time.Millisecond)
			p.ObserveAttempt(Attempt{
				ServerID:  "srv1",
				Target:    Target{Host: "203.0.113.7", Port: 443, SNI: "k.example", TLS: true},
				StartedAt: start,
				Events: []Event{
					{At: start, Stage: StageTCP, What: WhatConnected},
					{At: start.Add(50 * time.Millisecond), Stage: StageTLS, What: WhatSent, BytesOut: 600},
					{At: at, Stage: StageTLS, What: WhatRemoteReset},
				},
			})
		}
		if a := p.Assess(Target{SNI: "k.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("fast kills belong to SNI-blocking; only stalls are freeze evidence")
		}
	})
	t.Run("SNIs do not cross-contaminate", func(t *testing.T) {
		p, det, _ := newPolicy(t, now)
		feedDifferential(det, "f1.example", 2, 0, now)
		feedDifferential(det, "f2.example", 2, 0, now)
		if a := p.Assess(Target{SNI: "f1.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("failures spread across SNIs must not name a freeze")
		}
	})
	t.Run("SNI matching is case-insensitive", func(t *testing.T) {
		p, det, _ := newPolicy(t, now)
		feedDifferential(det, "MiXeD.Example", 2, 1, now)
		if a := p.Assess(Target{SNI: "mixed.example", TLS: true}, "chrome"); !a.Freeze {
			t.Fatal("same SNI in different case must share one track")
		}
	})
	t.Run("nil detector never fires", func(t *testing.T) {
		p := NewFreezePolicy(nil)
		if a := p.Assess(Target{SNI: "x.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("fail-closed: no recognizer means no freeze claim")
		}
		p.ObserveAttempt(tlsStallAttempt("x.example", now)) // must not panic
	})
}

func TestSiberianOtherSNIWorking(t *testing.T) {
	base := time.Now()
	p, det, _ := newPolicy(t, base)
	// One sequential success elsewhere plus the differential on h1: the
	// differential carries the verdict; the point here is only that the
	// policy does not crash on multi-SNI state.
	feedDifferential(det, "h1.example", 2, 1, base)
	det.Observe(probe.FreezeSample{SNI: "other.example", Concurrent: 1, At: base})
	a := p.Assess(Target{SNI: "h1.example", TLS: true}, "chrome")
	if !a.Freeze || len(a.Evidence) == 0 {
		t.Fatalf("expected freeze with evidence, got %+v", a)
	}
}

func TestNextSiberianFingerprint(t *testing.T) {
	cases := []struct {
		current string
		next    string
		ok      bool
	}{
		{"", "firefox", true},
		{"chrome", "firefox", true},
		{"safari", "firefox", true},
		{"ios", "firefox", true},
		{" Chrome ", "firefox", true},
		{"firefox", "edge", true},
		{"edge", "qq", true},
		{"qq", "android", true},
		{"android", "", false},
		{"nonsense", "firefox", true},
	}
	for _, c := range cases {
		next, ok := NextSiberianFingerprint(c.current)
		if next != c.next || ok != c.ok {
			t.Fatalf("NextSiberianFingerprint(%q) = (%q, %v), want (%q, %v)",
				c.current, next, ok, c.next, c.ok)
		}
	}
}

// TestSiberianRotationListIsSingleSourced pins the unification: the
// censor policy reads exactly the probe's rotation list, so the two
// layers can never contradict each other on which fingerprints are safe.
func TestSiberianRotationListIsSingleSourced(t *testing.T) {
	want := probe.FreezeFingerprintRotation()
	if len(siberianRotation) != len(want) {
		t.Fatalf("siberianRotation = %v, probe list = %v", siberianRotation, want)
	}
	for i := range want {
		if siberianRotation[i] != want[i] {
			t.Fatalf("siberianRotation = %v, probe list = %v", siberianRotation, want)
		}
	}
}
