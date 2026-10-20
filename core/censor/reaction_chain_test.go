package censor

import (
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/probe"
)

// TestFreezeReactionChain walks the whole event → policy → action
// chain end to end, one link at a time, so no link can silently
// detach ("detector exists, reaction doesn't"):
//
//  1. event: the shared recognizer confirms a freeze from dial
//     samples (parallel stalls, sequential success);
//  2. policy: FreezePolicy.Assess names the freeze and, while the
//     120 s backoff is hot, prescribes NO action — waiting is the
//     action, and any suggestion here would burn a fingerprint;
//  3. action (fingerprint): after the backoff the policy suggests
//     the next fingerprint from the single rotation list;
//  4. action (SNI): the pool burns the frozen SNI and rotates to
//     the next profile candidate;
//  5. action (failover): with rotations recorded and the pool
//     exhausted, the ladder's only remaining move is failover.
func TestFreezeReactionChain(t *testing.T) {
	now := time.Now()
	det := &probe.FreezeDetector{Now: func() time.Time { return now }}
	const sni = "dest.test"
	det.Observe(probe.FreezeSample{SNI: sni, Concurrent: 1, At: now})
	for i := 0; i < 2; i++ {
		det.Observe(probe.FreezeSample{SNI: sni, Concurrent: 6, Stalled: true, At: now})
	}
	pool := NewSNIPool([]string{sni, "alt.test"})
	policy := NewFreezePolicy(det)
	clock := now
	policy.now = func() time.Time { return clock }
	target := Target{Host: "203.0.113.7", Port: 443, SNI: sni, TLS: true}

	// Link 2: hot backoff — freeze named, no action prescribed.
	a := policy.Assess(target, "chrome")
	if !a.Freeze {
		t.Fatal("chain link 2: the policy must name the confirmed freeze")
	}
	if a.SuggestedFingerprint != "" {
		t.Fatalf("chain link 2: during backoff no fingerprint may be suggested, got %q (rotating now burns it)", a.SuggestedFingerprint)
	}
	if a.RetryAfter.Sub(now) < 100*time.Second {
		t.Fatalf("chain link 2: RetryAfter = %v, want the ~120s quiet period", a.RetryAfter)
	}

	// Link 3: backoff over — rotate the fingerprint, first step of
	// the single-sourced list (chrome is a suspect, firefox is head).
	clock = now.Add(3 * time.Minute)
	a = policy.Assess(target, "chrome")
	if a.SuggestedFingerprint != "firefox" {
		t.Fatalf("chain link 3: SuggestedFingerprint = %q, want firefox", a.SuggestedFingerprint)
	}
	policy.NoteRotation(sni)

	// Link 4: the SNI itself is burned in the pool and rotation
	// yields the alternate dest from the profile data.
	if next := pool.BurnAndRotate(sni); next != "alt.test" {
		t.Fatalf("chain link 4: pool rotation = %q, want alt.test", next)
	}
	if !pool.IsBad(sni) {
		t.Fatal("chain link 4: the frozen SNI must stay burned on this network")
	}

	// Link 5: a rotation was already applied and stalls continue —
	// the ladder escalates past fingerprint and SNI to failover.
	for i := 0; i < 4; i++ {
		det.Observe(probe.FreezeSample{SNI: sni, Concurrent: 6, Stalled: true, At: clock})
	}
	a = policy.Assess(target, "firefox")
	if !a.RotateSNI {
		t.Fatal("chain link 5: continued stalls after a rotation must escalate to SNI rotation")
	}
	policy.NoteRotation(sni)
	a = policy.Assess(target, "edge")
	if !a.Failover {
		t.Fatal("chain link 5: after two rotations the ladder must end at failover")
	}
	if next := pool.BurnAndRotate("alt.test"); next != "" {
		t.Fatalf("chain link 5: exhausted pool = %q, want empty (failover, not cycling)", next)
	}
}
