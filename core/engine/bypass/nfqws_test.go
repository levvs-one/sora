package bypass

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// fakeInterceptor records every Sync and can be told to fail them.
type fakeInterceptor struct {
	mu     sync.Mutex
	syncs  [][]QueueSpec
	sweeps int
	err    error
}

func (f *fakeInterceptor) Sync(_ context.Context, specs []QueueSpec) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.err != nil {
		return f.err
	}
	f.syncs = append(f.syncs, append([]QueueSpec(nil), specs...))
	return nil
}

func (f *fakeInterceptor) Sweep(context.Context) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.sweeps++
	return nil
}

func (f *fakeInterceptor) lastSync() []QueueSpec {
	f.mu.Lock()
	defer f.mu.Unlock()
	if len(f.syncs) == 0 {
		return nil
	}
	return f.syncs[len(f.syncs)-1]
}

func (f *fakeInterceptor) syncCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return len(f.syncs)
}

func writeScript(t *testing.T, name, body string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), name)
	if err := os.WriteFile(path, []byte(body), 0o755); err != nil {
		t.Fatal(err)
	}
	return path
}

// fakeNFQWS stands in for the nfqws binary: it stays alive until killed.
func fakeNFQWS(t *testing.T) string {
	return writeScript(t, "nfqws", "#!/bin/sh\nexec sleep 3600\n")
}

// nfqEngine builds a wrapped engine whose interceptor is the fake.
func nfqEngine(t *testing.T, bins Binaries) (*Engine, *fakeInterceptor) {
	t.Helper()
	fi := &fakeInterceptor{}
	e := Wrap(stubEngine{}, bins, t.TempDir(), nil)
	e.iceptOverride = fi
	return e, fi
}

func nfqPlan(strategies ...engine.BypassStrategy) *engine.Plan {
	p := &engine.Plan{}
	for i, s := range strategies {
		s := s
		p.Outbounds = append(p.Outbounds, engine.Outbound{
			ID: string(rune('a' + i)), Protocol: engine.ProtocolBypass, Bypass: &s,
		})
	}
	return p
}

func TestNFQWSExecutorRunsTheDefaultStrategy(t *testing.T) {
	e, fi := nfqEngine(t, Binaries{NFQWS: fakeNFQWS(t)})
	if err := e.Apply(context.Background(), nfqPlan(DefaultStrategy())); err != nil {
		t.Fatalf("apply: %v", err)
	}
	if got := len(e.filters); got != 1 {
		t.Fatalf("running filters = %d, want 1", got)
	}
	specs := fi.lastSync()
	if len(specs) != 1 || specs[0].Queue != queueBase || specs[0].TCPPorts != "80,443" || specs[0].UDPPorts != "443" {
		t.Fatalf("synced specs = %+v, want one queue %d with the default filters", specs, queueBase)
	}
	if fi.sweeps == 0 {
		t.Fatal("the startup sweep never ran")
	}
	// Re-applying the same plan must not restart the instance.
	for k := range e.filters {
		first := e.filters[k].proc
		if err := e.Apply(context.Background(), nfqPlan(DefaultStrategy())); err != nil {
			t.Fatalf("re-apply: %v", err)
		}
		if e.filters[k].proc != first {
			t.Fatal("re-apply restarted a running filter")
		}
	}
	if err := e.Close(); err != nil {
		t.Fatalf("close: %v", err)
	}
	if got := len(e.filters); got != 0 {
		t.Fatalf("filters after Close = %d, want 0", got)
	}
	if specs := fi.lastSync(); len(specs) != 0 {
		t.Fatalf("last sync after Close = %+v, want the table cleared", specs)
	}
}

