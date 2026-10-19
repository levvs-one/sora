// Package probe measures TCP reachability and optional TLS handshakes without a
// tunnel, credentials, or application payload. It streams uncached results so
// provider endpoint changes are reflected immediately.
package probe

import (
	"context"
	"crypto/tls"
	"math"
	"net"
	"net/netip"
	"strconv"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/race"
)

// Short default timeouts bound list updates for unreachable endpoints.
const (
	// DefaultTimeout bounds one endpoint.
	DefaultTimeout = 5 * time.Second
	// DefaultConcurrency limits simultaneous sockets for large
	// subscriptions.
	DefaultConcurrency = 8
	// MaxEndpoints bounds one request.
	MaxEndpoints = 256
)

// Config configures a prober.
type Config struct {
	// Timeout bounds one endpoint.
	Timeout time.Duration
	// Concurrency bounds how many endpoints are measured at once.
	Concurrency int
	// TLS requires a certificate-bearing handshake, not just an open TCP
	// socket.
	TLS bool
	// ServerName selects the verified TLS name. Empty uses the endpoint
	// host.
	ServerName string
}

// Prober measures endpoints and streams the results.
type Prober struct {
	timeout     time.Duration
	concurrency int
	tls         bool
	serverName  string
	// slots shares the socket budget across all requests; per-request
	// limits would let concurrent calls multiply socket usage.
	slots chan struct{}
	// requests bounds concurrent calls so one-endpoint floods cannot create
	// an unbounded queue.
	requests chan struct{}
	// freeze is the optional passive freeze detector; freezeInFlight
	// counts in-flight TLS handshakes per SNI for it.
	freeze         *FreezeDetector
	freezeMu       sync.Mutex
	freezeInFlight map[string]int
	// lookupIP resolves endpoint hosts for address racing; nil uses
	// the system resolver. Tests override it to avoid the network.
	lookupIP func(ctx context.Context, host string) ([]netip.Addr, error)
}

// MaxConcurrentRequests bounds how many measurements a prober runs at once.
const MaxConcurrentRequests = 4

// New returns a prober with the defaults filled in.
func New(cfg Config) *Prober {
	if cfg.Timeout <= 0 {
		cfg.Timeout = DefaultTimeout
	}
	if cfg.Concurrency <= 0 {
		cfg.Concurrency = DefaultConcurrency
	}
	return &Prober{
		timeout:     cfg.Timeout,
		concurrency: cfg.Concurrency,
		tls:         cfg.TLS,
		serverName:  cfg.ServerName,
		slots:       make(chan struct{}, cfg.Concurrency),
		requests:    make(chan struct{}, MaxConcurrentRequests),
	}
}

// SetFreezeDetector attaches the passive freeze detector: every TLS dial
// this prober runs is observed with its per-SNI in-flight handshake count,
// so the "parallel handshakes stall while sequential ones succeed" pattern
// becomes visible without an active probe. Nil detaches. Safe for
// concurrent use; swaps are not synchronized with in-flight dials, so
// attach once at setup.
func (p *Prober) SetFreezeDetector(d *FreezeDetector) {
	p.freezeMu.Lock()
	defer p.freezeMu.Unlock()
	p.freeze = d
}

// freezeBegin counts one more in-flight handshake for sni. It returns nil
// when no detector is attached, and freezeEnd is a no-op for nil.
func (p *Prober) freezeBegin(sni string) (*FreezeDetector, int) {
	p.freezeMu.Lock()
	defer p.freezeMu.Unlock()
	if p.freeze == nil {
		return nil, 0
	}
	if p.freezeInFlight == nil {
		p.freezeInFlight = map[string]int{}
	}
	p.freezeInFlight[sni]++
	return p.freeze, p.freezeInFlight[sni]
}

