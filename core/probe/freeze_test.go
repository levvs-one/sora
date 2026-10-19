package probe

// Tests for the SNI-freeze detector: the positive pattern (parallel stalls,
// sequential succeeds), the negatives that must NOT read as a freeze
// (dead endpoint, healthy path, single stall, fast reset, stale samples),
// the fingerprint rotation, and an end-to-end differential probe against a
// fake censor that stalls handshakes past 3 concurrent.

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"math/big"
	"net"
	"sync/atomic"
	"syscall"
	"testing"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func observeStalled(d *FreezeDetector, sni string, concurrent, n int) {
	for i := 0; i < n; i++ {
		d.Observe(FreezeSample{SNI: sni, Concurrent: concurrent, Stalled: true})
	}
}

func observeOK(d *FreezeDetector, sni string, concurrent, n int) {
	for i := 0; i < n; i++ {
		d.Observe(FreezeSample{SNI: sni, Concurrent: concurrent, Stalled: false})
	}
}

// TestFreezeDetectorDetectsPattern is the positive case: 3 parallel
// handshakes stall while 2 sequential ones succeed.
func TestFreezeDetectorDetectsPattern(t *testing.T) {
	d := &FreezeDetector{}
	observeStalled(d, "a.example", 6, 3)
	observeOK(d, "a.example", 1, 2)

	v := d.Verdict("a.example")
	if !v.Frozen {
		t.Fatalf("expected frozen, evidence: %v", v.Evidence)
	}
	if v.Confidence <= 0.35 || v.Confidence > freezeConfidenceCap {
		t.Fatalf("confidence %v outside the claimable band", v.Confidence)
	}
	if v.ParallelStalled != 3 || v.SequentialOK != 2 {
		t.Fatalf("counts wrong: %+v", v)
	}
	m := v.Mitigation("chrome")
	if m.NextFingerprint != "firefox" {
		t.Fatalf("expected fingerprint rotation chrome->firefox, got %q", m.NextFingerprint)
	}
	if !m.RotateSNI || m.CapParallelism != freezeParallelThreshold || m.Why == "" {
		t.Fatalf("mitigation incomplete: %+v", m)
	}
}

// TestFreezeDetectorDeadEndpoint is the key negative: when sequential
// handshakes stall too, the endpoint is dead or slow — not frozen.
func TestFreezeDetectorDeadEndpoint(t *testing.T) {
	d := &FreezeDetector{}
	observeStalled(d, "dead.example", 6, 3)
	observeStalled(d, "dead.example", 1, 2)

	v := d.Verdict("dead.example")
	if v.Frozen {
		t.Fatal("dead endpoint must not read as a freeze")
	}
	if v.Confidence != 0 {
		t.Fatalf("non-frozen verdict must carry zero confidence, got %v", v.Confidence)
	}
	if m := v.Mitigation("chrome"); m != (FreezeMitigation{}) {
		t.Fatalf("non-frozen verdict must yield zero mitigation, got %+v", m)
	}
}

// TestFreezeDetectorHealthy: parallel handshakes complete — no freeze.
func TestFreezeDetectorHealthy(t *testing.T) {
	d := &FreezeDetector{}
	observeOK(d, "ok.example", 6, 4)
	observeOK(d, "ok.example", 1, 1)

	if v := d.Verdict("ok.example"); v.Frozen {
		t.Fatal("healthy path must not read as a freeze")
	}
}

// TestFreezeDetectorNeedsCorroboration: one stalled parallel handshake is
// not a pattern.
func TestFreezeDetectorNeedsCorroboration(t *testing.T) {
	d := &FreezeDetector{}
	observeStalled(d, "thin.example", 6, 1)
	observeOK(d, "thin.example", 1, 1)

	if v := d.Verdict("thin.example"); v.Frozen {
		t.Fatal("a single stalled parallel handshake must not claim a freeze")
	}
}

// TestFreezeDetectorResetIsNotFreeze: fast resets are the SNI-blocking
// signature (censor package), never the freeze pattern.
func TestFreezeDetectorResetIsNotFreeze(t *testing.T) {
	d := &FreezeDetector{}
	reset := &net.OpError{Op: "read", Net: "tcp", Err: syscall.ECONNRESET}
	for i := 0; i < 3; i++ {
		d.ObserveFailure("rst.example", 6, reset, true)
	}
	observeOK(d, "rst.example", 1, 2)

	if v := d.Verdict("rst.example"); v.Frozen {
		t.Fatalf("resets must not read as a freeze, evidence: %v", v.Evidence)
	}
}

