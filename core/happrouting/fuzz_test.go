package happrouting

import "testing"

// Wave-B fuzz targets for the happRouting payload decoders. Payloads
// arrive inside provider deep links and subscription bodies, i.e. from
// parties the user does not control.

// FuzzDecodePayload drives the full payload entry (link unwrap, base64
// layers, JSON) and, on success, the encoder and converter, which must
// never panic on a profile the decoder accepted.
func FuzzDecodePayload(f *testing.F) {
	f.Add(`{"Name":"seed","GlobalProxy":true,"RemoteDNS":"1.1.1.1","DirectSites":["example.com"]}`)
	f.Add("happ://routing/onadd/eyJOYW1lIjoic2VlZCJ9")
	f.Add("eyJOYW1lIjoic2VlZCJ9")
	f.Add("")
	f.Fuzz(func(_ *testing.T, s string) {
		p, err := DecodePayload(s)
		if err != nil {
			return
		}
		_, _ = p.EncodeLink()
		_ = p.Convert("proxy")
		_, _ = p.MarshalJSON()
	})
}

// FuzzParseJSON drives the raw-JSON decoder directly.
func FuzzParseJSON(f *testing.F) {
	f.Add([]byte(`{"Name":"seed","ProxySites":["a.example"],"DirectIP":["10.0.0.0/8"]}`))
	f.Add([]byte(`{}`))
	f.Add([]byte(`{"Name":123}`))
	f.Fuzz(func(_ *testing.T, b []byte) {
		p, err := ParseJSON(b)
		if err != nil {
			return
		}
		_ = p.Convert("proxy")
	})
}
