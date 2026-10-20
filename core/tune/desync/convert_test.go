package desync

import (
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
)

// Every nfqws seed in the pool must convert faithfully and pass the
// same plan validation a hand-written strategy faces: the tuner may
// never offer a genome the executor would refuse.
func TestSeedPoolNFQWSGenomesConvertAndValidate(t *testing.T) {
	converted := 0
	for _, p := range SeedParams() {
		if !p.RequiresNFQWS() {
			continue
		}
		s, ok := p.BypassStrategy()
		if !ok {
			t.Errorf("seed %s does not convert", p.ID())
			continue
		}
		converted++
		if got := bypass.BackendOf(s); got != bypass.BackendNFQWS {
			t.Errorf("seed %s converted to backend %v, want nfqws", p.ID(), got)
		}
		o := engine.Outbound{ID: "tune", Protocol: engine.ProtocolBypass, Bypass: &s}
		if err := o.Validate(); err != nil {
			t.Errorf("seed %s converted strategy refused by validation: %v", p.ID(), err)
		}
	}
	if converted == 0 {
		t.Fatal("the pool has no nfqws seeds; the conversion is untested")
	}
}

// tpws genomes convert through the legacy fields and stay tpws.
func TestTPWSGenomesConvertToTPWS(t *testing.T) {
	for _, p := range []Params{
		{Method: MethodSplit, SplitPos: "1"},
		{Method: MethodDisorder, SplitPos: "2"},
		{Method: MethodOOB, SplitPos: "1"},
		{Method: MethodTLSRec},
		{Method: MethodHTTPShuffle},
	} {
		s, ok := p.BypassStrategy()
		if !ok {
			t.Fatalf("genome %s must convert", p.ID())
		}
		if got := bypass.BackendOf(s); got != bypass.BackendTPWS {
			t.Errorf("genome %s converted to backend %v, want tpws", p.ID(), got)
		}
		o := engine.Outbound{ID: "tune", Protocol: engine.ProtocolBypass, Bypass: &s}
		if err := o.Validate(); err != nil {
			t.Errorf("genome %s converted strategy refused: %v", p.ID(), err)
		}
	}
}

// Unfaithful genomes refuse instead of approximating.
func TestUnfaithfulGenomesRefuse(t *testing.T) {
	for _, p := range []Params{
		{Method: MethodNone},
		{Method: MethodSplit, TTL: 3},              // TTL needs the fake packet
		{Method: MethodDisorder, AutoTTL: true},    // autottl needs the fake packet
		{Method: MethodOOB, Fooling: "badseq"},     // nfqws has no OOB byte
		{Method: MethodTLSRec, Repeats: 2},         // repeats need the fake packet
		{Method: MethodHTTPShuffle, Fooling: "ts"}, // fooling is nfqws-only, shuffle has no nfqws form
	} {
		if _, ok := p.BypassStrategy(); ok {
			t.Errorf("genome %s converted; want a refusal", p.ID())
		}
		if _, ok := p.NFQWSArgs("/zapret"); ok {
			t.Errorf("genome %s rendered nfqws args; want a refusal", p.ID())
		}
	}
}

func TestNFQWSArgsRenderTheGenome(t *testing.T) {
	p := Params{Method: MethodFake, FakeProto: "quic", TTL: 3, Scope: ScopeQUIC}
	args, ok := p.NFQWSArgs(string(filepath.Separator) + "zapret")
	if !ok {
		t.Fatal("the QUIC fake genome must render")
	}
	joined := strings.Join(args, " ")
	for _, want := range []string{
		"--dpi-desync=fake",
		"--dpi-desync-ttl=3",
		"--dpi-desync-fake-quic=" + filepath.Join(string(filepath.Separator)+"zapret", "fake", "quic_initial_www_google_com.bin"),
		"--filter-udp=443",
		"--filter-l7=quic",
	} {
		if !strings.Contains(joined, want) {
			t.Errorf("args %q missing %q", joined, want)
		}
	}
	// A tpws genome renders nothing here.
	if _, ok := (Params{Method: MethodSplit, SplitPos: "1"}).NFQWSArgs("/zapret"); ok {
		t.Error("a tpws genome rendered nfqws args")
	}
}
