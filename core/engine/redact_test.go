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
