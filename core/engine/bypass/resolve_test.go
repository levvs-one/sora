package bypass

import (
	"slices"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestResolveStrategyMidSNI(t *testing.T) {
	s := engine.BypassStrategy{SplitPos: []string{"1", MidSNIMarker}}
	r, ok, err := ResolveStrategy(s, "example.com", 0)
	if err != nil || !ok {
		t.Fatalf("resolve: ok=%v err=%v", ok, err)
	}
	// MidSNISplit("example.com") = sniext+14 (split_test.go pins it).
	if want := []string{"1", "sniext+14"}; !slices.Equal(r.SplitPos, want) {
		t.Fatalf("resolved = %v, want %v", r.SplitPos, want)
	}
	// The caller's strategy must not change.
	if s.SplitPos[1] != MidSNIMarker {
		t.Fatal("ResolveStrategy mutated the input strategy")
	}
	// The resolved strategy validates and renders into both argv forms.
	o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &r}
	if err := o.Validate(); err != nil {
		t.Fatalf("resolved strategy refused: %v", err)
	}
	args, ok, err := ArgsForTarget(s, 4242, "example.com", 0)
	if err != nil || !ok || !slices.Contains(args, "--split-pos=1,sniext+14") {
		t.Fatalf("tpws args = %v ok=%v err=%v", args, ok, err)
	}
}

func TestResolveStrategyMidSNIInTLSRecord(t *testing.T) {
	s := engine.BypassStrategy{TLSRecord: MidSNIMarker}
	r, ok, err := ResolveStrategy(s, "google.com", 0)
	if err != nil || !ok || r.TLSRecord != "sniext+14" {
		t.Fatalf("resolved = %+v ok=%v err=%v", r, ok, err)
	}
}

func TestResolveStrategyMarkerNeedsSNI(t *testing.T) {
	s := engine.BypassStrategy{SplitPos: []string{MidSNIMarker}}
	if _, _, err := ResolveStrategy(s, "", 0); err == nil {
		t.Fatal("a marker without an SNI must be an error, not a guess")
	}
	if _, _, err := ResolveStrategy(s, "not a host!", 0); err == nil {
		t.Fatal("a marker with a garbage SNI must be an error")
	}
}

func TestUnresolvedMarkerFailsValidation(t *testing.T) {
	// Fail-closed by construction: the marker is data for the
	// resolver, never for a binary. Engine validation refuses it with
	// the remedy named.
	s := engine.BypassStrategy{SplitPos: []string{MidSNIMarker}}
	o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s}
	err := o.Validate()
	if err == nil || !strings.Contains(err.Error(), "ResolveStrategy") {
		t.Fatalf("unresolved marker must be refused naming the remedy, got %v", err)
	}
}

func TestResolveStrategyFakeTTLFromPath(t *testing.T) {
	s := engine.BypassStrategy{
		Desync: []string{"fake"}, FakeTLS: "tls", AutoTTL: true, AutoTTLDelta: DefaultTTLDelta,
		FilterTCP: "443",
	}
	r, ok, err := ResolveStrategy(s, "", 12)
	if err != nil || !ok {
		t.Fatalf("resolve: ok=%v err=%v", ok, err)
	}
	// FakeTTL(12, 2) = 10 (fakettl_test.go pins the math).
	if r.TTL != 10 || r.AutoTTL || r.AutoTTLDelta != 0 {
		t.Fatalf("resolved = %+v, want fixed TTL 10 with autottl cleared", r)
	}
	args, ok, err := NFQWSArgsForTarget(s, "/zapret", "", 12)
	if err != nil || !ok || !slices.Contains(args, "--dpi-desync-ttl=10") {
		t.Fatalf("nfqws args = %v ok=%v err=%v", args, ok, err)
	}
}

func TestResolveStrategyFakeTTLWindowCollapse(t *testing.T) {
	s := engine.BypassStrategy{
		Desync: []string{"fake"}, FakeTLS: "tls", AutoTTL: true, AutoTTLDelta: 2,
		FilterTCP: "443",
	}
	// Server 3 hops away, delta 2: no TTL dies strictly between the
	// censor and the server. Resolution must refuse (ok=false), so
	// the caller falls back to a non-fake strategy.
	if _, ok, err := ResolveStrategy(s, "", 3); err != nil || ok {
		t.Fatalf("window collapse: ok=%v err=%v, want ok=false err=nil", ok, err)
	}
}

func TestResolveStrategyUnmeasuredPathKeepsAutoTTL(t *testing.T) {
	s := engine.BypassStrategy{
		Desync: []string{"fake"}, FakeTLS: "tls", AutoTTL: true, AutoTTLDelta: 2,
		FilterTCP: "443",
	}
	r, ok, err := ResolveStrategy(s, "", 0)
	if err != nil || !ok || !r.AutoTTL || r.TTL != 0 {
		t.Fatalf("unmeasured path must keep autottl: %+v ok=%v err=%v", r, ok, err)
	}
	// And NFQWSArgs renders the delta with FakeTTL's window in
	// nfqws's native autottl syntax (vendored nfqws.c:
	// --dpi-desync-autottl=[<delta>[:<min>[-<max>]]]).
	args := NFQWSArgs(r, "/zapret")
	if !slices.Contains(args, "--dpi-desync-autottl=2:2-64") {
		t.Fatalf("args = %v, want --dpi-desync-autottl=2:2-64", args)
	}
}

func TestNFQWSArgsAutoTTLWithoutDeltaStaysBare(t *testing.T) {
	s := engine.BypassStrategy{Desync: []string{"fake"}, FakeTLS: "tls", AutoTTL: true, FilterTCP: "443"}
	args := NFQWSArgs(s, "/zapret")
	if !slices.Contains(args, "--dpi-desync-autottl") {
		t.Fatalf("args = %v, want the bare autottl flag", args)
	}
}

func TestResolveStrategyQUICFakeSplit(t *testing.T) {
	// QUIC-Initial desync profile shape: fake QUIC + a split position,
	// resolved and rendered end to end.
	s := engine.BypassStrategy{
		Desync: []string{"fake", "multisplit"}, SplitPos: []string{MidSNIMarker},
		FakeQUIC: "quic", AutoTTL: true, AutoTTLDelta: 2,
		FilterUDP: "443", FilterL7: "quic",
	}
	args, ok, err := NFQWSArgsForTarget(s, "/zapret", "example.com", 12)
	if err != nil || !ok {
		t.Fatalf("render: ok=%v err=%v", ok, err)
	}
	for _, want := range []string{
		"--dpi-desync=fake,multisplit",
		"--dpi-desync-split-pos=sniext+14",
		"--dpi-desync-ttl=10",
		"--filter-udp=443",
		"--filter-l7=quic",
	} {
		if !slices.Contains(args, want) {
			t.Errorf("args = %v, missing %s", args, want)
		}
	}
	for _, a := range args {
		if strings.Contains(a, "--dpi-desync-fake-quic=") && !strings.HasSuffix(a, "quic_initial_www_google_com.bin") {
			t.Errorf("fake-quic arg = %s, want the shipped QUIC Initial", a)
		}
	}
}
