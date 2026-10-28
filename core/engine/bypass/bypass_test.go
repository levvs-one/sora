package bypass

import (
	"slices"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestArgsCarryOnlyListeningAndTheStrategy(t *testing.T) {
	args := Args(engine.BypassStrategy{SplitPos: []string{"1", "midsld"}, Disorder: true, TLSRecord: "sniext+1"}, 4242)
	want := []string{"--socks", "--bind-addr=127.0.0.1", "--port=4242", "--split-pos=1,midsld", "--disorder", "--tlsrec=sniext+1"}
	if !slices.Equal(args, want) {
		t.Fatalf("args = %v", args)
	}
}

func TestRewriteTurnsBypassIntoTheLocalProxy(t *testing.T) {
	strategy := &engine.BypassStrategy{SplitPos: []string{"1"}}
	p := &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "z", Name: "No server", Protocol: engine.ProtocolBypass, Bypass: strategy},
		{ID: "d", Protocol: engine.ProtocolDirect},
	}}
	out := Rewrite(p, map[string]int{key(*strategy): 4242})
	if o := out.Outbounds[0]; o.Protocol != engine.ProtocolSOCKS5 || o.Server != "127.0.0.1" || o.Port != 4242 || o.ID != "z" {
		t.Fatalf("rewritten = %+v", o)
	}
	if p.Outbounds[0].Protocol != engine.ProtocolBypass {
		t.Fatal("the caller's plan must not change")
	}
}

func TestStrategiesAreChecked(t *testing.T) {
	for name, s := range map[string]*engine.BypassStrategy{
		"none":              nil,
		"does nothing":      {},
		"not a position":    {SplitPos: []string{"1;rm -rf"}},
		"option smuggled":   {SplitPos: []string{"1 --debug=@/etc/passwd"}},
		"disorder no split": {Disorder: true, TLSRecord: "sniext"},
	} {
		o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: s}
		if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "z") {
			t.Errorf("%s must be refused, got %v", name, err)
		}
	}
	good := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass,
		Bypass: &engine.BypassStrategy{SplitPos: []string{"method+2", "midsld", "-10"}, Disorder: true}}
	if err := good.Validate(); err != nil {
		t.Fatalf("a valid strategy was refused: %v", err)
	}
}

func TestByeDPIUsesAnExplicitLocalProxy(t *testing.T) {
	strategy := &engine.BypassStrategy{SplitPos: []string{"1"}}
	p := &engine.Plan{Outbounds: []engine.Outbound{{ID: "dpi", Protocol: engine.Protocol("byedpi"), Bypass: strategy}}}
	if !Has(p) {
		t.Fatal("explicit ByeDPI was not selected as a bypass proxy")
	}
	out := Rewrite(p, map[string]int{key(*strategy): 4242})
	if o := out.Outbounds[0]; o.Protocol != engine.ProtocolSOCKS5 || o.Server != "127.0.0.1" || o.Port != 4242 {
		t.Fatalf("explicit ByeDPI was not rewritten to its local proxy: %+v", o)
	}
	if p.Outbounds[0].Protocol != engine.Protocol("byedpi") {
		t.Fatal("the caller's plan must not change")
	}
}

func TestProxyDoesNotSwitchBackendsOrAcceptMissingStrategies(t *testing.T) {
	for _, pair := range [][2]engine.Protocol{{engine.ProtocolBypass, engine.ProtocolByeDPI}, {engine.ProtocolByeDPI, engine.ProtocolBypass}} {
		wrapper := Wrap(nil, "not-executed", t.TempDir(), nil, pair[0])
		plan := &engine.Plan{Outbounds: []engine.Outbound{{ID: "dpi", Protocol: pair[1], Bypass: &engine.BypassStrategy{SplitPos: []string{"1"}}}}}
		if err := wrapper.Validate(t.Context(), plan); err == nil {
			t.Fatal("validation silently changed the proxy backend")
		}
		if err := wrapper.Apply(t.Context(), plan); err == nil {
			t.Fatal("application silently changed the proxy backend")
		}
		plan.Outbounds[0] = engine.Outbound{ID: "dpi", Protocol: pair[0]}
		if err := wrapper.Validate(t.Context(), plan); err == nil {
			t.Fatal("validation accepted a missing strategy")
		}
		if err := wrapper.Apply(t.Context(), plan); err == nil {
			t.Fatal("application accepted a missing strategy")
		}
	}
}
