package ext

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// A runtime parent job must coexist with the worker's atomic startup job and
// its own resource-limit job. Merely cross-compiling both paths cannot prove it.
func TestRuntimeEngineJobAllowsIsolatedWorkers(t *testing.T) {
	cmd := filepath.Join(os.Getenv("SystemRoot"), "System32", "cmd.exe")
	child, err := supervise.Start(t.Context(), supervise.Spec{
		Name: "inert parent-job setup", Path: cmd, Args: []string{"/d", "/c", "exit", "0"}, Dir: t.TempDir(),
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = child.Stop(context.Background(), 0) })
	if err := child.Wait(t.Context()); err != nil {
		t.Fatal(err)
	}

	binary := os.Getenv("SORA_TEST_NESTED_WORKER_BIN")
	if binary == "" {
		binary = filepath.Join(t.TempDir(), "sora-core.exe")
		build := exec.CommandContext(t.Context(), "go", "build", "-o", binary, "../cmd/sora-core")
		if out, err := build.CombinedOutput(); err != nil {
			t.Fatalf("build isolated worker: %v\n%s", err, out)
		}
	}
	t.Run("successful script", func(t *testing.T) {
		ctx, cancel := context.WithTimeout(t.Context(), 8*time.Second)
		defer cancel()
		err := runJavaScriptCommand(ctx, exec.CommandContext(ctx, binary, "--extension-worker"),
			"const answer=2+2; if(answer!==4) throw new Error('wrong result');", "session.disconnected",
			func(context.Context, json.RawMessage) (json.RawMessage, error) {
				return nil, errors.New("unexpected bridge call")
			})
		if err != nil {
			t.Fatal(err)
		}
	})
	t.Run("cancelled after bridge readiness", func(t *testing.T) {
		ctx, cancel := context.WithTimeout(t.Context(), 8*time.Second)
		defer cancel()
		ready := false
		err := runJavaScriptCommand(ctx, exec.CommandContext(ctx, binary, "--extension-worker"),
			"console.log('fixture ready'); await new Promise(() => {});", "session.disconnected",
			func(context.Context, json.RawMessage) (json.RawMessage, error) {
				ready = true
				cancel()
				return json.RawMessage("null"), nil
			})
		if !ready || !errors.Is(err, context.Canceled) {
			t.Fatalf("worker readiness/cancellation: ready=%v err=%v", ready, err)
		}
	})
}
