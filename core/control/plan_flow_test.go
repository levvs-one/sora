package control

import (
	"errors"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/parser"
)

// stubResolver is a minimal resolver for the plan-path half of the
// consistency test.
type stubResolver map[string][]byte

func (s stubResolver) Get(reference string) ([]byte, error) {
	doc, ok := s[reference]
	if !ok {
		return nil, errors.New("control: stub secret not found")
	}
	return doc, nil
}

// linkSpec builds a minimal parser.OutboundSpec for flow tests.
func linkSpec(protocol, transport, security, flow string) parser.OutboundSpec {
	return parser.OutboundSpec{
		DisplayName: "t",
		Protocol:    protocol,
		Transport:   transport,
		Security:    security,
		Host:        "example.com",
		Port:        443,
		Flow:        flow,
	}
}

func TestOutboundToProtoFlowPassthrough(t *testing.T) {
	// An explicit flow from the link reaches the wire unchanged and is not
	// marked auto.
	wire := outboundToProto(linkSpec("vless", "tcp", "reality", "xtls-rprx-vision"), "ref")
	if wire.GetFlow() != "xtls-rprx-vision" {
		t.Fatalf("flow = %q, want xtls-rprx-vision", wire.GetFlow())
	}
	if wire.GetFlowAuto() {
		t.Fatal("flow_auto = true for a manual flow")
	}
}

func TestOutboundToProtoFlowAutoVision(t *testing.T) {
	// VLESS + TCP + REALITY without a flow: the effective flow is vision and
	// the badge flag is honest about who assigned it.
	for _, transport := range []string{"tcp", ""} {
		wire := outboundToProto(linkSpec("vless", transport, "reality", ""), "ref")
		if wire.GetFlow() != engine.VisionFlow {
			t.Fatalf("transport %q: flow = %q, want %q", transport, wire.GetFlow(), engine.VisionFlow)
		}
		if !wire.GetFlowAuto() {
			t.Fatalf("transport %q: flow_auto = false, want true", transport)
		}
	}
	// Same for Trojan + TLS.
	wire := outboundToProto(linkSpec("trojan", "tcp", "tls", ""), "ref")
	if wire.GetFlow() != engine.VisionFlow || !wire.GetFlowAuto() {
		t.Fatalf("trojan: flow = %q auto = %v", wire.GetFlow(), wire.GetFlowAuto())
	}
}

func TestOutboundToProtoManualFlowNeverOverwritten(t *testing.T) {
	// A manual flow (including the vision-udp443 variant) is respected as-is.
	wire := outboundToProto(linkSpec("vless", "tcp", "reality", "xtls-rprx-vision-udp443"), "ref")
	if wire.GetFlow() != "xtls-rprx-vision-udp443" {
		t.Fatalf("flow = %q, want the manual value untouched", wire.GetFlow())
	}
	if wire.GetFlowAuto() {
		t.Fatal("flow_auto = true for a manual flow")
	}
}

func TestOutboundToProtoFlowAutoNegative(t *testing.T) {
	cases := []struct {
		name      string
		protocol  string
		transport string
		security  string
	}{
		{"non-vless protocol", "shadowsocks", "tcp", "tls"},
		{"ws transport", "vless", "ws", "tls"},
		{"no tls or reality", "vless", "tcp", "none"},
		{"trojan without tls", "trojan", "tcp", "none"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			wire := outboundToProto(linkSpec(tc.protocol, tc.transport, tc.security, ""), "ref")
			if wire.GetFlow() != "" {
				t.Fatalf("flow = %q, want empty", wire.GetFlow())
			}
			if wire.GetFlowAuto() {
				t.Fatal("flow_auto = true, want false")
			}
		})
	}
}

func TestEffectiveFlowMatchesPlanLevel(t *testing.T) {
	// effectiveFlow (UI path) must agree with outboundFromProto (plan path):
	// the same spec through both must yield the same wire flow and badge.
	specs := []parser.OutboundSpec{
		linkSpec("vless", "tcp", "reality", ""),
		linkSpec("vless", "", "tls", ""),
		linkSpec("vless", "tcp", "reality", "xtls-rprx-vision"),
		linkSpec("trojan", "tcp", "tls", ""),
		linkSpec("vless", "ws", "tls", ""),
		linkSpec("ss", "tcp", "none", ""),
	}
	for i, spec := range specs {
		uiFlow, uiAuto := effectiveFlow(spec)
		// The real pipeline: the UI reads the proto fields, the plan
		// restores the flow from the credential document written at import.
		doc, err := credentialDocument(spec)
		if err != nil {
			t.Fatalf("case %d: credentialDocument: %v", i, err)
		}
		secrets := stubResolver{"ref": doc}
		wire := outboundToProto(spec, "ref")
		plan, err := outboundFromProto(0, wire, secrets)
		if err != nil {
			t.Fatalf("case %d: outboundFromProto: %v", i, err)
		}
		if plan.Flow != uiFlow || plan.FlowAuto != uiAuto {
			t.Fatalf("case %d (%+v): UI (%q,%v) != plan (%q,%v)",
				i, spec, uiFlow, uiAuto, plan.Flow, plan.FlowAuto)
		}
		if wire.GetFlow() != uiFlow || wire.GetFlowAuto() != uiAuto {
			t.Fatalf("case %d: proto fields (%q,%v) != effective (%q,%v)",
				i, wire.GetFlow(), wire.GetFlowAuto(), uiFlow, uiAuto)
		}
	}
}
