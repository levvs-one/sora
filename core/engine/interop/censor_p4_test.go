package interop_test

// CENSOR-P4 interop: AmneziaWG and Shadowsocks-2022/plugin plans
// proven by real traffic through the pinned binaries, not by config
// acceptance. Servers are sing-box-lx 1.14.3-lx.22 (the only AWG
// server sora ships); clients are sora plans rendered by each engine.
//
// Timing data ("мелочи" §4): every wait below is a named constant
// with its reason — no magic sleeps copied between tests.
//   - p4ServerSettle: after `run -c stdin:` a sing-box server needs
//     to bind its listeners before clients dial; the Xray harness
//     uses 300ms for the same fact, 500ms covers the WG endpoint's
//     device setup on this 2-core VM with headroom.
//   - p4StartTimeout: engine Apply budget. The harness uses 10s for
//     plain transports; AWG adds a junk+handshake round the plain
//     cases do not pay, so 20s.
//   - fetch() itself retries 5 times with a 5s client timeout and
//     300ms spacing (harness helper), which is the retry policy for
//     every case here — reused, not re-invented.

import (
	"context"
	"crypto/ecdh"
	"crypto/rand"
	"crypto/sha1"
	"encoding/base64"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/singbox"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/wgobfusc"
)

const (
	p4ServerSettle = 500 * time.Millisecond
	p4StartTimeout = 20 * time.Second
	p4CtxTimeout   = 60 * time.Second
	ss2022PSK      = "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=" // 32 bytes, test vector only
	ss2022WrongPSK = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
	ss2022Method   = "2022-blake3-aes-256-gcm"
	awgClientAddr  = "10.66.0.2/24"
	awgServerAddr  = "10.66.0.1/24"
	p4TargetReply  = reply
)

// startP4SingBoxServer runs a sing-box server config on loopback.
func startP4SingBoxServer(t *testing.T, dir string, cfg map[string]any) {
	t.Helper()
	bin, err := singbox.Prober.Discover(context.Background(), dir, supervise.DiscoveryOptions{})
	if err != nil {
		t.Fatal(err)
	}
	raw, err := json.Marshal(cfg)
	if err != nil {
		t.Fatal(err)
	}
	dir2 := t.TempDir()
	cfgPath := dir2 + "/server.json"
	if err := os.WriteFile(cfgPath, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	proc, err := supervise.Start(ctx, supervise.Spec{
		Name: "singbox-p4-server", Path: bin.Path,
		Args: []string{"run", "-c", cfgPath}, Dir: dir2,
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cancel()
		_ = proc.Stop(context.Background(), 0)
	})
	time.Sleep(p4ServerSettle)
	if err := proc.Err(); err != nil {
		t.Fatalf("sing-box p4 server: %v", err)
	}
}

// driveP4Client renders plan on the single named engine and fetches
// the target through its local proxy, harness-style.
func driveP4Client(t *testing.T, dir string, kind engine.Kind, plan *engine.Plan, target string) (string, error) {
	t.Helper()
	body, err, _ := driveP4ClientLogged(t, dir, kind, plan, target)
	return body, err
}

// driveP4ClientLogged is driveP4Client plus the engine log center,
// so a test can tell an environment block (this sandbox's seccomp
// profile denies sendmmsg, which wireguard-go requires) from a
// product failure. The distinction is made ONLY by the exact EPERM
// signature in the engine log (sandboxBlocksSendmmsg): a box that
// merely runs under some seccomp filter — the default Docker
// profile, which ALLOWS sendmmsg — must run the traffic proof, not
// skip it (CENSOR-P4 fix M1).
func driveP4ClientLogged(t *testing.T, dir string, kind engine.Kind, plan *engine.Plan, target string) (string, error, *logs.Center) {
	t.Helper()
	availability := registry.Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir()}).Availability()
	if _, err := engine.SelectEngine(plan, availability, []engine.Kind{kind}); err != nil {
		t.Fatalf("selection for %s: %v", kind, err)
	}
	local := port(t)
	center := logs.New(logs.Settings{CaptureLevel: logs.LevelDebug, RecordDestinations: true})
	reg := registry.Discover(context.Background(), dir, supervise.Config{
		HomeDir: t.TempDir(), LocalPort: local, StartTimeout: p4StartTimeout, Logs: center,
	})
	plan.Engines = []engine.Kind{kind}
	ctx, cancel := context.WithTimeout(context.Background(), p4CtxTimeout)
	defer cancel()
	eng, err := reg.Factory()(ctx, plan)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = eng.Close() }()
	if err := eng.Apply(ctx, plan); err != nil {
		t.Fatalf("Apply on %s: %v", kind, err)
	}
	body, err := fetch(ctx, local, target)
	return body, err, center
}

