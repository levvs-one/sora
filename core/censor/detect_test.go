package censor

import (
	"strings"
	"testing"
	"time"

	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
)

func mkAttempt() Attempt {
	return Attempt{
		ServerID: "srv1",
		Target:   Target{Host: "vpn.example.com", Port: 443, SNI: "vpn.example.com", TLS: true, Protocol: "vless"},
	}
}

func ev(at time.Duration, stage Stage, what What, detail string) Event {
	return Event{At: time.Unix(1000, 0).Add(at), Stage: stage, What: what, Detail: detail}
}

func withStart(a Attempt) Attempt {
	a.StartedAt = time.Unix(1000, 0)
	return a
}

func TestDetectSNIBlocking(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(100*time.Millisecond, StageTCP, WhatConnected, ""),
		ev(120*time.Millisecond, StageTLS, WhatSent, "client_hello"),
		ev(400*time.Millisecond, StageTLS, WhatRemoteReset, ""),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindSNIBlocking {
		t.Fatalf("kind = %v, want sni_blocking", v.Kind)
	}
	if v.Confidence < 0.75 {
		t.Fatalf("confidence = %v, want >= 0.75 for the textbook SNI signature", v.Confidence)
	}
	if !v.HasProfile || v.Profile.Preset != obfsv1.ObfsPreset_OBFS_PRESET_BALANCED {
		t.Fatalf("profile = %+v, want the balanced obfuscation preset", v.Profile)
	}
	if v.Band() != "high" {
		t.Fatalf("band = %q, want high", v.Band())
	}
}

func TestDetectRSTInjectionMidStream(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(100*time.Millisecond, StageTCP, WhatConnected, ""),
		ev(150*time.Millisecond, StageTLS, WhatSent, "client_hello"),
		ev(300*time.Millisecond, StageTLS, WhatReceived, "server_hello"),
		ev(500*time.Millisecond, StageApp, WhatSent, "vmess_handshake"),
		ev(600*time.Millisecond, StageApp, WhatRemoteReset, ""),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindRSTInjection {
		t.Fatalf("kind = %v, want rst_injection", v.Kind)
	}
}

func TestDetectHandshakeTimeout(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(100*time.Millisecond, StageTCP, WhatConnected, ""),
		ev(120*time.Millisecond, StageTLS, WhatSent, "client_hello"),
		ev(10*time.Second, StageTLS, WhatLocalTimeout, ""),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindHandshakeTimeout {
		t.Fatalf("kind = %v, want handshake_timeout", v.Kind)
	}
}

