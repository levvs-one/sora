// Package keyutil persists standard minisign author keys with owner-only secrets.
package keyutil

import (
	"crypto/rand"
	"os"
	"path/filepath"
	"strings"

	"aead.dev/minisign"
)

// KeyPair is one author identity for packaging and publishing extensions.
type KeyPair struct {
	Private       minisign.PrivateKey
	PublicKeyLine string
}

// Generate creates an author key using the operating system RNG.
func Generate() (*KeyPair, error) {
	pub, key, err := minisign.GenerateKey(rand.Reader)
	if err != nil {
		return nil, err
	}
	return &KeyPair{Private: key, PublicKeyLine: pub.String()}, nil
}

// WriteSecret stores an unencrypted offline key with owner-only permissions.
func (k *KeyPair) WriteSecret(path, _ string) error {
	raw, err := k.Private.MarshalText()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	f, err := os.OpenFile(path, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
	if err != nil {
		return err
	}
	if _, err := f.Write(raw); err != nil {
		_ = f.Close()
		return err
	}
	return f.Close()
}

// WritePublic stores the public identity authors paste into manifests.
func (k *KeyPair) WritePublic(path, comment string) error {
	text := "untrusted comment: " + comment + "\n" + k.PublicKeyLine + "\n"
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(text), 0o644)
}

// Load reads an unencrypted minisign key. Password prompts are never opened.
func Load(path string) (minisign.PrivateKey, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return minisign.PrivateKey{}, err
	}
	var key minisign.PrivateKey
	err = key.UnmarshalText([]byte(strings.TrimSpace(string(raw))))
	return key, err
}
