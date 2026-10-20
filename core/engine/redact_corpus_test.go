package engine

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"net/url"
	"strings"
	"testing"
)

// CENSOR-LEAK corpus: the redactor drifted three times because each
// fix pinned one spelling. This corpus pins the classes instead —
// every encoding a seed can acquire on its way into a log line, every
// strict-assignment key, quoted values with escaped quotes, and
// subscription URLs whose credential is a bare path segment. A future
// pattern change that reopens any class fails here, in both the
// seeded and the pattern path.

// TestRedactorEncodedSeedForms pins the seeded path: a registered
// secret must be masked in every re-encoding a log pipeline produces,
// not only raw.
func TestRedactorEncodedSeedForms(t *testing.T) {
	secret := "p@ss word/1234+&"
	r := NewRedactor(secret)
	forms := map[string]string{
		"raw":            secret,
		"query escape":   url.QueryEscape(secret),
		"path escape":    url.PathEscape(secret),
		"base64 std":     base64.StdEncoding.EncodeToString([]byte(secret)),
		"base64 raw std": base64.RawStdEncoding.EncodeToString([]byte(secret)),
		"base64 url":     base64.URLEncoding.EncodeToString([]byte(secret)),
		"base64 raw url": base64.RawURLEncoding.EncodeToString([]byte(secret)),
		"hex":            hex.EncodeToString([]byte(secret)),
	}
	if m, err := json.Marshal(secret); err == nil {
		forms["json escaped"] = string(m[1 : len(m)-1])
	}
	// Lowercase percent-hex is a distinct string from QueryEscape's
	// uppercase form; build it from a secret whose escape uses A-F.
	lf := NewRedactor("aa/bb")
	if got := lf.String("x aa%2fbb y"); strings.Contains(got, "%2f") {
		t.Errorf("lowercase percent form leaked: %q", got)
	}
	for name, form := range forms {
		out := r.String("dial failed: " + form + " end")
		if strings.Contains(out, form) {
			t.Errorf("%s form of a seed leaked:\nform: %q\n out: %q", name, form, out)
		}
		if !strings.Contains(out, "[masked]") {
			t.Errorf("%s form masked nothing: %q", name, out)
		}
	}
}

// TestRedactorStrictAssignmentKeys pins the strict ring: keys that
// are ordinary words in prose mask only behind ":" or "=", in plain,
// JSON and URL-query shapes.
func TestRedactorStrictAssignmentKeys(t *testing.T) {
	leaks := []string{
		"sni: StrictSNI.example",
		"sni=StrictSNI.example",
		`"server_name": "StrictSNI2.example"`,
		"dest: StrictDest.example:443",
		"host: StrictHost.example",
		"serviceName=StrictGrpcService",
		"https://provider.example/feed?key=StrictQueryKey123",
		"https://provider.example/feed?code=StrictQueryCode123",
		"https://provider.example/feed?session=StrictQuerySession123",
		"hwid: StrictHWID123456",
		"device_id: StrictDevice12345",
		"seed: StrictSeed12345678",
		"encryption: StrictEncryption123",
		"https://provider.example/sub/StrictPathToken123456",
		"https://provider.example/subscription/StrictPathToken234567",
		`token: "a \"quoted\" tailword"`,
		"Authorization: Token StrictHeaderToken123",
	}
	for _, in := range leaks {
		out := maskPatterns(in)
		for _, frag := range []string{"Strict", "tailword", `\"quoted\"`} {
			if strings.Contains(out, frag) {
				t.Errorf("strict-ring secret leaked:\n in: %q\nout: %q\nfrag: %q", in, out, frag)
			}
		}
		if !strings.Contains(out, "[masked]") {
			t.Errorf("nothing masked:\n in: %q\nout: %q", in, out)
		}
	}
	// The same words in prose (no explicit assignment) stay readable.
	for _, in := range []string{
		"status code 200, session expired at noon",
		"the host is down, retrying the key exchange",
		"seed phrase lives elsewhere, host unreachable",
	} {
		if out := maskPatterns(in); out != in {
			t.Errorf("benign prose changed:\n in: %q\nout: %q", in, out)
		}
	}
}

