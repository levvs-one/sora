package engine

import (
	"encoding/json"
	"slices"
	"strings"
	"testing"
)

func TestProfileSecretKeyAliasesAreRegisteredForRedaction(t *testing.T) {
	for _, key := range []string{"password", "PASSWORD", "PublicKey", "PUBLICKEY", "publicKey", "SecretKey", "ſecretKey", "SEED", "ſeed"} {
		t.Run(key, func(t *testing.T) {
			raw, err := json.Marshal(map[string]any{"outbounds": []any{map[string]any{"settings": map[string]any{key: "fixture-secret-value"}}}})
			if err != nil {
				t.Fatal(err)
			}
			outbound := Outbound{Protocol: ProtocolXrayProfile, Profile: raw}
			secrets := outbound.Secrets()
			if !slices.Contains(secrets, "fixture-secret-value") {
				t.Fatal("profile credential alias was not registered")
			}
			if strings.Contains(NewRedactor(secrets...).String("engine error: fixture-secret-value"), "fixture-secret-value") {
				t.Fatal("profile credential escaped value-based redaction")
			}
		})
	}
}