// freezeEnd records the handshake outcome and releases the in-flight slot.
// The raw dial error is classified here, before errs.From redacts it.
func (p *Prober) freezeEnd(d *FreezeDetector, sni string, inflight int, err error) {
	if d == nil {
		return
	}
	p.freezeMu.Lock()
	p.freezeInFlight[sni]--
	p.freezeMu.Unlock()
	d.ObserveFailure(sni, inflight, err, true)
}

// Probe streams one result per endpoint in completion order, then closes the
// channel. Missing serverIDs produce empty IDs. Socket limits are global to the
// prober; excess requests are rejected instead of queued.
func (p *Prober) Probe(ctx context.Context, endpoints []*corev1.Endpoint, serverIDs []string) (<-chan *corev1.ProbeResult, error) {
	if len(endpoints) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeNoEndpoints,
			"probe: the request carries no endpoints")
	}
	if len(endpoints) > MaxEndpoints {
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyProbeTooMany,
			"probe: the request carries %d endpoints, the limit is %d", len(endpoints), MaxEndpoints)
	}
	select {
	case p.requests <- struct{}{}:
	default:
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyProbeTooMany,
			"probe: %d measurements are already running, the limit is %d",
			len(p.requests), MaxConcurrentRequests)
	}
	results := make(chan *corev1.ProbeResult, len(endpoints))
	go func() {
		defer close(results)
		defer func() { <-p.requests }()
		var wg sync.WaitGroup
		for index, endpoint := range endpoints {
			wg.Add(1)
			go func(index int, endpoint *corev1.Endpoint) {
				defer wg.Done()
				select {
				case p.slots <- struct{}{}:
					defer func() { <-p.slots }()
				case <-ctx.Done():
					return
				}
				result := p.measure(ctx, index, endpoint, serverIDs)
				select {
				case results <- result:
				case <-ctx.Done():
				}
			}(index, endpoint)
		}
		wg.Wait()
	}()
	return results, nil
}

// measure always returns a result so failed endpoints remain represented in the
// list.
func (p *Prober) measure(ctx context.Context, index int, endpoint *corev1.Endpoint, serverIDs []string) *corev1.ProbeResult {
	result := &corev1.ProbeResult{}
	if index < len(serverIDs) {
		result.ServerId = serverIDs[index]
	}
	host, port, err := addressOf(endpoint)
	if err != nil {
		result.Error = toWire(err, "")
		return result
	}
	latency, err := p.dial(ctx, host, port)
	if err != nil {
		result.Error = toWire(err, host)
		return result
	}
	result.Reachable = true
	result.LatencyMs = counter(latency.Milliseconds())
	return result
}

// dial opens the connection, optionally completes a handshake, and reports how
// long the whole thing took.
func (p *Prober) dial(ctx context.Context, host string, port uint32) (time.Duration, error) {
	timeout := p.timeout
	if deadline, ok := ctx.Deadline(); ok {
		if remaining := time.Until(deadline); remaining > 0 && remaining < timeout {
			timeout = remaining
		}
	}
	if timeout <= 0 {
		return 0, errs.Newf(errs.CodeDeadlineExceeded, errs.KeyProbeInvalidEndpoint,
			"probe: the request has no time left")
	}
	// A hostname that resolves to several addresses races them Happy
	// Eyeballs style (P0-9): the first successful dial wins instead of
	// betting the whole budget on the first answer. A resolved answer —
	// even a single address — dials from the answer directly, so the
	// race never pays for a second DNS lookup. IP literals and failed
	// lookups keep the historical single-dial path, where the dialer
	// resolves (or skips resolving) exactly as before.
	if addrs, ok := p.candidateAddrs(ctx, host, timeout); ok {
		return p.dialRace(ctx, host, port, addrs, timeout)
	}
	return p.dialSingle(ctx, host, port, timeout)
}

