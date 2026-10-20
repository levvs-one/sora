package happrouting

import (
	"encoding/base64"
	"errors"
	"strings"
	"testing"
)

// goldenJSON is a routing document assembled field by field from the
// reconstructed HappRoutingData schema (see the package doc): every
// field the builder emits, in the builder's capitalisation.
const goldenJSON = `{"Name":"Provider RU","GlobalProxy":true,"FakeDNS":false,"UseChunkFiles":false,"RemoteDNSType":"DoH","RemoteDNSIP":"https://dns.example/dns-query","DomesticDNSType":"DoU","DomesticDNSIP":"77.88.8.8","DirectSites":["geosite:category-ru","bank.example"],"DirectIp":["geoip:ru","10.0.0.0/8"],"ProxySites":["geosite:youtube","video.example"],"ProxyIp":["203.0.113.7"],"BlockSites":["ads.example"],"BlockIp":["198.51.100.0/24"],"DomainStrategy":"IPIfNonMatch"}`

// goldenBase64 is goldenJSON in the builder's transport encoding
// (standard base64 with padding), computed independently of this
// package's encoder.
const goldenBase64 = "eyJOYW1lIjoiUHJvdmlkZXIgUlUiLCJHbG9iYWxQcm94eSI6dHJ1ZSwiRmFrZUROUyI6ZmFsc2UsIlVzZUNodW5rRmlsZXMiOmZhbHNlLCJSZW1vdGVETlNUeXBlIjoiRG9IIiwiUmVtb3RlRE5TSVAiOiJodHRwczovL2Rucy5leGFtcGxlL2Rucy1xdWVyeSIsIkRvbWVzdGljRE5TVHlwZSI6IkRvVSIsIkRvbWVzdGljRE5TSVAiOiI3Ny44OC44LjgiLCJEaXJlY3RTaXRlcyI6WyJnZW9zaXRlOmNhdGVnb3J5LXJ1IiwiYmFuay5leGFtcGxlIl0sIkRpcmVjdElwIjpbImdlb2lwOnJ1IiwiMTAuMC4wLjAvOCJdLCJQcm94eVNpdGVzIjpbImdlb3NpdGU6eW91dHViZSIsInZpZGVvLmV4YW1wbGUiXSwiUHJveHlJcCI6WyIyMDMuMC4xMTMuNyJdLCJCbG9ja1NpdGVzIjpbImFkcy5leGFtcGxlIl0sIkJsb2NrSXAiOlsiMTk4LjUxLjEwMC4wLzI0Il0sIkRvbWFpblN0cmF0ZWd5IjoiSVBJZk5vbk1hdGNoIn0="

func TestGoldenLinkDecodes(t *testing.T) {
	for name, payload := range map[string]string{
		"deep link":   "happ://routing/add/" + goldenBase64,
		"bare base64": goldenBase64,
		"raw json":    goldenJSON,
		// The subscription-settings field may hold the whole link
		// (the builder's output pasted verbatim).
		"link in field": "happ://routing/add/" + goldenBase64,
	} {
		p, err := DecodePayload(payload)
		if err != nil {
			t.Fatalf("%s: %v", name, err)
		}
		if p.Name != "Provider RU" || p.GlobalProxy == nil || !*p.GlobalProxy {
			t.Fatalf("%s: name/globalproxy = %q/%v", name, p.Name, p.GlobalProxy)
		}
		if p.RemoteDNSIP != "https://dns.example/dns-query" || p.DomesticDNSIP != "77.88.8.8" {
			t.Fatalf("%s: dns = %q/%q", name, p.RemoteDNSIP, p.DomesticDNSIP)
		}
		if len(p.DirectSites) != 2 || len(p.BlockIP) != 1 || p.DomainStrategy != "IPIfNonMatch" {
			t.Fatalf("%s: lists/strategy wrong: %+v", name, p)
		}
	}
}

