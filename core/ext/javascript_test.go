package ext

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"
)

func TestJavaScriptProcess(t *testing.T) {
	binary := filepath.Join(t.TempDir(), "sora-core")
	if runtime.GOOS == "windows" {
		binary += ".exe"
	}
	build := exec.CommandContext(t.Context(), "go", "build", "-o", binary, "../cmd/sora-core")
	if output, err := build.CombinedOutput(); err != nil {
		t.Fatalf("build real worker: %v\n%s", err, output)
	}
	m, x := bgPair(t, 15)
	scheduler := NewScheduler(nil)
	scheduler.SetFetchTransport(func(string) http.RoundTripper {
		return roundTripFunc(func(req *http.Request) (*http.Response, error) {
			if req.URL.Host != "api.example.com" {
				t.Errorf("disallowed request escaped: %s", req.URL)
			}
			return &http.Response{StatusCode: 200, Header: http.Header{}, Body: io.NopCloser(strings.NewReader("ready"))}, nil
		})
	})
	var env *WorkerEnv
	if err := scheduler.Register(m, x, func(_ context.Context, e *WorkerEnv) error { env = e; return nil }); err != nil {
		t.Fatal(err)
	}
	task, _ := scheduler.Task(m.ID)
	scheduler.runOnce(task)
	bridge := func(ctx context.Context, raw json.RawMessage) (json.RawMessage, error) {
		return workerBridgeCall(ctx, m, env, raw, func() (json.RawMessage, error) { t.Fatal("refused API forwarded to app"); return nil, nil })
	}
	t.Run("real worker script, permissions, allowlist and events", func(t *testing.T) {
		source, err := os.ReadFile("testdata/worker.js")
		if err != nil {
			t.Fatal(err)
		}
		ctx, cancel := context.WithTimeout(t.Context(), 10*time.Second)
		defer cancel()
		cmd := exec.CommandContext(ctx, binary, "--extension-worker")
		if err = runJavaScriptCommand(ctx, cmd, string(source), "session.connected", bridge); err != nil {
			t.Fatal(err)
		}
		var lines []string
		for _, line := range env.log.Entries() {
			lines = append(lines, line.Message)
		}
		for _, expected := range []string{"worker finished", "getServers DENIED", "session.connected", "fetch DENIED"} {
			if !strings.Contains(strings.Join(lines, "\n"), expected) {
				t.Errorf("missing %q: %v", expected, lines)
			}
		}
	})
	t.Run("source map filesystem loader disabled including eval", func(t *testing.T) {
		if runtime.GOOS != "linux" {
			t.Skip("the source-map read trap uses Linux /dev/zero")
		}
		// The default loader reads forever until the child exhausts its memory
		// budget. A disabled loader returns normally without opening this path.
		source := "eval('//# sourceMappingURL=file:///dev/zero'); console.log('source maps disabled');"
		ctx, cancel := context.WithTimeout(t.Context(), 5*time.Second)
		defer cancel()
		if err := runJavaScriptCommand(ctx, exec.CommandContext(ctx, binary, "--extension-worker"), source, "session.disconnected", bridge); err != nil {
			t.Fatal(err)
		}
	})
	t.Run("host cancellation", func(t *testing.T) {
		ctx, cancel := context.WithCancel(t.Context())
		timer := time.AfterFunc(100*time.Millisecond, cancel)
		defer timer.Stop()
		defer cancel()
		err := runJavaScriptCommand(ctx, exec.CommandContext(ctx, binary, "--extension-worker"), "while(true) {}", "session.disconnected", bridge)
		if !errors.Is(err, context.Canceled) {
			t.Fatalf("host cancellation became a worker failure: %v", err)
		}
	})
	for _, tc := range []struct {
		name, source string
		timeout      time.Duration
	}{
		{"wall timeout", "while (true) {}", 250 * time.Millisecond},
		{"CPU budget", "while (true) {}", WorkerWallTimeout},
		{"memory budget", "const arrays=[]; while(true) arrays.push(new Uint8Array(8*1024*1024));", 8 * time.Second},
		{"memory budget large allocation", "const bytes = new Uint8Array(1024*1024*1024);", 8 * time.Second},
		{"promise rejection", "Promise.reject(new Error('uncaught'));", 8 * time.Second},
		{"unfinished promise", "await new Promise(() => {});", 8 * time.Second},
		{"call budget", "for(let i=0;i<1000;i++) console.log(i);", 8 * time.Second},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if tc.name == "memory budget large allocation" && runtime.GOOS != "windows" {
				t.Skip("Windows job commit rejection")
			}
			ctx, cancel := context.WithTimeout(t.Context(), tc.timeout)
			defer cancel()
			started := time.Now()
			err := runJavaScriptCommand(ctx, exec.CommandContext(ctx, binary, "--extension-worker"), tc.source, "session.disconnected", bridge)
			if err == nil {
				t.Fatal("hostile worker succeeded")
			}
			if tc.name == "CPU budget" && !errors.Is(err, errWorkerCPUBudget) {
				t.Fatalf("wrong CPU budget error: %v", err)
			}
			if strings.HasPrefix(tc.name, "memory budget") && !errors.Is(err, errWorkerMemoryBudget) {
				t.Fatalf("wrong memory budget error: %v", err)
			}
			// CPU time excludes scheduling delays on shared CI runners.
			if tc.name == "CPU budget" && ctx.Err() != nil {
				t.Fatal("CPU budget only ended at wall timeout")
			}
			if strings.HasPrefix(tc.name, "memory budget") && ctx.Err() != nil {
				t.Fatal("memory exhaustion only ended at wall timeout")
			}
			t.Logf("isolated worker stopped after %s", time.Since(started))
		})
	}
}

func TestJavaScriptParentBudget(t *testing.T) {
	binary := filepath.Join(t.TempDir(), "budget-worker")
	if runtime.GOOS == "windows" {
		binary += ".exe"
	}
	build := exec.CommandContext(t.Context(), "go", "build", "-o", binary, "./testdata/budget-worker")
	if output, err := build.CombinedOutput(); err != nil {
		t.Fatalf("build worker without watchdog: %v\n%s", err, output)
	}
	for _, tc := range []struct {
		name string
		want error
	}{
		{"memory", errWorkerMemoryBudget}, {"CPU", errWorkerCPUBudget},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(t.Context(), WorkerWallTimeout)
			defer cancel()
			started := time.Now()
			err := runJavaScriptCommand(ctx, exec.CommandContext(ctx, binary, tc.name), "", "", func(context.Context, json.RawMessage) (json.RawMessage, error) {
				t.Error("worker without watchdog unexpectedly called the host")
				return nil, errors.New("unexpected worker call")
			})
			if !errors.Is(err, tc.want) {
				t.Fatalf("parent budget enforcement: got %v, want %v", err, tc.want)
			}
			if ctx.Err() != nil {
				t.Fatal("parent only stopped worker at wall timeout")
			}
			t.Logf("parent stopped worker without watchdog after %s: %v", time.Since(started), err)
		})
	}
}
