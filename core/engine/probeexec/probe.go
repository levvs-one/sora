// Package probeexec measures an installed engine binary's REAL
// fingerprint capabilities (CENSOR-FP, strengthened mandate: pin =
// expectation, probe = fact).
//
// For each engine it renders probe plans with sora's own renderers,
// starts the binary on loopback, pushes a SOCKS connection through
// the rendered mixed inbound toward a local capture listener, and
// reads the ClientHello the binary actually emits. ECH is a fact
// when the captured outer SNI is the ECHConfigList's public_name;
// the key-share knob is a fact when classical/hybrid change the
// captured key_share groups; a fingerprint spelling is a fact when
// a hello arrives wearing it. Config checks alone are never trusted
// (Xray's loader accepts a garbage echConfigList; only the wire
// tells).
package probeexec

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/mihomo"
	"github.com/levvs-one/sora-client/core/engine/singbox"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
)

// RealityTestPublicKey is a valid X25519 public key generated for
// probing (a REALITY server key's public half is not a secret; the
// all-zero key is rejected by engines as a low-order point).
const RealityTestPublicKey = "xOSCQjWQt1MYcsmMlM7_0j61pRYh_gYu1PTA6YUE0y0"

// ECHTestList is the pinned ECHConfigList fixture (public_name
// "public.example.com") whose wire effect the probe looks for.
var ECHTestList = []string{
	"-----BEGIN ECH CONFIGS-----",
	"AEX+DQBBBwAgACAAAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHwAEAAEAAQAScHVibGlj",
	"LmV4YW1wbGUuY29tAAA=",
	"-----END ECH CONFIGS-----",
}

// ECHTestPublicName is the public_name inside ECHTestList.
const ECHTestPublicName = "public.example.com"

// ProbeTarget is the SNI the probe plans claim before ECH rewrites it.
const probeSNI = "example.com"

// Runner probes the engine binaries in Dir.
type Runner struct {
	Dir string
	// CaptureTimeout bounds one engine start + capture.
	CaptureTimeout time.Duration
}

func (r Runner) timeout() time.Duration {
	if r.CaptureTimeout > 0 {
		return r.CaptureTimeout
	}
	return 10 * time.Second
}

func (r Runner) binary(kind engine.Kind) string {
	return filepath.Join(r.Dir, string(kind))
}

// ConfigCheck runs the binary's own config validation over a
// rendered config. It is a NECESSARY signal, never a sufficient one:
// Xray accepts an unparseable echConfigList here (probed).
func (r Runner) ConfigCheck(kind engine.Kind, rendered []byte) error {
	home, err := os.MkdirTemp("", "sora-probe-home-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(home)
	var args []string
	switch kind {
	case engine.KindSingBox:
		args = []string{"check", "-c", "stdin", "-D", home, "--disable-color"}
	case engine.KindMihomo:
		args = []string{"-d", home, "-f", "-", "-t"}
	case engine.KindXray:
		args = []string{"run", "-test", "-c", "stdin:"}
	default:
		return fmt.Errorf("probeexec: unknown engine kind %q", kind)
	}
	ctx, cancel := context.WithTimeout(context.Background(), r.timeout())
	defer cancel()
	cmd := exec.CommandContext(ctx, r.binary(kind), args...)
	cmd.Stdin = bytes.NewReader(rendered)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("probeexec: %s config check: %w (%s)", kind, err, trimOut(out))
	}
	return nil
}