// sandboxBlocksSendmmsg reports whether the engine logs carry the
// signature of this sandbox's seccomp profile denying sendmmsg.
// wireguard-go sends handshake and junk packets with sendmmsg, so
// no userspace WireGuard/AmneziaWG traffic can flow here at all;
// that is an environment boundary (like the missing /dev/net/tun),
// not a product defect — the AWG test skips with the reason and
// must be re-run on a dev machine.
func sandboxBlocksSendmmsg(center *logs.Center) bool {
	for _, e := range center.Matching(logs.Filter{}) {
		if strings.Contains(e.Message, "sendmmsg: operation not permitted") {
			return true
		}
	}
	return false
}

func p4Plan(o engine.Outbound) *engine.Plan {
	return &engine.Plan{
		SessionID:  "censor-p4",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Outbounds:  []engine.Outbound{o},
		Rules:      []engine.Rule{{Type: engine.RuleMatchAll, Target: o.ID}},
		Options:    engine.Options{LogLevel: "warning", TestURL: engine.TestURLProduction},
	}
}

func p4Target(t *testing.T) string {
	t.Helper()
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, p4TargetReply)
	}))
	t.Cleanup(target.Close)
	return target.URL
}

func TestP4Shadowsocks2022Traffic(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	serverPort := port(t)
	startP4SingBoxServer(t, dir, map[string]any{
		"log":       map[string]any{"level": "error"},
		"inbounds":  []any{map[string]any{"type": "shadowsocks", "tag": "ss-in", "listen": "127.0.0.1", "listen_port": serverPort, "method": ss2022Method, "password": ss2022PSK}},
		"outbounds": []any{map[string]any{"type": "direct", "tag": "direct"}},
		"route":     map[string]any{"final": "direct"},
	})
	target := p4Target(t)
	mk := func(psk string) *engine.Plan {
		return p4Plan(engine.Outbound{ID: "ss2022", Name: "ss2022", Protocol: engine.ProtocolShadowsocks,
			Server: "127.0.0.1", Port: uint16(serverPort), Cipher: ss2022Method, Password: psk})
	}
	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindXray, engine.KindMihomo} {
		t.Run(string(kind), func(t *testing.T) {
			body, err := driveP4Client(t, dir, kind, mk(ss2022PSK), target)
			if err != nil {
				t.Fatalf("SS-2022 through %s: %v", kind, err)
			}
			if body != p4TargetReply {
				t.Fatalf("SS-2022 through %s: got %q", kind, body)
			}
		})
	}
	// Negative control: a valid-shape but wrong PSK must not pass traffic.
	t.Run("wrong-psk", func(t *testing.T) {
		if _, err := driveP4Client(t, dir, engine.KindSingBox, mk(ss2022WrongPSK), target); err == nil {
			t.Fatal("a wrong SS-2022 PSK reached the target: traffic bypassed the cipher")
		}
	})
	// Negative control at the plan level: chacha12-2022 is carried by
	// no pinned engine, so selection refuses it everywhere before any
	// process starts.
	t.Run("chacha12-refused-at-selection", func(t *testing.T) {
		availability := registry.Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir()}).Availability()
		p := mk(ss2022PSK)
		p.Outbounds[0].Cipher = "2022-blake3-chacha12-poly1305"
		if _, err := engine.SelectEngine(p, availability, engine.DefaultPreference); err == nil {
			t.Fatal("chacha12-2022 must be refused at selection: no pinned engine carries it")
		}
	})
}

// wsShim terminates the RFC 6455 half of a v2ray-plugin hop and
// records the stream the client sends. Measured on the pinned
// binaries (byte capture, 2026-10-20): both engines' v2ray-plugin
// clients speak v2ray mux.cool framing over the websocket —
// sing-box opens a control session to "v1.mux.cool" (the magic is
// visible verbatim in the first frame), mihomo frames the target
// session directly — so the stream behind the websocket is NOT a
// raw Shadowsocks stream, and completing the data plane needs a
// real mux.cool counterpart (the v2ray-plugin server binary),
// which neither the engines' inbounds (sing-box rejects "plugin"
// in an SS inbound as an unknown field) nor this sandbox provide.
// The shim therefore proves the plugin is genuinely on the wire
// (upgrade, path, mux framing) and the end-to-end data plane is
// escalated with the plugin-binary packaging decision.
// p4Observed records what the shim actually saw on the wire, so
// the plugin test asserts protocol facts (websocket upgrade,
// mux.cool framing) instead of guessing from fetch outcomes.
type p4Observed struct {
	mu       sync.Mutex
	upgraded bool
	path     string
	prefix   []byte // first bytes of the client->backend stream
}

