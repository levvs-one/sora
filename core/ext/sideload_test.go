package ext

import (
	"strings"
	"testing"
)

func TestAuthorKeyFingerprintFormat(t *testing.T) {
	keyID, fp, err := AuthorKeyFingerprint(testPubKeyLine(t))
	if err != nil {
		t.Fatalf("fingerprint: %v", err)
	}
	if len(keyID) != 16 {
		t.Errorf("key id should be 16 hex chars, got %q", keyID)
	}
	groups := strings.Split(fp, ":")
	if len(groups) != 16 {
		t.Fatalf("fingerprint should be 16 groups, got %q", fp)
	}
	for _, g := range groups {
		if len(g) != 4 {
			t.Errorf("fingerprint group %q should be 4 hex chars", g)
		}
		for _, c := range g {
			if !strings.ContainsRune("0123456789ABCDEF", c) {
				t.Errorf("fingerprint group %q is not uppercase hex", g)
			}
		}
	}
	// Deterministic for the same key.
	_, fp2, err := AuthorKeyFingerprint(testPubKeyLine(t))
	if err != nil || fp2 != fp {
		t.Error("fingerprint must be deterministic")
	}
}

func TestAuthorKeyFingerprintRejectsGarbage(t *testing.T) {
	for _, bad := range []string{"", "not-base64!!!", "aGk="} {
		if _, _, err := AuthorKeyFingerprint(bad); err == nil {
			t.Errorf("expected rejection for %q", bad)
		}
	}
}

func TestSideloadConsentFacts(t *testing.T) {
	m := testManifest(t)
	m.Permissions = []string{"routing.rules", "connections.read", "notifications", "servers.read"}
	facts, err := SideloadConsent(m)
	if err != nil {
		t.Fatalf("consent: %v", err)
	}
	if !facts.SelfAttested {
		t.Error("sideload consent must always be marked self-attested")
	}
	if facts.AuthorName != "Example" || facts.AuthorID != "github:example" {
		t.Errorf("author facts wrong: %+v", facts)
	}
	if facts.KeyID == "" || facts.Fingerprint == "" {
		t.Error("consent must show the author key id and fingerprint")
	}
	// Dangerous permissions come first.
	if len(facts.Permissions) != 4 {
		t.Fatalf("expected 4 permission facts, got %d", len(facts.Permissions))
	}
	if facts.Permissions[0].ID != "routing.rules" || facts.Permissions[0].Risk != RiskDangerous {
		t.Errorf("dangerous permission must sort first: %+v", facts.Permissions[0])
	}
	// Every permission gets a concrete consequence, not a code word.
	for _, p := range facts.Permissions {
		if p.Consequence == "" || p.Consequence == p.ID {
			t.Errorf("permission %q needs a concrete consequence", p.ID)
		}
	}
	// The warning block names the catalog gap and the self-attestation gap.
	joined := strings.Join(facts.Risks, "\n")
	if !strings.Contains(joined, "Not from the Sora catalog") {
		t.Error("risks must state the package is not from the catalog")
	}
	if !strings.Contains(joined, "self-attested") {
		t.Error("risks must explain self-attestation")
	}
	if !strings.Contains(joined, "routing.rules") {
		t.Error("risks must call out the dangerous permission by name")
	}
}

func TestSideloadConsentRejectsNil(t *testing.T) {
	if _, err := SideloadConsent(nil); err == nil {
		t.Error("expected rejection for nil manifest")
	}
}
