package engine

import (
	"encoding/base64"
	"strings"
	"testing"
)

// CENSOR-P4: the SS method/plugin gates and the AWG fail-closed
// additions. The method/plugin facts are measured on the pinned
// binaries (see ss_support.go / ss_plugin.go); these tests pin the
// data so a silent edit of the tables fails loudly.

func ssPlan(method, password string) *Plan {
	return &Plan{SessionID: "p4", Outbounds: []Outbound{
		{ID: "ss", Name: "ss", Protocol: ProtocolShadowsocks,
			Server: "ss.example.com", Port: 4433, Cipher: method, Password: password},
	}}
}

func TestSSMethodSelectionMatrix(t *testing.T) {
	key32 := base64.StdEncoding.EncodeToString(make([]byte, 32))
	cases := []struct {
		method string
		carry  map[Kind]bool
	}{
		{"2022-blake3-aes-256-gcm", map[Kind]bool{KindSingBox: true, KindXray: true, KindMihomo: true}},
		{"2022-blake3-chacha8-poly1305", map[Kind]bool{KindMihomo: true}},
		{"2022-blake3-chacha12-poly1305", map[Kind]bool{}},
		{"aes-192-gcm", map[Kind]bool{KindSingBox: true, KindMihomo: true}},
		{"chacha20-poly1305", map[Kind]bool{KindXray: true}},
		{"aes-256-cfb", map[Kind]bool{KindSingBox: true, KindMihomo: true}},
		{"none", map[Kind]bool{KindSingBox: true, KindMihomo: true}},
		{"super-cipher-9000", map[Kind]bool{}},
	}
	for _, tc := range cases {
		pw := "a-long-enough-password"
		if strings.HasPrefix(tc.method, "2022-") {
			pw = key32
		}
		p := ssPlan(tc.method, pw)
		for _, kind := range []Kind{KindSingBox, KindXray, KindMihomo} {
			missing := Catalog[kind].Missing(p)
			has := false
			for _, m := range missing {
				if strings.Contains(m, "shadowsocks method") {
					has = true
				}
			}
			if has == tc.carry[kind] {
				t.Errorf("method %s on %s: method-missing=%v, want carry=%v (missing=%v)",
					tc.method, kind, has, tc.carry[kind], missing)
			}
		}
	}
}

func TestSSPluginSelectionMatrix(t *testing.T) {
	key32 := base64.StdEncoding.EncodeToString(make([]byte, 32))
	_ = key32
	mk := func(plugin, opts string) *Plan {
		p := ssPlan("aes-256-gcm", "a-long-enough-password")
		p.Outbounds[0].Plugin, p.Outbounds[0].PluginOpts = plugin, opts
		return p
	}
	cases := []struct {
		name  string
		plan  *Plan
		carry map[Kind]bool
	}{
		{"v2ray-plugin", mk("v2ray-plugin", "tls;host=example.com"), map[Kind]bool{KindSingBox: true, KindMihomo: true}},
		{"obfs-local", mk("obfs-local", "obfs=tls;obfs-host=example.com"), map[Kind]bool{KindSingBox: true, KindMihomo: true}},
		{"gost-plugin", mk("gost-plugin", "host=example.com"), map[Kind]bool{KindMihomo: true}},
		{"shadow-tls", mk("shadow-tls", "host=example.com;password=pw"), map[Kind]bool{KindMihomo: true}},
	}
	for _, tc := range cases {
		for _, kind := range []Kind{KindSingBox, KindXray, KindMihomo} {
			missing := Catalog[kind].Missing(tc.plan)
			has := false
			for _, m := range missing {
				if strings.Contains(m, "shadowsocks plugin") {
					has = true
				}
			}
			if has == tc.carry[kind] {
				t.Errorf("plugin %s on %s: plugin-missing=%v, want carry=%v (missing=%v)",
					tc.name, kind, has, tc.carry[kind], missing)
			}
		}
	}
	// Legacy obfs: Xray must report it missing; the carriers must not.
	p := ssPlan("aes-256-gcm", "a-long-enough-password")
	p.Outbounds[0].Obfs, p.Outbounds[0].ObfsParam = "tls", "example.com"
	if m := Catalog[KindXray].Missing(p); !strings.Contains(strings.Join(m, ","), "shadowsocks obfs") {
		t.Errorf("xray must miss legacy SS obfs, missing=%v", m)
	}
	for _, kind := range []Kind{KindSingBox, KindMihomo} {
		for _, m := range Catalog[kind].Missing(p) {
			if strings.Contains(m, "obfs") {
				t.Errorf("%s must carry legacy SS obfs, missing=%v", kind, m)
			}
		}
	}
}

