package censor

import (
	"testing"
	"time"
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

// tlsKillAttempt is the freeze's other face: killed right after the
// ClientHello, still with no server bytes.
func tlsKillAttempt(sni string, at time.Time) Attempt {
	start := at.Add(300 * time.Millisecond)
	return Attempt{
		ServerID:  "srv1",
		Target:    Target{Host: "203.0.113.7", Port: 443, SNI: sni, TLS: true, Protocol: "vless"},
		StartedAt: start,
		Events: []Event{
			{At: start, Stage: StageTCP, What: WhatConnected},
			{At: start.Add(50 * time.Millisecond), Stage: StageTLS, What: WhatSent, BytesOut: 600},
			{At: at, Stage: StageTLS, What: WhatRemoteReset},
		},
	}
}

func TestSiberianFreezeDetected(t *testing.T) {
	d := NewFreezeDetector()
	now := time.Now()
	sni := "dest.example.com"
	for i := 0; i < 3; i++ {
		d.Observe(tlsStallAttempt(sni, now.Add(time.Duration(i)*time.Second)))
	}
	a := d.Assess(Target{SNI: sni, TLS: true}, "chrome")
	if !a.Freeze {
		t.Fatal("expected freeze after 3 TLS stalls on one SNI")
	}
	// The freeze is hot: the only correct action is the backoff, not a
	// fingerprint rotation.
	if a.SuggestedFingerprint != "" {
		t.Fatalf("no fingerprint may be suggested during the hot freeze, got %q", a.SuggestedFingerprint)
	}
	if a.RetryAfter.IsZero() || time.Until(a.RetryAfter) < 119*time.Second {
		t.Fatalf("backoff must be >= 120s, got %v", time.Until(a.RetryAfter))
	}
	if until, ok := d.BackoffUntil(sni); !ok || time.Until(until) < 119*time.Second {
		t.Fatal("BackoffUntil must report the hot backoff")
	}
	if len(a.Evidence) == 0 || a.Explanation == "" {
		t.Fatal("assessment must carry evidence and an explanation")
	}
}

func TestSiberianRotationAfterBackoff(t *testing.T) {
	d := NewFreezeDetector()
	base := time.Now()
	d.now = func() time.Time { return base }
	sni := "dest.example.com"
	for i := 0; i < 3; i++ {
		d.Observe(tlsStallAttempt(sni, base.Add(time.Duration(i)*time.Second)))
	}
	if a := d.Assess(Target{SNI: sni, TLS: true}, "chrome"); a.SuggestedFingerprint != "" {
		t.Fatal("hot freeze must not suggest a fingerprint")
	}
	base = base.Add(3 * time.Minute)
	a := d.Assess(Target{SNI: sni, TLS: true}, "chrome")
	if a.SuggestedFingerprint != "firefox" {
		t.Fatalf("after the backoff the rotation should start at firefox, got %q", a.SuggestedFingerprint)
	}
	if a.RotateSNI || a.Failover {
		t.Fatal("3 failures should suggest only a fingerprint rotation, not SNI rotation or failover")
	}
	if _, ok := d.BackoffUntil(sni); ok {
		t.Fatal("backoff must have expired")
	}
}

func TestSiberianEscalationLadder(t *testing.T) {
	d := NewFreezeDetector()
	base := time.Now()
	d.now = func() time.Time { return base }
	advance := func(dt time.Duration) { base = base.Add(dt) }
	sni := "dest.example.com"
	// Six failures: the SNI itself looks burned.
	for i := 0; i < 6; i++ {
		d.Observe(tlsKillAttempt(sni, base.Add(time.Duration(i)*time.Second)))
	}
	advance(3 * time.Minute) // let the backoff expire so the ladder is visible
	a := d.Assess(Target{SNI: sni, TLS: true}, "firefox")
	if !a.Freeze || !a.RotateSNI {
		t.Fatal("6 failures should escalate to SNI rotation")
	}
	if a.Failover {
		t.Fatal("no rotation was applied yet: failover is premature")
	}
	// The session applies the suggested fingerprint twice; failures
	// continue anyway.
	d.NoteRotation(sni)
	for i := 6; i < 9; i++ {
		d.Observe(tlsStallAttempt(sni, base.Add(time.Duration(i)*time.Second)))
	}
	d.NoteRotation(sni)
	for i := 9; i < 12; i++ {
		d.Observe(tlsStallAttempt(sni, base.Add(time.Duration(i)*time.Second)))
	}
	advance(3 * time.Minute)
	a = d.Assess(Target{SNI: sni, TLS: true}, "edge")
	if !a.Failover {
		t.Fatal("two rotations without relief should escalate to failover")
	}
	if a.SuggestedFingerprint != "" {
		t.Fatal("failover assessment must not suggest another fingerprint")
	}
}

func TestSiberianNegativeCases(t *testing.T) {
	now := time.Now()
	t.Run("two failures are not enough", func(t *testing.T) {
		d := NewFreezeDetector()
		d.Observe(tlsStallAttempt("a.example", now))
		d.Observe(tlsStallAttempt("a.example", now.Add(time.Second)))
		if a := d.Assess(Target{SNI: "a.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("2 failures must not name a freeze")
		}
	})
	t.Run("TCP-stage failures are not a freeze", func(t *testing.T) {
		d := NewFreezeDetector()
		for i := 0; i < 4; i++ {
			at := now.Add(time.Duration(i) * time.Second)
			d.Observe(Attempt{
				ServerID:  "srv1",
				Target:    Target{Host: "203.0.113.7", Port: 443, SNI: "b.example", TLS: true},
				StartedAt: at.Add(-time.Second),
				Events: []Event{
					{At: at, Stage: StageTCP, What: WhatLocalTimeout, Detail: "timeout"},
				},
			})
		}
		if a := d.Assess(Target{SNI: "b.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("unanswered SYNs are IP filtering or a dead server, not a freeze")
		}
	})
	t.Run("success resets the track", func(t *testing.T) {
		d := NewFreezeDetector()
		for i := 0; i < 3; i++ {
			d.Observe(tlsStallAttempt("c.example", now.Add(time.Duration(i)*time.Second)))
		}
		d.ObserveSuccess(Target{SNI: "c.example", TLS: true})
		if a := d.Assess(Target{SNI: "c.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("a success after the failures means recovery, not a freeze")
		}
		if _, ok := d.BackoffUntil("c.example"); ok {
			t.Fatal("success must clear the backoff")
		}
	})
	t.Run("server bytes veto the freeze", func(t *testing.T) {
		d := NewFreezeDetector()
		for i := 0; i < 3; i++ {
			at := now.Add(time.Duration(i) * time.Second)
			a := tlsStallAttempt("d.example", at)
			a.Events[3].BytesIn = 1200 // the far end spoke: not a freeze
			d.Observe(a)
		}
		if a := d.Assess(Target{SNI: "d.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("failures with server bytes must not count as a freeze")
		}
	})
	t.Run("TLS alerts are the server's voice", func(t *testing.T) {
		d := NewFreezeDetector()
		for i := 0; i < 3; i++ {
			at := now.Add(time.Duration(i) * time.Second)
			d.Observe(Attempt{
				ServerID:  "srv1",
				Target:    Target{Host: "203.0.113.7", Port: 443, SNI: "e.example", TLS: true},
				StartedAt: at.Add(-time.Second),
				Events: []Event{
					{At: at, Stage: StageTLS, What: WhatTLSAlert, Detail: "handshake_failure"},
				},
			})
		}
		if a := d.Assess(Target{SNI: "e.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("TLS alerts must not feed the freeze verdict")
		}
	})
	t.Run("SNIs do not cross-contaminate", func(t *testing.T) {
		d := NewFreezeDetector()
		for i := 0; i < 2; i++ {
			d.Observe(tlsStallAttempt("f1.example", now.Add(time.Duration(i)*time.Second)))
			d.Observe(tlsStallAttempt("f2.example", now.Add(time.Duration(i)*time.Second)))
		}
		if a := d.Assess(Target{SNI: "f1.example", TLS: true}, "chrome"); a.Freeze {
			t.Fatal("failures spread across SNIs must not name a freeze")
		}
	})
	t.Run("SNI matching is case-insensitive", func(t *testing.T) {
		d := NewFreezeDetector()
		d.Observe(tlsStallAttempt("MiXeD.Example", now))
		d.Observe(tlsStallAttempt("mixed.example.", now.Add(time.Second)))
		d.Observe(tlsStallAttempt("MIXED.EXAMPLE", now.Add(2*time.Second)))
		if a := d.Assess(Target{SNI: "mixed.example", TLS: true}, "chrome"); !a.Freeze {
			t.Fatal("same SNI in different case must share one track")
		}
	})
}

func TestSiberianParallelEvidence(t *testing.T) {
	d := NewFreezeDetector()
	now := time.Now()
	sni := "g.example"
	// Four parallel handshakes: above the censor's trigger of 3.
	ends := make([]func(), 0, 4)
	for i := 0; i < 4; i++ {
		ends = append(ends, d.Begin(sni))
	}
	for i := 0; i < 3; i++ {
		d.Observe(tlsStallAttempt(sni, now.Add(time.Duration(i)*time.Second)))
	}
	for _, end := range ends {
		end()
	}
	a := d.Assess(Target{SNI: sni, TLS: true}, "chrome")
	if !a.Freeze {
		t.Fatal("expected freeze")
	}
	found := false
	for _, e := range a.Evidence {
		if len(e) >= 4 && e[:4] == "peak" {
			found = true
		}
	}
	if !found {
		t.Fatalf("expected parallel-handshake evidence, got %v", a.Evidence)
	}
}

func TestSiberianOtherSNIWorking(t *testing.T) {
	d := NewFreezeDetector()
	now := time.Now()
	for i := 0; i < 3; i++ {
		d.Observe(tlsStallAttempt("h1.example", now.Add(time.Duration(i)*time.Second)))
	}
	base := d.Assess(Target{SNI: "h1.example", TLS: true}, "chrome").Confidence
	d2 := NewFreezeDetector()
	for i := 0; i < 3; i++ {
		d2.Observe(tlsStallAttempt("h1.example", now.Add(time.Duration(i)*time.Second)))
	}
	d2.ObserveSuccess(Target{SNI: "other.example", TLS: true})
	boosted := d2.Assess(Target{SNI: "h1.example", TLS: true}, "chrome").Confidence
	if boosted <= base {
		t.Fatalf("a working other destination should raise confidence (%v -> %v)", base, boosted)
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
