package main

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"aead.dev/minisign"

	"github.com/levvs-one/sora-client/core/ext"
)

func TestReleaseMetadataCrossLanguageFixtures(t *testing.T) {
	data, err := os.ReadFile("../../../app/test/fixtures/releases/metadata.json")
	if err != nil {
		t.Fatal(err)
	}
	var fixtures struct {
		PublicKey string                       `json:"public_key"`
		Releases  map[string]map[string]string `json:"releases"`
		Cases     map[string]map[string]string `json:"cases"`
	}
	if err := json.Unmarshal(data, &fixtures); err != nil {
		t.Fatal(err)
	}
	for name, record := range fixtures.Releases {
		fixtures.Cases[name] = record
	}
	for name, record := range fixtures.Cases {
		t.Run(name, func(t *testing.T) {
			version := "1.0.5"
			if name == "1.0.4" {
				version = name
			}
			directory := t.TempDir()
			for field, filename := range map[string]string{"manifest": "SHA256SUMS", "signature": "SHA256SUMS.minisig", "metadata": "release.json"} {
				if err := os.WriteFile(filepath.Join(directory, filename), []byte(record[field]), 0o600); err != nil {
					t.Fatal(err)
				}
			}
			manifest, err := verifyRelease(directory, version, fixtures.PublicKey)
			valid := name == "1.0.4" || name == "1.0.5" || name == "wrong-size" || name == "previous-matrix"
			if (err == nil) != valid {
				t.Fatalf("verification: %v", err)
			}
			if !valid {
				return
			}
			expectedArtifacts := 15
			if name == "previous-matrix" {
				expectedArtifacts = 12
			}
			if manifest.metadata == nil || len(manifest.metadata.Artifacts) != expectedArtifacts {
				t.Fatal("producer metadata was not loaded")
			}
			for _, artifact := range manifest.metadata.Artifacts {
				if artifact.Arch == "any" {
					continue
				}
				size, err := manifest.artifactSize(artifact.Name, artifact.OS+"/"+artifact.Arch, version)
				expected := int64(3)
				if name == "wrong-size" {
					expected = 4
				}
				if err != nil || size != expected {
					t.Fatalf("artifact query: %d, %v", size, err)
				}
				if _, err := manifest.artifactSize(artifact.Name, "wrong/target", version); err == nil {
					t.Fatal("wrong target was accepted")
				}
			}
			if _, err := manifest.artifactSize("../package", "linux/amd64", version); err == nil {
				t.Fatal("unknown artifact was accepted")
			}
			for _, problem := range []string{"missing", "tamper", "oversize", "empty", "directory", "symlink"} {
				t.Run(problem, func(t *testing.T) {
					metadata := filepath.Join(directory, "release.json")
					if err := os.RemoveAll(metadata); err != nil {
						t.Fatal(err)
					}
					switch problem {
					case "tamper":
						err = os.WriteFile(metadata, []byte(record["metadata"]+" "), 0o600)
					case "oversize":
						err = os.WriteFile(metadata, make([]byte, 1024*1024+1), 0o600)
					case "empty":
						err = os.WriteFile(metadata, nil, 0o600)
					case "directory":
						err = os.Mkdir(metadata, 0o700)
					case "symlink":
						err = os.Symlink(filepath.Join(directory, "SHA256SUMS"), metadata)
						if err != nil {
							t.Skipf("symlink unavailable: %v", err)
						}
					}
					if err != nil {
						t.Fatal(err)
					}
					if _, err := verifyRelease(directory, version, fixtures.PublicKey); err == nil {
						t.Fatal("invalid metadata file accepted")
					}
				})
			}
		})
	}
}