// TestFreezeDetectorStaleSamplesIgnored: samples older than the TTL stop
// counting, so a verdict always reflects recent path behavior.
func TestFreezeDetectorStaleSamplesIgnored(t *testing.T) {
	now := time.Now()
	d := &FreezeDetector{Now: func() time.Time { return now }}
	old := now.Add(-freezeSampleTTL - time.Minute)
	for i := 0; i < 3; i++ {
		d.Observe(FreezeSample{SNI: "old.example", Concurrent: 6, Stalled: true, At: old})
	}
	for i := 0; i < 2; i++ {
		d.Observe(FreezeSample{SNI: "old.example", Concurrent: 1, Stalled: false, At: old})
	}
	if v := d.Verdict("old.example"); v.Frozen {
		t.Fatal("stale samples must not produce a freeze verdict")
	}
}

// TestRotateFingerprint checks the auto-switch order.
func TestRotateFingerprint(t *testing.T) {
	cases := map[string]string{
		"chrome":  "firefox",
		"firefox": "safari",
		"android": "chrome", // wraps around
		"Chrome":  "firefox",
		"":        "firefox", // unknown/empty switches away from the default
		"bogus":   "firefox",
		"random":  "firefox", // random is not a rotation pick
	}
	for in, want := range cases {
		if got := RotateFingerprint(in); got != want {
			t.Fatalf("RotateFingerprint(%q) = %q, want %q", in, got, want)
		}
	}
	// Full cycle returns to the start without repeats.
	seen := map[string]bool{}
	cur := "chrome"
	for i := 0; i < len(freezeFingerprintRotation); i++ {
		if seen[cur] {
			t.Fatalf("rotation repeated %q", cur)
		}
		seen[cur] = true
		cur = RotateFingerprint(cur)
	}
	if cur != "chrome" {
		t.Fatalf("rotation did not cycle, ended at %q", cur)
	}
}

// TestFreezeDetectorOnFreezeCooldown: the hook fires once per cooldown even
// while the freeze persists.
func TestFreezeDetectorOnFreezeCooldown(t *testing.T) {
	now := time.Now()
	var fires atomic.Int32
	d := &FreezeDetector{
		Now:      func() time.Time { return now },
		Cooldown: time.Hour,
		OnFreeze: func(FreezeVerdict) { fires.Add(1) },
	}
	observeStalled(d, "c.example", 6, 2)
	observeOK(d, "c.example", 1, 1)
	if fires.Load() != 1 {
		t.Fatalf("expected one OnFreeze fire, got %d", fires.Load())
	}
	// More of the same inside the cooldown: no refire.
	observeStalled(d, "c.example", 6, 2)
	if fires.Load() != 1 {
		t.Fatalf("cooldown violated: %d fires", fires.Load())
	}
	// After the cooldown a fresh pattern may fire again. (Old samples
	// expired with the TTL, so the pattern needs fresh observations.)
	now = now.Add(2 * time.Hour)
	observeStalled(d, "c.example", 6, 2)
	observeOK(d, "c.example", 1, 1)
	if fires.Load() != 2 {
		t.Fatalf("expected refire after cooldown, got %d", fires.Load())
	}
}

// censorHarness is a fake censor: it completes TLS handshakes quickly while
// at most stallAfter are in flight, and stalls (never answers) beyond that.
type censorHarness struct {
	t          *testing.T
	ln         net.Listener
	cert       tls.Certificate
	stallAfter int
	stallFor   time.Duration
	inflight   atomic.Int32
	closed     atomic.Bool
}

func newCensorHarness(t *testing.T, stallAfter int, stallFor time.Duration, dnsNames ...string) *censorHarness {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	tmpl := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{CommonName: "freeze.test"},
		DNSNames:     dnsNames,
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(time.Hour),
	}
	der, err := x509.CreateCertificate(rand.Reader, tmpl, tmpl, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	h := &censorHarness{t: t, ln: ln, stallAfter: stallAfter, stallFor: stallFor,
		cert: tls.Certificate{Certificate: [][]byte{der}, PrivateKey: key}}
	t.Cleanup(h.close)
	go h.serve()
	return h
}

