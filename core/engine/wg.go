package engine

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
)

// WireGuard pre-shared key helpers (S8 post-quantum audit, 2026-10-20).
//
// WireGuard's Noise handshake mixes an optional 32-byte pre-shared key
// (psk) into the chaining key. A random PSK known only to client and
// server makes the handshake quantum-resistant for "harvest now, decrypt
// later": breaking it later requires breaking the PSK, not just the
// X25519 ECDH. This is the AmneziaVPN precedent (11.2024): a server-side
// PQ-PSK with the server accepting both PSK and non-PSK clients during
// rollout.
//
// What sora can do honestly on the client side:
//   - generate the PSK (GenerateWireGuardPSK — the `wg genpsk`
//     equivalent; the UI's "generate" button calls this),
//   - carry it in the plan (Outbound peer PreSharedKey — already plumbed
//     through the sing-box, mihomo and Xray renderers),
//   - shape-check it before the engines see it (ValidateWireGuardPSK).
//
// What sora cannot do: provision the server side. There is no one-click
// deploy in sora, and stock sing-box/mihomo WireGuard servers configure
// the PSK per peer — a peer either has one or not, so "accept clients
// with and without PSK" needs an AmneziaVPN-style server, not a config
// flag. Delivering the PSK to the server operator stays out of band.

// wireGuardPSKLen is the WireGuard pre-shared key length in bytes:
// Noise PSK, 32 bytes, base64-encoded on the wire configs.
const wireGuardPSKLen = 32

// GenerateWireGuardPSK creates a fresh random WireGuard pre-shared key,
// base64-encoded exactly like `wg genpsk` (44 chars with padding).
// The caller must deliver the key to the server operator out of band —
// sora cannot rotate a server-side key by itself, and the server peer
// entry must carry the same PSK or the handshake fails.
func GenerateWireGuardPSK() (string, error) {
	key := make([]byte, wireGuardPSKLen)
	if _, err := rand.Read(key); err != nil {
		return "", fmt.Errorf("generate WireGuard PSK: %w", err)
	}
	return base64.StdEncoding.EncodeToString(key), nil
}

// ValidateWireGuardPSK shape-checks a WireGuard pre-shared key: base64
// (padded or unpadded, as `wg` tooling accepts both) decoding to exactly
// 32 bytes. An empty key is valid: it means "no PSK", which WireGuard
// treats as the all-zero chaining contribution.
func ValidateWireGuardPSK(s string) error {
	if s == "" {
		return nil
	}
	raw, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		raw, err = base64.RawStdEncoding.DecodeString(s)
	}
	if err != nil {
		return fmt.Errorf("wireguard: pre-shared key is not base64: %w", err)
	}
	if len(raw) != wireGuardPSKLen {
		return fmt.Errorf("wireguard: pre-shared key decodes to %d bytes, want %d", len(raw), wireGuardPSKLen)
	}
	return nil
}
