package ext

import (
	"testing"
	"time"
)

// TestTokenExpires bounds the damage of a leaked token: it stops working
// after TokenTTL, and Verify drops it.
func TestTokenExpires(t *testing.T) {
	iss := NewTokenIssuer()
	tok, err := iss.Mint("com.example.hello", []string{"servers.read"})
	if err != nil {
		t.Fatalf("mint: %v", err)
	}
	g, ok := iss.Verify(tok)
	if !ok {
		t.Fatal("fresh token must verify")
	}
	if g.ExpiresAt.Sub(g.IssuedAt) != TokenTTL {
		t.Errorf("token lifetime = %s, want %s", g.ExpiresAt.Sub(g.IssuedAt), TokenTTL)
	}
	if TokenTTL != 24*time.Hour {
		t.Errorf("TokenTTL = %s, want 24h (a leaked token must not live for weeks)", TokenTTL)
	}

	// Age the grant past its TTL (white-box: same package).
	iss.mu.Lock()
	for k, grant := range iss.tokens {
		grant.ExpiresAt = time.Now().Add(-time.Hour)
		iss.tokens[k] = grant
	}
	iss.mu.Unlock()
	if _, ok := iss.Verify(tok); ok {
		t.Fatal("expired token must not verify")
	}
	iss.mu.Lock()
	n := len(iss.tokens)
	iss.mu.Unlock()
	if n != 0 {
		t.Errorf("expired token must be dropped on verify, %d remain", n)
	}
}

func TestGrantExpired(t *testing.T) {
	now := time.Now()
	if (&Grant{ExpiresAt: now.Add(time.Hour)}).Expired(now) {
		t.Error("future expiry must not be expired")
	}
	if !(&Grant{ExpiresAt: now}).Expired(now) {
		t.Error("expiry exactly now must count as expired (fail closed)")
	}
	if !(&Grant{ExpiresAt: now.Add(-time.Second)}).Expired(now) {
		t.Error("past expiry must be expired")
	}
}

// TestMintSweepsExpiredTokens keeps the issuer map from growing without
// bound when tokens are minted but never verified.
func TestMintSweepsExpiredTokens(t *testing.T) {
	iss := NewTokenIssuer()
	if _, err := iss.Mint("com.example.old", nil); err != nil {
		t.Fatalf("mint: %v", err)
	}
	iss.mu.Lock()
	for k, grant := range iss.tokens {
		grant.ExpiresAt = time.Now().Add(-time.Hour)
		iss.tokens[k] = grant
	}
	nBefore := len(iss.tokens)
	iss.mu.Unlock()
	if nBefore != 1 {
		t.Fatalf("setup: want 1 token, got %d", nBefore)
	}
	if _, err := iss.Mint("com.example.new", nil); err != nil {
		t.Fatalf("mint: %v", err)
	}
	iss.mu.Lock()
	n := len(iss.tokens)
	iss.mu.Unlock()
	if n != 1 {
		t.Errorf("mint must sweep expired tokens, have %d", n)
	}
}
