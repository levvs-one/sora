package bypass

import (
	"context"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"

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
		"oob byte":      {SplitPos: []string{"1"}, OOB: true, OOBData: "0x00"},
		"mss only":      {MSS: "1300"},
	} {
		o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: s}
		if err := o.Validate(); err != nil {
			t.Errorf("%s was refused: %v", name, err)
		}
	}
}

func TestBackendOfSelectsNFQWSForDesync(t *testing.T) {
	if got := BackendOf(engine.BypassStrategy{SplitPos: []string{"1"}, Disorder: true}); got != BackendTPWS {
		t.Fatalf("legacy strategy runs on backend %v, want tpws", got)
	}
	if got := BackendOf(engine.BypassStrategy{Desync: []string{"fake", "split2"}}); got != BackendNFQWS {
		t.Fatalf("desync strategy runs on backend %v, want nfqws", got)
	}
}

func TestNFQWSArgsRenderTheModernSet(t *testing.T) {
	home := string(filepath.Separator) + "zapret"
	args := NFQWSArgs(engine.BypassStrategy{
		Desync:    []string{"fake", "split2", "disorder2", "multisplit"},
		SplitPos:  []string{"1", "2"},
		Fooling:   "badseq",
		AutoTTL:   true,
		Repeats:   2,
		FakeTLS:   "tls", // built-in: no flag
		FakeQUIC:  "quic",
		FilterTCP: "80,443",
		FilterUDP: "443",
		FilterL7:  "tls,quic",
	}, home)
	want := []string{
		"--dpi-desync=fake,split2,disorder2,multisplit",
		"--dpi-desync-split-pos=1,2",
		"--dpi-desync-fooling=badseq",
		"--dpi-desync-autottl",
		"--dpi-desync-repeats=2",
		"--dpi-desync-fake-quic=" + filepath.Join(home, "fake", "quic_initial_www_google_com.bin"),
		"--filter-tcp=80,443",
		"--filter-udp=443",
		"--filter-l7=tls,quic",
	}
	if !slices.Equal(args, want) {
		t.Fatalf("args = %v", args)
	}
}

func TestNFQWSArgsRenderFixedTTLFakeFiles(t *testing.T) {
	home := string(filepath.Separator) + "zapret"
	args := NFQWSArgs(engine.BypassStrategy{
		Desync:  []string{"fake"},
		TTL:     8,
		FakeTLS: "tls_clienthello_www_google_com.bin",
	}, home)
	want := []string{
		"--dpi-desync=fake",
		"--dpi-desync-ttl=8",
		"--dpi-desync-fake-tls=" + filepath.Join(home, "fake", "tls_clienthello_www_google_com.bin"),
	}
	if !slices.Equal(args, want) {
		t.Fatalf("args = %v", args)
	}
}

func TestDefaultStrategyIsTheModernNFQWSSet(t *testing.T) {
	s := DefaultStrategy()
	if BackendOf(s) != BackendNFQWS {
		t.Fatal("the default strategy must select the nfqws backend")
	}
	if s.FilterUDP != "443" || s.FakeQUIC == "" {
		t.Fatalf("the default must desync UDP/QUIC, got %+v", s)
	}
	o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s}
	if err := o.Validate(); err != nil {
		t.Fatalf("the default strategy was refused: %v", err)
	}
	args := NFQWSArgs(s, string(filepath.Separator)+"zapret")
	for _, flag := range []string{"--dpi-desync=fake,split2,disorder2,multisplit", "--dpi-desync-autottl", "--filter-udp=443"} {
		if !slices.Contains(args, flag) {
			t.Fatalf("args = %v, missing %s", args, flag)
		}
	}
}