func TestGoldenConversion(t *testing.T) {
	p, err := DecodePayload(goldenBase64)
	if err != nil {
		t.Fatal(err)
	}
	got := p.Convert("out-1")
	gotSentinel := p.Convert("")
	if len(gotSentinel.Rules) != 9 {
		t.Fatalf("sentinel convert: %d rules", len(gotSentinel.Rules))
	}
	if len(got.Rules) != 9 {
		t.Fatalf("convert: %d rules, want 9: %+v", len(got.Rules), got.Rules)
	}
	for i, rule := range got.Rules {
		wantTarget := []string{"reject", "reject", "direct", "direct", "direct", "direct", "out-1", "out-1", "out-1"}[i]
		wantDest := []string{
			"domain:ads.example", "198.51.100.0/24",
			"geosite:category-ru", "domain:bank.example", "geoip:ru", "10.0.0.0/8",
			"geosite:youtube", "domain:video.example", "203.0.113.7/32",
		}[i]
		if rule.Destination != wantDest || rule.OutboundID != wantTarget {
			t.Errorf("rule %d = %+v, want {%s %s}", i, rule, wantDest, wantTarget)
		}
	}
	if got.RemoteDNS != "DoH https://dns.example/dns-query" || got.DomesticDNS != "DoU 77.88.8.8" {
		t.Errorf("dns carried = %q / %q", got.RemoteDNS, got.DomesticDNS)
	}
	// Every carried field is accounted for: DNS + DomainStrategy are
	// recorded-not-applied, the lists and GlobalProxy=true applied.
	var applied, recorded []string
	for _, n := range got.Notes {
		if n.Applied {
			applied = append(applied, n.Field)
		} else {
			recorded = append(recorded, n.Field)
		}
	}
	if len(applied) != 2 || len(recorded) != 3 {
		t.Errorf("notes applied=%v recorded=%v", applied, recorded)
	}
}

func TestEncodeLinkRoundTrip(t *testing.T) {
	p, err := DecodePayload(goldenBase64)
	if err != nil {
		t.Fatal(err)
	}
	link, err := p.EncodeLink()
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(link, "happ://routing/add/") {
		t.Fatalf("link = %q", link)
	}
	back, err := DecodePayload(link)
	if err != nil {
		t.Fatal(err)
	}
	if back.Name != p.Name || len(back.DirectSites) != 2 || back.RemoteDNSIP != p.RemoteDNSIP {
		t.Fatalf("round trip drift: %+v vs %+v", back, p)
	}
	// The encoded form must be standard padded base64 of JSON.
	raw, err := base64.StdEncoding.DecodeString(strings.TrimPrefix(link, "happ://routing/add/"))
	if err != nil || !strings.Contains(string(raw), `"DirectIp"`) {
		t.Fatalf("encoded payload is not builder-shaped: %v %s", err, raw)
	}
}

func TestSpellingVariantsAndShapes(t *testing.T) {
	// RemoteDNSIp spelling (older Happ), string list, string bool,
	// numeric LastUpdated: all tolerated by the builder itself.
	doc := `{"name":"x","globalproxy":"false","RemoteDNSIp":"1.1.1.1","DomesticDNSIp":"8.8.8.8","LastUpdated":1720000000,"DirectSites":"a.example\nb.example","FakeDNS":1}`
	p, err := ParseJSON([]byte(doc))
	if err != nil {
		t.Fatal(err)
	}
	if p.RemoteDNSIP != "1.1.1.1" || p.DomesticDNSIP != "8.8.8.8" {
		t.Fatalf("dns ip variants: %q %q", p.RemoteDNSIP, p.DomesticDNSIP)
	}
	if p.GlobalProxy == nil || *p.GlobalProxy {
		t.Fatalf("globalproxy string false = %v", p.GlobalProxy)
	}
	if p.FakeDNS == nil || !*p.FakeDNS {
		t.Fatalf("fakedns numeric = %v", p.FakeDNS)
	}
	if p.LastUpdated != "1720000000" || len(p.DirectSites) != 2 {
		t.Fatalf("updated/sites: %q %v", p.LastUpdated, p.DirectSites)
	}
	conv := p.Convert("")
	// GlobalProxy=false is recorded, never applied.
	found := false
	for _, n := range conv.Notes {
		if n.Field == "GlobalProxy" && !n.Applied {
			found = true
		}
	}
	if !found {
		t.Fatalf("GlobalProxy=false note missing: %+v", conv.Notes)
	}
}

