package engine

import (
	"encoding/base64"
	"strings"
	"testing"
)

// validMLDSA65Verify is a shape-valid ML-DSA-65 verification key:
// 1952 zero bytes in raw base64url (2603 characters). Validation is
// shape-only — key ownership is proven by the handshake signature the
// key enables, never by this check.
var validMLDSA65Verify = base64.RawURLEncoding.EncodeToString(make([]byte, mldsa65VerifyKeyBytes))

// TestValidateMLDSA65Verify pins the plan-level shape gate (CENSOR-P1):
// a malformed mldsa65Verify fails here instead of failing Xray's
// config load (probed on the pin: `invalid "mldsa65Verify"`), and the
// key without REALITY is a stray value no renderer can honour.
func TestValidateMLDSA65Verify(t *testing.T) {
	o := realityOutbound()
	o.TLS.RealityMLDSA65Verify = validMLDSA65Verify
	if err := o.ValidateReality(); err != nil {
		t.Errorf("valid mldsa65Verify: ValidateReality = %v, want nil", err)
	}
	if err := o.Validate(); err != nil {
		t.Errorf("valid mldsa65Verify: Validate = %v, want nil", err)
	}
	for _, bad := range []string{"AAAA", validMLDSA65Verify[:2600], "not+base64url!!!"} {
		o := realityOutbound()
		o.TLS.RealityMLDSA65Verify = bad
		if err := o.ValidateReality(); err == nil || !strings.Contains(err.Error(), "mldsa65Verify") {
			t.Errorf("mldsa65Verify %q...: ValidateReality = %v, want an mldsa65Verify error", bad[:8], err)
		}
	}
	o = realityOutbound()
	o.TLS.Reality = false
	o.TLS.RealityMLDSA65Verify = validMLDSA65Verify
	if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "mldsa65Verify needs REALITY") {
		t.Errorf("mldsa65Verify without REALITY: Validate = %v, want a needs-REALITY error", err)
	}
}

// TestMLDSA65VerifyRequiresXray pins the capability gate: only Xray
// carries the pinned ML-DSA-65 check, so sing-box and mihomo must
// report the feature missing instead of silently completing a weaker
// handshake.
func TestMLDSA65VerifyRequiresXray(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Outbounds[0].TLS.RealityMLDSA65Verify = validMLDSA65Verify
	if !p.RequiredFeatures()[FeatureRealityMLDSA65] {
		t.Fatal("a plan pinning mldsa65Verify must require FeatureRealityMLDSA65")
	}
	if missing := strings.Join(Catalog[KindXray].Missing(p), " "); strings.Contains(missing, string(FeatureRealityMLDSA65)) {
		t.Errorf("xray renders mldsa65Verify and must not report it missing: %q", missing)
	}
	for _, kind := range []Kind{KindSingBox, KindMihomo} {
		missing := strings.Join(Catalog[kind].Missing(p), " ")
		if !strings.Contains(missing, string(FeatureRealityMLDSA65)) {
			t.Errorf("%s must report %s missing, got %q", kind, FeatureRealityMLDSA65, missing)
		}
	}
	plain := validPlan()
	if plain.RequiredFeatures()[FeatureRealityMLDSA65] {
		t.Error("a plan without mldsa65Verify must not require the feature")
	}
}

// TestMLDSA65VerifyIsIdentifier: the verify key is public but names
// the server, so it joins the redaction identifiers like the REALITY
// public key and shortId.
func TestMLDSA65VerifyIsIdentifier(t *testing.T) {
	o := realityOutbound()
	o.TLS.RealityMLDSA65Verify = validMLDSA65Verify
	found := false
	for _, id := range o.Identifiers() {
		if id == validMLDSA65Verify {
			found = true
		}
	}
	if !found {
		t.Error("mldsa65Verify must be among the outbound identifiers for redaction")
	}
}
