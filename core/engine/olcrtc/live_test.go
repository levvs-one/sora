package olcrtc

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/mihomo"
	"github.com/levvs-one/sora-client/core/engine/singbox"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/errs"
)

func realBinary(t *testing.T) string {
	t.Helper()
	if os.Getenv("SORA_OLCRTC_BIN") == "" {
		t.Skip("set SORA_OLCRTC_BIN to the pinned binary with its checksum manifest")
	}
	b, err := Discover(t.Context(), "")
	if err != nil {
		t.Fatal(err)
	}
	return b.Path
}

func TestRealOLCRTCFailureCleansConfiguration(t *testing.T) {
	binary := realBinary(t)
	nativeBinary, err := xray.Prober.Discover(t.Context(), os.Getenv("SORA_ENGINES_DIR"))
	if err != nil {
		t.Fatal(err)
	}
	native, err := xray.New(supervise.Config{Binary: nativeBinary, HomeDir: t.TempDir()})
	if err != nil {
		t.Fatal(err)
	}
	e := Wrap(native, binary, t.TempDir(), nil)
	defer func() { _ = e.Close() }()
	port, err := supervise.FreePort()
	if err != nil {
		t.Fatal(err)
	}
	l := Listener{Port: uint16(port), Username: strings.Repeat("u", 64), Password: strings.Repeat("p", 64)}
	raw := []byte("mode: cnc\nauth:\n  provider: jitsi\nroom:\n  id: https://127.0.0.1/room\nnet:\n  transport: datachannel\n  dns: 127.0.0.1:53\n")
	_, err = e.launch(t.Context(), raw, l)
	if err == nil || !strings.Contains(err.Error(), "key required") {
		t.Fatalf("real config rejection: %v", err)
	}
	for _, c := range e.clients {
		if !c.proc.Exited() {
			t.Fatal("failed startup left a child alive")
		}
	}
	if err := e.Stop(t.Context()); err != nil {
		t.Fatal(err)
	}
	files, err := os.ReadDir(e.home)
	if err != nil || len(files) != 0 {
		t.Fatalf("failed config retained: %v", err)
	}
	t.Log("real upstream process rejected missing key and exited; temporary config removed")
}

