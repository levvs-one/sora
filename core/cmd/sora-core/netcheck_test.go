package main

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/probe"
)

// stubQUICProbe replaces the network probe for the duration of a
// test: sandboxed kernels may refuse loopback UDP replies outright
// (sendto: operation not permitted), which is why the probe package
// tests its wire logic through injected dials too. The stub returns
// a fixed verdict and, for Blocked, records the ban in the tracker
// exactly like the real probe does.
func stubQUICProbe(t *testing.T, verdict probe.Verdict) {
	t.Helper()
	old := quicProbeFn
	quicProbeFn = func(_ context.Context, host string, port int, tracker *probe.BanTracker) (*probe.QUICResult, error) {
		res := &probe.QUICResult{Host: host, Port: port, Verdict: verdict, LocalPort: 40000, Remote: "203.0.113.7:443", RTT: time.Millisecond}
		if verdict == probe.VerdictBlocked && tracker != nil {
			tracker.NoteBlocked(res.LocalPort, res.Remote)
		}
		return res, nil
	}
	t.Cleanup(func() { quicProbeFn = old })
}

// TestRunQUICProbeOpenVerdict: the operator trigger renders the
// verdict with its advice and leaves a ban tracker file in the data
// dir.
func TestRunQUICProbeOpenVerdict(t *testing.T) {
	stubQUICProbe(t, probe.VerdictOpen)
	dir := t.TempDir()
	lines, err := runQUICProbe(context.Background(), dir, "example.com")
	if err != nil {
		t.Fatal(err)
	}
	joined := strings.Join(lines, "\n")
	if !strings.Contains(joined, "verdict=open") || !strings.Contains(joined, "advice:") {
		t.Fatalf("lines = %q, want the open verdict with advice", joined)
	}
	if _, err := os.Stat(filepath.Join(dir, banTrackerFileName)); err != nil {
		t.Fatalf("ban tracker file must be persisted: %v", err)
	}
}

// TestRunQUICProbeBlockedRecordsReaction: a blocked verdict records
// the ban (visible in the saved tracker file a restart would load)
// and prints the reaction line — the chain event → record → rotate
// does not end at the verdict.
func TestRunQUICProbeBlockedRecordsReaction(t *testing.T) {
	stubQUICProbe(t, probe.VerdictBlocked)
	dir := t.TempDir()
	lines, err := runQUICProbe(context.Background(), dir, "example.com:443")
	if err != nil {
		t.Fatal(err)
	}
	joined := strings.Join(lines, "\n")
	if !strings.Contains(joined, "verdict=blocked") || !strings.Contains(joined, "reaction: the blocked 4-tuple was recorded") {
		t.Fatalf("lines = %q, want blocked verdict + reaction", joined)
	}
	restarted, n, err := probe.LoadBanTracker(filepath.Join(dir, banTrackerFileName))
	if err != nil || n != 1 || !restarted.Banned(40000, "203.0.113.7:443") {
		t.Fatalf("after the run, a restart must restore the ban: n=%d err=%v", n, err)
	}
}

// TestRunQUICProbeCorruptTrackerIsHonestReset: a corrupt tracker
// file produces a visible reset line and a working probe — never a
// silent empty start.
func TestRunQUICProbeCorruptTrackerIsHonestReset(t *testing.T) {
	stubQUICProbe(t, probe.VerdictOpen)
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, banTrackerFileName), []byte("{broken"), 0o600); err != nil {
		t.Fatal(err)
	}
	lines, err := runQUICProbe(context.Background(), dir, "example.com")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(strings.Join(lines, "\n"), "ban tracker state reset:") {
		t.Fatalf("lines = %v, want the honest reset line", lines)
	}
	if _, _, err := probe.LoadBanTracker(filepath.Join(dir, banTrackerFileName)); err != nil {
		t.Fatalf("tracker file must be valid after the run: %v", err)
	}
}

// TestRunQUICProbeMissingDataDir pins CENSOR-SURV review Medium 3:
// on a fresh operator run the data dir may not exist yet. The probe
// must still print its verdict (previously the tracker save failed
// and the verdict was lost entirely), and the tracker file is
// created inside the new dir.
func TestRunQUICProbeMissingDataDir(t *testing.T) {
	stubQUICProbe(t, probe.VerdictOpen)
	dir := filepath.Join(t.TempDir(), "does-not-exist")
	lines, err := runQUICProbe(context.Background(), dir, "example.com")
	if err != nil {
		t.Fatalf("missing data dir must not lose the verdict: %v", err)
	}
	joined := strings.Join(lines, "\n")
	if !strings.Contains(joined, "verdict=open") {
		t.Fatalf("lines = %q, want the open verdict", joined)
	}
	if _, err := os.Stat(filepath.Join(dir, banTrackerFileName)); err != nil {
		t.Fatalf("ban tracker file must be persisted in the created dir: %v", err)
	}
}

// TestRunQUICProbeSaveFailureKeepsVerdict: when the tracker cannot
// be saved at all (here the tracker path is blocked by a directory),
// the verdict is still returned, with the save failure as a warning
// line — persistence trouble is not a lost result.
func TestRunQUICProbeSaveFailureKeepsVerdict(t *testing.T) {
	stubQUICProbe(t, probe.VerdictBlocked)
	dir := t.TempDir()
	if err := os.Mkdir(filepath.Join(dir, banTrackerFileName), 0o700); err != nil {
		t.Fatal(err)
	}
	lines, err := runQUICProbe(context.Background(), dir, "example.com")
	if err != nil {
		t.Fatalf("a save failure must not fail the probe run: %v", err)
	}
	joined := strings.Join(lines, "\n")
	if !strings.Contains(joined, "verdict=blocked") {
		t.Fatalf("lines = %q, want the blocked verdict despite the save failure", joined)
	}
	if !strings.Contains(joined, "warning: ban tracker was not saved:") {
		t.Fatalf("lines = %q, want the save-failure warning line", joined)
	}
}

func TestQUICTargetParsing(t *testing.T) {
	if host, port, err := quicTarget("example.com"); err != nil || host != "example.com" || port != 443 {
		t.Fatalf("bare host = (%q, %d, %v), want example.com:443", host, port, err)
	}
	if host, port, err := quicTarget("example.com:8443"); err != nil || host != "example.com" || port != 8443 {
		t.Fatalf("host:port = (%q, %d, %v), want example.com:8443", host, port, err)
	}
	for _, bad := range []string{"", "example.com:0", "example.com:99999", "example.com:abc"} {
		if _, _, err := quicTarget(bad); err == nil {
			t.Errorf("target %q must be rejected", bad)
		}
	}
}
