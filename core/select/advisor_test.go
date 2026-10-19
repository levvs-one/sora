package serversel

import (
	"strings"
	"testing"
	"time"
)

// fakeClock is a manually advanced clock for hysteresis tests.
type fakeClock struct{ t time.Time }

func (f *fakeClock) now() time.Time { return f.t }
func (f *fakeClock) advance(d time.Duration) {
	f.t = f.t.Add(d)
}

func testAdvisorConfig(clk *fakeClock) AdvisorConfig {
	return AdvisorConfig{
		WindowSize:        4,
		ConfirmWindows:    2,
		LatencyFactor:     2.0,
		LatencySlack:      100 * time.Millisecond,
		ErrorRate:         0.5,
		MinSwitchInterval: 10 * time.Minute,
		Now:               clk.now,
	}
}

// feed pushes n identical observations, returning the last verdict.
func feed(a *Advisor, n int, lat time.Duration, ok bool) (bool, string) {
	var sw bool
	var reason string
	for i := 0; i < n; i++ {
		sw, reason = a.Observe(lat, ok)
	}
	return sw, reason
}

func TestAdvisorNotArmed(t *testing.T) {
	clk := &fakeClock{t: time.Now()}
	a := NewAdvisor(testAdvisorConfig(clk))
	if sw, _ := feed(a, 8, time.Second, false); sw {
		t.Fatal("unarmed advisor must never advise a switch")
	}
}

func TestAdvisorHealthyNoSwitch(t *testing.T) {
	clk := &fakeClock{t: time.Now()}
	a := NewAdvisor(testAdvisorConfig(clk))
	a.Arm("s1", 50*time.Millisecond)
	// Ten healthy windows: nothing may fire.
	for w := 0; w < 10; w++ {
		if sw, _ := feed(a, 4, 50*time.Millisecond, true); sw {
			t.Fatalf("healthy server must not trigger a switch (window %d)", w)
		}
	}
}

func TestAdvisorLatencyDegradation(t *testing.T) {
	clk := &fakeClock{t: time.Now()}
	a := NewAdvisor(testAdvisorConfig(clk))
	a.Arm("s1", 50*time.Millisecond)

	// Baseline limit: max(50ms*2, 50ms+100ms) = 150ms.
	// One degraded window is not enough with ConfirmWindows=2.
	if sw, _ := feed(a, 4, 500*time.Millisecond, true); sw {
		t.Fatal("single degraded window must not switch yet")
	}
	// Second consecutive degraded window advises the switch.
	sw, reason := feed(a, 4, 500*time.Millisecond, true)
	if !sw {
		t.Fatal("sustained degradation must advise a switch")
	}
	if !strings.Contains(reason, "s1") || !strings.Contains(reason, "p95") {
		t.Fatalf("reason must name the server and the signal, got %q", reason)
	}
}

func TestAdvisorErrorRateDegradation(t *testing.T) {
	clk := &fakeClock{t: time.Now()}
	a := NewAdvisor(testAdvisorConfig(clk))
	a.Arm("s1", 50*time.Millisecond)

	// 3 of 4 failed = 75% > 50% limit, two windows in a row.
	feed(a, 3, 50*time.Millisecond, false)
	if sw, _ := feed(a, 1, 50*time.Millisecond, true); sw {
		t.Fatal("first degraded window must not switch yet")
	}
	feed(a, 3, 50*time.Millisecond, false)
	sw, reason := feed(a, 1, 50*time.Millisecond, true)
	if !sw {
		t.Fatal("sustained error rate must advise a switch")
	}
	if !strings.Contains(reason, "error rate") {
		t.Fatalf("reason must mention error rate, got %q", reason)
	}
}

func TestAdvisorRecoveryResetsCounter(t *testing.T) {
	clk := &fakeClock{t: time.Now()}
	a := NewAdvisor(testAdvisorConfig(clk))
	a.Arm("s1", 50*time.Millisecond)

	// One degraded window, then a healthy one resets the streak.
	feed(a, 4, 500*time.Millisecond, true)
	feed(a, 4, 50*time.Millisecond, true)
	// One more degraded window: still only one in a row, no switch.
	if sw, _ := feed(a, 4, 500*time.Millisecond, true); sw {
		t.Fatal("recovery must reset the consecutive-degraded counter")
	}
}

