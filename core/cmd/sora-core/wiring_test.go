package main

import (
	"context"
	"errors"
	"os"
	"sort"
	"testing"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
)

// wantServices lists every proto service the core must expose on its
// control socket. When a new *_grpc.pb.go service lands, mount it in
// mountControlServices AND add its name here; this test fails closed
// otherwise. The names are the ServiceName values from the generated
// descriptors.
var wantServices = []string{
	"sora.censor.v1.CensorControl",
	"sora.core.v1.CoreControl",
	"sora.custom.v1.CustomServers",
	"sora.ext.v1.ExtensionHost",
	"sora.leak.v1.LeakService",
	"sora.obfs.v1.ObfsControl",
}

// TestAllProtoServicesMounted runs the exact mount sequence the production
// binary uses and asserts, via grpc.Server.GetServiceInfo reflection, that
// every proto service is registered with at least one method. An
// implemented-but-unmounted service answers UNIMPLEMENTED on the wire (this
// is how CustomServers shipped dead: proto, implementation, client and UI
// existed, MountCustomServices was never called); a service registered here
// with its real implementation cannot answer UNIMPLEMENTED for its own
// methods.
func TestAllProtoServicesMounted(t *testing.T) {
	dir := t.TempDir()
	if err := os.Chmod(dir, 0o700); err != nil {
		t.Fatal(err)
	}
	vault, err := secret.Open(dir, secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = vault.Close() })
	token := make([]byte, control.TokenLen)
	for i := range token {
		token[i] = byte(i + 1)
	}
	auth, err := control.NewAuthenticator(token)
	if err != nil {
		t.Fatal(err)
	}
	sessions := session.NewManager(session.ManagerConfig{
		TunUp: func(context.Context, string) error { return nil },
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return nil, errors.New("wiring test starts no session")
		},
	})
	plane, err := control.New(control.Config{
		Authenticator: auth,
		Sessions:      sessions,
		Secrets:       vault,
		DataDir:       dir,
	})
	if err != nil {
		t.Fatal(err)
	}
	gs := grpc.NewServer()
	t.Cleanup(gs.Stop)
	if err := mountControlServices(gs, plane, dir); err != nil {
		t.Fatalf("mountControlServices: %v", err)
	}
	info := gs.GetServiceInfo()
	got := make([]string, 0, len(info))
	for name, svc := range info {
		got = append(got, name)
		if len(svc.Methods) == 0 {
			t.Errorf("service %s registered with no methods", name)
		}
	}
	sort.Strings(got)
	want := append([]string(nil), wantServices...)
	sort.Strings(want)
	if len(got) != len(want) {
		t.Fatalf("registered services = %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("registered services = %v, want %v", got, want)
		}
	}
}

// TestBenchmarkSelectKindPicksACarryingEngine pins the benchmarker's
// engine selection. The production wiring once passed a nil preference
// to SelectEngine, which iterates the given order — so it tried no
// engine at all and BenchmarkServers answered ErrNoEngine for every
// server against a real core (WAVE-INTEGRATION E2E). The selection must
// pick the first DefaultPreference engine that carries the outbound.
func TestBenchmarkSelectKindPicksACarryingEngine(t *testing.T) {
	availability := []engine.Availability{
		{Kind: engine.KindSingBox, Usable: true, Version: engine.Version{Major: 1, Minor: 14, Patch: 3}},
		{Kind: engine.KindXray, Usable: true, Version: engine.Version{Major: 26, Minor: 3, Patch: 27}},
		{Kind: engine.KindMihomo, Usable: true, Version: engine.Version{Major: 1, Minor: 19, Patch: 32}},
	}
	kind, err := benchmarkSelectKind(availability, engine.Outbound{
		ID: "srv-1", Protocol: engine.ProtocolVLESS, Server: "192.0.2.10", Port: 443,
		UUID: "11111111-2222-3333-4444-555555555555",
	})
	if err != nil {
		t.Fatalf("benchmarkSelectKind: %v", err)
	}
	if kind != engine.KindSingBox {
		t.Fatalf("kind = %s, want the first carrying engine of DefaultPreference (sing-box)", kind)
	}
	if _, err := benchmarkSelectKind(nil, engine.Outbound{
		ID: "srv-2", Protocol: engine.ProtocolVLESS, Server: "192.0.2.10", Port: 443,
		UUID: "11111111-2222-3333-4444-555555555555",
	}); err == nil {
		t.Fatal("with no usable engines the selection must fail, not invent one")
	}
}
