package probe

import (
	"context"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// fakeEngine is a benchmark engine double: Apply records the plan, Running
// exposes a test proxy port, Close marks teardown.
type fakeEngine struct {
	port    int
	applied *engine.Plan
	closed  atomic.Bool
	failRun bool
}

func (f *fakeEngine) Kind() engine.Kind                            { return engine.KindSingBox }
func (f *fakeEngine) Capabilities() engine.Capabilities            { return engine.Capabilities{} }
func (f *fakeEngine) State() engine.State                          { return engine.StateRunning }
func (f *fakeEngine) Version() engine.Version                      { return engine.Version{} }
func (f *fakeEngine) Validate(context.Context, *engine.Plan) error { return nil }
func (f *fakeEngine) Apply(_ context.Context, p *engine.Plan) error {
	if f.failRun {
		return errors.New("fake: engine failed to start")
	}
	f.applied = p
	return nil
}
func (f *fakeEngine) Stop(context.Context) error { return nil }
func (f *fakeEngine) Close() error               { f.closed.Store(true); return nil }
func (f *fakeEngine) Groups(context.Context) ([]engine.GroupStatus, error) {
	return nil, nil
}
func (f *fakeEngine) Select(context.Context, string, string) error { return nil }
func (f *fakeEngine) Delay(ctx context.Context, _ string, _ string, _ time.Duration) (time.Duration, error) {
	return 0, nil
}
func (f *fakeEngine) Counters(context.Context) (engine.Counters, error) {
	return engine.Counters{}, nil
}
func (f *fakeEngine) Events() *engine.EventBus { return engine.NewEventBus(1) }
func (f *fakeEngine) Running() (supervise.Runtime, error) {
	return supervise.Runtime{LocalPort: f.port}, nil
}

// proxyStub serves fixed bytes for any request, acting as the loopback proxy
// target for benchmark downloads.
func proxyStub(t *testing.T, payload []byte) (*httptest.Server, int) {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Length", "1048576")
		// Stream the payload in a loop; the client stops at duration end.
		for {
			if _, err := w.Write(payload); err != nil {
				return
			}
			if f, ok := w.(http.Flusher); ok {
				f.Flush()
			}
		}
	}))
	addr := srv.Listener.Addr().(*net.TCPAddr)
	return srv, addr.Port
}

func testOutbound(id string) engine.Outbound {
	return engine.Outbound{ID: id, Name: "srv-" + id, Server: "example.com", Port: 443}
}

func newTestBenchmarker(t *testing.T, eng *fakeEngine) *Benchmarker {
	t.Helper()
	b, err := NewBenchmarker(BenchmarkerConfig{
		NewEngine: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return eng, nil
		},
		SelectKind: func(engine.Outbound) (engine.Kind, error) {
			return engine.KindSingBox, nil
		},
		Now: time.Now,
	})
	if err != nil {
		t.Fatal(err)
	}
	return b
}

func collectSamples(t *testing.T, ch <-chan BandwidthSample) []BandwidthSample {
	t.Helper()
	var out []BandwidthSample
	timeout := time.After(15 * time.Second)
	for {
		select {
		case s, ok := <-ch:
			if !ok {
				return out
			}
			out = append(out, s)
		case <-timeout:
			t.Fatal("timed out waiting for benchmark samples")
		}
	}
}

func TestBenchmarkSuccess(t *testing.T) {
	payload := make([]byte, 64*1024)
	stub, port := proxyStub(t, payload)
	defer stub.Close()

	eng := &fakeEngine{port: port}
	b := newTestBenchmarker(t, eng)

	ch, err := b.Benchmark(context.Background(), []engine.Outbound{testOutbound("s1")}, engine.BandwidthOptions{
		URL:         stub.URL,
		Duration:    1500 * time.Millisecond,
		Timeout:     10 * time.Second,
		Concurrency: 2,
	})
	if err != nil {
		t.Fatal(err)
	}
	samples := collectSamples(t, ch)

	var done *BandwidthSample
	for i := range samples {
		if samples[i].Done {
			done = &samples[i]
		}
	}
	if done == nil {
		t.Fatal("no done sample")
	}
	if done.Err != nil {
		t.Fatalf("benchmark failed: %v", done.Err)
	}
	if done.BytesPerSec == 0 {
		t.Fatal("expected positive throughput")
	}
	if !eng.closed.Load() {
		t.Fatal("temporary engine was not closed")
	}
	if eng.applied == nil || len(eng.applied.Outbounds) != 1 {
		t.Fatal("engine did not receive the single-outbound plan")
	}
	if !eng.applied.LocalProxy.Enabled {
		t.Fatal("benchmark plan must enable the loopback proxy")
	}

	// No stored history remains to assert (M3): results are the live
	// samples above, nothing else.
}

