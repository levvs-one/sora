package stealth

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func codes(rep Report) map[string]Severity {
	m := map[string]Severity{}
	for _, f := range rep.Findings {
		m[f.Code] = f.Severity
	}
	return m
}

func planWith(o engine.Outbound) *engine.Plan {
	p := enginetest.Plan()
	p.Outbounds = []engine.Outbound{o}
	p.Groups = nil
	p.Rules = nil
	return p
}

func TestGradePlainWireGuard(t *testing.T) {
	rep := Grade(planWith(enginetest.Outbound(engine.ProtocolWireGuard)))
	if got := codes(rep)["wg/plain"]; got != SeverityHigh {
		t.Fatalf("plain WireGuard should be high risk, got %q (score %d)", got, rep.Score)
	}
	if rep.Score > 100-deductHigh {
		t.Fatalf("score %d ignores the high finding", rep.Score)
	}
}

func TestGradeAmneziaWG2(t *testing.T) {
	// enginetest.AmneziaWG uses 2.0 ranges for H1/H2 but static H3/H4.
	rep := Grade(planWith(enginetest.AmneziaWG()))
	c := codes(rep)
	if _, ok := c["wg/plain"]; ok {
		t.Fatal("AmneziaWG must not be graded as plain WireGuard")
	}
	if c["wg/awg-static-headers"] != SeverityMedium {
		t.Fatalf("static H3/H4 should warn, got %v", c)
	}
	if rep.Score >= 100 {
		t.Fatalf("static headers should cost score, got %d", rep.Score)
	}
}

func TestGradeReality(t *testing.T) {
	rep := Grade(planWith(enginetest.Outbound(engine.ProtocolVLESS)))
	if got := codes(rep)["tls/reality"]; got != SeverityInfo {
		t.Fatalf("REALITY should be informational, got %q", got)
	}
	if rep.Score != 100 {
		t.Fatalf("REALITY plan should score 100, got %d", rep.Score)
	}
}

func TestGradeTLSWithoutHardening(t *testing.T) {
	rep := Grade(planWith(enginetest.Outbound(engine.ProtocolVMess)))
	c := codes(rep)
	if c["tls/no-utls"] != SeverityMedium {
		t.Fatalf("missing uTLS fingerprint should warn, got %v", c)
	}
	if c["tls/no-fragment"] != SeverityMedium {
		t.Fatalf("missing fragment should warn, got %v", c)
	}
	want := 100 - 2*deductMedium
	if rep.Score != want {
		t.Fatalf("score = %d, want %d", rep.Score, want)
	}
}

func TestGradeStaleFingerprint(t *testing.T) {
	// An explicitly pinned outdated Chrome parrot is a likely cause of
	// blocking (TSPU field tests), not a cosmetic issue.
	o := enginetest.Outbound(engine.ProtocolVMess)
	o.TLS.Fingerprint = "hellochrome_133"
	rep := Grade(planWith(o))
	if got := codes(rep)["tls/fp-stale"]; got != SeverityHigh {
		t.Fatalf("stale pinned parrot should be high risk, got %q", got)
	}
	// The fresh auto parrot must not warn.
	o.TLS.Fingerprint = "hellochrome_auto"
	if _, ok := codes(Grade(planWith(o)))["tls/fp-stale"]; ok {
		t.Fatal("fresh auto parrot should not warn")
	}
	// The portable alias cannot be judged stale without measuring the
	// engine's bytes (that is the JA4 self-test's job).
	o.TLS.Fingerprint = "chrome"
	if _, ok := codes(Grade(planWith(o)))["tls/fp-stale"]; ok {
		t.Fatal("alias fingerprint should not be judged stale by name")
	}
}

func TestGradeNoPQKeyShare(t *testing.T) {
	o := enginetest.Outbound(engine.ProtocolVMess)
	o.TLS.Fingerprint = "hellochrome_120"
	if got := codes(Grade(planWith(o)))["tls/no-pq-keyshare"]; got != SeverityMedium {
		t.Fatalf("pre-PQ parrot should warn, got %q", got)
	}
	o.TLS.Fingerprint = "hellochrome_131"
	if _, ok := codes(Grade(planWith(o)))["tls/no-pq-keyshare"]; ok {
		t.Fatal("Chrome 131+ parrot must not warn about PQ key share")
	}
}

