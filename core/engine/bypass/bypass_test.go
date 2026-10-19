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

func TestArgsCarryTheNewTamperOptions(t *testing.T) {
	args := Args(engine.BypassStrategy{
		SplitPos:         []string{"1"},
		SplitAnyProtocol: true,
		Disorder:         true, DisorderScope: "tls",
		OOB: true, OOBScope: "http",
		HostDot: true, HostTab: true, HostNoSpace: true,
		MethodSpace: true, UnixEOL: true,
	}, 4242)
	want := []string{"--socks", "--bind-addr=127.0.0.1", "--port=4242",
		"--split-pos=1", "--split-any-protocol",
		"--disorder=tls", "--oob=http",
		"--hostdot", "--hosttab", "--hostnospace", "--methodspace", "--unixeol"}
	if !slices.Equal(args, want) {
		t.Fatalf("args = %v", args)
	}
}

func TestArgsKeepBareDisorderAndOOB(t *testing.T) {
	args := Args(engine.BypassStrategy{SplitPos: []string{"1"}, Disorder: true, OOB: true}, 4242)
	for _, flag := range []string{"--disorder", "--oob"} {
		if !slices.Contains(args, flag) {
			t.Fatalf("args = %v, missing %s", args, flag)
		}
	}
}

func TestArgsCarryTheTamperWindow(t *testing.T) {
	args := Args(engine.BypassStrategy{
		SplitPos:     []string{"1"},
		OOB:          true,
		OOBData:      "0xFF",
		TamperStart:  "n1",
		TamperCutoff: "sniext+200",
		MSS:          "1300",
	}, 4242)
	want := []string{"--socks", "--bind-addr=127.0.0.1", "--port=4242",
		"--split-pos=1", "--oob",
		"--tamper-start=n1", "--tamper-cutoff=sniext+200",
		"--oob-data=0xFF", "--mss=1300"}
	if !slices.Equal(args, want) {
		t.Fatalf("args = %v", args)
	}
}

func TestStrategiesAreChecked(t *testing.T) {
	for name, s := range map[string]*engine.BypassStrategy{
		"none":              nil,
		"does nothing":      {},
		"not a position":    {SplitPos: []string{"1;rm -rf"}},
		"option smuggled":   {SplitPos: []string{"1 --debug=@/etc/passwd"}},
		"disorder no split": {Disorder: true, TLSRecord: "sniext"},
		"bad scope":         {SplitPos: []string{"1"}, Disorder: true, DisorderScope: "udp"},
		"scope no disorder": {SplitPos: []string{"1"}, OOBScope: "tls"},
		"bad tamper pos":    {SplitPos: []string{"1"}, TamperStart: "1;2"},
		"tamper no shaping": {TamperCutoff: "100"},
		"bad oob data":      {SplitPos: []string{"1"}, OOB: true, OOBData: "0xFFF"},
		"oob data no oob":   {SplitPos: []string{"1"}, OOBData: "x"},
		"bad mss":           {SplitPos: []string{"1"}, MSS: "ten"},
		"tiny mss":          {SplitPos: []string{"1"}, MSS: "32"},
		"mss smuggled":      {SplitPos: []string{"1"}, MSS: "1300 --debug"},
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
	for name, s := range map[string]*engine.BypassStrategy{
		"tamper window": {SplitPos: []string{"1"}, TamperStart: "n2", TamperCutoff: "sniext+200"},
		"oob byte":     {SplitPos: []string{"1"}, OOB: true, OOBData: "0x00"},
		"mss only":     {MSS: "1300"},
	} {
		o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: s}
		if err := o.Validate(); err != nil {
			t.Errorf("%s was refused: %v", name, err)
		}
	}
}
