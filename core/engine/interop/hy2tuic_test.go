package interop_test

// Hysteria2 and TUIC interop by fact of traffic (CENSOR-P3): a local
// sing-box server speaks hy2 and TUIC (plain, salamander obfs, gecko
// obfs, port hopping over several listen ports, TUIC congestion and
// heartbeat tuning), and every engine that claims the feature must
// carry real HTTP traffic through it — or fail, for the negative
// controls. Validators and `check`/`-t` acceptance alone miss
// silently ignored keys (mihomo accepts an unknown TUIC congestion
// controller at config load), so this suite only believes bytes
// arriving at the target.
//
// Environment honesty: in the audit sandbox UDP is blocked, so
// this traffic verification did NOT run there — the suite probes
// the environment by fact (udpChildProbeWorks below), self-skips
// with the reason, and the live QUIC run remains pending a
// UDP-capable dev machine. Config acceptance (`sing-box check`,
// `mihomo -t`) and the unit tests are what was verified in the
// sandbox; they are not a substitute for this traffic run.
//
// Hopping scenario honesty: a Hysteria2 server does not "hop"; the
// client rotates destination ports. The server side here is three
// identical hy2 inbounds on the three ports of the client's hop
// spec, so whichever port a connection lands on is served. Repeated
// fetches with fresh engines exercise more than one port over the
// run; the assertion that matters — traffic flows with a hop spec
// the old sing-box render made unstartable ("bad port range") — is
// deterministic.

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
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/singbox"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

const (
	hy2Password  = "hy2-interop-password"
	tuicPassword = "tuic-interop-password"
	obfsPassword = "obfs-interop-password"
)

// writeTestCert creates a self-signed server certificate for
// example.com / 127.0.0.1 in dir and returns its paths. Clients use
// TLS.Insecure (sing-box, mihomo) or the SSL_CERT_FILE wrapper
// (Xray, via enginetest.TrustCertificate in the hy2 plain case).
func writeTestCert(t *testing.T, dir string) (certPath, keyPath string) {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	tmpl := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{CommonName: "example.com"},
		DNSNames:     []string{"example.com"},
		IPAddresses:  []net.IP{net.ParseIP("127.0.0.1")},
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(24 * time.Hour),
		KeyUsage:     x509.KeyUsageDigitalSignature | x509.KeyUsageKeyEncipherment,
		ExtKeyUsage:  []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
	}
	der, err := x509.CreateCertificate(rand.Reader, tmpl, tmpl, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	certPath, keyPath = filepath.Join(dir, "cert.pem"), filepath.Join(dir, "key.pem")
	if err := os.WriteFile(certPath, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der}), 0o600); err != nil {
		t.Fatal(err)
	}
	keyDER, err := x509.MarshalECPrivateKey(key)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(keyPath, pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: keyDER}), 0o600); err != nil {
		t.Fatal(err)
	}
	return certPath, keyPath
}

// startHy2TUICServer starts one sing-box process serving every
// scenario inbound and returns the port assignments.
type hy2Ports struct {
	plain, salamander, gecko, tuic int
	hop                            [3]int
}

