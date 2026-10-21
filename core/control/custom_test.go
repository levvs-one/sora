package control

import (
	"context"
	"errors"
	"net"
	"os"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	customv1 "github.com/levvs-one/sora-client/core/gen/sora/custom/v1"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
)

// customTestPlane builds a control Server with a data directory, a real
// secret vault, and a known control token.
func customTestPlane(t *testing.T) (*Server, []byte) {
	t.Helper()
	dir := t.TempDir()
	if err := os.Chmod(dir, 0o700); err != nil {
		t.Fatal(err)
	}
	vault, err := secret.Open(dir, secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = vault.Close() })
	token := make([]byte, TokenLen)
	for i := range token {
		token[i] = byte(i + 1)
	}
	auth, err := NewAuthenticator(token)
	if err != nil {
		t.Fatal(err)
	}
	sessions := session.NewManager(session.ManagerConfig{
		TunUp: func(context.Context, string) error { return nil },
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return nil, errors.New("custom tests start no session")
		},
	})
	srv, err := New(Config{
		Authenticator: auth,
		Sessions:      sessions,
		Secrets:       vault,
		DataDir:       dir,
	})
	if err != nil {
		t.Fatal(err)
	}
	return srv, token
}

func customVersion() *corev1.ApiVersion {
	return &corev1.ApiVersion{Major: 1, Minor: 0, MinSupportedMinor: 0}
}

func customImpl(t *testing.T, srv *Server) *customServer {
	t.Helper()
	gs := grpc.NewServer()
	srv.MountCustomServices(gs)
	info := gs.GetServiceInfo()
	if _, ok := info["sora.custom.v1.CustomServers"]; !ok {
		t.Fatal("MountCustomServices did not register sora.custom.v1.CustomServers")
	}
	gs.Stop()
	return &customServer{srv: srv}
}

func TestCustomRPCSaveListDelete(t *testing.T) {
	srv, token := customTestPlane(t)
	c := customImpl(t, srv)
	ctx := context.Background()

	saved, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
		Server: &customv1.CustomServer{
			Name:        "Home",
			Protocol:    customv1.CustomProtocol_CUSTOM_PROTOCOL_VLESS,
			Address:     "vpn.example.com",
			Port:        443,
			Credentials: `{"uuid":"uuid-secret"}`,
		},
	})
	if err != nil {
		t.Fatalf("SaveCustomServer: %v", err)
	}
	if saved.GetError() != nil {
		t.Fatalf("SaveCustomServer error: %v", saved.GetError())
	}
	got := saved.GetServer()
	if got.GetId() == "" {
		t.Fatal("no id assigned")
	}
	if got.GetCredentials() != "" {
		t.Error("response echoes credential material")
	}
	if !got.GetHasCredentials() {
		t.Error("HasCredentials is false after save")
	}

	listed, err := c.ListCustomServers(ctx, &customv1.ListCustomServersRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
	})
	if err != nil || listed.GetError() != nil {
		t.Fatalf("ListCustomServers: %v, %v", err, listed.GetError())
	}
	if len(listed.GetServers()) != 1 || listed.GetServers()[0].GetId() != got.GetId() {
		t.Fatalf("list = %v", listed.GetServers())
	}
	if listed.GetServers()[0].GetCredentials() != "" {
		t.Error("list echoes credential material")
	}

	deleted, err := c.DeleteCustomServer(ctx, &customv1.DeleteCustomServerRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
		Id:                   got.GetId(),
	})
	if err != nil || deleted.GetError() != nil {
		t.Fatalf("DeleteCustomServer: %v, %v", err, deleted.GetError())
	}
	again, err := c.ListCustomServers(ctx, &customv1.ListCustomServersRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
	})
	if err != nil || again.GetError() != nil {
		t.Fatalf("ListCustomServers: %v, %v", err, again.GetError())
	}
	if len(again.GetServers()) != 0 {
		t.Fatalf("list after delete = %v", again.GetServers())
	}
}

