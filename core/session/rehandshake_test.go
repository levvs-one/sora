package session

import (
	"math/rand/v2"
	"testing"
	"time"
)

func TestRehandshakeDeadlineSpreadsWithJitter(t *testing.T) {
	p := RehandshakePolicy{MaxAge: time.Hour, Jitter: 10 * time.Minute}
	est := time.Now()
	r := rand.New(rand.NewPCG(1, 2))
	seen := map[time.Time]bool{}
	for i := 0; i < 50; i++ {
		d := p.Deadline(est, r)
		if d.Before(est.Add(50*time.Minute)) || d.After(est.Add(70*time.Minute)) {
			t.Fatalf("deadline %v outside [50m, 70m] of establishment", d.Sub(est))
		}
		seen[d] = true
	}
	if len(seen) < 40 {
		t.Fatalf("jitter barely spreads the deadline: %d distinct of 50", len(seen))
	}
}

func TestRehandshakeDisabledPolicy(t *testing.T) {
	p := RehandshakePolicy{}
	if d := p.Deadline(time.Now(), rand.New(rand.NewPCG(1, 1))); !d.IsZero() {
		t.Fatalf("zero policy must not schedule: %v", d)
	}
	if p.Overdue(time.Now(), time.Time{}) {
		t.Fatal("a zero deadline is never overdue")
	}
	// Negative values fail closed instead of scheduling in the past.
	p = RehandshakePolicy{MaxAge: -time.Hour, Jitter: -time.Minute}
	if d := p.Deadline(time.Now(), nil); !d.IsZero() {
		t.Fatalf("negative policy must not schedule: %v", d)
	}
}

func TestRehandshakeJitterClampedToMaxAge(t *testing.T) {
	p := RehandshakePolicy{MaxAge: time.Minute, Jitter: time.Hour}
	est := time.Now()
	r := rand.New(rand.NewPCG(7, 7))
	for i := 0; i < 200; i++ {
		if d := p.Deadline(est, r); d.Before(est) {
			t.Fatalf("clamped jitter must never schedule in the past: %v", d.Sub(est))
		}
	}
}

func TestRehandshakeOverdueBoundary(t *testing.T) {
	p := RehandshakePolicy{MaxAge: time.Hour}
	d := p.Deadline(time.Now().Add(-2*time.Hour), nil) // nil rand: zero jitter
	if !p.Overdue(time.Now(), d) {
		t.Fatal("a deadline two hours past must be overdue")
	}
	if p.Overdue(d.Add(-time.Second), d) {
		t.Fatal("one second before the deadline is not overdue")
	}
}

func TestKeepaliveIntervalJitterBounds(t *testing.T) {
	r := rand.New(rand.NewPCG(3, 4))
	for i := 0; i < 500; i++ {
		got := KeepaliveInterval(20*time.Second, r)
		if got < 15*time.Second || got > 25*time.Second {
			t.Fatalf("keepalive %v outside ±25%% of 20s", got)
		}
	}
	if got := KeepaliveInterval(0, r); got != 0 {
		t.Fatalf("zero base must disable keepalive, got %v", got)
	}
	if got := KeepaliveInterval(-time.Second, r); got != 0 {
		t.Fatalf("negative base must disable keepalive, got %v", got)
	}
	if got := KeepaliveInterval(20*time.Second, nil); got != 20*time.Second {
		t.Fatalf("nil source must return the base unchanged, got %v", got)
	}
}
