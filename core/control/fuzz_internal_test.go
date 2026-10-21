package control

import (
	"os"
	"path/filepath"
	"testing"

	"google.golang.org/protobuf/proto"

	"github.com/levvs-one/sora-client/core/custom"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// Wave-B fuzz targets for the control plane's stored-data decoders.
// Everything here decodes bytes that were written earlier — possibly by
// an older core, a crashed write, or a hand-edited data directory — and
// several of them decode provider-shaped material (subscription records
// and their stored proto lists). All must fail closed, never panic.

// FuzzDecodeRecord drives the subscription record decoder and the
// record's own derived views.
func FuzzDecodeRecord(f *testing.F) {
	f.Add([]byte(`{"v":1,"id":"x","link":"https://a.example/sub"}`))
	f.Add([]byte(`{"v":2}`))
	f.Add([]byte(`{}`))
	f.Add([]byte(`{"v":1,"info":{"title":"t"},"list_parts":3}`))
	f.Fuzz(func(_ *testing.T, b []byte) {
		rec, err := decodeRecord(b)
		if err != nil {
			return
		}
		_ = rec.storedLink()
		_ = rec.interval()
	})
}

// FuzzStoredListProto drives the stored server-list decoder shape: a
// protobuf FetchSubscriptionResponse whose outbounds downstream code
// walks field by field.
func FuzzStoredListProto(f *testing.F) {
	seed := &corev1.FetchSubscriptionResponse{Outbounds: []*corev1.OutboundSpec{
		{Protocol: "vless", Endpoint: &corev1.Endpoint{Host: "a.example", Port: 443}},
	}}
	raw, _ := proto.Marshal(seed)
	f.Add(raw)
	f.Add([]byte{})
	f.Add([]byte{0x0a, 0x03, 0x08, 0x96, 0x01})
	f.Fuzz(func(_ *testing.T, b []byte) {
		var list corev1.FetchSubscriptionResponse
		if err := proto.Unmarshal(b, &list); err != nil {
			return
		}
		for _, o := range list.GetOutbounds() {
			_ = o.GetProtocol()
			_ = o.GetTransport()
			_ = o.GetSecurity()
			_ = o.GetEndpoint().GetHost()
			_ = o.GetEndpoint().GetPort()
			_ = o.GetCredentials().GetReference()
			_ = o.GetBypass()
		}
	})
}

// FuzzCredentialDocument drives the credential-document conversion that
// runs on user-supplied custom-server material: flat credential strings
// become vault documents; documents are detected, never trusted blindly.
func FuzzCredentialDocument(f *testing.F) {
	f.Add("vless", []byte("123e4567-e89b-12d3-a456-426614174000"))
	f.Add("shadowsocks", []byte("aes-256-gcm:password"))
	f.Add("wireguard", []byte("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="))
	f.Add("trojan", []byte(`{"password":"pw","sni":"a.example"}`))
	f.Add("", []byte(""))
	f.Fuzz(func(_ *testing.T, protocol string, raw []byte) {
		_ = isCredentialDocument(raw)
		_ = customCredentialDocument(custom.Protocol(protocol), raw)
	})
}

// FuzzLoadObfsProfile drives the persisted obfuscation profile loader
// (protojson + normalization) from an arbitrary file body.
func FuzzLoadObfsProfile(f *testing.F) {
	f.Add([]byte(`{"suiteName":"seed"}`))
	f.Add([]byte(`{}`))
	f.Add([]byte(`{"unknownField":1}`))
	f.Fuzz(func(t *testing.T, b []byte) {
		path := filepath.Join(t.TempDir(), obfsProfileFile)
		if err := os.WriteFile(path, b, 0o600); err != nil {
			t.Fatal(err)
		}
		_ = loadObfsProfile(path, nil)
	})
}

// FuzzSubscriptionLinkParts drives the stored-link normalization pair:
// whatever a record carries as its link is split and re-validated here
// before every refresh dial.
func FuzzSubscriptionLinkParts(f *testing.F) {
	f.Add("https://a.example/sub")
	f.Add("https://a.example/sub|https://b.example/sub")
	f.Add(" http://a.example/sub ")
	f.Fuzz(func(_ *testing.T, s string) {
		_, _ = normalizedLink(s)
		_, _, _ = subscriptionLinkParts(s)
	})
}