func TestEntryClassification(t *testing.T) {
	p := &Profile{
		DirectSites: []string{"*.wild.example", "https://url.example/path", "GeoSite:Mixed", "single-label", "bad entry", "10.1.2.3"},
		DirectIP:    []string{"2001:db8::1", "192.168.0.0/16", "domain-in-ip-list.example"},
	}
	conv := p.Convert("")
	want := map[string]bool{
		"domain:wild.example":              true,
		"domain:url.example":               true,
		"geosite:Mixed":                    true,
		"10.1.2.3/32":                      true,
		"2001:db8::1/128":                  true,
		"192.168.0.0/16":                   true,
		"domain:domain-in-ip-list.example": true,
	}
	for _, r := range conv.Rules {
		if !want[r.Destination] {
			t.Errorf("unexpected rule %+v", r)
		}
		delete(want, r.Destination)
	}
	if len(want) != 0 {
		t.Errorf("missing rules: %v", want)
	}
	if conv.Skipped != 2 { // "single-label" and "bad entry"
		t.Errorf("skipped = %d, want 2", conv.Skipped)
	}
}

// Boundary vectors the golden tests do not cover: overlap between
// lists, duplicates inside one list, and the all-empty profile. The
// expectations pin the converter's existing semantics, not new ones.
func TestConversionBoundaries(t *testing.T) {
	t.Run("same destination in direct and proxy keeps both, direct first", func(t *testing.T) {
		// Dedup is per (destination, target): the same site listed for
		// direct and for proxy yields two rules. Conversion order is
		// block, direct, proxy and the engines match first-hit, so the
		// direct rule is the one that takes effect.
		p := &Profile{
			DirectSites: []string{"both.example"},
			ProxySites:  []string{"both.example"},
		}
		conv := p.Convert("")
		if len(conv.Rules) != 2 {
			t.Fatalf("rules = %+v, want the direct and proxy pair", conv.Rules)
		}
		if conv.Rules[0] != (Rule{Destination: "domain:both.example", OutboundID: TargetDirect}) ||
			conv.Rules[1] != (Rule{Destination: "domain:both.example", OutboundID: "proxy"}) {
			t.Errorf("rules = %+v, want direct first, then proxy", conv.Rules)
		}
	})

	t.Run("duplicates inside one list collapse to one rule", func(t *testing.T) {
		// Exact repeats — including repeats that only emerge after
		// classification (case, wildcard prefix) — dedup to one rule.
		p := &Profile{DirectSites: []string{"dup.example", "dup.example", "DUP.example", "*.dup.example"}}
		conv := p.Convert("")
		if len(conv.Rules) != 1 || conv.Rules[0].Destination != "domain:dup.example" {
			t.Errorf("rules = %+v, want one domain:dup.example rule", conv.Rules)
		}
		if conv.Skipped != 0 {
			t.Errorf("skipped = %d, want 0: duplicates are deduped, not skipped", conv.Skipped)
		}
	})

	t.Run("all lists empty converts to zero rules and no list note", func(t *testing.T) {
		conv := (&Profile{Name: "empty"}).Convert("")
		if len(conv.Rules) != 0 {
			t.Errorf("rules = %+v, want none", conv.Rules)
		}
		if conv.Skipped != 0 {
			t.Errorf("skipped = %d, want 0", conv.Skipped)
		}
		// Honest accounting: with nothing carried by the document
		// there is nothing to note — in particular no applied-lists
		// note for lists that produced no rules.
		if len(conv.Notes) != 0 {
			t.Errorf("notes = %+v, want none for an empty profile", conv.Notes)
		}
	})
}

func TestInvalidPayloadsFailHonestly(t *testing.T) {
	for name, payload := range map[string]string{
		"empty":          "",
		"not base64":     "!!!not-a-payload!!!",
		"base64 of text": base64.StdEncoding.EncodeToString([]byte("just some servers")),
		"json array":     `["vless://x"]`,
		"json scalar":    `42`,
		"wrong types":    `{"DirectSites": 42}`,
		"wrong link":     "happ://add/https://example.com/sub",
		"truncated b64":  goldenBase64[:len(goldenBase64)-7],
	} {
		if _, err := DecodePayload(payload); !errors.Is(err, ErrInvalid) {
			t.Errorf("%s: err = %v, want ErrInvalid", name, err)
		}
	}
}