// dialSingle is the historical one-address dial: one TCP connect, and one
// TLS handshake when configured.
func (p *Prober) dialSingle(ctx context.Context, host string, port uint32, timeout time.Duration) (time.Duration, error) {
	address := net.JoinHostPort(host, strconv.FormatUint(uint64(port), 10))
	start := time.Now()
	if !p.tls {
		connection, err := (&net.Dialer{Timeout: timeout}).DialContext(ctx, "tcp", address)
		if err != nil {
			return 0, errs.From(err)
		}
		_ = connection.Close()
		return time.Since(start), nil
	}
	// Include TLS in the measurement to distinguish certificate failures
	// from TCP reachability. The context cancels stalled handshakes.
	sni := p.serverName
	if sni == "" {
		sni = host
	}
	freeze, inflight := p.freezeBegin(sni)
	dialer := &tls.Dialer{
		NetDialer: &net.Dialer{Timeout: timeout},
		Config:    p.tlsConfig(host),
	}
	connection, err := dialer.DialContext(ctx, "tcp", address)
	// freezeEnd classifies the raw error before errs.From redacts the
	// operation; the phase signal does not survive wrapping.
	p.freezeEnd(freeze, sni, inflight, err)
	if err != nil {
		return 0, errs.From(err)
	}
	_ = connection.Close()
	return time.Since(start), nil
}

// candidateAddrs resolves host to the addresses a race would try, in
// resolver order. It reports false for IP literals (nothing to resolve)
// and when resolution fails, keeping those cases on the historical
// single-dial path where the dialer resolves (or skips resolving) as
// before. A resolved answer — even a single address — reports true, so
// the caller dials from the answer directly instead of resolving twice.
func (p *Prober) candidateAddrs(ctx context.Context, host string, timeout time.Duration) ([]netip.Addr, bool) {
	if _, err := netip.ParseAddr(host); err == nil {
		return nil, false
	}
	lookup := p.lookupIP
	if lookup == nil {
		lookup = systemLookupIP
	}
	// Bound the lookup well inside the endpoint budget so a slow
	// resolver cannot starve the race.
	rctx, cancel := context.WithTimeout(ctx, min(timeout, 2*time.Second))
	defer cancel()
	addrs, err := lookup(rctx, host)
	if err != nil || len(addrs) == 0 {
		return nil, false
	}
	return addrs, true
}

// systemLookupIP resolves host through the system resolver, keeping the
// answer order: the race preference order is deterministic, never
// shuffled.
func systemLookupIP(ctx context.Context, host string) ([]netip.Addr, error) {
	records, err := net.DefaultResolver.LookupIPAddr(ctx, host)
	if err != nil {
		return nil, err
	}
	addrs := make([]netip.Addr, 0, len(records))
	for _, r := range records {
		if addr, ok := netip.AddrFromSlice(r.IP); ok {
			addrs = append(addrs, addr.Unmap())
		}
	}
	return addrs, nil
}

// dialRace dials every resolved address of the endpoint in a Happy
// Eyeballs race and reports the winner's latency. The winner's label
// names its address for process-local telemetry; it never reaches the
// wire result, where endpoint addresses stay redacted (SORA-M7).
func (p *Prober) dialRace(ctx context.Context, host string, port uint32, addrs []netip.Addr, timeout time.Duration) (time.Duration, error) {
	portStr := strconv.FormatUint(uint64(port), 10)
	candidates := make([]race.Candidate, 0, len(addrs))
	for _, addr := range addrs {
		target := net.JoinHostPort(addr.String(), portStr)
		candidates = append(candidates, race.Candidate{
			Label:   "tcp/" + target,
			Network: "tcp",
			Address: target,
			Dial: func(dialCtx context.Context) (net.Conn, error) {
				return p.dialCandidate(dialCtx, host, target, timeout)
			},
		})
	}
	res, err := race.Race(ctx, candidates, race.Options{
		Concurrency:    race.DefaultConcurrency,
		Stagger:        race.DefaultStagger,
		AttemptTimeout: timeout,
	})
	if err != nil {
		return 0, err
	}
	_ = res.Conn.Close()
	return res.Latency, nil
}

