package bypass

import (
	"slices"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestWindowsStrategyUsesOnlyLoopbackAndSupportedShaping(t *testing.T) {
	for _, test := range []struct {
		disorder, oob bool
		mode          string
	}{{false, false, "split"}, {true, false, "disorder"}, {false, true, "oob"}, {true, true, "disoob"}} {
		strategy := engine.BypassStrategy{SplitPos: []string{"1", "2"}, Disorder: test.disorder, OOB: test.oob,
			TLSRecord: "1", HostCase: true, DomainCase: true}
		args, err := WindowsArgs(strategy, 4242)
		want := []string{"--ip=127.0.0.1", "--port=4242", "--no-udp", "--" + test.mode + "=1", "--" + test.mode + "=2", "--tlsrec=1", "--mod-http=hcsmix,dcsmix"}
		if err != nil || !slices.Equal(args, want) {
			t.Fatalf("%s: %v, %v", test.mode, args, err)
		}
	}
}

func TestWindowsRefusesUnsupportedStrategiesWithoutApproximatingThem(t *testing.T) {
	for _, strategy := range []engine.BypassStrategy{
		{SplitPos: []string{"midsld"}},
		{SplitPos: []string{"1"}, TLSRecord: "sniext"},
		{SplitPos: []string{"1"}, MethodEOL: true},
		{SplitPos: []string{"1 --pidfile=other"}},
		{SplitPos: []string{"1;command"}},
		{SplitPos: []string{"10000"}},
		{},
	} {
		if args, err := WindowsArgs(strategy, 4242); err == nil || args != nil {
			t.Fatalf("unsupported strategy %+v produced %v, %v", strategy, args, err)
		}
	}
}
