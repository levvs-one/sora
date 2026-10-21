package ext

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"runtime/debug"
	"runtime/metrics"
	"strings"
	"time"

	"github.com/dop251/goja"
	"github.com/dop251/goja/parser"
)

// Worker budgets bound committed memory, CPU time, wall time and source size.
const (
	WorkerMemoryBytes = 128 << 20
	// workerOSMemoryBytes is the hard OS backstop. The Go runtime maps heap
	// in 64 MiB arenas, so an OS limit at the budget itself fails runtime
	// start-up on some kernels; watchWorkerHeap enforces the budget instead.
	workerOSMemoryBytes = 4 * WorkerMemoryBytes
	WorkerCPUSeconds    = 2
	WorkerWallTimeout   = 30 * time.Second
	MaxWorkerSource     = 1 << 20
	maxWorkerMessage    = 12 << 20
	maxWorkerCalls      = 256
)

// WorkerCall uses JSON only: no Go objects or native handles reach JavaScript.
type WorkerCall func(context.Context, json.RawMessage) (json.RawMessage, error)

type workerInput struct {
	Source      string `json:"source"`
	SessionKind string `json:"session_kind"`
}

// RunJavaScriptProcess executes one script in a disposable, resource-limited
// copy of sora-core. Cancellation kills and reaps it, including blocked native
// calls and allocation failures which a VM interrupt alone cannot contain.
func RunJavaScriptProcess(ctx context.Context, source string, event string, call WorkerCall) error {
	ctx, cancel := context.WithTimeout(ctx, WorkerWallTimeout)
	defer cancel()
	exe, err := os.Executable()
	if err != nil {
		return err
	}
	cmd := exec.CommandContext(ctx, exe, "--extension-worker") //nolint:gosec // os.Executable is this binary, never an extension-supplied command.
	return runJavaScriptCommand(ctx, cmd, source, event, call)
}

func runJavaScriptCommand(ctx context.Context, cmd *exec.Cmd, source string, event string, call WorkerCall) error {
	if len(source) > MaxWorkerSource {
		return errors.New("worker source exceeds 1 MiB")
	}
	input, err := cmd.StdinPipe()
	if err != nil {
		return err
	}
	defer func() { _ = input.Close() }()
	output, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	// OOM dumps can be large and carry script data; only the first line of
	// a Go runtime failure is kept, which names the cause and nothing else.
	fatal := &runtimeFailure{}
	cmd.Stderr = fatal
	if err = cmd.Start(); err != nil {
		return err
	}
	defer func() { _ = cmd.Process.Kill(); _ = cmd.Wait() }()
	enc := json.NewEncoder(input)
	if err = enc.Encode(workerInput{Source: source, SessionKind: event}); err != nil {
		return err
	}
	scan := bufio.NewScanner(output)
	scan.Buffer(make([]byte, 4096), maxWorkerMessage)
	for calls := 0; scan.Scan(); calls++ {
		if calls >= maxWorkerCalls {
			return errors.New("worker API call budget exceeded")
		}
		var outcome struct {
			WorkerError string `json:"worker_error"`
		}
		if json.Unmarshal(scan.Bytes(), &outcome) == nil && outcome.WorkerError != "" {
			return errors.New(outcome.WorkerError)
		}
		reply, callErr := call(ctx, append(json.RawMessage(nil), scan.Bytes()...))
		if callErr != nil {
			return callErr
		}
		if len(reply) > maxWorkerMessage {
			return errors.New("worker reply exceeds message budget")
		}
		if _, err = input.Write(append(reply, '\n')); err != nil {
			return err
		}
	}
	if err = scan.Err(); err != nil {
		return err
	}
	if err = cmd.Wait(); err != nil {
		if ctx.Err() != nil {
			return ctx.Err()
		}
		if line := fatal.line(); line != "" {
			return fmt.Errorf("worker process: %w: %s", err, line)
		}
		return fmt.Errorf("worker process: %w", err)
	}
	return ctx.Err()
}

