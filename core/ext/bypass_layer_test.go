package ext

import (
	"strings"
	"testing"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func tpwsStrategy() *corev1.BypassStrategy {
	return &corev1.BypassStrategy{SplitPos: []string{"1"}, Disorder: true}
}

func nfqwsStrategy() *corev1.BypassStrategy {
	return &corev1.BypassStrategy{
		Desync: []string{"fake", "split2"}, FakeTls: "tls", AutoTtl: true,
		FilterTcp: "80,443", FilterL7: "tls",
	}
}

func TestLayerStoreRoundTrip(t *testing.T) {
	dir := t.TempDir()
	store, err := NewLayerStore(dir)
	if err != nil {
		t.Fatalf("NewLayerStore: %v", err)
	}
	layer := Layer{
		Global: nfqwsStrategy(),
		Bindings: []Binding{
			{Match: "domain:example.com", Strategy: tpwsStrategy()},
			{Match: "203.0.113.0/24", Strategy: nfqwsStrategy()},
		},
	}
	if err := store.Set("com.example.anti", layer); err != nil {
		t.Fatalf("Set: %v", err)
	}
	got, ok := store.Get("com.example.anti")
	if !ok {
		t.Fatal("Get: layer missing after Set")
	}
	if got.UpdatedAt.IsZero() {
		t.Error("Set did not stamp UpdatedAt")
	}
	if got.Global.GetAutoTtl() != true || len(got.Bindings) != 2 ||
		got.Bindings[0].Match != "domain:example.com" ||
		got.Bindings[1].Strategy.GetFilterTcp() != "80,443" {
		t.Errorf("round-trip layer = %+v", got)
	}
	// A fresh store over the same directory sees the same layer.
	reopened, err := NewLayerStore(dir)
	if err != nil {
		t.Fatalf("NewLayerStore (reopen): %v", err)
	}
	got2, ok := reopened.Get("com.example.anti")
	if !ok || got2.UpdatedAt != got.UpdatedAt || len(got2.Bindings) != 2 {
		t.Errorf("reopened layer = %+v, ok=%v", got2, ok)
	}
	// Mutating the returned layer must not corrupt the store.
	got.Global.SplitPos = []string{"9"}
	again, _ := store.Get("com.example.anti")
	if len(again.Global.GetSplitPos()) != 0 {
		t.Error("Get returned a layer aliasing the store")
	}
}

func TestLayerStoreValidationFailsClosed(t *testing.T) {
	store, err := NewLayerStore(t.TempDir())
	if err != nil {
		t.Fatalf("NewLayerStore: %v", err)
	}
	cases := map[string]Layer{
		"empty strategy changes nothing": {Global: &corev1.BypassStrategy{}},
		"unknown desync method":          {Global: &corev1.BypassStrategy{Desync: []string{"bogus"}}},
		"tpws knob on nfqws strategy":    {Global: &corev1.BypassStrategy{Desync: []string{"fake"}, FakeTls: "tls", HostCase: true, FilterTcp: "443", FilterUdp: "443", FilterL7: "tls"}},
		"bad match whitespace":           {Bindings: []Binding{{Match: "exa mple.com", Strategy: tpwsStrategy()}}},
		"bad match port":                 {Bindings: []Binding{{Match: "example.com:443", Strategy: tpwsStrategy()}}},
		"bad match scheme":               {Bindings: []Binding{{Match: "https://example.com", Strategy: tpwsStrategy()}}},
		"bad match empty tag":            {Bindings: []Binding{{Match: "domain:", Strategy: tpwsStrategy()}}},
		"binding without strategy":       {Bindings: []Binding{{Match: "domain:example.com"}}},
		"duplicate match": {Bindings: []Binding{
			{Match: "domain:example.com", Strategy: tpwsStrategy()},
			{Match: "domain:example.com", Strategy: tpwsStrategy()},
		}},
	}
	for name, layer := range cases {
		if err := store.Set("com.example.anti", layer); err == nil {
			t.Errorf("%s: Set succeeded, want refusal", name)
		}
	}
	if _, ok := store.Get("com.example.anti"); ok {
		t.Error("a refused layer was stored")
	}
	// A refused Set leaves the previously stored layer untouched.
	good := Layer{Global: tpwsStrategy()}
	if err := store.Set("com.example.anti", good); err != nil {
		t.Fatalf("Set good: %v", err)
	}
	if err := store.Set("com.example.anti", Layer{Global: &corev1.BypassStrategy{}}); err == nil {
		t.Fatal("Set bad succeeded over a good layer")
	}
	got, _ := store.Get("com.example.anti")
	if len(got.Global.GetSplitPos()) != 1 {
		t.Errorf("stored layer changed after a refused Set: %+v", got.Global)
	}
}

func TestLayerStoreLimits(t *testing.T) {
	store, err := NewLayerStore("")
	if err != nil {
		t.Fatalf("NewLayerStore: %v", err)
	}
	// Binding count: MaxBypassBindings+1 distinct matches.
	tooMany := Layer{}
	for i := 0; i <= MaxBypassBindings; i++ {
		tooMany.Bindings = append(tooMany.Bindings, Binding{
			Match:    "domain:h" + itoaTest(i) + ".example.com",
			Strategy: tpwsStrategy(),
		})
	}
	if err := store.Set("com.example.anti", tooMany); err == nil {
		t.Error("Set with >256 bindings succeeded")
	}
	// Serialized size: one valid strategy whose fake payload name
	// balloons the protojson document past 64 KiB.
	big := Layer{Global: &corev1.BypassStrategy{
		Desync: []string{"fake"}, FakeTls: strings.Repeat("a", MaxBypassLayerBytes),
		FilterTcp: "443", FilterL7: "tls",
	}}
	if err := store.Set("com.example.big", big); err == nil {
		t.Error("Set with an oversized layer succeeded")
	}
}

func itoaTest(i int) string {
	if i == 0 {
		return "0"
	}
	var buf [8]byte
	pos := len(buf)
	for i > 0 {
		pos--
		buf[pos] = byte('0' + i%10)
		i /= 10
	}
	return string(buf[pos:])
}

func TestLayerStoreDeleteAndListOrder(t *testing.T) {
	store, err := NewLayerStore("")
	if err != nil {
		t.Fatalf("NewLayerStore: %v", err)
	}
	base := time.Date(2026, 10, 21, 0, 0, 0, 0, time.UTC)
	clock := base
	store.Now = func() time.Time { return clock }
	mk := func() Layer { return Layer{Global: tpwsStrategy()} }
	if err := store.Set("b.ext", mk()); err != nil {
		t.Fatal(err)
	}
	clock = base.Add(time.Hour)
	if err := store.Set("a.ext", mk()); err != nil {
		t.Fatal(err)
	}
	if err := store.Set("c.ext", mk()); err != nil {
		t.Fatal(err)
	}
	list := store.List()
	if len(list) != 3 {
		t.Fatalf("List len = %d", len(list))
	}
	// Newest first; the tie between a.ext and c.ext breaks by id.
	if list[0].ID != "a.ext" || list[1].ID != "c.ext" || list[2].ID != "b.ext" {
		t.Errorf("List order = %s, %s, %s; want a.ext, c.ext, b.ext",
			list[0].ID, list[1].ID, list[2].ID)
	}
	if err := store.Delete("a.ext"); err != nil {
		t.Fatalf("Delete: %v", err)
	}
	if _, ok := store.Get("a.ext"); ok {
		t.Error("deleted layer still present")
	}
	if err := store.Delete("a.ext"); err != nil {
		t.Errorf("Delete of a missing layer: %v", err)
	}
	if got := store.List(); len(got) != 2 {
		t.Errorf("List after Delete len = %d", len(got))
	}
}

func TestValidateBypassMatch(t *testing.T) {
	valid := []string{
		"example.com", "domain:example.com", "full:sub.example.co.uk",
		"192.0.2.1", "192.0.2.0/24", "2001:db8::1", "2001:db8::/32",
		"geosite:category-ru", "geoip:ru", "ruleset:custom-list",
	}
	for _, m := range valid {
		if err := ValidateBypassMatch(m); err != nil {
			t.Errorf("ValidateBypassMatch(%q) = %v, want nil", m, err)
		}
	}
	invalid := []string{
		"", " ", " example.com", "exa mple.com", "example.com:443",
		"https://example.com", "domain:", "domain:-bad-.com", "domain:bad..com",
		"process:chrome.exe", "8080", "geosite:", "*", "dom ain.com",
	}
	for _, m := range invalid {
		if err := ValidateBypassMatch(m); err == nil {
			t.Errorf("ValidateBypassMatch(%q) = nil, want refusal", m)
		}
	}
}

func TestBypassStrategyConversionRoundTrip(t *testing.T) {
	in := &corev1.BypassStrategy{
		SplitPos: []string{"1", "sniext+1"}, Disorder: true, DisorderScope: "tls",
		Oob: true, OobScope: "http", TlsRecord: "2", HostCase: true, DomainCase: true,
		MethodEol: true, HostDot: true, HostTab: true, HostNoSpace: true,
		MethodSpace: true, UnixEol: true, SplitAnyProtocol: true,
		TamperStart: "n1", TamperCutoff: "n5", OobData: "0x41", Mss: "1200",
	}
	out := EngineToProtoStrategy(ProtoToEngineStrategy(in))
	if out.GetTlsRecord() != in.GetTlsRecord() || out.GetMss() != "1200" ||
		len(out.GetSplitPos()) != 2 || !out.GetSplitAnyProtocol() || !out.GetUnixEol() {
		t.Errorf("tpws round-trip = %+v", out)
	}
	nfq := nfqwsStrategy()
	out2 := EngineToProtoStrategy(ProtoToEngineStrategy(nfq))
	if len(out2.GetDesync()) != 2 || out2.GetFilterTcp() != "80,443" || !out2.GetAutoTtl() {
		t.Errorf("nfqws round-trip = %+v", out2)
	}
	if !IsEmptyBypassStrategy(nil) || !IsEmptyBypassStrategy(&corev1.BypassStrategy{}) {
		t.Error("IsEmptyBypassStrategy: empty strategies must report empty")
	}
	if IsEmptyBypassStrategy(in) {
		t.Error("IsEmptyBypassStrategy: a full strategy reported empty")
	}
}