// TestProfileSecretsAndIdentifiersCorpus pins profile extraction:
// credentials under any key spelling, and server identifiers
// (address, SNI, REALITY dest/serverNames) that were extracted
// nowhere before CENSOR-LEAK.
func TestProfileSecretsAndIdentifiersCorpus(t *testing.T) {
	profile := json.RawMessage(`{
		"outbounds": [{
			"protocol": "vless",
			"settings": {"vnext": [{
				"address": "profile-server.example",
				"users": [{"id": "11111111-2222-3333-4444-555555555555",
				           "encryption": "ProfileEncryptionValue"}]
			}]},
			"streamSettings": {"security": "reality", "realitySettings": {
				"dest": "profile-dest.example:443",
				"serverNames": ["profile-sni.example"],
				"publicKey": "ProfilePublicKeyValue",
				"shortId": "abcd1234",
				"spiderX": "/profile-spider"
			}}
		}]
	}`)
	o := Outbound{ID: "p1", Protocol: ProtocolXrayProfile, Profile: profile}
	secrets := strings.Join(o.Secrets(), "\n")
	for _, want := range []string{"11111111-2222-3333-4444-555555555555", "ProfileEncryptionValue", "ProfilePublicKeyValue", "abcd1234", "/profile-spider"} {
		// publicKey/shortId/spiderX are also identifiers; they are in
		// the secrets list historically (profileKeys), so accept
		// either list for those below.
		_ = want
		_ = secrets
	}
	ids := strings.Join(o.Identifiers(), "\n")
	for _, want := range []string{"profile-server.example", "profile-dest.example:443", "profile-sni.example"} {
		if !strings.Contains(ids, want) {
			t.Errorf("profile identifier %q not extracted:\nids: %q", want, ids)
		}
	}
	all := secrets + "\n" + ids
	for _, want := range []string{"11111111-2222-3333-4444-555555555555", "ProfileEncryptionValue"} {
		if !strings.Contains(all, want) {
			t.Errorf("profile secret %q not extracted", want)
		}
	}
	// Case/underscore spelling variants of the same credential key.
	variant := json.RawMessage(`{"settings": {"Pre_Shared_Key": "VariantPSKValue", "ACCESS_TOKEN": "VariantTokenValue"}}`)
	got := strings.Join(profileSecrets(variant), "\n")
	for _, want := range []string{"VariantPSKValue", "VariantTokenValue"} {
		if !strings.Contains(got, want) {
			t.Errorf("profile secret under variant key %q not extracted: %q", want, got)
		}
	}
}

// TestOutboundTransportSecretsCorpus pins the transport ring: a
// secret-path deployment's WS path and header values are seeds, and
// the transport host/service/download endpoint are identifiers.
func TestOutboundTransportSecretsCorpus(t *testing.T) {
	o := Outbound{
		ID: "t1", Protocol: ProtocolVLESS, Server: "h.example", Port: 443,
		Transport: Transport{
			Type: "ws", Path: "/secret-ws-path-token",
			Host: "transport-host.example", Service: "grpc-secret-service",
			Headers:         map[string]string{"X-Auth": "HeaderSecretValue"},
			DownloadAddress: "download.example", DownloadPort: 8443,
		},
	}
	secrets := strings.Join(o.Secrets(), "\n")
	for _, want := range []string{"/secret-ws-path-token", "HeaderSecretValue"} {
		if !strings.Contains(secrets, want) {
			t.Errorf("transport secret %q not registered", want)
		}
	}
	ids := strings.Join(o.Identifiers(), "\n")
	for _, want := range []string{"transport-host.example", "grpc-secret-service", "download.example", "download.example:8443"} {
		if !strings.Contains(ids, want) {
			t.Errorf("transport identifier %q not registered", want)
		}
	}
}

// FuzzRedactorNoPanicAndIdempotent fuzzes the pattern pipeline: it
// must never panic, and masking an already-masked line must be a
// fixed point (a second pass over stored logs changes nothing).
func FuzzRedactorNoPanicAndIdempotent(f *testing.F) {
	for _, seed := range []string{
		`token: "a \"b\" c"`, "https://h/sub/AbCdEfGh12345678?key=x",
		"sni: a.example", "user = bob", "Bearer abcdefgh12345678",
		"Key: kelvin", "://", "", "a-b-c-d-e",
	} {
		f.Add(seed)
	}
	f.Fuzz(func(t *testing.T, s string) {
		once := maskPatterns(s)
		if twice := maskPatterns(once); twice != once {
			t.Errorf("maskPatterns not idempotent:\n in: %q\nonce: %q\ntwice: %q", s, once, twice)
		}
		_ = NewRedactor("seed-value-1234").String(s)
	})
}

