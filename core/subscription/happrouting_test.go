package subscription

import (
	"encoding/base64"
	"net/http"
	"testing"
)

const happPayload = "eyJOYW1lIjoiUHJvdmlkZXIgUlUiLCJEaXJlY3RTaXRlcyI6WyJiYW5rLmV4YW1wbGUiXX0="

func TestHappRoutingFromHeaderAndBodyLine(t *testing.T) {
	// The header wins over the body line, like every other Info key.
	header := http.Header{}
	header.Set("happ-routing", "happ://routing/add/"+happPayload)
	body := []byte("#happ-routing: ignored-body-value\nvless://x@h:1#a\n")
	info := parseInfo(header, body)
	if info.HappRouting != "happ://routing/add/"+happPayload {
		t.Fatalf("header happ-routing = %q", info.HappRouting)
	}

	info = parseInfo(http.Header{}, body)
	if info.HappRouting != "ignored-body-value" {
		t.Fatalf("body happ-routing = %q", info.HappRouting)
	}

	// No routing anywhere: empty, never an error.
	info = parseInfo(http.Header{}, []byte("vless://x@h:1#a\n"))
	if info.HappRouting != "" {
		t.Fatalf("absent happ-routing = %q", info.HappRouting)
	}
}

func TestProviderRoutingFromPayload(t *testing.T) {
	doc := `{"Name":"P","DirectSites":["bank.example"],"BlockIp":["198.51.100.0/24"],"RemoteDNSType":"DoH","RemoteDNSIP":"https://dns.example/dns-query"}`
	got, err := ProviderRoutingFromPayload(base64.StdEncoding.EncodeToString([]byte(doc)))
	if err != nil {
		t.Fatal(err)
	}
	if got.Name != "P" || len(got.Rules) != 2 {
		t.Fatalf("converted = %+v", got)
	}
	if got.Rules[0].OutboundID != "reject" || got.Rules[1].OutboundID != "direct" {
		t.Fatalf("rule order/targets = %+v", got.Rules)
	}
	if got.RemoteDNS != "DoH https://dns.example/dns-query" {
		t.Fatalf("remote dns = %q", got.RemoteDNS)
	}
	if _, err := ProviderRoutingFromPayload("!!!broken!!!"); err == nil {
		t.Fatal("a broken payload must be an error, so refresh keeps the old layer")
	}
}

func TestOverrideStoreKeepsProviderRouting(t *testing.T) {
	s := NewOverrideStore(t.TempDir())
	const id = "0123456789abcdef"
	o := &Override{
		Renames:         map[string]string{"a": "b"},
		ProviderRouting: &ProviderRouting{Name: "P", Rules: []OverrideRule{{Destination: "domain:x.example", OutboundID: "direct"}}},
	}
	if err := s.Save(id, o); err != nil {
		t.Fatal(err)
	}
	got, err := s.Load(id)
	if err != nil {
		t.Fatal(err)
	}
	if got.ProviderRouting == nil || len(got.ProviderRouting.Rules) != 1 || got.Renames["a"] != "b" {
		t.Fatalf("round trip = %+v", got)
	}
	// An override holding only a provider layer is not "empty": its
	// file must survive, and clearing the layer removes it.
	if err := s.Save(id, &Override{ProviderRouting: got.ProviderRouting}); err != nil {
		t.Fatal(err)
	}
	if got, _ := s.Load(id); got.ProviderRouting == nil {
		t.Fatal("a provider-only override was treated as empty and dropped")
	}
	if err := s.Save(id, &Override{}); err != nil {
		t.Fatal(err)
	}
	if got, _ := s.Load(id); got.ProviderRouting != nil {
		t.Fatalf("clearing must remove the layer: %+v", got)
	}
}
