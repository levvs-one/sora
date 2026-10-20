package clashapi

import (
	"context"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// This file pins the fast-switch invariant for the Clash-API engines
// (mihomo, and sing-box through the same wrapper): after Apply, the
// engine's effective selection equals the plan's Group.Selected — even
// when the engine's persisted cache holds a different member from an
// earlier session — while a runtime Select on the same engine instance
// survives a re-Apply (a session reconnect).
//
// The engine is the test binary re-executed with fakeClashFlag: it
// serves a minimal Clash API on the address the rendered config names
// and keeps its selection in a state file, like the real engines keep
// theirs in cache.db.

const fakeClashFlag = "-sora-fake-clash"

func TestMain(m *testing.M) {
	if len(os.Args) > 2 && os.Args[1] == fakeClashFlag {
		os.Exit(fakeClashEngine(os.Args[2]))
	}
	os.Exit(m.Run())
}

type fakeClashConfig struct {
	Addr  string `json:"addr"`
	State string `json:"state"`
}

func fakeClashEngine(mode string) int {
	raw, err := io.ReadAll(os.Stdin)
	if err != nil {
		return 3
	}
	var cfg fakeClashConfig
	if err := json.Unmarshal(raw, &cfg); err != nil {
		return 2
	}
	if mode == "check" {
		return 0
	}
	now := func() string {
		if data, err := os.ReadFile(cfg.State); err == nil && len(data) > 0 {
			return string(data)
		}
		return "a" // a selector starts on its first member
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/version", func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{"meta": true, "version": "fake-1"})
	})
	mux.HandleFunc("/proxies", func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{"proxies": map[string]any{
			"pick": map[string]any{"name": "pick", "type": "Selector", "now": now(), "all": []string{"a", "b"}},
		}})
	})
	mux.HandleFunc("/proxies/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPut {
			http.NotFound(w, r)
			return
		}
		var body struct {
			Name string `json:"name"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		if err := os.WriteFile(cfg.State, []byte(body.Name), 0o600); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	})
	listener, err := net.Listen("tcp", cfg.Addr)
	if err != nil {
		return 4
	}
	_ = http.Serve(listener, mux)
	return 0
}

type fakeClashDriver struct{ state string }

func (fakeClashDriver) Kind() engine.Kind { return engine.KindMihomo }

func (d fakeClashDriver) Render(_ *engine.Plan, rt supervise.Runtime) ([]byte, error) {
	return json.Marshal(fakeClashConfig{Addr: rt.ControlAddr, State: d.state})
}

func (fakeClashDriver) RunArgs(supervise.Runtime) []string   { return []string{fakeClashFlag, "run"} }
func (fakeClashDriver) CheckArgs(supervise.Runtime) []string { return []string{fakeClashFlag, "check"} }

func (fakeClashDriver) Handshake(ctx context.Context, rt supervise.Runtime) (string, error) {
	info, err := For(rt).Version(ctx)
	return info.Version, err
}

func (fakeClashDriver) Reload(context.Context, supervise.Runtime, []byte) error {
	return supervise.ErrReloadUnsupported
}

func clashSelectedPlan() *engine.Plan {
	return &engine.Plan{
		SessionID:  "selected",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Options:    engine.Options{LogLevel: "warning", Mode: "rule", TestURL: engine.TestURLProduction},
		Outbounds: []engine.Outbound{
			{ID: "a", Name: "a", Protocol: engine.ProtocolSOCKS5, Server: "198.51.100.1", Port: 1080, UserID: "u", Password: "p"},
			{ID: "b", Name: "b", Protocol: engine.ProtocolSOCKS5, Server: "198.51.100.2", Port: 1080, UserID: "u", Password: "p"},
		},
		Groups: []engine.Group{
			{Name: "pick", Type: engine.GroupSelect, Outbounds: []string{"a", "b"}, Selected: "b"},
		},
		Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "pick"}},
	}
}

func newFakeClashEngine(t *testing.T, state string) *Engine {
	t.Helper()
	sup, err := supervise.New(supervise.Config{
		Binary:        supervise.Binary{Kind: engine.KindMihomo, Path: os.Args[0]},
		HomeDir:       t.TempDir(),
		StartTimeout:  10 * time.Second,
		StopGrace:     time.Second,
		RestartBudget: 1,
		RestartWindow: time.Minute,
	}, fakeClashDriver{state: state})
	if err != nil {
		t.Fatalf("supervise.New: %v", err)
	}
	eng := NewEngine(sup)
	t.Cleanup(func() { _ = eng.Close() })
	return eng
}

func readSelection(t *testing.T, state string) string {
	t.Helper()
	data, err := os.ReadFile(state)
	if err != nil {
		t.Fatalf("reading the fake engine's selection: %v", err)
	}
	return string(data)
}

func TestApplyPinsThePlannedSelection(t *testing.T) {
	state := filepath.Join(t.TempDir(), "selection")
	// The engine cache holds "a" from an earlier session; the new plan
	// selects "b", and b must win at Connect.
	if err := os.WriteFile(state, []byte("a"), 0o600); err != nil {
		t.Fatal(err)
	}
	eng := newFakeClashEngine(t, state)
	if err := eng.Apply(context.Background(), clashSelectedPlan()); err != nil {
		t.Fatalf("Apply: %v", err)
	}
	if got := readSelection(t, state); got != "b" {
		t.Fatalf("effective selection after Apply = %q, want the plan's Selected b", got)
	}
	groups, err := eng.Groups(context.Background())
	if err != nil {
		t.Fatalf("Groups: %v", err)
	}
	for _, g := range groups {
		if g.Name == "pick" && g.Selected != "b" {
			t.Fatalf("Groups reports selected = %q, want b", g.Selected)
		}
	}

	// A runtime fast switch moves the group, and a re-Apply of the same
	// plan (a session reconnect) must not undo it.
	if err := eng.Select(context.Background(), "pick", "a"); err != nil {
		t.Fatalf("Select: %v", err)
	}
	if err := eng.Apply(context.Background(), clashSelectedPlan()); err != nil {
		t.Fatalf("re-Apply: %v", err)
	}
	if got := readSelection(t, state); got != "a" {
		t.Fatalf("effective selection after re-Apply = %q, want the runtime choice a", got)
	}

	// A fresh engine instance (a new session) with the same plan pins
	// the plan's member again, over the cached runtime choice.
	fresh := newFakeClashEngine(t, state)
	if err := fresh.Apply(context.Background(), clashSelectedPlan()); err != nil {
		t.Fatalf("fresh Apply: %v", err)
	}
	if got := readSelection(t, state); got != "b" {
		t.Fatalf("effective selection for a fresh session = %q, want the plan's Selected b", got)
	}
}
