package engine

import (
	"strings"
	"testing"
)

// M1 (PASS1-ANALYSIS): the key=value pattern must mask secrets whose
// values are quoted phrases, provider-style keys the old pattern missed,
// and token-style links. The Redactor seed path masks exact values; these
// tests cover the unknown-value patterns.
func TestRedactorMasksCredentialPatterns(t *testing.T) {
	cases := []struct {
		name string
		in   string
		want []string // substrings that must NOT survive masking
	}{
		{
			name: "quoted value with spaces masked whole",
			in:   `token: "my secret value"`,
			// Every word of the phrase must be gone, not just the
			// contiguous "secret value": the separator must not eat the
			// opening quote (that used to leak the phrase tail word by
			// word: token: "a b" -> token: "[masked] b").
			want: []string{"secret value", `"my`, "secret", "value"},
		},
		{
			name: "short quoted value masked whole",
			in:   `token: "a b"`,
			want: []string{"a b", `b"`},
		},
		{
			name: "quoted passphrase masked whole",
			in:   `password: "correct horse battery"`,
			want: []string{"correct", "horse", "battery"},
		},
		{
			name: "json quoted value masked whole",
			in:   `"token": "abc def"`,
			want: []string{"abc", "def"},
		},
		{
			name: "api_key masked",
			in:   "api_key=sk-live-abcdef123456",
			want: []string{"sk-live"},
		},
		{
			name: "obfs_param masked",
			in:   "obfs_param: example.com",
			want: []string{"example.com"},
		},
		{
			name: "username masked",
			in:   "username: bob",
			want: []string{"bob"},
		},
		{
			name: "explicit user assignment masked",
			in:   "user = bob",
			want: []string{"bob"},
		},
		{
			name: "login prose untouched",
			in:   "login failed for client",
			want: nil, // asserted separately: no masking at all
		},
		{
			name: "token in link masked, host readable",
			in:   "connect to https://token12345@host.example/x",
			want: []string{"token12345"},
		},
		{
			name: "uuid masked",
			in:   "id 123e4567-e89b-12d3-a456-426614174000 ok",
			want: []string{"123e4567-e89b"},
		},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			out := maskPatterns(c.in)
			for _, leak := range c.want {
				if strings.Contains(out, leak) {
					t.Errorf("secret leaked:\n in: %q\nout: %q\nleak: %q", c.in, out, leak)
				}
			}
			if c.name == "token in link masked, host readable" && !strings.Contains(out, "host.example") {
				t.Errorf("host was masked too: %q", out)
			}
			if c.name == "login prose untouched" && out != c.in {
				t.Errorf("benign text changed:\n in: %q\nout: %q", c.in, out)
			}
			if !strings.Contains(out, "[masked]") && len(c.want) > 0 {
				t.Errorf("nothing masked:\n in: %q\nout: %q", c.in, out)
			}
		})
	}
}

func TestRedactorSeededValuesWin(t *testing.T) {
	r := NewRedactor("short", "longer-secret-value")
	out := r.String("used longer-secret-value and short here")
	if strings.Contains(out, "longer-secret-value") || strings.Contains(out, "short") {
		t.Errorf("seeded values not masked: %q", out)
	}
}

// TestMaskGateParity pins the maskPatterns fast-path gate: lines that no
// pattern can touch come back byte-identical, and representative lines
// from every pattern family are still masked exactly as without the gate.
func TestMaskGateParity(t *testing.T) {
	unchanged := []string{
		"[tun] interface sora0 up, mtu 9000",
		"dns: query for example.com. from 192.168.1.10",
		"connection reset by peer, retry 3 of 5",
		"123e4567-e89b-12d3-a456 (partial uuid, only three dashes)",
	}
	for _, in := range unchanged {
		if out := maskPatterns(in); out != in {
			t.Errorf("clean line changed:\n in: %q\nout: %q", in, out)
		}
	}
	masked := map[string]string{
		`token: "my secret value"`: `token: [masked]`,
		`token: "a b"`:             `token: [masked]`,
		`user = "bob jones"`:       `user = [masked]`,
		"vless://123e4567-e89b-12d3-a456-426614174000@h:443": "vless://[masked]@h:443",
		"uuid is 123e4567-e89b-12d3-a456-426614174000 ok":    "uuid [masked] [masked] ok",
		"id 123e4567-e89b-12d3-a456-426614174000 end":        "id [masked] end",
		"api_key=testkey123456":                              "api_key=[masked]",
		"user = bob":                                         "user = [masked]",
	}
	for in, want := range masked {
		if out := maskPatterns(in); out != want {
			t.Errorf("mask changed by gate:\n in: %q\nwant: %q\n got: %q", in, want, out)
		}
	}
}