func startHy2TUICServer(t *testing.T, dir string) (hy2Ports, string) {
	t.Helper()
	certPath, keyPath := writeTestCert(t, t.TempDir())
	p := hy2Ports{plain: port(t), salamander: port(t), gecko: port(t), tuic: port(t),
		hop: [3]int{port(t), port(t), port(t)}}
	tlsBlock := map[string]any{"enabled": true, "server_name": "example.com",
		"certificate_path": certPath, "key_path": keyPath}
	hy2Inbound := func(tag string, listenPort int, obfs map[string]any) map[string]any {
		in := map[string]any{
			"type": "hysteria2", "tag": tag, "listen": "127.0.0.1", "listen_port": listenPort,
			"users": []any{map[string]any{"password": hy2Password}},
			"tls":   tlsBlock,
		}
		if obfs != nil {
			in["obfs"] = obfs
		}
		return in
	}
	obfs := func(typ string) map[string]any { return map[string]any{"type": typ, "password": obfsPassword} }
	inbounds := []any{
		hy2Inbound("hy2-plain", p.plain, nil),
		hy2Inbound("hy2-salamander", p.salamander, obfs("salamander")),
		hy2Inbound("hy2-gecko", p.gecko, obfs("gecko")),
		hy2Inbound("hy2-hop-0", p.hop[0], nil),
		hy2Inbound("hy2-hop-1", p.hop[1], nil),
		hy2Inbound("hy2-hop-2", p.hop[2], nil),
		map[string]any{
			"type": "tuic", "tag": "tuic-in", "listen": "127.0.0.1", "listen_port": p.tuic,
			"users":              []any{map[string]any{"uuid": uuid, "password": tuicPassword}},
			"congestion_control": "bbr",
			"tls":                tlsBlock,
		},
	}
	cfg, err := json.Marshal(map[string]any{
		"log":       map[string]any{"level": "warn"},
		"inbounds":  inbounds,
		"outbounds": []any{map[string]any{"type": "direct", "tag": "direct"}},
	})
	if err != nil {
		t.Fatal(err)
	}
	cfgPath := filepath.Join(t.TempDir(), "server.json")
	if err := os.WriteFile(cfgPath, cfg, 0o600); err != nil {
		t.Fatal(err)
	}
	bin, err := singbox.Prober.Discover(context.Background(), dir, supervise.DiscoveryOptions{})
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	proc, err := supervise.Start(ctx, supervise.Spec{Name: "sing-box-hy2-tuic-server", Path: bin.Path,
		Args: []string{"run", "-c", cfgPath}, Dir: t.TempDir()})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cancel()
		_ = proc.Stop(context.Background(), 0)
	})
	time.Sleep(500 * time.Millisecond)
	if err := proc.Err(); err != nil {
		t.Fatalf("sing-box hy2/tuic server: %v", err)
	}
	return p, certPath
}

// runClientOnce starts one engine of the given kind with a single
// outbound and fetches the target through its local proxy.
func runClientOnce(t *testing.T, dir string, kind engine.Kind, o engine.Outbound, target string) (string, error) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	local := port(t)
	reg := registry.Discover(ctx, dir, supervise.Config{HomeDir: t.TempDir(), LocalPort: local, StartTimeout: 10 * time.Second})
	plan := &engine.Plan{
		SessionID:  "hy2tuic-interop",
		Engines:    []engine.Kind{kind},
		LocalProxy: engine.LocalProxy{Enabled: true},
		Outbounds:  []engine.Outbound{o},
		Rules:      []engine.Rule{{Type: engine.RuleMatchAll, Target: o.ID}},
		Options:    engine.Options{LogLevel: "warning", TestURL: engine.TestURLProduction},
	}
	eng, err := reg.Factory()(ctx, plan)
	if err != nil {
		return "", err
	}
	defer func() { _ = eng.Close() }()
	if err := eng.Apply(ctx, plan); err != nil {
		return "", fmt.Errorf("apply: %w", err)
	}
	return fetch(ctx, local, target)
}

// udpChildProbeWorks reports whether a process spawned by this
// test can send a UDP datagram over loopback. It re-executes the
// test binary as a child running TestUDPChildProbe, because the
// ability that matters is the engine children's, not this process's.
// How the audit sandbox blocks UDP depends on the probe type
// (measured 2026-10-20): python/shell raw-socket probes fail at
// sendto with EPERM (Operation not permitted), while the Go child
// probe here does not get EPERM — its datagram is silently
// dropped and the read times out (i/o timeout). Both forms mean
// UDP is unavailable there, and this probe treats either as a
// failure of the child, so QUIC scenarios cannot run there at
// all; the suite skips with the reason instead of burning minutes
// on handshake timeouts that would look like engine failures. On
// a machine without the policy the probe passes and the full
// matrix runs.
func udpChildProbeWorks(t *testing.T) (bool, string) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, os.Args[0], "-test.run", "^TestUDPChildProbe$", "-test.count=1", "-test.v")
	cmd.Env = append(os.Environ(), "SORA_UDP_PROBE_CHILD=1")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return false, fmt.Sprintf("udp child probe: %v: %s", err, out)
	}
	return true, ""
}