// TestBenchmarkBuildsFreshEnginePerServer pins the load-bearing half of
// the Hysteria2 stall audit (WEB-RESEARCH-5 S2): every server is measured
// through its OWN newly built temporary engine, so a benchmark verdict
// can never ride a pre-existing (possibly stalled) QUIC connection —
// neither the live session's nor another server's. If benchmarkOne ever
// starts sharing one engine across servers, this fails.
func TestBenchmarkBuildsFreshEnginePerServer(t *testing.T) {
	payload := make([]byte, 32*1024)
	stub, port := proxyStub(t, payload)
	defer stub.Close()

	var mu sync.Mutex
	var engines []*fakeEngine
	b, err := NewBenchmarker(BenchmarkerConfig{
		NewEngine: func(context.Context, *engine.Plan) (engine.Engine, error) {
			eng := &fakeEngine{port: port}
			mu.Lock()
			engines = append(engines, eng)
			mu.Unlock()
			return eng, nil
		},
		SelectKind: func(engine.Outbound) (engine.Kind, error) {
			return engine.KindSingBox, nil
		},
		Now: time.Now,
	})
	if err != nil {
		t.Fatal(err)
	}
	ch, err := b.Benchmark(context.Background(),
		[]engine.Outbound{testOutbound("s1"), testOutbound("s2")},
		engine.BandwidthOptions{
			URL:         stub.URL,
			Duration:    300 * time.Millisecond,
			Timeout:     10 * time.Second,
			Concurrency: 2,
		})
	if err != nil {
		t.Fatal(err)
	}
	samples := collectSamples(t, ch)
	doneCount := 0
	for _, s := range samples {
		if s.Done {
			doneCount++
			if s.Err != nil {
				t.Fatalf("benchmark for %s failed: %v", s.ServerID, s.Err)
			}
		}
	}
	if doneCount != 2 {
		t.Fatalf("expected 2 done samples, got %d (%+v)", doneCount, samples)
	}
	mu.Lock()
	defer mu.Unlock()
	if len(engines) != 2 {
		t.Fatalf("NewEngine called %d times for 2 servers, want exactly 2 (one fresh engine per server)", len(engines))
	}
	seen := map[string]bool{}
	for _, eng := range engines {
		if eng.applied == nil || len(eng.applied.Outbounds) != 1 {
			t.Fatalf("each temporary engine must carry exactly one outbound, got %+v", eng.applied)
		}
		seen[eng.applied.Outbounds[0].ID] = true
		if !eng.closed.Load() {
			t.Fatal("temporary engine was not closed")
		}
	}
	if !seen["s1"] || !seen["s2"] {
		t.Fatalf("each server must be measured on its own engine, saw %v", seen)
	}
}

