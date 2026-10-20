package probe

// Throughput benchmarks: measures real download goodput per server through a
// temporary engine session. Results stream to the caller live; sora keeps
// no benchmark history of its own (the GetBenchmarks RPC that once read
// one had no client and was removed — see reports/PASS1-SWARM.md, M3).
//
// A benchmark spins up one engine per server (never the live session engine),
// routes a local loopback proxy through that server only, downloads in
// parallel streams, then tears the engine down. The temporary engine receives
// credentials exactly like a normal session (stdin); no new secret paths are
// introduced.

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"sync"
	"sync/atomic"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Defaults for benchmarks. The speed-test URL is documented because the
// traffic it serves is what the user pays for on metered servers.
const (
	// DefaultSpeedtestURL serves sized downloads and honors range requests.
	DefaultSpeedtestURL = "https://speed.cloudflare.com/__down?bytes=100000000"

	defaultBenchmarkDuration    = 10 * time.Second
	defaultBenchmarkTimeout     = 30 * time.Second
	defaultBenchmarkConcurrency = 2
	maxBenchmarkConcurrency     = 4
)

// BenchmarkerConfig wires a Benchmarker. NewEngine and SelectKind are
// required.
type BenchmarkerConfig struct {
	// NewEngine builds a temporary engine for one benchmark plan.
	NewEngine func(ctx context.Context, p *engine.Plan) (engine.Engine, error)
	// SelectKind picks the engine kind able to carry the outbound.
	SelectKind func(o engine.Outbound) (engine.Kind, error)
	// Now is overridden in tests.
	Now func() time.Time
}

// BandwidthSample is one progress or final sample of a server benchmark.
type BandwidthSample struct {
	ServerID    string
	BytesPerSec uint64
	ProgressPct uint32
	Done        bool
	Err         error
}

// Benchmarker measures throughput. It keeps no stored history: results
// stream out of Benchmark live, and the app stores whatever it shows.
type Benchmarker struct {
	cfg BenchmarkerConfig
}

// NewBenchmarker validates the config.
func NewBenchmarker(cfg BenchmarkerConfig) (*Benchmarker, error) {
	if cfg.NewEngine == nil || cfg.SelectKind == nil {
		return nil, fmt.Errorf("probe: benchmarker needs NewEngine and SelectKind")
	}
	return &Benchmarker{cfg: cfg}, nil
}

// runtimeProvider is implemented by engines embedding supervise.Supervisor.
type runtimeProvider interface {
	Running() (supervise.Runtime, error)
}

// Benchmark measures every outbound's download goodput, streaming progress
// samples. The returned channel closes when all servers are done; each
// server ends with exactly one Done sample (carrying Err on failure), unless
// ctx is cancelled first: then undelivered samples are dropped, but every
// temporary engine is still torn down and the channel still closes.
// A caller that stops reading must cancel ctx, otherwise producers stay
// blocked on the full channel.
func (b *Benchmarker) Benchmark(ctx context.Context, outbounds []engine.Outbound, opts engine.BandwidthOptions) (<-chan BandwidthSample, error) {
	if len(outbounds) == 0 {
		return nil, fmt.Errorf("probe: benchmark needs at least one outbound")
	}
	if opts.Duration <= 0 {
		opts.Duration = defaultBenchmarkDuration
	}
	if opts.Timeout <= 0 {
		opts.Timeout = defaultBenchmarkTimeout
	}
	if opts.Concurrency <= 0 {
		opts.Concurrency = defaultBenchmarkConcurrency
	}
	if opts.Concurrency > maxBenchmarkConcurrency {
		opts.Concurrency = maxBenchmarkConcurrency
	}
	if opts.URL == "" {
		opts.URL = DefaultSpeedtestURL
	}

	out := make(chan BandwidthSample, len(outbounds)*2)
	sem := make(chan struct{}, opts.Concurrency)
	// send prefers delivering the sample, but never wedges the producer:
	// once the caller's context is done the consumer is gone (or going),
	// so the sample is dropped and the caller unwinds. Engine teardown and
	// the channel close stay guaranteed even when nobody drains.
	send := func(s BandwidthSample) bool {
		select {
		case out <- s:
			return true
		default:
		}
		select {
		case out <- s:
			return true
		case <-ctx.Done():
			return false
		}
	}
	var wg sync.WaitGroup
	for _, o := range outbounds {
		o := o
		kind, err := b.cfg.SelectKind(o)
		if err != nil {
			send(BandwidthSample{ServerID: o.ID, Done: true, Err: engine.ErrNoEngine})
			continue
		}
		wg.Add(1)
		go func() {
			defer wg.Done()
			select {
			case sem <- struct{}{}:
				defer func() { <-sem }()
			case <-ctx.Done():
				send(BandwidthSample{ServerID: o.ID, Done: true, Err: ctx.Err()})
				return
			}
			b.benchmarkOne(ctx, o, kind, opts, send)
		}()
	}
	go func() {
		wg.Wait()
		close(out)
	}()
	return out, nil
}

