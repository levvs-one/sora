package ext

import (
	"errors"
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

// TestValidateBypassMatchLengthCap pins M1(a) at the layer boundary:
// a match whose "ext: "+match outbound name would exceed the plan's
// MaxNameBytes is refused at Apply/Set, while a match exactly at the
// cap still validates.
func TestValidateBypassMatchLengthCap(t *testing.T) {
	domain := func(total int) string {
		// Labels of at most 63 bytes summing (with dots) to total.
		var labels []string
		rest := total
		for rest > 0 {
			n := min(rest, 63)
			if rest-n == 1 { // never leave a 1-byte remainder + dot
				n--
			}
			labels = append(labels, strings.Repeat("a", n))
			rest -= n
			if rest > 0 {
				rest-- // the dot
			}
		}
		return strings.Join(labels, ".")
	}
	atCap := "domain:" + domain(MaxBypassMatchBytes-len("domain:"))
	if len(atCap) != MaxBypassMatchBytes {
		t.Fatalf("fixture: at-cap match is %d bytes, want %d", len(atCap), MaxBypassMatchBytes)
	}
	if err := ValidateBypassMatch(atCap); err != nil {
		t.Errorf("match at the cap: ValidateBypassMatch = %v, want nil", err)
	}
	overCap := "domain:" + domain(MaxBypassMatchBytes-len("domain:")+2)
	if len(overCap) <= MaxBypassMatchBytes {
		t.Fatalf("fixture: over-cap match is %d bytes", len(overCap))
	}
	if err := ValidateBypassMatch(overCap); err == nil {
		t.Error("match over the cap: ValidateBypassMatch = nil, want refusal")
	}
	store, err := NewLayerStore("")
	if err != nil {
		t.Fatal(err)
	}
	if err := store.Set("com.example.anti", Layer{Bindings: []Binding{
		{Match: overCap, Strategy: tpwsStrategy()},
	}}); err == nil {
		t.Error("Set with an over-cap match succeeded, want refusal at Apply")
	}
	if _, ok := store.Get("com.example.anti"); ok {
		t.Error("an over-cap layer was stored")
	}
}

// TestLayerStoreCanonicalizesMatches pins L2 at storage time: what
// Set stores is the ruleFromProto-canonical form (case folded, IDNA
// punycode), and two spellings of one host are a duplicate.
func TestLayerStoreCanonicalizesMatches(t *testing.T) {
	store, err := NewLayerStore("")
	if err != nil {
		t.Fatal(err)
	}
	if err := store.Set("com.example.anti", Layer{Bindings: []Binding{
		{Match: "domain:EXAMPLE.com", Strategy: tpwsStrategy()},
		{Match: "Sub.Example.COM", Strategy: tpwsStrategy()},
		{Match: "domain:münchen.de", Strategy: tpwsStrategy()},
	}}); err != nil {
		t.Fatalf("Set: %v", err)
	}
	got, ok := store.Get("com.example.anti")
	if !ok {
		t.Fatal("layer missing after Set")
	}
	want := []string{"domain:example.com", "sub.example.com", "domain:xn--mnchen-3ya.de"}
	if len(got.Bindings) != len(want) {
		t.Fatalf("bindings = %+v", got.Bindings)
	}
	for i, w := range want {
		if got.Bindings[i].Match != w {
			t.Errorf("binding %d stored as %q, want canonical %q", i, got.Bindings[i].Match, w)
		}
	}
	// Canonical duplicate: the same host in two spellings is refused.
	if err := store.Set("com.example.dup", Layer{Bindings: []Binding{
		{Match: "domain:EXAMPLE.com", Strategy: tpwsStrategy()},
		{Match: "domain:example.com", Strategy: tpwsStrategy()},
	}}); err == nil {
		t.Error("Set with canonically duplicate matches succeeded")
	}
}

// TestLayerStoreSaveFailureKeepsMemoryInStepWithDisk pins L3: when
// persistence fails, Set returns the error AND the in-memory state is
// unchanged (Get does not see the layer), and Delete likewise rolls
// back.
func TestLayerStoreSaveFailureKeepsMemoryInStepWithDisk(t *testing.T) {
	store, err := NewLayerStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	boom := errors.New("disk full (test seam)")
	orig := layerWriteFile
	t.Cleanup(func() { layerWriteFile = orig })
	layerWriteFile = func(string, []byte) error { return boom }

	if err := store.Set("com.example.anti", Layer{Global: tpwsStrategy()}); err == nil {
		t.Fatal("Set with a failing save succeeded")
	}
	if _, ok := store.Get("com.example.anti"); ok {
		t.Fatal("Get sees a layer whose save failed: memory diverged from disk")
	}

	layerWriteFile = orig
	if err := store.Set("com.example.anti", Layer{Global: tpwsStrategy()}); err != nil {
		t.Fatalf("Set with a working save: %v", err)
	}
	layerWriteFile = func(string, []byte) error { return boom }
	if err := store.Delete("com.example.anti"); err == nil {
		t.Fatal("Delete with a failing save succeeded")
	}
	if _, ok := store.Get("com.example.anti"); !ok {
		t.Fatal("a failed Delete removed the layer from memory but not from disk")
	}
	if err := store.Set("com.example.anti", Layer{Bindings: []Binding{
		{Match: "domain:example.com", Strategy: tpwsStrategy()},
	}}); err == nil {
		t.Fatal("overwriting Set with a failing save succeeded")
	}
	got, _ := store.Get("com.example.anti")
	if len(got.Bindings) != 0 || got.Global == nil {
		t.Errorf("a failed overwrite changed the stored layer: %+v", got)
	}
}

// fullBypassProto is the M4 fixture: every one of the contract's 29
// BypassStrategy fields set to a distinctive value, so a dropped,
// swapped or mistyped conversion of any single field fails an
// assertion that names it. (The combination is not a *valid*
// strategy — conversion is algebraic and must not care.)
func fullBypassProto() *corev1.BypassStrategy {
	return &corev1.BypassStrategy{
		SplitPos: []string{"1", "host+2"}, Disorder: true, DisorderScope: "tls",
		Oob: true, OobScope: "http", TlsRecord: "sniext+1",
		HostCase: true, DomainCase: true, MethodEol: true, HostDot: true,
		HostTab: true, HostNoSpace: true, MethodSpace: true, UnixEol: true,
		SplitAnyProtocol: true, TamperStart: "n1", TamperCutoff: "n9",
		OobData: "0x41", Mss: "1200",
		Desync: []string{"fake", "split2"}, FakeTls: "tls-custom.bin",
		FakeQuic: "quic-custom.bin", Fooling: "badseq", Ttl: 7, AutoTtl: true,
		Repeats: 3, FilterTcp: "80,443", FilterUdp: "443", FilterL7: "tls,quic",
	}
}

// TestBypassStrategyConversionRoundTrip pins the proto->engine
// conversion and the round trip back field by field over the full
// 29-field fixture (M4): every field of both results is asserted.
// TestLayerStoreMidSNIMarkerScoping pins the midsni branch-3
// semantics at the store: the marker is not a native executor
// position (vendored zapret parse_posmarker knows only
// method/host/endhost/sld/midsld/endsld/sniext; the shipped tpws
// binary refuses --split-pos=midsni), so a marker strategy is
// accepted ONLY on a binding to a plain domain — the one scope with
// a concrete target to resolve against at plan merge. In a global,
// and on tag/address/network bindings, it stays InvalidArgument.
func TestLayerStoreMidSNIMarkerScoping(t *testing.T) {
	marker := &corev1.BypassStrategy{SplitPos: []string{"midsni"}}
	markerDisorder := &corev1.BypassStrategy{SplitPos: []string{"midsni"}, Disorder: true}
	markerTLSRec := &corev1.BypassStrategy{TlsRecord: "midsni"}
	store, err := NewLayerStore("")
	if err != nil {
		t.Fatal(err)
	}
	refused := map[string]Layer{
		"marker as global":          {Global: marker},
		"marker on geosite binding": {Bindings: []Binding{{Match: "geosite:category-ads", Strategy: marker}}},
		"marker on geoip binding":   {Bindings: []Binding{{Match: "geoip:ru", Strategy: marker}}},
		"marker on ruleset binding": {Bindings: []Binding{{Match: "ruleset:custom", Strategy: marker}}},
		"marker on IP binding":      {Bindings: []Binding{{Match: "192.0.2.1", Strategy: marker}}},
		"marker on CIDR binding":    {Bindings: []Binding{{Match: "192.0.2.0/24", Strategy: marker}}},
	}
	for name, layer := range refused {
		if err := store.Set("com.example.anti", layer); err == nil {
			t.Errorf("%s: Set succeeded, want the marker refused in this scope", name)
		}
	}
	if _, ok := store.Get("com.example.anti"); ok {
		t.Error("a refused marker layer was stored")
	}
	accepted := map[string]Layer{
		"marker on domain binding":        {Bindings: []Binding{{Match: "domain:example.com", Strategy: marker}}},
		"marker on full binding":          {Bindings: []Binding{{Match: "full:sub.example.com", Strategy: markerDisorder}}},
		"marker on bare-domain binding":   {Bindings: []Binding{{Match: "example.org", Strategy: marker}}},
		"tlsrec marker on domain binding": {Bindings: []Binding{{Match: "domain:example.net", Strategy: markerTLSRec}}},
	}
	for name, layer := range accepted {
		if err := store.Set("com.example.anti", layer); err != nil {
			t.Errorf("%s: Set = %v, want the marker accepted in binding scope", name, err)
		}
	}
	// The direct validator agrees with the store's scoping.
	if err := ValidateBypassBindingStrategy("domain:example.com", marker); err != nil {
		t.Errorf("ValidateBypassBindingStrategy(domain) = %v", err)
	}
	if err := ValidateBypassBindingStrategy("geosite:x", marker); err == nil ||
		!strings.Contains(err.Error(), "midsni") {
		t.Errorf("ValidateBypassBindingStrategy(geosite) = %v, want a midsni refusal", err)
	}
	if err := ValidateBypassStrategy(marker); err == nil {
		t.Error("ValidateBypassStrategy (global scope) accepted the marker")
	}
}

func TestBypassStrategyConversionRoundTrip(t *testing.T) {
	in := fullBypassProto()
	eng := ProtoToEngineStrategy(in)
	// Engine side, field by field.
	if len(eng.SplitPos) != 2 || eng.SplitPos[0] != "1" || eng.SplitPos[1] != "host+2" {
		t.Errorf("SplitPos = %v", eng.SplitPos)
	}
	if !eng.Disorder {
		t.Error("Disorder = false")
	}
	if eng.DisorderScope != "tls" {
		t.Errorf("DisorderScope = %q", eng.DisorderScope)
	}
	if !eng.OOB {
		t.Error("OOB = false")
	}
	if eng.OOBScope != "http" {
		t.Errorf("OOBScope = %q", eng.OOBScope)
	}
	if eng.TLSRecord != "sniext+1" {
		t.Errorf("TLSRecord = %q", eng.TLSRecord)
	}
	if !eng.HostCase {
		t.Error("HostCase = false")
	}
	if !eng.DomainCase {
		t.Error("DomainCase = false")
	}
	if !eng.MethodEOL {
		t.Error("MethodEOL = false")
	}
	if !eng.HostDot {
		t.Error("HostDot = false")
	}
	if !eng.HostTab {
		t.Error("HostTab = false")
	}
	if !eng.HostNoSpace {
		t.Error("HostNoSpace = false")
	}
	if !eng.MethodSpace {
		t.Error("MethodSpace = false")
	}
	if !eng.UnixEOL {
		t.Error("UnixEOL = false")
	}
	if !eng.SplitAnyProtocol {
		t.Error("SplitAnyProtocol = false")
	}
	if eng.TamperStart != "n1" {
		t.Errorf("TamperStart = %q", eng.TamperStart)
	}
	if eng.TamperCutoff != "n9" {
		t.Errorf("TamperCutoff = %q", eng.TamperCutoff)
	}
	if eng.OOBData != "0x41" {
		t.Errorf("OOBData = %q", eng.OOBData)
	}
	if eng.MSS != "1200" {
		t.Errorf("MSS = %q", eng.MSS)
	}
	if len(eng.Desync) != 2 || eng.Desync[0] != "fake" || eng.Desync[1] != "split2" {
		t.Errorf("Desync = %v", eng.Desync)
	}
	if eng.FakeTLS != "tls-custom.bin" {
		t.Errorf("FakeTLS = %q", eng.FakeTLS)
	}
	if eng.FakeQUIC != "quic-custom.bin" {
		t.Errorf("FakeQUIC = %q", eng.FakeQUIC)
	}
	if eng.Fooling != "badseq" {
		t.Errorf("Fooling = %q", eng.Fooling)
	}
	if eng.TTL != 7 {
		t.Errorf("TTL = %d", eng.TTL)
	}
	if !eng.AutoTTL {
		t.Error("AutoTTL = false")
	}
	if eng.AutoTTLDelta != 0 {
		t.Errorf("AutoTTLDelta = %d, want 0 (the contract carries no auto_ttl_delta)", eng.AutoTTLDelta)
	}
	if eng.Repeats != 3 {
		t.Errorf("Repeats = %d", eng.Repeats)
	}
	if eng.FilterTCP != "80,443" {
		t.Errorf("FilterTCP = %q", eng.FilterTCP)
	}
	if eng.FilterUDP != "443" {
		t.Errorf("FilterUDP = %q", eng.FilterUDP)
	}
	if eng.FilterL7 != "tls,quic" {
		t.Errorf("FilterL7 = %q", eng.FilterL7)
	}
	// Round trip back to proto, field by field.
	out := EngineToProtoStrategy(eng)
	if len(out.GetSplitPos()) != 2 || out.GetSplitPos()[0] != "1" || out.GetSplitPos()[1] != "host+2" {
		t.Errorf("round-trip SplitPos = %v", out.GetSplitPos())
	}
	if !out.GetDisorder() {
		t.Error("round-trip Disorder = false")
	}
	if out.GetDisorderScope() != "tls" {
		t.Errorf("round-trip DisorderScope = %q", out.GetDisorderScope())
	}
	if !out.GetOob() {
		t.Error("round-trip Oob = false")
	}
	if out.GetOobScope() != "http" {
		t.Errorf("round-trip OobScope = %q", out.GetOobScope())
	}
	if out.GetTlsRecord() != "sniext+1" {
		t.Errorf("round-trip TlsRecord = %q", out.GetTlsRecord())
	}
	if !out.GetHostCase() {
		t.Error("round-trip HostCase = false")
	}
	if !out.GetDomainCase() {
		t.Error("round-trip DomainCase = false")
	}
	if !out.GetMethodEol() {
		t.Error("round-trip MethodEol = false")
	}
	if !out.GetHostDot() {
		t.Error("round-trip HostDot = false")
	}
	if !out.GetHostTab() {
		t.Error("round-trip HostTab = false")
	}
	if !out.GetHostNoSpace() {
		t.Error("round-trip HostNoSpace = false")
	}
	if !out.GetMethodSpace() {
		t.Error("round-trip MethodSpace = false")
	}
	if !out.GetUnixEol() {
		t.Error("round-trip UnixEol = false")
	}
	if !out.GetSplitAnyProtocol() {
		t.Error("round-trip SplitAnyProtocol = false")
	}
	if out.GetTamperStart() != "n1" {
		t.Errorf("round-trip TamperStart = %q", out.GetTamperStart())
	}
	if out.GetTamperCutoff() != "n9" {
		t.Errorf("round-trip TamperCutoff = %q", out.GetTamperCutoff())
	}
	if out.GetOobData() != "0x41" {
		t.Errorf("round-trip OobData = %q", out.GetOobData())
	}
	if out.GetMss() != "1200" {
		t.Errorf("round-trip Mss = %q", out.GetMss())
	}
	if len(out.GetDesync()) != 2 || out.GetDesync()[0] != "fake" || out.GetDesync()[1] != "split2" {
		t.Errorf("round-trip Desync = %v", out.GetDesync())
	}
	if out.GetFakeTls() != "tls-custom.bin" {
		t.Errorf("round-trip FakeTls = %q", out.GetFakeTls())
	}
	if out.GetFakeQuic() != "quic-custom.bin" {
		t.Errorf("round-trip FakeQuic = %q", out.GetFakeQuic())
	}
	if out.GetFooling() != "badseq" {
		t.Errorf("round-trip Fooling = %q", out.GetFooling())
	}
	if out.GetTtl() != 7 {
		t.Errorf("round-trip Ttl = %d", out.GetTtl())
	}
	if !out.GetAutoTtl() {
		t.Error("round-trip AutoTtl = false")
	}
	if out.GetRepeats() != 3 {
		t.Errorf("round-trip Repeats = %d", out.GetRepeats())
	}
	if out.GetFilterTcp() != "80,443" {
		t.Errorf("round-trip FilterTcp = %q", out.GetFilterTcp())
	}
	if out.GetFilterUdp() != "443" {
		t.Errorf("round-trip FilterUdp = %q", out.GetFilterUdp())
	}
	if out.GetFilterL7() != "tls,quic" {
		t.Errorf("round-trip FilterL7 = %q", out.GetFilterL7())
	}
	if !IsEmptyBypassStrategy(nil) || !IsEmptyBypassStrategy(&corev1.BypassStrategy{}) {
		t.Error("IsEmptyBypassStrategy: empty strategies must report empty")
	}
	if IsEmptyBypassStrategy(in) {
		t.Error("IsEmptyBypassStrategy: a full strategy reported empty")
	}
}