func TestNFQWSExecutorDedupesAndAllocatesQueues(t *testing.T) {
	e, fi := nfqEngine(t, Binaries{NFQWS: fakeNFQWS(t)})
	quicOnly := engine.BypassStrategy{
		Desync: []string{"fake"}, FakeQUIC: "quic", FilterUDP: "443", FilterL7: "quic",
	}
	// Two outbounds share the default strategy; a third differs.
	p := nfqPlan(DefaultStrategy(), DefaultStrategy(), quicOnly)
	if err := e.Apply(context.Background(), p); err != nil {
		t.Fatalf("apply: %v", err)
	}
	defer func() { _ = e.Close() }()
	if got := len(e.filters); got != 2 {
		t.Fatalf("running filters = %d, want 2 (dedupe by rendered args)", got)
	}
	specs := fi.lastSync()
	if len(specs) != 2 || specs[0].Queue != queueBase || specs[1].Queue != queueBase+1 {
		t.Fatalf("synced specs = %+v, want queues %d and %d", specs, queueBase, queueBase+1)
	}
	// Dropping one strategy stops its instance, frees its queue, and
	// re-syncs the rules to the survivor alone.
	if err := e.Apply(context.Background(), nfqPlan(quicOnly)); err != nil {
		t.Fatalf("apply reduced plan: %v", err)
	}
	if got := len(e.filters); got != 1 {
		t.Fatalf("filters after reduction = %d, want 1", got)
	}
	specs = fi.lastSync()
	if len(specs) != 1 || specs[0].UDPPorts != "443" || specs[0].TCPPorts != "" {
		t.Fatalf("synced specs after reduction = %+v, want the QUIC-only survivor", specs)
	}
}

func TestNFQWSExecutorFailsClosedOnUnfilteredStrategy(t *testing.T) {
	e, fi := nfqEngine(t, Binaries{NFQWS: fakeNFQWS(t)})
	unfiltered := engine.BypassStrategy{Desync: []string{"split2"}}
	err := e.Apply(context.Background(), nfqPlan(unfiltered))
	if err == nil || !strings.Contains(err.Error(), "filter") {
		t.Fatalf("an unfiltered desync strategy must fail closed, got %v", err)
	}
	if len(e.filters) != 0 || fi.syncCount() != 0 {
		t.Fatal("a refused strategy started processes or rules")
	}
}

func TestNFQWSExecutorFailsClosedWhenRulesFail(t *testing.T) {
	e, fi := nfqEngine(t, Binaries{NFQWS: fakeNFQWS(t)})
	fi.err = errors.New("nft: operation not permitted")
	err := e.Apply(context.Background(), nfqPlan(DefaultStrategy()))
	if err == nil || !strings.Contains(err.Error(), "queue rules") {
		t.Fatalf("a rules failure must fail closed, got %v", err)
	}
	if len(e.filters) != 0 {
		t.Fatal("a filter started although its rules never landed")
	}
	// The queue must have been released: once nft recovers, the same
	// strategy gets the first queue again.
	fi.err = nil
	if err := e.Apply(context.Background(), nfqPlan(DefaultStrategy())); err != nil {
		t.Fatalf("apply after recovery: %v", err)
	}
	defer func() { _ = e.Close() }()
	if specs := fi.lastSync(); len(specs) != 1 || specs[0].Queue != queueBase {
		t.Fatalf("specs after recovery = %+v, want queue %d (released on failure)", specs, queueBase)
	}
}

func TestNFQWSExecutorFailsClosedWhenProcessDiesAtStartup(t *testing.T) {
	dying := writeScript(t, "nfqws", "#!/bin/sh\necho 'nfqws: cannot open queue 200' >&2\nexit 1\n")
	e, fi := nfqEngine(t, Binaries{NFQWS: dying})
	err := e.Apply(context.Background(), nfqPlan(DefaultStrategy()))
	if err == nil || !strings.Contains(err.Error(), "cannot open queue") {
		t.Fatalf("a startup death must fail closed with the reason, got %v", err)
	}
	if len(e.filters) != 0 {
		t.Fatal("a dead filter stayed registered")
	}
	// The rules must have been re-synced away from the dead queue:
	// traffic must never steer into a queue with nothing behind it.
	if specs := fi.lastSync(); len(specs) != 0 {
		t.Fatalf("last sync = %+v, want the dead queue's rules removed", specs)
	}
}

