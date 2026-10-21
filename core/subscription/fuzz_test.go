package subscription

import (
	"net/http"
	"testing"
)

// Wave-B fuzz targets for the subscription metadata surface: everything
// here is parsed from provider-controlled bytes (response headers and
// bodies), so it is attacker-shaped by definition.

// FuzzParseInfo drives parseInfo over a fuzzed body plus fuzzed values
// for the four headers providers actually use to carry metadata.
func FuzzParseInfo(f *testing.F) {
	f.Add([]byte("#profile-title: seed\nvless://123e4567-e89b-12d3-a456-426614174000@a.example:443"), "upload=1; download=2; total=100; expire=1893456000", "base64:c2VlZA==", "https://example.com/panel")
	f.Add([]byte(""), "", "", "")
	f.Add([]byte("#subscription-userinfo: upload=18446744073709551615; download=0; total=0; expire=-1"), "garbage", "", "")
	f.Fuzz(func(_ *testing.T, body []byte, userinfo, title, web string) {
		h := http.Header{}
		if userinfo != "" {
			h.Set("subscription-userinfo", userinfo)
		}
		if title != "" {
			h.Set("profile-title", title)
		}
		if web != "" {
			h.Set("profile-web-page-url", web)
		}
		_ = parseInfo(h, body)
		_, _ = bodyHeaders(body)
		_, _ = decodeBody(body)
	})
}

// FuzzSplitFallback drives the fallback-reference splitter/joiner pair.
func FuzzSplitFallback(f *testing.F) {
	f.Add("https://a.example/sub")
	f.Add("https://a.example/sub|https://b.example/sub")
	f.Add("|")
	f.Add("https://a.example/sub|")
	f.Fuzz(func(_ *testing.T, s string) {
		primary, fallback, err := SplitFallback(s)
		if err != nil {
			return
		}
		_ = JoinFallback(primary, fallback)
	})
}

// FuzzProviderRoutingFromPayload drives the happRouting payload path
// (deep link / bare base64 / raw JSON) through conversion into the
// stored routing layer.
func FuzzProviderRoutingFromPayload(f *testing.F) {
	f.Add(`{"Name":"seed","GlobalProxy":true}`)
	f.Add("happ://routing/onadd/eyJOYW1lIjoic2VlZCJ9")
	f.Add("")
	f.Fuzz(func(_ *testing.T, s string) {
		_, _ = ProviderRoutingFromPayload(s)
	})
}
