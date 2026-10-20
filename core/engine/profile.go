package engine

import (
	"encoding/json"
	"sort"
	"strings"
)

// profileKeys are the fields of an Xray configuration that carry
// credentials. Keys are matched in normalized form (lowercase, "-"
// and "_" stripped), so every spelling a hand-written or generated
// profile uses — preSharedKey, pre_shared_key, pre-shared-key —
// resolves to the same entry. The old exact-spelling map missed
// every variant it did not enumerate, and missed whole fields
// (token, uuid, encryption) entirely: a profile credential under a
// missed key was never registered with the redactor and reached
// engine logs verbatim (CENSOR-LEAK).
var profileKeys = map[string]bool{
	"id": true, "password": true, "pass": true, "user": true,
	"publickey": true, "privatekey": true, "shortid": true,
	"presharedkey": true, "secretkey": true, "spiderx": true,
	"seed": true, "token": true, "auth": true, "apikey": true,
	"accesstoken": true, "refreshtoken": true, "sessiontoken": true,
	"uuid": true, "encryption": true, "psk": true,
}

// profileIdentifierKeys are the profile fields that identify a server
// or a target rather than authenticate: the endpoint address, the
// TLS/REALITY server names and dest, the transport host. They belong
// with Identifiers, not Secrets — the same distinction the plan
// fields draw — but they must be registered either way: before this,
// a profile's server address and REALITY dest were extracted
// nowhere, so engine output naming them was never masked.
var profileIdentifierKeys = map[string]bool{
	"address": true, "server": true, "servername": true,
	"servernames": true, "sni": true, "dest": true, "host": true,
}

// normalizeProfileKey folds a JSON key to its canonical form.
func normalizeProfileKey(k string) string {
	k = strings.ToLower(k)
	k = strings.ReplaceAll(k, "_", "")
	return strings.ReplaceAll(k, "-", "")
}

// profileWalk visits every string value filed under a key whose
// normalized form is in keys, anywhere in the profile JSON.
func profileWalk(raw json.RawMessage, keys map[string]bool) []string {
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
			// Keys are visited in sorted order: Go map iteration is
			// randomized, and Secrets()/Identifiers() feed ordered
			// redactor registration and tests — the same profile must
			// yield the same lists on every run (determinism rule).
			names := make([]string, 0, len(x))
			for k := range x {
				names = append(names, k)
			}
			sort.Strings(names)
			for _, k := range names {
				value := x[k]
				if !keys[normalizeProfileKey(k)] {
					walk(value)
					continue
				}
				switch s := value.(type) {
				case string:
					out = append(out, s)
				case []any:
					// serverNames and similar list fields.
					for _, e := range s {
						if str, ok := e.(string); ok {
							out = append(out, str)
						}
					}
				}
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

// profileSecrets extracts profile credentials for redacting engine output.
func profileSecrets(raw json.RawMessage) []string {
	return profileWalk(raw, profileKeys)
}

// profileIdentifiers extracts profile server/target identifiers for
// redacting engine output alongside the plan's own identifiers.
func profileIdentifiers(raw json.RawMessage) []string {
	return profileWalk(raw, profileIdentifierKeys)
}
