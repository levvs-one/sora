package xray

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func realityOutbound(id string) engine.Outbound {
	return engine.Outbound{
		ID: id, Protocol: engine.ProtocolVLESS,
		Server: "203.0.113.1", Port: 443,
		TLS: engine.TLS{Reality: true, ServerName: "example.com", RealityPublicKey: "public-key"},
	}
}

func timeoutErr() error {
	return &url.Error{Op: "dial", URL: "https://203.0.113.1", Err: context.DeadlineExceeded}
}

func TestFingerprintRotatable(t *testing.T) {
	cases := []struct {
		name string
		o    engine.Outbound
		want bool
	}{
		{"reality without fingerprint", realityOutbound("a"), true},
		{"reality with explicit fingerprint", func() engine.Outbound {
			o := realityOutbound("b")
			o.TLS.Fingerprint = "firefox"
			return o
		}(), false},
		{"reality with oddly-cased fingerprint", func() engine.Outbound {
			o := realityOutbound("c")
			o.TLS.Fingerprint = "Firefox"
			return o
		}(), false},
		{"plain tls without fingerprint", engine.Outbound{
			ID: "d", Protocol: engine.ProtocolVLESS, TLS: engine.TLS{Enabled: true},
		}, false},
		{"trojan without reality", engine.Outbound{
			ID: "e", Protocol: engine.ProtocolTrojan, Password: "x",
		}, false},
		{"shadowsocks", engine.Outbound{
			ID: "f", Protocol: engine.ProtocolShadowsocks, Password: "x", Cipher: "aes-256-gcm",
		}, false},
	}
	for _, tc := range cases {
		if got := fingerprintRotatable(tc.o); got != tc.want {
			t.Errorf("%s: fingerprintRotatable = %v, want %v", tc.name, got, tc.want)
		}
	}
}

func TestRetryFingerprint(t *testing.T) {
	if got := retryFingerprint(0); got != "" {
		t.Errorf("attempt 0 = %q, want empty (the renderer applies its default)", got)
	}
	if fingerprintRotation[0] != defaultXrayFingerprint {
		t.Errorf("rotation[0] = %q, want the canonical default %q", fingerprintRotation[0], defaultXrayFingerprint)
	}
	if got := retryFingerprint(1); got != "firefox" {
		t.Errorf("attempt 1 = %q, want %q", got, "firefox")
	}
	last := len(fingerprintRotation) - 1
	if got := retryFingerprint(last); got == "" || got == fingerprintRotation[0] {
		t.Errorf("attempt %d = %q, want a distinct fallback fingerprint", last, got)
	}
	for _, attempt := range []int{-1, len(fingerprintRotation), len(fingerprintRotation) + 5} {
		if got := retryFingerprint(attempt); got != "" {
			t.Errorf("attempt %d = %q, want empty (rotation exhausted)", attempt, got)
		}
	}
}

func TestIsTimeout(t *testing.T) {
	if !isTimeout(timeoutErr()) {
		t.Error("a url.Error wrapping a deadline must count as a timeout")
	}
	if !isTimeout(fmt.Errorf("probe: %w", timeoutErr())) {
		t.Error("a wrapped timeout must count as a timeout")
	}
	if isTimeout(errors.New("connection refused")) {
		t.Error("a refusal must not count as a timeout")
	}
	if isTimeout(nil) {
		t.Error("nil must not count as a timeout")
	}
}

func drainMeasurements(out chan engine.Measurement) []engine.Measurement {
	close(out)
	var ms []engine.Measurement
	for m := range out {
		ms = append(ms, m)
	}
	return ms
}