func TestGradeRandomizedFingerprint(t *testing.T) {
	o := enginetest.Outbound(engine.ProtocolVMess)
	o.TLS.Fingerprint = "randomized"
	if got := codes(Grade(planWith(o)))["tls/fp-randomized"]; got != SeverityLow {
		t.Fatalf("randomized fingerprint should warn low, got %q", got)
	}
	// Randomized is worse than exact imitation, better than nothing:
	// it must not trigger the missing-fingerprint finding.
	if _, ok := codes(Grade(planWith(o)))["tls/no-utls"]; ok {
		t.Fatal("explicit fingerprint should not warn as missing")
	}
}

func TestGradeStaleRealityFingerprint(t *testing.T) {
	// REALITY's fingerprint is the decoy handshake DPI sees: a stale
	// pinned parrot is just as bad there.
	o := enginetest.Outbound(engine.ProtocolVLESS)
	o.TLS.Fingerprint = "hellochrome_131"
	if got := codes(Grade(planWith(o)))["tls/fp-stale"]; got != SeverityHigh {
		t.Fatalf("stale REALITY parrot should be high risk, got %q", got)
	}
}

func TestGradeFragmentClearsFinding(t *testing.T) {
	p := planWith(enginetest.Outbound(engine.ProtocolVMess))
	p.Options.Fragment = engine.Fragment{Enabled: true, Packets: "tlshello"}
	rep := Grade(p)
	if _, ok := codes(rep)["tls/no-fragment"]; ok {
		t.Fatal("enabled fragment should clear the no-fragment finding")
	}
}

func TestGradeShadowsocks(t *testing.T) {
	rep := Grade(planWith(enginetest.Outbound(engine.ProtocolShadowsocks)))
	if got := codes(rep)["ss/no-obfs"]; got != SeverityMedium {
		t.Fatalf("plain Shadowsocks should warn, got %q", got)
	}
	o := enginetest.Outbound(engine.ProtocolShadowsocks)
	o.Obfs, o.ObfsParam = "tls", "cdn.example.com"
	rep = Grade(planWith(o))
	if got := codes(rep)["ss/obfs"]; got != SeverityInfo {
		t.Fatalf("obfuscated Shadowsocks should be informational, got %q", got)
	}
	if rep.Score != 100 {
		t.Fatalf("obfuscated Shadowsocks should score 100, got %d", rep.Score)
	}
}

func TestGradeChainedHidesInnerHandshake(t *testing.T) {
	wg := enginetest.Outbound(engine.ProtocolWireGuard)
	wg.ID = "wg"
	wg.Via = "ss"
	ss := enginetest.Outbound(engine.ProtocolShadowsocks)
	ss.ID = "ss"
	p := planWith(wg)
	p.Outbounds = append(p.Outbounds, ss)
	rep := Grade(p)
	c := codes(rep)
	if _, ok := c["wg/plain"]; ok {
		t.Fatal("chained WireGuard handshake is encapsulated; only the outer leg is visible")
	}
	if c["chain/via"] != SeverityInfo {
		t.Fatalf("chain should be noted, got %v", c)
	}
	// The visible leg is plain Shadowsocks: medium.
	if rep.Score != 100-deductMedium {
		t.Fatalf("score = %d, want %d", rep.Score, 100-deductMedium)
	}
}

func TestGradeBypassIsInformational(t *testing.T) {
	o := engine.Outbound{ID: "bypass", Name: "zapret", Protocol: engine.ProtocolBypass,
		Bypass: &engine.BypassStrategy{SplitPos: []string{"1"}, Disorder: true}}
	rep := Grade(planWith(o))
	if len(rep.Findings) != 1 || rep.Findings[0].Severity != SeverityInfo {
		t.Fatalf("bypass should yield one informational finding, got %+v", rep.Findings)
	}
	if rep.Score != 100 {
		t.Fatalf("score = %d, want 100", rep.Score)
	}
}

func TestGradeEmptyPlan(t *testing.T) {
	if rep := Grade(&engine.Plan{}); rep.Score != 100 || len(rep.Findings) != 0 {
		t.Fatalf("empty plan should score 100 cleanly, got %+v", rep)
	}
	if rep := Grade(nil); rep.Score != 100 {
		t.Fatalf("nil plan should score 100, got %d", rep.Score)
	}
}

func TestGradeWorstOutboundWins(t *testing.T) {
	p := planWith(enginetest.Outbound(engine.ProtocolVLESS))
	p.Outbounds = append(p.Outbounds, enginetest.Outbound(engine.ProtocolWireGuard))
	if rep := Grade(p); rep.Score != 100-deductHigh {
		t.Fatalf("plan scores as its weakest outbound: %d", rep.Score)
	}
}
