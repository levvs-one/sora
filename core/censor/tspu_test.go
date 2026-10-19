package censor

import (
	"context"
	"sync"
	"testing"
	"time"
)

// cutoffStall builds a direct-path attempt that stalled after ~16 KB out
// with nothing back: the whitelist signature.
func cutoffStall(host string, at time.Time) Attempt {
	start := at.Add(-30 * time.Second)
	return Attempt{
		ServerID:  "direct",
		Target:    Target{Host: host, Port: 443, TLS: true},
		StartedAt: start,
		Events: []Event{
			{At: start, Stage: StageTCP, What: WhatConnected},
			{At: start.Add(time.Second), Stage: StageTLS, What: WhatSent, BytesOut: 1200},
			{At: start.Add(2 * time.Second), Stage: StageData, What: WhatSent, BytesOut: 16101},
			{At: at, Stage: StageData, What: WhatLocalTimeout, BytesOut: 16101, Detail: "timeout"},
		},
	}
}

func TestWhitelistDetected(t *testing.T) {
	d := NewWhitelistDetector()
	now := time.Now()
	for i, h := range []string{"a.example", "b.example", "c.example"} {
		d.Observe(cutoffStall(h, now.Add(time.Duration(i)*time.Second)))
	}
	a := d.Assess()
	if !a.WhitelistMode {
		t.Fatal("expected whitelist mode after 3 cutoff stalls to distinct dests")
	}
	if a.DistinctDests != 3 {
		t.Fatalf("expected 3 distinct dests, got %d", a.DistinctDests)
	}
	if !a.Strategy.TCP443First || !a.Strategy.ValidSNIOnly || !a.Strategy.RotateSNI {
		t.Fatalf("strategy must be TCP/443-first + valid-SNI-only + rotate, got %+v", a.Strategy)
	}
	if len(a.Evidence) == 0 || a.Explanation == "" {
		t.Fatal("assessment must carry evidence and an explanation")
	}
}

func TestWhitelistNegativeCases(t *testing.T) {
	now := time.Now()
	t.Run("two dests are not enough", func(t *testing.T) {
		d := NewWhitelistDetector()
		d.Observe(cutoffStall("a.example", now))
		d.Observe(cutoffStall("b.example", now.Add(time.Second)))
		if a := d.Assess(); a.WhitelistMode {
			t.Fatal("2 dests must not name whitelist mode")
		}
	})
	t.Run("same dest thrice is one data point", func(t *testing.T) {
		d := NewWhitelistDetector()
		for i := 0; i < 3; i++ {
			d.Observe(cutoffStall("a.example", now.Add(time.Duration(i)*time.Second)))
		}
		if a := d.Assess(); a.WhitelistMode {
			t.Fatal("one stalled dest is targeted blocking, not default-deny")
		}
	})
	t.Run("a direct success disproves the mode", func(t *testing.T) {
		d := NewWhitelistDetector()
		for i, h := range []string{"a.example", "b.example", "c.example"} {
			d.Observe(cutoffStall(h, now.Add(time.Duration(i)*time.Second)))
		}
		d.ObserveSuccess(Target{Host: "d.example", Port: 443})
		if a := d.Assess(); a.WhitelistMode {
			t.Fatal("a working direct destination disproves default-deny")
		}
	})
	t.Run("early stall is not the cutoff signature", func(t *testing.T) {
		d := NewWhitelistDetector()
		for i, h := range []string{"a.example", "b.example", "c.example"} {
			a := cutoffStall(h, now.Add(time.Duration(i)*time.Second))
			a.Events[3].BytesOut = 1200 // stalled during the handshake, not at 16 KB
			d.Observe(a)
		}
		if a := d.Assess(); a.WhitelistMode {
			t.Fatal("stalls far below 16 KB are not the whitelist cutoff")
		}
	})
	t.Run("data back from the far end vetoes", func(t *testing.T) {
		d := NewWhitelistDetector()
		for i, h := range []string{"a.example", "b.example", "c.example"} {
			a := cutoffStall(h, now.Add(time.Duration(i)*time.Second))
			a.Events[3].BytesIn = 50000 // the far end answered: not a silent drop
			d.Observe(a)
		}
		if a := d.Assess(); a.WhitelistMode {
			t.Fatal("stalls with real inbound data are not silent drops")
		}
	})
	t.Run("refused SYNs are not the signature", func(t *testing.T) {
		d := NewWhitelistDetector()
		for i, h := range []string{"a.example", "b.example", "c.example"} {
			at := now.Add(time.Duration(i) * time.Second)
			d.Observe(Attempt{
				ServerID:  "direct",
				Target:    Target{Host: h, Port: 443},
				StartedAt: at.Add(-time.Second),
				Events: []Event{
					{At: at, Stage: StageTCP, What: WhatError, Detail: "refused"},
				},
			})
		}
		if a := d.Assess(); a.WhitelistMode {
			t.Fatal("refused connections must not feed the whitelist verdict")
		}
	})
}

