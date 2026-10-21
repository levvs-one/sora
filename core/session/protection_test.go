package session

import (
	"context"
	"errors"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

type strictTestGuard struct{ fakeGuard }

func (g *strictTestGuard) Restore(ctx context.Context) error {
	if g.Current().StrictKillSwitch {
		return nil
	}
	return g.fakeGuard.Restore(ctx)
}
func (g *strictTestGuard) Release(ctx context.Context) error { return g.fakeGuard.Restore(ctx) }

func TestStrictManagerShutdownAndFailedDisconnect(t *testing.T) {
	g := &strictTestGuard{}
	m, _ := testManager(t, g)
	if _, err := m.Connect(t.Context(), strictPlan("strict"), Settings{StrictKillSwitch: true, Reconnect: true}); err != nil {
		t.Fatal(err)
	}
	if err := m.Shutdown(t.Context()); err != nil {
		t.Fatal(err)
	}
	if !m.Status().StrictKillSwitch {
		t.Fatal("service shutdown released strict mode")
	}
	// Even a stopped session must allow the explicit disable operation.
	off := false
	if err := m.SetProtection(t.Context(), false, &off); err != nil {
		t.Fatal(err)
	}
	if m.Status().KillSwitch {
		t.Fatal("disable retained protection")
	}
	m, eng := testManager(t, g)
	if _, err := m.Connect(t.Context(), strictPlan("stop-failure"), Settings{StrictKillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	eng.stopErr = errors.New("engine failed to stop")
	if err := m.Disconnect(t.Context()); err == nil {
		t.Fatal("stop failure hidden")
	}
	if g.Current().KillSwitch {
		t.Fatal("stop error stranded the firewall")
	}
}

func TestStrictFailedStartupRemainsReleasableWithoutSession(t *testing.T) {
	g := &strictTestGuard{}
	m, eng := testManager(t, g)
	eng.apply = errors.New("engine failed to start")
	if _, err := m.Connect(t.Context(), strictPlan("strict"), Settings{StrictKillSwitch: true}); err == nil {
		t.Fatal("expected startup failure")
	}
	if !m.Status().StrictKillSwitch {
		t.Fatal("startup cleanup released strict intent")
	}
	if err := m.Disconnect(t.Context()); err != nil {
		t.Fatal(err)
	}
	if m.Status().KillSwitch {
		t.Fatal("disconnect without session did not release intent")
	}
}

func TestStrictReplacementCannotSilentlyDisableProtection(t *testing.T) {
	g := &strictTestGuard{}
	m, _ := testManager(t, g)
	if _, err := m.Connect(t.Context(), strictPlan("first"), Settings{StrictKillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := m.Connect(t.Context(), strictPlan("replacement"), Settings{}); err != nil {
		t.Fatal(err)
	}
	if !g.Current().StrictKillSwitch {
		t.Fatal("Connect silently disabled strict mode")
	}
	if err := m.Disconnect(t.Context()); err != nil {
		t.Fatal(err)
	}
}

func TestStrictEndpointsIncludeBothFamiliesAndWireGuardPeers(t *testing.T) {
	plan := &engine.Plan{Outbounds: []engine.Outbound{
		{Server: "203.0.113.2", Port: 443},
		{Server: "2001:db8::2", Port: 8443},
		{Peers: []engine.WireGuardPeer{{Endpoint: "[2001:db8::3]:51820"}}},
	}}
	endpoints, err := planEndpoints(t.Context(), plan)
	if err != nil {
		t.Fatal(err)
	}
	if len(endpoints) != 3 {
		t.Fatalf("endpoints=%v", endpoints)
	}
}

func strictPlan(id string) *engine.Plan {
	plan := testPlan(id)
	for i := range plan.Outbounds {
		plan.Outbounds[i].Server = "203.0.113.2"
	}
	return plan
}
