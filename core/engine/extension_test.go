package engine

import (
	"slices"
	"strings"
	"testing"
)

func TestExtensionProxyRejectsEveryDirectPath(t *testing.T) {
	for _, target := range []string{"vpn", "chain", "safe", "direct", "bypass", "winws", "provider", "mixed", "cycle", "unknown", "pass", "reject", "dns", "unsafe-chain"} {
		t.Run(target, func(t *testing.T) {
			p := &Plan{
				Outbounds: []Outbound{
					{ID: "vpn", Protocol: ProtocolSOCKS5, Server: "127.0.0.1", Port: 1080},
					{ID: "chain", Protocol: ProtocolSOCKS5, Server: "127.0.0.1", Port: 1081, Via: "vpn"},
					{ID: "bypass", Protocol: ProtocolBypass}, {ID: "winws", Protocol: ProtocolWinws}, {ID: "provider", Protocol: ProtocolXrayProfile},
					{ID: "unsafe-chain", Protocol: ProtocolSOCKS5, Via: "bypass"},
				},
				Groups: []Group{
					{Name: "safe", Type: GroupSelect, Outbounds: []string{"chain", "vpn"}},
					{Name: "mixed", Type: GroupSelect, Outbounds: []string{"vpn", "direct"}},
					{Name: "cycle", Type: GroupSelect, Outbounds: []string{"cycle"}},
				},
			}
			want := slices.Contains([]string{"vpn", "chain", "safe"}, target)
			if p.IsVPNTarget(target) != want {
				t.Fatalf("VPN-only check for %q = %v, want %v", target, !want, want)
			}
		})
	}
}

func TestExtensionProxyValidationAndRedaction(t *testing.T) {
	p := &Plan{SessionID: "fetch", Outbounds: []Outbound{{ID: "vpn", Protocol: ProtocolSOCKS5, Server: "127.0.0.1", Port: 1080}},
		ExtensionProxy: &ExtensionProxy{Port: 23456, Username: strings.Repeat("u", 26), Password: strings.Repeat("p", 52), Target: "vpn"}}
	if err := p.Validate(); err != nil {
		t.Fatal(err)
	}
	if !p.RequiredFeatures()[FeatureExtensionProxy] {
		t.Fatal("engine selection may omit the private listener")
	}
	for _, secret := range []string{p.ExtensionProxy.Username, p.ExtensionProxy.Password} {
		if !slices.Contains(p.Secrets(), secret) {
			t.Fatal("extension credential is missing from log redaction")
		}
	}
	for _, change := range []func(*ExtensionProxy){
		func(x *ExtensionProxy) { x.Port = 0 },
		func(x *ExtensionProxy) { x.Username = "" },
		func(x *ExtensionProxy) { x.Password = "short" },
		func(x *ExtensionProxy) { x.Target = "direct" },
	} {
		x := *p.ExtensionProxy
		change(&x)
		broken := *p
		broken.ExtensionProxy = &x
		if broken.Validate() == nil {
			t.Fatal("accepted an unsafe extension listener")
		}
	}
}
