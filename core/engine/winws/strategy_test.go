package winws

import (
	"reflect"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestFixedCaptureAndPinnedGrammar(t *testing.T) {
	for _, disorder := range []bool{false, true} {
		mode := "multisplit"
		if disorder {
			mode = "multidisorder"
		}
		got, err := Args(engine.BypassStrategy{SplitPos: []string{"1", "midsld"}, Disorder: disorder, HostCase: true, DomainCase: true, MethodEOL: true})
		want := []string{"--wf-l3=ipv4,ipv6", "--wf-tcp=80,443", "--wf-filter-lan=1", "--dpi-desync=" + mode, "--dpi-desync-split-pos=1,midsld", "--hostcase", "--domcase", "--methodeol"}
		if err != nil || !reflect.DeepEqual(got, want) {
			t.Fatalf("args %v: %v", got, err)
		}
	}
	for _, strategy := range []engine.BypassStrategy{
		{}, {SplitPos: []string{"1 --wf-raw=true"}}, {SplitPos: []string{"@filter"}}, {SplitPos: []string{"10000"}},
		{SplitPos: []string{"1"}, OOB: true}, {SplitPos: []string{"1"}, TLSRecord: "1"},
	} {
		if got, err := Args(strategy); err == nil || got != nil {
			t.Fatalf("unsupported strategy returned %v, %v", got, err)
		}
	}
}

func TestMachineFilterDoesNotBecomeVPNOrSelectiveProxy(t *testing.T) {
	p := &engine.Plan{SessionID: "filter", Outbounds: []engine.Outbound{{ID: "filter", Protocol: engine.ProtocolWinws, Bypass: &engine.BypassStrategy{SplitPos: []string{"1"}}}}, Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "filter"}}}
	if _, err := admit(p); err != nil {
		t.Fatal(err)
	}
	out := Rewrite(p)
	if out.Outbounds[0].Protocol != engine.ProtocolDirect || p.Outbounds[0].Protocol != engine.ProtocolWinws {
		t.Fatal("projection changed the caller or produced a proxy")
	}
	if p.IsVPNTarget("filter") {
		t.Fatal("packet filter advertised a VPN")
	}
	p.Outbounds = append(p.Outbounds, engine.Outbound{ID: "other", Protocol: engine.ProtocolDirect})
	if _, err := admit(p); err == nil {
		t.Fatal("mixed packet-filter plan accepted")
	}
}
