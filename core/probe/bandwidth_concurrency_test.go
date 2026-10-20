package probe

// Concurrency regression tests: a consumer that abandons the sample
// channel mid-benchmark (like control.BenchmarkServers returning on a
// broken stream) must not wedge the benchmark goroutines or leak the
// temporary engines.

import (
	"context"
	"net"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// closeCountingEngine is a fake benchmark engine that counts Close calls.
type closeCountingEngine struct {
	port   int
	closed *atomic.Int32
}

func (f *closeCountingEngine) Kind() engine.Kind                            { return engine.KindSingBox }
func (f *closeCountingEngine) Capabilities() engine.Capabilities            { return engine.Capabilities{} }
func (f *closeCountingEngine) State() engine.State                          { return engine.StateRunning }
func (f *closeCountingEngine) Version() engine.Version                      { return engine.Version{} }
func (f *closeCountingEngine) Validate(context.Context, *engine.Plan) error { return nil }
func (f *closeCountingEngine) Apply(context.Context, *engine.Plan) error    { return nil }
func (f *closeCountingEngine) Stop(context.Context) error                   { return nil }
func (f *closeCountingEngine) Close() error                                 { f.closed.Add(1); return nil }
func (f *closeCountingEngine) Groups(context.Context) ([]engine.GroupStatus, error) {
	return nil, nil
}
func (f *closeCountingEngine) Select(context.Context, string, string) error { return nil }
func (f *closeCountingEngine) Delay(_ context.Context, _, _ string, _ time.Duration) (time.Duration, error) {
	return 0, nil
}
func (f *closeCountingEngine) Counters(context.Context) (engine.Counters, error) {
	return engine.Counters{}, nil
}
func (f *closeCountingEngine) Events() *engine.EventBus { return engine.NewEventBus(1) }
func (f *closeCountingEngine) Running() (supervise.Runtime, error) {
	return supervise.Runtime{LocalPort: f.port}, nil
}

// slowProxyStub streams 1 KiB every 200 ms forever, so downloads never
// finish on their own and progress ticks keep coming. With blocking sample
// sends the producers wedge on the full channel; the fix must let them
// unwind on cancellation.
func slowProxyStub(t *testing.T) (*httptest.Server, int) {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Length", "1073741824") // 1 GiB: never reached
		chunk := make([]byte, 1024)
		f, _ := w.(http.Flusher)
		for {
			if _, err := w.Write(chunk); err != nil {
				return
			}
			if f != nil {
				f.Flush()
			}
			select {
			case <-r.Context().Done():
				return
			case <-time.After(200 * time.Millisecond):
			}
		}
	}))
	t.Cleanup(srv.Close)
	addr := srv.Listener.Addr().(*net.TCPAddr)
	return srv, addr.Port
}

// TestBenchmarkAbandonedConsumerTearsDownEngines abandons the sample channel
// while downloads are in flight (like control.BenchmarkServers returning on
// a broken stream) and then cancels. Every built engine must still be torn
// down and the channel must still close so range loops terminate.
func TestBenchmarkAbandonedConsumerTearsDownEngines(t *testing.T) {
	stub, port := slowProxyStub(t)

	// built counts engines actually constructed; a server that never gets
	// a semaphore slot before cancellation correctly reports Done without
	// building one. The invariant is closed == built.
	var built, closed atomic.Int32
	b, err := NewBenchmarker(BenchmarkerConfig{
		NewEngine: func(context.Context, *engine.Plan) (engine.Engine, error) {
			built.Add(1)
			return &closeCountingEngine{port: port, closed: &closed}, nil
		},
		SelectKind: func(engine.Outbound) (engine.Kind, error) {
			return engine.KindSingBox, nil
		},
		Now: time.Now,
	})
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	outbounds := []engine.Outbound{
		testOutbound("s1"), testOutbound("s2"),
		testOutbound("s3"), testOutbound("s4"),
	}
	ch, err := b.Benchmark(ctx, outbounds, engine.BandwidthOptions{
		URL: stub.URL, Duration: 30 * time.Second, Timeout: time.Minute,
	})
	if err != nil {
		t.Fatal(err)
	}
	// Abandon the channel and let progress samples pile up: with the old
	// blocking sends the producers wedge on the full channel here. Then
	// cancel and check teardown WITHOUT draining: draining would unwedge
	// the producers itself and hide the leak.
	time.Sleep(2500 * time.Millisecond)
	cancel()
	deadline := time.Now().Add(5 * time.Second)
	for {
		builtN, closedN := built.Load(), closed.Load()
		if builtN > 0 && closedN == builtN {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("engines not torn down after consumer abandonment: closed=%d built=%d",
				closedN, builtN)
		}
		time.Sleep(50 * time.Millisecond)
	}
	// Every producer is gone, so the channel must be closed: drain it.
	timeout := time.After(5 * time.Second)
drain:
	for {
		select {
		case _, ok := <-ch:
			if !ok {
				break drain
			}
		case <-timeout:
			t.Fatal("sample channel did not close after cancellation")
		}
	}
	if built.Load() == 0 {
		t.Fatal("no benchmark engine was built; the test proves nothing")
	}
}
