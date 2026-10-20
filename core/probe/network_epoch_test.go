package probe

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// Fake network fingerprints, in the shape session.NetworkFingerprint
// produces (interface + address parts). The trackers treat the
// fingerprint as opaque data: only equality matters.
const (
	fakeNetA = "eth0 192.168.1.2,wlan0 10.0.0.2"
	fakeNetB = "eth0 172.16.0.2"
)

// frozenDetector returns a detector whose verdict for sni is Frozen,
// with a controllable clock.
func frozenDetector(now time.Time) *FreezeDetector {
	d := &FreezeDetector{Now: func() time.Time { return now }}
	d.Observe(FreezeSample{SNI: "dest.test", Concurrent: 1, At: now})
	for i := 0; i < 2; i++ {
		d.Observe(FreezeSample{SNI: "dest.test", Concurrent: 6, Stalled: true, At: now})
	}
	return d
}

// TestFreezeDetectorNetworkChangeDropsSamples: verdicts measured on
// one network must not survive a move — the freeze belonged to a
// path that no longer exists.
func TestFreezeDetectorNetworkChangeDropsSamples(t *testing.T) {
	now := time.Now()
	d := frozenDetector(now)
	if !d.Verdict("dest.test").Frozen {
		t.Fatal("precondition: detector must be frozen on network A")
	}
	if d.BindNetwork(fakeNetA) {
		t.Fatal("first bind only records the epoch, it must not drop state")
	}
	if !d.Verdict("dest.test").Frozen {
		t.Fatal("same-network bind must keep the verdict")
	}
	if d.BindNetwork(fakeNetA) {
		t.Fatal("re-binding the same network must not drop state")
	}
	if !d.BindNetwork(fakeNetB) {
		t.Fatal("a network change must report dropped state")
	}
	v := d.Verdict("dest.test")
	if v.Frozen || v.ParallelTotal != 0 || v.SequentialTotal != 0 {
		t.Fatalf("after a network change the verdict must be empty, got %+v", v)
	}
	if d.NetworkEpoch() != fakeNetB {
		t.Fatalf("epoch = %q, want %q", d.NetworkEpoch(), fakeNetB)
	}
	if d.BindNetwork("") {
		t.Fatal("an empty fingerprint (offline/unknown) must never invalidate")
	}
}

// TestBanTrackerNetworkChangeDropsBans: a residual ban is a property
// of one network's path; after a move the dialer must be free to use
// the same source port again.
func TestBanTrackerNetworkChangeDropsBans(t *testing.T) {
	b := NewBanTracker()
	b.NoteBlocked(40000, "203.0.113.7:443")
	if !b.Banned(40000, "203.0.113.7:443") {
		t.Fatal("precondition: tuple must be banned")
	}
	if b.BindNetwork(fakeNetA) || !b.Banned(40000, "203.0.113.7:443") {
		t.Fatal("first bind must keep the ban")
	}
	if !b.BindNetwork(fakeNetB) {
		t.Fatal("network change must report dropped bans")
	}
	if b.Banned(40000, "203.0.113.7:443") {
		t.Fatal("the ban belonged to the old network and must be gone")
	}
}

// TestBanTrackerPersistenceAcrossRestart: save → a brand-new tracker
// loaded from the file (the restart) still honors the ban; expired
// entries never resurrect.
func TestBanTrackerPersistenceAcrossRestart(t *testing.T) {
	path := filepath.Join(t.TempDir(), "ban.json")
	b := NewBanTracker()
	b.NoteBlocked(40000, "203.0.113.7:443")
	b.NoteBlocked(40001, "198.51.100.9:443")
	if err := SaveBanTracker(path, b); err != nil {
		t.Fatal(err)
	}
	restarted, restored, err := LoadBanTracker(path)
	if err != nil {
		t.Fatal(err)
	}
	if restored != 2 {
		t.Fatalf("restored = %d, want 2", restored)
	}
	if !restarted.Banned(40000, "203.0.113.7:443") || !restarted.Banned(40001, "198.51.100.9:443") {
		t.Fatal("bans must survive the restart")
	}
	// The file is owner-only: it reveals which remotes were banned.
	if info, err := os.Stat(path); err != nil || info.Mode().Perm() != 0o600 {
		t.Fatalf("ban file mode = %v, err %v, want 0600", info.Mode().Perm(), err)
	}
}

// TestBanTrackerLoadHonesty: a missing file is a first run (no error,
// no bans); a corrupt file is a loud error with no tracker, so the
// caller records the reset instead of starting empty in silence;
// already-expired entries in a valid file are dropped.
func TestBanTrackerLoadHonesty(t *testing.T) {
	dir := t.TempDir()
	fresh, n, err := LoadBanTracker(filepath.Join(dir, "absent.json"))
	if err != nil || n != 0 || fresh == nil {
		t.Fatalf("missing file = (%v, %d, %v), want a fresh tracker", fresh, n, err)
	}
	bad := filepath.Join(dir, "bad.json")
	if err := os.WriteFile(bad, []byte("{not json"), 0o600); err != nil {
		t.Fatal(err)
	}
	tr, _, err := LoadBanTracker(bad)
	if err == nil || tr != nil {
		t.Fatalf("corrupt file = (%v, %v), want nil tracker and an error", tr, err)
	}
	expired := filepath.Join(dir, "expired.json")
	past := time.Now().Add(-time.Minute).UTC().Format(time.RFC3339)
	body := `{"version":1,"saved_at":"` + past + `","entries":[{"key":"1->203.0.113.7:443","until":"` + past + `"}]}`
	if err := os.WriteFile(expired, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	tr, n, err = LoadBanTracker(expired)
	if err != nil || n != 0 || tr.Banned(1, "203.0.113.7:443") {
		t.Fatalf("expired entries must be dropped: n=%d err=%v", n, err)
	}
	if !strings.Contains(body, "203.0.113.7") {
		t.Fatal("test fixture sanity")
	}
}