// Probe measures one engine binary and returns the fact record the
// capability overlay (engine.EngineProbe) consumes. A missing binary
// is an error; every measurement failure degrades to a Rejected
// verdict with the reason in Notes, never to a silent Unknown where
// a measurement was attempted.
func (r Runner) Probe(ctx context.Context, kind engine.Kind) (*engine.EngineProbe, error) {
	bin := r.binary(kind)
	if _, err := os.Stat(bin); err != nil {
		return nil, fmt.Errorf("probeexec: %s binary: %w", kind, err)
	}
	pr := &engine.EngineProbe{
		At:           time.Now(),
		Method:       "probeexec: renderer config check + SOCKS-through wire capture of the real ClientHello (ECH by outer SNI, key share by key_share groups, spelling by hello arrival)",
		Fingerprints: map[string]engine.ProbeVerdict{},
		JA4:          map[string]string{},
		PQKeyShare:   map[string]bool{},
	}
	// ECH: pinned list, TLS plan. The fact is the outer SNI.
	if facts, err := r.capture(ctx, kind, echPlan()); err == nil && facts.SNI == ECHTestPublicName {
		pr.ECH = engine.ProbeAccepted
		pr.Notes = append(pr.Notes, fmt.Sprintf("ECH: outer SNI became %q (hello %d bytes)", facts.SNI, facts.Length))
	} else {
		pr.ECH = engine.ProbeRejected
		pr.Notes = append(pr.Notes, fmt.Sprintf("ECH: no ECH hello captured (%v)", err))
	}
	// KeyShare: classical must drop the hybrid group, hybrid must
	// carry it, both must render and dial.
	classical, errC := r.capture(ctx, kind, realityPlan("chrome", "classical"))
	hybrid, errH := r.capture(ctx, kind, realityPlan("chrome", "hybrid"))
	switch {
	case errC != nil:
		pr.KeyShare = engine.ProbeRejected
		pr.Notes = append(pr.Notes, fmt.Sprintf("key share: classical capture failed (%v)", errC))
	case errH != nil:
		pr.KeyShare = engine.ProbeRejected
		pr.Notes = append(pr.Notes, fmt.Sprintf("key share: hybrid capture failed (%v)", errH))
	case classical.PQKeyShare:
		pr.KeyShare = engine.ProbeRejected
		pr.Notes = append(pr.Notes, "key share: 'classical' still offered the hybrid group — the knob is ignored")
	case !hybrid.PQKeyShare:
		pr.KeyShare = engine.ProbeRejected
		pr.Notes = append(pr.Notes, "key share: 'hybrid' offered no hybrid group — the knob is ignored")
	default:
		pr.KeyShare = engine.ProbeAccepted
		pr.Notes = append(pr.Notes, "key share: classical/hybrid change the captured key_share groups as pinned")
	}
	// Fingerprint spellings: a hello wearing the name is the fact.
	for _, name := range []string{"hellochrome_auto", "chrome", "firefox", "safari", "edge", "ios", "qq", "randomized", "hellochrome_133", "hellochrome_155"} {
		facts, err := r.capture(ctx, kind, realityPlan(name, ""))
		if err != nil {
			pr.Fingerprints[name] = engine.ProbeRejected
			continue
		}
		pr.Fingerprints[name] = engine.ProbeAccepted
		pr.JA4[name] = facts.JA4
		pr.PQKeyShare[name] = facts.PQKeyShare
	}
	// Spelling honesty: a versioned parrot name accepted on a
	// non-Xray engine arrived via the renderer's degradation to the
	// browser alias (sing-box refuses the raw name at load). The
	// tell is the JA4: identical to the alias's JA4, different from
	// what the name claims. Record it — a plan pinning the version
	// is still gated by engine.ProbeMissing's spelling check; the
	// probe's job is to make the substitution visible, not silent.
	for _, name := range []string{"hellochrome_133", "hellochrome_155"} {
		if pr.Fingerprints[name] != engine.ProbeAccepted || kind == engine.KindXray {
			continue
		}
		if alias := "chrome"; pr.JA4[name] != "" && pr.JA4[name] == pr.JA4[alias] {
			pr.Notes = append(pr.Notes, fmt.Sprintf("fingerprint %s: hello arrived wearing the %q alias (JA4 %s) — renderer degradation, not native support", name, alias, pr.JA4[name]))
		}
	}
	// Determinism (мелочи): the default spelling captured twice must
	// be the same shape; byte differences are allowed only where the
	// protocol itself varies (GREASE, random, key bytes, permutation).
	if a, err1 := r.capture(ctx, kind, realityPlan("chrome", "")); err1 == nil {
		if b, err2 := r.capture(ctx, kind, realityPlan("chrome", "")); err2 == nil {
			if diagnostics.SameShape(a, b) {
				pr.Notes = append(pr.Notes, fmt.Sprintf("determinism: two 'chrome' captures share JA4 %s (lengths %d/%d, padding %d/%d)", a.JA4, a.Length, b.Length, a.PaddingLen, b.PaddingLen))
			} else {
				pr.Notes = append(pr.Notes, fmt.Sprintf("determinism: two 'chrome' captures DIFFER in shape (JA4 %s vs %s)", a.JA4, b.JA4))
			}
		}
	}
	return pr, nil
}

