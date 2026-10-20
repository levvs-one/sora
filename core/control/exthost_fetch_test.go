package control_test

import (
	"context"
	"fmt"
	"io"
	"net"
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
// extension scheduler and a local-proxy port are configured.
func extFetchServer(t *testing.T, proxyPort int) (*control.Server, *ext.Scheduler, *secret.Store) {
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
		ExtScheduler:   sched,
		LocalProxyPort: proxyPort,
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
	server, _, _ := extFetchServer(t, 7897)
	rt := server.ExtFetchTransport()("com.example.hello")
	req, err := http.NewRequest(http.MethodGet, "https://example.com/", nil)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := rt.RoundTrip(req); err == nil {
		t.Fatal("extension fetch succeeded without a session: it must fail closed")
	} else if k := errs.KeyOf(err); k != ext.KeyNetFetchNoTunnel {
		t.Fatalf("error key = %q, want %q (%v)", k, ext.KeyNetFetchNoTunnel, err)
	}
}

// TestExtFetchTransportUsesLiveSessionProxy is the end-to-end property:
// with a session up whose plan opens the local proxy (the application /
// system-proxy mode — a TUN plan has no listener by default and fails
// closed instead, see TestExtFetchTransportTunPlanFailsClosed), an
// extension fetch is proxied through the tunnel listener on the
// configured port — the origin sees the proxy's stamp, never a direct
// connection.
func TestExtFetchTransportUsesLiveSessionProxy(t *testing.T) {
	origin := startStampedOrigin(t)
	proxyPort := startFakeTunnelProxy(t)

	server, _, store := extFetchServer(t, proxyPort)
	ctx := context.Background()
	plan := validPlan(t, store)
	plan.TunnelMode = corev1.TunnelMode_TUNNEL_MODE_APPLICATION
	connected, err := server.Connect(ctx, &corev1.ConnectRequest{
		ApiVersion: clientVersion(), SessionPlan: plan, ControlAuthenticator: testToken,
	})
	if err != nil || connected.GetError() != nil {
		t.Fatalf("Connect = %v, %v", connected.GetError(), err)
	}
	t.Cleanup(func() {
		_, _ = server.Disconnect(ctx, &corev1.DisconnectRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken})
	})

	rt := server.ExtFetchTransport()("com.example.hello")
	req, err := http.NewRequest(http.MethodGet, origin, nil)
	if err != nil {
		t.Fatal(err)
	}
	resp, err := rt.RoundTrip(req)
	if err != nil {
		t.Fatalf("extension fetch through the tunnel: %v", err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK || string(body) != "via-tunnel" {
		t.Fatalf("got %d %q: the request did not ride the tunnel proxy", resp.StatusCode, body)
	}

	// After disconnect the same transport fails closed again.
	if _, err := server.Disconnect(ctx, &corev1.DisconnectRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken}); err != nil {
		t.Fatalf("Disconnect: %v", err)
	}
	req2, _ := http.NewRequest(http.MethodGet, origin, nil)
	if _, err := rt.RoundTrip(req2); err == nil {
		t.Fatal("extension fetch after Disconnect must fail closed")
	}
}

// TestExtFetchTransportTunPlanFailsClosed pins the TUN-mode behavior: a
// TUN session opens no local listener by default, so extension fetches
// fail closed (ext.netfetch.no-tunnel) instead of dialing direct around
// the tunnel. Riding the TUN itself is future work (it needs an
// authenticated private listener the plan layer does not provide yet).
func TestExtFetchTransportTunPlanFailsClosed(t *testing.T) {
	server, _, store := extFetchServer(t, 7899)
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
	rt := server.ExtFetchTransport()("com.example.hello")
	req, err := http.NewRequest(http.MethodGet, "https://example.com/", nil)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := rt.RoundTrip(req); err == nil {
		t.Fatal("TUN-mode extension fetch succeeded: it must fail closed without a tunnel listener")
	} else if k := errs.KeyOf(err); k != ext.KeyNetFetchNoTunnel {
		t.Fatalf("error key = %q, want %q (%v)", k, ext.KeyNetFetchNoTunnel, err)
	}
}

// TestExtKillSwitchSyncsToScheduler pins the kill-switch wiring: arming
// the session's kill switch pauses background extension work; disarming
// resumes it.
func TestExtKillSwitchSyncsToScheduler(t *testing.T) {
	server, sched, store := extFetchServer(t, 7898)
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

// startStampedOrigin serves "via-tunnel" only to requests stamped by the
// fake tunnel proxy; a direct request gets a teapot.
func startStampedOrigin(t *testing.T) string {
	t.Helper()
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("X-Via-Tunnel-Test") != "yes" {
			http.Error(w, "direct", http.StatusTeapot)
			return
		}
		fmt.Fprint(w, "via-tunnel")
	})
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	srv := &http.Server{Handler: mux}
	go func() { _ = srv.Serve(ln) }()
	t.Cleanup(func() { _ = srv.Close() })
	return "http://" + ln.Addr().String()
}

// startFakeTunnelProxy serves a minimal forward proxy on a free loopback
// port and returns the port: it forwards absolute-URI requests and stamps
// them X-Via-Tunnel-Test.
func startFakeTunnelProxy(t *testing.T) int {
	t.Helper()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	port := ln.Addr().(*net.TCPAddr).Port
	srv := &http.Server{Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !r.URL.IsAbs() {
			http.Error(w, "proxy needs an absolute URI", http.StatusBadRequest)
			return
		}
		out, err := http.NewRequest(r.Method, r.URL.String(), nil)
		if err != nil {
			http.Error(w, "bad request", http.StatusBadRequest)
			return
		}
		out.Header.Set("X-Via-Tunnel-Test", "yes")
		resp, err := http.DefaultTransport.RoundTrip(out)
		if err != nil {
			http.Error(w, "forward failed", http.StatusBadGateway)
			return
		}
		defer resp.Body.Close()
		w.WriteHeader(resp.StatusCode)
		_, _ = io.Copy(w, resp.Body)
	})}
	go func() { _ = srv.Serve(ln) }()
	t.Cleanup(func() { _ = srv.Close() })
	return port
}