func TestAdvisorNoFlapping(t *testing.T) {
	clk := &fakeClock{t: time.Now()}
	a := NewAdvisor(testAdvisorConfig(clk))
	a.Arm("s1", 50*time.Millisecond)

	// First advised switch.
	feed(a, 4, 500*time.Millisecond, true)
	sw, _ := feed(a, 4, 500*time.Millisecond, true)
	if !sw {
		t.Fatal("first degradation must advise a switch")
	}
	a.Switched("s2", 60*time.Millisecond)

	// Degradation resumes immediately: cooldown must suppress the advice.
	feed(a, 4, 500*time.Millisecond, true)
	sw, reason := feed(a, 4, 500*time.Millisecond, true)
	if sw {
		t.Fatal("must not advise a second switch inside MinSwitchInterval")
	}
	if !strings.Contains(reason, "cooling down") {
		t.Fatalf("reason must mention the cooldown, got %q", reason)
	}

	// After the interval, sustained degradation advises again.
	clk.advance(11 * time.Minute)
	if sw, _ := feed(a, 4, 500*time.Millisecond, true); !sw {
		t.Fatal("must advise again once the cooldown expired")
	}
}

func TestAdvisorCooldownKeepsPending(t *testing.T) {
	clk := &fakeClock{t: time.Now()}
	a := NewAdvisor(testAdvisorConfig(clk))
	a.Arm("s1", 50*time.Millisecond)

	feed(a, 4, 500*time.Millisecond, true)
	if sw, _ := feed(a, 4, 500*time.Millisecond, true); !sw {
		t.Fatal("first degradation must advise a switch")
	}
	a.Switched("s2", 60*time.Millisecond)

	// Stay degraded through the cooldown; the advice must fire on the
	// first window evaluated after it ends, without needing a fresh
	// ConfirmWindows streak.
	clk.advance(9 * time.Minute)
	feed(a, 4, 500*time.Millisecond, true) // suppressed, counter kept
	feed(a, 4, 500*time.Millisecond, true) // suppressed, counter kept
	clk.advance(2 * time.Minute)           // past the 10m cooldown
	if sw, _ := feed(a, 4, 500*time.Millisecond, true); !sw {
		t.Fatal("pending degradation must fire right after the cooldown")
	}
}

func TestAdvisorManualSwitchStartsCooldown(t *testing.T) {
	clk := &fakeClock{t: time.Now()}
	a := NewAdvisor(testAdvisorConfig(clk))
	a.Arm("s1", 50*time.Millisecond)
	// A manual switch (no degradation) still starts the cooldown.
	a.Switched("s2", 60*time.Millisecond)
	feed(a, 4, 500*time.Millisecond, true)
	if sw, _ := feed(a, 4, 500*time.Millisecond, true); sw {
		t.Fatal("manual switch must start the cooldown too")
	}
}

func TestAdvisorConfigClamps(t *testing.T) {
	a := NewAdvisor(AdvisorConfig{
		WindowSize:        -3,
		ConfirmWindows:    500,
		LatencyFactor:     0.5,
		LatencySlack:      -time.Second,
		ErrorRate:         5,
		MinSwitchInterval: time.Hour * 100,
	})
	cfg := a.Config()
	if cfg.WindowSize != 4 || cfg.ConfirmWindows != 100 {
		t.Fatalf("window clamps wrong: %+v", cfg)
	}
	if cfg.LatencyFactor != 1.05 || cfg.ErrorRate != 1 {
		t.Fatalf("threshold clamps wrong: %+v", cfg)
	}
	if cfg.LatencySlack != 0 || cfg.MinSwitchInterval != 24*time.Hour {
		t.Fatalf("duration clamps wrong: %+v", cfg)
	}
}

func TestAdvisorZeroConfigIsUsable(t *testing.T) {
	a := NewAdvisor(AdvisorConfig{})
	a.Arm("s1", 50*time.Millisecond)
	if !a.Armed() {
		t.Fatal("Arm must arm the advisor")
	}
	if sw, _ := feed(a, 200, 50*time.Millisecond, true); sw {
		t.Fatal("healthy traffic on a zero-config advisor must not switch")
	}
}
