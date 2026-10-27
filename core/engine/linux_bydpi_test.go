package engine

import "testing"

func TestByeDPIIsASeparateServerlessPlan(t *testing.T) {
	p := &Plan{SessionID: "byedpi", Outbounds: []Outbound{{
		ID: "dpi", Protocol: Protocol("byedpi"), Bypass: &BypassStrategy{SplitPos: []string{"1"}},
	}}}
	if err := p.Validate(); err != nil {
		t.Fatalf("standalone ByeDPI plan rejected: %v", err)
	}
	if p.IsVPNTarget("dpi") {
		t.Fatal("a DPI proxy must not be accepted as a VPN-only extension target")
	}
	mixed := *p
	mixed.Outbounds = append(append([]Outbound(nil), p.Outbounds...), Outbound{ID: "vpn", Protocol: ProtocolSOCKS5, Server: "127.0.0.1", Port: 1080})
	if err := mixed.Validate(); err == nil {
		t.Fatal("a mixed plan must not select an ambiguous DPI backend")
	}
	chained := *p
	chained.Outbounds = append([]Outbound(nil), p.Outbounds...)
	chained.Outbounds[0].Via = "vpn"
	if err := chained.Validate(); err == nil {
		t.Fatal("a serverless DPI outbound cannot dial through another outbound")
	}
}
