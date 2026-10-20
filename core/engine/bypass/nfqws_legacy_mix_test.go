package bypass

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// TestDesyncStrategyRefusesTPWSOnlyFields pins the S2 seams fix:
// bypass.NFQWSArgs renders only SplitPos of the legacy tpws fields, so
// a strategy mixing desync methods with any other legacy field used to
// validate, route to nfqws via BackendOf, and silently lose the legacy
// shaping. Validation must refuse the mix instead (the mirror of the
// existing "nfqws-only field needs a desync method" checks).
func TestDesyncStrategyRefusesTPWSOnlyFields(t *testing.T) {
	base := engine.BypassStrategy{Desync: []string{"fake"}, FilterTCP: "443"}
	for name, mutate := range map[string]func(*engine.BypassStrategy){
		"disorder":           func(s *engine.BypassStrategy) { s.Disorder, s.SplitPos = true, []string{"1"} },
		"disorder scope":     func(s *engine.BypassStrategy) { s.Disorder, s.DisorderScope, s.SplitPos = true, "tls", []string{"1"} },
		"oob":                func(s *engine.BypassStrategy) { s.OOB, s.SplitPos = true, []string{"1"} },
		"oob data":           func(s *engine.BypassStrategy) { s.OOB, s.OOBData, s.SplitPos = true, "0x00", []string{"1"} },
		"tlsrec":             func(s *engine.BypassStrategy) { s.TLSRecord = "sniext+1" },
		"hostcase":           func(s *engine.BypassStrategy) { s.HostCase = true },
		"domcase":            func(s *engine.BypassStrategy) { s.DomainCase = true },
		"methodeol":          func(s *engine.BypassStrategy) { s.MethodEOL = true },
		"hostdot":            func(s *engine.BypassStrategy) { s.HostDot = true },
		"hosttab":            func(s *engine.BypassStrategy) { s.HostTab = true },
		"hostnospace":        func(s *engine.BypassStrategy) { s.HostNoSpace = true },
		"methodspace":        func(s *engine.BypassStrategy) { s.MethodSpace = true },
		"unixeol":            func(s *engine.BypassStrategy) { s.UnixEOL = true },
		"split-any-protocol": func(s *engine.BypassStrategy) { s.SplitAnyProtocol = true },
		"tamper-start":       func(s *engine.BypassStrategy) { s.TamperStart = "n1" },
		"tamper-cutoff":      func(s *engine.BypassStrategy) { s.TamperCutoff = "n2" },
		"mss":                func(s *engine.BypassStrategy) { s.MSS = "1300" },
	} {
		s := base
		mutate(&s)
		o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s}
		err := o.Validate()
		if err == nil || !strings.Contains(err.Error(), "tpws-only") {
			t.Errorf("%s mixed with desync must be refused as tpws-only, got %v", name, err)
		}
	}
	// SplitPos is the one legacy field NFQWSArgs does render
	// (--dpi-desync-split-pos): the mix stays legal.
	s := base
	s.SplitPos = []string{"1", "midsld"}
	o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s}
	if err := o.Validate(); err != nil {
		t.Fatalf("desync + split-pos must stay valid, got %v", err)
	}
	// Pure legacy strategies are untouched by the new check.
	legacy := engine.BypassStrategy{SplitPos: []string{"1"}, Disorder: true, HostCase: true, MSS: "1300"}
	o = engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &legacy}
	if err := o.Validate(); err != nil {
		t.Fatalf("a pure tpws strategy must stay valid, got %v", err)
	}
}

// TestShippedFakePayloadsExist pins the fake-payload seam (S2 task 4):
// every fake file name the code can generate by default must exist in
// the vendored zapret tree that packaging/zapret/build.sh copies into
// <engines>/zapret/fake/ — the directory NFQWSArgs resolves names
// against via the executor's assets dir. A rename on either side
// breaks nfqws at startup (it exits on an unreadable fake file), so
// pin the names here instead.
func TestShippedFakePayloadsExist(t *testing.T) {
	fakeDir := filepath.Join("..", "..", "..", "third_party", "zapret", "files", "fake")
	for _, name := range []string{
		defaultQUICFake,                      // "quic" keyword and DefaultStrategy
		"tls_clienthello_www_google_com.bin", // named by TestNFQWSArgsRenderFixedTTLFakeFiles strategies
	} {
		if _, err := os.Stat(filepath.Join(fakeDir, name)); err != nil {
			t.Errorf("fake payload %q missing from the vendored zapret tree (%s): %v", name, fakeDir, err)
		}
	}
	// The default strategy's rendered fake path must land inside the
	// fake/ subdirectory of the assets dir it is given.
	args := NFQWSArgs(DefaultStrategy(), string(filepath.Separator)+"assets")
	want := "--dpi-desync-fake-quic=" + filepath.Join(string(filepath.Separator)+"assets", "fake", defaultQUICFake)
	found := false
	for _, a := range args {
		if a == want {
			found = true
		}
	}
	if !found {
		t.Fatalf("default strategy args = %v, want %q", args, want)
	}
}