func TestMeasureRotatesFingerprintOnTimeout(t *testing.T) {
	o := realityOutbound("r1")
	var seen []string
	fake := func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions) ([]probeResult, error) {
		seen = append(seen, outbounds[0].TLS.Fingerprint)
		if len(seen) == 1 {
			return []probeResult{{err: timeoutErr()}}, nil
		}
		return []probeResult{{latency: 5 * time.Millisecond}}, nil
	}
	out := make(chan engine.Measurement, 4)
	hints, err := measure(context.Background(), supervise.Config{}, []engine.Outbound{o}, engine.MeasureOptions{}, out, fake)
	if err != nil {
		t.Fatal(err)
	}
	ms := drainMeasurements(out)
	if len(ms) != 1 {
		t.Fatalf("measurements = %d, want exactly one per outbound", len(ms))
	}
	if ms[0].Err != nil {
		t.Fatalf("the rotated retry must succeed, got %v", ms[0].Err)
	}
	if ms[0].OutboundID != "r1" || ms[0].Latency != 5*time.Millisecond {
		t.Fatalf("measurement = %+v, want the retried success", ms[0])
	}
	if len(seen) != 2 || seen[0] != "" || seen[1] != "firefox" {
		t.Fatalf("fingerprints tried = %q, want [\"\" \"firefox\"]", seen)
	}
	if hints["r1"] != "firefox" {
		t.Fatalf("hints = %v, want the working fingerprint for r1", hints)
	}
}

func TestMeasureDoesNotRetryNonTimeout(t *testing.T) {
	calls := 0
	fake := func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions) ([]probeResult, error) {
		calls++
		return []probeResult{{err: errors.New("connection refused")}}, nil
	}
	out := make(chan engine.Measurement, 4)
	hints, err := measure(context.Background(), supervise.Config{}, []engine.Outbound{realityOutbound("r1")}, engine.MeasureOptions{}, out, fake)
	if err != nil {
		t.Fatal(err)
	}
	ms := drainMeasurements(out)
	if calls != 1 {
		t.Fatalf("probe calls = %d, want 1 (no retry on non-timeout errors)", calls)
	}
	if len(ms) != 1 || ms[0].Err == nil {
		t.Fatalf("the refusal must be reported, got %+v", ms)
	}
	if len(hints) != 0 {
		t.Fatalf("hints = %v, want none on failure", hints)
	}
}

func TestMeasureDoesNotRetryExplicitFingerprint(t *testing.T) {
	o := realityOutbound("r2")
	o.TLS.Fingerprint = "chrome"
	calls := 0
	fake := func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions) ([]probeResult, error) {
		calls++
		return []probeResult{{err: timeoutErr()}}, nil
	}
	out := make(chan engine.Measurement, 4)
	_, err := measure(context.Background(), supervise.Config{}, []engine.Outbound{o}, engine.MeasureOptions{}, out, fake)
	if err != nil {
		t.Fatal(err)
	}
	ms := drainMeasurements(out)
	if calls != 1 {
		t.Fatalf("probe calls = %d, want 1 (explicit fingerprints are never rotated)", calls)
	}
	if len(ms) != 1 || ms[0].Err == nil {
		t.Fatalf("the timeout must be reported, got %+v", ms)
	}
}

func TestMeasureDoesNotRetryWithoutReality(t *testing.T) {
	o := engine.Outbound{ID: "s", Protocol: engine.ProtocolShadowsocks, Server: "203.0.113.1", Port: 8388, Password: "x", Cipher: "aes-256-gcm"}
	calls := 0
	fake := func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions) ([]probeResult, error) {
		calls++
		return []probeResult{{err: timeoutErr()}}, nil
	}
	out := make(chan engine.Measurement, 4)
	_, err := measure(context.Background(), supervise.Config{}, []engine.Outbound{o}, engine.MeasureOptions{}, out, fake)
	if err != nil {
		t.Fatal(err)
	}
	drainMeasurements(out)
	if calls != 1 {
		t.Fatalf("probe calls = %d, want 1 (nothing to rotate without REALITY)", calls)
	}
}

func TestMeasureExhaustsRotation(t *testing.T) {
	var seen []string
	fake := func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions) ([]probeResult, error) {
		seen = append(seen, outbounds[0].TLS.Fingerprint)
		return []probeResult{{err: timeoutErr()}}, nil
	}
	out := make(chan engine.Measurement, 4)
	hints, err := measure(context.Background(), supervise.Config{}, []engine.Outbound{realityOutbound("r1")}, engine.MeasureOptions{}, out, fake)
	if err != nil {
		t.Fatal(err)
	}
	ms := drainMeasurements(out)
	if len(seen) != len(fingerprintRotation) {
		t.Fatalf("attempts = %d, want the full rotation of %d", len(seen), len(fingerprintRotation))
	}
	if seen[0] != "" {
		t.Fatalf("first attempt must render the default, tried %q", seen[0])
	}
	for i := 1; i < len(seen); i++ {
		if seen[i] != fingerprintRotation[i] {
			t.Fatalf("attempt %d tried %q, want %q", i, seen[i], fingerprintRotation[i])
		}
	}
	if len(ms) != 1 || ms[0].Err == nil {
		t.Fatalf("an exhausted rotation must report the timeout, got %+v", ms)
	}
	if len(hints) != 0 {
		t.Fatalf("hints = %v, want none when every fingerprint timed out", hints)
	}
}

