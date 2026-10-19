package engine

import (
	"encoding/base64"
	"slices"
	"testing"
)

func ssOutbound(method, password string) Outbound {
	return Outbound{ID: "ss", Protocol: ProtocolShadowsocks,
		Server: "ss.example.com", Port: 8388, Cipher: method, Password: password}
}

func TestClassifyShadowsocksMethod(t *testing.T) {
	cases := []struct {
		method string
		class  ssMethodClass
	}{
		{"2022-blake3-aes-128-gcm", ssClassAEAD2022},
		{"2022-blake3-aes-256-gcm", ssClassAEAD2022},
		{"2022-blake3-chacha20-poly1305", ssClassAEAD2022},
		{"2022-blake3-chacha12-poly1305", ssClassAEAD2022},
		{"2022-blake3-chacha8-poly1305", ssClassAEAD2022},
		{"aes-256-gcm", ssClassAEAD},
		{"aes-128-gcm", ssClassAEAD},
		{"chacha20-ietf-poly1305", ssClassAEAD},
		{"chacha20-poly1305", ssClassAEAD},
		{"xchacha20-ietf-poly1305", ssClassAEAD},
		{"", ssClassAEAD}, // empty renders as aes-256-gcm everywhere
		{"AES-256-GCM", ssClassAEAD},
		{"rc4-md5", ssClassStream},
		{"aes-256-cfb", ssClassStream},
		{"aes-128-cfb8", ssClassStream},
		{"chacha20", ssClassStream},
		{"chacha20-ietf", ssClassStream},
		{"bf-cfb", ssClassStream},
		{"none", ssClassNone},
		{"plain", ssClassNone},
		{"aes-256-gcmm", ssClassUnknown},
		{"super-cipher-9000", ssClassUnknown},
	}
	for _, tc := range cases {
		if got := classifyShadowsocksMethod(tc.method); got != tc.class {
			t.Errorf("classifyShadowsocksMethod(%q) = %d, want %d", tc.method, got, tc.class)
		}
	}
}

func TestShadowsocks2022KeyLengths(t *testing.T) {
	for method, want := range map[string]int{
		"2022-blake3-aes-128-gcm": 16, "2022-blake3-aes-256-gcm": 32,
		"2022-blake3-chacha20-poly1305": 32, "2022-blake3-chacha12-poly1305": 32,
		"2022-blake3-chacha8-poly1305": 32,
	} {
		if shadowsocks2022KeyLen[method] != want {
			t.Errorf("key length for %s = %d, want %d", method, shadowsocks2022KeyLen[method], want)
		}
	}
}

func TestShadowsocksWarnings(t *testing.T) {
	key16 := base64.StdEncoding.EncodeToString(make([]byte, 16))
	key32 := base64.StdEncoding.EncodeToString(make([]byte, 32))
	// SIP023 identity-header chain: only the last segment is the PSK.
	chain := key32 + ":" + key32

	cases := []struct {
		name     string
		method   string
		password string
		want     []string
	}{
		{"valid 2022 aes-256", "2022-blake3-aes-256-gcm", key32, nil},
		{"valid 2022 aes-128", "2022-blake3-aes-128-gcm", key16, nil},
		{"valid 2022 chacha20", "2022-blake3-chacha20-poly1305", key32, nil},
		{"valid 2022 identity chain", "2022-blake3-aes-256-gcm", chain, nil},
		{"2022 wrong length", "2022-blake3-aes-256-gcm", key16, []string{WarnShadowsocks2022BadKey}},
		{"2022 not base64", "2022-blake3-aes-256-gcm", "not-a-key!!", []string{WarnShadowsocks2022BadKey}},
		{"2022 empty key", "2022-blake3-aes-128-gcm", "", []string{WarnShadowsocks2022BadKey}},
		{"legacy aead strong password", "aes-256-gcm", "a-long-enough-password", nil},
		{"legacy aead short password", "aes-256-gcm", "short", []string{WarnShadowsocksWeakPassword}},
		{"stream cipher", "rc4-md5", "password", []string{WarnShadowsocksDeprecatedCipher}},
		{"stream cipher cfb8", "aes-128-cfb8", "password", []string{WarnShadowsocksDeprecatedCipher}},
		{"no encryption", "none", "password", []string{WarnShadowsocksNoEncryption}},
		{"plain", "plain", "password", []string{WarnShadowsocksNoEncryption}},
		{"unknown method", "aes-256-gcmm", "password", []string{WarnShadowsocksUnknownMethod}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := ssOutbound(tc.method, tc.password).shadowsocksWarnings()
			if !slices.Equal(got, tc.want) {
				t.Errorf("warnings = %v, want %v", got, tc.want)
			}
		})
	}
}

func TestShadowsocksWarningsOnlyForShadowsocks(t *testing.T) {
	o := Outbound{ID: "v", Protocol: ProtocolVLESS, Server: "v.example.com",
		Port: 443, Cipher: "none", Password: "x"}
	if got := o.shadowsocksWarnings(); len(got) != 0 {
		t.Errorf("non-shadowsocks outbound must not get SS warnings, got %v", got)
	}
}

func TestOutboundWarningsIncludeShadowsocks(t *testing.T) {
	o := ssOutbound("2022-blake3-aes-256-gcm", "too-short")
	if got := o.Warnings(); !slices.Contains(got, WarnShadowsocks2022BadKey) {
		t.Errorf("Warnings() = %v, must contain %q", got, WarnShadowsocks2022BadKey)
	}
	good := ssOutbound("2022-blake3-aes-256-gcm",
		base64.StdEncoding.EncodeToString(make([]byte, 32)))
	for _, w := range good.Warnings() {
		switch w {
		case WarnShadowsocksNoEncryption, WarnShadowsocksDeprecatedCipher,
			WarnShadowsocksWeakPassword, WarnShadowsocks2022BadKey,
			WarnShadowsocksUnknownMethod:
			t.Errorf("valid SS-2022 outbound unexpectedly warns %q", w)
		}
	}
}
