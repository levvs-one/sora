package engine

import (
	"strings"
	"testing"
)

func echPlan() *Plan {
	return &Plan{SessionID: "s1", Outbounds: []Outbound{{
		ID: "o1", Protocol: ProtocolVLESS, Server: "203.0.113.7", Port: 443,
		TLS: TLS{Enabled: true, ServerName: "cdn.example.com", ECH: ECHConfig{Enabled: true}},
	}}}
}

func TestProbeMissingGatesByFact(t *testing.T) {
	p := echPlan()
	// No probe: the pin's expectations stand, nothing is gated.
	if got := ProbeMissing(p, KindXray, nil); len(got) != 0 {
		t.Errorf("no probe must gate nothing, got %v", got)
	}
	// A probe that ACCEPTED ECH gates nothing either.
	ok := &EngineProbe{ECH: ProbeAccepted}
	if got := ProbeMissing(p, KindXray, ok); len(got) != 0 {
		t.Errorf("accepted probe must gate nothing, got %v", got)
	}
	// A probe that REJECTED ECH on this binary gates it with a named
	// reason, even though the catalog claims the feature.
	bad := &EngineProbe{ECH: ProbeRejected}
	got := ProbeMissing(p, KindXray, bad)
	if len(got) != 1 || !strings.Contains(got[0], "probe:") {
		t.Fatalf("rejected probe must gate ECH with a probe-named reason, got %v", got)
	}
	// A rejected fingerprint spelling gates versioned parrots on
	// engines whose probe says so (sing-box rejects them at load).
	parrot := &Plan{Outbounds: []Outbound{{ID: "o1", Protocol: ProtocolVLESS,
		TLS: TLS{Reality: true, Fingerprint: "hellochrome_133"}}}}
	fpBad := &EngineProbe{Fingerprints: map[string]ProbeVerdict{"hellochrome_133": ProbeRejected}}
	got = ProbeMissing(parrot, KindSingBox, fpBad)
	// Two named reasons: the probe rejects the spelling AND the
	// engine class cannot spell versioned parrots at all.
	if len(got) != 2 || !strings.Contains(got[0]+got[1], "hellochrome_133") || !strings.Contains(got[0]+got[1], "probe:") {
		t.Errorf("rejected parrot spelling must be gated with both reasons, got %v", got)
	}
}

func TestSelectEngineProbedPrefersFact(t *testing.T) {
	p := echPlan()
	avail := []Availability{{Kind: KindXray, Usable: true}, {Kind: KindMihomo, Usable: true}}
	probes := map[Kind]*EngineProbe{
		KindXray:   {ECH: ProbeRejected},
		KindMihomo: {ECH: ProbeAccepted},
	}
	pref := []Kind{KindXray, KindMihomo}
	sel, err := SelectEngineProbed(p, avail, pref, probes)
	if err != nil {
		t.Fatal(err)
	}
	if sel.Kind != KindMihomo {
		t.Errorf("selected %s, want mihomo (the probe-carried engine)", sel.Kind)
	}
	// Every engine probe-rejected: the error names the probe reason.
	probes[KindMihomo] = &EngineProbe{ECH: ProbeRejected}
	if _, err := SelectEngineProbed(p, avail, pref, probes); err == nil {
		t.Error("all engines probe-rejected must fail selection")
	}
}