func TestValidateShadowsocks2022KeyFailsClosed(t *testing.T) {
	key16 := base64.StdEncoding.EncodeToString(make([]byte, 16))
	key32 := base64.StdEncoding.EncodeToString(make([]byte, 32))
	for _, tc := range []struct {
		name, method, pw string
		wantErr          bool
	}{
		{"good 256", "2022-blake3-aes-256-gcm", key32, false},
		{"good 128", "2022-blake3-aes-128-gcm", key16, false},
		{"identity chain", "2022-blake3-aes-256-gcm", key32 + ":" + key32, false},
		{"wrong length", "2022-blake3-aes-256-gcm", key16, true},
		{"not base64", "2022-blake3-aes-128-gcm", "not-a-key!!", true},
		{"empty", "2022-blake3-aes-256-gcm", "", true},
		{"legacy unaffected", "aes-256-gcm", "short", false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			err := ssPlan(tc.method, tc.pw).Outbounds[0].Validate()
			if (err != nil) != tc.wantErr {
				t.Fatalf("Validate = %v, wantErr %v", err, tc.wantErr)
			}
			if tc.wantErr && !strings.Contains(err.Error(), "PSK") {
				t.Fatalf("error must name the PSK requirement, got %v", err)
			}
		})
	}
}

func TestValidateShadowsocksPluginFailsClosed(t *testing.T) {
	mk := func() Outbound { return ssPlan("aes-256-gcm", "a-long-enough-password").Outbounds[0] }
	for _, tc := range []struct {
		name   string
		mutate func(*Outbound)
		want   string // substring; "" means valid
	}{
		{"known plugin ok", func(o *Outbound) { o.Plugin, o.PluginOpts = "v2ray-plugin", "tls;host=example.com;path=/ws" }, ""},
		{"obfs-local ok", func(o *Outbound) { o.Plugin, o.PluginOpts = "obfs-local", "obfs=tls;obfs-host=example.com" }, ""},
		{"unknown plugin", func(o *Outbound) { o.Plugin = "nosuch-plugin" }, "unknown shadowsocks plugin"},
		{"opts without plugin", func(o *Outbound) { o.PluginOpts = "tls" }, "without a plugin"},
		{"unknown option", func(o *Outbound) { o.Plugin, o.PluginOpts = "v2ray-plugin", "bogus=1" }, "unknown option"},
		{"duplicate option", func(o *Outbound) { o.Plugin, o.PluginOpts = "v2ray-plugin", "host=a.com;host=b.com" }, "set twice"},
		{"bad flag", func(o *Outbound) { o.Plugin, o.PluginOpts = "v2ray-plugin", "tls=maybe" }, "boolean"},
		{"bad host", func(o *Outbound) { o.Plugin, o.PluginOpts = "v2ray-plugin", "host=exa mple.com" }, "not a valid host"},
		{"bad path", func(o *Outbound) { o.Plugin, o.PluginOpts = "v2ray-plugin", "path=ws" }, "absolute path"},
		{"bad obfs mode", func(o *Outbound) { o.Plugin, o.PluginOpts = "obfs-local", "obfs=salamander" }, "http or tls"},
		{"stray segment", func(o *Outbound) { o.Plugin, o.PluginOpts = "v2ray-plugin", "tls;;host=a.com" }, "empty option segment"},
		{"legacy obfs ok", func(o *Outbound) { o.Obfs, o.ObfsParam = "tls", "example.com" }, ""},
		{"legacy obfs bad mode", func(o *Outbound) { o.Obfs = "salamander" }, "simple-obfs mode"},
		{"obfs-host injection", func(o *Outbound) { o.Obfs, o.ObfsParam = "tls", "a.com;obfs=http" }, "separator"},
		{"dead obfs-host", func(o *Outbound) { o.ObfsParam = "example.com" }, "without an obfs mode"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			o := mk()
			tc.mutate(&o)
			err := o.Validate()
			if tc.want == "" {
				if err != nil {
					t.Fatalf("Validate = %v, want nil", err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Validate = %v, want error containing %q", err, tc.want)
			}
		})
	}
	// Plugin fields on a non-Shadowsocks outbound are refused, not dropped.
	o := Outbound{ID: "v", Name: "v", Protocol: ProtocolVLESS, Server: "v.example.com", Port: 443,
		UUID: "b831381d-6324-4d53-ad4f-8cda48b30811", Plugin: "v2ray-plugin"}
	if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "plugins belong to shadowsocks") {
		t.Fatalf("plugin on vless: Validate = %v", err)
	}
}