// TestRedactorParityKeySpellings pins the canonical key-superset shared
// byte-for-byte with sora-legacy (M1, pass 3/3): every WireGuard
// pre-shared-key spelling, every spider spelling and every public-key
// spelling must mask, plain and as a quoted JSON value (quoted form
// verifies the phrase tail is not leaked word by word — the pass-1
// false closure).
func TestRedactorParityKeySpellings(t *testing.T) {
	keys := []string{
		"pre_shared_key", "pre-shared-key", "preshared_key", "presharedkey",
		"public_key", "public-key", "publickey",
		"spider_x", "spider-x", "spiderx", "spiderX",
		"private_key", "auth_str", "short_id",
	}
	for _, key := range keys {
		for _, in := range []string{
			key + "=ParitySecret99",
			key + ": ParitySecret99",
			`"` + key + `": "ParitySecret99"`,
			key + `: "secret phrase tail"`,
		} {
			out := maskPatterns(in)
			if strings.Contains(out, "ParitySecret99") || strings.Contains(out, "phrase tail") {
				t.Errorf("key %q leaked: in=%q out=%q", key, in, out)
			}
			if !strings.Contains(out, "[masked]") {
				t.Errorf("key %q masked nothing: in=%q out=%q", key, in, out)
			}
		}
	}
	// pre_shared_key is the literal WireGuard field name in sing-box JSON:
	// a quoted multi-word value must be masked whole, not word by word.
	out := maskPatterns(`"pre_shared_key": "a b c"`)
	for _, leak := range []string{"a b", `b"`, "c"} {
		if strings.Contains(out, leak) {
			t.Errorf("quoted pre_shared_key tail leaked: out=%q leak=%q", out, leak)
		}
	}
}

// TestMaskPatternsDifferential pins the [pass3-opt] per-pattern gates:
// maskPatterns must stay byte-identical to the unconditional pattern
// pipeline on every input, ASCII or not. The reference below is that
// pipeline verbatim.
func TestMaskPatternsDifferential(t *testing.T) {
	reference := func(s string) string {
		s = userInfoPattern.ReplaceAllString(s, "${1}://[masked]@")
		s = tokenLinkPattern.ReplaceAllString(s, "${1}://[masked]")
		s = authHeaderPattern.ReplaceAllString(s, "${1}[masked]")
		s = bearerPattern.ReplaceAllString(s, "${1}[masked]")
		s = keyValuePattern.ReplaceAllString(s, "${1}${2}[masked]")
		s = strictKeyValuePattern.ReplaceAllString(s, "${1}${2}[masked]")
		s = uuidPattern.ReplaceAllString(s, "[masked]")
		return s
	}
	fragments := []string{
		"plain log line, latency 45ms",
		"token: \"my secret value\"",
		"Token: abc",
		"PASSWORD=hunter2",
		"pre_shared_key: zzz",
		"pre-shared-key: zzz",
		"public_key: q",
		"spider_x=1",
		"api_key: k",
		"auth_str: s",
		"client_secret: c",
		"short_id: 6ba8",
		"user = bob",
		"login: root",
		"username: eve",
		"vless://123e4567-e89b-12d3-a456-426614174000@h:443",
		"vmess://dG9rZW4td2l0aC1kYXNoZXM=",
		"https://user:pass@host/path",
		"uuid is 123e4567-e89b-12d3-a456-426614174000 ok",
		"a-b-c-d-e",
		"Key: kelvin",
		"пароль token: y",
		"ключ: значение",
		"obfs_param: p",
		"access_token=xyz123",
		"Authorization: Bearer abcdefgh123456",
		"Bearer abcdefgh12345678",
		"psk: p",
		"key",
		"user",
		"://",
		"-",
		"",
	}
	var inputs []string
	inputs = append(inputs, fragments...)
	for _, a := range fragments {
		for _, b := range fragments {
			inputs = append(inputs, a+" "+b)
		}
	}
	for _, in := range inputs {
		if got, want := maskPatterns(in), reference(in); got != want {
			t.Errorf("maskPatterns differs from unconditional pipeline:\n in: %q\nwant: %q\n got: %q", in, want, got)
		}
	}
}

// TestRedactorParityCompoundTokens pins the S5 seams extension shared by
// both repos' redactors: compound *_token keys (access_token and friends,
// snake and camelCase) and HTTP Authorization/Bearer credentials were
// invisible to the canonical key alternation — \btoken\b has no word
// boundary inside access_token, and "Authorization" has none after
// "auth" — so both forms leaked verbatim into logs in both cores.
func TestRedactorParityCompoundTokens(t *testing.T) {
	leaks := []string{
		"access_token=CompoundSecret111",
		`access_token: "CompoundSecret111 phrase tail"`,
		"refresh_token=CompoundSecret222",
		"session_token: CompoundSecret333",
		"id_token=CompoundSecret444",
		"auth_token=CompoundSecret555",
		"api_token=CompoundSecret666",
		`"accessToken": "CompoundSecret777"`,
		"Authorization: Bearer CompoundSecret888token",
		"Authorization: Basic CompoundSecret999",
		"curl -H 'Bearer CompoundSecret000abcdefgh'",
	}
	for _, in := range leaks {
		out := maskPatterns(in)
		if strings.Contains(out, "CompoundSecret") || strings.Contains(out, "phrase tail") {
			t.Errorf("compound secret leaked:\n in: %q\nout: %q", in, out)
		}
		if !strings.Contains(out, "[masked]") {
			t.Errorf("nothing masked:\n in: %q\nout: %q", in, out)
		}
	}
	// Prose must survive: "bearer" without a token-shaped value is not
	// a credential.
	for _, in := range []string{
		"bearer of good news",
		"the bearer instrument is payable at sight",
		"tokens are counted per bucket, 45ms",
	} {
		if out := maskPatterns(in); out != in {
			t.Errorf("benign text changed:\n in: %q\nout: %q", in, out)
		}
	}
}