// TestUDPChildProbe is the child half of udpChildProbeWorks: a plain
// in-process UDP loopback echo exchange. It only runs when re-executed
// as a child (SORA_UDP_PROBE_CHILD=1); in a normal suite run it skips.
func TestUDPChildProbe(t *testing.T) {
	if os.Getenv("SORA_UDP_PROBE_CHILD") != "1" {
		t.Skip("child-probe helper")
	}
	ln, err := net.ListenPacket("udp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	defer ln.Close()
	go func() {
		buf := make([]byte, 2048)
		n, addr, err := ln.ReadFrom(buf)
		if err == nil {
			_, _ = ln.WriteTo(buf[:n], addr)
		}
	}()
	c, err := net.Dial("udp", ln.LocalAddr().String())
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer c.Close()
	_ = c.SetDeadline(time.Now().Add(3 * time.Second))
	if _, err := c.Write(make([]byte, 1200)); err != nil {
		t.Fatalf("write: %v", err)
	}
	buf := make([]byte, 2048)
	if _, err := c.Read(buf); err != nil {
		t.Fatalf("read: %v", err)
	}
}

func TestHysteria2AndTUICThroughEngines(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	if ok, why := udpChildProbeWorks(t); !ok {
		t.Skipf("UDP traffic from spawned engine processes is unavailable in this environment, so QUIC scenarios cannot run here (run on a dev machine): %s", why)
	}
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = io.WriteString(w, reply) }))
	defer target.Close()
	ports, serverCert := startHy2TUICServer(t, dir)

	hy2 := func(id string, listenPort int) engine.Outbound {
		return engine.Outbound{
			ID: id, Name: id, Protocol: engine.ProtocolHysteria2,
			Server: "127.0.0.1", Port: uint16(listenPort), Password: hy2Password,
			TLS: engine.TLS{Enabled: true, ServerName: "example.com", Insecure: true, ALPN: []string{"h3"}},
		}
	}
	tuic := func(id string) engine.Outbound {
		return engine.Outbound{
			ID: id, Name: id, Protocol: engine.ProtocolTUIC,
			Server: "127.0.0.1", Port: uint16(ports.tuic), UUID: uuid, Password: tuicPassword,
			TLS: engine.TLS{Enabled: true, ServerName: "example.com", Insecure: true, ALPN: []string{"h3"}},
		}
	}
	// The hop spec names exactly the served ports; the generated
	// free ports are not contiguous, so the spec is a port list.
	hopSpec := fmt.Sprintf("%d,%d,%d", ports.hop[0], ports.hop[1], ports.hop[2])

	type scenario struct {
		name     string
		outbound engine.Outbound
		kinds    []engine.Kind
		wantErr  bool
	}
	salamander := hy2("hy2-salamander", ports.salamander)
	salamander.Obfs, salamander.ObfsParam = "salamander", obfsPassword
	gecko := hy2("hy2-gecko", ports.gecko)
	gecko.Obfs, gecko.ObfsParam = "gecko", obfsPassword
	hopping := hy2("hy2-hop", ports.hop[0])
	hopping.HopPorts, hopping.HopInterval = hopSpec, 30
	hopping.UpMbps, hopping.DownMbps = 20, 100
	badObfs := hy2("hy2-bad-obfs", ports.salamander)
	badObfs.Obfs, badObfs.ObfsParam = "salamander", "wrong-obfs-password"
	crossObfs := hy2("hy2-cross-obfs", ports.salamander)
	crossObfs.Obfs, crossObfs.ObfsParam = "gecko", obfsPassword
	badPassword := hy2("hy2-bad-password", ports.plain)
	badPassword.Password = "wrong-password"
	tuicTuned := tuic("tuic-tuned")
	tuicTuned.CongestionControl, tuicTuned.UDPRelayMode, tuicTuned.TUICHeartbeat = "cubic", "quic", 25
	tuicBad := tuic("tuic-bad-password")
	tuicBad.Password = "wrong-password"

	both := []engine.Kind{engine.KindSingBox, engine.KindMihomo}
	scenarios := []scenario{
		{"hy2-plain", hy2("hy2-plain", ports.plain), both, false},
		{"hy2-salamander", salamander, both, false},
		{"hy2-gecko", gecko, both, false},
		{"hy2-hopping-brutal", hopping, both, false},
		{"tuic-plain", tuic("tuic-plain"), both, false},
		{"tuic-tuned-cubic-quic-heartbeat", tuicTuned, both, false},
		// Negative controls: traffic must NOT arrive.
		{"hy2-wrong-obfs-password", badObfs, both, true},
		{"hy2-gecko-against-salamander-server", crossObfs, both, true},
		{"hy2-wrong-password", badPassword, both, true},
		{"tuic-wrong-password", tuicBad, both, true},
	}
	for _, sc := range scenarios {
		for _, kind := range sc.kinds {
			t.Run(string(kind)+"/"+sc.name, func(t *testing.T) {
				// Selection must agree with the scenario: every
				// positive case is claimable by the engine, and
				// Xray must refuse the gated ones (checked in the
				// gate subtest below, not per-scenario).
				body, err := runClientOnce(t, dir, kind, sc.outbound, target.URL)
				if sc.wantErr {
					if err == nil && body == reply {
						t.Fatalf("negative control reached the target through %s: traffic bypassed the tunnel or the server accepted bad credentials", kind)
					}
					return
				}
				if err != nil {
					t.Fatalf("request through %s: %v", kind, err)
				}
				if body != reply {
					t.Fatalf("got %q, want %q", body, reply)
				}
			})
		}
	}

	// Xray carries plain hy2 (no obfs, no hopping) with real TLS
	// verification: the catalog refuses insecure hy2 plans on Xray,
	// so the client trusts the server's self-signed cert through
	// the SSL_CERT_FILE wrapper (enginetest.TrustCertificate), the
	// same mechanism the XHTTP-TLS matrix uses. Known rig caveat
	// (CENSOR-P2 §escalations, post-SORA-H5): the digest manifest
	// drops CA wrapper binaries unless the discovery opt-in
	// AllowEnvBin is set and the wrappers keep their engine names;
	// if this subtest reports the Xray binary as unusable while the
	// bare binary works, that manifest gate — not the hy2 path — is
	// the suspect.
	t.Run("xray/hy2-plain-verified-tls", func(t *testing.T) {
		enginetest.TrustCertificate(t, serverCert)
		o := hy2("hy2-xray", ports.plain)
		o.TLS.Insecure = false
		body, err := runClientOnce(t, dir, engine.KindXray, o, target.URL)
		if err != nil {
			t.Fatalf("request through xray: %v", err)
		}
		if body != reply {
			t.Fatalf("got %q, want %q", body, reply)
		}
	})
}