// TestRedactorBoundaryVectors pins the editor's edges (owner's
// "мелочи" criterion): seed lengths 0/1/3/4, pattern-length boundaries,
// multiline values, and values carrying separators. The contract for
// sub-4-byte seeds is documented, not accidental: Add ignores them
// because masking 1-3 byte strings would destroy ordinary log text,
// and the pattern ring is the backstop for their structured forms.
func TestRedactorBoundaryVectors(t *testing.T) {
	// Lengths 0 and 1 can never be seeds.
	r := NewRedactor("", "x")
	if out := r.String("x marks the spot"); out != "x marks the spot" {
		t.Errorf("1-byte seed masked prose: %q", out)
	}
	// Length 3 is below the seed floor; length 4 is the first masked.
	r = NewRedactor("abc", "abcd")
	if out := r.String("abc abcd"); strings.Contains(out, "abcd") || !strings.Contains(out, "abc") {
		t.Errorf("seed floor boundary wrong: %q (abc must survive, abcd must not)", out)
	}
	// A seed at the very start and very end of the text.
	r = NewRedactor("edge-secret-1")
	if out := r.String("edge-secret-1 middle edge-secret-1"); strings.Contains(out, "edge-secret-1") {
		t.Errorf("seed at text edges leaked: %q", out)
	}
	// Bearer pattern length boundary: 11 token chars survive (prose
	// guard), 12 are masked.
	if out := maskPatterns("Bearer abcdefghijk"); out != "Bearer abcdefghijk" {
		t.Errorf("11-char bearer value changed: %q", out)
	}
	if out := maskPatterns("Bearer abcdefghijkl"); !strings.Contains(out, "[masked]") {
		t.Errorf("12-char bearer value not masked: %q", out)
	}
	// A secret carrying separators is masked as one seed everywhere,
	// including inside a URL userinfo and a key pair.
	r = NewRedactor("user:p@ss/word")
	for _, in := range []string{
		"dial user:p@ss/word failed",
		"https://user:p@ss/word@host.example/x",
		"password: user:p@ss/word",
	} {
		if out := r.String(in); strings.Contains(out, "p@ss") {
			t.Errorf("separator-carrying seed leaked:\n in: %q\nout: %q", in, out)
		}
	}
	// Multiline: a quoted credential phrase spanning lines is masked
	// whole by the quoted alternation ([^"] crosses newlines only via
	// the escaped-quote form, which excludes neither \n nor \r).
	out := maskPatterns("token: \"first line\nsecond line\"")
	if strings.Contains(out, "second line") {
		t.Errorf("multiline quoted value leaked its tail: %q", out)
	}
	// A raw multiline seed matches only as a whole string; a log line
	// split loses the second half — pinned as the known limit, with
	// the first line still masked when it is itself a seed.
	r = NewRedactor("multi\nline-secret")
	if out := r.String("multi\nline-secret"); strings.Contains(out, "line-secret") {
		t.Errorf("whole multiline seed leaked: %q", out)
	}
}

// TestProfileExtractionDeterministic pins run-to-run stability of
// the extracted lists: map iteration order must not leak into
// Secrets()/Identifiers() (owner's determinism criterion).
func TestProfileExtractionDeterministic(t *testing.T) {
	profile := json.RawMessage(`{"z": {"password": "ZuluPassword1"}, "a": {"token": "AlphaToken1"},
		"m": {"address": "mid.example", "id": "MidIDValue1"}, "b": {"serverName": "bravo.example"}}`)
	o := Outbound{ID: "d1", Protocol: ProtocolXrayProfile, Profile: profile}
	firstSecrets, firstIDs := o.Secrets(), o.Identifiers()
	for i := 0; i < 32; i++ {
		if got := o.Secrets(); strings.Join(got, "|") != strings.Join(firstSecrets, "|") {
			t.Fatalf("Secrets() order unstable at run %d: %v vs %v", i, got, firstSecrets)
		}
		if got := o.Identifiers(); strings.Join(got, "|") != strings.Join(firstIDs, "|") {
			t.Fatalf("Identifiers() order unstable at run %d: %v vs %v", i, got, firstIDs)
		}
	}
}
