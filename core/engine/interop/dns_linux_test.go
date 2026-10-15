//go:build linux

package interop_test

import (
	"context"
	"encoding/json"
	"encoding/pem"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"golang.org/x/net/dns/dnsmessage"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/logs"
)

func TestXrayTunInterceptsDNSOverUDPAndTCP(t *testing.T) {
	if os.Getenv("SORA_TUN_INTEGRATION") != "1" {
		t.Skip("requires the isolated TUN integration namespace")
	}
	self, err := os.Readlink("/proc/self/ns/net")
	if err != nil {
		t.Fatal(err)
	}
	if parent := os.Getenv("SORA_PARENT_NETNS"); parent == "" || parent == self {
		t.Fatal("DNS integration must not touch the host network")
	}
	var queries atomic.Int32
	doh := httptest.NewUnstartedServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 65536))
		var query dnsmessage.Message
		if err != nil || query.Unpack(body) != nil || len(query.Questions) != 1 {
			http.Error(w, "invalid DNS request", http.StatusBadRequest)
			return
		}
		query.Response = true
		query.RecursionAvailable = true
		question := query.Questions[0]
		if question.Type == dnsmessage.TypeA {
			query.Answers = []dnsmessage.Resource{{
				Header: dnsmessage.ResourceHeader{Name: question.Name, Type: dnsmessage.TypeA, Class: dnsmessage.ClassINET, TTL: 60},
				Body:   &dnsmessage.AResource{A: [4]byte{203, 0, 113, 99}},
			}}
		}
		response, err := query.Pack()
		if err != nil {
			http.Error(w, "invalid DNS response", http.StatusInternalServerError)
			return
		}
		queries.Add(1)
		w.Header().Set("Content-Type", "application/dns-message")
		_, _ = w.Write(response)
	}))
	doh.EnableHTTP2 = true
	doh.StartTLS()
	t.Cleanup(doh.Close)
	certificate := filepath.Join(t.TempDir(), "resolver.pem")
	if err := os.WriteFile(certificate, pem.EncodeToMemory(&pem.Block{
		Type: "CERTIFICATE", Bytes: doh.TLS.Certificates[0].Certificate[0],
	}), 0600); err != nil {
		t.Fatal(err)
	}
	enginetest.TrustCertificate(t, certificate)
	_, resolverPort, err := net.SplitHostPort(strings.TrimPrefix(doh.URL, "https://"))
	if err != nil {
		t.Fatal(err)
	}
	portNumber, err := strconv.ParseUint(resolverPort, 10, 16)
	if err != nil {
		t.Fatal(err)
	}
	// A provider cannot reach the client's LAN resolver. Forwarding its TCP
	// request through the proxy must fail; interception must use session DNS.
	unreachable, err := (&net.ListenConfig{}).Listen(t.Context(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = unreachable.Close() })
	var forwarded atomic.Int32
	go func() {
		for {
			connection, err := unreachable.Accept()
			if err != nil {
				return
			}
			forwarded.Add(1)
			_ = connection.Close()
		}
	}()
	dir := os.Getenv("SORA_ENGINES_DIR")
	binary, err := xray.Prober.Discover(t.Context(), dir)
	if err != nil {
		t.Fatal(err)
	}
	proxyPort := port(t)
	startServer(t, binary, []service{{inbound: map[string]any{
		"listen": "127.0.0.1", "port": proxyPort, "protocol": "shadowsocks",
		"settings": map[string]any{"method": "aes-256-gcm", "password": password},
	}}}, unreachable.Addr().String())
	for _, profile := range []bool{false, true} {
		t.Run(strconv.FormatBool(profile), func(t *testing.T) {
			journal := logs.New(logs.Settings{CaptureLevel: logs.LevelDebug, RecordDestinations: true})
			t.Cleanup(func() {
				if t.Failed() {
					for _, e := range journal.Query(logs.Filter{}, 0, 100).Entries {
						t.Log(e.Message)
					}
				}
			})
			plan := &engine.Plan{
				SessionID: "dns-fallback", Engines: []engine.Kind{engine.KindXray}, PrivateControl: true,
				Tun: engine.Tun{Enabled: true, DeviceName: engine.TunDevice, Stack: "gvisor"},
				Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolShadowsocks,
					Server: "127.0.0.1", Port: uint16(proxyPort), Cipher: "aes-256-gcm", Password: password}},
				Rules:   []engine.Rule{{Type: engine.RuleMatchAll, Target: "out"}},
				Options: engine.Options{LogLevel: "debug"},
				DNS: engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "resolver", Address: "127.0.0.1",
					Port: uint16(portNumber), Transport: engine.DNSHTTPS}}},
			}
			if profile {
				raw, err := json.Marshal(map[string]any{"outbounds": []any{map[string]any{
					"tag": "provider", "protocol": "shadowsocks", "settings": map[string]any{"servers": []any{map[string]any{
						"address": "127.0.0.1", "port": proxyPort, "method": "aes-256-gcm", "password": password,
					}}},
				}}})
				if err != nil {
					t.Fatal(err)
				}
				plan.Outbounds = []engine.Outbound{{ID: "out", Protocol: engine.ProtocolXrayProfile,
					Server: "127.0.0.1", Port: uint16(proxyPort), Profile: raw}}
			}
			reg := registry.Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir(), Logs: journal})
			eng, err := reg.Factory()(t.Context(), plan)
			if err != nil {
				t.Fatal(err)
			}
			t.Cleanup(func() { _ = eng.Close() })
			if err := eng.Apply(t.Context(), plan); err != nil {
				t.Fatal(err)
			}
			if output, err := exec.CommandContext(t.Context(), "ip", "route", "replace", "203.0.113.53/32", "dev", engine.TunDevice).CombinedOutput(); err != nil {
				t.Fatalf("DNS test route: %v %s", err, output)
			}
			for _, protocol := range []string{"udp", "tcp"} {
				t.Run(protocol, func(t *testing.T) {
					resolver := net.Resolver{PreferGo: true, Dial: func(ctx context.Context, _, _ string) (net.Conn, error) {
						return (&net.Dialer{}).DialContext(ctx, protocol, "203.0.113.53:53")
					}}
					ctx, cancel := context.WithTimeout(t.Context(), 3*time.Second)
					defer cancel()
					addresses, err := resolver.LookupNetIP(ctx, "ip4", "sora-"+protocol+".test")
					if err != nil || len(addresses) != 1 || addresses[0] != netip.MustParseAddr("203.0.113.99") {
						t.Fatalf("%s DNS through TUN: %v %v", protocol, addresses, err)
					}
				})
			}
			if err := eng.Stop(t.Context()); err != nil {
				t.Fatal(err)
			}
		})
	}
	if queries.Load() == 0 || forwarded.Load() != 0 {
		t.Fatalf("DNS bypassed the session resolver: DoH=%d forwarded=%d", queries.Load(), forwarded.Load())
	}
}
