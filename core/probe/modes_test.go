package probe_test

import (
	"context"
	"net"
	"net/http"
	"net/http/httptest"
	"runtime"
	"strconv"
	"testing"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/probe"
)

func endpointOf(t *testing.T, address string) *corev1.Endpoint {
	t.Helper()
	host, portText, err := net.SplitHostPort(address)
	if err != nil {
		t.Fatal(err)
	}
	port, err := strconv.ParseUint(portText, 10, 16)
	if err != nil {
		t.Fatal(err)
	}
	return &corev1.Endpoint{Host: host, Port: uint32(port)}
}

func only(t *testing.T, results <-chan *corev1.ProbeResult) *corev1.ProbeResult {
	t.Helper()
	var got []*corev1.ProbeResult
	for r := range results {
		got = append(got, r)
	}
	if len(got) != 1 {
		t.Fatalf("want one result, got %d", len(got))
	}
	return got[0]
}

func TestTLSModeTimesAHandshakeWithAnUnverifiedCertificate(t *testing.T) {
	server := httptest.NewTLSServer(http.NotFoundHandler())
	defer server.Close()
	p := probe.New(probe.Config{Timeout: 3 * time.Second})
	results, err := p.ProbeMode(context.Background(), []*corev1.Endpoint{endpointOf(t, server.Listener.Addr().String())}, []string{"s"}, probe.ModeTLS)
	if err != nil {
		t.Fatal(err)
	}
	if r := only(t, results); !r.GetReachable() || r.GetServerId() != "s" {
		t.Fatalf("a self-signed TLS server must still be timed: %v", r)
	}
}

func TestTLSModeFailsOnAPlainTCPServer(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = listener.Close() }()
	go func() {
		for {
			conn, err := listener.Accept()
			if err != nil {
				return
			}
			_, _ = conn.Write([]byte("not tls\r\n"))
			_ = conn.Close()
		}
	}()
	p := probe.New(probe.Config{Timeout: 3 * time.Second})
	results, err := p.ProbeMode(context.Background(), []*corev1.Endpoint{endpointOf(t, listener.Addr().String())}, nil, probe.ModeTLS)
	if err != nil {
		t.Fatal(err)
	}
	if r := only(t, results); r.GetReachable() || r.GetError() == nil {
		t.Fatalf("a server without TLS must not look reachable: %v", r)
	}
}

func TestICMPModeEchoesLoopback(t *testing.T) {
	p := probe.New(probe.Config{Timeout: 3 * time.Second})
	results, err := p.ProbeMode(context.Background(), []*corev1.Endpoint{{Host: "127.0.0.1", Port: 443}}, []string{"lo"}, probe.ModeICMP)
	if err != nil {
		t.Fatal(err)
	}
	r := only(t, results)
	if r.GetReachable() {
		return
	}
	// Unprivileged runs without ping sockets cannot echo at all; that is a
	// property of the machine, reported as permission denied, not a bug.
	if r.GetError().GetCode() == corev1.SoraErrorCode_SORA_ERROR_CODE_PERMISSION_DENIED {
		t.Skipf("ICMP is not allowed for this user on %s: %s", runtime.GOOS, r.GetError().GetDetailRedacted())
	}
	t.Fatalf("loopback must answer an echo: %v", r)
}

func TestICMPModeStopsAtTheDeadline(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()
	p := probe.New(probe.Config{Timeout: 5 * time.Second})
	start := time.Now()
	// TEST-NET-1 has no host behind it. A local VPN tunnel may still answer
	// for it, so only the time is checked: a silent address must not hold
	// the request past its deadline.
	results, err := p.ProbeMode(ctx, []*corev1.Endpoint{{Host: "192.0.2.1", Port: 443}}, nil, probe.ModeICMP)
	if err != nil {
		t.Fatal(err)
	}
	for range results {
	}
	if elapsed := time.Since(start); elapsed > 2*time.Second {
		t.Fatalf("the echo outlived its deadline: %v", elapsed)
	}
}
