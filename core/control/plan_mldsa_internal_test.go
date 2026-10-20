package control

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/parser"
)

// TestMLDSA65VerifySurvivesTheVault pins the credential-document leg
// of the pqv import (CENSOR-P1): the verify key written by
// credentialDocument must come back as TLS.RealityMLDSA65Verify when
// the stored server is resolved into a plan outbound.
func TestMLDSA65VerifySurvivesTheVault(t *testing.T) {
	const verify = "pqv-vault-key"
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?security=reality" +
		"&pbk=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw&pqv=" + verify + "#PQ"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	document, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	values, err := parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	if o.TLS.RealityMLDSA65Verify != verify {
		t.Errorf("mldsa65Verify lost on the way to the engine: %+v", o.TLS)
	}
}
