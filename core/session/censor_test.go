package session

import (
	"context"
	"net"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/censor"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

func TestCensorActionFor(t *testing.T) {
	cases := []struct {
		name string
		code errs.Code
		key  errs.Key
		want censorAction
	}{
		{"timeout probes", errs.CodeTimeout, errs.KeyNetworkTimeout, censorProbe},
		{"network failure probes", errs.CodeUnavailable, errs.KeyNetworkFailed, censorProbe},
		{"tls abort probes", errs.CodeTLS, "core.tls.handshake", censorProbe},
		{"refused answers directly", errs.CodeUnavailable, errs.KeyConnectionRefused, censorRefused},
		{"certificate is skipped", errs.CodeTLS, errs.KeyTLSCertificate, censorSkip},
		{"engine crash is skipped", errs.CodeUnavailable, errs.KeyEngineStopped, censorSkip},
		{"bad plan is skipped", errs.CodeInvalidArgument, errs.KeyPlanOutbounds, censorSkip},
	}
	for _, c := range cases {
		if got := censorActionFor(c.code, c.key); got != c.want {
			t.Errorf("%s: action = %v, want %v", c.name, got, c.want)
		}
	}
}

func TestCensorTargetOf(t *testing.T) {
	plan := testPlan("s1")
	plan.Outbounds[0].Server = "de1.example.com"
	plan.Outbounds[0].Port = 443
	plan.Outbounds[0].TLS = engine.TLS{Enabled: true, ServerName: "de1.example.com"}
	plan.Outbounds[0].Protocol = engine.ProtocolVLESS
	target, ok := censorTargetOf(plan)
	if !ok {
		t.Fatal("want a target from a valid plan")
	}
	if target.Host != "de1.example.com" || target.Port != 443 || !target.TLS || target.SNI != "de1.example.com" {
		t.Fatalf("target = %+v", target)
	}
	if _, ok := censorTargetOf(nil); ok {
		t.Fatal("nil plan must not yield a target")
	}
	empty := &engine.Plan{}
	if _, ok := censorTargetOf(empty); ok {
		t.Fatal("plan without outbounds must not yield a target")
	}
}

// rstListener accepts connections and RSTs them at once.
func rstListener(t *testing.T) (net.Listener, int) {
	t.Helper()
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Skipf("no loopback: %v", err)
	}
	go func() {
		for {
			c, err := l.Accept()
			if err != nil {
				return
			}
			if tc, ok := c.(*net.TCPConn); ok {
				_ = tc.SetLinger(0)
			}
			_ = c.Close()
		}
	}()
	return l, l.Addr().(*net.TCPAddr).Port
}

func waitForCensorEvent(t *testing.T, s *Session, cursor uint64, timeout time.Duration) Event {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		for _, e := range s.Journal().Since(cursor, 0) {
			if e.Kind == EventCensor {
				return e
			}
		}
		time.Sleep(50 * time.Millisecond)
	}
	t.Fatal("no censorship verdict published to the journal")
	return Event{}
}

func TestWatcherProbesNetworkFailure(t *testing.T) {
	l, port := rstListener(t)
	defer l.Close()

	plan := testPlan("session-censor")
	plan.Outbounds[0].Server = "127.0.0.1"
	plan.Outbounds[0].Port = uint16(port)
	plan.Outbounds[0].TLS = engine.TLS{}
	cfg := testConfig(newFakeEngine(), &fakeGuard{})
	cfg.Plan = plan
	s, err := New(cfg)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	ctx := context.Background()
	if err := s.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = s.Stop(ctx) }()

	s.WatchCensorshipFailures(&censor.Detector{}, &censor.Prober{
		DialTimeout:      2 * time.Second,
		HandshakeTimeout: 2 * time.Second,
		ResolveTimeout:   2 * time.Second,
	})
	cursor := s.Journal().Latest()
	s.Journal().Append(Event{
		Kind:   EventError,
		Reason: errs.CodeTimeout,
		Key:    errs.KeyNetworkTimeout,
		Detail: "dial timeout",
	})

	ev := waitForCensorEvent(t, s, cursor, 15*time.Second)
	if ev.Censor == nil {
		t.Fatal("censor event must carry the structured verdict")
	}
	if ev.Censor.Kind != censor.KindRSTInjection {
		t.Fatalf("kind = %v, want rst_injection for the RSTing listener", ev.Censor.Kind)
	}
	if !strings.HasPrefix(ev.Detail, "censorship check:") {
		t.Fatalf("detail = %q, want the user-facing line", ev.Detail)
	}
}

// A refusing server is evidence against censorship: the watcher answers
// directly, without spending a probe.
func TestWatcherRefusedNeedsNoProbe(t *testing.T) {
	s, err := New(testConfig(newFakeEngine(), &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	ctx := context.Background()
	if err := s.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = s.Stop(ctx) }()

	s.WatchCensorshipFailures(&censor.Detector{}, &censor.Prober{})
	cursor := s.Journal().Latest()
	s.Journal().Append(Event{
		Kind:   EventError,
		Reason: errs.CodeUnavailable,
		Key:    errs.KeyConnectionRefused,
		Detail: "connection refused",
	})

	ev := waitForCensorEvent(t, s, cursor, 5*time.Second)
	if ev.Censor == nil || ev.Censor.Kind != censor.KindNoInterference {
		t.Fatalf("verdict = %+v, want no_interference without a probe", ev.Censor)
	}
	if ev.Censor.HasProfile {
		t.Fatalf("no_interference must not suggest a preset")
	}
}

// Local failures are not censorship questions: the watcher stays silent.
func TestWatcherIgnoresLocalFailures(t *testing.T) {
	s, err := New(testConfig(newFakeEngine(), &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	ctx := context.Background()
	if err := s.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = s.Stop(ctx) }()

	s.WatchCensorshipFailures(&censor.Detector{}, &censor.Prober{})
	before := s.Journal().Latest()
	s.Journal().Append(Event{
		Kind:   EventError,
		Reason: errs.CodeUnavailable,
		Key:    errs.KeyEngineStopped,
		Detail: "engine exited",
	})
	time.Sleep(300 * time.Millisecond)
	for _, e := range s.Journal().Since(before, 64) {
		if e.Kind == EventCensor {
			t.Fatalf("a local engine failure must not produce a censorship verdict: %+v", e.Censor)
		}
	}
}

// A flapping closed port must not flood the journal: the direct refused
// verdict shares the one-per-minute budget with probes.
func TestWatcherRefusedVerdictIsRateLimited(t *testing.T) {
	s, err := New(testConfig(newFakeEngine(), &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	ctx := context.Background()
	if err := s.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = s.Stop(ctx) }()

	s.WatchCensorshipFailures(&censor.Detector{}, &censor.Prober{})
	before := s.Journal().Latest()
	for i := 0; i < 3; i++ {
		s.Journal().Append(Event{
			Kind:   EventError,
			Reason: errs.CodeUnavailable,
			Key:    errs.KeyConnectionRefused,
			Detail: "connection refused",
		})
	}
	deadline := time.Now().Add(5 * time.Second)
	for {
		n := 0
		for _, e := range s.Journal().Since(before, 64) {
			if e.Kind == EventCensor {
				n++
			}
		}
		if n == 1 {
			return // the first verdict landed; the rest must stay suppressed
		}
		if n > 1 {
			t.Fatalf("got %d censor verdicts for 3 refused errors, want at most 1 per minute", n)
		}
		if time.Now().After(deadline) {
			t.Fatal("no censorship verdict published for the refused errors")
		}
		time.Sleep(50 * time.Millisecond)
	}
}
