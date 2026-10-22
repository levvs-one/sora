//go:build linux && amd64

package interop_test

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"math/big"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/logs"
)

func communityServer(t *testing.T, path string, args, env []string, listen int) {
	t.Helper()
	home := t.TempDir()
	cmd := exec.Command(path, args...) //nolint:gosec,noctx // pinned test server; cleanup always kills and reaps it
	cmd.Dir = home
	cmd.Env = append(os.Environ(), "HOME="+home, "XDG_DATA_HOME="+home, "XDG_CONFIG_HOME="+home)
	cmd.Env = append(cmd.Env, env...)
	tail := supervise.NewTail(40)
	cmd.Stdout, cmd.Stderr = tail, tail
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
	})
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		conn, err := (&net.Dialer{Timeout: 100 * time.Millisecond}).DialContext(t.Context(), "tcp", net.JoinHostPort("127.0.0.1", strconv.Itoa(listen)))
		if err == nil {
			_ = conn.Close()
			return
		}
		time.Sleep(25 * time.Millisecond)
	}
	t.Fatalf("server did not listen: %v", tail)
}

func TestCommunityServersCarryRealTraffic(t *testing.T) {
	engines, servers := os.Getenv("SORA_ENGINES_DIR"), os.Getenv("SORA_COMMUNITY_SERVERS_DIR")
	if engines == "" || servers == "" {
		t.Skip("set SORA_ENGINES_DIR and SORA_COMMUNITY_SERVERS_DIR after running community-servers.sh")
	}
	for name, want := range map[string]string{"mita": "3.38.1", "caddy": "v2.11.7"} {
		out, err := exec.CommandContext(t.Context(), filepath.Join(servers, name), "version").Output() //nolint:gosec // opt-in pinned test fixture directory
		if err != nil || !strings.HasPrefix(string(out), want) {
			t.Fatalf("unexpected %s version: %s %v", name, out, err)
		}
	}
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = io.WriteString(w, reply) }))
	defer target.Close()
	home := t.TempDir()
	mieruPort := port(t)
	mitaConfig, err := json.Marshal(map[string]any{
		"portBindings": []any{map[string]any{"port": mieruPort, "protocol": "TCP"}, map[string]any{"port": mieruPort, "protocol": "UDP"}},
		"users":        []any{map[string]any{"name": "alice", "password": password, "allowPrivateIP": true, "allowLoopbackIP": true}},
		"loggingLevel": "ERROR",
	})
	if err != nil {
		t.Fatal(err)
	}
	mitaPath := filepath.Join(home, "mita.json")
	if err := os.WriteFile(mitaPath, mitaConfig, 0600); err != nil {
		t.Fatal(err)
	}
	communityServer(t, filepath.Join(servers, "mita"), []string{"run"},
		[]string{"MITA_CONFIG_JSON_FILE=" + mitaPath, "MITA_UDS_PATH=" + filepath.Join(home, "mita.sock"), "MITA_INSECURE_UDS=1"}, mieruPort)

	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	cert := &x509.Certificate{SerialNumber: big.NewInt(1), Subject: pkix.Name{CommonName: "Community interop"},
		NotBefore: time.Now().Add(-time.Hour), NotAfter: time.Now().Add(24 * time.Hour),
		IPAddresses: []net.IP{net.ParseIP("127.0.0.1")}, KeyUsage: x509.KeyUsageDigitalSignature, ExtKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth}, BasicConstraintsValid: true}
	der, err := x509.CreateCertificate(rand.Reader, cert, cert, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	keyDER, err := x509.MarshalPKCS8PrivateKey(key)
	if err != nil {
		t.Fatal(err)
	}
	certPEM := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der})
	certPath, keyPath := filepath.Join(home, "cert.pem"), filepath.Join(home, "key.pem")
	for path, contents := range map[string][]byte{certPath: certPEM, keyPath: pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: keyDER})} {
		if err := os.WriteFile(path, contents, 0600); err != nil {
			t.Fatal(err)
		}
	}
	naivePort := port(t)
	caddyfile := fmt.Sprintf(`{
 admin off
 auto_https off
 order forward_proxy before respond
}
https://127.0.0.1:%d {
 tls %s %s
 forward_proxy {
  basic_auth alice %s
  hide_ip
  hide_via
  acl {
   allow 127.0.0.1
   deny all
  }
 }
 respond "front" 200
}
`, naivePort, certPath, keyPath, password)
	caddyPath := filepath.Join(home, "Caddyfile")
	if err := os.WriteFile(caddyPath, []byte(caddyfile), 0600); err != nil {
		t.Fatal(err)
	}
	communityServer(t, filepath.Join(servers, "caddy"), []string{"run", "--config", caddyPath, "--adapter", "caddyfile"}, nil, naivePort)

	for _, tc := range []struct {
		name string
		kind engine.Kind
		out  engine.Outbound
	}{
		{"mieru-tcp", engine.KindMihomo, engine.Outbound{Protocol: engine.ProtocolMieru, Port: uint16(mieruPort), Transport: engine.Transport{Type: "tcp"}, Mieru: &engine.Mieru{Multiplexing: "MULTIPLEXING_HIGH", HandshakeMode: "HANDSHAKE_NO_WAIT"}}},
		{"mieru-udp", engine.KindMihomo, engine.Outbound{Protocol: engine.ProtocolMieru, Port: uint16(mieruPort), Transport: engine.Transport{Type: "udp"}, Mieru: &engine.Mieru{PortRange: fmt.Sprintf("%d-%d", mieruPort, mieruPort), Multiplexing: "MULTIPLEXING_OFF"}}},
		{"naive-https", engine.KindSingBox, engine.Outbound{Protocol: engine.ProtocolNaive, Port: uint16(naivePort), Transport: engine.Transport{Type: "tcp"}, TLS: engine.TLS{Enabled: true}, Naive: &engine.Naive{Certificate: []string{string(certPEM)}, ExtraHeaders: map[string]string{"X-Community": "private-header"}}}},
		{"naive-quic", engine.KindSingBox, engine.Outbound{Protocol: engine.ProtocolNaive, Port: uint16(naivePort), Transport: engine.Transport{Type: "udp"}, TLS: engine.TLS{Enabled: true}, Naive: &engine.Naive{QUIC: true, Certificate: []string{string(certPEM)}}}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			for _, wrong := range []bool{false, true} {
				t.Run(fmt.Sprintf("wrong-password=%v", wrong), func(t *testing.T) {
					o := tc.out
					o.ID, o.Name, o.Server, o.UserID, o.Password = "out", tc.name, "127.0.0.1", "alice", password
					if wrong {
						o.Password = "wrong-community-password"
					}
					p := &engine.Plan{SessionID: "community", Engines: []engine.Kind{tc.kind}, LocalProxy: engine.LocalProxy{Enabled: true},
						Outbounds: []engine.Outbound{o}, Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "out"}}, Options: engine.Options{LogLevel: "debug"}}
					local := port(t)
					center := logs.New(logs.Settings{CaptureLevel: logs.LevelDebug})
					reg := registry.Discover(t.Context(), engines, supervise.Config{HomeDir: t.TempDir(), LocalPort: local, Logs: center, StartTimeout: 10 * time.Second})
					ctx, cancel := context.WithTimeout(t.Context(), 20*time.Second)
					defer cancel()
					eng, err := reg.Factory()(ctx, p)
					if err != nil {
						t.Fatal(err)
					}
					defer func() { _ = eng.Close() }()
					if err := eng.Apply(ctx, p); err != nil {
						t.Fatal(err)
					}
					body, err := fetch(ctx, local, target.URL)
					if wrong {
						if err == nil {
							t.Fatal("wrong credentials reached the target")
						}
					} else if err != nil || body != reply {
						for _, entry := range center.Matching(logs.Filter{}) {
							t.Log(entry.Message)
						}
						t.Fatalf("traffic: %q %v", body, err)
					}
					for _, entry := range center.Matching(logs.Filter{}) {
						if strings.Contains(entry.Message, o.Password) || strings.Contains(entry.Message, "private-header") {
							t.Fatal("credential reached engine logs")
						}
					}
				})
			}
		})
	}
}
