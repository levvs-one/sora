package probe

import (
	"net/netip"
	"strings"
	"testing"
	"time"
)

func mustAddr(t *testing.T, s string) netip.Addr {
	t.Helper()
	a, err := netip.ParseAddr(s)
	if err != nil {
		t.Fatalf("parse %q: %v", s, err)
	}
	return a
}

func TestSubnetOf(t *testing.T) {
	p, ok := SubnetOf(mustAddr(t, "203.0.113.7"))
	if !ok || p.String() != "203.0.113.0/24" {
		t.Fatalf("v4: got %v %v", p, ok)
	}
	p, ok = SubnetOf(mustAddr(t, "2001:db8:abcd:12::1"))
	if !ok || p.String() != "2001:db8:abcd::/48" {
		t.Fatalf("v6: got %v %v", p, ok)
	}
	if _, ok := SubnetOf(netip.Addr{}); ok {
		t.Fatal("invalid addr must not map")
	}
	if _, ok := SubnetOf(mustAddr(t, "127.0.0.1")); ok {
		t.Fatal("loopback must not map")
	}
}

func TestSubnetReputationBurned(t *testing.T) {
	r := NewSubnetReputation()
	base := time.Now()
	r.now = func() time.Time { return base }
	// Three distinct failing IPs in one /24, no successes: burned.
	for _, ip := range []string{"203.0.113.1", "203.0.113.2", "203.0.113.3"} {
		r.Observe(mustAddr(t, ip), false)
	}
	if got := r.State(mustAddr(t, "203.0.113.99")); got != SubnetBurned {
		t.Fatalf("State = %v, want burned", got)
	}
}

func TestSubnetReputationSingleDeadIPIsNotBurned(t *testing.T) {
	r := NewSubnetReputation()
	r.Observe(mustAddr(t, "203.0.113.1"), false)
	if got := r.State(mustAddr(t, "203.0.113.2")); got != SubnetHealthy {
		t.Fatalf("single dead IP must not condemn the /24, got %v", got)
	}
}

func TestSubnetReputationDegraded(t *testing.T) {
	r := NewSubnetReputation()
	r.Observe(mustAddr(t, "198.51.100.1"), false)
	r.Observe(mustAddr(t, "198.51.100.2"), false)
	r.Observe(mustAddr(t, "198.51.100.3"), false)
	r.Observe(mustAddr(t, "198.51.100.4"), true)
	if got := r.State(mustAddr(t, "198.51.100.9")); got != SubnetDegraded {
		t.Fatalf("State = %v, want degraded", got)
	}
}

func TestSubnetReputationWindowExpiry(t *testing.T) {
	r := NewSubnetReputation()
	base := time.Now()
	now := base
	r.now = func() time.Time { return now }
	for _, ip := range []string{"203.0.113.1", "203.0.113.2", "203.0.113.3"} {
		r.Observe(mustAddr(t, ip), false)
	}
	now = base.Add(2 * subnetWindow)
	if got := r.State(mustAddr(t, "203.0.113.1")); got != SubnetHealthy {
		t.Fatalf("stale outcomes must expire, got %v", got)
	}
}

func TestSubnetReputationIPv6(t *testing.T) {
	r := NewSubnetReputation()
	for _, ip := range []string{"2001:db8:1::1", "2001:db8:1::2", "2001:db8:1::3"} {
		r.Observe(mustAddr(t, ip), false)
	}
	if got := r.State(mustAddr(t, "2001:db8:1::9")); got != SubnetBurned {
		t.Fatalf("v6 /48: got %v, want burned", got)
	}
	// A different /48 is unaffected.
	if got := r.State(mustAddr(t, "2001:db8:2::9")); got != SubnetHealthy {
		t.Fatalf("other /48: got %v, want healthy", got)
	}
}

func TestSubnetReputationWave(t *testing.T) {
	r := NewSubnetReputation()
	nets := []string{"203.0.113", "198.51.100", "192.0.2"}
	for _, n := range nets {
		for _, h := range []string{"1", "2", "3"} {
			r.Observe(mustAddr(t, n+"."+h), false)
		}
	}
	wave, burned := r.Wave()
	if !wave || len(burned) != 3 {
		t.Fatalf("Wave = %v, burned = %d, want true/3", wave, len(burned))
	}
	lines := r.SummaryLines()
	found := false
	for _, l := range lines {
		if strings.Contains(l, "CARPET-BAN WAVE") {
			found = true
		}
	}
	if !found {
		t.Fatalf("SummaryLines must name the wave, got %v", lines)
	}
}

func TestSubnetReputationNoWaveBelowBar(t *testing.T) {
	r := NewSubnetReputation()
	for _, n := range []string{"203.0.113", "198.51.100"} {
		for _, h := range []string{"1", "2", "3"} {
			r.Observe(mustAddr(t, n+"."+h), false)
		}
	}
	if wave, _ := r.Wave(); wave {
		t.Fatal("two burned subnets are not a wave")
	}
}

func TestSubnetReputationEmptySummary(t *testing.T) {
	r := NewSubnetReputation()
	if lines := r.SummaryLines(); len(lines) != 0 {
		t.Fatalf("no data must mean no claims, got %v", lines)
	}
}
