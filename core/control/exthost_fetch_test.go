package control_test

import (
	"context"
	"net/http"
	"testing"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/ext"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
)

// extFetchServer builds a control plane wired like production: an
// extension scheduler is configured.
func extFetchServer(t *testing.T) (*control.Server, *ext.Scheduler, *secret.Store) {
	t.Helper()
	store, err := secret.Open(secretTestDir(t), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatalf("opening the secret store: %v", err)
	}
	t.Cleanup(func() { _ = store.Close() })
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatalf("NewAuthenticator: %v", err)
	}
	sched := ext.NewScheduler(nil)
	server, err := control.New(control.Config{
		Version:       control.Version{Major: 1, Minor: 2, MinSupportedMinor: 1},
		Authenticator: auth,
		Secrets:       store,
		Sessions: session.NewManager(session.ManagerConfig{
			TunUp:   noAdapter,
			Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil },
		}),
		ExtScheduler: sched,
	})
	if err != nil {
		t.Fatalf("control.New: %v", err)
	}
	return server, sched, store
}

// TestExtFetchTransportFailsClosedWithoutSession is the leak guard at the
// control layer: no live session ⇒ the extension fetch transport refuses
// the request with ext.netfetch.no-tunnel instead of dialing direct.
func TestExtFetchTransportFailsClosedWithoutSession(t *testing.T) {
	server, _, _ := extFetchServer(t)
	rt := server.ExtFetchTransport()("com.example.hello")
	req, err := http.NewRequestWithContext(context.Background(), http.MethodGet, "https://example.com/", nil)
	if err != nil {
		t.Fatal(err)
	}
	if resp, err := rt.RoundTrip(req); err == nil {
		_ = resp.Body.Close()
		t.Fatal("extension fetch succeeded without a session: it must fail closed")
	} else if k := errs.KeyOf(err); k != ext.KeyNetFetchNoTunnel {
		t.Fatalf("error key = %q, want %q (%v)", k, ext.KeyNetFetchNoTunnel, err)
	}
}

// A custom engine without the isolated inbound must never fall back to its
// ordinary listener, whether the session uses TUN or system proxy mode.
func TestExtFetchTransportFailsClosedWithoutEngineInbound(t *testing.T) {
	for _, mode := range []corev1.TunnelMode{corev1.TunnelMode_TUNNEL_MODE_SYSTEM, corev1.TunnelMode_TUNNEL_MODE_APPLICATION} {
		server, _, store := extFetchServer(t)
		plan := validPlan(t, store)
		plan.TunnelMode = mode
		connected, err := server.Connect(t.Context(), &corev1.ConnectRequest{
			ApiVersion: clientVersion(), SessionPlan: plan, ControlAuthenticator: testToken,
		})
		if err != nil || connected.GetError() != nil {
			t.Fatalf("Connect: %v, %v", connected.GetError(), err)
		}
		rt := server.ExtFetchTransport()("com.example.hello")
		req, err := http.NewRequestWithContext(t.Context(), http.MethodGet, "https://example.com/", nil)
		if err != nil {
			t.Fatal(err)
		}
		if resp, err := rt.RoundTrip(req); err == nil {
			_ = resp.Body.Close()
			t.Fatal("an engine without the isolated inbound permitted fetch")
		} else if errs.KeyOf(err) != ext.KeyNetFetchNoTunnel {
			t.Fatalf("wrong error: %v", err)
		}
		_, err = server.Disconnect(t.Context(), &corev1.DisconnectRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken})
		if err != nil {
			t.Fatal(err)
		}
	}
}

func TestExtFetchTransportFailsClosedInBypassMode(t *testing.T) {
	server, _, store := extFetchServer(t)
	plan := validPlan(t, store)
	plan.TunnelMode = corev1.TunnelMode_TUNNEL_MODE_APPLICATION
	plan.Outbounds = []*corev1.OutboundSpec{{Id: "bypass", Protocol: "bypass", Bypass: &corev1.BypassStrategy{SplitPos: []string{"1"}}}}
	plan.Routes = []*corev1.RoutingRule{{Destination: "443", OutboundId: "bypass"}}
	plan.Routing = &corev1.RoutingOptions{ProxyTarget: "bypass"}
	connected, err := server.Connect(t.Context(), &corev1.ConnectRequest{ApiVersion: clientVersion(), SessionPlan: plan, ControlAuthenticator: testToken})
	if err != nil || connected.GetError() != nil {
		t.Fatalf("Connect: %v, %v", connected.GetError(), err)
	}
	t.Cleanup(func() {
		_, _ = server.Disconnect(context.Background(), &corev1.DisconnectRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken})
	})
	req, err := http.NewRequestWithContext(t.Context(), http.MethodGet, "https://example.com/", nil)
	if err != nil {
		t.Fatal(err)
	}
	if resp, err := server.ExtFetchTransport()("com.example.hello").RoundTrip(req); err == nil {
		_ = resp.Body.Close()
		t.Fatal("bypass mode permitted fetch")
	} else if errs.KeyOf(err) != ext.KeyNetFetchNoTunnel {
		t.Fatalf("wrong error: %v", err)
	}
}

// TestExtKillSwitchSyncsToScheduler pins the kill-switch wiring: arming
// the session's kill switch pauses background extension work; disarming
// resumes it.
func TestExtKillSwitchSyncsToScheduler(t *testing.T) {
	server, sched, store := extFetchServer(t)
	ctx := context.Background()
	connected, err := server.Connect(ctx, &corev1.ConnectRequest{
		ApiVersion: clientVersion(), SessionPlan: validPlan(t, store), ControlAuthenticator: testToken,
	})
	if err != nil || connected.GetError() != nil {
		t.Fatalf("Connect = %v, %v", connected.GetError(), err)
	}
	t.Cleanup(func() {
		_, _ = server.Disconnect(ctx, &corev1.DisconnectRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken})
	})
	if sched.Paused() {
		t.Fatal("scheduler must start unpaused for a session without the kill switch")
	}
	resp, err := server.SetKillSwitch(ctx, &corev1.SetKillSwitchRequest{
		ApiVersion: clientVersion(), Enabled: true,
	})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("SetKillSwitch(true) = %v, %v", resp.GetError(), err)
	}
	if !sched.Paused() {
		t.Fatal("arming the kill switch must pause background extension work")
	}
	resp, err = server.SetKillSwitch(ctx, &corev1.SetKillSwitchRequest{
		ApiVersion: clientVersion(), Enabled: false,
	})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("SetKillSwitch(false) = %v, %v", resp.GetError(), err)
	}
	if sched.Paused() {
		t.Fatal("disarming the kill switch must resume background extension work")
	}
}
