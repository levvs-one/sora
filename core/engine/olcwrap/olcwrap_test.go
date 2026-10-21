package olcwrap

import (
	"context"
	"errors"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/logs"
)

// stubEngine is a minimal engine.Engine that records what the
// decorator hands it.
type stubEngine struct {
	applied   *engine.Plan
	validated *engine.Plan
}

func (s *stubEngine) Kind() engine.Kind                 { return engine.KindSingBox }
func (s *stubEngine) Capabilities() engine.Capabilities { return engine.Capabilities{} }
func (s *stubEngine) State() engine.State               { return engine.StateIdle }
func (s *stubEngine) Version() engine.Version           { return engine.Version{} }
func (s *stubEngine) Groups(context.Context) ([]engine.GroupStatus, error) {
	return nil, nil
}
func (s *stubEngine) Select(context.Context, string, string) error { return nil }
func (s *stubEngine) Delay(context.Context, string, string, time.Duration) (time.Duration, error) {
	return 0, nil
}
func (s *stubEngine) Counters(context.Context) (engine.Counters, error) {
	return engine.Counters{}, nil
}
func (s *stubEngine) Events() *engine.EventBus { return nil }
func (s *stubEngine) Validate(_ context.Context, p *engine.Plan) error {
	s.validated = p
	return nil
}
func (s *stubEngine) Apply(_ context.Context, p *engine.Plan) error { s.applied = p; return nil }
func (s *stubEngine) Stop(context.Context) error                    { return nil }
func (s *stubEngine) Close() error                                  { return nil }

func olcOutbound(id, provider, transport string) engine.Outbound {
	return engine.Outbound{
		ID: id, Name: id, Protocol: engine.ProtocolOLCRTC, Server: "room-01",
		Password: testKey,
		Olcrtc:   &engine.OlcrtcConfig{Provider: provider, Transport: transport, Room: "room-01"},
	}
}

func planWith(outs ...engine.Outbound) *engine.Plan {
	return &engine.Plan{
		SessionID: "test",
		Outbounds: outs,
		DNS:       engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "dns-0", Transport: engine.DNSPlain, Address: "1.1.1.1", Port: 53}}},
	}
}

// fakeSidecar writes a stand-in olcrtc binary: a shell script that
// execs a python listener on the port its YAML config names.
func fakeSidecar(t *testing.T) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "olcrtc")
	body := `#!/bin/sh
exec python3 - "$1" <<'EOF'
import socket, sys
port = 0
for line in open(sys.argv[1]):
    s = line.strip()
    if s.startswith("port:"):
        port = int(s.split(":", 1)[1])
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", port))
s.listen(5)
while True:
    c, _ = s.accept()
    c.close()
EOF
`
	if err := os.WriteFile(path, []byte(body), 0o755); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestRewriteForAllEnginesShape(t *testing.T) {
	// The rewrite is engine-agnostic: whatever engine the registry
	// picks (sing-box, mihomo or Xray) receives the same SOCKS5
	// outbound. This pins the shape all three renderers consume.
	p := planWith(olcOutbound("a", "jitsi", "datachannel"),
		engine.Outbound{ID: "d", Protocol: engine.ProtocolDirect})
	cfg := ConfigFromOutbound(p.Outbounds[0], "1.1.1.1:53")
	out := Rewrite(p, "1.1.1.1:53", map[string]Listener{cfg.Key(): {Port: 41001, User: "u1", Pass: "p1"}})
	got := out.Outbounds[0]
	if got.Protocol != engine.ProtocolSOCKS5 || got.Server != "127.0.0.1" || got.Port != 41001 ||
		got.UserID != "u1" || got.Password != "p1" || got.SOCKSUDP {
		t.Fatalf("rewritten = %+v, want authenticated loopback SOCKS5 without UDP", got)
	}
	if out.Outbounds[1].Protocol != engine.ProtocolDirect {
		t.Fatalf("non-olcrtc outbound touched: %+v", out.Outbounds[1])
	}
	if p.Outbounds[0].Protocol != engine.ProtocolOLCRTC {
		t.Fatal("Rewrite mutated the caller's plan")
	}
	// Without listeners (validation/selection), the placeholder
	// port is 1 and no credentials appear.
	out = Rewrite(p, "1.1.1.1:53", nil)
	if got := out.Outbounds[0]; got.Port != 1 || got.UserID != "" || got.Password != "" {
		t.Fatalf("placeholder rewrite = %+v", got)
	}
}