func TestCustomRPCValidation(t *testing.T) {
	srv, token := customTestPlane(t)
	c := customImpl(t, srv)
	ctx := context.Background()

	for name, mutate := range map[string]func(*customv1.CustomServer){
		"bad address":  func(s *customv1.CustomServer) { s.Address = "999.1.1.1" },
		"empty secret": func(s *customv1.CustomServer) { s.Credentials = "" },
		"bad protocol": func(s *customv1.CustomServer) { s.Protocol = customv1.CustomProtocol_CUSTOM_PROTOCOL_UNSPECIFIED },
		"zero port":    func(s *customv1.CustomServer) { s.Port = 0 },
		"huge port":    func(s *customv1.CustomServer) { s.Port = 70000 },
	} {
		t.Run(name, func(t *testing.T) {
			in := &customv1.CustomServer{
				Name:        "X",
				Protocol:    customv1.CustomProtocol_CUSTOM_PROTOCOL_VLESS,
				Address:     "vpn.example.com",
				Port:        443,
				Credentials: `{"uuid":"secret"}`,
			}
			mutate(in)
			resp, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{
				ApiVersion:           customVersion(),
				ControlAuthenticator: token,
				Server:               in,
			})
			if err != nil {
				t.Fatalf("transport error: %v", err)
			}
			if resp.GetError() == nil {
				t.Error("invalid input accepted without a domain error")
			}
		})
	}

	// Path traversal in the id is rejected.
	resp, err := c.DeleteCustomServer(ctx, &customv1.DeleteCustomServerRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
		Id:                   "../evil",
	})
	if err != nil {
		t.Fatalf("transport error: %v", err)
	}
	if resp.GetError() == nil {
		t.Error("path traversal id accepted")
	}

	// Unknown id on test is a domain NotFound, not a transport error.
	testResp, err := c.TestCustomServer(ctx, &customv1.TestCustomServerRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
		Id:                   "no-such-server",
	})
	if err != nil {
		t.Fatalf("transport error: %v", err)
	}
	if testResp.GetError() == nil {
		t.Error("unknown id accepted")
	}
}

func TestCustomRPCAuthorization(t *testing.T) {
	srv, token := customTestPlane(t)
	c := customImpl(t, srv)
	ctx := context.Background()
	bad := append([]byte(nil), token...)
	bad[0] ^= 0xff

	if _, err := c.ListCustomServers(ctx, &customv1.ListCustomServersRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: bad,
	}); status.Code(err) != codes.Unauthenticated {
		t.Errorf("bad token: code = %v, want Unauthenticated", status.Code(err))
	}

	if _, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{
		ControlAuthenticator: token,
		Server:               &customv1.CustomServer{},
	}); status.Code(err) != codes.FailedPrecondition {
		t.Errorf("missing version: code = %v, want FailedPrecondition", status.Code(err))
	}
}

func TestCustomRPCTestReachability(t *testing.T) {
	srv, token := customTestPlane(t)
	c := customImpl(t, srv)
	ctx := context.Background()

	ln, err := (&net.ListenConfig{}).Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Skipf("no loopback: %v", err)
	}
	defer func() { _ = ln.Close() }()
	go func() {
		for {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			_ = conn.Close()
		}
	}()
	port := uint32(ln.Addr().(*net.TCPAddr).Port)

	saved, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
		Server: &customv1.CustomServer{
			Name:        "Local",
			Protocol:    customv1.CustomProtocol_CUSTOM_PROTOCOL_TROJAN,
			Address:     "127.0.0.1",
			Port:        port,
			Credentials: `{"uuid":"secret"}`,
		},
	})
	if err != nil || saved.GetError() != nil {
		t.Fatalf("save: %v %v", err, saved.GetError())
	}
	id := saved.GetServer().GetId()

	// Point the stored server at a closed port for the negative case.
	ln2, err := (&net.ListenConfig{}).Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Skipf("no loopback: %v", err)
	}
	closedPort := uint32(ln2.Addr().(*net.TCPAddr).Port)
	_ = ln2.Close()

	probe := func(port uint32) *customv1.TestCustomServerResponse {
		t.Helper()
		// Rewrite the stored endpoint by re-saving with the new port.
		upd, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{
			ApiVersion:           customVersion(),
			ControlAuthenticator: token,
			Server: &customv1.CustomServer{
				Id:          id,
				Name:        "Local",
				Protocol:    customv1.CustomProtocol_CUSTOM_PROTOCOL_TROJAN,
				Address:     "127.0.0.1",
				Port:        port,
				Credentials: "",
			},
		})
		if err != nil || upd.GetError() != nil {
			t.Fatalf("re-save: %v %v", err, upd.GetError())
		}
		resp, err := c.TestCustomServer(ctx, &customv1.TestCustomServerRequest{
			ApiVersion:           customVersion(),
			ControlAuthenticator: token,
			Id:                   id,
			TimeoutMs:            2000,
		})
		if err != nil {
			t.Fatalf("test: %v", err)
		}
		return resp
	}

	up := probe(port)
	if up.GetError() != nil || !up.GetReachable() {
		t.Errorf("reachable server: reachable=%v err=%v", up.GetReachable(), up.GetError())
	}
	// Loopback handshakes usually complete in under a millisecond, so a
	// zero latency_ms is expected here; the field's resolution is
	// documented in the contract.

	down := probe(closedPort)
	if down.GetError() == nil {
		t.Error("closed port reported without an error")
	}
	if down.GetReachable() {
		t.Error("closed port reported reachable")
	}
}

