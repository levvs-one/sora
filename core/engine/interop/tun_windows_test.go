//go:build windows

package interop_test

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
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
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
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
	reg := registry.Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir(), StartTimeout: 15 * time.Second})
	manager := session.NewManager(session.ManagerConfig{Factory: reg.Factory()})
	t.Cleanup(func() { _ = manager.Disconnect(context.Background()) })
	_, targetPort, _ := net.SplitHostPort(address)
	destination := net.JoinHostPort("203.0.113.10", targetPort)
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
		t.Run(fmt.Sprintf("%s/%s/provider=%v", tc.kind, tc.stack, tc.profile), func(t *testing.T) {
			p := &engine.Plan{SessionID: "windows-tun", Engines: []engine.Kind{tc.kind},
				Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolShadowsocks,
					Server: "127.0.0.1", Port: uint16(serverPort), Cipher: "aes-256-gcm", Password: password}},
				Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "out"}},
				Tun: engine.Tun{Enabled: true, DeviceName: engine.TunDevice, Stack: tc.stack, AutoRoute: true,
					RouteAddressSets: []string{"203.0.113.0/24"}},
				DNS: engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "resolver", Address: "1.1.1.1", Transport: engine.DNSPlain}}}}
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
			ctx, cancel := context.WithTimeout(t.Context(), 30*time.Second)
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
			response, err := client.Get("http://" + destination)
			if err != nil {
				t.Fatalf("TCP packet through TUN: %v", err)
			}
			body, err := io.ReadAll(response.Body)
			_ = response.Body.Close()
			if err != nil || string(body) != reply {
				t.Fatalf("TCP packet reply: %q %v", body, err)
			}
			packet, err := (&net.Dialer{Timeout: 5 * time.Second}).DialContext(ctx, "udp", destination)
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = packet.Close() }()
			_ = packet.SetDeadline(time.Now().Add(5 * time.Second))
			payload := fmt.Sprintf("windows-tun-%s-%s", tc.kind, tc.stack)
			_, err = packet.Write([]byte(payload))
			buffer := make([]byte, 4096)
			var n int
			if err == nil {
				n, err = packet.Read(buffer)
			}
			if err != nil || string(buffer[:n]) != payload {
				t.Fatalf("UDP packet reply: %q %v", buffer[:n], err)
			}
		})
		if t.Failed() {
			break
		}
	}
	if err := manager.Disconnect(t.Context()); err != nil {
		t.Fatal(err)
	}
	if _, err := net.InterfaceByName(engine.TunDevice); err == nil {
		t.Fatal("disconnect retained the adapter")
	}
}
