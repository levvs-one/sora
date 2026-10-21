package parser

import "testing"

// Wave-B fuzz targets: direct entry into each format branch, so a run
// spends its budget inside one decoder instead of re-paying detection,
// and the olcrtc parse∘ShareLink identity the format promises.

// FuzzParseJSONFormats drives parseJSON in each of its three shapes
// (SIP008, sing-box, Xray/Remnawave).
func FuzzParseJSONFormats(f *testing.F) {
	f.Add([]byte(`{"version":2,"servers":[{"id":1,"remarks":"r","server":"a.example","server_port":8388,"method":"aes-256-gcm","password":"pw"}]}`), uint8(0))
	f.Add([]byte(`{"outbounds":[{"type":"shadowsocks","tag":"p","server":"a.example","server_port":8388,"method":"aes-256-gcm","password":"pw"}]}`), uint8(1))
	f.Add([]byte(`[{"remarks":"x","outbounds":[{"protocol":"trojan","settings":{"servers":[{"address":"a.example","port":443,"password":"pw"}]}}]}]`), uint8(2))
	f.Add([]byte(`{"version":2,"servers":[]}`), uint8(0))
	f.Add([]byte(`null`), uint8(1))
	formats := []Format{FormatSIP008, FormatSingBox, FormatXray}
	f.Fuzz(func(_ *testing.T, b []byte, which uint8) {
		_, _ = (LinkParser{MaxItems: 100}).parseJSON(b, formats[which%uint8(len(formats))])
	})
}

// FuzzParseYAML drives the Clash subset decoder directly: yaml.v3 into
// []map[string]any plus the per-proxy spec mapping (alias and anchor
// shapes included in the seeds on purpose).
func FuzzParseYAML(f *testing.F) {
	f.Add([]byte("proxies:\n  - name: a\n    type: ss\n    server: a.example\n    port: 8388\n    cipher: aes-256-gcm\n    password: pw"))
	f.Add([]byte("proxies: []"))
	f.Add([]byte("proxies:\n  - &x {name: a, type: vmess, server: a.example, port: 443, uuid: 123e4567-e89b-12d3-a456-426614174000}\n  - *x"))
	f.Add([]byte("proxies:\n  - name: [nested, list]\n    type: {deep: map}"))
	f.Fuzz(func(_ *testing.T, b []byte) {
		_, _ = (LinkParser{MaxItems: 100}).parseYAML(b)
	})
}

// FuzzParseWG drives the WireGuard config decoder directly.
func FuzzParseWG(f *testing.F) {
	f.Add("[Interface]\nPrivateKey = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\nAddress = 10.0.0.2/32\n[Peer]\nPublicKey = BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBE=\nEndpoint = a.example:51820")
	f.Add("[Interface]\nPrivateKey = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\n[Peer]\nPublicKey = BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBE=\nEndpoint = [2001:db8::1]:51820\nAllowedIPs = ::/0")
	f.Fuzz(func(_ *testing.T, s string) {
		_, _ = (LinkParser{MaxItems: 100}).parseWG(s)
	})
}

// FuzzOlcRTCLink drives the hand-cut olcrtc:// grammar and asserts the
// identity the format documents: an accepted link re-emitted through
// ShareLink parses back to the same stable identity.
func FuzzOlcRTCLink(f *testing.F) {
	const key = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	f.Add("olcrtc://wbstream?datachannel@room-01#" + key + "$seed")
	f.Add("olcrtc://jitsi?vp8channel<vp8-fps=30>@https://meet.jit.si/room#" + key)
	f.Add("olcrtc://telemost?videochannel<video-codec=qrcode>@room#" + key + "$name")
	f.Add("olcrtc://none?seichannel<batch=1&frag=1200>@r#" + key)
	f.Fuzz(func(t *testing.T, s string) {
		r, err := (LinkParser{MaxItems: 100}).Parse([]byte(s))
		if err != nil {
			return
		}
		for _, srv := range r.Servers {
			if srv.Protocol != "olcrtc" {
				continue
			}
			link, err := srv.ShareLink()
			if err != nil {
				t.Fatalf("ShareLink(%q) failed: %v", s, err)
			}
			back, err := (LinkParser{MaxItems: 100}).Parse([]byte(link))
			if err != nil {
				t.Fatalf("reparse of %q (from %q) failed: %v", link, s, err)
			}
			if len(back.Servers) != 1 || back.Servers[0].StableKey() != srv.StableKey() {
				t.Fatalf("olcrtc round trip changed identity: %q -> %q (%#v vs %#v)", s, link, srv, back.Servers)
			}
		}
	})
}
