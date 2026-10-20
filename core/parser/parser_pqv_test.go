package parser

import (
	"strings"
	"testing"
)

// TestParseLinkMLDSA65Verify pins the pqv import (CENSOR-P1): a vless
// link's post-quantum REALITY verification key lands on the spec
// instead of being dropped with the rest of the unrecognized query —
// dropping it would silently downgrade the server check the provider
// pinned.
func TestParseLinkMLDSA65Verify(t *testing.T) {
	const verify = "pqv-test-key"
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@example.com:443?security=reality" +
		"&pbk=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw&pqv=" + verify + "#PQ"
	r, err := (LinkParser{}).Parse([]byte(link))
	if err != nil || len(r.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", r, err)
	}
	if got := r.Servers[0].MLDSA65Verify; got != verify {
		t.Errorf("MLDSA65Verify = %q, want %q", got, verify)
	}
	if !strings.Contains(r.Servers[0].Options["pqv"], verify) {
		t.Error("the raw pqv option must stay visible in Options")
	}
}