// benchmarkOne runs a single server through a temporary engine session. The
// engine is always torn down, even on failure or cancellation. Samples that
// cannot be delivered after the caller's context ends are dropped so a gone
// consumer never wedges the benchmark.
func (b *Benchmarker) benchmarkOne(ctx context.Context, o engine.Outbound, kind engine.Kind, opts engine.BandwidthOptions, send func(BandwidthSample) bool) {
	id := o.ID
	fail := func(err error) {
		send(BandwidthSample{ServerID: id, Done: true, ProgressPct: 100, Err: err})
	}
	if !send(BandwidthSample{ServerID: id, ProgressPct: 0}) {
		return
	}

	ctx, cancel := context.WithTimeout(ctx, opts.Timeout)
	defer cancel()

	o.Name = "benchmark"
	plan := &engine.Plan{
		SessionID: "benchmark-" + id,
		Engines:   []engine.Kind{kind},
		LocalProxy: engine.LocalProxy{Enabled: true},
		Outbounds: []engine.Outbound{o},
		Rules:     []engine.Rule{{Type: engine.RuleMatchAll, Target: o.Name}},
		Options:   engine.Options{LogLevel: "error"},
	}
	eng, err := b.cfg.NewEngine(ctx, plan)
	if err != nil {
		fail(fmt.Errorf("probe: benchmark engine build: %w", err))
		return
	}
	// Guaranteed teardown: no temporary session may outlive its benchmark.
	defer func() { _ = eng.Close() }()

	if err := eng.Apply(ctx, plan); err != nil {
		fail(fmt.Errorf("probe: benchmark engine start: %w", err))
		return
	}
	rp, ok := eng.(runtimeProvider)
	if !ok {
		fail(fmt.Errorf("probe: benchmark engine exposes no loopback proxy"))
		return
	}
	rt, err := rp.Running()
	if err != nil || rt.LocalPort == 0 {
		fail(fmt.Errorf("probe: benchmark proxy not running"))
		return
	}
	proxyAddr := fmt.Sprintf("127.0.0.1:%d", rt.LocalPort)
	if err := waitProxy(ctx, proxyAddr, 10*time.Second); err != nil {
		fail(fmt.Errorf("probe: benchmark proxy not ready: %w", err))
		return
	}

	bps, err := downloadGoodput(ctx, proxyAddr, opts.URL, opts.Duration, opts.Concurrency, func(pct uint32) {
		send(BandwidthSample{ServerID: id, ProgressPct: pct})
	})
	if err != nil {
		fail(err)
		return
	}
	b.recordBandwidth(id, bps, kind)
	send(BandwidthSample{ServerID: id, BytesPerSec: bps, ProgressPct: 100, Done: true})
}

// waitProxy polls a TCP dial until the loopback proxy accepts or ctx ends.
func waitProxy(ctx context.Context, addr string, timeout time.Duration) error {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	for {
		conn, err := (&net.Dialer{}).DialContext(ctx, "tcp", addr)
		if err == nil {
			_ = conn.Close()
			return nil
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(100 * time.Millisecond):
		}
	}
}

// downloadGoodput fetches url through the loopback proxy in parallel range
// streams for the whole duration and returns bytes per second. Progress
// callbacks receive 0..99; the caller emits the final 100.
func downloadGoodput(ctx context.Context, proxyAddr, rawURL string, duration time.Duration, concurrency int, progress func(uint32)) (uint64, error) {
	proxyURL, err := url.Parse("http://" + proxyAddr)
	if err != nil {
		return 0, fmt.Errorf("probe: bad proxy address: %w", err)
	}
	// Explicit proxy: benchmark traffic must go through the engine, never
	// through an ambient HTTP_PROXY.
	client := &http.Client{
		Transport: &http.Transport{Proxy: http.ProxyURL(proxyURL)},
	}

	ctx, cancel := context.WithTimeout(ctx, duration)
	defer cancel()

	var total atomic.Uint64
	var wg sync.WaitGroup
	errCh := make(chan error, concurrency)
	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func(worker int) {
			defer wg.Done()
			// Offset streams so parallel workers don't fetch identical
			// ranges; the server only needs to honor Range loosely.
			req, err := http.NewRequestWithContext(ctx, http.MethodGet, rawURL, nil)
			if err != nil {
				errCh <- err
				return
			}
			if worker > 0 {
				req.Header.Set("Range", fmt.Sprintf("bytes=%d-", worker*1<<20))
			}
			resp, err := client.Do(req)
			if err != nil {
				errCh <- err
				return
			}
			defer func() { _ = resp.Body.Close() }()
			if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusPartialContent {
				errCh <- fmt.Errorf("probe: speedtest answered %s", resp.Status)
				return
			}
			buf := make([]byte, 128*1024)
			for {
				n, rerr := resp.Body.Read(buf)
				total.Add(uint64(n))
				if rerr != nil {
					if rerr == io.EOF {
						// Server ended the stream early; keep what we got.
						return
					}
					// Context cancellation is the normal stop.
					return
				}
			}
		}(i)
	}

	start := time.Now()
	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()
	done := make(chan struct{})
	go func() { wg.Wait(); close(done) }()
	for {
		select {
		case <-done:
			elapsed := time.Since(start)
			if elapsed <= 0 {
				return 0, fmt.Errorf("probe: no measurable download")
			}
			return uint64(float64(total.Load()) / elapsed.Seconds()), nil
		case err := <-errCh:
			cancel()
			wg.Wait()
			return 0, err
		case t := <-ticker.C:
			pct := uint32(t.Sub(start) * 100 / duration)
			if pct > 99 {
				pct = 99
			}
			progress(pct)
		case <-ctx.Done():
			// Duration elapsed: workers drain via the cancelled context.
			wg.Wait()
			elapsed := time.Since(start)
			if elapsed <= 0 || total.Load() == 0 {
				return 0, fmt.Errorf("probe: no measurable download")
			}
			return uint64(float64(total.Load()) / elapsed.Seconds()), nil
		}
	}
}