func TestValidateConnectMatrix(t *testing.T) {
	base := Config{Provider: "jitsi", Transport: "datachannel", Room: "room-01", KeyHex: testKey, DNS: "1.1.1.1:53"}
	cases := []struct {
		name   string
		mutate func(*Config)
		key    errs.Key // "" means connectable
	}{
		{"jitsi datachannel", func(c *Config) {}, ""},
		{"jitsi seichannel", func(c *Config) { c.Transport = "seichannel" }, ""},
		{"jitsi videochannel", func(c *Config) { c.Transport = "videochannel" }, ""},
		{"jitsi vp8channel", func(c *Config) { c.Transport = "vp8channel" }, ""},
		{"telemost datachannel", func(c *Config) { c.Provider = "telemost" }, errs.KeyOlcrtcCombination},
		{"telemost seichannel", func(c *Config) { c.Provider, c.Transport = "telemost", "seichannel" }, errs.KeyOlcrtcCombination},
		{"telemost vp8channel", func(c *Config) { c.Provider, c.Transport = "telemost", "vp8channel" }, ""},
		{"telemost videochannel", func(c *Config) { c.Provider, c.Transport = "telemost", "videochannel" }, ""},
		{"wbstream datachannel guest", func(c *Config) { c.Provider = "wbstream" }, errs.KeyOlcrtcTokenRequired},
		{"wbstream datachannel with token", func(c *Config) { c.Provider, c.AuthToken = "wbstream", "tok" }, ""},
		{"wbstream seichannel guest", func(c *Config) { c.Provider, c.Transport = "wbstream", "seichannel" }, ""},
		{"wbstream vp8channel guest", func(c *Config) { c.Provider, c.Transport = "wbstream", "vp8channel" }, ""},
		{"none is not connectable", func(c *Config) { c.Provider, c.Room = "none", "" }, errs.KeyOlcrtcNotConnectable},
		{"server mode always refused", func(c *Config) { c.Mode = "srv" }, errs.KeyOlcrtcServerMode},
		{"bad key", func(c *Config) { c.KeyHex = "abc" }, errs.KeyOlcrtcInvalid},
		{"unknown provider", func(c *Config) { c.Provider = "zoom" }, errs.KeyOlcrtcInvalid},
		{"unknown transport", func(c *Config) { c.Transport = "smokechannel" }, errs.KeyOlcrtcInvalid},
		{"missing room", func(c *Config) { c.Room = "" }, errs.KeyOlcrtcInvalid},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			cfg := base
			tc.mutate(&cfg)
			err := ValidateConnect(cfg)
			if tc.key == "" {
				if err != nil {
					t.Fatalf("ValidateConnect = %v, want connectable", err)
				}
				return
			}
			var ce *errs.Error
			if !errors.As(err, &ce) || ce.Key() != tc.key {
				t.Fatalf("ValidateConnect = %v, want key %s", err, tc.key)
			}
		})
	}
}

func TestSidecarLifecycle(t *testing.T) {
	home := filepath.Join(t.TempDir(), "olcrtc-home")
	inner := &stubEngine{}
	center := logs.New(logs.Settings{})
	e := Wrap(inner, fakeSidecar(t), home, center)
	p := planWith(olcOutbound("a", "jitsi", "datachannel"))
	if err := e.Apply(context.Background(), p); err != nil {
		t.Fatalf("apply: %v", err)
	}
	// The inner engine received a SOCKS5 plan pointing at a live
	// listener with credentials.
	if inner.applied == nil {
		t.Fatal("inner engine never applied")
	}
	got := inner.applied.Outbounds[0]
	if got.Protocol != engine.ProtocolSOCKS5 || got.Port == 0 || got.Port == 1 || got.UserID == "" || got.Password == "" {
		t.Fatalf("applied outbound = %+v", got)
	}
	conn, err := net.DialTimeout("tcp", "127.0.0.1:"+strconv.Itoa(int(got.Port)), 2*time.Second)
	if err != nil {
		t.Fatalf("sidecar listener does not accept: %v", err)
	}
	_ = conn.Close()
	// The rendered config exists during the session, owner-only,
	// inside an owner-only home, and carries the plan resolver —
	// never the sidecar's own 8.8.8.8 default.
	entries, err := os.ReadDir(home)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 1 {
		t.Fatalf("home holds %d files, want the one config", len(entries))
	}
	cfgPath := filepath.Join(home, entries[0].Name())
	info, err := os.Stat(cfgPath)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("config mode = %o, want 0600", info.Mode().Perm())
	}
	if hinfo, err := os.Stat(home); err != nil || hinfo.Mode().Perm() != 0o700 {
		t.Fatalf("home mode = %v, %v; want 0700", hinfo.Mode().Perm(), err)
	}
	raw, err := os.ReadFile(cfgPath)
	if err != nil {
		t.Fatal(err)
	}
	text := string(raw)
	for _, want := range []string{"mode: cnc", `provider: "jitsi"`, `key: "` + testKey + `"`, `dns: "1.1.1.1:53"`, `user: "` + got.UserID + `"`} {
		if !strings.Contains(text, want) {
			t.Fatalf("config missing %q:\n%s", want, text)
		}
	}
	if strings.Contains(text, "8.8.8.8") {
		t.Fatalf("config fell back to the sidecar default resolver:\n%s", text)
	}
	// Two outbounds with one configuration share one sidecar.
	p2 := planWith(olcOutbound("a", "jitsi", "datachannel"), olcOutbound("b", "jitsi", "datachannel"))
	if err := e.Apply(context.Background(), p2); err != nil {
		t.Fatalf("apply two: %v", err)
	}
	e.mu.Lock()
	n := len(e.procs)
	e.mu.Unlock()
	if n != 1 {
		t.Fatalf("sidecars = %d, want 1 shared", n)
	}
	// Stop removes the config file and kills the listener.
	if err := e.Stop(context.Background()); err != nil {
		t.Fatalf("stop: %v", err)
	}
	if _, err := os.Stat(cfgPath); !os.IsNotExist(err) {
		t.Fatalf("config survived Stop: %v", err)
	}
	if conn, err := net.DialTimeout("tcp", "127.0.0.1:"+strconv.Itoa(int(got.Port)), 300*time.Millisecond); err == nil {
		_ = conn.Close()
		t.Fatal("listener survived Stop")
	}
}

