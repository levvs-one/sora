package engine

import (
	"encoding/json"
	"slices"
	"strings"
)

// profileKeys are the fields of an Xray configuration that carry credentials.
var profileKeys = []string{
	"id", "password", "pass", "user", "publicKey", "privateKey",
	"shortId", "preSharedKey", "secretKey", "spiderX", "seed",
}

// profileSecrets extracts profile credentials for redacting engine output.
func profileSecrets(raw json.RawMessage) []string {
	if len(raw) == 0 {
		return nil
	}
	var v any
	if json.Unmarshal(raw, &v) != nil {
		return nil
	}
	var out []string
	var walk func(any)
	walk = func(v any) {
		switch x := v.(type) {
		case map[string]any:
			for k, value := range x {
				if s, ok := value.(string); ok && slices.ContainsFunc(profileKeys, func(name string) bool { return strings.EqualFold(k, name) }) {
					out = append(out, s)
					continue
				}
				walk(value)
			}
		case []any:
			for _, value := range x {
				walk(value)
			}
		}
	}
	walk(v)
	return out
}