func (o *p4Observed) noteUpgrade(path string) {
	o.mu.Lock()
	o.upgraded, o.path = true, path
	o.mu.Unlock()
}

func (o *p4Observed) notePayload(b []byte) {
	o.mu.Lock()
	if len(o.prefix) < 256 {
		o.prefix = append(o.prefix, b...)
		if len(o.prefix) > 256 {
			o.prefix = o.prefix[:256]
		}
	}
	o.mu.Unlock()
}

func (o *p4Observed) reset() {
	o.mu.Lock()
	o.upgraded, o.path, o.prefix = false, "", nil
	o.mu.Unlock()
}

func (o *p4Observed) snapshot() (bool, string, []byte) {
	o.mu.Lock()
	defer o.mu.Unlock()
	return o.upgraded, o.path, append([]byte(nil), o.prefix...)
}

type wsShim struct {
	backend  string
	observed *p4Observed
	mu       sync.Mutex // serializes frame writes: header+payload must not interleave
}

func (s *wsShim) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	key := r.Header.Get("Sec-Websocket-Key")
	if key == "" || !strings.EqualFold(r.Header.Get("Upgrade"), "websocket") {
		http.Error(w, "not a websocket upgrade", http.StatusBadRequest)
		return
	}
	sum := sha1.Sum([]byte(key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
	hj, ok := w.(http.Hijacker)
	if !ok {
		http.Error(w, "hijack unsupported", http.StatusInternalServerError)
		return
	}
	conn, buf, err := hj.Hijack()
	if err != nil {
		return
	}
	defer conn.Close()
	_, _ = buf.WriteString("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: " +
		base64.StdEncoding.EncodeToString(sum[:]) + "\r\n\r\n")
	_ = buf.Flush()
	if s.observed != nil {
		s.observed.noteUpgrade(r.URL.Path)
	}
	backend, err := net.Dial("tcp", s.backend)
	if err != nil {
		return
	}
	defer backend.Close()
	go func() { // backend -> client: one binary frame per read chunk
		tmp := make([]byte, 32*1024)
		for {
			n, err := backend.Read(tmp)
			if n > 0 {
				s.mu.Lock()
				_ = wsWriteFrame(conn, tmp[:n])
				s.mu.Unlock()
			}
			if err != nil {
				return
			}
		}
	}()
	for { // client -> backend: reassemble (possibly fragmented) messages
		payload, op, err := wsReadFrame(conn)
		if err != nil {
			return
		}
		switch op {
		case 1, 2, 0: // text/binary/continuation carry the SS stream
			if s.observed != nil {
				s.observed.notePayload(payload)
			}
			if _, err := backend.Write(payload); err != nil {
				return
			}
		case 8: // close
			return
		case 9: // ping -> pong
			s.mu.Lock()
			_ = wsWriteFrameOp(conn, 10, payload)
			s.mu.Unlock()
		}
	}
}

// wsReadFrame reads one frame, returning payload and opcode.
func wsReadFrame(conn net.Conn) ([]byte, byte, error) {
	var hdr [2]byte
	if _, err := io.ReadFull(conn, hdr[:]); err != nil {
		return nil, 0, err
	}
	op := hdr[0] & 0x0f
	masked := hdr[1]&0x80 != 0
	ln := uint64(hdr[1] & 0x7f)
	switch ln {
	case 126:
		var b [2]byte
		if _, err := io.ReadFull(conn, b[:]); err != nil {
			return nil, 0, err
		}
		ln = uint64(b[0])<<8 | uint64(b[1])
	case 127:
		var b [8]byte
		if _, err := io.ReadFull(conn, b[:]); err != nil {
			return nil, 0, err
		}
		ln = 0
		for _, c := range b {
			ln = ln<<8 | uint64(c)
		}
	}
	var mask [4]byte
	if masked {
		if _, err := io.ReadFull(conn, mask[:]); err != nil {
			return nil, 0, err
		}
	}
	payload := make([]byte, ln)
	if _, err := io.ReadFull(conn, payload); err != nil {
		return nil, 0, err
	}
	if masked {
		for i := range payload {
			payload[i] ^= mask[i%4]
		}
	}
	return payload, op, nil
}

func wsWriteFrame(conn net.Conn, payload []byte) error { return wsWriteFrameOp(conn, 2, payload) }

func wsWriteFrameOp(conn net.Conn, op byte, payload []byte) error {
	var hdr []byte
	switch n := len(payload); {
	case n < 126:
		hdr = []byte{0x80 | op, byte(n)}
	case n < 65536:
		hdr = []byte{0x80 | op, 126, byte(n >> 8), byte(n)}
	default:
		hdr = make([]byte, 10)
		hdr[0] = 0x80 | op
		hdr[1] = 127
		for i := 0; i < 8; i++ {
			hdr[2+i] = byte(uint64(n) >> (56 - 8*i))
		}
	}
	if _, err := conn.Write(hdr); err != nil {
		return err
	}
	_, err := conn.Write(payload)
	return err
}

func TestP4ShadowsocksV2RayPluginTraffic(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	// Plain SS backend the plugin hop forwards to.
	backendPort := port(t)
	startP4SingBoxServer(t, dir, map[string]any{
		"log":       map[string]any{"level": "error"},
		"inbounds":  []any{map[string]any{"type": "shadowsocks", "tag": "ss-in", "listen": "127.0.0.1", "listen_port": backendPort, "method": "aes-256-gcm", "password": password}},
		"outbounds": []any{map[string]any{"type": "direct", "tag": "direct"}},
		"route":     map[string]any{"final": "direct"},
	})
	observed := &p4Observed{}
	shim := httptest.NewServer(&wsShim{backend: "127.0.0.1:" + strconv.Itoa(backendPort), observed: observed})
	defer shim.Close()
	shimPort, _ := strconv.Atoi(strings.TrimPrefix(shim.URL, "http://127.0.0.1:"))
	target := p4Target(t)
	mk := func(withPlugin bool) *engine.Plan {
		o := engine.Outbound{ID: "ssvp", Name: "ssvp", Protocol: engine.ProtocolShadowsocks,
			Server: "127.0.0.1", Port: uint16(shimPort), Cipher: "aes-256-gcm", Password: password}
		if withPlugin {
			o.Plugin, o.PluginOpts = "v2ray-plugin", "host=example.com;path=/ws"
		}
		return p4Plan(o)
	}
	// Both engines' real v2ray-plugin clients must perform the
	// websocket upgrade to the rendered path and put mux.cool
	// framing on the wire. The fetch itself cannot complete: the
	// shim is not a mux.cool counterpart (see the wsShim comment),
	// so a fetch error is expected and the assertions are on the
	// captured wire bytes — that is what proves the rendered plugin
	// configuration is honored, not silently dropped.
	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindMihomo} {
		t.Run(string(kind)+"-plugin-on-wire", func(t *testing.T) {
			observed.reset()
			_, _ = driveP4Client(t, dir, kind, mk(true), target)
			upgraded, path, prefix := observed.snapshot()
			if !upgraded {
				t.Fatalf("%s v2ray-plugin client never performed the websocket upgrade", kind)
			}
			if path != "/ws" {
				t.Fatalf("%s plugin upgrade path = %q, want /ws (rendered plugin_opts)", kind, path)
			}
			if len(prefix) < 32 {
				t.Fatalf("%s plugin stream too short to be mux framing: %d bytes", kind, len(prefix))
			}
			if kind == engine.KindSingBox && !strings.Contains(string(prefix), "v1.mux.cool") {
				t.Fatalf("sing-box mux control session magic missing from stream prefix: %q", prefix[:32])
			}
		})
	}
	// Negative control: a plain SS client must not even upgrade —
	// the plugin hop refuses non-websocket traffic.
	t.Run("no-plugin-fails", func(t *testing.T) {
		observed.reset()
		if _, err := driveP4Client(t, dir, engine.KindSingBox, mk(false), target); err == nil {
			t.Fatal("plain shadowsocks reached the target through a websocket hop: the plugin is not on the wire")
		}
		if upgraded, _, _ := observed.snapshot(); upgraded {
			t.Fatal("plain shadowsocks performed a websocket upgrade")
		}
	})
	// Xray refuses the plan at selection (no plugin support), never
	// silently unobfuscated.
	t.Run("xray-refused-at-selection", func(t *testing.T) {
		availability := registry.Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir()}).Availability()
		if _, err := engine.SelectEngine(mk(true), availability, []engine.Kind{engine.KindXray}); err == nil {
			t.Fatal("a plugin plan must not select Xray")
		}
	})
}

