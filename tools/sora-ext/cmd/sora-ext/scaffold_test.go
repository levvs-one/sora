package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/ext"
	"github.com/levvs-one/sora-client/tools/sora-ext/internal/keyutil"
	"github.com/levvs-one/sora-client/tools/sora-ext/internal/pack"
)

func TestScaffoldKeepsSigningKeyOutOfPackage(t *testing.T) {
	dir := t.TempDir()
	if code := scaffoldRun("com.example.test", "panel", "Test", "Test Author", "github:example", "Testing package integrity", "", dir); code != 0 {
		t.Fatalf("scaffold: %d", code)
	}
	files, err := pack.Collect(dir)
	if err != nil {
		t.Fatal(err)
	}
	for path := range files {
		if filepath.Ext(path) == ".key" {
			t.Fatalf("package includes key %q", path)
		}
	}
	key, err := keyutil.Load(filepath.Join(dir, ".sora", "author.key"))
	if err != nil {
		t.Fatal(err)
	}
	payload := []byte(pack.Checksums(files))
	sig, err := ext.SignPayload(key, "test", "checksums.txt", 1700000000, payload)
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := ext.ParseManifest(files["sora-extension.json"])
	if err != nil {
		t.Fatal(err)
	}
	if err := ext.VerifyPackageSignature(manifest.Author.PublicKey, sig, payload); err != nil {
		t.Fatal(err)
	}
	payload[0] ^= 1
	if err := ext.VerifyPackageSignature(manifest.Author.PublicKey, sig, payload); err == nil {
		t.Fatal("tampered checksums accepted")
	}
	info, err := os.Stat(filepath.Join(dir, ".sora", "author.key"))
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm()&0o077 != 0 {
		t.Fatal("private key is readable by other users")
	}
}