func trimOut(b []byte) string {
	s := string(b)
	if len(s) > 300 {
		s = s[len(s)-300:]
	}
	return s
}

// --- plans ------------------------------------------------------------

func basePlan() *engine.Plan {
	return &engine.Plan{
		SessionID:  "probeexec",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Options:    engine.Options{LogLevel: "warning", Mode: "rule"},
		DNS: engine.DNS{Enabled: true, Servers: []engine.DNSServer{
			{Tag: "local", Transport: engine.DNSSystem, Address: "system"},
		}},
		Groups: []engine.Group{{Name: "Proxy", Type: engine.GroupSelect, Outbounds: []string{"probe"}}},
		Rules:  []engine.Rule{{Type: engine.RuleMatchAll, Target: "Proxy"}},
	}
}

func realityPlan(fingerprint, keyShare string) *engine.Plan {
	p := basePlan()
	p.Outbounds = []engine.Outbound{{
		ID: "probe", Protocol: engine.ProtocolVLESS, Server: "127.0.0.1",
		UUID: "11111111-1111-1111-1111-111111111111",
		TLS: engine.TLS{
			Enabled: true, Reality: true, ServerName: probeSNI,
			RealityPublicKey: RealityTestPublicKey,
			Fingerprint:      fingerprint, KeyShare: keyShare,
		},
	}}
	return p
}

func echPlan() *engine.Plan {
	p := basePlan()
	p.Outbounds = []engine.Outbound{{
		ID: "probe", Protocol: engine.ProtocolVLESS, Server: "127.0.0.1",
		UUID: "11111111-1111-1111-1111-111111111111",
		TLS: engine.TLS{
			Enabled: true, ServerName: probeSNI, Fingerprint: "chrome",
			ECH: engine.ECHConfig{Enabled: true, Config: ECHTestList},
		},
	}}
	return p
}

// --- capture ----------------------------------------------------------

