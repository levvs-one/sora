package ext

import "testing"

// Wave-B fuzz targets for the extension data formats that had no target
// yet: the signed-catalog document, background-worker configs, and the
// minisign text formats. Catalog bytes arrive from the network by
// design; the rest arrive from extension packages and user pastes.

// FuzzParseCatalog drives the catalog document decoder.
func FuzzParseCatalog(f *testing.F) {
	f.Add([]byte(`{"version":1,"extensions":[]}`))
	f.Add([]byte(`{"version":1,"extensions":[{"id":"a.b","name":"x","version":"1.0.0"}]}`))
	f.Add([]byte(`[]`))
	f.Fuzz(func(_ *testing.T, b []byte) {
		_, _ = ParseCatalog(b)
	})
}

// FuzzParseBackgroundConfig drives the background worker config decoder.
func FuzzParseBackgroundConfig(f *testing.F) {
	f.Add([]byte(`{"intervalSeconds":60}`))
	f.Add([]byte(`{}`))
	f.Fuzz(func(_ *testing.T, b []byte) {
		_, _ = ParseBackgroundConfig(b)
	})
}

// FuzzParseSignText drives the minisign public-key and signature text
// parsers (both are pasted/downloaded text formats).
func FuzzParseSignText(f *testing.F) {
	f.Add("untrusted comment: sora extension signing key\nRWTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==")
	f.Add("untrusted comment: signature from sora sign\nRWQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==")
	f.Add("")
	f.Fuzz(func(_ *testing.T, s string) {
		_, _, _ = ParsePublicKey(s)
		_, _ = ParseSignature(s)
	})
}
