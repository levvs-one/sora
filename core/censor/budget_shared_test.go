package censor

import (
	"context"
	"net"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/probe"
)

// swapSharedBudget points BOTH default names at one fresh limiter
// (fast refusal timeout for tests) and restores them afterwards.
// The production wiring binds both names to the same object at
// package init; the swap preserves exactly that shape.
func swapSharedBudget(t *testing.T) *probe.HandshakeLimiter {
	t.Helper()
	fresh := probe.NewHandshakeLimiter(0, 100*time.Millisecond)
	oldProbe, oldCensor := probe.DefaultHandshakeLimiter, DefaultHandshakeBudget
	probe.DefaultHandshakeLimiter, DefaultHandshakeBudget = fresh, fresh
	t.Cleanup(func() {
		probe.DefaultHandshakeLimiter, DefaultHandshakeBudget = oldProbe, oldCensor
	})
	return fresh
}

// TestSharedHandshakeBudgetAcrossPaths pins CENSOR-SURV review
// Medium 2: CheckDest (probe) and censor.Prober used to hold two
// independent default limiters, so one SNI could see 6 parallel
// handshakes against a cap of 3. Both defaults are now the single
// probe.DefaultHandshakeLimiter instance — proven here by identity
// and by the combined cap: slots taken through the two paths add up
// to 3, and a fourth acquire through either path is refused.
func TestSharedHandshakeBudgetAcrossPaths(t *testing.T) {
	if DefaultHandshakeBudget != probe.DefaultHandshakeLimiter {
		t.Fatal("censor.DefaultHandshakeBudget must be probe.DefaultHandshakeLimiter itself, not a second instance")
	}
	shared := swapSharedBudget(t)
	const sni = "shared-budget-cap.test"
	ctx := context.Background()
	var releases []func()
	// Two slots via the censor path, one via the probe path.
	for i := 0; i < 2; i++ {
		r, err := DefaultHandshakeBudget.Acquire(ctx, sni)
		if err != nil {
			t.Fatalf("censor-path acquire %d: %v", i, err)
		}
		releases = append(releases, r)
	}
	r, err := probe.DefaultHandshakeLimiter.Acquire(ctx, sni)
	if err != nil {
		t.Fatalf("probe-path acquire: %v", err)
	}
	releases = append(releases, r)
	defer func() {
		for _, rel := range releases {
			rel()
		}
	}()
	if got := shared.InFlight(sni); got != 3 {
		t.Fatalf("InFlight = %d, want 3 combined across both paths", got)
	}
	// A fourth acquire through EITHER path must be refused.
	if _, err := DefaultHandshakeBudget.Acquire(ctx, sni); err == nil {
		t.Fatal("fourth acquire via the censor path must be refused: the cap is combined, not per path")
	}
	if _, err := probe.DefaultHandshakeLimiter.Acquire(ctx, sni); err == nil {
		t.Fatal("fourth acquire via the probe path must be refused: the cap is combined, not per path")
	}
}

// TestProbeEventsMaskNamesAndUseSharedBudget runs the real Prober
// against a local listener with the shared default budget saturated
// for the target's SNI: the attempt must record the budget refusal
// (not a fourth ClientHello), and every event detail — the DNS
// resolution and the budget refusal — must carry masked names only
// (CENSOR-SURV review, §6: raw IP in the DNS event, raw SNI in the
// budget refusal).
func TestProbeEventsMaskNamesAndUseSharedBudget(t *testing.T) {
	swapSharedBudget(t)
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
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
	host, portStr, _ := net.SplitHostPort(ln.Addr().String())
	port, _ := strconv.Atoi(portStr)

	// Saturate the shared budget for the SNI the prober will use
	// (Target.SNI empty → the host itself).
	var releases []func()
	for i := 0; i < 3; i++ {
		r, err := DefaultHandshakeBudget.Acquire(context.Background(), host)
		if err != nil {
			t.Fatalf("saturating acquire %d: %v", i, err)
		}
		releases = append(releases, r)
	}
	defer func() {
		for _, rel := range releases {
			rel()
		}
	}()

	p := &Prober{} // Budget nil → the shared default instance.
	a := p.Probe(context.Background(), Target{Host: host, Port: port, TLS: true})

	var sawMaskedDNS, sawBudget bool
	for _, e := range a.Events {
		if strings.Contains(e.Detail, "127.0.0.1") {
			t.Fatalf("event %+v leaks the raw IP in its detail", e)
		}
		if e.Stage == StageDNS && e.What == WhatResolved && e.Detail == "127.***" {
			sawMaskedDNS = true
		}
		if e.Stage == StageTLS && strings.Contains(e.Detail, "handshake budget") && strings.Contains(e.Detail, "127.***") {
			sawBudget = true
		}
	}
	if !sawMaskedDNS {
		t.Fatalf("want a DNS resolved event with masked detail 127.***, got %+v", a.Events)
	}
	if !sawBudget {
		t.Fatalf("want a masked handshake-budget TLS event from the shared budget, got %+v", a.Events)
	}
}

// TestDNSPoisoningMaskedResolvedComparison: the detector's
// ExpectedIP comparison must keep working now that the prober
// records resolved addresses masked. A masked resolution whose
// first octet matches the expected address is not a mismatch; a
// different first octet still names poisoning, and the evidence
// prints masked forms only.
func TestDNSPoisoningMaskedResolvedComparison(t *testing.T) {
	mk := func(resolved, expected string) Attempt {
		a := withStart(mkAttempt())
		a.ExpectedIP = expected
		a.Events = []Event{
			ev(0, StageDNS, WhatResolved, resolved),
			ev(50*time.Millisecond, StageDNS, WhatError, "nxdomain"),
		}
		return a
	}
	// Same first octet: masked "203.***" vs raw expected 203.0.113.99
	// must not be read as a mismatch (only the weak NXDOMAIN branch
	// remains, below the claim floor).
	if v := (Detector{}).Detect(mk("203.***", "203.0.113.99")); v.Kind == KindDNSPoisoning {
		t.Fatalf("masked same-octet resolution must not claim poisoning, got %+v", v)
	}
	// Different first octet: poisoning, with masked evidence.
	v := (Detector{}).Detect(mk("198.***", "203.0.113.99"))
	if v.Kind != KindDNSPoisoning {
		t.Fatalf("masked different-octet resolution must claim poisoning, got %+v", v)
	}
	joined := strings.Join(v.Evidence, "\n")
	if strings.Contains(joined, "203.0.113.99") || strings.Contains(joined, "198.51") {
		t.Fatalf("poisoning evidence leaks a raw address: %q", joined)
	}
}