// dialCandidate dials one raced address: a TCP connect, plus the TLS
// handshake when configured. Each attempt is observed by the freeze
// detector exactly like the historical single dial, so in-flight counts
// stay truthful; attempts cancelled as race losers carry
// context.Canceled, which the detector deliberately ignores.
func (p *Prober) dialCandidate(ctx context.Context, host, target string, timeout time.Duration) (net.Conn, error) {
	if !p.tls {
		return (&net.Dialer{Timeout: timeout}).DialContext(ctx, "tcp", target)
	}
	sni := p.serverName
	if sni == "" {
		sni = host
	}
	freeze, inflight := p.freezeBegin(sni)
	raw, err := (&net.Dialer{Timeout: timeout}).DialContext(ctx, "tcp", target)
	if err != nil {
		p.freezeEnd(freeze, sni, inflight, err)
		return nil, err
	}
	tlsConn := tls.Client(raw, p.tlsConfig(host))
	if err := tlsConn.HandshakeContext(ctx); err != nil {
		p.freezeEnd(freeze, sni, inflight, err)
		_ = raw.Close()
		return nil, err
	}
	p.freezeEnd(freeze, sni, inflight, nil)
	return tlsConn, nil
}

// EndpointProber defines the interface required by the control plane, keeping
// compatibility checks near the implementation.
type EndpointProber interface {
	Probe(ctx context.Context, endpoints []*corev1.Endpoint, serverIDs []string) (<-chan *corev1.ProbeResult, error)
}

var _ EndpointProber = (*Prober)(nil)

// tlsConfig enables certificate verification so hijacked or untrusted servers
// cannot appear healthy.
func (p *Prober) tlsConfig(host string) *tls.Config {
	name := p.serverName
	if name == "" {
		name = host
	}
	return &tls.Config{
		ServerName: name,
		MinVersion: tls.VersionTLS12,
	}
}

// addressOf reads and checks one endpoint.
func addressOf(endpoint *corev1.Endpoint) (string, uint32, error) {
	if endpoint == nil {
		return "", 0, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
			"probe: the endpoint is missing")
	}
	host := endpoint.GetHost()
	if host == "" {
		return "", 0, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
			"probe: the endpoint has no host")
	}
	port := endpoint.GetPort()
	if port == 0 || port > 0xffff {
		return "", 0, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
			"probe: the port is not a port")
	}
	return host, port, nil
}

// toWire converts probe failures without exposing endpoint addresses to
// clients.
func toWire(err error, host string) *corev1.SoraError {
	classified := errs.From(err)
	detail := classified.Detail()
	if host == "" && detail == "" {
		detail = "the endpoint is not a host and a port"
	}
	return &corev1.SoraError{
		Code:           probeCode(classified.Code()),
		UserMessageKey: string(classified.Key()),
		DetailRedacted: detail,
		Retryable:      classified.Retryable(),
	}
}

// probeCode maps network failures, including refusal, to unavailable probe
// results. Malformed endpoints remain invalid.
func probeCode(code errs.Code) corev1.SoraErrorCode {
	switch code {
	case errs.CodeInvalidArgument:
		return corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT
	case errs.CodePermissionDenied:
		return corev1.SoraErrorCode_SORA_ERROR_CODE_PERMISSION_DENIED
	case errs.CodeTimeout, errs.CodeDeadlineExceeded:
		return corev1.SoraErrorCode_SORA_ERROR_CODE_DEADLINE_EXCEEDED
	default:
		return corev1.SoraErrorCode_SORA_ERROR_CODE_UNAVAILABLE
	}
}

// counter converts milliseconds to the wire field without negative values.
func counter(value int64) uint32 {
	if value <= 0 {
		return 0
	}
	if value > math.MaxUint32 {
		return math.MaxUint32
	}
	return uint32(value) //nolint:gosec // bounded by the check above
}
