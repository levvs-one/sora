package engine

// Shadowsocks method knowledge: classification and key requirements.
//
// The core passes the method name and password to the engines verbatim, so a
// typo or a weak method surfaces only as an opaque dial failure. This file
// centralizes what sora knows about Shadowsocks ciphers across SIP004/SIP007
// (AEAD 2017), SIP022 (AEAD-2022) and the long-deprecated stream ciphers, and
// turns that knowledge into warning codes the client localizes (see
// Outbound.Warnings). Nothing here changes the wire format; it only advises.

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"strings"
)

// ssMethodClass groups Shadowsocks methods by security properties.
type ssMethodClass int

const (
	// ssClassAEAD2022 covers the SIP022 methods: BLAKE3 key derivation,
	// fixed-length binary PSK, mandatory replay protection.
	ssClassAEAD2022 ssMethodClass = iota
	// ssClassAEAD covers the SIP004/SIP007 AEAD methods: password-derived
	// keys, no mandated replay protection.
	ssClassAEAD
	// ssClassStream covers the pre-AEAD stream ciphers: no integrity, no
	// replay protection; deprecated since 2017 and unsafe against active
	// probing (see gfw.report guidance to deprecate unauthenticated
	// constructions).
	ssClassStream
	// ssClassNone covers "none" and "plain": no encryption at all.
	ssClassNone
	// ssClassUnknown is any method sora does not recognize; engines may
	// reject it.
	ssClassUnknown
)

// shadowsocks2022KeyLen maps each SIP022 method to its required PSK length
// in bytes. The PSK is raw binary, base64-encoded for storage.
var shadowsocks2022KeyLen = map[string]int{
	"2022-blake3-aes-128-gcm":        16,
	"2022-blake3-aes-256-gcm":        32,
	"2022-blake3-chacha20-poly1305":  32,
	"2022-blake3-chacha12-poly1305":  32,
	"2022-blake3-chacha8-poly1305":   32,
}

// shadowsocksAEAD holds the SIP004/SIP007 AEAD methods, including the
// naming aliases engines accept.
var shadowsocksAEAD = map[string]bool{
	"aes-128-gcm": true, "aes-192-gcm": true, "aes-256-gcm": true,
	"chacha20-ietf-poly1305": true, "chacha20-poly1305": true,
	"xchacha20-ietf-poly1305": true, "xchacha20-poly1305": true,
}

// shadowsocksStream holds the deprecated stream ciphers. Matched by prefix
// because of the many key-size variants (aes-128-cfb, aes-256-cfb8, ...).
var shadowsocksStreamPrefixes = []string{
	"aes-128-ctr", "aes-192-ctr", "aes-256-ctr",
	"aes-128-cfb", "aes-192-cfb", "aes-256-cfb",
	"camellia-128-cfb", "camellia-192-cfb", "camellia-256-cfb",
	"rc4", "bf-cfb", "cast5-cfb", "des-cfb", "idea-cfb", "rc2-cfb", "seed-cfb",
	"salsa20", "chacha20", "xchacha20",
}

// normalizeShadowsocksMethod lowercases the method and applies sora's
// default: an empty cipher renders as aes-256-gcm in every engine.
func normalizeShadowsocksMethod(method string) string {
	m := strings.ToLower(strings.TrimSpace(method))
	if m == "" {
		return "aes-256-gcm"
	}
	return m
}

// classifyShadowsocksMethod returns the security class of a method name.
func classifyShadowsocksMethod(method string) ssMethodClass {
	m := normalizeShadowsocksMethod(method)
	if _, ok := shadowsocks2022KeyLen[m]; ok {
		return ssClassAEAD2022
	}
	if shadowsocksAEAD[m] {
		return ssClassAEAD
	}
	if m == "none" || m == "plain" {
		return ssClassNone
	}
	for _, p := range shadowsocksStreamPrefixes {
		// The trailing "8" covers the cfb8 variants (aes-128-cfb8, ...).
		if m == p || strings.HasPrefix(m, p+"-") || strings.HasPrefix(m, p+"8") {
			return ssClassStream
		}
	}
	return ssClassUnknown
}

// decodeShadowsocksPSK decodes a base64 PSK, tolerating padded/unpadded and
// URL-safe alphabets. Per SIP023 the client password may be a
// colon-separated PSK chain (iPSK:...:uPSK); the last segment is the
// effective PSK. Base64 has no colons, so splitting is safe.
func decodeShadowsocksPSK(password string) ([]byte, bool) {
	psk := password
	if i := strings.LastIndex(psk, ":"); i >= 0 {
		psk = psk[i+1:]
	}
	for _, enc := range []*base64.Encoding{
		base64.StdEncoding, base64.RawStdEncoding,
		base64.URLEncoding, base64.RawURLEncoding,
	} {
		if b, err := enc.DecodeString(psk); err == nil {
			return b, true
		}
	}
	return nil, false
}

