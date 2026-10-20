package probe

import (
	"testing"
	"time"
)

func TestPathQualityZeroValue(t *testing.T) {
	var q PathQuality
	now := time.Now()
	if q.RTT() != 0 || q.Jitter() != 0 || q.LossStreak() != 0 || q.MaxLossStreak() != 0 {
		t.Fatal("zero value must report zero stats")
	}
	if q.Stalled(time.Second, now) {
		t.Fatal("no samples must not count as a stall")
	}
	if q.Stalled(0, now) || q.Stalled(-time.Second, now) {
		t.Fatal("non-positive threshold must never stall")
	}
}

func TestPathQualitySmoothsRTT(t *testing.T) {
	var q PathQuality
	now := time.Now()
	for i := 0; i < 100; i++ {
		q.Observe(100*time.Millisecond, true, now.Add(time.Duration(i)*time.Second))
	}
	if got := q.RTT(); got != 100*time.Millisecond {
		t.Fatalf("constant samples must converge exactly, got %v", got)
	}
	if q.Jitter() != 0 {
		t.Fatalf("constant RTT must have zero jitter, got %v", q.Jitter())
	}
	// A step up moves the EWMA by 1/8 of the gap per sample.
	q.Observe(200*time.Millisecond, true, now)
	if got := q.RTT(); got != 100*time.Millisecond+12*time.Millisecond+500*time.Microsecond {
		t.Fatalf("EWMA step = %v, want 112.5ms", got)
	}
	if q.Jitter() <= 0 {
		t.Fatal("an RTT step must register jitter")
	}
}

func TestPathQualityLossStreaks(t *testing.T) {
	var q PathQuality
	now := time.Now()
	q.Observe(50*time.Millisecond, true, now)
	for i := 0; i < 3; i++ {
		q.Observe(0, false, now)
	}
	if q.LossStreak() != 3 || q.MaxLossStreak() != 3 {
		t.Fatalf("streak = %d/%d, want 3/3", q.LossStreak(), q.MaxLossStreak())
	}
	// Failures must not poison the RTT estimate.
	if q.RTT() != 50*time.Millisecond {
		t.Fatalf("RTT after losses = %v, want 50ms", q.RTT())
	}
	q.Observe(50*time.Millisecond, true, now)
	if q.LossStreak() != 0 || q.MaxLossStreak() != 3 {
		t.Fatalf("success resets current streak only: %d/%d", q.LossStreak(), q.MaxLossStreak())
	}
	// A zero-RTT success is a sign of life, not a measurement.
	q.Observe(0, true, now.Add(time.Second))
	if q.RTT() != 50*time.Millisecond {
		t.Fatalf("zero-RTT sample must not move the EWMA: %v", q.RTT())
	}
	if q.Stalled(2*time.Second, now.Add(2*time.Second)) {
		t.Fatal("a recent sign of life must not stall")
	}
}

func TestPathQualityStallPredicate(t *testing.T) {
	var q PathQuality
	start := time.Now()
	q.Observe(30*time.Millisecond, true, start)
	if q.Stalled(10*time.Second, start.Add(9*time.Second)) {
		t.Fatal("before the threshold: not stalled")
	}
	if !q.Stalled(10*time.Second, start.Add(10*time.Second)) {
		t.Fatal("at the threshold: stalled")
	}
	// A later success clears the stall.
	q.Observe(30*time.Millisecond, true, start.Add(11*time.Second))
	if q.Stalled(10*time.Second, start.Add(20*time.Second)) {
		t.Fatal("a fresh success must clear the stall")
	}
}