func (h *censorHarness) addr() (string, uint32) {
	a := h.ln.Addr().(*net.TCPAddr)
	return "127.0.0.1", uint32(a.Port)
}

func (h *censorHarness) close() {
	h.closed.Store(true)
	_ = h.ln.Close()
}

func (h *censorHarness) serve() {
	for {
		conn, err := h.ln.Accept()
		if err != nil {
			return
		}
		go h.handle(conn)
	}
}

func (h *censorHarness) handle(conn net.Conn) {
	n := h.inflight.Add(1)
	defer h.inflight.Add(-1)
	defer func() { _ = conn.Close() }()
	if int(n) > h.stallAfter {
		// The freeze: never answer the handshake.
		time.Sleep(h.stallFor)
		return
	}
	tlsConn := tls.Server(conn, &tls.Config{Certificates: []tls.Certificate{h.cert}})
	_ = tlsConn.SetDeadline(time.Now().Add(5 * time.Second))
	_ = tlsConn.Handshake()
}

// TestProbeFreezeDetectsCensor runs the full differential probe against the
// fake censor: sequential handshakes pass, the parallel burst stalls.
func TestProbeFreezeDetectsCensor(t *testing.T) {
	h := newCensorHarness(t, 3, 30*time.Second)
	host, port := h.addr()

	p := &FreezeProber{Timeout: 1500 * time.Millisecond}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	v, err := p.ProbeFreeze(ctx, host, port, "victim.example",
		FreezeProbeOptions{Sequential: 2, Parallel: 6, Timeout: 1500 * time.Millisecond})
	if err != nil {
		t.Fatal(err)
	}
	if !v.Frozen {
		t.Fatalf("expected frozen against the stalling censor, evidence: %v", v.Evidence)
	}
	if v.SNI != "victim.example" {
		t.Fatalf("verdict SNI = %q", v.SNI)
	}
	m := v.Mitigation("chrome")
	if m.NextFingerprint == "" || !m.RotateSNI || m.CapParallelism != 3 {
		t.Fatalf("mitigation missing: %+v", m)
	}
}

// TestProbeFreezeHealthyServer: a server that answers every handshake is
// not a freeze, however parallel the burst.
func TestProbeFreezeHealthyServer(t *testing.T) {
	h := newCensorHarness(t, 1<<30, 0) // never stalls
	host, port := h.addr()

	p := &FreezeProber{Timeout: 1500 * time.Millisecond}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	v, err := p.ProbeFreeze(ctx, host, port, "healthy.example",
		FreezeProbeOptions{Sequential: 2, Parallel: 6, Timeout: 1500 * time.Millisecond})
	if err != nil {
		t.Fatal(err)
	}
	if v.Frozen {
		t.Fatalf("healthy server must not read as frozen: %+v", v)
	}
}

// TestProbeFreezeValidation rejects bad targets and useless bursts.
func TestProbeFreezeValidation(t *testing.T) {
	p := &FreezeProber{}
	ctx := context.Background()
	if _, err := p.ProbeFreeze(ctx, "", 443, "x.example", FreezeProbeOptions{}); err == nil {
		t.Fatal("empty host must be rejected")
	}
	if _, err := p.ProbeFreeze(ctx, "127.0.0.1", 0, "x.example", FreezeProbeOptions{}); err == nil {
		t.Fatal("zero port must be rejected")
	}
	// A burst of 3 does not exceed the threshold: the test could not
	// exercise the pattern.
	if _, err := p.ProbeFreeze(ctx, "127.0.0.1", 443, "x.example",
		FreezeProbeOptions{Parallel: 3}); err == nil {
		t.Fatal("parallel burst at/below the threshold must be rejected")
	}
}