func TestMeasureReportsNoHintOnDefaultSuccess(t *testing.T) {
	fake := func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions) ([]probeResult, error) {
		if outbounds[0].TLS.Fingerprint != "" {
			t.Fatalf("first attempt must not set a fingerprint, got %q", outbounds[0].TLS.Fingerprint)
		}
		return []probeResult{{latency: time.Millisecond}}, nil
	}
	out := make(chan engine.Measurement, 4)
	hints, err := measure(context.Background(), supervise.Config{}, []engine.Outbound{realityOutbound("r1")}, engine.MeasureOptions{}, out, fake)
	if err != nil {
		t.Fatal(err)
	}
	ms := drainMeasurements(out)
	if len(ms) != 1 || ms[0].Err != nil {
		t.Fatalf("measurement = %+v, want success", ms)
	}
	if len(hints) != 0 {
		t.Fatalf("hints = %v, want none when the default fingerprint works", hints)
	}
}

func TestDriverRemembersFingerprintHint(t *testing.T) {
	d := &driver{}
	d.noteFingerprint("r1", "safari")
	if got := d.fingerprintHints()["r1"]; got != "safari" {
		t.Fatalf("hint = %q, want %q", got, "safari")
	}
	// Empty ids and fingerprints are ignored, never clobbering a hint.
	d.noteFingerprint("", "safari")
	d.noteFingerprint("r1", "")
	d.noteFingerprint("r2", "")
	if got := d.fingerprintHints()["r1"]; got != "safari" {
		t.Fatalf("hint after no-op notes = %q, want %q", got, "safari")
	}
	if _, ok := d.fingerprintHints()["r2"]; ok {
		t.Fatal("empty fingerprint must not create a hint")
	}
}

func TestWarnRealityWithoutVision(t *testing.T) {
	eng, err := New(supervise.Config{Binary: supervise.Binary{Path: "/bin/true"}, HomeDir: t.TempDir()})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = eng.Close() }()
	ch, unsub := eng.Events().Subscribe()
	defer unsub()
	p := &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "novision", Name: "No Vision", Protocol: engine.ProtocolVLESS, TLS: engine.TLS{Reality: true}},
		{ID: "vision", Protocol: engine.ProtocolVLESS, Flow: "xtls-rprx-vision", TLS: engine.TLS{Reality: true}},
		{ID: "plain", Protocol: engine.ProtocolVLESS, TLS: engine.TLS{Enabled: true}},
	}}
	eng.warnRealityWithoutVision(p)
	var msgs []string
drain:
	for {
		select {
		case ev := <-ch:
			if ev.Kind == engine.EventLog {
				msgs = append(msgs, ev.Message)
			}
		default:
			break drain
		}
	}
	if len(msgs) != 1 {
		t.Fatalf("warnings = %d, want exactly one: %q", len(msgs), msgs)
	}
	if !strings.Contains(msgs[0], "No Vision") || !strings.Contains(msgs[0], "vision") {
		t.Fatalf("warning %q must name the outbound and the missing vision flow", msgs[0])
	}

	// Nil plans and clean plans warn about nothing.
	eng.warnRealityWithoutVision(nil)
	eng.warnRealityWithoutVision(&engine.Plan{Outbounds: []engine.Outbound{
		{ID: "ok", Protocol: engine.ProtocolVLESS, Flow: "xtls-rprx-vision", TLS: engine.TLS{Reality: true}},
	}})
	select {
	case ev := <-ch:
		t.Fatalf("unexpected event after clean plans: %+v", ev)
	default:
	}
}
