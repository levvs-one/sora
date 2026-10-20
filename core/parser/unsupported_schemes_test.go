package parser

import (
	"testing"
)

// T023: sora has no OpenVPN transport and must never import its links as
// servers. OpenVPN is detectable by design (open opcode byte, deterministic
// handshake; Xue et al., USENIX Security 2022); tls-crypt/XOR do not save
// it (FOSDEM 2026). The product decision is "no OpenVPN, not even as a
// legacy option" — an openvpn:// link must land in the import report as
// unsupported, never as a server. If OpenVPN is ever added, it must arrive
// as an explicit legacy-only protocol with a warning; this test locks the
// rejection contract either way.
func TestOpenVPNLinksAreRejected(t *testing.T) {
	for _, link := range []string{
		"openvpn://vpn.example.com:1194",
		"openvpn://user:pass@vpn.example.com:443?transport=tcp",
		"OPENVPN://vpn.example.com:1194",
	} {
		r, err := (LinkParser{}).Parse([]byte(link))
		if err != nil {
			t.Fatalf("Parse(%q) = %v, want a report, not an error", link, err)
		}
		if len(r.Servers) != 0 {
			t.Errorf("Parse(%q) imported %d servers, want 0", link, len(r.Servers))
		}
		if r.Report.Unsupported != 1 {
			t.Errorf("Parse(%q): unsupported = %d, want 1 (%+v)", link, r.Report.Unsupported, r.Report)
		}
	}
	// Mixed lists: the openvpn line is skipped, the good one imports.
	r, err := (LinkParser{}).Parse([]byte(
		"openvpn://vpn.example.com:1194\n" +
			"ss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388#SS"))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 1 || r.Servers[0].Protocol != "shadowsocks" {
		t.Errorf("mixed import = %+v, want only the SS server", r.Servers)
	}
	if r.Report.Unsupported != 1 {
		t.Errorf("mixed import: unsupported = %d, want 1", r.Report.Unsupported)
	}
}