func TestBenchmarkNoEngine(t *testing.T) {
	b, err := NewBenchmarker(BenchmarkerConfig{
		NewEngine: func(context.Context, *engine.Plan) (engine.Engine, error) {
			t.Fatal("engine must not be built without a kind")
			return nil, nil
		},
		SelectKind: func(engine.Outbound) (engine.Kind, error) {
			return "", engine.ErrNoEngine
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	ch, err := b.Benchmark(context.Background(), []engine.Outbound{testOutbound("s9")}, engine.BandwidthOptions{})
	if err != nil {
		t.Fatal(err)
	}
	samples := collectSamples(t, ch)
	if len(samples) != 1 || !samples[0].Done || !errors.Is(samples[0].Err, engine.ErrNoEngine) {
		t.Fatalf("expected single ErrNoEngine done sample, got %+v", samples)
	}
}

func TestBenchmarkEngineStartFails(t *testing.T) {
	stub, port := proxyStub(t, make([]byte, 1024))
	defer stub.Close()

	eng := &fakeEngine{port: port, failRun: true}
	b := newTestBenchmarker(t, eng)
	ch, err := b.Benchmark(context.Background(), []engine.Outbound{testOutbound("s2")}, engine.BandwidthOptions{
		URL: stub.URL, Duration: time.Second, Timeout: 5 * time.Second,
	})
	if err != nil {
		t.Fatal(err)
	}
	samples := collectSamples(t, ch)
	var done *BandwidthSample
	for i := range samples {
		if samples[i].Done {
			done = &samples[i]
		}
	}
	if done == nil || done.Err == nil {
		t.Fatalf("expected failed done sample, got %+v", samples)
	}
	if !eng.closed.Load() {
		t.Fatal("failed engine must still be closed")
	}
}

func TestBenchmarkCancelled(t *testing.T) {
	stub, port := proxyStub(t, make([]byte, 1024))
	defer stub.Close()

	eng := &fakeEngine{port: port}
	b := newTestBenchmarker(t, eng)
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	ch, err := b.Benchmark(ctx, []engine.Outbound{testOutbound("s3")}, engine.BandwidthOptions{
		URL: stub.URL, Duration: time.Minute, Timeout: time.Minute,
	})
	if err != nil {
		t.Fatal(err)
	}
	samples := collectSamples(t, ch)
	if len(samples) == 0 || !samples[len(samples)-1].Done {
		t.Fatalf("cancelled benchmark must end with a done sample: %+v", samples)
	}
}

func TestNewBenchmarkerValidation(t *testing.T) {
	if _, err := NewBenchmarker(BenchmarkerConfig{}); err == nil {
		t.Fatal("expected validation error for empty config")
	}
}

// TestBenchmarkPlanPassesEngineValidation runs the benchmark with the
// engine double (whose Validate is a no-op) and then puts the applied
// plan through the REAL engine.Plan.Validate. The double alone let two
// wiring defects ship: the match-all rule targeted the invented
// display name "benchmark" instead of the outbound ID, which every
// real engine rejects as an unknown target (WAVE-INTEGRATION E2E).
func TestBenchmarkPlanPassesEngineValidation(t *testing.T) {
	payload := make([]byte, 32*1024)
	stub, port := proxyStub(t, payload)
	defer stub.Close()

	eng := &fakeEngine{port: port}
	b := newTestBenchmarker(t, eng)
	outbound := engine.Outbound{
		ID: "shadowsocks:127.0.0.1:8388:abc123", Name: "srv-real",
		Protocol: engine.ProtocolShadowsocks, Server: "127.0.0.1", Port: 8388,
		Cipher: "aes-256-gcm", Password: "test-password",
	}
	ch, err := b.Benchmark(context.Background(), []engine.Outbound{outbound}, engine.BandwidthOptions{
		URL: stub.URL, Duration: 1200 * time.Millisecond, Timeout: 10 * time.Second, Concurrency: 1,
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, s := range collectSamples(t, ch) {
		if s.Done && s.Err != nil {
			t.Fatalf("benchmark failed: %v", s.Err)
		}
	}
	if eng.applied == nil {
		t.Fatal("engine received no plan")
	}
	if err := eng.applied.Validate(); err != nil {
		t.Fatalf("the benchmark plan must pass real engine validation: %v", err)
	}
	found := false
	for _, r := range eng.applied.Rules {
		if r.Type == engine.RuleMatchAll {
			found = true
			if r.Target != outbound.ID {
				t.Fatalf("match-all rule target = %q, want the outbound ID %q", r.Target, outbound.ID)
			}
		}
	}
	if !found {
		t.Fatal("benchmark plan has no match-all rule")
	}
}
