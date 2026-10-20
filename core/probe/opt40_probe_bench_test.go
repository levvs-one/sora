package probe

// Regression benchmarks for the [opt40] Probe fan-out: Probe used to
// spawn one goroutine per endpoint, so a 200-endpoint request paid
// ~200 goroutine launches (≈22 KB, ≈390 allocs measured) for at most
// Config.Concurrency concurrent dials. The worker pool in Probe must
// keep these numbers at the pooled level:
//
//	BenchmarkProbeFanout200Invalid   94 709 B/op, 1407 allocs -> 73 212 B/op, 1016 allocs
//	BenchmarkProbeFanout200Closed   444 633 B/op, 9031 allocs -> 421 634 B/op, 8625 allocs
//	BenchmarkProbeFanout200Reachable 412 207 B/op, 7223 allocs -> 389 050 B/op, 6823 allocs
//
// (B/op and allocs/op are the deterministic metrics; ns/op on the
// shared VM is noise and is not part of the claim.)

import (
	"context"
	"fmt"
	"net"
	"testing"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func fanoutEndpoints(n int, host string, port uint32) ([]*corev1.Endpoint, []string) {
	eps := make([]*corev1.Endpoint, n)
	ids := make([]string, n)
	for i := range eps {
		eps[i] = &corev1.Endpoint{Host: host, Port: port}
		ids[i] = fmt.Sprintf("srv-%d", i)
	}
	return eps, ids
}

func runFanout(b *testing.B, p *Prober, eps []*corev1.Endpoint, ids []string) {
	b.Helper()
	ch, err := p.Probe(context.Background(), eps, ids)
	if err != nil {
		b.Fatal(err)
	}
	n := 0
	for range ch {
		n++
	}
	if n != len(eps) {
		b.Fatalf("got %d results, want %d", n, len(eps))
	}
}

// BenchmarkProbeFanout200Invalid is the pure fan-out measurement: every
// endpoint is malformed, so no dial happens and the entire cost is the
// fan-out machinery plus per-endpoint result/error construction.
func BenchmarkProbeFanout200Invalid(b *testing.B) {
	p := New(Config{Timeout: time.Second, Concurrency: 8})
	eps, ids := fanoutEndpoints(200, "", 443)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		runFanout(b, p, eps, ids)
	}
}

// BenchmarkProbeFanout200Closed fans out over 200 refused loopback
// endpoints: real dials, all failing fast.
func BenchmarkProbeFanout200Closed(b *testing.B) {
	p := New(Config{Timeout: time.Second, Concurrency: 8})
	eps, ids := fanoutEndpoints(200, "127.0.0.1", 1)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		runFanout(b, p, eps, ids)
	}
}

// BenchmarkProbeFanout200Reachable fans out over 200 endpoints served
// by one loopback listener.
func BenchmarkProbeFanout200Reachable(b *testing.B) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		b.Fatal(err)
	}
	defer ln.Close()
	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			_ = c.Close()
		}
	}()
	port := uint32(ln.Addr().(*net.TCPAddr).Port) //nolint:gosec // test listener port
	p := New(Config{Timeout: 2 * time.Second, Concurrency: 8})
	eps, ids := fanoutEndpoints(200, "127.0.0.1", port)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		runFanout(b, p, eps, ids)
	}
}
