package parser

import (
	"encoding/base64"
	"net/url"
	"strings"
	"testing"
)

func TestParseLinks(t *testing.T) {
	// Normalize schemes and apply protocol-specific security defaults.
	tests := []struct{ name, input, protocol, security string }{
		{"vless", "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443?security=tls&type=ws&path=%2F#🇩🇪%20Berlin", "vless", "tls"},
		{"vless plain", "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443", "vless", "none"},
		{"trojan", "trojan://secret@example.com:443?sni=example.com#Trojan", "trojan", "tls"},
		{"shadowsocks", "ss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388#SS", "shadowsocks", "none"},
		{"hysteria2", "hysteria2://secret@example.com:443?sni=example.com#H2", "hysteria2", "tls"},
		{"hy2", "hy2://secret@example.com:443#H2", "hysteria2", "tls"},
		{"tuic", "tuic://123e4567-e89b-12d3-a456-426614174000:pass@example.com:443", "tuic", "tls"},
		{"socks", "socks://user:pass@example.com:1080", "socks5", "none"},
		{"socks5", "socks5://example.com:1080", "socks5", "none"},
		{"https", "https://user:pass@example.com:443", "http", "tls"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r, err := (LinkParser{}).Parse([]byte(tt.input))
			if err != nil {
				t.Fatal(err)
			}
			if len(r.Servers) != 1 || r.Servers[0].Protocol != tt.protocol || r.Servers[0].Security != tt.security {
				t.Fatalf("unexpected result: %#v", r)
			}
		})
	}
}

func TestBase64Wrapped(t *testing.T) {
	raw := "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443\n"
	enc := base64.StdEncoding.EncodeToString([]byte(raw))
	enc = strings.Join([]string{enc[:8], enc[8:]}, "\n")
	r, err := (LinkParser{}).Parse([]byte(enc))
	if err != nil || r.Report.Imported != 1 {
		t.Fatalf("result=%#v err=%v", r, err)
	}
}

func TestRejectsHTTPSubscription(t *testing.T) {
	if _, err := (LinkParser{}).Parse([]byte("http://example.com/sub")); err == nil {
		t.Fatal("expected rejection")
	}
}
func TestLimit(t *testing.T) {
	r, err := (LinkParser{MaxItems: 1}).Parse([]byte("vless://123e4567-e89b-12d3-a456-426614174000@a.example:443\nvless://123e4567-e89b-12d3-a456-426614174000@b.example:443"))
	if err != nil {
		t.Fatal(err)
	}
	if r.Report.Unsupported != 1 {
		t.Fatalf("%#v", r.Report)
	}
}
func FuzzDetect(f *testing.F) {
	f.Add([]byte("vless://x.example:443"))
	f.Fuzz(func(_ *testing.T, b []byte) { _, _ = (ImportDetector{}).Detect(b) })
}
func FuzzParseLink(f *testing.F) {
	f.Add("vless://123e4567-e89b-12d3-a456-426614174000@example.com:443")
	f.Fuzz(func(_ *testing.T, s string) { _, _ = (LinkParser{MaxItems: 100}).Parse([]byte(s)) })
}
func BenchmarkParseBase64Subscription(b *testing.B) {
	var lines strings.Builder
	for i := 0; i < 5000; i++ {
		lines.WriteString("vless://123e4567-e89b-12d3-a456-426614174000@example.com:443?type=tcp\n")
	}
	encoded := base64.StdEncoding.EncodeToString([]byte(lines.String()))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = (LinkParser{}).Parse([]byte(encoded))
	}
}

// TestXrayConfigurationsBecomeProfiles checks one profile per configuration in
// Remnawave-style subscription lists.
func TestXrayConfigurationsBecomeProfiles(t *testing.T) {
	config := func(name string) string {
		return `{"remarks":"` + name + `","inbounds":[{"listen":"127.0.0.1","port":10808,"protocol":"socks"}],
		"outbounds":[{"tag":"proxy","protocol":"vless","settings":{"vnext":[{"address":"185.92.222.239","port":443,
		"users":[{"id":"123e4567-e89b-12d3-a456-426614174000","encryption":"none"}]}]},
		"streamSettings":{"network":"xhttp","security":"reality","realitySettings":{"publicKey":"k","shortId":"s"}}},
		{"protocol":"freedom","tag":"direct"}],"routing":{"rules":[{"domain":["domain:openai.com"],"outboundTag":"proxy"}]}}`
	}
	r, err := (LinkParser{}).Parse([]byte("[" + config("🇳🇱 Нидерланды") + "," + config("Авто") + "]"))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 2 {
		t.Fatalf("servers = %d, report %+v", len(r.Servers), r.Report)
	}
	a, b := r.Servers[0], r.Servers[1]
	if a.Protocol != "xray-profile" || a.DisplayName != "🇳🇱 Нидерланды" || a.Host != "185.92.222.239" || a.Port != 443 {
		t.Fatalf("profile = %+v", a)
	}
	if a.Transport != "xhttp" || a.Security != "reality" || a.CountryCode != "🇳🇱" {
		t.Fatalf("transport, security and country come from the profile: %+v", a)
	}
	if a.Options["profile"] == "" {
		t.Fatal("the configuration travels whole")
	}
	if a.StableKey() == b.StableKey() {
		t.Fatal("two profiles on one server must keep two identities")
	}
}

