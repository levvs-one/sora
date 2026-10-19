package probe

import (
	"context"
	"net"
	"net/netip"
	"strings"
	"testing"
	"time"
)

// racingListener opens a TCP listener on 127.0.0.1 and returns its port.
func racingListener(t *testing.T) uint32 {
	t.Helper()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	t.Cleanup(func() { _ = ln.Close() })
	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			_ = c.Close()
		}
	}()
	return uint32(ln.Addr().(*net.TCPAddr).Port) //nolint:gosec // test listener port
}

// twoLoopbacks resolves any host to 127.0.0.2 first (nothing listens
// there: dials refuse fast) and 127.0.0.1 second.
func twoLoopbacks(_ context.Context, _ string) ([]netip.Addr, error) {
	return []netip.Addr{
		netip.MustParseAddr("127.0.0.2"),
		netip.MustParseAddr("127.0.0.1"),
	}, nil
}

// TestDialRacesResolvedAddresses checks the Happy Eyeballs path: the
// first resolved address refuses, and the race still reaches the
// listener on the second one instead of failing on the first.
func TestDialRacesResolvedAddresses(t *testing.T) {
	port := racingListener(t)
	p := New(Config{Timeout: 5 * time.Second})
	p.lookupIP = twoLoopbacks
	for i := 0; i < 5; i++ {
		latency, err := p.dial(context.Background(), "example.com", port)
		if err != nil {
			t.Fatalf("iteration %d: dial() error = %v", i, err)
		}
		if latency <= 0 {
			t.Fatalf("iteration %d: latency = %v, want positive", i, latency)
		}
	}
}

// TestDialRaceFailureRedactsAddresses checks that a raced failure keeps
// the SORA-M7 redaction: no resolved address may reach the caller in the
// error.
func TestDialRaceFailureRedactsAddresses(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	closed := uint32(ln.Addr().(*net.TCPAddr).Port) //nolint:gosec // test port
	_ = ln.Close()                                  // nothing listens now: both refuse
	p := New(Config{Timeout: 5 * time.Second})
	p.lookupIP = twoLoopbacks
	_, err = p.dial(context.Background(), "example.com", closed)
	if err == nil {
		t.Fatal("dial() error = nil, want refused")
	}
	if s := err.Error(); strings.Contains(s, "127.0.0") {
		t.Errorf("dial() error leaks an address: %q", s)
	}
}

// TestDialIPLiteralKeepsTheSinglePath checks that an IP literal never
// resolves or races: the historical path dials it directly.
func TestDialIPLiteralKeepsTheSinglePath(t *testing.T) {
	port := racingListener(t)
	p := New(Config{Timeout: 5 * time.Second})
	p.lookupIP = func(_ context.Context, host string) ([]netip.Addr, error) {
		t.Errorf("resolver called for IP literal %q", host)
		return nil, nil
	}
	latency, err := p.dial(context.Background(), "127.0.0.1", port)
	if err != nil {
		t.Fatalf("dial() error = %v", err)
	}
	if latency <= 0 {
		t.Errorf("latency = %v, want positive", latency)
	}
}

// TestCandidateAddrsReturnsNilOnResolutionFailure checks that a failed
// lookup keeps the endpoint on the historical single-dial path instead
// of failing the measurement: the dialer's own resolution reports the
// DNS failure, as before.
func TestCandidateAddrsReturnsNilOnResolutionFailure(t *testing.T) {
	p := New(Config{Timeout: 3 * time.Second})
	p.lookupIP = func(_ context.Context, _ string) ([]netip.Addr, error) {
		return nil, &net.DNSError{Err: "no such host", Name: "example.invalid", IsNotFound: true}
	}
	if addrs := p.candidateAddrs(context.Background(), "example.com", 3*time.Second); addrs != nil {
		t.Errorf("candidateAddrs() = %v, want nil on resolution failure", addrs)
	}
}

// TestCandidateAddrsSkipsIPLiteral checks that an IP literal never
// triggers a resolution: there is nothing to race.
func TestCandidateAddrsSkipsIPLiteral(t *testing.T) {
	p := New(Config{Timeout: 3 * time.Second})
	p.lookupIP = func(_ context.Context, host string) ([]netip.Addr, error) {
		t.Errorf("resolver called for IP literal %q", host)
		return nil, nil
	}
	for _, host := range []string{"127.0.0.1", "::1"} {
		if addrs := p.candidateAddrs(context.Background(), host, 3*time.Second); addrs != nil {
			t.Errorf("candidateAddrs(%q) = %v, want nil", host, addrs)
		}
	}
}

// TestCandidateAddrsKeepsResolverOrder checks the race preference order
// is the resolver's answer order: deterministic, never shuffled.
func TestCandidateAddrsKeepsResolverOrder(t *testing.T) {
	want := []netip.Addr{
		netip.MustParseAddr("2001:db8::1"),
		netip.MustParseAddr("93.184.216.34"),
		netip.MustParseAddr("2001:db8::2"),
	}
	p := New(Config{Timeout: 3 * time.Second})
	p.lookupIP = func(_ context.Context, _ string) ([]netip.Addr, error) { return want, nil }
	got := p.candidateAddrs(context.Background(), "example.com", 3*time.Second)
	if len(got) != len(want) {
		t.Fatalf("candidateAddrs() = %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("candidateAddrs()[%d] = %v, want %v (order changed)", i, got[i], want[i])
		}
	}
}
