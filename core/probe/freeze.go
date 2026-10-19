package probe

// SNI-freeze detection: the "parallel handshake stall" pattern.
//
// Signature: several parallel TLS handshakes to the same SNI stall (never
// complete within the deadline) while sequential handshakes to the same SNI
// succeed. This is not SNI blocking: a censor that blocks an SNI outright
// answers with RST right after the ClientHello (SignatureReset, handled by
// the censor package's SNI-blocking rule). A freezer lets the SNI through
// but throttles concurrency — connections stall once more than a few
// handshakes share one SNI.
//
// The differential test (parallel vs sequential) is what separates a freeze
// from a dead endpoint: a dead or slow endpoint stalls sequential
// handshakes too, so the detector refuses to claim a freeze without at
// least one sequential success for the same SNI. Sparse input yields
// Frozen=false with an explanation, never a guess — the same discipline as
// the censor package (uncertain verdicts read as uncertainty).
//
// Two ways to feed the detector:
//   - Passive: attach it to a Prober with SetFreezeDetector. Every TLS dial
//     the prober runs is observed with its per-SNI in-flight count.
//   - Active: FreezeProber.ProbeFreeze runs the differential test on
//     demand: a few sequential handshakes, then one parallel burst.
//
// When a freeze is confirmed the verdict carries the automatic mitigation:
// rotate the uTLS fingerprint, rotate the SNI, and cap handshake parallelism
// at the observed ceiling. Applying the mitigation to the session plan is
// the control plane's job; the detector only names the switch, and the
// OnFreeze hook fires (rate-limited) so the control plane can act.

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"net"
	"strconv"
	"sync"
	"time"
)

// Freeze-detection tuning. The parallel threshold mirrors the observed
// censor behavior: freezes begin above ~3 concurrent handshakes per SNI.
const (
	// freezeParallelThreshold: samples with Concurrent above this count as
	// parallel handshakes sharing one SNI.
	freezeParallelThreshold = 3
	// freezeMinStalled: stalled parallel samples needed to claim a freeze.
	freezeMinStalled = 2
	// freezeMinSequentialOK: successful sequential samples needed to rule
	// out a dead endpoint.
	freezeMinSequentialOK = 1
	// freezeSampleTTL: samples older than this stop counting, so a freeze
	// verdict always reflects recent path behavior.
	freezeSampleTTL = 30 * time.Minute
	// freezeMaxSamples bounds per-SNI memory.
	freezeMaxSamples = 128
	// freezeConfidenceCap: one detector never claims certainty alone.
	freezeConfidenceCap = 0.85
	// freezeCooldownDefault: minimum interval between OnFreeze firings for
	// one SNI, so a persistent freeze does not flap the mitigation.
	freezeCooldownDefault = 15 * time.Minute
)

// freezeFingerprintRotation is the auto-switch order for the uTLS
// fingerprint when a freeze fires: common browser parrots only. "random" is
// excluded — a random pick can land back on the throttled fingerprint —
// and so are the region-specific "360"/"qq".
var freezeFingerprintRotation = []string{"chrome", "firefox", "safari", "edge", "ios", "android"}

// RotateFingerprint returns the next fingerprint after current in the
// freeze-mitigation rotation, wrapping around. Names are matched
// case-insensitively; an empty or unknown current yields "firefox" —
// deliberately different from engine.DefaultFingerprint ("chrome") so the
// switch is real even when the caller had no fingerprint configured.
func RotateFingerprint(current string) string {
	norm := ""
	for _, r := range freezeFingerprintRotation {
		if equalFoldASCII(r, current) {
			norm = r
			break
		}
	}
	if norm == "" {
		return "firefox"
	}
	for i, r := range freezeFingerprintRotation {
		if r == norm {
			return freezeFingerprintRotation[(i+1)%len(freezeFingerprintRotation)]
		}
	}
	return "firefox" // unreachable; kept for totality
}

func equalFoldASCII(a, b string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := 0; i < len(a); i++ {
		ca, cb := a[i], b[i]
		if 'A' <= ca && ca <= 'Z' {
			ca += 'a' - 'A'
		}
		if 'A' <= cb && cb <= 'Z' {
			cb += 'a' - 'A'
		}
		if ca != cb {
			return false
		}
	}
	return true
}

