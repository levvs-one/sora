package censor

import (
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/probe"
)

const (
	fakeNetA = "eth0 192.168.1.2"
	fakeNetB = "wlan0 172.16.0.2"
)

// TestSNIPoolNetworkChangeUnburns: burned marks are verdicts about
// one network's path. After a move, every candidate is a candidate
// again — the candidates themselves are profile data and stay.
func TestSNIPoolNetworkChangeUnburns(t *testing.T) {
	p := NewSNIPool([]string{"a.test", "b.test"})
	if got := p.BurnAndRotate("a.test"); got != "b.test" {
		t.Fatalf("BurnAndRotate = %q, want b.test", got)
	}
	if got := p.BurnAndRotate("b.test"); got != "" {
		t.Fatalf("exhausted pool = %q, want empty (failover, not cycling)", got)
	}
	if p.BindNetwork(fakeNetA) {
		t.Fatal("first bind must not clear marks")
	}
	if p.Current() != "" {
		t.Fatal("same network: marks must stand")
	}
	if !p.BindNetwork(fakeNetB) {
		t.Fatal("network change must report cleared marks")
	}
	if got := p.Current(); got != "a.test" {
		t.Fatalf("after a network change Current = %q, want a.test (pool data kept, marks dropped)", got)
	}
	if snap := p.Snapshot(); len(snap) != 2 || snap[0] != "a.test" || snap[1] != "b.test" {
		t.Fatalf("Snapshot = %v, want the profile data in order", snap)
	}
}

// TestFreezePolicyNetworkChangeDropsBackoff: a freeze recognized on
// network A must not hold the session in its quiet period on network
// B — and the shared recognizer's samples go with it (one bind call
// invalidates the whole chain).
func TestFreezePolicyNetworkChangeDropsBackoff(t *testing.T) {
	now := time.Now()
	det := &probe.FreezeDetector{Now: func() time.Time { return now }}
	det.Observe(probe.FreezeSample{SNI: "dest.test", Concurrent: 1, At: now})
	for i := 0; i < 2; i++ {
		det.Observe(probe.FreezeSample{SNI: "dest.test", Concurrent: 6, Stalled: true, At: now})
	}
	p := NewFreezePolicy(det)
	p.now = func() time.Time { return now }
	target := Target{Host: "203.0.113.7", Port: 443, SNI: "dest.test", TLS: true}
	a := p.Assess(target, "chrome")
	if !a.Freeze {
		t.Fatal("precondition: policy must see the freeze")
	}
	if _, ok := p.BackoffUntil("dest.test"); !ok {
		t.Fatal("precondition: backoff must be armed")
	}
	p.BindNetwork(fakeNetA)
	if _, ok := p.BackoffUntil("dest.test"); !ok {
		t.Fatal("same network: backoff must stand")
	}
	if !p.BindNetwork(fakeNetB) {
		t.Fatal("network change must report dropped state")
	}
	if _, ok := p.BackoffUntil("dest.test"); ok {
		t.Fatal("the backoff belonged to the old network and must be gone")
	}
	if a := p.Assess(target, "chrome"); a.Freeze {
		t.Fatal("the recognizer's samples belonged to the old network too")
	}
}