func wgKey(t *testing.T) (priv, pub string) {
	t.Helper()
	k, err := ecdh.X25519().GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	return base64.StdEncoding.EncodeToString(k.Bytes()),
		base64.StdEncoding.EncodeToString(k.PublicKey().Bytes())
}

func TestP4AmneziaWGTraffic(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	awg, err := wgobfusc.Generate()
	if err != nil {
		t.Fatal(err)
	}
	serverPriv, serverPub := wgKey(t)
	clientPriv, clientPub := wgKey(t)
	serverPort := port(t)
	awgJSON := map[string]any{
		"jc": awg.Jc, "jmin": awg.Jmin, "jmax": awg.Jmax,
		"s1": awg.S1, "s2": awg.S2, "s3": awg.S3, "s4": awg.S4,
		"h1": awg.H1, "h2": awg.H2, "h3": awg.H3, "h4": awg.H4,
		"i1": awg.I1, "i2": awg.I2, "i3": awg.I3, "i4": awg.I4, "i5": awg.I5,
	}
	endpoint := map[string]any{
		"type": "wireguard", "tag": "wg-in", "address": []string{awgServerAddr},
		"private_key": serverPriv, "listen_port": serverPort, "mtu": 1280,
		"peers": []any{map[string]any{"public_key": clientPub, "allowed_ips": []string{"10.66.0.2/32"}}},
	}
	for k, v := range awgJSON {
		endpoint[k] = v
	}
	startP4SingBoxServer(t, dir, map[string]any{
		"log":       map[string]any{"level": "error"},
		"endpoints": []any{endpoint},
		"outbounds": []any{map[string]any{"type": "direct", "tag": "direct"}},
		"route":     map[string]any{"final": "direct"},
	})
	target := p4Target(t)
	mk := func(a *engine.AmneziaWG) *engine.Plan {
		return p4Plan(engine.Outbound{ID: "awg", Name: "awg", Protocol: engine.ProtocolWireGuard,
			Server: "127.0.0.1", Port: uint16(serverPort),
			PrivateKey: clientPriv, Addresses: []string{awgClientAddr}, Amnezia: a,
			Peers: []engine.WireGuardPeer{{PublicKey: serverPub,
				Endpoint: "127.0.0.1:" + strconv.Itoa(serverPort), AllowedIPs: []string{"0.0.0.0/0"}}}})
	}
	good := awg
	// sing-box-lx serves its own stack; mihomo's independent AWG
	// implementation reaching the same server is the cross-engine
	// proof the parameters are data, not a fork dialect.
	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindMihomo} {
		t.Run(string(kind), func(t *testing.T) {
			a := good
			body, err, center := driveP4ClientLogged(t, dir, kind, mk(&a), target)
			if err != nil {
				// SKIP only on an exact signature: the engine
				// log carries sendmmsg's EPERM, or this test
				// process's own sendmmsg probe was denied with
				// EPERM (sendmmsgDenied — mihomo reports the
				// blocked send only as a proxy 502, never as a
				// log line). Any other failure — including on a
				// host that happens to run under an unrelated
				// seccomp filter — is a real failure and must
				// stay red (CENSOR-P4 fix M1).
				if sandboxBlocksSendmmsg(center) || sendmmsgDenied() {
					t.Skipf("sandbox seccomp denies sendmmsg (wireguard-go cannot send): AWG traffic proof requires a dev machine; fetch failed with: %v", err)
				}
				t.Fatalf("AWG through %s: %v", kind, err)
			}
			if body != p4TargetReply {
				t.Fatalf("AWG through %s: got %q", kind, body)
			}
		})
	}
	// Negative controls: mismatched magic headers and plain
	// WireGuard must both fail the handshake against the AWG server.
	t.Run("mismatched-headers-fail", func(t *testing.T) {
		a := good
		a.H1 = "777000-777999"
		if _, err := driveP4Client(t, dir, engine.KindSingBox, mk(&a), target); err == nil {
			t.Fatal("mismatched AWG headers reached the target: obfuscation parameters are not on the wire")
		}
	})
	t.Run("plain-wireguard-fails", func(t *testing.T) {
		if _, err := driveP4Client(t, dir, engine.KindSingBox, mk(nil), target); err == nil {
			t.Fatal("plain WireGuard reached an AmneziaWG server")
		}
	})
}
