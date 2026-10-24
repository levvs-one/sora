package main

import (
	"context"
	"crypto/rand"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"aead.dev/minisign"

	"github.com/levvs-one/sora-client/core/ext"
)

func TestReleaseSignatureTrustBoundary(t *testing.T) {
	public, private, err := minisign.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	other, _, err := minisign.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	payload := []byte(strings.Repeat("a", 64) + "  sora_1.2.3_amd64.deb\n")
	for _, test := range []string{"valid", "modified manifest", "wrong key", "untrusted signer", "wrong version", "catalog replay", "missing signature", "oversize manifest", "oversize signature", "empty manifest", "directory", "symlink"} {
		t.Run(test, func(t *testing.T) {
			dir := t.TempDir()
			role := "release:v1.2.3:SHA256SUMS"
			if test == "catalog replay" {
				role = "catalog.json"
			}
			signature, err := ext.SignPayload(private, "test", role, 1700000000, payload)
			if err != nil {
				t.Fatal(err)
			}
			manifest := filepath.Join(dir, "SHA256SUMS")
			if err := os.WriteFile(manifest, payload, 0o600); err != nil {
				t.Fatal(err)
			}
			if err := os.WriteFile(manifest+".minisig", []byte(signature), 0o600); err != nil {
				t.Fatal(err)
			}
			version, key := "1.2.3", public.String()
			switch test {
			case "modified manifest":
				err = os.WriteFile(manifest, append([]byte("changed"), payload...), 0o600)
			case "wrong key":
				key = other.String()
			case "untrusted signer":
				key = releasePublicKey
			case "wrong version":
				version = "1.2.4"
			case "missing signature":
				err = os.Remove(manifest + ".minisig")
			case "oversize manifest":
				err = os.WriteFile(manifest, make([]byte, 1024*1024+1), 0o600)
			case "oversize signature":
				err = os.WriteFile(manifest+".minisig", make([]byte, 8193), 0o600)
			case "empty manifest":
				err = os.WriteFile(manifest, nil, 0o600)
			case "directory", "symlink":
				if err = os.Remove(manifest); err != nil {
					t.Fatal(err)
				}
				if test == "directory" {
					err = os.Mkdir(manifest, 0o700)
				} else {
					err = os.Symlink(manifest+".minisig", manifest)
					if err != nil {
						t.Skipf("symlink unavailable: %v", err)
					}
				}
			}
			if err != nil {
				t.Fatal(err)
			}
			err = verifyRelease(dir, version, key)
			if (err == nil) != (test == "valid") {
				t.Fatalf("verification: %v", err)
			}
		})
	}
}

func TestReleaseVerifierRejectsAmbiguousCommandsWithoutStartingCore(t *testing.T) {
	data := filepath.Join(t.TempDir(), "must-not-be-created")
	t.Setenv("SORA_DATA_DIR", data)
	for _, args := range [][]string{
		{"-verify-release=", "-release-version=", "-uninstall-service"},
		{"-release-version=", "-print-token"},
		{"-release-version", "1.2.3"},
		{"-verify-release", t.TempDir()},
		{"-verify-release", t.TempDir(), "-release-version", "v1.2.3"},
		{"-verify-release", t.TempDir(), "-release-version", "01.2.3"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3-beta"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "-install-service"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "-uninstall-service"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "-print-token"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "-version"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "extra"},
	} {
		if err := run(context.Background(), args); err == nil {
			t.Fatalf("accepted %q", args)
		}
	}
	if _, err := os.Stat(data); !os.IsNotExist(err) {
		t.Fatalf("verification touched core state: %v", err)
	}
}

func TestReleaseTrustRootMatchesApplication(t *testing.T) {
	data, err := os.ReadFile("../../../app/lib/src/ext/verifier.dart")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), "'"+releasePublicKey+"'") {
		t.Fatal("native release trust root differs from the application's team key")
	}
}