func TestDetectDNSPoisoningKnownGood(t *testing.T) {
	a := withStart(mkAttempt())
	a.KnownGoodHost = true
	a.Events = []Event{
		ev(50*time.Millisecond, StageDNS, WhatError, "nxdomain"),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindDNSPoisoning {
		t.Fatalf("kind = %v, want dns_poisoning", v.Kind)
	}
	if v.Confidence < 0.75 {
		t.Fatalf("confidence = %v, want high for nxdomain on a known-good host", v.Confidence)
	}
}

func TestDetectDNSPoisoningExpectedIPMismatch(t *testing.T) {
	a := withStart(mkAttempt())
	a.ExpectedIP = "203.0.113.7"
	a.Events = []Event{
		ev(50*time.Millisecond, StageDNS, WhatResolved, "198.51.100.99"),
		ev(60*time.Millisecond, StageDNS, WhatError, "stopped"),
	}
	// Resolved to an unexpected address then failed: the mismatch is the
	// signal even though resolution "succeeded".
	v := Detector{}.Detect(a)
	if v.Kind != KindDNSPoisoning {
		t.Fatalf("kind = %v, want dns_poisoning on address mismatch", v.Kind)
	}
}

func TestDetectIPBlockingTimeout(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(8*time.Second, StageTCP, WhatLocalTimeout, ""),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindIPBlocking {
		t.Fatalf("kind = %v, want ip_blocking", v.Kind)
	}
	// A SYN timeout is genuinely ambiguous: never confident.
	if v.Confidence >= 0.75 {
		t.Fatalf("confidence = %v, want < 0.75: silence is not proof of filtering", v.Confidence)
	}
	if !strings.Contains(strings.ToLower(v.Explanation), "may be down") {
		t.Fatalf("explanation must admit the host may simply be down, got %q", v.Explanation)
	}
}

func TestDetectRefusedIsNotCensorship(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(30*time.Millisecond, StageTCP, WhatError, "refused"),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindNoInterference {
		t.Fatalf("kind = %v, want no_interference: a refusing server is evidence against censorship", v.Kind)
	}
	if v.HasProfile {
		t.Fatalf("no_interference must not suggest an obfuscation preset, got %+v", v.Profile)
	}
}

// Negative: a certificate failure must never be claimed as censorship.
func TestDetectCertFailureStaysUnknown(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(100*time.Millisecond, StageTCP, WhatConnected, ""),
		ev(120*time.Millisecond, StageTLS, WhatSent, "client_hello"),
		ev(300*time.Millisecond, StageTLS, WhatError, "certificate: unknown authority"),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindUnknown {
		t.Fatalf("kind = %v, want unknown: cert failures are indistinguishable from portals", v.Kind)
	}
	if v.Confidence >= minClaimConfidence {
		t.Fatalf("confidence = %v, want below claim floor", v.Confidence)
	}
	if v.HasProfile {
		t.Fatalf("unknown verdict must not suggest a preset")
	}
}

// Negative: no events at all must not produce a claim.
func TestDetectEmptyAttemptStaysUnknown(t *testing.T) {
	v := Detector{}.Detect(Attempt{ServerID: "srv1"})
	if v.Kind != KindUnknown {
		t.Fatalf("kind = %v, want unknown for an empty attempt", v.Kind)
	}
	if v.Confidence >= minClaimConfidence {
		t.Fatalf("confidence = %v, an empty attempt must not clear the claim floor", v.Confidence)
	}
}

// Negative: NXDOMAIN for a name never seen working is weak evidence.
func TestDetectNXDomainUnknownHostStaysLow(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(50*time.Millisecond, StageDNS, WhatError, "nxdomain"),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindUnknown {
		t.Fatalf("kind = %v, want unknown: the name may simply not exist", v.Kind)
	}
}

// Negative: a late reset with no server bytes is stranger than SNI blocking;
// the detector must not stretch the signature to fit.
func TestDetectLateResetNotClaimedAsSNI(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(100*time.Millisecond, StageTCP, WhatConnected, ""),
		ev(120*time.Millisecond, StageTLS, WhatSent, "client_hello"),
		ev(30*time.Second, StageTLS, WhatRemoteReset, ""),
	}
	v := Detector{}.Detect(a)
	if v.Kind == KindSNIBlocking {
		t.Fatalf("kind = sni_blocking for a reset 30s after ClientHello: signature stretched too far")
	}
}

// A prescription must exist only where obfuscation helps. DNS poisoning is
// fixed by encrypted DNS and an unreachable IP by another server —
// suggesting a handshake preset there would be decoration, not a solution.
func TestNoProfileWhereObfuscationCannotHelp(t *testing.T) {
	dns := withStart(mkAttempt())
	dns.KnownGoodHost = true
	dns.Events = []Event{ev(50*time.Millisecond, StageDNS, WhatError, "nxdomain")}
	if v := (Detector{}).Detect(dns); v.HasProfile {
		t.Fatalf("dns_poisoning must not suggest an obfuscation preset, got %+v", v.Profile)
	}
	ip := withStart(mkAttempt())
	ip.Events = []Event{ev(8*time.Second, StageTCP, WhatLocalTimeout, "")}
	if v := (Detector{}).Detect(ip); v.HasProfile {
		t.Fatalf("ip_blocking must not suggest an obfuscation preset, got %+v", v.Profile)
	}
}