func TestCustomOutboundsHook(t *testing.T) {
	srv, token := customTestPlane(t)
	c := customImpl(t, srv)
	ctx := context.Background()

	if got := srv.CustomOutbounds(); len(got) != 0 {
		t.Fatalf("empty store: %d outbounds", len(got))
	}
	saved, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
		Server: &customv1.CustomServer{
			Name:        "Hook",
			Protocol:    customv1.CustomProtocol_CUSTOM_PROTOCOL_VLESS,
			Address:     "vpn.example.com",
			Port:        443,
			Credentials: `{"uuid":"secret"}`,
		},
	})
	if err != nil || saved.GetError() != nil {
		t.Fatalf("save: %v %v", err, saved.GetError())
	}
	out := srv.CustomOutbounds()
	if len(out) != 1 {
		t.Fatalf("outbounds = %d", len(out))
	}
	spec := out[0]
	if spec.GetId() != "custom/"+saved.GetServer().GetId() {
		t.Errorf("id = %q", spec.GetId())
	}
	if spec.GetProtocol() != "vless" || spec.GetDisplayName() != "Hook" {
		t.Errorf("spec = %+v", spec)
	}
	if spec.GetEndpoint().GetHost() != "vpn.example.com" || spec.GetEndpoint().GetPort() != 443 {
		t.Errorf("endpoint = %+v", spec.GetEndpoint())
	}
	if spec.GetCredentials().GetReference() == "" {
		t.Error("no credentials reference")
	}
}

// injectSubscription puts a fabricated subscription record into the book so
// merge tests don't need a network fetch.
func injectSubscription(t *testing.T, srv *Server, id string, specs ...*corev1.OutboundSpec) {
	t.Helper()
	srv.subs.mu.Lock()
	defer srv.subs.mu.Unlock()
	srv.subs.records[id] = &subscriptionRecord{
		ID:      id,
		URL:     "https://example.com/sub",
		Created: time.Now(),
	}
	srv.subs.lists[id] = specs
}

func saveCustomForHook(t *testing.T, c *customServer, token []byte, name string) string {
	t.Helper()
	saved, err := c.SaveCustomServer(context.Background(), &customv1.SaveCustomServerRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
		Server: &customv1.CustomServer{
			Name:        name,
			Protocol:    customv1.CustomProtocol_CUSTOM_PROTOCOL_VLESS,
			Address:     "vpn.example.com",
			Port:        443,
			Credentials: `{"uuid":"s3cr3t"}`,
		},
	})
	if err != nil || saved.GetError() != nil {
		t.Fatalf("save: %v %v", err, saved.GetError())
	}
	return saved.GetServer().GetId()
}