// capturingEngine records the plan the wrapper hands to the engine.
type capturingEngine struct {
	stubEngine
	applied *engine.Plan
}

func (c *capturingEngine) Apply(_ context.Context, p *engine.Plan) error {
	c.applied = p
	return nil
}

func TestMixedPlanRunsBothBackends(t *testing.T) {
	tpws := writeScript(t, "tpws", `#!/bin/sh
exec python3 - "$@" <<'EOF'
import socket, sys
port = 0
for a in sys.argv[1:]:
    if a.startswith("--port="):
        port = int(a.split("=", 1)[1])
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", port))
s.listen(5)
while True:
    c, _ = s.accept()
    c.close()
EOF
`)
	inner := &capturingEngine{}
	fi := &fakeInterceptor{}
	e := Wrap(inner, Binaries{TPWS: tpws, NFQWS: fakeNFQWS(t)}, t.TempDir(), nil)
	e.iceptOverride = fi

	legacy := engine.BypassStrategy{SplitPos: []string{"1"}}
	p := &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "legacy", Protocol: engine.ProtocolBypass, Bypass: &legacy},
		{ID: "modern", Protocol: engine.ProtocolBypass, Bypass: ptrStrategy(DefaultStrategy())},
	}}
	if err := e.Apply(context.Background(), p); err != nil {
		t.Fatalf("apply mixed plan: %v", err)
	}
	defer func() { _ = e.Close() }()
	if len(e.procs) != 1 || len(e.filters) != 1 {
		t.Fatalf("running: %d tpws, %d nfqws; want 1 and 1", len(e.procs), len(e.filters))
	}
	byID := map[string]engine.Outbound{}
	for _, o := range inner.applied.Outbounds {
		byID[o.ID] = o
	}
	if got := byID["legacy"]; got.Protocol != engine.ProtocolSOCKS5 || got.Server != "127.0.0.1" || got.Port == 0 {
		t.Fatalf("legacy outbound rewritten to %+v, want the tpws SOCKS5 proxy", got)
	}
	if got := byID["modern"]; got.Protocol != engine.ProtocolDirect {
		t.Fatalf("nfqws outbound rewritten to %+v, want direct (desync is at the packet layer)", got)
	}
}

func ptrStrategy(s engine.BypassStrategy) *engine.BypassStrategy { return &s }

func TestRewriteLeavesNFQWSOutboundsDirect(t *testing.T) {
	s := DefaultStrategy()
	p := &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "z", Name: "Zapret", Protocol: engine.ProtocolBypass, Bypass: &s},
	}}
	out := Rewrite(p, nil)
	if got := out.Outbounds[0]; got.Protocol != engine.ProtocolDirect || got.ID != "z" || got.Name != "Zapret" {
		t.Fatalf("nfqws outbound rewritten to %+v, want direct with identity kept", got)
	}
}

func BenchmarkNFQWSArgsRender(b *testing.B) {
	s := DefaultStrategy()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = NFQWSArgs(s, "/engines/zapret")
	}
}

func BenchmarkNFQWSKeyAndQueueRules(b *testing.B) {
	e := &Engine{home: "/zapret"}
	s := DefaultStrategy()
	spec := QueueSpec{Queue: queueBase, TCPPorts: s.FilterTCP, UDPPorts: s.FilterUDP}
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = e.nfqKey(s)
		_, _ = spec.AddRules()
	}
}

func BenchmarkRewriteMixedPlan(b *testing.B) {
	legacy := engine.BypassStrategy{SplitPos: []string{"1"}}
	modern := DefaultStrategy()
	p := &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "legacy", Protocol: engine.ProtocolBypass, Bypass: &legacy},
		{ID: "modern", Protocol: engine.ProtocolBypass, Bypass: &modern},
		{ID: "plain", Protocol: engine.ProtocolVLESS, Server: "example.com", Port: 443},
	}}
	ports := map[string]int{key(legacy): 4242}
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = Rewrite(p, ports)
	}
}
