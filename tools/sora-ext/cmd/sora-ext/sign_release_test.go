package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/ext"
	"github.com/levvs-one/sora-client/tools/sora-ext/internal/keyutil"
)

func TestSignReleaseManifest(t *testing.T) {
	dir := t.TempDir()
	key, err := keyutil.Generate()
	if err != nil {
		t.Fatal(err)
	}
	keyPath := filepath.Join(dir, "test.key")
	if err := key.WriteSecret(keyPath, "test"); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(dir, "SHA256SUMS")
	payload := []byte("release manifest to authenticate\n")
	if err := os.WriteFile(path, payload, 0o600); err != nil {
		t.Fatal(err)
	}
	role := "release:v1.2.3:SHA256SUMS"
	if code := cmdSignFile([]string{"--key", keyPath, "--role", role, path}); code != 0 {
		t.Fatalf("signing failed: %d", code)
	}
	signature, err := os.ReadFile(path + ".minisig")
	if err != nil {
		t.Fatal(err)
	}
	if err := ext.VerifyPayload(key.PublicKeyLine, string(signature), role, payload); err != nil {
		t.Fatal(err)
	}
	for _, otherRole := range []string{"catalog.json", "revocations.json", "release:v1.2.4:SHA256SUMS"} {
		if err := ext.VerifyPayload(key.PublicKeyLine, string(signature), otherRole, payload); err == nil {
			t.Fatalf("accepted signature as %s", otherRole)
		}
	}
}

func TestSignFileRejectsMalformedReleaseRoles(t *testing.T) {
	for _, role := range []string{"", "SHA256SUMS", "release:v01.2.3:SHA256SUMS", "release:v1.2.3-beta:SHA256SUMS", "release:v1.2.3:catalog.json", "release:v1.2.3:SHA256SUMS\n"} {
		if code := cmdSignFile([]string{"--key", "does-not-exist", "--role", role, "SHA256SUMS"}); code != 1 {
			t.Fatalf("invalid role %q was not rejected before reading the key: %d", role, code)
		}
	}
}
