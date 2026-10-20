package parser

import "testing"

// TestParseSIP008ImportsShadowsocksServers is the regression test for the
// B1 servers audit: SIP008 entries carry no "type" field, and the parser
// used to demand one, so every entry failed validation and a SIP008
// subscription imported zero servers while reporting no error.
func TestParseSIP008ImportsShadowsocksServers(t *testing.T) {
	src := `{"version":1,"servers":[
		{"id":"1","remarks":"tokyo","server":"tokyo.example.com","server_port":8388,"password":"pw1","method":"aes-256-gcm"},
		{"id":"2","remarks":"osaka","server":"osaka.example.com","server_port":8389,"password":"pw2","method":"chacha20-ietf-poly1305","plugin":"v2ray-plugin","plugin_opts":"tls;host=cdn.example.com"},
		{"id":"3","remarks":"tokyo-again","server":"tokyo.example.com","server_port":8388,"password":"pw1","method":"aes-256-gcm"}
	]}`
	r, err := (LinkParser{}).Parse([]byte(src))
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if r.Format != FormatSIP008 {
		t.Fatalf("format = %q, want %q", r.Format, FormatSIP008)
	}
	if len(r.Servers) != 2 || r.Report.Imported != 2 || r.Report.SkippedDuplicates != 1 || r.Report.Invalid != 0 {
		t.Fatalf("servers = %d, report = %+v; want 2 imported, 1 duplicate, 0 invalid", len(r.Servers), r.Report)
	}
	first := r.Servers[0]
	if first.Protocol != "shadowsocks" || first.Host != "tokyo.example.com" || first.Port != 8388 ||
		first.Password != "pw1" || first.Cipher != "aes-256-gcm" || first.DisplayName != "tokyo" {
		t.Fatalf("first server = %+v", first)
	}
	second := r.Servers[1]
	if second.DisplayName != "osaka" || second.Options["ss_plugin"] != "v2ray-plugin" ||
		second.Options["ss_plugin_opts"] != "tls;host=cdn.example.com" {
		t.Fatalf("second server = %+v options=%v", second, second.Options)
	}
}
