package engine

import (
	"strings"
	"testing"
)

// CENSOR-P2: plan-level honesty for the WS/HTTPUpgrade/gRPC transports
// and the VMess/Trojan protocols. Every field a renderer would drop
// silently must fail here instead.

func p2Outbound(proto Protocol) Outbound {
	o := Outbound{ID: "p2", Name: "p2", Protocol: proto, Server: "edge.example.com", Port: 443}
	switch proto {
	case ProtocolVMess:
		o.UUID = "b831381d-6324-4d53-ad4f-8cda48b30811"
	case ProtocolTrojan:
		o.Password = "pw"
	}
	return o
}

func TestValidateGRPCFieldsNeedGRPC(t *testing.T) {
	for _, tc := range []struct {
		name   string
		mutate func(*Transport)
	}{
		{"service on ws", func(tr *Transport) { tr.Type, tr.Service = "ws", "tun" }},
		{"authority on ws", func(tr *Transport) { tr.Type, tr.GRPCAuthority = "ws", "a.example.com" }},
		{"multi on tcp", func(tr *Transport) { tr.Type, tr.GRPCMultiMode = "tcp", true }},
		{"user agent on httpupgrade", func(tr *Transport) { tr.Type, tr.GRPCUserAgent = "httpupgrade", "ua" }},
	} {
		o := p2Outbound(ProtocolTrojan)
		tc.mutate(&o.Transport)
		if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "needs the grpc transport") {
			t.Errorf("%s: Validate = %v, want a grpc-transport error", tc.name, err)
		}
	}
	o := p2Outbound(ProtocolTrojan)
	o.Transport = Transport{Type: "grpc", Service: "tun", GRPCAuthority: "a.example.com", GRPCMultiMode: true, GRPCUserAgent: "ua/1.0"}
	if err := o.Validate(); err != nil {
		t.Fatalf("full grpc field set: Validate = %v", err)
	}
}

func TestValidateEarlyDataHeaderName(t *testing.T) {
	o := p2Outbound(ProtocolVMess)
	o.Transport = Transport{Type: "ws", Path: "/ws", EarlyDataHeaderName: "X-Early"}
	if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "without early data") {
		t.Fatalf("header name without early data: Validate = %v", err)
	}
	o.Transport.EarlyData = 2048
	if err := o.Validate(); err != nil {
		t.Fatalf("header name with early data: Validate = %v", err)
	}
	o.Transport.EarlyDataHeaderName = "Bad Header"
	if err := o.Validate(); err == nil {
		t.Fatal("unsafe header name must fail")
	}
}

func TestValidateVMessSecurityWhitelist(t *testing.T) {
	for _, cipher := range []string{"", "auto", "aes-128-gcm", "chacha20-poly1305", "none", "zero"} {
		o := p2Outbound(ProtocolVMess)
		o.Cipher = cipher
		if err := o.Validate(); err != nil {
			t.Errorf("security %q: Validate = %v", cipher, err)
		}
	}
	// aes-128-ctr is refused by the pinned sing-box and mihomo at load
	// and silently ignored by Xray; a nonsense value likewise.
	for _, cipher := range []string{"aes-128-ctr", "bogus-cipher", "aes-256-gcm"} {
		o := p2Outbound(ProtocolVMess)
		o.Cipher = cipher
		if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "vmess security") {
			t.Errorf("security %q: Validate = %v, want a vmess security error", cipher, err)
		}
	}
	o := p2Outbound(ProtocolVMess)
	o.UUID = ""
	if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "vmess needs a uuid") {
		t.Fatalf("vmess without uuid: Validate = %v", err)
	}
}

func TestValidateTrojanPassword(t *testing.T) {
	o := p2Outbound(ProtocolTrojan)
	o.Password = ""
	if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "trojan needs a password") {
		t.Fatalf("trojan without password: Validate = %v", err)
	}
}

func TestWarningsEarlyData(t *testing.T) {
	o := p2Outbound(ProtocolVMess)
	o.Transport = Transport{Type: "ws", Path: "/ws", EarlyData: 2048}
	found := false
	for _, w := range o.Warnings() {
		if w == "websocket-early-data-0rtt" {
			found = true
		}
	}
	if !found {
		t.Fatalf("Warnings = %v, want websocket-early-data-0rtt", o.Warnings())
	}
}

func TestCatalogGRPCGates(t *testing.T) {
	mk := func() *Plan {
		o := p2Outbound(ProtocolTrojan)
		o.Transport = Transport{Type: "grpc", Service: "tun", GRPCAuthority: "a.example.com", GRPCMultiMode: true}
		return &Plan{SessionID: "p2", Outbounds: []Outbound{o}}
	}
	for _, kind := range []Kind{KindSingBox, KindMihomo} {
		missing := Catalog[kind].Missing(mk())
		found := false
		for _, m := range missing {
			if strings.Contains(m, "gRPC authority/multi-mode") {
				found = true
			}
		}
		if !found {
			t.Errorf("%s: Missing = %v, want the gRPC authority/multi-mode gate", kind, missing)
		}
	}
	if missing := Catalog[KindXray].Missing(mk()); len(missing) != 0 {
		t.Errorf("xray: Missing = %v, want none for its own gRPC fields", missing)
	}
	// User agent alone: mihomo carries it, sing-box does not.
	o := p2Outbound(ProtocolTrojan)
	o.Transport = Transport{Type: "grpc", Service: "tun", GRPCUserAgent: "ua/1.0"}
	p := &Plan{SessionID: "p2", Outbounds: []Outbound{o}}
	if missing := Catalog[KindMihomo].Missing(p); len(missing) != 0 {
		t.Errorf("mihomo: Missing = %v, want none for grpc-user-agent", missing)
	}
	found := false
	for _, m := range Catalog[KindSingBox].Missing(p) {
		if strings.Contains(m, "gRPC user-agent") {
			found = true
		}
	}
	if !found {
		t.Errorf("sing-box: Missing = %v, want the gRPC user-agent gate", Catalog[KindSingBox].Missing(p))
	}
}

// Boundaries (owner's "мелочи" standard): values at the edges behave
// deliberately, not accidentally.
func TestCensorP2Boundaries(t *testing.T) {
	// Early data: 0 is off (renderers omit the key, pinned per engine),
	// a large value passes through as data — the pinned binaries accept
	// at least 1 MiB (sing-box check) / 16 MiB, so the plan invents no
	// cap of its own; the engines own the wire limit.
	o := p2Outbound(ProtocolVMess)
	o.Transport = Transport{Type: "ws", Path: "/ws", EarlyData: 1048576}
	if err := o.Validate(); err != nil {
		t.Fatalf("early data 1MiB: Validate = %v", err)
	}
	// Lengths: a maximum-size DNS host name (253 bytes), a long path
	// and a dotted service name all pass through untruncated.
	host := strings.Repeat("a", 63) + "." + strings.Repeat("b", 63) + "." +
		strings.Repeat("c", 63) + "." + strings.Repeat("d", 61) // 253 bytes
	o.Transport = Transport{Type: "ws", Path: "/" + strings.Repeat("p", 1024), Host: host}
	if err := o.Validate(); err != nil {
		t.Fatalf("long path/host: Validate = %v", err)
	}
	// Empty vs absent: an empty gRPC service name is legal data (the
	// engines apply their default service) and must validate; each
	// renderer omits the key rather than emitting an empty one.
	o2 := p2Outbound(ProtocolTrojan)
	o2.Transport = Transport{Type: "grpc"}
	if err := o2.Validate(); err != nil {
		t.Fatalf("empty grpc service: Validate = %v", err)
	}
}