// FreezeSample is one observed TLS handshake outcome.
type FreezeSample struct {
	// SNI is the server name the handshake was sent with.
	SNI string
	// Concurrent is how many handshakes to the same SNI were in flight
	// when this one ran. 1 means sequential; values below 1 are treated
	// as 1.
	Concurrent int
	// Stalled is true when the handshake never completed within the
	// deadline. Stalled=false means the handshake completed: fast
	// failures (reset, alert, certificate) are never recorded, because a
	// failed handshake is not a successful one and carries no freeze
	// signal either way.
	Stalled bool
	// At is the observation time; zero means now.
	At time.Time
}

// FreezeVerdict is the detector's reading for one SNI.
type FreezeVerdict struct {
	SNI string
	// Frozen is true only when the differential pattern held: parallel
	// handshakes stalled while sequential ones succeeded.
	Frozen bool
	// Confidence is in [0, 1] when Frozen, 0 otherwise.
	Confidence float64
	// SequentialOK/SequentialTotal count successful/total sequential
	// samples; ParallelStalled/ParallelTotal the parallel ones.
	SequentialOK, SequentialTotal  int
	ParallelStalled, ParallelTotal int
	Evidence                       []string
}

// Mitigation names the automatic response to a confirmed freeze. The zero
// value means "no action": it is only meaningful when the verdict is
// Frozen.
func (v FreezeVerdict) Mitigation(currentFingerprint string) FreezeMitigation {
	if !v.Frozen {
		return FreezeMitigation{}
	}
	return FreezeMitigation{
		NextFingerprint: RotateFingerprint(currentFingerprint),
		// The SNI itself is the throttle key: stop reusing it. The caller
		// picks the alternate (subscription alternate SNI, fronting host)
		// or omits the SNI.
		RotateSNI: true,
		// Handshakes at or below the ceiling go through; serialize above it.
		CapParallelism: freezeParallelThreshold,
		Why: "parallel TLS handshakes to " + v.SNI + " stall while " +
			"sequential ones succeed: per-SNI concurrency freeze",
	}
}

// FreezeMitigation is the automatic response to a confirmed freeze.
type FreezeMitigation struct {
	// NextFingerprint is the uTLS fingerprint to switch to.
	NextFingerprint string
	// RotateSNI asks the caller to stop reusing the throttled SNI.
	RotateSNI bool
	// CapParallelism is the per-SNI handshake concurrency ceiling that
	// dodges the freeze.
	CapParallelism int
	// Why is the human-readable reason, for logs and diagnostics.
	Why string
}

// FreezeDetector accumulates handshake outcomes per SNI and names the
// freeze pattern. The zero value is usable; Now may be overridden in
// tests. It is safe for concurrent use.
type FreezeDetector struct {
	Now func() time.Time
	// OnFreeze fires when a verdict flips to frozen for an SNI, at most
	// once per Cooldown per SNI. It is called without the detector lock;
	// keep it fast and non-blocking.
	OnFreeze func(v FreezeVerdict)
	// Cooldown bounds OnFreeze refires; zero means the default.
	Cooldown time.Duration

	mu       sync.Mutex
	samples  map[string][]FreezeSample
	lastFire map[string]time.Time
}

func (d *FreezeDetector) now() time.Time {
	if d.Now != nil {
		return d.Now()
	}
	return time.Now()
}

func (d *FreezeDetector) cooldown() time.Duration {
	if d.Cooldown > 0 {
		return d.Cooldown
	}
	return freezeCooldownDefault
}

// Observe records one dial outcome. Only TLS dials belong here: a sample
// covers the TCP connect plus the handshake, because the passive prober
// path cannot separate the two — a dial that never completes in time under
// parallelism is the freeze signal at either layer. The active probe
// (FreezeProber) separates the phases precisely; feed it raw handshake
// samples.
func (d *FreezeDetector) Observe(s FreezeSample) {
	if s.SNI == "" {
		return
	}
	if s.Concurrent < 1 {
		s.Concurrent = 1
	}
	if s.At.IsZero() {
		s.At = d.now()
	}
	d.mu.Lock()
	if d.samples == nil {
		d.samples = map[string][]FreezeSample{}
	}
	kept := append(d.samples[s.SNI], s)
	if len(kept) > freezeMaxSamples {
		kept = kept[len(kept)-freezeMaxSamples:]
	}
	d.samples[s.SNI] = kept
	d.mu.Unlock()

	if d.OnFreeze == nil {
		return
	}
	v := d.Verdict(s.SNI)
	if !v.Frozen {
		return
	}
	now := d.now()
	d.mu.Lock()
	last := d.lastFire[s.SNI]
	if d.lastFire == nil {
		d.lastFire = map[string]time.Time{}
	}
	if now.Sub(last) < d.cooldown() {
		d.mu.Unlock()
		return
	}
	d.lastFire[s.SNI] = now
	d.mu.Unlock()
	d.OnFreeze(v)
}