// The upstream none provider speaks to a real local SFU. Test-only credentials
// are issued with LiveKit's official auth package outside the Sora dependency tree.
func TestLocalWebRTCTunnel(t *testing.T) {
	binary := realBinary(t)
	sfubinary := os.Getenv("SORA_LIVEKIT_BIN")
	tokensPath := os.Getenv("SORA_LIVEKIT_TOKENS")
	if sfubinary == "" || tokensPath == "" {
		t.Skip("set SORA_LIVEKIT_BIN and SORA_LIVEKIT_TOKENS for the local SFU integration")
	}
	tokens, err := os.ReadFile(tokensPath)
	if err != nil {
		t.Fatal(err)
	}
	identities := strings.Fields(string(tokens))
	if len(identities) != 2 {
		t.Fatal("expected two LiveKit room grants")
	}
	ctx, cancel := context.WithTimeout(t.Context(), 90*time.Second)
	defer cancel()
	home := t.TempDir()
	sfu, err := supervise.Start(ctx, supervise.Spec{Name: "livekit", Path: sfubinary, Dir: home, Args: []string{"--dev", "--config", os.Getenv("SORA_LIVEKIT_CONFIG")}})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = sfu.Stop(context.Background(), time.Second) }()
	t.Cleanup(func() {
		if t.Failed() {
			t.Log(sfu.Output().Last(8))
		}
	})
	const key = "d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799"
	localConfig := func(mode, token string, l Listener) []byte {
		cfg := map[string]any{"mode": mode, "auth": map[string]any{"provider": "none"}, "engine": map[string]any{"name": "livekit", "url": "ws://127.0.0.1:17880", "token": token}, "crypto": map[string]any{"key": key}, "net": map[string]any{"transport": "datachannel", "dns": "127.0.0.1:53"}}
		if mode == "cnc" {
			cfg["socks"] = map[string]any{"host": "127.0.0.1", "port": l.Port, "user": l.Username, "pass": l.Password}
		}
		raw, err := yaml.Marshal(cfg)
		if err != nil {
			t.Fatal(err)
		}
		return raw
	}
	// Wait for the HTTP control listener before the CLI's one-shot SFU join.
	ready := false
	for range 100 {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://127.0.0.1:17880", nil)
		if err != nil {
			t.Fatal(err)
		}
		resp, err := (&http.Client{Timeout: 100 * time.Millisecond}).Do(req)
		if err == nil {
			_ = resp.Body.Close()
			ready = true
			break
		}
		select {
		case <-ctx.Done():
			t.Fatal(ctx.Err())
		case <-time.After(50 * time.Millisecond):
		}
	}
	if !ready {
		t.Fatal("local SFU not ready")
	}
	serverPath := filepath.Join(home, "server.yaml")
	if err := os.WriteFile(serverPath, localConfig("srv", identities[0], Listener{}), 0600); err != nil {
		t.Fatal(err)
	}
	server, err := supervise.Start(ctx, supervise.Spec{Name: "olcrtc-server", Path: binary, Dir: home, Args: []string{serverPath}})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = server.Stop(context.Background(), time.Second) }()
	t.Cleanup(func() {
		if t.Failed() {
			t.Log(server.Output().Last(8))
		}
	})
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusNoContent) }))
	defer target.Close()
	builders := []struct {
		name   string
		prober supervise.Prober
		build  func(supervise.Config) (engine.Engine, error)
	}{
		{"sing-box", singbox.Prober, func(c supervise.Config) (engine.Engine, error) { return singbox.New(c) }},
		{"xray", xray.Prober, func(c supervise.Config) (engine.Engine, error) { return xray.New(c) }},
		{"mihomo", mihomo.Prober, func(c supervise.Config) (engine.Engine, error) { return mihomo.New(c) }},
	}
	for _, builder := range builders {
		t.Run(builder.name, func(t *testing.T) {
			nativeBinary, err := builder.prober.Discover(ctx, os.Getenv("SORA_ENGINES_DIR"))
			if err != nil {
				t.Fatal(err)
			}
			localPort, err := supervise.FreePort()
			if err != nil {
				t.Fatal(err)
			}
			native, err := builder.build(supervise.Config{Binary: nativeBinary, HomeDir: filepath.Join(t.TempDir(), builder.name), LocalPort: localPort})
			if err != nil {
				t.Fatal(err)
			}
			e := Wrap(native, binary, t.TempDir(), nil)
			defer func() {
				if err := e.Close(); err != nil {
					t.Error(err)
				}
			}()
			carrierPort, err := supervise.FreePort()
			if err != nil {
				t.Fatal(err)
			}
			user, err := supervise.RandomSecret()
			if err != nil {
				t.Fatal(err)
			}
			password, err := supervise.RandomSecret()
			if err != nil {
				t.Fatal(err)
			}
			l := Listener{Port: uint16(carrierPort), Username: user, Password: password}
			c, err := e.launch(ctx, localConfig("cnc", identities[1], l), l)
			if err != nil {
				t.Fatal(e.redactor.Err(err))
			}
			info, err := os.Stat(c.spec.Args[0])
			if err != nil || info.Mode().Perm() != 0600 {
				t.Fatal("config is not private")
			}
			dirinfo, err := os.Stat(c.home)
			if err != nil || dirinfo.Mode().Perm() != 0700 {
				t.Fatal("session home is not private")
			}
			bad := l
			bad.Password = strings.Repeat("x", 64)
			if authenticate(ctx, bad) == nil {
				t.Fatal("wrong SOCKS password accepted")
			}
			plan := &engine.Plan{SessionID: "local-e2e", LocalProxy: engine.LocalProxy{Enabled: true}, Outbounds: []engine.Outbound{{ID: "olc", Name: "OLCRTC", Protocol: engine.ProtocolOLCRTC}}, Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "olc"}}}
			if err := native.Apply(ctx, Rewrite(plan, map[string]Listener{"olc": l})); err != nil {
				t.Fatal(err)
			}
			proxy := &url.URL{Scheme: "socks5", Host: "127.0.0.1:" + strconv.Itoa(localPort)}
			transport := &http.Transport{Proxy: http.ProxyURL(proxy)}
			defer transport.CloseIdleConnections()
			req, err := http.NewRequestWithContext(ctx, http.MethodGet, target.URL, nil)
			if err != nil {
				t.Fatal(err)
			}
			resp, err := (&http.Client{Transport: transport, Timeout: 15 * time.Second}).Do(req)
			if err != nil {
				t.Fatal(err)
			}
			_, err = io.Copy(io.Discard, resp.Body)
			closeErr := resp.Body.Close()
			if errors.Join(err, closeErr) != nil || resp.StatusCode != 204 {
				t.Fatal("tunnel response failed")
			}
			e.workers.Add(1)
			go e.watch(c)
			events, unsub := e.Events().Subscribe()
			defer unsub()
			if err := c.proc.Stop(ctx, 0); err != nil {
				t.Fatal(err)
			}
			recovered := false
			for !recovered {
				select {
				case ev := <-events:
					if ev.Kind == engine.EventFatal {
						if errs.KeyOf(ev.Err) != errs.KeyEngineStartFailed {
							t.Fatal(ev.Err)
						}
						t.Log("upstream local datachannel rejoin failed its handshake; supervisor reported core.engine.start_failed")
						recovered = true
					}
					recovered = recovered || ev.Kind == engine.EventState && ev.State == engine.StateRunning
				case <-ctx.Done():
					t.Fatal(ctx.Err())
				}
			}
			if err := e.Stop(ctx); err != nil {
				t.Fatal(err)
			}
			if _, err := os.Stat(c.spec.Args[0]); !errors.Is(err, os.ErrNotExist) {
				t.Fatal("disconnect kept key file")
			}
			if authenticate(ctx, l) == nil {
				t.Fatal("listener survived disconnect")
			}
			t.Log("real HTTP 204 through native engine -> authenticated SOCKS -> OLC2/smux/WebRTC -> local LiveKit -> real olcrtc server; process death reported and cleanup passed")
		})
	}
}
