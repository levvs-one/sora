package engine

import "testing"

func hy2Outbound() Outbound {
	return Outbound{
		ID: "hy2", Name: "hy2", Protocol: ProtocolHysteria2,
		Server: "hy.example.com", Port: 443, Password: "secret",
		TLS: TLS{Enabled: true, ServerName: "hy.example.com"},
	}
}

func TestValidateAcceptsHysteria2Tuning(t *testing.T) {
	o := hy2Outbound()
	o.UpMbps, o.DownMbps = 20, 100
	o.HopPorts = "20000-30000,40000"
	o.HopInterval = 30
	if err := o.Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
}

func TestValidateRejectsBadHysteria2Tuning(t *testing.T) {
	cases := []struct {
		name string
		mut  func(*Outbound)
	}{
		{"negative up", func(o *Outbound) { o.UpMbps = -1 }},
		{"negative down", func(o *Outbound) { o.DownMbps = -1 }},
		{"negative hop interval", func(o *Outbound) { o.HopInterval = -1 }},
		{"hop interval below minimum", func(o *Outbound) { o.HopPorts = "20000"; o.HopInterval = 4 }},
		{"hop interval without ports", func(o *Outbound) { o.HopInterval = 30 }},
		{"bad hop ports", func(o *Outbound) { o.HopPorts = "abc" }},
		{"reversed hop range", func(o *Outbound) { o.HopPorts = "30000-20000" }},
		{"port zero in hop range", func(o *Outbound) { o.HopPorts = "0-100" }},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			o := hy2Outbound()
			c.mut(&o)
			if err := o.Validate(); err == nil {
				t.Fatalf("Validate = nil, want error")
			}
		})
	}
}

func tuicOutbound() Outbound {
	return Outbound{
		ID: "tuic", Name: "tuic", Protocol: ProtocolTUIC,
		Server: "tu.example.com", Port: 443,
		UUID: "11111111-2222-3333-4444-555555555555", Password: "secret",
		TLS: TLS{Enabled: true, ServerName: "tu.example.com"},
	}
}

func TestValidateAcceptsTUICTuning(t *testing.T) {
	for _, cc := range []string{"", "bbr", "cubic", "new_reno"} {
		for _, mode := range []string{"", "native", "quic"} {
			o := tuicOutbound()
			o.CongestionControl, o.UDPRelayMode = cc, mode
			if err := o.Validate(); err != nil {
				t.Fatalf("Validate(%q, %q) = %v, want nil", cc, mode, err)
			}
		}
	}
}

func TestValidateRejectsBadTUICTuning(t *testing.T) {
	o := tuicOutbound()
	o.CongestionControl = "brutal"
	if err := o.Validate(); err == nil {
		t.Fatal("Validate = nil for unknown tuic congestion control, want error")
	}
	o = tuicOutbound()
	o.UDPRelayMode = "stream"
	if err := o.Validate(); err == nil {
		t.Fatal("Validate = nil for unknown tuic udp relay mode, want error")
	}
}

func TestSecretsIncludesTUICToken(t *testing.T) {
	o := tuicOutbound()
	o.Token = "v4-token-secret"
	for _, s := range o.Secrets() {
		if s == "v4-token-secret" {
			return
		}
	}
	t.Fatal("TUIC v4 token is not redacted")
}