func TestCustomOutboundsMergedIntoSubscriptionStates(t *testing.T) {
	srv, token := customTestPlane(t)
	injectSubscription(t, srv, "sub1",
		&corev1.OutboundSpec{Id: "sub-server-1", DisplayName: "Sub Server", Protocol: "vless"})
	c := customImpl(t, srv)

	states := srv.subs.list()
	if len(states) != 1 || len(states[0].GetOutbounds()) != 1 {
		t.Fatalf("before save: states=%d outbounds=%d", len(states), len(states[0].GetOutbounds()))
	}
	id := saveCustomForHook(t, c, token, "Home")

	states = srv.subs.list()
	if len(states) != 1 {
		t.Fatalf("states = %d, want 1", len(states))
	}
	got := states[0].GetOutbounds()
	if len(got) != 2 {
		t.Fatalf("outbounds = %d, want 2 (subscription + custom)", len(got))
	}
	if got[0].GetId() != "sub-server-1" {
		t.Errorf("first outbound = %q, want the subscription's own server first", got[0].GetId())
	}
	if want := "custom/" + id; got[1].GetId() != want {
		t.Errorf("second outbound = %q, want %q", got[1].GetId(), want)
	}
	// The merged slice must be fresh: rewriting a slot of the returned
	// state must not corrupt the book's stored list.
	got[0] = &corev1.OutboundSpec{Id: "mutated"}
	again := srv.subs.list()[0].GetOutbounds()
	if len(again) != 2 || again[0].GetId() != "sub-server-1" {
		t.Errorf("book list corrupted through merged state: %+v", again)
	}
	// Deleting the custom server removes it from the merged states.
	if _, err := c.DeleteCustomServer(context.Background(), &customv1.DeleteCustomServerRequest{
		ApiVersion:           customVersion(),
		ControlAuthenticator: token,
		Id:                   id,
	}); err != nil {
		t.Fatalf("delete: %v", err)
	}
	if n := len(srv.subs.list()[0].GetOutbounds()); n != 1 {
		t.Errorf("after delete: outbounds = %d, want 1", n)
	}
}

func TestCustomServerChangeBroadcastsToSubscriptionWatchers(t *testing.T) {
	srv, token := customTestPlane(t)
	injectSubscription(t, srv, "sub1")
	c := customImpl(t, srv)
	changes, stop := srv.subs.watch()
	defer stop()

	id := saveCustomForHook(t, c, token, "Home")
	select {
	case st := <-changes:
		found := false
		for _, o := range st.GetOutbounds() {
			if o.GetId() == "custom/"+id {
				found = true
			}
		}
		if !found {
			t.Errorf("broadcast state lacks the new custom server: %+v", st.GetOutbounds())
		}
	case <-time.After(5 * time.Second):
		t.Fatal("no subscription broadcast after SaveCustomServer")
	}
}

// TestCustomCredentialsBuildAConnectablePlan pins the contract between the
// client form and the planner: only a credential document is accepted, and
// what is stored comes back as engine credentials at connect time.
func TestCustomCredentialsBuildAConnectablePlan(t *testing.T) {
	srv, token := customTestPlane(t)
	c := customImpl(t, srv)
	ctx := context.Background()
	save := func(protocol customv1.CustomProtocol, credentials string) *customv1.SaveCustomServerResponse {
		t.Helper()
		resp, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{
			ApiVersion:           customVersion(),
			ControlAuthenticator: token,
			Server: &customv1.CustomServer{
				Name: "Manual", Protocol: protocol, Address: "vpn.example.com", Port: 443, Credentials: credentials,
			},
		})
		if err != nil {
			t.Fatal(err)
		}
		return resp
	}
	if resp := save(customv1.CustomProtocol_CUSTOM_PROTOCOL_VLESS, "bare-uuid"); resp.GetError() == nil {
		t.Fatal("a bare secret was stored; the planner could never read it back")
	}
	if resp := save(customv1.CustomProtocol_CUSTOM_PROTOCOL_VLESS, `{"uuid":"11111111-2222-3333-4444-555555555555"}`); resp.GetError() != nil {
		t.Fatalf("vless document refused: %v", resp.GetError())
	}
	if resp := save(customv1.CustomProtocol_CUSTOM_PROTOCOL_SHADOWSOCKS, `{"method":"chacha20-ietf-poly1305","password":"pw"}`); resp.GetError() != nil {
		t.Fatalf("shadowsocks document refused: %v", resp.GetError())
	}
	specs := srv.CustomOutbounds()
	if len(specs) != 2 {
		t.Fatalf("outbounds = %d, want 2", len(specs))
	}
	for i, spec := range specs {
		out, err := outboundFromProto(i, spec, srv.secrets)
		if err != nil {
			t.Fatalf("%s: %v", spec.GetProtocol(), err)
		}
		switch spec.GetProtocol() {
		case "vless":
			if out.UUID != "11111111-2222-3333-4444-555555555555" || !out.TLS.Enabled {
				t.Errorf("vless outbound = uuid %q tls %v", out.UUID, out.TLS.Enabled)
			}
		case "shadowsocks":
			if out.Cipher != "chacha20-ietf-poly1305" || out.Password != "pw" || out.TLS.Enabled {
				t.Errorf("shadowsocks outbound = cipher %q password %q tls %v", out.Cipher, out.Password, out.TLS.Enabled)
			}
		}
	}
}