func TestDesyncStrategiesAreChecked(t *testing.T) {
	for name, s := range map[string]*engine.BypassStrategy{
		"unknown method":            {Desync: []string{"nope"}},
		"too many methods":          {Desync: []string{"fake", "split2", "disorder2", "multisplit", "fakedsplit", "fakeddisorder", "ipfrag2", "udplen", "tamper"}},
		"fooling without desync":    {Fooling: "badseq"},
		"bad fooling":               {Desync: []string{"fake"}, Fooling: "nope"},
		"ttl without fake":          {Desync: []string{"split2"}, TTL: 8},
		"ttl and autottl":           {Desync: []string{"fake"}, TTL: 8, AutoTTL: true},
		"ttl out of range":          {Desync: []string{"fake"}, TTL: 300},
		"autottl without fake":      {Desync: []string{"split2"}, AutoTTL: true},
		"repeats without fake":      {Desync: []string{"split2"}, Repeats: 3},
		"repeats out of range":      {Desync: []string{"fake"}, Repeats: 99},
		"quic fake without udp":     {Desync: []string{"fake"}, FakeQUIC: "quic"},
		"fake payload without fake": {Desync: []string{"split2"}, FakeTLS: "tls"},
		"fake path escape":          {Desync: []string{"fake"}, FakeTLS: "../evil.bin"},
		"filter without desync":     {FilterUDP: "443"},
		"bad port":                  {Desync: []string{"fake"}, FilterUDP: "443,99999"},
		"bad port range":            {Desync: []string{"fake"}, FilterTCP: "0-10"},
		"bad l7":                    {Desync: []string{"fake"}, FilterL7: "quic,smtp"},
	} {
		o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: s}
		if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "z") {
			t.Errorf("%s must be refused, got %v", name, err)
		}
	}
	for name, s := range map[string]engine.BypassStrategy{
		"modern default": DefaultStrategy(),
		"fake with tls keyword": {
			Desync: []string{"fake"}, FakeTLS: "tls", FilterTCP: "443",
		},
		"full desync set": {
			Desync: []string{"fake", "split2", "disorder2"}, SplitPos: []string{"1"},
			Fooling: "badseq,ts", TTL: 8, Repeats: 3,
			FilterTCP: "80,443", FilterUDP: "443", FilterL7: "tls,quic",
		},
		"quic fake with udp": {
			Desync: []string{"fake"}, FakeQUIC: "quic_initial_www_google_com.bin",
			FilterUDP: "443", FilterL7: "quic",
		},
	} {
		o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s}
		if err := o.Validate(); err != nil {
			t.Errorf("%s was refused: %v", name, err)
		}
	}
}

// stubEngine is the innermost engine for Apply tests: the nfqws
// fail-closed path returns before it is ever touched.
type stubEngine struct{}

func (stubEngine) Kind() engine.Kind                 { return engine.KindSingBox }
func (stubEngine) Capabilities() engine.Capabilities { return engine.Capabilities{} }
func (stubEngine) State() engine.State               { return "" }
func (stubEngine) Version() engine.Version           { return engine.Version{} }
func (stubEngine) Groups(context.Context) ([]engine.GroupStatus, error) {
	return nil, nil
}
func (stubEngine) Select(context.Context, string, string) error { return nil }
func (stubEngine) Delay(context.Context, string, string, time.Duration) (time.Duration, error) {
	return 0, nil
}
func (stubEngine) Counters(context.Context) (engine.Counters, error) { return engine.Counters{}, nil }
func (stubEngine) Events() *engine.EventBus                          { return nil }
func (stubEngine) Validate(context.Context, *engine.Plan) error      { return nil }
func (stubEngine) Apply(context.Context, *engine.Plan) error         { return nil }
func (stubEngine) Stop(context.Context) error                        { return nil }
func (stubEngine) Close() error                                      { return nil }

func TestApplyFailsClosedForNFQWS(t *testing.T) {
	e := Wrap(stubEngine{}, filepath.Join("no", "tpws"), t.TempDir(), nil)
	s := DefaultStrategy()
	p := &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s},
	}}
	err := e.Apply(context.Background(), p)
	if err == nil || !strings.Contains(err.Error(), "nfqws") || !strings.Contains(err.Error(), "z") {
		t.Fatalf("an nfqws strategy must fail closed, got %v", err)
	}
}

func TestApplyStillRunsTPWS(t *testing.T) {
	e := Wrap(stubEngine{}, filepath.Join("no", "tpws"), t.TempDir(), nil)
	s := engine.BypassStrategy{SplitPos: []string{"1"}}
	p := &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s},
	}}
	// The tpws binary is missing, so Apply fails starting it — but it
	// must not fail closed as an nfqws strategy.
	err := e.Apply(context.Background(), p)
	if err == nil || strings.Contains(err.Error(), "nfqws") {
		t.Fatalf("a tpws strategy must take the tpws path, got %v", err)
	}
}
