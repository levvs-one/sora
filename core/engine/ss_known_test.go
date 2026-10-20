package engine

import "testing"

// TestIsKnownShadowsocksMethod pins the exported classifier the
// control plane's custom-server credential split relies on (B1-fix
// R2): it must agree with classifyShadowsocksMethod's lists — every
// class but Unknown counts, case-insensitively — and the empty string
// must not count (it is the absence of a method, even though the
// classifier maps it onto the aes-256-gcm default for warnings).
func TestIsKnownShadowsocksMethod(t *testing.T) {
	for _, method := range []string{
		"aes-256-gcm", "aes-128-gcm", "chacha20-ietf-poly1305",
		"xchacha20-ietf-poly1305",
		"2022-blake3-aes-128-gcm", "2022-blake3-aes-256-gcm",
		"2022-blake3-chacha20-poly1305", "2022-blake3-chacha12-poly1305",
		"2022-blake3-chacha8-poly1305",
		"aes-256-cfb", "aes-128-cfb8", "rc4-md5", "chacha20",
		"none", "plain",
		"AES-256-GCM",
	} {
		if !IsKnownShadowsocksMethod(method) {
			t.Errorf("IsKnownShadowsocksMethod(%q) = false, want true", method)
		}
	}
	for _, method := range []string{"", " ", "my", "aes-256-gcmm", "super-cipher-9000"} {
		if IsKnownShadowsocksMethod(method) {
			t.Errorf("IsKnownShadowsocksMethod(%q) = true, want false", method)
		}
	}
}
