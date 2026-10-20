package engine

import (
	"strings"
	"testing"
)

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

func TestValidateHysteria21_14Tuning(t *testing.T) {
	// S4: sing-box 1.14 fields — randomized hop interval and BBR
	// profile — validate like the base tuning does.
	ok := hy2Outbound()
	ok.HopPorts = "20000-30000"
	ok.HopInterval, ok.HopIntervalMax = 30, 90
	ok.BBRProfile = "conservative"
	if err := ok.Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
	bad := []struct {
		name string
		mut  func(*Outbound)
	}{
		{"negative hop max", func(o *Outbound) { o.HopIntervalMax = -1 }},
		{"hop max without ports", func(o *Outbound) { o.HopIntervalMax = 60 }},
		{"hop max below interval", func(o *Outbound) {
			o.HopPorts = "20000"
			o.HopInterval, o.HopIntervalMax = 90, 30
		}},
		{"unknown bbr profile", func(o *Outbound) { o.BBRProfile = "turbo" }},
	}
	for _, c := range bad {
		t.Run(c.name, func(t *testing.T) {
			o := hy2Outbound()
			c.mut(&o)
			if err := o.Validate(); err == nil {
				t.Fatalf("Validate = nil, want error")
			}
		})
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

func TestValidateHysteria2ObfsGate(t *testing.T) {
	// CENSOR-P3: the obfs type must be one the engines implement and
	// its password is credential data the engines require — both
	// hopping engines reject an obfs block without a password at
	// config load (verified on the pins).
	ok := hy2Outbound()
	ok.Obfs, ok.ObfsParam = "gecko", "gecko-secret"
	if err := ok.Validate(); err != nil {
		t.Fatalf("Validate(gecko) = %v, want nil", err)
	}
	bad := []struct {
		name string
		mut  func(*Outbound)
	}{
		{"unknown obfs", func(o *Outbound) { o.Obfs, o.ObfsParam = "bogus", "x" }},
		{"obfs without password", func(o *Outbound) { o.Obfs, o.ObfsParam = "salamander", "" }},
		{"password without type", func(o *Outbound) { o.Obfs, o.ObfsParam = "", "orphan" }},
		{"cap above ceiling", func(o *Outbound) { o.DownMbps = MaxHy2BandwidthMbps + 1 }},
	}
	for _, c := range bad {
		t.Run(c.name, func(t *testing.T) {
			o := hy2Outbound()
			o.Obfs, o.ObfsParam = "", ""
			c.mut(&o)
			if err := o.Validate(); err == nil {
				t.Fatalf("Validate = nil, want error")
			}
		})
	}
}

func TestValidateTUICHeartbeat(t *testing.T) {
	for _, hb := range []int{0, 1, 10, MaxTUICHeartbeatSeconds} {
		o := tuicOutbound()
		o.TUICHeartbeat = hb
		if err := o.Validate(); err != nil {
			t.Fatalf("Validate(heartbeat=%d) = %v, want nil", hb, err)
		}
	}
	for _, hb := range []int{-1, MaxTUICHeartbeatSeconds + 1} {
		o := tuicOutbound()
		o.TUICHeartbeat = hb
		if err := o.Validate(); err == nil {
			t.Fatalf("Validate(heartbeat=%d) = nil, want error", hb)
		}
	}
}

func TestHy2ObfsRequiresFeatureGate(t *testing.T) {
	// CENSOR-P3: an obfuscated hy2 plan must require FeatureHy2Obfs
	// so engine selection keeps it off Xray (whose renderer refuses
	// obfs) instead of failing at Apply.
	p := &Plan{Outbounds: []Outbound{hy2Outbound()}}
	if p.RequiredFeatures()[FeatureHy2Obfs] {
		t.Fatal("plain hy2 plan must not require the obfs feature")
	}
	p.Outbounds[0].Obfs, p.Outbounds[0].ObfsParam = "salamander", "secret"
	if !p.RequiredFeatures()[FeatureHy2Obfs] {
		t.Fatal("obfuscated hy2 plan must require FeatureHy2Obfs")
	}
	if Catalog[KindXray].Supports(FeatureHy2Obfs) {
		t.Fatal("Xray must not claim FeatureHy2Obfs")
	}
	for _, k := range []Kind{KindSingBox, KindMihomo} {
		if !Catalog[k].Supports(FeatureHy2Obfs) {
			t.Fatalf("%s must claim FeatureHy2Obfs", k)
		}
	}
}

func TestHopPortRangesAndSingBoxSpelling(t *testing.T) {
	ranges, err := HopPortRanges("20000-30000,40000")
	if err != nil {
		t.Fatal(err)
	}
	if len(ranges) != 2 || ranges[0] != [2]int{20000, 30000} || ranges[1] != [2]int{40000, 40000} {
		t.Fatalf("ranges = %v", ranges)
	}
	ports, err := SingBoxHopPorts("20000-30000,40000")
	if err != nil {
		t.Fatal(err)
	}
	if len(ports) != 2 || ports[0] != "20000:30000" || ports[1] != "40000:40000" {
		t.Fatalf("sing-box ports = %v", ports)
	}
	if _, err := HopPortRanges("20000:30000"); err == nil {
		t.Fatal("colon spelling is engine syntax, not plan syntax: want error")
	}
}

func TestEffectiveTUICDefaults(t *testing.T) {
	o := tuicOutbound()
	if o.EffectiveTUICCongestion() != DefaultTUICCongestion {
		t.Fatalf("congestion = %q, want %q", o.EffectiveTUICCongestion(), DefaultTUICCongestion)
	}
	if o.EffectiveTUICHeartbeatSeconds() != DefaultTUICHeartbeatSeconds {
		t.Fatalf("heartbeat = %d, want %d", o.EffectiveTUICHeartbeatSeconds(), DefaultTUICHeartbeatSeconds)
	}
	o.CongestionControl, o.TUICHeartbeat = "new_reno", 42
	if o.EffectiveTUICCongestion() != "new_reno" || o.EffectiveTUICHeartbeatSeconds() != 42 {
		t.Fatal("pinned values must win over defaults")
	}
}

// TestValidateHy2TUICBoundaries pins the owner's boundary matrix
// (CENSOR-P3 "мелочи"): every tuning number at its edges — 0,
// negative, exactly-at-bound, one-past-bound — for bandwidth caps,
// hop-port ranges and the TUIC heartbeat.
func TestValidateHy2TUICBoundaries(t *testing.T) {
	hy2Cases := []struct {
		name    string
		mut     func(*Outbound)
		wantErr bool
	}{
		{"caps zero = bbr", func(o *Outbound) { o.UpMbps, o.DownMbps = 0, 0 }, false},
		{"caps at ceiling", func(o *Outbound) { o.UpMbps, o.DownMbps = MaxHy2BandwidthMbps, MaxHy2BandwidthMbps }, false},
		{"up one past ceiling", func(o *Outbound) { o.UpMbps = MaxHy2BandwidthMbps + 1 }, true},
		{"down one past ceiling", func(o *Outbound) { o.DownMbps = MaxHy2BandwidthMbps + 1 }, true},
		{"hop empty", func(o *Outbound) { o.HopPorts = "" }, false},
		{"hop single port", func(o *Outbound) { o.HopPorts = "443" }, false},
		{"hop port 1", func(o *Outbound) { o.HopPorts = "1" }, false},
		{"hop port 65535", func(o *Outbound) { o.HopPorts = "65535" }, false},
		{"hop port 0", func(o *Outbound) { o.HopPorts = "0" }, true},
		{"hop port 65536", func(o *Outbound) { o.HopPorts = "65536" }, true},
		{"hop full range", func(o *Outbound) { o.HopPorts = "1-65535" }, false},
		{"hop degenerate range", func(o *Outbound) { o.HopPorts = "5000-5000" }, false},
		{"hop reversed range", func(o *Outbound) { o.HopPorts = "5000-4999" }, true},
		{"hop empty element", func(o *Outbound) { o.HopPorts = "20000,,30000" }, true},
		{"hop trailing comma", func(o *Outbound) { o.HopPorts = "20000," }, true},
		{"hop interval at minimum", func(o *Outbound) { o.HopPorts, o.HopInterval = "20000", MinHy2HopIntervalSeconds }, false},
		{"hop interval below minimum", func(o *Outbound) { o.HopPorts, o.HopInterval = "20000", MinHy2HopIntervalSeconds - 1 }, true},
		{"hop interval max equals interval", func(o *Outbound) { o.HopPorts, o.HopInterval, o.HopIntervalMax = "20000", 30, 30 }, false},
	}
	for _, c := range hy2Cases {
		t.Run("hy2/"+c.name, func(t *testing.T) {
			o := hy2Outbound()
			o.Obfs, o.ObfsParam = "", ""
			c.mut(&o)
			err := o.Validate()
			if (err != nil) != c.wantErr {
				t.Fatalf("Validate = %v, wantErr %v", err, c.wantErr)
			}
		})
	}
	tuicCases := []struct {
		name    string
		hb      int
		wantErr bool
	}{
		{"heartbeat unset", 0, false},
		{"heartbeat minimum", MinTUICHeartbeatSeconds, false},
		{"heartbeat default", DefaultTUICHeartbeatSeconds, false},
		{"heartbeat maximum", MaxTUICHeartbeatSeconds, false},
		{"heartbeat above maximum", MaxTUICHeartbeatSeconds + 1, true},
		{"heartbeat negative", -1, true},
	}
	for _, c := range tuicCases {
		t.Run("tuic/"+c.name, func(t *testing.T) {
			o := tuicOutbound()
			o.TUICHeartbeat = c.hb
			err := o.Validate()
			if (err != nil) != c.wantErr {
				t.Fatalf("Validate(heartbeat=%d) = %v, wantErr %v", c.hb, err, c.wantErr)
			}
		})
	}
}

// TestHy2ObfsValidationNeverEchoesPassword: validation errors are
// log-bound text; the obfs password (credential data) must never
// appear in them — masking at the log layer is the second line of
// defence, not an excuse to leak at the source (CENSOR-P3 "мелочи").
func TestHy2ObfsValidationNeverEchoesPassword(t *testing.T) {
	o := hy2Outbound()
	o.Obfs, o.ObfsParam = "bogus-type", "obfs-secret-value"
	err := o.Validate()
	if err == nil {
		t.Fatal("Validate = nil for unknown obfs, want error")
	}
	if strings.Contains(err.Error(), "obfs-secret-value") {
		t.Fatalf("validation error leaks the obfs password: %v", err)
	}
	found := false
	for _, s := range o.Secrets() {
		if s == "obfs-secret-value" {
			found = true
		}
	}
	if !found {
		t.Fatal("obfs password must stay in Secrets() for the log redactor")
	}
}