func TestSNIPool(t *testing.T) {
	p := NewSNIPool([]string{"B.Example.", "a.example", "b.example", "", "a.example"})
	if p.Len() != 2 {
		t.Fatalf("expected 2 unique normalized members, got %d", p.Len())
	}
	if got := p.Current(); got != "b.example" {
		t.Fatalf("Current should be the first member, got %q", got)
	}
	if got := p.Rotate(); got != "a.example" {
		t.Fatalf("Rotate should advance, got %q", got)
	}
	p.MarkBad("a.example")
	if got := p.Current(); got != "b.example" {
		t.Fatalf("burned member must be skipped, got %q", got)
	}
	if !p.IsBad("A.EXAMPLE") {
		t.Fatal("IsBad must be case-insensitive")
	}
	p.MarkBad("b.example")
	if got := p.Rotate(); got != "" {
		t.Fatalf("exhausted pool must return empty, got %q", got)
	}
	if got := p.Current(); got != "" {
		t.Fatalf("exhausted pool Current must be empty, got %q", got)
	}
	p.ResetBad()
	if got := p.Current(); got == "" {
		t.Fatal("ResetBad must revive the pool")
	}
}

func TestHandshakeLimiter(t *testing.T) {
	l := NewHandshakeLimiter(2, time.Second)
	ctx := context.Background()
	r1, err := l.Acquire(ctx, "a.example")
	if err != nil {
		t.Fatal(err)
	}
	defer r1()
	r2, err := l.Acquire(ctx, "a.example")
	if err != nil {
		t.Fatal(err)
	}
	// NOTE: r2 is released exactly once, explicitly below — no defer here,
	// or the deferred release would double-release at return and block.
	if got := l.InFlight("a.example"); got != 2 {
		t.Fatalf("expected 2 in flight, got %d", got)
	}
	// Third acquire on the same SNI must time out; another SNI is unaffected.
	if _, err := l.Acquire(ctx, "a.example"); err == nil {
		t.Fatal("expected acquire timeout at the cap")
	}
	r3, err := l.Acquire(ctx, "b.example")
	if err != nil {
		t.Fatal("different SNIs must not contend")
	}
	r3()
	// Release frees a slot.
	r2()
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		r, err := l.Acquire(ctx, "a.example")
		if err != nil {
			t.Error(err)
			return
		}
		r()
	}()
	wg.Wait()
	// Context cancellation is honored. With every slot taken, the only
	// ready select case is ctx.Done().
	r4, err := l.Acquire(ctx, "a.example")
	if err != nil {
		t.Fatal(err)
	}
	cctx, cancel := context.WithCancel(ctx)
	cancel()
	if _, err := l.Acquire(cctx, "a.example"); err == nil {
		t.Fatal("expected context error")
	}
	r4()
}
