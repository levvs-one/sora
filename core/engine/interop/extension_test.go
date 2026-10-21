package interop_test

import (
	"context"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/mihomo"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/ext"
)

// Different origins distinguish direct traffic from the VPN exit even though
// both are reachable locally. An ignored config key therefore fails the test.
func TestExtensionFetchUsesAuthenticatedVPNDespiteDirectRule(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	var directHits atomic.Int32
	direct := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		directHits.Add(1)
		_, _ = io.WriteString(w, "direct-origin")
	}))
	defer direct.Close()
	vpn := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Proxy-Authorization") != "" {
			t.Error("inbound credential leaked to the origin")
		}
		_, _ = io.WriteString(w, "vpn-origin")
	}))
	defer vpn.Close()
	server, err := xray.Prober.Discover(t.Context(), dir)
	if err != nil {
		t.Fatal(err)
	}
	// The VPN exit answers TCP DNS for example.com, so a name resolved outside
	// the tunnel (or not at all) fails instead of reaching the VPN origin.
	resolver, err := mihomo.Prober.Discover(t.Context(), dir)
	if err != nil {
		t.Fatal(err)
	}
	dnsPort := port(t)
	startProcess(t, "mihomo-dns", resolver.Path, []string{"-d", t.TempDir(), "-f", "-"}, map[string]any{
		"log-level": "warning",
		"hosts":     map[string]any{"example.com": []string{"127.0.0.2", "::1"}},
		"dns": map[string]any{"enable": true, "listen": "127.0.0.1:" + strconv.Itoa(dnsPort), "use-hosts": true,
			"ipv6": true, "nameserver": []string{"127.0.0.1:1"}},
		"rules": []string{"MATCH,DIRECT"},
	})
	upstream := port(t)
	startProcess(t, "xray-server", server.Path, []string{"run", "-c", "stdin:"}, map[string]any{
		"log": map[string]any{"loglevel": "warning"},
		"inbounds": []any{map[string]any{
			"listen": "127.0.0.1", "port": upstream, "protocol": "shadowsocks",
			"settings": map[string]any{"method": "aes-256-gcm", "password": password},
		}},
		"routing": map[string]any{"rules": []any{map[string]any{"port": "53", "outboundTag": "resolver"}}},
		"outbounds": []any{
			map[string]any{"protocol": "freedom", "settings": map[string]any{"redirect": strings.TrimPrefix(vpn.URL, "http://")}},
			map[string]any{"tag": "resolver", "protocol": "freedom", "settings": map[string]any{"redirect": "127.0.0.1:" + strconv.Itoa(dnsPort)}},
		},
	})
	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindXray, engine.KindMihomo} {
		t.Run(string(kind), func(t *testing.T) {
			ctx, cancel := context.WithTimeout(t.Context(), 30*time.Second)
			defer cancel()
			local := port(t)
			p := &engine.Plan{
				SessionID: "extension-fetch", Engines: []engine.Kind{kind}, LocalProxy: engine.LocalProxy{Enabled: true},
				ExtensionProxy: &engine.ExtensionProxy{Port: port(t), Username: "extension-session-user", Password: "extension-session-private-password", Target: "vpn"},
				Outbounds: []engine.Outbound{{ID: "vpn", Name: "VPN", Protocol: engine.ProtocolShadowsocks,
					Server: "127.0.0.1", Port: uint16(upstream), Cipher: "aes-256-gcm", Password: password}},
				Rules: []engine.Rule{
					{Type: engine.RuleDomain, Value: "localhost", Target: "direct"},
					{Type: engine.RuleDomain, Value: "example.com", Target: "direct"},
					{Type: engine.RuleIPCIDR, Value: "127.0.0.0/8", Target: "direct"},
					{Type: engine.RuleMatchAll, Target: "reject"},
				},
				Options: engine.Options{LogLevel: "warning"},
			}
			reg := registry.Discover(ctx, dir, supervise.Config{HomeDir: t.TempDir(), LocalPort: local})
			eng, err := reg.Factory()(ctx, p)
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = eng.Close() }()
			if err := eng.Apply(ctx, p); err != nil {
				t.Fatal(err)
			}
			if body, err := fetch(ctx, local, direct.URL); err != nil || body != "direct-origin" {
				t.Fatalf("ordinary listener must retain direct routing: %q, %v", body, err)
			}
			before := directHits.Load()
			for _, auth := range []string{"valid", "missing", "wrong"} {
				proxy := &url.URL{Scheme: "socks5", Host: "127.0.0.1:" + strconv.Itoa(p.ExtensionProxy.Port)}
				if auth != "missing" {
					secret := p.ExtensionProxy.Password
					if auth == "wrong" {
						secret = "incorrect-password"
					}
					proxy.User = url.UserPassword(p.ExtensionProxy.Username, secret)
				}
				tr := &http.Transport{Proxy: http.ProxyURL(proxy)}
				client := &http.Client{Transport: tr, Timeout: 3 * time.Second}
				req, err := http.NewRequestWithContext(ctx, http.MethodGet, direct.URL, nil)
				if err != nil {
					t.Fatal(err)
				}
				resp, err := client.Do(req)
				if auth != "valid" {
					if resp != nil {
						_ = resp.Body.Close()
					}
					if err == nil {
						t.Fatalf("%s login opened the extension inbound", auth)
					}
					continue
				}
				if err != nil {
					t.Fatal(err)
				}
				body, err := io.ReadAll(resp.Body)
				_ = resp.Body.Close()
				tr.CloseIdleConnections()
				if err != nil || string(body) != "vpn-origin" {
					t.Fatalf("extension escaped VPN: %q, %v", body, err)
				}
			}
			// Exercise the production SOCKS transport against the real inbound,
			// by name, so its DNS must also use the VPN despite the direct rule.
			tr, err := ext.ProxyRoundTripper(ext.TunnelProxy{Addr: "127.0.0.1:" + strconv.Itoa(p.ExtensionProxy.Port), Username: p.ExtensionProxy.Username, Password: p.ExtensionProxy.Password})
			if err != nil {
				t.Fatal(err)
			}
			defer tr.CloseIdleConnections()
			_, directPort, _ := net.SplitHostPort(direct.Listener.Addr().String())
			req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://example.com:"+directPort+"/", nil)
			if err != nil {
				t.Fatal(err)
			}
			resp, err := tr.RoundTrip(req)
			if err != nil {
				t.Fatal(err)
			}
			body, err := io.ReadAll(resp.Body)
			_ = resp.Body.Close()
			if err != nil || string(body) != "vpn-origin" || directHits.Load() != before {
				t.Fatalf("production transport bypassed the VPN: %q, direct hits=%d", body, directHits.Load()-before)
			}
		})
	}
}

func startProcess(t *testing.T, name, path string, args []string, config map[string]any) {
	t.Helper()
	cfg, err := json.Marshal(config)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	proc, err := supervise.Start(ctx, supervise.Spec{Name: name, Path: path, Args: args, Dir: t.TempDir(), Config: cfg})
	if err != nil {
		cancel()
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cancel()
		_ = proc.Stop(context.Background(), 0)
	})
	time.Sleep(300 * time.Millisecond)
	if err := proc.Err(); err != nil {
		t.Fatalf("%s: %v", name, err)
	}
}
