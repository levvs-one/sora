package winws

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// This finite child records only private files, never sockets or WinDivert.
func TestMain(m *testing.M) {
	if len(os.Args) > 1 && strings.HasPrefix(os.Args[1], "--wf-") {
		mode, _ := os.ReadFile("fixture-mode")
		bootstrap := slices.Contains(os.Args[1:], "--wf-raw=false")
		name := "filter"
		if bootstrap {
			name = "bootstrap"
		}
		raw, _ := json.Marshal(os.Args[1:])
		if err := os.WriteFile(name+".args", raw, 0o600); err != nil {
			os.Exit(2)
		}
		if err := os.WriteFile(name+".pid", []byte(strconv.Itoa(os.Getpid())), 0o600); err != nil {
			os.Exit(2)
		}
		if string(mode) == name+"-exit" {
			os.Exit(3)
		}
		if string(mode) != name+"-stall" {
			fmt.Println(readyMarker)
		}
		for end := time.Now().Add(15 * time.Second); time.Now().Before(end); {
			if _, err := os.Stat(name + ".exit"); err == nil {
				os.Exit(4)
			}
			time.Sleep(10 * time.Millisecond)
		}
		os.Exit(5)
	}
	os.Exit(m.Run())
}

type fixtureForwarder struct {
	engine.Engine
	mu       sync.Mutex
	state    engine.State
	bus      *engine.EventBus
	applyErr error
	onApply  func() error
	applied  *engine.Plan
}

func (f *fixtureForwarder) State() engine.State                              { f.mu.Lock(); defer f.mu.Unlock(); return f.state }
func (f *fixtureForwarder) Events() *engine.EventBus                         { return f.bus }
func (f *fixtureForwarder) Validate(_ context.Context, p *engine.Plan) error { return p.Validate() }
func (f *fixtureForwarder) Apply(_ context.Context, p *engine.Plan) error {
	if f.onApply != nil {
		if err := f.onApply(); err != nil {
			return err
		}
	}
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.applyErr != nil {
		return f.applyErr
	}
	f.applied = p
	f.state = engine.StateRunning
	return nil
}
func (f *fixtureForwarder) Stop(context.Context) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.state = engine.StateStopped
	return nil
}
func (f *fixtureForwarder) Close() error { return f.Stop(context.Background()) }

type bundleFixture struct{ active *atomic.Int32 }

func (b *bundleFixture) Close() error { b.active.Add(-1); return nil }

func fixturePlan() *engine.Plan {
	return &engine.Plan{SessionID: "filter", Outbounds: []engine.Outbound{{ID: "filter", Protocol: engine.ProtocolWinws, Bypass: &engine.BypassStrategy{SplitPos: []string{"1"}}}}, Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "filter"}}}
}

func fixture(t *testing.T) (*Engine, *fixtureForwarder, *atomic.Int32) {
	t.Helper()
	exe, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	f := &fixtureForwarder{state: engine.StateIdle, bus: engine.NewEventBus(16)}
	e := Wrap(f, exe, dir, nil)
	active := &atomic.Int32{}
	e.openBundle = func(string) (io.Closer, error) { active.Add(1); return &bundleFixture{active}, nil }
	e.checkService = func(_ string, required bool) error {
		if !required {
			return nil
		}
		if _, err := os.Stat(filepath.Join(dir, "bootstrap.pid")); err != nil {
			return errors.New("driver checked before no-capture readiness")
		}
		if _, err := os.Stat(filepath.Join(dir, "filter.args")); err == nil {
			return errors.New("capture started before loaded driver check")
		}
		return nil
	}
	t.Cleanup(func() {
		if err := e.Close(); err != nil {
			t.Error(err)
		}
		if active.Load() != 0 {
			t.Error("bundle ownership leaked")
		}
	})
	return e, f, active
}