func TestReleaseFullSnapshotGate(t *testing.T) {
	data, err := os.ReadFile("../../../app/test/fixtures/releases/metadata.json")
	if err != nil {
		t.Fatal(err)
	}
	var fixtures struct {
		PublicKey string                       `json:"public_key"`
		Releases  map[string]map[string]string `json:"releases"`
		Cases     map[string]map[string]string `json:"cases"`
	}
	if err := json.Unmarshal(data, &fixtures); err != nil {
		t.Fatal(err)
	}
	for _, problem := range []string{"valid", "previous matrix", "missing", "short", "long", "oversize sparse", "hash", "directory", "symlink", "extra", "many extras", "wrong signed size", "manifest mutation", "signature mutation", "metadata mutation"} {
		t.Run(problem, func(t *testing.T) {
			if problem == "oversize sparse" && runtime.GOOS != "linux" {
				t.Skip("Linux sparse-file guard; other platforms exercise an oversized byte fixture")
			}
			directory := t.TempDir()
			record := fixtures.Releases["1.0.5"]
			if problem == "previous matrix" {
				record = fixtures.Cases["previous-matrix"]
			}
			if problem == "wrong signed size" {
				record = fixtures.Cases["wrong-size"]
			}
			for field, filename := range map[string]string{"manifest": "SHA256SUMS", "signature": "SHA256SUMS.minisig", "metadata": "release.json"} {
				if err := os.WriteFile(filepath.Join(directory, filename), []byte(record[field]), 0o600); err != nil {
					t.Fatal(err)
				}
			}
			manifest, err := verifyRelease(directory, "1.0.5", fixtures.PublicKey)
			if err != nil {
				t.Fatal(err)
			}
			for _, artifact := range manifest.metadata.Artifacts {
				if err := os.WriteFile(filepath.Join(directory, artifact.Name), []byte("abc"), 0o600); err != nil {
					t.Fatal(err)
				}
			}
			file := filepath.Join(directory, manifest.metadata.Artifacts[0].Name)
			switch problem {
			case "missing", "directory", "symlink":
				if err := os.Remove(file); err != nil {
					t.Fatal(err)
				}
				switch problem {
				case "directory":
					err = os.Mkdir(file, 0o700)
				case "symlink":
					err = os.Symlink(filepath.Join(directory, "install.sh"), file)
					if err != nil {
						t.Skipf("symlink unavailable: %v", err)
					}
				}
			case "short":
				err = os.WriteFile(file, []byte("ab"), 0o600)
			case "long":
				err = os.WriteFile(file, []byte("abcd"), 0o600)
			case "oversize sparse":
				err = os.Truncate(file, 2*1024*1024*1024+1)
			case "hash":
				err = os.WriteFile(file, []byte("xyz"), 0o600)
			case "extra", "many extras":
				count := 1
				if problem == "many extras" {
					count = 1000
				}
				for i := 0; i < count; i++ {
					if err := os.WriteFile(filepath.Join(directory, fmt.Sprintf("extra-%04d", i)), []byte("x"), 0o600); err != nil {
						t.Fatal(err)
					}
				}
			case "manifest mutation":
				err = os.WriteFile(filepath.Join(directory, "SHA256SUMS"), []byte(record["manifest"]+" "), 0o600)
			case "signature mutation":
				err = os.WriteFile(filepath.Join(directory, "SHA256SUMS.minisig"), []byte("untrusted"), 0o600)
			case "metadata mutation":
				err = os.WriteFile(filepath.Join(directory, "release.json"), []byte(record["metadata"]+" "), 0o600)
			}
			if err != nil {
				t.Fatal(err)
			}
			err = manifest.verifyArtifactFiles(context.Background(), directory)
			if (err == nil) != (problem == "valid") {
				t.Fatalf("full snapshot verification: %v", err)
			}
		})
	}
}

func TestReleaseFullGateRejectsAnAuthenticatedPartialMatrix(t *testing.T) {
	public, private, err := minisign.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	artifact := releaseArtifact{Arch: "amd64", Name: "Sora-Setup-1.2.3-x64.exe", OS: "windows", SHA256: fmt.Sprintf("%x", sha256.Sum256([]byte("abc"))), Size: 3}
	metadata, err := json.Marshal(releaseMetadata{Artifacts: []releaseArtifact{artifact}, Schema: 1, Version: "1.2.3"})
	if err != nil {
		t.Fatal(err)
	}
	metadata = append(metadata, '\n')
	payload := []byte(fmt.Sprintf("%s  %s\n%x  release.json\n", artifact.SHA256, artifact.Name, sha256.Sum256(metadata)))
	signature, err := ext.SignPayload(private, "test", "release:v1.2.3:SHA256SUMS", 1700000000, payload)
	if err != nil {
		t.Fatal(err)
	}
	directory := t.TempDir()
	for name, data := range map[string][]byte{"SHA256SUMS": payload, "SHA256SUMS.minisig": []byte(signature), "release.json": metadata, artifact.Name: []byte("abc")} {
		if err := os.WriteFile(filepath.Join(directory, name), data, 0o600); err != nil {
			t.Fatal(err)
		}
	}
	manifest, err := verifyRelease(directory, "1.2.3", public.String())
	if err != nil {
		t.Fatal(err)
	}
	if err := manifest.verifyArtifactFiles(context.Background(), directory); err == nil {
		t.Fatal("partial signed snapshot passed the publication profile")
	}
}

func TestReleaseArtifactHashRespondsToCancellation(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("large sparse-file cancellation fixture is Linux-only")
	}
	directory := t.TempDir()
	file := filepath.Join(directory, "large-package")
	if err := os.WriteFile(file, nil, 0o600); err != nil {
		t.Fatal(err)
	}
	const size = 2 * 1024 * 1024 * 1024
	if err := os.Truncate(file, size); err != nil {
		t.Fatal(err)
	}
	root, err := os.OpenRoot(directory)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = root.Close() }()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	timer := time.AfterFunc(5*time.Millisecond, cancel)
	defer timer.Stop()
	if err := verifyReleaseArtifactFile(ctx, root, releaseArtifact{Name: "large-package", Size: size}); !errors.Is(err, context.Canceled) {
		t.Fatalf("hash did not stop on cancellation: %v", err)
	}
}
