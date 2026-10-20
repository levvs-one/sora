// Package keyutil reads and writes minisign-format key files, so extension
// authors can generate and use signing keys without installing minisign.
//
// Formats (compatible with the real minisign):
//
//	secret: "untrusted comment: <comment>\n" + base64("Ed" || keyID(8) || secretKey(64))
//	public: "untrusted comment: <comment>\n" + base64("Ed" || keyID(8) || publicKey(32))
//
// The 64-byte secret key is the libsodium layout seed(32) || pubkey(32);
// ext.SignPayload takes the 32-byte seed.
package keyutil

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// KeyPair is a generated minisign keypair.
type KeyPair struct {
	// KeyID is the 8-byte minisign key id (hex in messages).
	KeyID [8]byte
	// Seed is the 32-byte ed25519 seed for ext.SignPayload.
	Seed []byte
	// PublicKeyLine is the base64 line to paste into the manifest's
	// author.public_key.
	PublicKeyLine string
}

// Generate creates a fresh keypair.
func Generate() (*KeyPair, error) {
	seed := make([]byte, ed25519.SeedSize)
	if _, err := rand.Read(seed); err != nil {
		return nil, fmt.Errorf("randomness failed: %w", err)
	}
	var keyID [8]byte
	if _, err := rand.Read(keyID[:]); err != nil {
		return nil, fmt.Errorf("randomness failed: %w", err)
	}
	priv := ed25519.NewKeyFromSeed(seed)
	pub := priv.Public().(ed25519.PublicKey)
	raw := append([]byte{'E', 'd'}, keyID[:]...)
	raw = append(raw, pub...)
	return &KeyPair{
		KeyID:         keyID,
		Seed:          seed,
		PublicKeyLine: base64.StdEncoding.EncodeToString(raw),
	}, nil
}

// WriteSecret writes the secret key file (mode 0600).
func (k *KeyPair) WriteSecret(path, comment string) error {
	priv := ed25519.NewKeyFromSeed(k.Seed)
	raw := append([]byte{'E', 'd'}, k.KeyID[:]...)
	raw = append(raw, priv.Seed()...)
	raw = append(raw, priv.Public().(ed25519.PublicKey)...)
	text := "untrusted comment: " + comment + "\n" +
		base64.StdEncoding.EncodeToString(raw) + "\n"
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(text), 0o600)
}

// WritePublic writes the public key file.
func (k *KeyPair) WritePublic(path, comment string) error {
	text := "untrusted comment: " + comment + "\n" + k.PublicKeyLine + "\n"
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(text), 0o644)
}

// LoadSeed reads a minisign secret key file and returns the 32-byte seed
// for ext.SignPayload.
func LoadSeed(path string) ([]byte, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	lines := strings.Split(strings.TrimSpace(string(data)), "\n")
	if len(lines) < 2 {
		return nil, fmt.Errorf("not a minisign secret key file (want 2 lines, got %d)", len(lines))
	}
	raw, err := base64.StdEncoding.DecodeString(strings.TrimSpace(lines[1]))
	if err != nil {
		return nil, fmt.Errorf("bad base64 in key file: %w", err)
	}
	if len(raw) != 74 || raw[0] != 'E' || raw[1] != 'd' {
		return nil, fmt.Errorf("bad secret key envelope (want 74 bytes starting with \"Ed\", got %d)", len(raw))
	}
	seed := make([]byte, ed25519.SeedSize)
	copy(seed, raw[10:42])
	return seed, nil
}
