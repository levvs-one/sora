package engine

import (
	"strings"
	"testing"
)

// T024: ECH honesty rules. ECH must never silently degrade into leaking
// the very name it is supposed to hide.

func echOutbound() Outbound {
	return Outbound{
		ID:       "ech1",
		Protocol: ProtocolVLESS,
		Server:   "203.0.113.7",
		Port:     443,
		TLS: TLS{
			Enabled:    true,
			ServerName: "example.com",
			ECH:        ECHConfig{Enabled: true},
		},
	}
}

func TestValidateRejectsECHWithoutTLS(t *testing.T) {
	o := echOutbound()
	o.TLS.Enabled = false
	if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "ECH is enabled but TLS is not") {
		t.Errorf("Validate = %v, want ECH-without-TLS error", err)
	}
}

func TestValidateRejectsECHWithReality(t *testing.T) {
	o := echOutbound()
	o.TLS.Reality = true
	if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "incompatible") {
		t.Errorf("Validate = %v, want ECH+REALITY incompatibility error", err)
	}
}

func TestValidateAcceptsECHQueryServerName(t *testing.T) {
	// PASS3 deep S4: the old rejection ("not rendered yet, needs
	// sing-box >= 1.13") outlived its truth — sing-box renders
	// query_server_name (floor is 1.14.3) and mihomo renders
	// query-server-name in ech-opts.
	o := echOutbound()
	o.TLS.ECH.QueryServerName = "ech.example.com"
	if err := o.Validate(); err != nil {
		t.Errorf("Validate = %v, want nil for a rendered query_server_name", err)
	}
}

func TestECHPlanRequiresFeatureECH(t *testing.T) {
	// PASS3 deep S4: an ECH plan must route only to engines whose
	// renderer emits ECH. Xray renders none of it, so it reports the
	// feature missing; sing-box and mihomo carry it.
	p := &Plan{SessionID: "s1", Outbounds: []Outbound{echOutbound()}}
	if !p.RequiredFeatures()[FeatureECH] {
		t.Fatal("an ECH-enabled plan must require feature ech")
	}
	if missing := Catalog[KindXray].Missing(p); !containsStr(missing, "feature "+string(FeatureECH)) {
		t.Errorf("xray must miss feature ech, got %v", missing)
	}
	for _, kind := range []Kind{KindSingBox, KindMihomo} {
		if missing := Catalog[kind].Missing(p); containsStr(missing, "feature "+string(FeatureECH)) {
			t.Errorf("%s renders ECH and must not miss feature ech, got %v", kind, missing)
		}
	}
}

func containsStr(list []string, want string) bool {
	for _, s := range list {
		if s == want {
			return true
		}
	}
	return false
}

func TestValidateRejectsECHBootstrapOverPlaintextDNS(t *testing.T) {
	p := &Plan{
		SessionID: "s1",
		Outbounds: []Outbound{echOutbound()},
		DNS: DNS{
			Enabled: true,
			Servers: []DNSServer{{Tag: "dns-1", Transport: DNSPlain, Address: "8.8.8.8", Port: 53}},
		},
	}
	if err := p.Validate(); err == nil || !strings.Contains(err.Error(), "no encrypted DNS transport") {
		t.Errorf("Validate = %v, want encrypted-DNS bootstrap error", err)
	}
}

func TestValidateRejectsECHBootstrapWithoutDNS(t *testing.T) {
	p := &Plan{SessionID: "s1", Outbounds: []Outbound{echOutbound()}}
	if err := p.Validate(); err == nil || !strings.Contains(err.Error(), "no encrypted DNS transport") {
		t.Errorf("Validate = %v, want encrypted-DNS bootstrap error", err)
	}
}

func TestValidateAcceptsECHWithEncryptedDNS(t *testing.T) {
	p := &Plan{
		SessionID: "s1",
		Outbounds: []Outbound{echOutbound()},
		DNS: DNS{
			Enabled: true,
			Servers: []DNSServer{{Tag: "dns-1", Transport: DNSHTTPS, Address: "1.1.1.1"}},
		},
	}
	if err := p.Validate(); err != nil {
		t.Errorf("Validate = %v, want nil for ECH with DoH", err)
	}
}

func TestValidateAcceptsECHWithPinnedConfig(t *testing.T) {
	// A pinned ECHConfigList skips the DNS lookup entirely, so plaintext
	// DNS is irrelevant.
	o := echOutbound()
	o.TLS.ECH.Config = []string{"-----BEGIN ECHCONFIG-----"}
	p := &Plan{
		SessionID: "s1",
		Outbounds: []Outbound{o},
		DNS: DNS{
			Enabled: true,
			Servers: []DNSServer{{Tag: "dns-1", Transport: DNSPlain, Address: "8.8.8.8", Port: 53}},
		},
	}
	if err := p.Validate(); err != nil {
		t.Errorf("Validate = %v, want nil for ECH with pinned config", err)
	}
}

func TestValidateAcceptsDisabledECH(t *testing.T) {
	o := echOutbound()
	o.TLS.ECH = ECHConfig{}
	p := &Plan{
		SessionID: "s1",
		Outbounds: []Outbound{o},
		DNS: DNS{
			Enabled: true,
			Servers: []DNSServer{{Tag: "dns-1", Transport: DNSPlain, Address: "8.8.8.8", Port: 53}},
		},
	}
	if err := p.Validate(); err != nil {
		t.Errorf("Validate = %v, want nil when ECH is off", err)
	}
}