// TestProberFeedsFreezeDetector: the passive path. One Probe call fans 6
// parallel TLS dials at the stalling censor under a shared SNI; the dial
// hook must record them as stalled parallel samples with the right
// in-flight count. The sequential-success leg goes through the same
// freezeEnd wiring the dial uses: a full end-to-end success is not
// testable here because the prober verifies certificates against the
// system roots (by design) and a test CA is not trusted.
func TestProberFeedsFreezeDetector(t *testing.T) {
	// stallAfter=0: every handshake stalls, so every dial exercises the
	// hook's stall path through the real network stack.
	stall := newCensorHarness(t, 0, 30*time.Second, "shared.example")
	_, stallPort := stall.addr()

	d := &FreezeDetector{}
	p := New(Config{
		Timeout:     1500 * time.Millisecond,
		Concurrency: 8,
		TLS:         true,
		ServerName:  "shared.example",
	})
	p.SetFreezeDetector(d)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	burst := make([]*corev1.Endpoint, 6)
	for i := range burst {
		burst[i] = &corev1.Endpoint{Host: "127.0.0.1", Port: stallPort}
	}
	if _, err := drainProbe(ctx, p, burst); err != nil {
		t.Fatal(err)
	}
	// All 6 dials ran under one SNI: the hook must have recorded every
	// one, and the overlapping dials must show up as parallel. (The
	// ramp-up dials see lower in-flight counts — honest behavior, also
	// present in production.)
	v := d.Verdict("shared.example")
	if v.ParallelTotal+v.SequentialTotal != 6 {
		t.Fatalf("dial hook did not record the burst: %+v", v)
	}
	if v.ParallelStalled < 2 {
		t.Fatalf("expected overlapping dials to count as parallel: %+v", v)
	}
	// Sequential success through the same wiring the dial uses on err==nil.
	// (A full end-to-end success is not testable here: the prober verifies
	// certificates against the system roots by design, and a test CA is
	// not trusted.)
	p.freezeEnd(d, "shared.example", 1, nil)

	v = d.Verdict("shared.example")
	if !v.Frozen {
		t.Fatalf("expected frozen from passive prober observations, evidence: %v", v.Evidence)
	}
}

func drainProbe(ctx context.Context, p *Prober, endpoints []*corev1.Endpoint) ([]*corev1.ProbeResult, error) {
	ch, err := p.Probe(ctx, endpoints, nil)
	if err != nil {
		return nil, err
	}
	var out []*corev1.ProbeResult
	for r := range ch {
		out = append(out, r)
	}
	return out, nil
}

// TestProberWithoutDetectorUnaffected: with no detector attached the TLS
// dial path behaves exactly as before the freeze hooks existed. The test
// server's self-signed certificate fails system-root verification, so the
// prober must report the certificate error — and nothing else.
func TestProberWithoutDetectorUnaffected(t *testing.T) {
	healthy := newCensorHarness(t, 1<<30, 0, "x.example")
	_, port := healthy.addr()
	p := New(Config{Timeout: 5 * time.Second, TLS: true, ServerName: "x.example"})
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	results, err := drainProbe(ctx, p, []*corev1.Endpoint{{Host: "127.0.0.1", Port: port}})
	if err != nil {
		t.Fatal(err)
	}
	if len(results) != 1 {
		t.Fatalf("expected one result, got %+v", results)
	}
	r := results[0]
	if r.Reachable || r.Error == nil || r.Error.UserMessageKey != "core.tls.certificate" {
		t.Fatalf("expected a certificate failure, got %+v", r)
	}
}

// TestObserveFailureIgnoresCancellation checks that a cancelled dial is
// not recorded as a stall: cancellation carries no signal about the
// network (someone stopped waiting), and connection racing cancels
// losers routinely, so recording them would poison the detector with
// false freeze evidence on every race.
func TestObserveFailureIgnoresCancellation(t *testing.T) {
	d := &FreezeDetector{}
	d.ObserveFailure("a.example", 6, context.Canceled, true)
	d.ObserveFailure("a.example", 6, context.Canceled, false)
	v := d.Verdict("a.example")
	if v.Frozen {
		t.Fatalf("cancelled attempts must not freeze a verdict, evidence: %v", v.Evidence)
	}
	if v.ParallelTotal != 0 || v.ParallelStalled != 0 {
		t.Fatalf("cancelled attempts recorded samples: %+v", v)
	}
	// A genuine timeout still records a stall.
	d.ObserveFailure("a.example", 6, context.DeadlineExceeded, true)
	v = d.Verdict("a.example")
	if v.ParallelStalled != 1 {
		t.Fatalf("deadline-exceeded attempts must still record stalls: %+v", v)
	}
}
