package main

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/json"
	"fmt"
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
	metadata, err := json.Marshal(releaseMetadata{Artifacts: []releaseArtifact{{
		Arch: "amd64", Name: "sora_1.2.3_amd64.deb", OS: "linux", SHA256: strings.Repeat("a", 64), Size: 1,
	}}, Schema: 1, Version: "1.2.3"})
	if err != nil {
		t.Fatal(err)
	}
	metadata = append(metadata, '\n')
	payload := []byte(fmt.Sprintf("%x  release.json\n%s  sora_1.2.3_amd64.deb\n", sha256.Sum256(metadata), strings.Repeat("a", 64)))
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
			if err := os.WriteFile(filepath.Join(dir, "release.json"), metadata, 0o600); err != nil {
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
			verified, verifyErr := verifyRelease(dir, version, key)
			err = verifyErr
			if (err == nil) != (test == "valid") {
				t.Fatalf("verification: %v", err)
			}
			if test == "valid" {
				if err := verified.verifyArtifactFiles(context.Background(), dir); err == nil {
					t.Fatal("partial manifest passed the full publication profile")
				}
				size, err := verified.artifactSize("sora_1.2.3_amd64.deb", "linux/amd64", "1.2.3")
				if err != nil || size != 1 {
					t.Fatalf("signed artifact size: %d, %v", size, err)
				}
				if _, err := verified.artifactSize("sora-core_1.2.3_amd64.deb", "linux/amd64", "1.2.3"); err == nil {
					t.Fatal("missing artifact checksum accepted")
				}
			}
		})
	}
}

func TestReleaseVerifierRejectsAmbiguousCommandsWithoutStartingCore(t *testing.T) {
	data := filepath.Join(t.TempDir(), "must-not-be-created")
	t.Setenv("SORA_DATA_DIR", data)
	for _, args := range [][]string{
		{"-verify-release-files"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "-verify-release-files=false"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "-verify-release-files", "-release-artifact", "sora_1.2.3_amd64.deb", "-release-target", "linux/amd64"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "-verify-release-files", "-install-service"},
		{"-release-artifact="},
		{"-release-target", "linux/amd64", "-print-token"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "-release-artifact", "sora_1.2.3_amd64.deb"},
		{"-verify-release", t.TempDir(), "-release-version", "1.2.3", "-release-target", "linux/amd64"},
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

func TestReleaseLegacyManifestRejectedBeforeArtifacts(t *testing.T) {
	public, private, err := minisign.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	payload := []byte(strings.Repeat("a", 64) + "  sora_1.2.3_amd64.deb\n")
	signature, err := ext.SignPayload(private, "test", "release:v1.2.3:SHA256SUMS", 1700000000, payload)
	if err != nil {
		t.Fatal(err)
	}
	if err := ext.VerifyPayload(public.String(), signature, "release:v1.2.3:SHA256SUMS", payload); err != nil {
		t.Fatal(err)
	}
	for _, strayJSON := range []bool{false, true} {
		directory := t.TempDir()
		for name, data := range map[string][]byte{"SHA256SUMS": payload, "SHA256SUMS.minisig": []byte(signature)} {
			if err := os.WriteFile(filepath.Join(directory, name), data, 0o600); err != nil {
				t.Fatal(err)
			}
		}
		if strayJSON {
			if err := os.WriteFile(filepath.Join(directory, "release.json"), []byte("{}\n"), 0o600); err != nil {
				t.Fatal(err)
			}
		}
		if _, err := verifyRelease(directory, "1.2.3", public.String()); err == nil {
			t.Fatalf("retired signed legacy format accepted (stray JSON: %v)", strayJSON)
		}
	}
}