func TestParseHysteria2TuningOptions(t *testing.T) {
	r, err := (LinkParser{}).Parse([]byte("hysteria2://secret@example.com:443?upmbps=20&downmbps=100&mport=20000-30000%2C40000&hop-interval=30&sni=example.com#H2"))
	if err != nil {
		t.Fatal(err)
	}
	o := r.Servers[0].Options
	for k, want := range map[string]string{"upmbps": "20", "downmbps": "100", "mport": "20000-30000,40000", "hop-interval": "30"} {
		if o[k] != want {
			t.Errorf("Options[%q] = %q, want %q", k, o[k], want)
		}
	}
}

func TestParseTUICTuningOptions(t *testing.T) {
	r, err := (LinkParser{}).Parse([]byte("tuic://123e4567-e89b-12d3-a456-426614174000:pass@example.com:443?congestion_control=cubic&udp_relay_mode=quic#TUIC"))
	if err != nil {
		t.Fatal(err)
	}
	o := r.Servers[0].Options
	if o["congestion_control"] != "cubic" || o["udp_relay_mode"] != "quic" {
		t.Fatalf("unexpected tuic options: %#v", o)
	}
	r, err = (LinkParser{}).Parse([]byte("tuic://example.com:443?token=v4secret#TUICv4"))
	if err != nil {
		t.Fatal(err)
	}
	if r.Servers[0].Options["token"] != "v4secret" {
		t.Fatalf("v4 token not parsed: %#v", r.Servers[0].Options)
	}
}

func TestParseShadowsocksPlugin(t *testing.T) {
	// Combined SIP002 form: one plugin parameter with ;-separated options.
	r, err := (LinkParser{}).Parse([]byte("ss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388?plugin=v2ray-plugin%3Btls%3Bhost%3Dexample.com#SS"))
	if err != nil {
		t.Fatal(err)
	}
	o := r.Servers[0].Options
	if o["ss_plugin"] != "v2ray-plugin" || o["ss_plugin_opts"] != "tls;host=example.com" {
		t.Fatalf("combined plugin form: %#v", o)
	}
	// Split form: plugin_opts wins over the ;-suffix of plugin.
	r, err = (LinkParser{}).Parse([]byte("ss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388?plugin=v2ray-plugin%3Btls&plugin_opts=tls%3Bhost%3Dother.example#SS"))
	if err != nil {
		t.Fatal(err)
	}
	o = r.Servers[0].Options
	if o["ss_plugin"] != "v2ray-plugin" || o["ss_plugin_opts"] != "tls;host=other.example" {
		t.Fatalf("split plugin form: %#v", o)
	}
	// No plugin: canonical keys stay empty.
	r, err = (LinkParser{}).Parse([]byte("ss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388#SS"))
	if err != nil {
		t.Fatal(err)
	}
	o = r.Servers[0].Options
	if o["ss_plugin"] != "" || o["ss_plugin_opts"] != "" {
		t.Fatalf("no plugin: %#v", o)
	}
}

