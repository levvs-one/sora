package control_test

// Tests for the obfuscation suite's WatchEvents signals: a corrupt
// obfs_profile.json at startup and a pinned engine that cannot carry the
// stored profile must surface in the session event stream instead of
// silently disabling or dropping defences.

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/control"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
	"github.com/levvs-one/sora-client/core/secret"
	"google.golang.org/grpc"
)

// obfsEventStream is a minimal WatchEvents sink: embedding the interface
// supplies the unneeded methods.
type obfsEventStream struct {
	grpc.ServerStreamingServer[corev1.CoreEvent]
	ctx  context.Context
	sent []*corev1.CoreEvent
}

func (s *obfsEventStream) Send(e *corev1.CoreEvent) error {
	s.sent = append(s.sent, e)
	return nil
}

func (s *obfsEventStream) Context() context.Context { return s.ctx }

// collectObfsEvents replays the running session's journal through
// WatchEvents and returns everything the server sent.
func collectObfsEvents(t *testing.T, server *control.Server) []*corev1.CoreEvent {
	t.Helper()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	stream := &obfsEventStream{ctx: ctx}
	done := make(chan error, 1)
	go func() {
		done <- server.WatchEvents(&corev1.WatchEventsRequest{ApiVersion: clientVersion()}, stream)
	}()
	// The history replay is synchronous; the sleep only lets the
	// subscriber goroutine get scheduled.
	time.Sleep(200 * time.Millisecond)
	cancel()
	if err := <-done; err != nil {
		t.Fatalf("WatchEvents() = %v", err)
	}
	return stream.sent
}

func obfsConnect(t *testing.T, server *control.Server, store *secret.Store, engines ...string) {
	t.Helper()
	plan := validPlan(t, store)
	// Application mode: the sandbox's host interface overlaps the TUN
	// FakeIP pool, so a system-mode plan cannot connect here. The
	// obfuscation merge is tunnel-mode independent.
	plan.TunnelMode = corev1.TunnelMode_TUNNEL_MODE_APPLICATION
	plan.Engines = engines
	res, err := server.Connect(context.Background(), &corev1.ConnectRequest{
		ApiVersion:           clientVersion(),
		SessionPlan:          plan,
		ControlAuthenticator: testToken,
	})
	if err != nil {
		t.Fatalf("Connect() error = %v", err)
	}
	if res.GetError() != nil {
		t.Fatalf("Connect() wire error = %v", res.GetError())
	}
}

func obfsLogLines(events []*corev1.CoreEvent) []string {
	var out []string
	for _, e := range events {
		if lb := e.GetLogBatch(); lb != nil {
			out = append(out, lb.GetLines()...)
		}
	}
	return out
}

func obfsLinesWith(lines []string, substrs ...string) []string {
	var matched []string
	for _, l := range lines {
		ok := true
		for _, sub := range substrs {
			if !strings.Contains(l, sub) {
				ok = false
				break
			}
		}
		if ok {
			matched = append(matched, l)
		}
	}
	return matched
}

func TestCorruptObfsProfileSurfacesInWatchEvents(t *testing.T) {
	for _, tc := range []struct {
		name    string
		content string
		want    string
	}{
		{"unparseable", "{not json", "corrupt"},
		{"invalid", `{"preset": 99}`, "invalid"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			dir := t.TempDir()
			if err := os.WriteFile(filepath.Join(dir, "obfs_profile.json"), []byte(tc.content), 0o600); err != nil {
				t.Fatal(err)
			}
			rec := &planRecorder{}
			server, store := newObfsTestServer(t, dir, rec)
			obfsConnect(t, server, store)

			lines := obfsLogLines(collectObfsEvents(t, server))
			if got := obfsLinesWith(lines, "obfs_profile.json", tc.want); len(got) == 0 {
				t.Errorf("no %q warning for the stored profile in WatchEvents; lines: %q", tc.want, lines)
			}

			// Applying a fresh profile clears the startup warning: the
			// next session must not repeat stale news.
			ctx := context.Background()
			res, err := server.ApplyObfsProfile(ctx, applyReq(&obfsv1.ObfuscationProfile{
				Preset: obfsv1.ObfsPreset_OBFS_PRESET_LIGHT,
			}))
			if err != nil || res.GetError() != nil {
				t.Fatalf("ApplyObfsProfile() = %v, %v", err, res.GetError())
			}
			obfsConnect(t, server, store)
			for _, l := range obfsLogLines(collectObfsEvents(t, server)) {
				if strings.Contains(l, "obfs_profile.json") {
					t.Errorf("stale stored-profile warning after Apply: %q", l)
				}
			}
		})
	}
}

func TestPinnedIncompatibleEngineWarnsAtConnect(t *testing.T) {
	ctx := context.Background()
	newServerWithProfile := func(t *testing.T, p *obfsv1.ObfuscationProfile) (*control.Server, *planRecorder, func(engines ...string)) {
		t.Helper()
		dir := t.TempDir()
		rec := &planRecorder{}
		server, store := newObfsTestServer(t, dir, rec)
		if p != nil {
			res, err := server.ApplyObfsProfile(ctx, applyReq(p))
			if err != nil || res.GetError() != nil {
				t.Fatalf("ApplyObfsProfile() = %v, %v", err, res.GetError())
			}
		}
		connect := func(engines ...string) {
			obfsConnect(t, server, store, engines...)
		}
		return server, rec, connect
	}

	t.Run("pinned mihomo drops fragmentation", func(t *testing.T) {
		// BALANCED enables fragmentation with delay and jitter: mihomo
		// carries none of the three.
		server, _, connect := newServerWithProfile(t, &obfsv1.ObfuscationProfile{
			Preset: obfsv1.ObfsPreset_OBFS_PRESET_BALANCED,
		})
		connect("mihomo")
		lines := obfsLogLines(collectObfsEvents(t, server))
		if got := obfsLinesWith(lines, `"mihomo"`, "TLS fragmentation"); len(got) == 0 {
			t.Errorf("no pinned-engine warning in WatchEvents; lines: %q", lines)
		}
	})

	t.Run("pinned xray carries everything", func(t *testing.T) {
		server, _, connect := newServerWithProfile(t, &obfsv1.ObfuscationProfile{
			Preset: obfsv1.ObfsPreset_OBFS_PRESET_BALANCED,
		})
		connect("xray")
		for _, l := range obfsLogLines(collectObfsEvents(t, server)) {
			if strings.Contains(l, "obfuscation: the preferred engine") {
				t.Errorf("spurious engine warning for a capable engine: %q", l)
			}
		}
	})

	t.Run("no pin means no warning", func(t *testing.T) {
		server, _, connect := newServerWithProfile(t, &obfsv1.ObfuscationProfile{
			Preset: obfsv1.ObfsPreset_OBFS_PRESET_BALANCED,
		})
		connect()
		for _, l := range obfsLogLines(collectObfsEvents(t, server)) {
			if strings.Contains(l, "obfuscation: the preferred engine") {
				t.Errorf("spurious engine warning without a pin: %q", l)
			}
		}
	})

	t.Run("disabled suite never warns", func(t *testing.T) {
		server, _, connect := newServerWithProfile(t, &obfsv1.ObfuscationProfile{
			Preset: obfsv1.ObfsPreset_OBFS_PRESET_OFF,
		})
		connect("mihomo")
		for _, l := range obfsLogLines(collectObfsEvents(t, server)) {
			if strings.Contains(l, "obfuscation: the preferred engine") {
				t.Errorf("spurious engine warning with the suite off: %q", l)
			}
		}
	})
}