func TestFilterStartupOrderProjectionAndStop(t *testing.T) {
	e, f, active := fixture(t)
	if err := e.Apply(t.Context(), fixturePlan()); err != nil {
		t.Fatal(err)
	}
	if e.State() != engine.StateRunning || active.Load() != 1 {
		t.Fatalf("state=%s locked=%d", e.State(), active.Load())
	}
	f.mu.Lock()
	protocol := f.applied.Outbounds[0].Protocol
	f.mu.Unlock()
	if protocol != engine.ProtocolDirect {
		t.Fatal("forwarder did not receive direct projection")
	}
	raw, err := os.ReadFile(filepath.Join(e.home, "bootstrap.args"))
	if err != nil {
		t.Fatal(err)
	}
	var args []string
	if err := json.Unmarshal(raw, &args); err != nil || !slices.Equal(args, []string{"--wf-raw=false"}) {
		t.Fatalf("bootstrap captured traffic: %s", raw)
	}
	proc := e.proc
	if err := e.Stop(t.Context()); err != nil {
		t.Fatal(err)
	}
	if !proc.Exited() || active.Load() != 0 {
		t.Fatal("stop released ownership before child termination")
	}
}

func TestFilterFailuresDoNotStartUnshapedForwarder(t *testing.T) {
	for _, mode := range []string{"bootstrap-exit", "bootstrap-stall", "filter-exit", "filter-stall", "driver-mismatch", "forwarder-refusal", "cancelled"} {
		t.Run(mode, func(t *testing.T) {
			e, f, active := fixture(t)
			if err := os.WriteFile(filepath.Join(e.home, "fixture-mode"), []byte(mode), 0o600); err != nil {
				t.Fatal(err)
			}
			if mode == "driver-mismatch" {
				e.checkService = func(_ string, required bool) error {
					if required {
						return errors.New("foreign driver")
					}
					return nil
				}
			}
			if mode == "forwarder-refusal" {
				f.applyErr = errors.New("refused forwarding configuration")
			}
			timeout := 5 * time.Second
			if strings.HasSuffix(mode, "-stall") {
				timeout = time.Second
			}
			ctx, cancel := context.WithTimeout(t.Context(), timeout)
			if mode == "cancelled" {
				cancel()
			}
			defer cancel()
			err := e.Apply(ctx, fixturePlan())
			if err == nil {
				t.Fatal("failed filter accepted")
			}
			switch mode {
			case "driver-mismatch":
				if !strings.Contains(err.Error(), "foreign driver") {
					t.Fatalf("wrong failure: %v", err)
				}
			case "forwarder-refusal":
				if !strings.Contains(err.Error(), "refused forwarding") {
					t.Fatalf("wrong failure: %v", err)
				}
			case "cancelled":
				if !errors.Is(err, context.Canceled) {
					t.Fatalf("wrong cancellation: %v", err)
				}
			default:
				name := strings.Split(mode, "-")[0]
				if _, statErr := os.Stat(filepath.Join(e.home, name+".args")); statErr != nil {
					t.Fatalf("child did not reach requested failure: %v", statErr)
				}
				if strings.HasSuffix(mode, "-stall") && !errors.Is(err, context.DeadlineExceeded) {
					t.Fatalf("wrong timeout: %v", err)
				}
				if strings.HasSuffix(mode, "-exit") && !strings.Contains(err.Error(), "exited before readiness") {
					t.Fatalf("wrong exit: %v", err)
				}
			}
			if f.State() == engine.StateRunning || active.Load() != 0 || e.proc != nil || e.bootstrap != nil {
				t.Fatal("failure retained a process or unshaped session")
			}
		})
	}
}

func TestRejectedStrategyKeepsWorkingFilter(t *testing.T) {
	e, _, _ := fixture(t)
	if err := e.Apply(t.Context(), fixturePlan()); err != nil {
		t.Fatal(err)
	}
	proc := e.proc
	p := fixturePlan()
	p.Outbounds[0].Bypass.TLSRecord = "1"
	if err := e.Apply(t.Context(), p); err == nil {
		t.Fatal("unsupported record split accepted")
	}
	if proc.Exited() || e.proc != proc {
		t.Fatal("invalid replacement stopped the working filter")
	}
}

