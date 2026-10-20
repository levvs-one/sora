package engine

import "testing"

// TestRealityMuxExcludesVisionOnEveryEngine pins PASS3 deep S3a:
// sing-box and mihomo DO implement the vision flow, so a vision flow
// suppresses the REALITY mux default through the shared predicate —
// no renderer may emit mux+vision together.
func TestRealityMuxExcludesVision(t *testing.T) {
	base := Outbound{
		Protocol: ProtocolVLESS,
		TLS:      TLS{Reality: true},
	}
	for _, flow := range []string{"xtls-rprx-vision", "xtls-rprx-vision-udp443"} {
		o := base
		o.Flow = flow
		if RealityMux(o, MuxOptions{}) {
			t.Errorf("flow %q: mux must be suppressed under vision", flow)
		}
	}
	if !RealityMux(base, MuxOptions{}) {
		t.Error("REALITY without a vision flow must keep the mux default")
	}
	o := base
	o.Flow = "xtls-rprx-vision"
	if RealityMux(o, MuxOptions{Disabled: true}) {
		t.Error("Disabled must suppress mux regardless of flow")
	}
}

// TestHasVLESSEncryption pins the boundary the XTLS flow rules key
// off (PASS3 deep S3b): only a non-empty, non-"none" Encryption
// string lifts the TCP-only restriction on vision flows.
func TestHasVLESSEncryption(t *testing.T) {
	for _, enc := range []string{"", "none"} {
		if (Outbound{Encryption: enc}).HasVLESSEncryption() {
			t.Errorf("Encryption %q must not count as VLESS Encryption", enc)
		}
	}
	o := Outbound{Encryption: "mlkem768x25519plus.native.0rtt.AAAA"}
	if !o.HasVLESSEncryption() {
		t.Error("a real VLESS Encryption string must count")
	}
}
