package censor

import (
	"context"
	"net"
	"testing"
	"time"
)

func testProber() *Prober {
	return &Prober{
		DialTimeout:      2 * time.Second,
		HandshakeTimeout: 2 * time.Second,
		ResolveTimeout:   2 * time.Second,
	}
}

func localhostPort(l net.Listener) int {
	return l.Addr().(*net.TCPAddr).Port
}

func findWhat(a Attempt, stage Stage) []What {
	var out []What
	for _, e := range a.Events {
		if e.Stage == stage {
			out = append(out, e.What)
		}
	}
	return out
}

func containsWhat(ws []What, w What) bool {
	for _, x := range ws {
		if x == w {
			return true
		}
	}
	return false
}

func TestProbeRefused(t *testing.T) {
	// Reserve a port, then close it: nothing listens.
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Skipf("no loopback: %v", err)
	}
	port := localhostPort(l)
	_ = l.Close()

	a := testProber().Probe(context.Background(), Target{Host: "127.0.0.1", Port: port})
	ws := findWhat(a, StageTCP)
	if !containsWhat(ws, WhatError) {
		t.Fatalf("tcp events = %v, want an error (refused)", ws)
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindNoInterference {
		t.Fatalf("kind = %v, want no_interference for a refusing port", v.Kind)
	}
}

func TestDNSFailureClassification(t *testing.T) {
	// Hermetic: the sandbox resolver answers even for .invalid (wildcard
	// DNS), so a network-dependent NXDOMAIN test would be flaky. The units
	// below are what the probe feeds the detector.
	if got := dnsDetail(&net.DNSError{IsNotFound: true, Name: "vpn.example.com"}); got != "nxdomain" {
		t.Fatalf("dnsDetail(notFound) = %q, want nxdomain", got)
	}
	nx := &net.DNSError{IsNotFound: true}
	if classifyConnError(nx) != WhatError {
		t.Fatalf("classifyConnError(nxdomain) should be a plain error event")
	}
	// And the detector end of the pipeline: NXDOMAIN for a name nobody saw
	// working proves nothing.
	a := withStart(mkAttempt())
	a.Events = []Event{ev(50*time.Millisecond, StageDNS, WhatError, "nxdomain")}
	if v := (Detector{}).Detect(a); v.Kind != KindUnknown {
		t.Fatalf("kind = %v, want unknown for an unresolvable unknown host", v.Kind)
	}
}

func TestProbeTCPResetAfterConnect(t *testing.T) {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Skipf("no loopback: %v", err)
	}
	defer l.Close()
	go func() {
		for {
			c, err := l.Accept()
			if err != nil {
				return
			}
			// RST the connection: a fresh accept torn down at once.
			if tc, ok := c.(*net.TCPConn); ok {
				_ = tc.SetLinger(0)
			}
			_ = c.Close()
		}
	}()

	a := testProber().Probe(context.Background(), Target{Host: "127.0.0.1", Port: localhostPort(l)})
	ws := findWhat(a, StageTCP)
	// Whether the RST lands during the connect or just after it is a kernel
	// race; either way the probe must observe the reset.
	if !containsWhat(ws, WhatRemoteReset) {
		t.Fatalf("tcp events = %v, want the reset observed", ws)
	}
	v := Detector{}.Detect(a)
	// Immediate RST, no TLS spoken: the detector may read it as injected,
	// but must never stretch it into an SNI claim, and must stay modest —
	// a RST on SYN is also how filtered-or-closed ports answer.
	if v.Kind == KindSNIBlocking {
		t.Fatalf("kind = sni_blocking without any TLS: signature overreach")
	}
	if v.Kind == KindRSTInjection && v.Confidence >= 0.75 {
		t.Fatalf("confidence = %v, want modest for a dial-time RST", v.Confidence)
	}
}

func TestProbePlainTCPNoTLS(t *testing.T) {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Skipf("no loopback: %v", err)
	}
	defer l.Close()
	go func() {
		for {
			c, err := l.Accept()
			if err != nil {
				return
			}
			_ = c.Close()
		}
	}()

	a := testProber().Probe(context.Background(), Target{Host: "127.0.0.1", Port: localhostPort(l), TLS: false})
	if len(a.Events) == 0 {
		t.Fatal("want events from a plain TCP probe")
	}
	for _, e := range a.Events {
		if e.Stage == StageTLS {
			t.Fatalf("plain TCP probe must not fabricate TLS events: %+v", e)
		}
	}
	// The listener closes cleanly: the probe observes the FIN rather than
	// mistaking a quiet close for interference.
	if ws := findWhat(a, StageTCP); !containsWhat(ws, WhatRemoteClose) {
		t.Fatalf("tcp events = %v, want the orderly close observed", ws)
	}
}
