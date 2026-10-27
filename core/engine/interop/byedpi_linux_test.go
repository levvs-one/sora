//go:build linux

package interop_test

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/logs"
)

func TestIsolatedNativeByeDPIEngineTraffic(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" || os.Getenv("SORA_BYPASS_ISOLATED") != "1" {
		t.Skip("set SORA_ENGINES_DIR in an isolated Linux network namespace")
	}
	current, err := os.Readlink("/proc/self/ns/net")
	parent := os.Getenv("SORA_PARENT_NETNS")
	if err != nil || parent == "" || current == parent {
		t.Fatal("the ByeDPI fixture must not use the parent network namespace")
	}
	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindXray, engine.KindMihomo} {
		t.Run(string(kind), func(t *testing.T) {
			if _, err := os.Stat(filepath.Join(dir, string(kind))); err != nil {
				t.Skipf("%s is not installed in the fixture: %v", kind, err)
			}
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			local := port(t)
			center := logs.New(logs.Settings{CaptureLevel: logs.LevelDebug})
			reg := registry.Discover(ctx, dir, supervise.Config{
				HomeDir: t.TempDir(), LocalPort: local, StartTimeout: 10 * time.Second, Logs: center,
			})
			if !reg.ByeDPIAvailable() {
				t.Fatal("the fixture has no usable host-owned ByeDPI backend")
			}
			plan := &engine.Plan{
				SessionID: "byedpi", Engines: []engine.Kind{kind}, LocalProxy: engine.LocalProxy{Enabled: true},
				Outbounds: []engine.Outbound{{ID: "byedpi", Protocol: engine.ProtocolByeDPI,
					Bypass: &engine.BypassStrategy{SplitPos: []string{"1"}, Disorder: true, TLSRecord: "1", HostCase: true}}},
				Rules:   []engine.Rule{{Type: engine.RuleMatchAll, Target: "byedpi"}},
				Options: engine.Options{LogLevel: "warning", TestURL: engine.TestURLProduction},
			}
			running, err := reg.Factory()(ctx, plan)
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = running.Close() }()
			if err := running.Apply(ctx, plan); err != nil {
				t.Fatalf("apply %s with ByeDPI: %v", kind, err)
			}
			for _, secure := range []bool{false, true} {
				t.Run(map[bool]string{false: "HTTP", true: "TLS"}[secure], func(t *testing.T) {
					handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
						_, _ = io.Copy(w, io.LimitReader(r.Body, 64*1024))
					})
					target := httptest.NewUnstartedServer(handler)
					if secure {
						target.StartTLS()
					} else {
						target.Start()
					}
					defer target.Close()
					client := target.Client()
					transport := client.Transport.(*http.Transport)
					proxy, err := url.Parse("http://127.0.0.1:" + strconv.Itoa(local))
					if err != nil {
						t.Fatal(err)
					}
					transport.Proxy = http.ProxyURL(proxy)
					client.Timeout = 5 * time.Second
					defer transport.CloseIdleConnections()
					payload := []byte("Sora isolated ByeDPI engine traffic")
					req, err := http.NewRequestWithContext(ctx, http.MethodPost, target.URL, bytes.NewReader(payload))
					if err != nil {
						t.Fatal(err)
					}
					response, err := client.Do(req)
					if err != nil {
						t.Fatal(err)
					}
					defer func() { _ = response.Body.Close() }()
					body, err := io.ReadAll(io.LimitReader(response.Body, 64*1024))
					if err != nil || response.StatusCode != http.StatusOK || !bytes.Equal(body, payload) {
						t.Fatalf("unexpected traffic: status=%d body=%q err=%v", response.StatusCode, body, err)
					}
				})
			}
		})
	}
}
