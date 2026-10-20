package engine

import (
	"encoding/base64"
	"testing"
)

func TestGenerateWireGuardPSK(t *testing.T) {
	a, err := GenerateWireGuardPSK()
	if err != nil {
		t.Fatalf("GenerateWireGuardPSK: %v", err)
	}
	b, err := GenerateWireGuardPSK()
	if err != nil {
		t.Fatalf("GenerateWireGuardPSK: %v", err)
	}
	if a == b {
		t.Error("two generated PSKs must differ")
	}
	// wg genpsk format: base64 of 32 bytes, padded to 44 chars.
	if len(a) != 44 {
		t.Errorf("PSK length = %d, want 44 (base64 of 32 bytes)", len(a))
	}
	raw, err := base64.StdEncoding.DecodeString(a)
	if err != nil {
		t.Fatalf("PSK is not padded base64: %v", err)
	}
	if len(raw) != 32 {
		t.Errorf("PSK decodes to %d bytes, want 32", len(raw))
	}
	if err := ValidateWireGuardPSK(a); err != nil {
		t.Errorf("generated PSK fails validation: %v", err)
	}
}

func TestValidateWireGuardPSK(t *testing.T) {
	good, err := GenerateWireGuardPSK()
	if err != nil {
		t.Fatalf("GenerateWireGuardPSK: %v", err)
	}
	raw, _ := base64.StdEncoding.DecodeString(good)
	unpadded := base64.RawStdEncoding.EncodeToString(raw)
	for _, tc := range []struct {
		name    string
		psk     string
		wantErr bool
	}{
		{"generated", good, false},
		{"unpadded", unpadded, false},
		{"empty means no PSK", "", false},
		{"not base64", "!!!not-base64!!!", true},
		{"too short", base64.StdEncoding.EncodeToString(make([]byte, 16)), true},
		{"too long", base64.StdEncoding.EncodeToString(make([]byte, 64)), true},
	} {
		if err := ValidateWireGuardPSK(tc.psk); (err != nil) != tc.wantErr {
			t.Errorf("%s: ValidateWireGuardPSK err = %v, wantErr = %v", tc.name, err, tc.wantErr)
		}
	}
}