// ObserveFailure classifies a dial error and records it as a freeze sample.
// Pass the raw dial error and whether a TLS handshake was attempted, the
// same contract as ClassifyDialError: classify before any errs wrapping.
//
// A cancelled attempt carries no signal about the network — someone
// stopped waiting, the handshake did not stall — so it is ignored. This
// matters for connection racing: losers are cancelled routinely, and
// recording them as stalls would poison the detector with false
// evidence on every race.
func (d *FreezeDetector) ObserveFailure(sni string, concurrent int, err error, tlsAttempted bool) {
	if err == nil {
		d.Observe(FreezeSample{SNI: sni, Concurrent: concurrent, Stalled: false})
		return
	}
	if errors.Is(err, context.Canceled) {
		return
	}
	f := ClassifyDialError(err, tlsAttempted)
	if f.Signature != SignatureTimeout {
		// A stall is a handshake that never finished in time. Resets,
		// alerts and certificate failures fail fast: they are not
		// successes, and they belong to other signatures (SNI blocking),
		// so the freeze detector records nothing for them.
		return
	}
	d.Observe(FreezeSample{SNI: sni, Concurrent: concurrent, Stalled: true})
}

// Verdict reads the current pattern for one SNI.
func (d *FreezeDetector) Verdict(sni string) FreezeVerdict {
	v := FreezeVerdict{SNI: sni}
	d.mu.Lock()
	samples := d.samples[sni]
	d.mu.Unlock()
	cutoff := d.now().Add(-freezeSampleTTL)
	for _, s := range samples {
		if s.At.Before(cutoff) {
			continue
		}
		if s.Concurrent > freezeParallelThreshold {
			v.ParallelTotal++
			if s.Stalled {
				v.ParallelStalled++
			}
		} else {
			v.SequentialTotal++
			if !s.Stalled {
				v.SequentialOK++
			}
		}
	}
	switch {
	case v.ParallelStalled >= freezeMinStalled && v.SequentialOK >= freezeMinSequentialOK:
		v.Frozen = true
		v.Confidence = freezeConfidence(v.ParallelStalled, v.SequentialOK)
		v.Evidence = []string{
			evidencef("%d of %d parallel dials (concurrency > %d) stalled",
				v.ParallelStalled, v.ParallelTotal, freezeParallelThreshold),
			evidencef("%d of %d sequential dials succeeded: the endpoint is alive, the path throttles concurrency",
				v.SequentialOK, v.SequentialTotal),
		}
	case v.SequentialTotal > 0 && v.SequentialOK == 0:
		v.Evidence = []string{
			evidencef("sequential dials stalled too (%d of %d): dead or slow endpoint, not a freeze signature",
				v.SequentialTotal-v.SequentialOK, v.SequentialTotal),
		}
	case v.ParallelTotal >= freezeMinStalled && v.ParallelStalled == 0:
		v.Evidence = []string{
			evidencef("%d parallel dials completed: no freeze", v.ParallelTotal),
		}
	default:
		v.Evidence = []string{"not enough was observed to name a freeze pattern"}
	}
	return v
}

// freezeConfidence: 0.55 for the minimal pattern (2 stalled parallels, 1
// sequential success), +0.10 per extra stalled parallel (up to 2),
// +0.05 per extra sequential success (up to 2), capped at 0.85 so one
// detector never claims certainty alone.
func freezeConfidence(stalledParallel, seqOK int) float64 {
	c := 0.55
	if extra := stalledParallel - freezeMinStalled; extra > 0 {
		if extra > 2 {
			extra = 2
		}
		c += 0.10 * float64(extra)
	}
	if extra := seqOK - freezeMinSequentialOK; extra > 0 {
		if extra > 2 {
			extra = 2
		}
		c += 0.05 * float64(extra)
	}
	if c > freezeConfidenceCap {
		c = freezeConfidenceCap
	}
	return c
}

func evidencef(format string, args ...any) string {
	return fmt.Sprintf(format, args...)
}

