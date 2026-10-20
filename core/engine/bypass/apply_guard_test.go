package bypass

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// recordingBinary is a fake zapret binary that appends its argv to a
// file and then stays alive: if the executor ever starts it, the file
// exists and names every argument the binary received.
func recordingBinary(t *testing.T, name string) (path, argvFile string) {
	t.Helper()
	dir := t.TempDir()
	argvFile = filepath.Join(dir, name+".argv")
	body := "#!/bin/sh\necho \"$@\" >> \"" + argvFile + "\"\nexec sleep 3600\n"
	return writeScript(t, name, body), argvFile
}

// TestApplyRefusesUnresolvedMarkerItself pins M1: the executor is its
// own last guard. A direct Apply of a plan whose strategy still
// carries the mid-SNI marker must refuse BEFORE starting any binary —
// the protection must not live only in the callers' Plan.Validate.
// The reviewer probe this regresses against: a fake tpws started with
// argv "--split-pos=midsni".
func TestApplyRefusesUnresolvedMarkerItself(t *testing.T) {
	rows := []struct {
		name     string
		strategy engine.BypassStrategy
		binary   string // "tpws" or "nfqws": which fake records argv
	}{
		{"tpws split marker", engine.BypassStrategy{SplitPos: []string{MidSNIMarker}}, "tpws"},
		{"nfqws split marker", engine.BypassStrategy{
			Desync: []string{"split2"}, SplitPos: []string{MidSNIMarker},
			FilterTCP: "80,443", FilterL7: "tls"}, "nfqws"},
		{"tlsrec marker", engine.BypassStrategy{TLSRecord: MidSNIMarker}, "tpws"},
	}
	for _, row := range rows {
		t.Run(row.name, func(t *testing.T) {
			tpwsPath, tpwsArgv := recordingBinary(t, "tpws")
			nfqPath, nfqArgv := recordingBinary(t, "nfqws")
			fi := &fakeInterceptor{}
			e := Wrap(stubEngine{}, Binaries{TPWS: tpwsPath, NFQWS: nfqPath, Assets: fakeAssets(t)}, t.TempDir(), nil)
			e.iceptOverride = fi
			caps := capableCaps()
			e.capsOverride = &caps
			s := row.strategy
			p := &engine.Plan{Outbounds: []engine.Outbound{
				{ID: "a", Protocol: engine.ProtocolBypass, Bypass: &s},
			}}
			err := e.Apply(context.Background(), p)
			if err == nil || !strings.Contains(err.Error(), MidSNIMarker) {
				t.Fatalf("Apply = %v, want a refusal naming the unresolved marker", err)
			}
			argvFile := tpwsArgv
			if row.binary == "nfqws" {
				argvFile = nfqArgv
			}
			if _, statErr := os.Stat(argvFile); !os.IsNotExist(statErr) {
				raw, _ := os.ReadFile(argvFile)
				t.Fatalf("the %s binary was started despite the refusal, argv: %s", row.binary, raw)
			}
			if len(fi.syncs) != 0 {
				t.Fatalf("a refused Apply installed rules: %v", fi.syncs)
			}
		})
	}
}

// TestApplyRefusesInvalidStrategyItself: a strategy plan validation
// rejects (here: OOB data without OOB) must be refused by Apply even
// though no Plan.Validate ran anywhere above it.
func TestApplyRefusesInvalidStrategyItself(t *testing.T) {
	e := Wrap(stubEngine{}, Binaries{TPWS: filepath.Join(t.TempDir(), "gone")}, t.TempDir(), nil)
	caps := capableCaps()
	e.capsOverride = &caps
	s := engine.BypassStrategy{SplitPos: []string{"1"}, OOBData: "x"}
	p := &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "a", Protocol: engine.ProtocolBypass, Bypass: &s},
	}}
	err := e.Apply(context.Background(), p)
	if err == nil || !strings.Contains(err.Error(), "executor refuses") {
		t.Fatalf("Apply = %v, want the executor's own validation refusal", err)
	}
}
