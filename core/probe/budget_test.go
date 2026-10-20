package probe

import (
	"context"
	"crypto/tls"
	"testing"
	"time"
)

// TestHandshakeLimiterCapsPerSNI pins the budget semantics the dial
// paths rely on: at most N concurrent slots per normalized SNI,
// independent budgets per SNI, and a bounded wait — never a deadlock —
// when the budget is saturated.
func TestHandshakeLimiterCapsPerSNI(t *testing.T) {
	l := NewHandshakeLimiter(2, 50*time.Millisecond)
	ctx := context.Background()
	r1, err := l.Acquire(ctx, "Dest.Test.")
	if err != nil {
		t.Fatal(err)
	}
	r2, err := l.Acquire(ctx, "dest.test")
	if err != nil {
		t.Fatal(err)
	}
	if got := l.InFlight("DEST.test"); got != 2 {
		t.Fatalf("InFlight = %d, want 2 (normalization must unify the key)", got)
	}
	if _, err := l.Acquire(ctx, "dest.test"); err == nil {
		t.Fatal("third parallel acquire on one SNI must time out, not succeed")
	}
	// A different SNI has its own budget.
	r3, err := l.Acquire(ctx, "other.test")
	if err != nil {
		t.Fatalf("different SNI must not contend: %v", err)
	}
	r3()
	r1()
	// A released slot can be taken again.
	r4, err := l.Acquire(ctx, "dest.test")
	if err != nil {
		t.Fatalf("acquire after release: %v", err)
	}
	r4()
	r2()
}

// TestDefaultDestLimiterIsTheSharedInstance pins CENSOR-SURV review
// Medium 2 on the probe side: the dest checker's production limiter
// is the single process-wide instance, not a private second budget.
// (The censor side — DefaultHandshakeBudget being the same object,
// and the combined cap across both paths — is pinned in
// core/censor's budget_shared_test.go.)
func TestDefaultDestLimiterIsTheSharedInstance(t *testing.T) {
	if destHandshakeLimiter != DefaultHandshakeLimiter {
		t.Fatal("destHandshakeLimiter must default to DefaultHandshakeLimiter (one budget per process)")
	}
}

// TestCheckDestRespectsHandshakeBudget proves the dest checker really
// acquires: with the budget for the dest saturated, the check fails
// with the budget error and never dials.
func TestCheckDestRespectsHandshakeBudget(t *testing.T) {
	old := destHandshakeLimiter
	destHandshakeLimiter = NewHandshakeLimiter(1, 20*time.Millisecond)
	t.Cleanup(func() { destHandshakeLimiter = old })

	hold, err := destHandshakeLimiter.Acquire(context.Background(), "dest.test")
	if err != nil {
		t.Fatal(err)
	}
	defer hold()

	dialed := false
	_, err = checkDest(context.Background(), "dest.test", localResolve,
		func(context.Context, string, *tls.Config) (*tls.Conn, error) {
			dialed = true
			return nil, nil
		}, nil)
	if err == nil {
		t.Fatal("saturated budget must fail the dest check")
	}
	if dialed {
		t.Fatal("no handshake may be attempted without a budget slot")
	}
}