func TestUnexpectedFilterExitStopsForwarderAndReportsFatal(t *testing.T) {
	e, f, active := fixture(t)
	ch, unsub := e.Events().Subscribe()
	defer unsub()
	if err := e.Apply(t.Context(), fixturePlan()); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(e.home, "filter.exit"), nil, 0o600); err != nil {
		t.Fatal(err)
	}
	select {
	case event := <-ch:
		if event.Kind != engine.EventFatal {
			t.Fatalf("event=%+v", event)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("filter crash did not report a fatal event")
	}
	if e.State() != engine.StateFailed || f.State() != engine.StateStopped || active.Load() != 0 {
		t.Fatal("filter crash left a working-looking session or bundle lock")
	}
}

func TestCloseIsTerminalEvenForAPrevalidatedApply(t *testing.T) {
	e, _, active := fixture(t)
	if err := e.Validate(t.Context(), fixturePlan()); err != nil {
		t.Fatal(err)
	}
	if err := e.Close(); err != nil {
		t.Fatal(err)
	}
	if err := e.Apply(t.Context(), fixturePlan()); err == nil || !strings.Contains(err.Error(), "closed") {
		t.Fatalf("closed runtime accepted apply: %v", err)
	}
	if active.Load() != 0 || e.proc != nil || e.bootstrap != nil {
		t.Fatal("late apply revived a closed filter")
	}
}

func TestCancellationAtNativeCheckpointsStartsNoTrafficChild(t *testing.T) {
	for _, stage := range []string{"before bootstrap", "before traffic"} {
		t.Run(stage, func(t *testing.T) {
			e, _, active := fixture(t)
			ctx, cancel := context.WithCancel(t.Context())
			defer cancel()
			check := e.checkService
			queries := 0
			e.checkService = func(binary string, required bool) error {
				if err := check(binary, required); err != nil {
					return err
				}
				queries++
				if (stage == "before bootstrap" && queries == 2) || (stage == "before traffic" && required) {
					cancel()
				}
				return nil
			}
			if err := e.Apply(ctx, fixturePlan()); !errors.Is(err, context.Canceled) {
				t.Fatalf("checkpoint cancellation: %v", err)
			}
			if _, err := os.Stat(filepath.Join(e.home, "filter.args")); !os.IsNotExist(err) {
				t.Fatal("traffic child started after cancellation")
			}
			if stage == "before bootstrap" {
				if _, err := os.Stat(filepath.Join(e.home, "bootstrap.args")); !os.IsNotExist(err) {
					t.Fatal("driver bootstrap started after cancellation")
				}
			}
			if active.Load() != 0 || e.proc != nil || e.bootstrap != nil {
				t.Fatal("cancelled checkpoint retained runtime ownership")
			}
		})
	}
}

func TestFilterExitDuringForwarderApplyCannotReportSuccess(t *testing.T) {
	e, f, active := fixture(t)
	f.onApply = func() error {
		if e.proc == nil {
			return errors.New("capturing child never started")
		}
		if err := os.WriteFile(filepath.Join(e.home, "filter.exit"), nil, 0o600); err != nil {
			return err
		}
		ctx, cancel := context.WithTimeout(t.Context(), 3*time.Second)
		defer cancel()
		_ = e.proc.Wait(ctx)
		if ctx.Err() != nil {
			return errors.New("fixture filter did not exit during forwarder apply")
		}
		return nil
	}
	err := e.Apply(t.Context(), fixturePlan())
	if err == nil || !strings.Contains(err.Error(), "exited during forwarder startup") {
		t.Fatalf("lost filter reported successful apply: %v", err)
	}
	if f.State() == engine.StateRunning || active.Load() != 0 || e.proc != nil {
		t.Fatal("lost filter left the forwarder running or its bundle locked")
	}
}