// capture renders the plan for kind, starts the binary, SOCKS-connects
// through its mixed inbound to a local listener standing in for the
// plan's server, and returns the byte facts of the ClientHello the
// binary emitted. The plan's outbound port is rewritten to the
// listener's port.
func (r Runner) capture(ctx context.Context, kind engine.Kind, p *engine.Plan) (diagnostics.HelloFacts, error) {
	var zero diagnostics.HelloFacts
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return zero, err
	}
	defer ln.Close()
	targetPort := ln.Addr().(*net.TCPAddr).Port
	p.Outbounds[0].Port = uint16(targetPort)
	socksLn, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return zero, err
	}
	socksPort := socksLn.Addr().(*net.TCPAddr).Port
	socksLn.Close()

	home, err := os.MkdirTemp("", "sora-probe-home-")
	if err != nil {
		return zero, err
	}
	defer os.RemoveAll(home)
	rt := supervise.Runtime{HomeDir: home, LocalPort: socksPort, LocalProxy: true,
		ControlAddr: "127.0.0.1:0", Secret: "probeexec", ProbeURL: "http://127.0.0.1/"}
	var rendered []byte
	var args []string
	switch kind {
	case engine.KindSingBox:
		rendered, err = singbox.Render(p, rt)
		args = []string{"run", "-c", "stdin", "-D", home, "--disable-color"}
	case engine.KindMihomo:
		ctl := freeAddr()
		var text string
		text, err = mihomo.Render(p, mihomo.Runtime{HomeDir: home, ControllerAddr: ctl, Secret: "probeexec", MixedPort: socksPort, TestURL: "http://127.0.0.1/"})
		rendered = []byte(text)
		args = []string{"-d", home, "-f", "-", "-ext-ctl", ctl}
	case engine.KindXray:
		rendered, err = xray.Render(p, rt, nil)
		args = []string{"run", "-c", "stdin:"}
	default:
		return zero, fmt.Errorf("probeexec: unknown engine kind %q", kind)
	}
	if err != nil {
		return zero, fmt.Errorf("probeexec: %s render: %w", kind, err)
	}
	if err := r.ConfigCheck(kind, rendered); err != nil {
		return zero, err
	}
	cctx, cancel := context.WithTimeout(ctx, r.timeout())
	defer cancel()
	cmd := exec.CommandContext(cctx, r.binary(kind), args...)
	cmd.Stdin = bytes.NewReader(rendered)
	var logBuf bytes.Buffer
	cmd.Stdout, cmd.Stderr = &logBuf, &logBuf
	if err := cmd.Start(); err != nil {
		return zero, err
	}
	defer func() {
		cmd.Process.Kill()
		cmd.Wait()
	}()
	// Wait for the mixed inbound.
	deadline := time.Now().Add(r.timeout())
	for {
		c, derr := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", socksPort), 250*time.Millisecond)
		if derr == nil {
			c.Close()
			break
		}
		if time.Now().After(deadline) {
			return zero, fmt.Errorf("probeexec: %s did not open its mixed inbound: %s", kind, trimOut(logBuf.Bytes()))
		}
		select {
		case <-cctx.Done():
			return zero, cctx.Err()
		case <-time.After(50 * time.Millisecond):
		}
	}
	helloCh := make(chan []byte, 1)
	go func() {
		c, aerr := ln.Accept()
		if aerr != nil {
			helloCh <- nil
			return
		}
		defer c.Close()
		// Accumulate until a full first record is buffered or the
		// deadline passes: an engine may flush its protocol header
		// and the ClientHello in separate segments.
		var raw []byte
		buf := make([]byte, 65536)
		for {
			c.SetReadDeadline(time.Now().Add(r.timeout()))
			n, rerr := c.Read(buf)
			raw = append(raw, buf[:n]...)
			if rerr != nil || len(raw) >= 5 {
				break
			}
		}
		helloCh <- raw
	}()
	// Push SOCKS attempts until the hello lands or the capture
	// budget ends. Two measured engine behaviours shape this loop:
	// an engine tears the outbound down when the client connection
	// closes early, so each attempt's connection stays OPEN while
	// its hello is awaited; and a CONNECT issued in the window
	// between the mixed listener's bind and the tunnel subsystem's
	// readiness is answered but silently dropped (measured on
	// mihomo: SOCKS success reply, no connection, no hello), so a
	// dropped attempt is retried on a fresh connection instead of
	// being mistaken for an engine refusal.
	for {
		conn, err := socksConnect(socksPort, targetPort)
		if err != nil {
			return zero, fmt.Errorf("probeexec: socks through %s: %w", kind, err)
		}
		select {
		case raw := <-helloCh:
			conn.Close()
			if len(raw) == 0 {
				return zero, fmt.Errorf("probeexec: %s emitted no ClientHello", kind)
			}
			return diagnostics.AnalyzeHello(raw)
		case <-time.After(3 * time.Second):
			conn.Close() // dropped attempt: retry on a fresh connection
		case <-cctx.Done():
			conn.Close()
			return zero, fmt.Errorf("probeexec: %s capture timeout: %s", kind, trimOut(logBuf.Bytes()))
		}
		select {
		case raw := <-helloCh:
			if len(raw) == 0 {
				return zero, fmt.Errorf("probeexec: %s emitted no ClientHello", kind)
			}
			return diagnostics.AnalyzeHello(raw)
		case <-cctx.Done():
			return zero, fmt.Errorf("probeexec: %s capture timeout: %s", kind, trimOut(logBuf.Bytes()))
		default:
		}
	}
}

func freeAddr() string {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return "127.0.0.1:0"
	}
	defer ln.Close()
	return ln.Addr().String()
}

// socksConnect performs a minimal SOCKS5 no-auth CONNECT to
// 127.0.0.1:targetPort through the proxy at 127.0.0.1:port and
// returns the OPEN connection: the caller holds it for the whole
// capture (see the capture comment — an early close aborts the
// engine's handshake). Reply errors are tolerated: the ClientHello
// is emitted before the proxy reports the (expected) failure of
// the fake server leg.
func socksConnect(port, targetPort int) (net.Conn, error) {
	c, err := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", port), 3*time.Second)
	if err != nil {
		return nil, err
	}
	c.SetDeadline(time.Now().Add(5 * time.Second))
	if _, err := c.Write([]byte{5, 1, 0}); err != nil {
		c.Close()
		return nil, err
	}
	buf := make([]byte, 262)
	if _, err := io.ReadFull(c, buf[:2]); err != nil {
		c.Close()
		return nil, err
	}
	req := []byte{5, 1, 0, 1, 127, 0, 0, 1, byte(targetPort >> 8), byte(targetPort)}
	if _, err := c.Write(req); err != nil {
		c.Close()
		return nil, err
	}
	_, _ = io.ReadFull(c, buf[:10])
	return c, nil
}