// errInvalidFreezeTarget reports a malformed freeze-probe target. The core
// dials it, so host and port are validated like any other untrusted input.
func errInvalidFreezeTarget() error {
	return errors.New("probe: freeze probe needs a valid host and port, and a parallel burst above the freeze threshold")
}

// FreezeProbeOptions tunes the active differential test.
type FreezeProbeOptions struct {
	// Sequential is how many handshakes run one at a time. Default 3.
	Sequential int
	// Parallel is the burst size; it must exceed the freeze threshold of 3
	// to exercise the pattern. Default 6.
	Parallel int
	// Timeout bounds one handshake. Default 10s.
	Timeout time.Duration
}

// FreezeProber runs the active differential freeze test: sequential
// handshakes first, then one parallel burst, all against host:port with the
// given SNI. The zero value is usable.
type FreezeProber struct {
	Timeout time.Duration
	Now     func() time.Time
}

func (f *FreezeProber) now() time.Time {
	if f.Now != nil {
		return f.Now()
	}
	return time.Now()
}

// ProbeFreeze executes the differential test and returns the detector
// verdict for sni. Every handshake attempt is observed into a fresh
// detector, so the verdict reflects exactly this test.
func (f *FreezeProber) ProbeFreeze(ctx context.Context, host string, port uint32, sni string, opts FreezeProbeOptions) (FreezeVerdict, error) {
	if host == "" || port == 0 || port > 0xffff {
		return FreezeVerdict{}, errInvalidFreezeTarget()
	}
	if opts.Sequential <= 0 {
		opts.Sequential = 3
	}
	if opts.Parallel <= 0 {
		opts.Parallel = 6
	}
	if opts.Parallel <= freezeParallelThreshold {
		return FreezeVerdict{}, errInvalidFreezeTarget()
	}
	timeout := f.Timeout
	if opts.Timeout > 0 {
		timeout = opts.Timeout
	}
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	d := &FreezeDetector{Now: f.Now}
	name := sni
	if name == "" {
		name = host
	}
	// Sequential leg: the control group. If these fail, the endpoint is
	// not a freeze candidate and the verdict will say so.
	for i := 0; i < opts.Sequential; i++ {
		if err := ctx.Err(); err != nil {
			return FreezeVerdict{SNI: name}, err
		}
		stalled, _ := freezeHandshake(ctx, timeout, host, port, name)
		d.Observe(FreezeSample{SNI: name, Concurrent: 1, Stalled: stalled, At: f.now()})
	}
	// Parallel leg: the freeze trigger. All goroutines start together so
	// the burst genuinely overlaps.
	var wg sync.WaitGroup
	for i := 0; i < opts.Parallel; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			stalled, _ := freezeHandshake(ctx, timeout, host, port, name)
			d.Observe(FreezeSample{SNI: name, Concurrent: opts.Parallel, Stalled: stalled, At: f.now()})
		}()
	}
	wg.Wait()
	return d.Verdict(name), nil
}

// freezeHandshake dials TCP, then runs a TLS handshake. It reports whether
// the handshake stalled (never completed in time) and the classified
// failure. Certificate verification is deliberately skipped: the freeze
// probe measures handshake liveness, not trust — hijacked certificates are
// a separate signature (SignatureCert) owned by the TLS prober.
func freezeHandshake(ctx context.Context, timeout time.Duration, host string, port uint32, sni string) (bool, DialFailure) {
	addr := net.JoinHostPort(host, strconv.FormatUint(uint64(port), 10))
	dctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	conn, err := (&net.Dialer{}).DialContext(dctx, "tcp", addr)
	if err != nil {
		return false, ClassifyDialError(err, false)
	}
	defer func() { _ = conn.Close() }()
	tlsConn := tls.Client(conn, &tls.Config{
		ServerName:         sni,
		MinVersion:         tls.VersionTLS12,
		InsecureSkipVerify: true, //nolint:gosec // liveness probe, not a trust decision; see above
	})
	_ = tlsConn.SetDeadline(time.Now().Add(timeout))
	if herr := tlsConn.HandshakeContext(dctx); herr != nil {
		f := ClassifyDialError(herr, true)
		if f.Signature == SignatureTimeout {
			// TCP already connected: any timeout here is a handshake
			// stall, even if the classifier could not name the phase.
			f.Phase = PhaseTLS
			return true, f
		}
		return false, f
	}
	return false, DialFailure{}
}