// TestHy2SelectionGates is the selection half of the matrix, split
// out because it needs no traffic: Xray must refuse obfuscated and
// hopping hy2 plans at selection (FeatureHy2Obfs / FeatureHy2PortHop),
// sing-box must accept them. It runs even where UDP is unavailable.
func TestHy2SelectionGates(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	mk := func(id string) engine.Outbound {
		return engine.Outbound{ID: id, Name: id, Protocol: engine.ProtocolHysteria2,
			Server: "127.0.0.1", Port: 443, Password: hy2Password,
			TLS: engine.TLS{Enabled: true, ServerName: "example.com", Insecure: true}}
	}
	salamander := mk("gate-salamander")
	salamander.Obfs, salamander.ObfsParam = "salamander", obfsPassword
	hopping := mk("gate-hopping")
	hopping.HopPorts, hopping.HopInterval = "31446,31447", 30
	{
		availability := registry.Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir()}).Availability()
		for _, o := range []engine.Outbound{salamander, hopping} {
			plan := &engine.Plan{SessionID: "gate", Outbounds: []engine.Outbound{o},
				Rules:   []engine.Rule{{Type: engine.RuleMatchAll, Target: o.ID}},
				Options: engine.Options{LogLevel: "warning", TestURL: engine.TestURLProduction}}
			if _, err := engine.SelectEngine(plan, availability, []engine.Kind{engine.KindXray}); err == nil {
				t.Fatalf("Xray must not be selected for gated hy2 outbound %s", o.ID)
			}
			if _, err := engine.SelectEngine(plan, availability, []engine.Kind{engine.KindSingBox}); err != nil {
				t.Fatalf("sing-box must carry gated hy2 outbound %s: %v", o.ID, err)
			}
		}
	}
}
