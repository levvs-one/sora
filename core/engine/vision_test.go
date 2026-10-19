package engine

import "testing"

// TestApplyAutoVision locks the S2 plan-level rule: VLESS/Trojan over
// TCP with TLS/REALITY and no explicit flow get xtls-rprx-vision, and
// the fact is recorded in FlowAuto. Everything else is left alone —
// most importantly a manually configured flow.
func TestApplyAutoVision(t *testing.T) {
	cases := []struct {
		name      string
		o         Outbound
		wantFlow  string
		wantAuto  bool
		wantApply bool
	}{
		{
			name:      "vless reality tcp empty flow gets vision",
			o:         Outbound{Protocol: ProtocolVLESS, Transport: Transport{Type: "tcp"}, TLS: TLS{Enabled: true, Reality: true}},
			wantFlow:  VisionFlow,
			wantAuto:  true,
			wantApply: true,
		},
		{
			name:      "vless tls tcp empty flow gets vision",
			o:         Outbound{Protocol: ProtocolVLESS, Transport: Transport{Type: "tcp"}, TLS: TLS{Enabled: true}},
			wantFlow:  VisionFlow,
			wantAuto:  true,
			wantApply: true,
		},
		{
			name:      "empty transport counts as tcp",
			o:         Outbound{Protocol: ProtocolVLESS, TLS: TLS{Enabled: true, Reality: true}},
			wantFlow:  VisionFlow,
			wantAuto:  true,
			wantApply: true,
		},
		{
			name:      "trojan tls tcp empty flow gets vision",
			o:         Outbound{Protocol: ProtocolTrojan, Transport: Transport{Type: "tcp"}, TLS: TLS{Enabled: true}},
			wantFlow:  VisionFlow,
			wantAuto:  true,
			wantApply: true,
		},
		{
			name:      "manual flow is respected",
			o:         Outbound{Protocol: ProtocolVLESS, Transport: Transport{Type: "tcp"}, TLS: TLS{Enabled: true, Reality: true}, Flow: "xtls-rprx-vision-udp443"},
			wantFlow:  "xtls-rprx-vision-udp443",
			wantAuto:  false,
			wantApply: false,
		},
		{
			name:      "manual vision flow is respected",
			o:         Outbound{Protocol: ProtocolVLESS, Transport: Transport{Type: "tcp"}, TLS: TLS{Enabled: true, Reality: true}, Flow: VisionFlow},
			wantFlow:  VisionFlow,
			wantAuto:  false,
			wantApply: false,
		},
		{
			name:      "non-tcp transport is untouched",
			o:         Outbound{Protocol: ProtocolVLESS, Transport: Transport{Type: "ws"}, TLS: TLS{Enabled: true, Reality: true}},
			wantFlow:  "",
			wantAuto:  false,
			wantApply: false,
		},
		{
			name:      "xhttp transport is untouched",
			o:         Outbound{Protocol: ProtocolVLESS, Transport: Transport{Type: "xhttp"}, TLS: TLS{Enabled: true, Reality: true}},
			wantFlow:  "",
			wantAuto:  false,
			wantApply: false,
		},
		{
			name:      "no tls no vision",
			o:         Outbound{Protocol: ProtocolVLESS, Transport: Transport{Type: "tcp"}},
			wantFlow:  "",
			wantAuto:  false,
			wantApply: false,
		},
		{
			name:      "vmess is untouched",
			o:         Outbound{Protocol: ProtocolVMess, Transport: Transport{Type: "tcp"}, TLS: TLS{Enabled: true}},
			wantFlow:  "",
			wantAuto:  false,
			wantApply: false,
		},
		{
			name:      "shadowsocks is untouched",
			o:         Outbound{Protocol: ProtocolShadowsocks, Transport: Transport{Type: "tcp"}, TLS: TLS{Enabled: true}},
			wantFlow:  "",
			wantAuto:  false,
			wantApply: false,
		},
		{
			name:      "hysteria2 is untouched",
			o:         Outbound{Protocol: ProtocolHysteria2, TLS: TLS{Enabled: true}},
			wantFlow:  "",
			wantAuto:  false,
			wantApply: false,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			o := tc.o
			if got := o.ApplyAutoVision(); got != tc.wantApply {
				t.Errorf("ApplyAutoVision() = %v, want %v", got, tc.wantApply)
			}
			if o.Flow != tc.wantFlow {
				t.Errorf("Flow = %q, want %q", o.Flow, tc.wantFlow)
			}
			if o.FlowAuto != tc.wantAuto {
				t.Errorf("FlowAuto = %v, want %v", o.FlowAuto, tc.wantAuto)
			}
		})
	}
}

// TestApplyAutoVisionKeepsVisionVariantHonest guards the IsVisionFlow
// contract the auto-vision relies on: the flow it assigns must count as
// a vision flow, and an empty flow must not.
func TestApplyAutoVisionKeepsVisionVariantHonest(t *testing.T) {
	o := Outbound{Protocol: ProtocolVLESS, Transport: Transport{Type: "tcp"}, TLS: TLS{Enabled: true, Reality: true}}
	o.ApplyAutoVision()
	if !IsVisionFlow(o.Flow) {
		t.Errorf("auto-assigned flow %q is not recognized as vision", o.Flow)
	}
	if IsVisionFlow("") {
		t.Error("empty flow must not count as vision")
	}
}
