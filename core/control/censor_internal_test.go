package control

import (
	"testing"

	"github.com/levvs-one/sora-client/core/censor"
	censorv1 "github.com/levvs-one/sora-client/core/gen/sora/censor/v1"
)

// TestCensorKindToProtoExhaustive locks the core→wire kind mapping
// (SW4): every detector kind has a distinct wire value. KindDataStall in
// particular regressed once already — it fell into the default and
// reached clients as UNKNOWN, erasing the TSPU-freeze diagnosis.
func TestCensorKindToProtoExhaustive(t *testing.T) {
	cases := map[censor.Kind]censorv1.CensorshipKind{
		censor.KindNoInterference:   censorv1.CensorshipKind_CENSORSHIP_KIND_NO_INTERFERENCE,
		censor.KindRSTInjection:     censorv1.CensorshipKind_CENSORSHIP_KIND_RST_INJECTION,
		censor.KindHandshakeTimeout: censorv1.CensorshipKind_CENSORSHIP_KIND_HANDSHAKE_TIMEOUT,
		censor.KindDNSPoisoning:     censorv1.CensorshipKind_CENSORSHIP_KIND_DNS_POISONING,
		censor.KindSNIBlocking:      censorv1.CensorshipKind_CENSORSHIP_KIND_SNI_BLOCKING,
		censor.KindIPBlocking:       censorv1.CensorshipKind_CENSORSHIP_KIND_IP_BLOCKING,
		censor.KindDataStall:        censorv1.CensorshipKind_CENSORSHIP_KIND_DATA_STALL,
	}
	for kind, want := range cases {
		if got := censorKindToProto(kind); got != want {
			t.Errorf("censorKindToProto(%v) = %v, want %v", kind, got, want)
		}
	}
	if got := censorKindToProto(censor.KindUnknown); got != censorv1.CensorshipKind_CENSORSHIP_KIND_UNKNOWN {
		t.Errorf("censorKindToProto(KindUnknown) = %v, want UNKNOWN", got)
	}
}

// TestCensorVerdictToProtoDataStall checks the whole verdict conversion
// for the freeze signature: kind, confidence, explanation and evidence
// all survive, and the wire kind is the dedicated DATA_STALL value.
func TestCensorVerdictToProtoDataStall(t *testing.T) {
	v := censorVerdictToProto(censor.Verdict{
		Kind:        censor.KindDataStall,
		Confidence:  0.7,
		Explanation: "session went silent after data flowed",
		Evidence:    []string{"16 KiB received, then 8s of silence"},
	})
	if v.GetKind() != censorv1.CensorshipKind_CENSORSHIP_KIND_DATA_STALL {
		t.Fatalf("kind = %v, want DATA_STALL", v.GetKind())
	}
	if v.GetConfidence() != 0.7 {
		t.Errorf("confidence = %v, want 0.7", v.GetConfidence())
	}
	if v.GetExplanation() == "" || len(v.GetEvidence()) != 1 {
		t.Errorf("verdict lost explanation/evidence: %+v", v)
	}
}