// JavaScriptMain is entered before service startup. The child has no store,
// socket, filesystem, networking, module loader or process API in its JS VM.
func JavaScriptMain(input io.Reader, output io.Writer) error {
	if err := limitWorkerProcess(); err != nil {
		return err
	}
	debug.SetMemoryLimit(WorkerMemoryBytes / 2)
	go watchWorkerBudget(WorkerMemoryBytes, WorkerCPUSeconds*time.Second)
	scan := bufio.NewScanner(input)
	scan.Buffer(make([]byte, 4096), maxWorkerMessage)
	if !scan.Scan() {
		return errors.New("missing worker source")
	}
	var init workerInput
	if err := json.Unmarshal(scan.Bytes(), &init); err != nil {
		return err
	}
	if len(init.Source) > MaxWorkerSource {
		return errors.New("worker source exceeds 1 MiB")
	}
	vm := goja.New()
	// The default source-map loader reads local files, including from eval.
	vm.SetParserOptions(parser.WithDisableSourceMaps)
	vm.SetMaxCallStackSize(256)
	if err := vm.Set("__sessionKind", init.SessionKind); err != nil {
		return err
	}
	if err := vm.Set("__call", func(raw string) string {
		if len(raw) > MaxWorkerSource {
			panic(vm.NewTypeError("worker request too large"))
		}
		if _, err := fmt.Fprintln(output, raw); err != nil {
			panic(vm.NewGoError(err))
		}
		if !scan.Scan() {
			panic(vm.NewTypeError("worker host closed"))
		}
		return string(scan.Bytes())
	}); err != nil {
		return err
	}
	_, err := vm.RunString(workerBootstrap)
	if err != nil {
		return err
	}
	rejected := map[*goja.Promise]bool{}
	vm.SetPromiseRejectionTracker(func(p *goja.Promise, op goja.PromiseRejectionOperation) {
		if op == goja.PromiseRejectionReject {
			rejected[p] = true
		} else {
			delete(rejected, p)
		}
	})
	result, err := vm.RunScript("worker.js", "(async () => {\n"+init.Source+"\n})()")
	if err != nil {
		return err
	}
	promise, ok := result.Export().(*goja.Promise)
	if !ok {
		return errors.New("worker did not return a promise")
	}
	if promise.State() == goja.PromiseStatePending {
		return errors.New("worker left an unresolved promise")
	}
	if promise.State() == goja.PromiseStateRejected {
		return fmt.Errorf("worker rejected: %s", promise.Result())
	}
	for p := range rejected {
		return fmt.Errorf("unhandled worker rejection: %s", p.Result())
	}
	return nil
}

const workerBootstrap = `
(() => {
 const host = __call;
 const sessionKind = __sessionKind;
 delete globalThis.__sessionKind;
 delete globalThis.__call;
 globalThis.window = globalThis;
 let seq = 0;
 const listeners = [];
 const api = {
  call(method, args) {
   return new Promise((resolve, reject) => {
    const r = JSON.parse(host(JSON.stringify({id: ++seq, method, args: args || {}})));
    if (r.ok) resolve(r.result);
    else { const e = new Error(r.error); e.code = r.error; reject(e); }
   });
  },
  onEvent(cb) {
   if (typeof cb !== 'function') throw new TypeError('listener must be a function');
   listeners.push(cb);
   Promise.resolve().then(() => { if (listeners.includes(cb)) cb(sessionKind, ''); });
   return () => { const i = listeners.indexOf(cb); if (i >= 0) listeners.splice(i, 1); };
  }
 };
 globalThis.soraExt = Object.freeze(api);
 globalThis.console = Object.freeze({log(...args) {
  const r = JSON.parse(host(JSON.stringify({method: 'log', args: {message: args.map(String).join(' ').slice(0,1024)}})));
  if (!r.ok) throw new Error(r.error);
 }});
})();`

// Exit codes of a worker stopped by watchWorkerBudget.
const (
	workerHeapExceeded = 3
	workerCPUExceeded  = 4
)

// watchWorkerBudget ends the worker once its live heap or its CPU time
// passes the budget. The OS limits (rlimits, a Windows job) stay as the
// backstop, but whether and how they bite differs per platform and per
// host job nesting, and this check behaves the same everywhere.
func watchWorkerBudget(heap uint64, cpu time.Duration) {
	sample := []metrics.Sample{{Name: "/memory/classes/heap/objects:bytes"}}
	for range time.Tick(20 * time.Millisecond) {
		metrics.Read(sample)
		if sample[0].Value.Kind() == metrics.KindUint64 && sample[0].Value.Uint64() > heap {
			_, _ = fmt.Fprintln(os.Stderr, "extension worker exceeded its memory budget")
			os.Exit(workerHeapExceeded)
		}
		if used, err := processCPUTime(); err == nil && used > cpu {
			_, _ = fmt.Fprintln(os.Stderr, "extension worker exceeded its CPU budget")
			os.Exit(workerCPUExceeded)
		}
	}
}

// runtimeFailure keeps the first stderr line of a worker when it is a Go
// runtime failure ("fatal error: ..." or "runtime: ..."), capped at 200
// bytes, and drops everything else.
type runtimeFailure struct {
	buf  []byte
	done bool
}

func (r *runtimeFailure) Write(p []byte) (int, error) {
	if !r.done {
		for _, b := range p {
			if b == '\n' || len(r.buf) >= 200 {
				r.done = true
				break
			}
			r.buf = append(r.buf, b)
		}
	}
	return len(p), nil
}

func (r *runtimeFailure) line() string {
	line := string(r.buf)
	if strings.HasPrefix(line, "fatal error:") || strings.HasPrefix(line, "runtime:") {
		return line
	}
	return ""
}