func TestValidateAmneziaWGP4Additions(t *testing.T) {
	for _, tc := range []struct {
		name   string
		mutate func(a *AmneziaWG)
		want   string
	}{
		{"j1 bad CPS", func(a *AmneziaWG) { a.J1 = "<b 0xzz>" }, "j1"},
		{"j2 ok CPS", func(a *AmneziaWG) { a.J2 = "<r 10><t>" }, ""},
		{"itime negative", func(a *AmneziaWG) { a.Itime = -1 }, "itime -1"},
		{"itime absurd", func(a *AmneziaWG) { a.Itime = 7200 }, "itime 7200"},
		{"jc without jmax", func(a *AmneziaWG) { a.Jmax = 0 }, "jmax is 0"},
		{"v3 plus j1", func(a *AmneziaWG) {
			b := goodAmnezia31()
			*a = *b
			a.J1 = "<r 10>"
		}, "cannot be combined with 3.1"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			a := goodAmnezia()
			tc.mutate(a)
			err := wireguardWithAmnezia(a).Validate()
			if tc.want == "" {
				if err != nil {
					t.Fatalf("Validate = %v, want nil", err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Validate = %v, want error containing %q", err, tc.want)
			}
		})
	}
}

func TestZeroAmneziaWGIsDisabled(t *testing.T) {
	o := wireguardWithAmnezia(&AmneziaWG{})
	if !o.Amnezia.IsZero() {
		t.Fatal("empty AmneziaWG must report IsZero")
	}
	p := &Plan{SessionID: "p4", Outbounds: []Outbound{o}}
	if p.RequiredFeatures()[FeatureAmneziaWG] {
		t.Fatal("a zero AmneziaWG must not require FeatureAmneziaWG")
	}
	o2 := wireguardWithAmnezia(goodAmnezia())
	if o2.Amnezia.IsZero() {
		t.Fatal("a populated AmneziaWG must not report IsZero")
	}
}

// "Мелочи" §3: plugin option strings are deterministic — the same
// option set renders the same string in any input order.
func TestCanonicalSSPluginOpts(t *testing.T) {
	cases := []struct{ plugin, in, want string }{
		{"v2ray-plugin", "tls;host=example.com", "tls;host=example.com"},
		{"v2ray-plugin", "host=example.com;tls", "tls;host=example.com"},
		{"v2ray-plugin", "path=/ws;host=example.com;mux;tls", "tls;mux;host=example.com;path=/ws"},
		{"obfs-local", "obfs-host=example.com;obfs=tls", "obfs=tls;obfs-host=example.com"},
		{"shadow-tls", "password=pw;host=example.com;version=3", "host=example.com;password=pw;version=3"},
		{"nosuch-plugin", "b=2;a=1", "b=2;a=1"}, // unknown passes through; validation owns rejection
	}
	for _, tc := range cases {
		if got := CanonicalSSPluginOpts(tc.plugin, tc.in); got != tc.want {
			t.Errorf("CanonicalSSPluginOpts(%q, %q) = %q, want %q", tc.plugin, tc.in, got, tc.want)
		}
	}
}

// "Мелочи" §5: every key the new code paths touch is inside the
// redactor's seed set — the SS-2022 PSK (Password), a plugin password
// that exists only inside PluginOpts, and the AWG header-protection
// key — and a log line quoting any of them is masked.
func TestSecretsCoverPluginAndAWGKeys(t *testing.T) {
	psk := base64.StdEncoding.EncodeToString([]byte("0123456789abcdef0123456789abcdef"))
	o := Outbound{ID: "ss", Name: "ss", Protocol: ProtocolShadowsocks,
		Server: "ss.example.com", Port: 4433,
		Cipher: "2022-blake3-aes-256-gcm", Password: psk,
		Plugin: "shadow-tls", PluginOpts: "host=example.com;password=" + "plugin-secret-value"}
	secrets := o.Secrets()
	for _, want := range []string{psk, "plugin-secret-value", o.PluginOpts} {
		found := false
		for _, s := range secrets {
			if s == want {
				found = true
			}
		}
		if !found {
			t.Errorf("Secrets() must contain %q, got %v", want, secrets)
		}
	}
	r := NewRedactor(secrets...)
	line := r.String("dial psk=" + psk + " pluginpw=plugin-secret-value opts=" + o.PluginOpts)
	for _, leak := range []string{psk, "plugin-secret-value"} {
		if strings.Contains(line, leak) {
			t.Errorf("redacted log line leaks %q: %s", leak, line)
		}
	}
	awg := wireguardWithAmnezia(goodAmnezia31())
	found := false
	for _, s := range awg.Secrets() {
		if s == awg.Amnezia.HeaderProtectionKey {
			found = true
		}
	}
	if !found {
		t.Error("Secrets() must contain the AWG header-protection key")
	}
}

func TestSelectEngineHostTUNProbeGate(t *testing.T) {
	p := Plan{SessionID: "p4", Tun: Tun{Enabled: true},
		Outbounds: []Outbound{{ID: "ss", Name: "ss", Protocol: ProtocolShadowsocks,
			Server: "ss.example.com", Port: 4433, Cipher: "aes-256-gcm", Password: "a-long-enough-password"}}}
	avail := []Availability{{Kind: KindSingBox, Usable: true,
		Version: mustVersion(t, "1.14.3-lx.22"), BuildTags: []string{"with_awg"},
		HostProbed: true, TUNDevice: false}}
	if _, err := SelectEngine(&p, avail, []Kind{KindSingBox}); err == nil ||
		!strings.Contains(err.Error(), "no TUN device") {
		t.Fatalf("probed host without TUN must refuse a TUN plan, got %v", err)
	}
	// Unprobed host: no gate (facts nobody measured must not refuse).
	avail[0].HostProbed = false
	if _, err := SelectEngine(&p, avail, []Kind{KindSingBox}); err != nil {
		t.Fatalf("unprobed host must not gate, got %v", err)
	}
	// Probed host WITH a TUN device, and no kernel WireGuard: an AWG
	// plan still selects sing-box-lx — userspace AWG needs no kernel
	// module (this VM is the standing example).
	avail[0].HostProbed, avail[0].TUNDevice, avail[0].KernelWireGuard = true, true, false
	awg := Plan{SessionID: "p4", Outbounds: []Outbound{wireguardWithAmnezia(goodAmnezia())}}
	if _, err := SelectEngine(&awg, avail, []Kind{KindSingBox}); err != nil {
		t.Fatalf("userspace AWG must not need kernel WireGuard, got %v", err)
	}
	// Same plan, probed tags WITHOUT with_awg: refused — the gate
	// keys off the probed tags, not the pinned version's reputation.
	avail[0].BuildTags = []string{"with_quic"}
	if _, err := SelectEngine(&awg, avail, []Kind{KindSingBox}); err == nil ||
		!strings.Contains(err.Error(), "amneziawg") {
		t.Fatalf("probed tags without with_awg must refuse an AWG plan, got %v", err)
	}
}