// Single-attempt confidence is capped: one observation is never certainty.
func TestDetectConfidenceCapped(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(100*time.Millisecond, StageTCP, WhatConnected, ""),
		ev(120*time.Millisecond, StageTLS, WhatSent, "client_hello"),
		ev(400*time.Millisecond, StageTLS, WhatRemoteReset, ""),
	}
	v := Detector{}.Detect(a)
	if v.Confidence > singleAttemptCap {
		t.Fatalf("confidence = %v, want <= %v", v.Confidence, singleAttemptCap)
	}
}

func TestDetectDataResetModest(t *testing.T) {
	a := withStart(mkAttempt())
	rx := ev(5*time.Second, StageData, WhatReceived, "")
	rx.BytesIn = 1024
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(100*time.Millisecond, StageTCP, WhatConnected, ""),
		rx,
		ev(70*time.Second, StageData, WhatRemoteReset, ""),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindRSTInjection {
		t.Fatalf("kind = %v, want rst_injection", v.Kind)
	}
	if v.Confidence >= 0.75 {
		t.Fatalf("confidence = %v, want modest: NAT timeouts also kill idle sessions", v.Confidence)
	}
}

// Negative: the SNI signature without any timing is ordering alone. A
// missing clock must not read as "instant": the time-windowed rules stay
// silent and the verdict is Unknown.
func TestDetectSNISignatureWithoutTimingStaysUnknown(t *testing.T) {
	a := mkAttempt() // no StartedAt, no event timestamps
	a.Events = []Event{
		{Stage: StageDNS, What: WhatResolved, Detail: "203.0.113.7"},
		{Stage: StageTCP, What: WhatConnected},
		{Stage: StageTLS, What: WhatSent, Detail: "client_hello"},
		{Stage: StageTLS, What: WhatRemoteReset},
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindUnknown {
		t.Fatalf("kind = %v, want unknown: no timing, no timing-based claim", v.Kind)
	}
}

// A reset that lands while the dial is still in flight never saw an
// established connection: the detector may note it, but modestly — a
// filtered port answers this way too.
func TestDetectDialTimeResetIsModest(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(200*time.Millisecond, StageTCP, WhatRemoteReset, ""),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindRSTInjection {
		t.Fatalf("kind = %v, want rst_injection for a dial-time reset", v.Kind)
	}
	if v.Confidence < minClaimConfidence || v.Confidence >= 0.75 {
		t.Fatalf("confidence = %v, want modest: above the claim floor, below high", v.Confidence)
	}
	if !strings.Contains(strings.ToLower(v.Explanation), "ordinary failure") {
		t.Fatalf("explanation must hedge a dial-time reset, got %q", v.Explanation)
	}
}

// The reset window is anchored at the connect, not at the attempt start: a
// slow DNS lookup must not hide a fast post-connect reset.
func TestDetectPostConnectResetWindowAnchoredAtConnect(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(4*time.Second, StageTCP, WhatConnected, ""),
		ev(4200*time.Millisecond, StageTCP, WhatRemoteReset, ""),
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindRSTInjection {
		t.Fatalf("kind = %v, want rst_injection: the reset was immediate after the connect", v.Kind)
	}
	if v.Confidence < 0.5 {
		t.Fatalf("confidence = %v, want the full post-connect reading, not the modest dial-time one", v.Confidence)
	}
}

// If the server spoke before the reset, it is not SNI blocking — even with
// no byte counts, a RECEIVED event means the far end answered.
func TestDetectReceivedBeforeResetDefeatsSNIClaim(t *testing.T) {
	a := withStart(mkAttempt())
	a.Events = []Event{
		ev(0, StageDNS, WhatResolved, "203.0.113.7"),
		ev(100*time.Millisecond, StageTCP, WhatConnected, ""),
		ev(120*time.Millisecond, StageTLS, WhatSent, "client_hello"),
		ev(200*time.Millisecond, StageTLS, WhatReceived, "server_hello"),
		ev(400*time.Millisecond, StageTLS, WhatRemoteReset, ""),
	}
	v := Detector{}.Detect(a)
	if v.Kind == KindSNIBlocking {
		t.Fatalf("kind = sni_blocking although the server sent bytes first: overreach")
	}
}