func TestSidecarDeathAtStartFailsClosed(t *testing.T) {
	path := filepath.Join(t.TempDir(), "olcrtc")
	if err := os.WriteFile(path, []byte("#!/bin/sh\necho 'olcrtc: cannot join room' >&2\nexit 1\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	inner := &stubEngine{}
	e := Wrap(inner, path, t.TempDir(), nil)
	err := e.Apply(context.Background(), planWith(olcOutbound("a", "jitsi", "datachannel")))
	if err == nil {
		t.Fatal("a sidecar that dies at start must fail Apply")
	}
	var ce *errs.Error
	if !errors.As(err, &ce) || ce.Key() != errs.KeyEngineStartFailed {
		t.Fatalf("error = %v, want key %s", err, errs.KeyEngineStartFailed)
	}
	if inner.applied != nil {
		t.Fatal("inner engine was applied behind a dead sidecar")
	}
}

func TestApplyGatesBeforeStateChanges(t *testing.T) {
	inner := &stubEngine{}
	e := Wrap(inner, fakeSidecar(t), t.TempDir(), nil)
	// wbstream+datachannel without a token: refused before any
	// sidecar starts and before the engine is touched.
	err := e.Apply(context.Background(), planWith(olcOutbound("a", "wbstream", "datachannel")))
	var ce *errs.Error
	if !errors.As(err, &ce) || ce.Key() != errs.KeyOlcrtcTokenRequired {
		t.Fatalf("error = %v, want key %s", err, errs.KeyOlcrtcTokenRequired)
	}
	if inner.applied != nil || len(e.procs) != 0 {
		t.Fatal("a gated plan changed state")
	}
	// No binary at all: the missing-binary key, also before state.
	e2 := Wrap(inner, "", t.TempDir(), nil)
	err = e2.Apply(context.Background(), planWith(olcOutbound("a", "jitsi", "datachannel")))
	if !errors.As(err, &ce) || ce.Key() != errs.KeyEngineBinaryMissing {
		t.Fatalf("error = %v, want key %s", err, errs.KeyEngineBinaryMissing)
	}
}

func TestLogLinesMaskTheKey(t *testing.T) {
	center := logs.New(logs.Settings{})
	inner := &stubEngine{}
	e := Wrap(inner, fakeSidecar(t), t.TempDir(), center)
	if err := e.Apply(context.Background(), planWith(olcOutbound("a", "jitsi", "datachannel"))); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = e.Stop(context.Background()) }()
	e.logLine("olcrtc: joined room-01 with key " + testKey)
	for _, entry := range center.Matching(logs.Filter{}) {
		if strings.Contains(entry.Message, testKey) {
			t.Fatalf("log line leaked the key: %q", entry.Message)
		}
		if strings.Contains(entry.Message, "[masked]") {
			return
		}
	}
	t.Fatal("no masked log entry found")
}

func TestPlanResolver(t *testing.T) {
	cases := []struct {
		name    string
		servers []engine.DNSServer
		want    string
	}{
		{"plain wins", []engine.DNSServer{{Transport: engine.DNSHTTPS, Address: "9.9.9.9"}, {Transport: engine.DNSPlain, Address: "1.1.1.1", Port: 5353}}, "1.1.1.1:5353"},
		{"plain default port", []engine.DNSServer{{Transport: engine.DNSTCP, Address: "8.8.4.4"}}, "8.8.4.4:53"},
		{"encrypted host fallback", []engine.DNSServer{{Transport: engine.DNSHTTPS, Address: "1.1.1.1"}}, "1.1.1.1:53"},
		{"ipv6 plain", []engine.DNSServer{{Transport: engine.DNSPlain, Address: "2606:4700:4700::1111"}}, "[2606:4700:4700::1111]:53"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := PlanResolver(&engine.Plan{DNS: engine.DNS{Servers: tc.servers}})
			if err != nil || got != tc.want {
				t.Fatalf("PlanResolver = %q, %v; want %q", got, err, tc.want)
			}
		})
	}
	// A system-only plan defers to the host resolver; on a host
	// without one it must error honestly, never invent 8.8.8.8.
	got, err := PlanResolver(&engine.Plan{DNS: engine.DNS{Servers: []engine.DNSServer{{Transport: engine.DNSSystem, Address: "system"}}}})
	if err == nil && (got == "" || strings.HasPrefix(got, "8.8.8.8")) {
		t.Fatalf("system fallback = %q", got)
	}
}
