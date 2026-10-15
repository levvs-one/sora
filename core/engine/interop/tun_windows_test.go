//go:build windows

package interop_test

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/session"
)

// This opt-in runs only in the disposable Windows CI VM. Test-prefix routes
// prove packet delivery without capturing the runner's real internet traffic.
func TestWindowsTunSwitchesCarryTCPAndUDP(t *testing.T) {
	if os.Getenv("SORA_WINDOWS_TUN_INTEGRATION") != "1" || os.Getenv("GITHUB_ACTIONS") != "true" {
		t.Skip("requires the disposable GitHub Actions Windows VM")
	}
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Fatal("missing installed engines directory")
	}
	if _, err := net.InterfaceByName(engine.TunDevice); err == nil {
		t.Fatal("a pre-existing adapter must not be touched")
	}
	payload := make([]byte, 32<<20)
	if _, err := rand.Read(payload); err != nil {
		t.Fatal(err)
	}
	digest := sha256.Sum256(payload)
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/bulk" {
			w.Header().Set("Content-Type", "application/octet-stream")
			_, _ = w.Write(payload)
			return
		}
		_, _ = io.WriteString(w, reply)
	}))
	t.Cleanup(target.Close)
	address := strings.TrimPrefix(target.URL, "http://")
	udp, err := (&net.ListenConfig{}).ListenPacket(t.Context(), "udp", address)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = udp.Close() })
	go func() {
		buffer := make([]byte, 4096)
		for {
			n, addr, err := udp.ReadFrom(buffer)
			if err != nil {
				return
			}
			_, _ = udp.WriteTo(buffer[:n], addr)
		}
	}()
	server, err := xray.Prober.Discover(t.Context(), dir)
	if err != nil {
		t.Fatal(err)
	}
	serverPort := port(t)
	startServer(t, server, []service{{inbound: map[string]any{
		"listen": "127.0.0.1", "port": serverPort, "protocol": "shadowsocks",
		"settings": map[string]any{"method": "aes-256-gcm", "password": password, "network": "tcp,udp"},
	}}}, address)
	settings := logs.DefaultSettings()
	settings.CaptureLevel = logs.LevelDebug
	settings.RecordDestinations = true
	journal := logs.New(settings)
	t.Cleanup(func() {
		if t.Failed() {
			for _, entry := range journal.Query(logs.Filter{}, 0, 1000).Entries {
				t.Logf("%s %s: %s", entry.Time.Format(time.RFC3339Nano), entry.Source, entry.Message)
			}
		}
	})
	reg := registry.Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir(), StartTimeout: 15 * time.Second, Logs: journal})
	manager := session.NewManager(session.ManagerConfig{Factory: reg.Factory()})
	t.Cleanup(func() { _ = manager.Disconnect(context.Background()) })
	_, targetPort, _ := net.SplitHostPort(address)
	destination := net.JoinHostPort("203.0.113.10", targetPort)
	// The same encrypted peer without TUN separates packet-stack overhead from
	// transport throughput. No public server or runner internet route is used.
	var baseline float64
	t.Run("proxy-throughput", func(t *testing.T) {
		plan := &engine.Plan{SessionID: "windows-proxy", Engines: []engine.Kind{engine.KindXray},
			LocalProxy: engine.LocalProxy{Enabled: true},
			Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolShadowsocks,
				Server: "127.0.0.1", Port: uint16(serverPort), Cipher: "aes-256-gcm", Password: password}},
			Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "out"}}}
		eng, err := reg.Factory()(t.Context(), plan)
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { _ = eng.Close() })
		if err := eng.Apply(t.Context(), plan); err != nil {
			t.Fatal(err)
		}
		running, err := eng.(*xray.Engine).Running()
		if err != nil {
			t.Fatal(err)
		}
		proxy := &url.URL{Scheme: "http", Host: fmt.Sprintf("127.0.0.1:%d", running.LocalPort)}
		transport := &http.Transport{Proxy: http.ProxyURL(proxy), DisableKeepAlives: true}
		t.Cleanup(transport.CloseIdleConnections)
		baseline = windowsTransferMbps(t, &http.Client{Transport: transport, Timeout: 45 * time.Second}, destination, len(payload), digest)
	})
	for round := range 3 {
		for _, tc := range []struct {
			kind    engine.Kind
			stack   string
			profile bool
		}{
			{engine.KindSingBox, "", false},
			{engine.KindXray, "gvisor", false}, {engine.KindXray, "system", false},
			{engine.KindXray, "mixed", false}, {engine.KindXray, "mips", false},
			{engine.KindMihomo, "gvisor", false}, {engine.KindMihomo, "system", false},
			{engine.KindMihomo, "mixed", false}, {engine.KindMihomo, "mips", false},
			{"", "", true},
		} {
			t.Run(fmt.Sprintf("%d/%s/%s/provider=%v", round, tc.kind, tc.stack, tc.profile), func(t *testing.T) {
				t.Cleanup(func() {
					if t.Failed() {
						for _, entry := range journal.Query(logs.Filter{}, 0, 300).Entries {
							t.Logf("%s %s: %s", entry.Time.Format(time.RFC3339Nano), entry.Source, entry.Message)
						}
					}
				})
				p := &engine.Plan{SessionID: "windows-tun", Engines: []engine.Kind{tc.kind},
					Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolShadowsocks,
						Server: "127.0.0.1", Port: uint16(serverPort), Cipher: "aes-256-gcm", Password: password}},
					Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "out"}},
					Tun: engine.Tun{Enabled: true, DeviceName: engine.TunDevice, Stack: tc.stack, AutoRoute: true,
						RouteAddressSets: []string{"203.0.113.0/24"}},
					Options: engine.Options{LogLevel: "debug"},
					DNS:     engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "resolver", Address: "1.1.1.1", Transport: engine.DNSPlain}}}}
				if tc.profile {
					p.Engines = nil
					raw, err := json.Marshal(map[string]any{"outbounds": []any{map[string]any{
						"protocol": "shadowsocks", "settings": map[string]any{"servers": []any{map[string]any{
							"address": "127.0.0.1", "port": serverPort, "method": "aes-256-gcm", "password": password,
						}}},
					}}})
					if err != nil {
						t.Fatal(err)
					}
					p.Outbounds = []engine.Outbound{{ID: "out", Protocol: engine.ProtocolXrayProfile, Profile: raw,
						Server: "127.0.0.1", Port: uint16(serverPort)}}
				}
				ctx, cancel := context.WithTimeout(t.Context(), 90*time.Second)
				defer cancel()
				if _, err := manager.Connect(ctx, p, session.Settings{}); err != nil {
					t.Fatal(err)
				}
				if _, err := net.InterfaceByName(engine.TunDevice); err != nil {
					t.Fatal(err)
				}
				transport := &http.Transport{DisableKeepAlives: true}
				defer transport.CloseIdleConnections()
				client := &http.Client{Transport: transport, Timeout: 5 * time.Second}
				request, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+destination, nil)
				if err != nil {
					t.Fatal(err)
				}
				response, err := client.Do(request)
				if err != nil {
					t.Fatalf("TCP packet through TUN: %v", err)
				}
				body, err := io.ReadAll(response.Body)
				_ = response.Body.Close()
				if err != nil || string(body) != reply {
					t.Fatalf("TCP packet reply: %q %v", body, err)
				}
				packet, err := (&net.Dialer{Timeout: 5 * time.Second}).DialContext(t.Context(), "udp", destination)
				if err != nil {
					t.Fatal(err)
				}
				defer func() { _ = packet.Close() }()
				_ = packet.SetDeadline(time.Now().Add(5 * time.Second))
				payload := fmt.Sprintf("windows-tun-%d-%s-%s", round, tc.kind, tc.stack)
				_, err = packet.Write([]byte(payload))
				buffer := make([]byte, 4096)
				var n int
				if err == nil {
					n, err = packet.Read(buffer)
				}
				if err != nil || string(buffer[:n]) != payload {
					t.Fatalf("UDP packet reply: %q %v", buffer[:n], err)
				}
				if round == 0 {
					client.Timeout = 45 * time.Second
					median := windowsTransferMbps(t, client, destination, 32<<20, digest)
					if baseline > 0 {
						t.Logf("TUN throughput relative to the same encrypted proxy: %.1f%%", median/baseline*100)
					}
				}
			})
		}
	}
	if err := manager.Disconnect(t.Context()); err != nil {
		t.Fatal(err)
	}
	if _, err := net.InterfaceByName(engine.TunDevice); err == nil {
		t.Fatal("disconnect retained the adapter")
	}
}

func windowsTransferMbps(t *testing.T, client *http.Client, destination string, size int, digest [sha256.Size]byte) float64 {
	t.Helper()
	var samples []float64
	for range 3 {
		start := time.Now()
		request, err := http.NewRequestWithContext(t.Context(), http.MethodGet, "http://"+destination+"/bulk", nil)
		if err != nil {
			t.Fatal(err)
		}
		response, err := client.Do(request)
		if err != nil {
			t.Fatal(err)
		}
		hash := sha256.New()
		n, err := io.Copy(hash, response.Body)
		_ = response.Body.Close()
		if err != nil || response.StatusCode != http.StatusOK || n != int64(size) || !bytes.Equal(hash.Sum(nil), digest[:]) {
			t.Fatalf("large TCP transfer: status=%d bytes=%d SHA256=%x error=%v", response.StatusCode, n, hash.Sum(nil), err)
		}
		samples = append(samples, float64(n)*8/time.Since(start).Seconds()/1e6)
	}
	slices.Sort(samples)
	t.Logf("TCP throughput: 3 x %d bytes, SHA256 verified, Mbps min=%.1f median=%.1f max=%.1f", size, samples[0], samples[1], samples[2])
	return samples[1]
}