func TestParseExtraDownloadSettings(t *testing.T) {
	// The XHTTP up/down split rides in the extra=<url-encoded JSON>
	// parameter (de-facto link standard, Xray camelCase).
	link := func(extra string) string {
		q := url.Values{}
		q.Set("type", "xhttp")
		q.Set("security", "tls")
		if extra != "" {
			q.Set("extra", extra)
		}
		return "vless://123e4567-e89b-12d3-a456-426614174000@up.example.com:443?" + q.Encode() + "#X"
	}
	parse := func(extra string) OutboundSpec {
		r, err := (LinkParser{}).Parse([]byte(link(extra)))
		if err != nil {
			t.Fatalf("extra %q: import failed: %v", extra, err)
		}
		if len(r.Servers) != 1 {
			t.Fatalf("extra %q: %#v", extra, r.Report)
		}
		return r.Servers[0]
	}
	// Valid extra: downloadSettings reaches the spec.
	s := parse(`{"downloadSettings":{"address":"down.example.com","port":8443}}`)
	if s.DownloadAddress != "down.example.com" || s.DownloadPort != 8443 {
		t.Errorf("valid extra: got %q:%d", s.DownloadAddress, s.DownloadPort)
	}
	// The rest of extra is ignored: xmux tuning has no producer yet, so
	// it must not leak into the split fields.
	s = parse(`{"xmux":{"maxConcurrency":64},"xPaddingBytes":"100-1000"}`)
	if s.DownloadAddress != "" || s.DownloadPort != 0 {
		t.Errorf("xmux-only extra: got %q:%d, want zero", s.DownloadAddress, s.DownloadPort)
	}
	// No extra: zero split.
	s = parse("")
	if s.DownloadAddress != "" || s.DownloadPort != 0 {
		t.Errorf("no extra: got %q:%d, want zero", s.DownloadAddress, s.DownloadPort)
	}
	// Garbage extra is provider decoration: the import survives, the
	// split is dropped.
	for name, extra := range map[string]string{
		"malformed json":        "{not json",
		"empty object":          "{}",
		"address without port":  `{"downloadSettings":{"address":"down.example.com"}}`,
		"port without address":  `{"downloadSettings":{"port":8443}}`,
		"zero port":             `{"downloadSettings":{"address":"down.example.com","port":0}}`,
		"out of range port":     `{"downloadSettings":{"address":"down.example.com","port":99999}}`,
		"negative port":         `{"downloadSettings":{"address":"down.example.com","port":-1}}`,
		"string port":           `{"downloadSettings":{"address":"down.example.com","port":"8443"}}`,
		"null downloadSettings": `{"downloadSettings":null}`,
		"non-object extra":      `[1,2,3]`,
	} {
		s = parse(extra)
		if s.DownloadAddress != "" || s.DownloadPort != 0 {
			t.Errorf("%s: got %q:%d, want zero", name, s.DownloadAddress, s.DownloadPort)
		}
	}
}

// TestPinnedHysteria2LinkIsRefusedNotUnpinned: pinSHA256 is defined for
// Hysteria2 links, but no engine consumes it (no plan field, no
// renderer). Importing such a link anyway would silently drop the pin,
// so parsing must refuse it (counted unsupported in lists) instead of
// importing an unpinned server.
func TestPinnedHysteria2LinkIsRefusedNotUnpinned(t *testing.T) {
	for _, link := range []string{
		"hysteria2://secret@example.com:443?pinSHA256=PEgHXXPzTsMBr6Uf5FYZ9CDpGHuCkSKpAZcJZU1hRVc%3D#H2",
		"hy2://secret@example.com:443?pin_sha256=PEgHXXPzTsMBr6Uf5FYZ9CDpGHuCkSKpAZcJZU1hRVc%3D#H2",
	} {
		r, err := (LinkParser{}).Parse([]byte(link))
		if err == nil && len(r.Servers) > 0 {
			t.Fatalf("pinned hy2 link was imported without its pin: %#v", r.Servers)
		}
	}
	// In a list, only the pinned link is skipped; neighbours import.
	r, err := (LinkParser{}).Parse([]byte(
		"hysteria2://secret@example.com:443#plain\n" +
			"hysteria2://secret@example.com:443?pinSHA256=PEgHXXPzTsMBr6Uf5FYZ9CDpGHuCkSKpAZcJZU1hRVc%3D#pinned"))
	if err != nil {
		t.Fatal(err)
	}
	if r.Report.Imported != 1 || r.Report.Unsupported != 1 {
		t.Fatalf("list = %+v, want 1 imported and 1 unsupported", r.Report)
	}
}

// TestParseClashDuplicatesByStableKey is the regression test for the
// duplicate-ValueKey bug: parseYAML appended every proxy without the
// StableKey deduplication parseList already had, so a Clash subscription
// listing one endpoint+UUID under two names produced two specs with the
// same identity.
func TestParseClashDuplicatesByStableKey(t *testing.T) {
	const uuid = "123e4567-e89b-12d3-a456-426614174000"
	payload := "proxies:\n" +
		"  - {name: First, type: vless, server: a.example.com, port: 443, uuid: " + uuid + "}\n" +
		"  - {name: Second, type: vless, server: a.example.com, port: 443, uuid: " + uuid + "}\n"
	r, err := (LinkParser{}).Parse([]byte(payload))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 1 || r.Servers[0].DisplayName != "First" {
		t.Fatalf("servers = %#v, want only the first entry kept", r.Servers)
	}
	if r.Report.Imported != 1 || r.Report.SkippedDuplicates != 1 {
		t.Fatalf("report = %+v, want 1 imported and 1 skipped duplicate", r.Report)
	}
	if len(r.Report.DuplicateItems) != 1 || r.Report.DuplicateItems[0].Index != 1 || r.Report.DuplicateItems[0].Reason != "duplicate server" {
		t.Fatalf("duplicate items = %#v, want one entry at index 1", r.Report.DuplicateItems)
	}
}