// Warning codes for risky Shadowsocks settings, localized by the client.
const (
	// WarnShadowsocksNoEncryption: method "none"/"plain" sends traffic
	// unencrypted.
	WarnShadowsocksNoEncryption = "shadowsocks-no-encryption"
	// WarnShadowsocksDeprecatedCipher: a pre-AEAD stream cipher without
	// integrity or replay protection.
	WarnShadowsocksDeprecatedCipher = "shadowsocks-deprecated-cipher"
	// WarnShadowsocksWeakPassword: a legacy AEAD method with a short
	// password, cheap to brute force (Xray docs recommend 16+ chars).
	WarnShadowsocksWeakPassword = "shadowsocks-weak-password"
	// WarnShadowsocks2022BadKey: a SIP022 method whose password is not a
	// base64 PSK of the required length; strict engines (sing-box, mihomo)
	// refuse to dial, so the key is almost certainly broken.
	WarnShadowsocks2022BadKey = "shadowsocks-2022-bad-key"
	// WarnShadowsocksUnknownMethod: a method sora does not recognize; the
	// selected engine may reject it.
	WarnShadowsocksUnknownMethod = "shadowsocks-unknown-method"
	// WarnShadowsocksLegacyCipher: a SIP004/SIP007 AEAD method. It works,
	// but its first-packet length and fully-encrypted shape are passive-
	// detectable by modern DPI (GFW since 11.2021, TSPU selectively). The
	// client renders this as the "Legacy" badge; it never blocks or
	// deletes the server — the user migrates explicitly.
	WarnShadowsocksLegacyCipher = "shadowsocks-legacy-cipher"
	// WarnShadowsocksKnownPort: the well-known default Shadowsocks port
	// 8388. Trivially fingerprintable by port-oriented blocking; new
	// servers should use a random high port (T020/P07-11).
	WarnShadowsocksKnownPort = "shadowsocks-known-port"
)

// minShadowsocksPasswordLen is the password length below which a legacy
// AEAD password is flagged as weak.
const minShadowsocksPasswordLen = 16

// wellKnownShadowsocksPort is the default SS port. Servers on it are
// trivially enumerable by port-oriented blocking.
const wellKnownShadowsocksPort = 8388

// DefaultNewShadowsocksMethod is the cipher the client pre-selects when
// the user creates a server by hand: SIP022, not the legacy AEAD. The
// wire default for imported links without a cipher stays aes-256-gcm —
// changing it would silently break existing servers.
const DefaultNewShadowsocksMethod = "2022-blake3-aes-256-gcm"

// Shadowsocks2022Methods lists the SIP022 ciphers for UI pickers, in
// recommended order.
func Shadowsocks2022Methods() []string {
	return []string{
		"2022-blake3-aes-256-gcm",
		"2022-blake3-aes-128-gcm",
		"2022-blake3-chacha20-poly1305",
	}
}

// GenerateShadowsocks2022PSK creates a fresh random pre-shared key for a
// SIP022 method, base64-encoded per SIP022. It backs the client's
// "upgrade to 2022" migration: new key and new method on the same server
// entry, no deletion. The caller must deliver the key to the server
// operator out of band — sora cannot rotate a server-side key by itself.
//
// NOT WIRED: no UI path calls this yet — it waits for the "rotate to
// 2022" client flow (T020).
func GenerateShadowsocks2022PSK(method string) (string, error) {
	n, ok := shadowsocks2022KeyLen[normalizeShadowsocksMethod(method)]
	if !ok {
		return "", fmt.Errorf("not a Shadowsocks-2022 method: %q", method)
	}
	key := make([]byte, n)
	if _, err := rand.Read(key); err != nil {
		return "", fmt.Errorf("generate SS-2022 PSK: %w", err)
	}
	return base64.StdEncoding.EncodeToString(key), nil
}

// shadowsocksWarnings classifies the outbound's method and key material
// into warning codes. It never fails validation: engines differ in the
// exact methods and key handling they accept, so everything here is advice,
// not a rejection.
func (o Outbound) shadowsocksWarnings() []string {
	if o.Protocol != ProtocolShadowsocks {
		return nil
	}
	var out []string
	method := normalizeShadowsocksMethod(o.Cipher)
	switch classifyShadowsocksMethod(o.Cipher) {
	case ssClassNone:
		out = append(out, WarnShadowsocksNoEncryption)
	case ssClassStream:
		out = append(out, WarnShadowsocksDeprecatedCipher)
	case ssClassAEAD:
		out = append(out, WarnShadowsocksLegacyCipher)
		if len(o.Password) < minShadowsocksPasswordLen {
			out = append(out, WarnShadowsocksWeakPassword)
		}
	case ssClassAEAD2022:
		want := shadowsocks2022KeyLen[method]
		key, ok := decodeShadowsocksPSK(o.Password)
		if !ok || len(key) != want {
			out = append(out, WarnShadowsocks2022BadKey)
		}
	case ssClassUnknown:
		out = append(out, WarnShadowsocksUnknownMethod)
	}
	if o.Port == wellKnownShadowsocksPort {
		out = append(out, WarnShadowsocksKnownPort)
	}
	return out
}
