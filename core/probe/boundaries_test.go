package probe

import (
	"context"
	"strings"
	"testing"
	"time"
)

// Boundary tests for the survivability thresholds: every constant
// that decides a verdict is exercised exactly at, just below, and
// just above its edge, so an off-by-one in a threshold cannot pass
// unnoticed.

// TestFreezeThresholdBoundaries: the parallel threshold is "more
// than 3 in flight": stalls at exactly 3 concurrent are sequential
// samples and can never make a freeze, no matter how many pile up;
// the claim needs exactly freezeMinStalled (2) stalled parallels.
func TestFreezeThresholdBoundaries(t *testing.T) {
	now := time.Now()
	d := &FreezeDetector{Now: func() time.Time { return now }}
	d.Observe(FreezeSample{SNI: "dest.test", Concurrent: 1, At: now})
	// At-threshold (3 concurrent) stalls: not parallel samples.
	for i := 0; i < 4; i++ {
		d.Observe(FreezeSample{SNI: "dest.test", Concurrent: 3, Stalled: true, At: now})
	}
	if v := d.Verdict("dest.test"); v.Frozen || v.ParallelTotal != 0 {
		t.Fatalf("concurrency == threshold must not count as parallel: %+v", v)
	}
	// One stalled parallel (above threshold): below the claim floor.
	d.Observe(FreezeSample{SNI: "dest.test", Concurrent: 4, Stalled: true, At: now})
	if v := d.Verdict("dest.test"); v.Frozen {
		t.Fatalf("one stalled parallel must not claim a freeze: %+v", v)
	}
	// The second stalled parallel reaches the floor exactly.
	d.Observe(FreezeSample{SNI: "dest.test", Concurrent: 4, Stalled: true, At: now})
	if v := d.Verdict("dest.test"); !v.Frozen {
		t.Fatalf("two stalled parallels + one sequential success must claim: %+v", v)
	}
	// And without any sequential success the same parallels stay a
	// dead-endpoint story, never a freeze (the differential rule).
	d2 := &FreezeDetector{Now: func() time.Time { return now }}
	for i := 0; i < 3; i++ {
		d2.Observe(FreezeSample{SNI: "dest.test", Concurrent: 6, Stalled: true, At: now})
	}
	if v := d2.Verdict("dest.test"); v.Frozen {
		t.Fatalf("no sequential success, no freeze claim: %+v", v)
	}
}

// TestBanTrackerExpiryBoundary: at TTL-1s the tuple is still banned;
// at exactly the TTL it is free (the ban is [start, start+420s) ).
func TestBanTrackerExpiryBoundary(t *testing.T) {
	base := time.Now()
	clock := base
	b := NewBanTracker()
	b.now = func() time.Time { return clock }
	b.NoteBlocked(40000, "203.0.113.7:443")
	clock = base.Add(residualBanTTL - time.Second)
	if !b.Banned(40000, "203.0.113.7:443") {
		t.Fatal("one second before expiry the ban must stand")
	}
	clock = base.Add(residualBanTTL)
	if b.Banned(40000, "203.0.113.7:443") {
		t.Fatal("at exactly the 420s TTL the ban must be over")
	}
}

// TestDefaultHandshakeLimitBoundary: the production default is
// exactly 3 parallel handshakes per SNI — three acquires succeed,
// the fourth waits and times out.
func TestDefaultHandshakeLimitBoundary(t *testing.T) {
	l := NewHandshakeLimiter(0, 30*time.Millisecond) // default cap, short wait
	ctx := context.Background()
	var releases []func()
	for i := 0; i < 3; i++ {
		r, err := l.Acquire(ctx, "dest.test")
		if err != nil {
			t.Fatalf("acquire %d of 3 must succeed: %v", i+1, err)
		}
		releases = append(releases, r)
	}
	if _, err := l.Acquire(ctx, "dest.test"); err == nil {
		t.Fatal("the 4th parallel handshake on one SNI must not acquire")
	}
	for _, r := range releases {
		r()
	}
	if got := l.InFlight("dest.test"); got != 0 {
		t.Fatalf("InFlight after releases = %d, want 0", got)
	}
}

// TestMaskedName: the event/log dictionary — names appear only
// masked, with their shape (first letter / first octet + suffix)
// preserved for diagnosis.
func TestMaskedName(t *testing.T) {
	cases := map[string]string{
		"www.microsoft.com": "w***.microsoft.com",
		"dest.test":         "d***.test",
		"localhost":         "l***",
		"203.0.113.7":       "203.***",
		"":                  "",
	}
	for in, want := range cases {
		if got := MaskedName(in); got != want {
			t.Errorf("MaskedName(%q) = %q, want %q", in, got, want)
		}
	}
	if m := frozenDetector(time.Now()).Verdict("dest.test").Mitigation("chrome"); strings.Contains(m.Why, "dest.test") {
		t.Errorf("mitigation Why leaks the raw SNI: %q", m.Why)
	}
}
