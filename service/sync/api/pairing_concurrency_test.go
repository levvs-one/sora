package api

// Concurrency regression tests for pairing session lifecycle: a stale TTL
// watcher must never close the session that replaced its own.

import "testing"

// TestStalePairingTTLDoesNotKillNewSession simulates the race where session
// A's TTL fires just as the user stops A and starts B: the stale watcher
// for A must leave B alone.
func TestStalePairingTTLDoesNotKillNewSession(t *testing.T) {
	d, _, _ := testDaemon(t)

	if _, _, err := d.StartPairing(); err != nil {
		t.Fatal(err)
	}
	d.mu.Lock()
	old := d.pairing
	d.mu.Unlock()
	if old == nil {
		t.Fatal("no pairing session after StartPairing")
	}
	if err := d.StopPairing(); err != nil {
		t.Fatal(err)
	}
	if _, _, err := d.StartPairing(); err != nil {
		t.Fatal(err)
	}
	// The stale watcher for the old session fires now.
	if err := d.stopPairingSession(old); err != nil {
		t.Fatal(err)
	}
	if active, _ := d.PairingActive(); !active {
		t.Fatal("stale TTL watcher killed the new pairing session")
	}
	// Sanity: stopping the current session still works.
	if err := d.StopPairing(); err != nil {
		t.Fatal(err)
	}
	if active, _ := d.PairingActive(); active {
		t.Fatal("pairing should be inactive after StopPairing")
	}
}