// TestCustomWireGuardBuildsAPeerFromTheServerAddress pins the hand-entered
// WireGuard path: the document is checked on save and the planner fills the
// peer endpoint from the server address, without TLS.
func TestCustomWireGuardBuildsAPeerFromTheServerAddress(t *testing.T) {
	srv, token := customTestPlane(t)
	c := customImpl(t, srv)
	key := "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8="
	save := func(doc string) *customv1.SaveCustomServerResponse {
		t.Helper()
		resp, err := c.SaveCustomServer(context.Background(), &customv1.SaveCustomServerRequest{
			ApiVersion:           customVersion(),
			ControlAuthenticator: token,
			Server: &customv1.CustomServer{
				Name: "WG", Protocol: customv1.CustomProtocol_CUSTOM_PROTOCOL_WIREGUARD,
				Address: "198.51.100.7", Port: 51820, Credentials: doc,
			},
		})
		if err != nil {
			t.Fatal(err)
		}
		return resp
	}
	for _, bad := range []string{
		"",
		`{"private_key":"short","addresses":"10.0.0.2/32","peers":"[{\"PublicKey\":\"` + key + `\",\"AllowedIPs\":[\"0.0.0.0/0\"]}]"}`,
		`{"private_key":"` + key + `","addresses":"10.0.0.2","peers":"[{\"PublicKey\":\"` + key + `\",\"AllowedIPs\":[\"0.0.0.0/0\"]}]"}`,
		`{"private_key":"` + key + `","addresses":"10.0.0.2/32","peers":"[]"}`,
		`{"private_key":"` + key + `","addresses":"10.0.0.2/32","peers":"[{\"PublicKey\":\"` + key + `\"}]"}`,
	} {
		if resp := save(bad); resp.GetError() == nil {
			t.Errorf("accepted a broken WireGuard document: %s", bad)
		}
	}
	good := `{"private_key":"` + key + `","addresses":"10.0.0.2/32,fd00::2/128","peers":"[{\"PublicKey\":\"` + key +
		`\",\"AllowedIPs\":[\"0.0.0.0/0\",\"::/0\"],\"PersistentKeepalive\":25}]"}`
	if resp := save(good); resp.GetError() != nil {
		t.Fatalf("refused a valid document: %v", resp.GetError())
	}
	specs := srv.CustomOutbounds()
	if len(specs) != 1 {
		t.Fatalf("outbounds = %d", len(specs))
	}
	out, err := outboundFromProto(0, specs[0], srv.secrets)
	if err != nil {
		t.Fatal(err)
	}
	if out.TLS.Enabled || out.Transport.Type != "udp" || out.PrivateKey != key || len(out.Addresses) != 2 {
		t.Errorf("outbound = tls %v transport %q key %q addresses %v", out.TLS.Enabled, out.Transport.Type, out.PrivateKey, out.Addresses)
	}
	if len(out.Peers) != 1 || out.Peers[0].Endpoint != "198.51.100.7:51820" || out.Peers[0].PersistentKeepalive != 25 {
		t.Errorf("peers = %+v", out.Peers)
	}
	if err := out.Validate(); err != nil {
		t.Errorf("the planned outbound does not validate: %v", err)
	}
}
