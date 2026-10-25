package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
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
			valid := name == "1.0.4" || name == "1.0.5" || name == "wrong-size"
			if (err == nil) != valid {
				t.Fatalf("verification: %v", err)
			}
			if !valid {
				return
			}
			if manifest.metadata == nil || len(manifest.metadata.Artifacts) != 12 {
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
