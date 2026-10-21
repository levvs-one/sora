package control_test

import (
	"context"
	"testing"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/guard"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
)

type strictFirewall struct{ armed bool }

func (f *strictFirewall) Arm(context.Context, []uint16) error { f.armed = true; return nil }
func (f *strictFirewall) Disarm(context.Context) error        { f.armed = false; return nil }
func (f *strictFirewall) Armed(context.Context) (bool, error) { return f.armed, nil }

func TestStrictContractRecoversAndDisablesWithoutSession(t *testing.T) {
	dir := t.TempDir()
	store, err := secret.Open(t.TempDir(), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = store.Close() }()
	firewall := &strictFirewall{}
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatal(err)
	}
	build := func() (*control.Server, *session.Manager) {
		t.Helper()
		system, err := guard.New(guard.Options{DataDir: dir, EnginePorts: []uint16{7890}}, firewall)
		if err != nil {
			t.Fatal(err)
		}
		if err := system.Recover(t.Context()); err != nil {
			t.Fatal(err)
		}
		manager := session.NewManager(session.ManagerConfig{Guard: system, TunUp: noAdapter, Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil }})
		server, err := control.New(control.Config{Sessions: manager, Secrets: store, Authenticator: auth, Version: control.Version{Major: 1, Minor: 12, MinSupportedMinor: 1}})
		if err != nil {
			t.Fatal(err)
		}
		return server, manager
	}
	server, manager := build()
	plan := validPlan(t, store)
	plan.Outbounds[0].Endpoint = &corev1.Endpoint{Host: "203.0.113.2", Port: 443}
	version := &corev1.ApiVersion{Major: 1, Minor: 12}
	response, err := server.Connect(t.Context(), &corev1.ConnectRequest{ApiVersion: version, ControlAuthenticator: testToken, SessionPlan: plan, StrictKillSwitch: true, Reconnect: true})
	if err != nil || response.GetError() != nil {
		t.Fatalf("connect=%v, %v", response, err)
	}
	if !response.Status.StrictKillSwitch || !response.Status.KillSwitch || !firewall.armed {
		t.Fatal("strict contract did not arm before startup")
	}
	if err := manager.Shutdown(t.Context()); err != nil {
		t.Fatal(err)
	}
	recovered, newManager := build()
	defer func() { _ = newManager.Disconnect(context.Background()) }()
	status, err := recovered.GetStatus(t.Context(), &corev1.GetStatusRequest{ApiVersion: version})
	if err != nil || !status.Status.StrictKillSwitch || status.Status.Connection.SessionId != "" {
		t.Fatalf("recovery status=%v, %v", status, err)
	}
	off := false
	disabled, err := recovered.SetKillSwitch(t.Context(), &corev1.SetKillSwitchRequest{ApiVersion: version, Enabled: false, Strict: &off})
	if err != nil || disabled.GetError() != nil || disabled.Enabled || disabled.Strict || firewall.armed {
		t.Fatalf("disable=%v, %v, armed=%v", disabled, err, firewall.armed)
	}
	_, afterDisable := build()
	if afterDisable.Status().StrictKillSwitch || firewall.armed {
		t.Fatal("explicit disable was undone on restart")
	}
}

func TestStrictDisconnectAcceptsStaleSessionAfterRecovery(t *testing.T) {
	firewall := &strictFirewall{}
	opts := guard.Options{DataDir: t.TempDir(), EnginePorts: []uint16{7890}}
	first, err := guard.New(opts, firewall)
	if err != nil {
		t.Fatal(err)
	}
	if err := first.Apply(t.Context(), session.Settings{StrictKillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	recovered, err := guard.New(opts, firewall)
	if err != nil {
		t.Fatal(err)
	}
	if err := recovered.Recover(t.Context()); err != nil {
		t.Fatal(err)
	}
	manager := session.NewManager(session.ManagerConfig{Guard: recovered, Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil }})
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatal(err)
	}
	server, err := control.New(control.Config{Sessions: manager, Authenticator: auth, Version: control.Version{Major: 1, Minor: 12}})
	if err != nil {
		t.Fatal(err)
	}
	result, err := server.Disconnect(t.Context(), &corev1.DisconnectRequest{ApiVersion: &corev1.ApiVersion{Major: 1, Minor: 12}, ControlAuthenticator: testToken, SessionId: "before-the-core-crashed"})
	if err != nil || result.GetError() != nil || firewall.armed {
		t.Fatalf("disconnect=%v, %v, armed=%v", result, err, firewall.armed)
	}
}
