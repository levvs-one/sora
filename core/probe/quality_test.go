package probe_test

import (
	"context"
	"testing"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/probe"
)

// TestProbeFeedsPathQuality (T035): every measured dial lands in the
// prober's quality registry — successes as RTT samples, failures as loss —
// keyed by (server, transport), so CENSORSHIP-METER reads real series
// instead of an empty showcase.
func TestProbeFeedsPathQuality(t *testing.T) {
	host, port := listener(t)
	prober := probe.New(probe.Config{Timeout: 2 * time.Second})

	results, err := prober.Probe(context.Background(), []*corev1.Endpoint{
		{Host: host, Port: port},
	}, []string{"berlin"})
	if err != nil {
		t.Fatalf("Probe: %v", err)
	}
	for range results {
	}

	q, ok := prober.Quality().Get("berlin", "tcp")
	if !ok {
		t.Fatalf("no quality series for (berlin, tcp); keys: %v", prober.Quality().Keys())
	}
	if q.RTT() <= 0 {
		t.Fatalf("series RTT = %v after a successful dial, want > 0", q.RTT())
	}
	if q.LossStreak() != 0 {
		t.Fatalf("series loss streak = %d after success, want 0", q.LossStreak())
	}

	// A failed dial records loss without an RTT.
	results, err = prober.Probe(context.Background(), []*corev1.Endpoint{
		{Host: "127.0.0.1", Port: closedPort(t)},
	}, []string{"dead"})
	if err != nil {
		t.Fatalf("Probe: %v", err)
	}
	for range results {
	}
	q, ok = prober.Quality().Get("dead", "tcp")
	if !ok {
		t.Fatalf("no quality series for (dead, tcp)")
	}
	if q.LossStreak() != 1 || q.RTT() != 0 {
		t.Fatalf("series after one failed dial: streak=%d rtt=%v, want 1/0", q.LossStreak(), q.RTT())
	}

	// Anonymous measurements (no server id) create no series: an
	// unattributable series can never feed a per-server meter.
	results, err = prober.Probe(context.Background(), []*corev1.Endpoint{
		{Host: host, Port: port},
	}, nil)
	if err != nil {
		t.Fatalf("Probe: %v", err)
	}
	for range results {
	}
	for _, k := range prober.Quality().Keys() {
		if k.Server == "" {
			t.Fatalf("anonymous probe created a series: %v", k)
		}
	}
}

// TestQualityRegistryBasics pins the registry contract directly.
func TestQualityRegistryBasics(t *testing.T) {
	r := probe.NewQualityRegistry()
	now := time.Now()
	r.Observe("a", "tls", 100*time.Millisecond, true, now)
	r.Observe("a", "tcp", 50*time.Millisecond, true, now)
	r.Observe("a", "tls", 0, false, now)
	if got := len(r.Keys()); got != 2 {
		t.Fatalf("Keys = %d, want 2 (transports stay separate)", got)
	}
	q, _ := r.Get("a", "tls")
	if q.LossStreak() != 1 {
		t.Fatalf("tls series streak = %d, want 1", q.LossStreak())
	}
	if _, ok := r.Get("missing", "tls"); ok {
		t.Fatalf("Get created a series for a missing key")
	}
}