// TestParseJSONDuplicatesByStableKey is the same regression for the
// sing-box JSON path of parseJSON.
func TestParseJSONDuplicatesByStableKey(t *testing.T) {
	const uuid = "123e4567-e89b-12d3-a456-426614174000"
	payload := `{"outbounds":[` +
		`{"type":"vless","tag":"First","server":"a.example.com","server_port":443,"uuid":"` + uuid + `"},` +
		`{"type":"vless","tag":"Second","server":"a.example.com","server_port":443,"uuid":"` + uuid + `"}]}`
	r, err := (LinkParser{}).Parse([]byte(payload))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 1 || r.Servers[0].DisplayName != "First" {
		t.Fatalf("servers = %#v, want only the first entry kept", r.Servers)
	}
	if r.Report.Imported != 1 || r.Report.SkippedDuplicates != 1 {
		t.Fatalf("report = %+v, want 1 imported and 1 skipped duplicate", r.Report)
	}
	if len(r.Report.DuplicateItems) != 1 || r.Report.DuplicateItems[0].Index != 1 || r.Report.DuplicateItems[0].Reason != "duplicate server" {
		t.Fatalf("duplicate items = %#v, want one entry at index 1", r.Report.DuplicateItems)
	}
}

// TestParseJSONAndYAMLKeepDistinctServers guards the deduplication against
// overreach: a different UUID or a different endpoint is a different
// server, and xray-profile entries keep distinct remarks (their
// StableKey includes the display name).
func TestParseJSONAndYAMLKeepDistinctServers(t *testing.T) {
	const uuidA = "123e4567-e89b-12d3-a456-426614174000"
	const uuidB = "123e4567-e89b-42d3-a456-426614174001"
	cases := map[string]string{
		"json different uuid": `{"outbounds":[` +
			`{"type":"vless","tag":"One","server":"a.example.com","server_port":443,"uuid":"` + uuidA + `"},` +
			`{"type":"vless","tag":"Two","server":"a.example.com","server_port":443,"uuid":"` + uuidB + `"}]}`,
		"json different endpoint": `{"outbounds":[` +
			`{"type":"vless","tag":"One","server":"a.example.com","server_port":443,"uuid":"` + uuidA + `"},` +
			`{"type":"vless","tag":"Two","server":"b.example.com","server_port":443,"uuid":"` + uuidA + `"}]}`,
		"yaml different uuid": "proxies:\n" +
			"  - {name: One, type: vless, server: a.example.com, port: 443, uuid: " + uuidA + "}\n" +
			"  - {name: Two, type: vless, server: a.example.com, port: 443, uuid: " + uuidB + "}\n",
		"yaml different endpoint": "proxies:\n" +
			"  - {name: One, type: vless, server: a.example.com, port: 443, uuid: " + uuidA + "}\n" +
			"  - {name: Two, type: vless, server: b.example.com, port: 443, uuid: " + uuidA + "}\n",
	}
	for name, payload := range cases {
		r, err := (LinkParser{}).Parse([]byte(payload))
		if err != nil {
			t.Fatalf("%s: %v", name, err)
		}
		if len(r.Servers) != 2 || r.Report.SkippedDuplicates != 0 {
			t.Errorf("%s: servers = %d, report = %+v, want both servers kept", name, len(r.Servers), r.Report)
		}
	}
	// Xray profiles on one endpoint with different remarks are distinct
	// (the name is part of their StableKey); the exact same profile
	// twice is a duplicate on the xray-config append site.
	config := func(name string) string {
		return `{"remarks":"` + name + `","inbounds":[{"listen":"127.0.0.1","port":10808,"protocol":"socks"}],` +
			`"outbounds":[{"tag":"proxy","protocol":"vless","settings":{"vnext":[{"address":"185.92.222.239","port":443,` +
			`"users":[{"id":"123e4567-e89b-12d3-a456-426614174000","encryption":"none"}]}]},` +
			`"streamSettings":{"network":"xhttp","security":"reality","realitySettings":{"publicKey":"k","shortId":"s"}}},` +
			`{"protocol":"freedom","tag":"direct"}],"routing":{"rules":[{"domain":["domain:openai.com"],"outboundTag":"proxy"}]}}`
	}
	r, err := (LinkParser{}).Parse([]byte("[" + config("One") + "," + config("Two") + "]"))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 2 || r.Report.SkippedDuplicates != 0 {
		t.Fatalf("profiles with different remarks: servers = %d, report = %+v, want both kept", len(r.Servers), r.Report)
	}
	r, err = (LinkParser{}).Parse([]byte("[" + config("Same") + "," + config("Same") + "]"))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 1 || r.Report.SkippedDuplicates != 1 || len(r.Report.DuplicateItems) != 1 {
		t.Fatalf("identical profiles: servers = %d, report = %+v, want 1 kept and 1 skipped duplicate", len(r.Servers), r.Report)
	}
}
