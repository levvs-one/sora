package registry

import (
	"errors"
	"os"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/errs"
)

func TestOLCRTCMissingCombinationNeverFallsBackToProviderTCPPing(t *testing.T) {
	r := &Registry{preference: engine.DefaultPreference}
	o := engine.Outbound{ID: "olc", Protocol: engine.ProtocolOLCRTC, Server: "meet.example.org", Port: 443}
	if _, err := r.Factory()(t.Context(), &engine.Plan{Outbounds: []engine.Outbound{o}}); errs.KeyOf(err) != errs.KeyEngineBinaryMissing {
		t.Fatalf("missing auxiliary binary: %v", err)
	}
	results, err := r.Measure(t.Context(), []engine.Outbound{o}, engine.MeasureOptions{})
	if err != nil {
		t.Fatal(err)
	}
	m := <-results
	if m.Err == nil || errors.Is(m.Err, engine.ErrNoEngine) || errs.KeyOf(m.Err) != errs.KeyEngineBinaryMissing {
		t.Fatal("provider TCP ping could be mistaken for tunnel reachability")
	}
}

func TestOLCRTCSelectionAndNativeValidation(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" || os.Getenv("SORA_OLCRTC_BIN") == "" {
		t.Skip("set SORA_ENGINES_DIR and SORA_OLCRTC_BIN for native validation")
	}
	r := Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir()})
	if len(r.binaries) != 3 || r.olcrtc.Path == "" {
		t.Fatal("expected all three forwarding engines and the pinned carrier")
	}
	for _, kind := range append([]engine.Kind{""}, engine.DefaultPreference...) {
		for _, tun := range []bool{false, true} {
			name := string(kind)
			if name == "" {
				name = "auto"
			}
			if tun {
				name += "-tun"
			}
			t.Run(name, func(t *testing.T) {
				p := &engine.Plan{SessionID: "olcrtc-validation", LocalProxy: engine.LocalProxy{Enabled: !tun},
					Outbounds: []engine.Outbound{{ID: "olc", Protocol: engine.ProtocolOLCRTC, Server: "meet.example.org", Port: 443,
						Password: "d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799",
						OLCRTC:   &engine.OLCRTC{Provider: "jitsi", Room: "https://meet.example.org/room", Transport: "datachannel"}}},
					Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "olc"}},
					DNS:   engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "dns", Transport: engine.DNSHTTPS, Address: "1.1.1.1"}}},
					Tun:   engine.Tun{Enabled: tun, Stack: "gvisor"}}
				if kind != "" {
					p.Engines = []engine.Kind{kind}
				}
				e, err := r.Factory()(t.Context(), p)
				if err != nil {
					t.Fatal(err)
				}
				defer func() { _ = e.Close() }()
				want := kind
				if want == "" {
					want = engine.DefaultPreference[0]
				}
				if e.Kind() != want || !e.Capabilities().Protocols[engine.ProtocolOLCRTC] {
					t.Fatal("selection lost the forwarding engine or carrier capability")
				}
				if err := e.Validate(t.Context(), p); err != nil {
					t.Fatal(err)
				}
				p.Outbounds[0].OLCRTC.Provider = "telemost"
				if err := e.Validate(t.Context(), p); errs.KeyOf(err) != errs.KeyPlanEngineUnsupported {
					t.Fatalf("unsupported provider/transport reached startup: %v", err)
				}
				if e.State() != engine.StateIdle {
					t.Fatal("validation started a connection")
				}
			})
		}
	}
}
