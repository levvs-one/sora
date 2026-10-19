package probe

import (
	"context"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
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

func (f *fakeEngine) Kind() engine.Kind                      { return engine.KindSingBox }
func (f *fakeEngine) Capabilities() engine.Capabilities      { return engine.Capabilities{} }
func (f *fakeEngine) State() engine.State                    { return engine.StateRunning }
func (f *fakeEngine) Version() engine.Version                 { return engine.Version{} }
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
		DataDir: t.TempDir(),
		Now:     time.Now,
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

	hist := b.History()
	if len(hist) != 1 || hist[0].ServerID != "s1" || hist[0].BytesPerSec == 0 {
		t.Fatalf("history not recorded: %+v", hist)
	}
	if hist[0].StaleAt(time.Now()) {
		t.Fatal("fresh entry must not be stale")
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
		DataDir: t.TempDir(),
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
	if len(b.History()) != 0 {
		t.Fatal("failed benchmark must not be recorded")
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

func TestHistoryTTLAndPersistence(t *testing.T) {
	dir := t.TempDir()
	now := time.Now()
	b, err := NewBenchmarker(BenchmarkerConfig{
		NewEngine:  func(context.Context, *engine.Plan) (engine.Engine, error) { return nil, nil },
		SelectKind: func(engine.Outbound) (engine.Kind, error) { return engine.KindSingBox, nil },
		DataDir:    dir,
		Now:        func() time.Time { return now },
	})
	if err != nil {
		t.Fatal(err)
	}
	b.RecordLatency("s1", 42*time.Millisecond)

	// Reload from disk: the entry must survive.
	b2, err := NewBenchmarker(BenchmarkerConfig{
		NewEngine:  func(context.Context, *engine.Plan) (engine.Engine, error) { return nil, nil },
		SelectKind: func(engine.Outbound) (engine.Kind, error) { return engine.KindSingBox, nil },
		DataDir:    dir,
		Now:        func() time.Time { return now.Add(25 * time.Hour) },
	})
	if err != nil {
		t.Fatal(err)
	}
	hist := b2.History()
	if len(hist) != 1 || hist[0].LatencyMs != 42 {
		t.Fatalf("history not persisted: %+v", hist)
	}
	if !hist[0].StaleAt(now.Add(25 * time.Hour)) {
		t.Fatal("25h-old entry must be stale")
	}
	if !hist[0].StaleAt(now) {
		t.Fatal("fresh entry must not be stale")
	}
	if _, err := os.Stat(filepath.Join(dir, historyDir, historyFile)); err != nil {
		t.Fatalf("history file missing: %v", err)
	}
}

func TestHistoryMergesBandwidthAndLatency(t *testing.T) {
	b, err := NewBenchmarker(BenchmarkerConfig{
		NewEngine:  func(context.Context, *engine.Plan) (engine.Engine, error) { return nil, nil },
		SelectKind: func(engine.Outbound) (engine.Kind, error) { return engine.KindSingBox, nil },
		DataDir:    t.TempDir(),
		Now:        time.Now,
	})
	if err != nil {
		t.Fatal(err)
	}
	b.RecordLatency("s1", 30*time.Millisecond)
	b.recordBandwidth("s1", 1_000_000, engine.KindSingBox)
	hist := b.History()
	if len(hist) != 1 {
		t.Fatalf("expected one merged entry: %+v", hist)
	}
	if hist[0].LatencyMs != 30 || hist[0].BytesPerSec != 1_000_000 {
		t.Fatalf("entry not merged: %+v", hist[0])
	}
}

func TestNewBenchmarkerValidation(t *testing.T) {
	if _, err := NewBenchmarker(BenchmarkerConfig{}); err == nil {
		t.Fatal("expected validation error for empty config")
	}
}
