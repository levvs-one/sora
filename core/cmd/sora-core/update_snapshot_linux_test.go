package main

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"aead.dev/minisign"
	"golang.org/x/sys/unix"

	"github.com/levvs-one/sora-client/core/ext"
)

func updateSnapshotFixture(t *testing.T) (string, string) {
	t.Helper()
	data, err := os.ReadFile("../../../app/test/fixtures/releases/metadata.json")
	if err != nil {
		t.Fatal(err)
	}
	var fixture struct {
		PublicKey string                       `json:"public_key"`
		Releases  map[string]map[string]string `json:"releases"`
	}
	if err := json.Unmarshal(data, &fixture); err != nil {
		t.Fatal(err)
	}
	source := t.TempDir()
	record := fixture.Releases["1.0.5"]
	for field, name := range map[string]string{"manifest": "SHA256SUMS", "signature": "SHA256SUMS.minisig", "metadata": "release.json"} {
		if err := os.WriteFile(filepath.Join(source, name), []byte(record[field]), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	var metadata releaseMetadata
	if err := json.Unmarshal([]byte(record["metadata"]), &metadata); err != nil {
		t.Fatal(err)
	}
	for _, artifact := range metadata.Artifacts {
		if err := os.WriteFile(filepath.Join(source, artifact.Name), []byte("abc"), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	return source, fixture.PublicKey
}

func TestPrepareUpdateSnapshotFormatsAndLegacy(t *testing.T) {
	for _, format := range []string{"deb", "rpm", "arch", "legacy"} {
		t.Run(format, func(t *testing.T) {
			source, key := updateSnapshotFixture(t)
			if format == "legacy" {
				format = "deb"
				public, private, err := minisign.GenerateKey(rand.Reader)
				if err != nil {
					t.Fatal(err)
				}
				key = public.String()
				payload := []byte("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad  sora-core_1.0.5_amd64.deb\n" +
					"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad  sora_1.0.5_amd64.deb\n")
				signature, err := ext.SignPayload(private, "test", "release:v1.0.5:SHA256SUMS", 1700000000, payload)
				if err != nil {
					t.Fatal(err)
				}
				if err := os.WriteFile(filepath.Join(source, "SHA256SUMS"), payload, 0o600); err != nil {
					t.Fatal(err)
				}
				if err := os.WriteFile(filepath.Join(source, "SHA256SUMS.minisig"), []byte(signature), 0o600); err != nil {
					t.Fatal(err)
				}
				if err := os.Remove(filepath.Join(source, "release.json")); err != nil {
					t.Fatal(err)
				}
			}
			target := t.TempDir()
			if err := os.Chmod(target, 0o700); err != nil {
				t.Fatal(err)
			}
			if err := prepareUpdateSnapshot(context.Background(), format, "1.0.5", source, target, key); err != nil {
				t.Fatal(err)
			}
			entries, err := os.ReadDir(target)
			if err != nil || (len(entries) != 4 && len(entries) != 5) {
				t.Fatalf("unexpected selected snapshot: %v, %v", entries, err)
			}
			for _, entry := range entries {
				info, err := entry.Info()
				if err != nil || !info.Mode().IsRegular() || info.Mode().Perm() != 0o600 {
					t.Fatalf("snapshot mode: %v, %v", info, err)
				}
			}
		})
	}
}

func TestPrepareUpdateSnapshotRejectsAndCleans(t *testing.T) {
	for _, problem := range []string{"manifest", "signature", "json", "package", "oversize metadata", "oversize package", "empty", "missing", "symlink", "hardlink", "fifo", "directory", "wrong key", "cancelled"} {
		t.Run(problem, func(t *testing.T) {
			source, key := updateSnapshotFixture(t)
			target := t.TempDir()
			if err := os.Chmod(target, 0o700); err != nil {
				t.Fatal(err)
			}
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()
			file := filepath.Join(source, "sora_1.0.5_amd64.deb")
			var err error
			switch problem {
			case "manifest":
				err = os.WriteFile(filepath.Join(source, "SHA256SUMS"), []byte("tampered"), 0o600)
			case "signature":
				err = os.WriteFile(filepath.Join(source, "SHA256SUMS.minisig"), []byte("tampered"), 0o600)
			case "json":
				err = os.WriteFile(filepath.Join(source, "release.json"), []byte("{}"), 0o600)
			case "package":
				err = os.WriteFile(file, []byte("bad"), 0o600)
			case "oversize metadata", "oversize package":
				length := int64(2147483649)
				if problem == "oversize metadata" {
					file, length = filepath.Join(source, "SHA256SUMS"), 1048577
				}
				err = os.Truncate(file, length)
			case "empty":
				err = os.Truncate(file, 0)
			case "missing":
				err = os.Remove(file)
			case "symlink", "fifo", "directory":
				if err := os.Remove(file); err != nil {
					t.Fatal(err)
				}
				switch problem {
				case "symlink":
					err = os.Symlink("sora-core_1.0.5_amd64.deb", file)
				case "fifo":
					err = unix.Mkfifo(file, 0o600)
				case "directory":
					err = os.Mkdir(file, 0o700)
				}
			case "hardlink":
				err = os.Link(file, filepath.Join(source, "second-link"))
			case "wrong key":
				key = releasePublicKey
			case "cancelled":
				cancel()
			}
			if err != nil {
				t.Fatal(err)
			}
			if err := prepareUpdateSnapshot(ctx, "deb", "1.0.5", source, target, key); err == nil || strings.Contains(err.Error(), "snapshot directory") {
				t.Fatalf("unsafe snapshot was not rejected at the input boundary: %v", err)
			}
			entries, err := os.ReadDir(target)
			if err != nil || len(entries) != 0 {
				t.Fatalf("failed snapshot was not cleaned: %v, %v", entries, err)
			}
		})
	}
}

func TestPrepareUpdateSnapshotDestinationAndArguments(t *testing.T) {
	source, key := updateSnapshotFixture(t)
	for _, problem := range []string{"permissions", "nonempty", "relative source", "relative target", "format", "version"} {
		t.Run(problem, func(t *testing.T) {
			target, from, format, version := t.TempDir(), source, "deb", "1.0.5"
			if err := os.Chmod(target, 0o700); err != nil {
				t.Fatal(err)
			}
			var err error
			switch problem {
			case "permissions":
				err = os.Chmod(target, 0o755)
			case "nonempty":
				err = os.WriteFile(filepath.Join(target, "preserve"), []byte("owned data"), 0o600)
			case "relative source":
				from = "."
			case "relative target":
				target = "."
			case "format":
				format = "../../escape"
			case "version":
				version = "1.0.5;touch /tmp/escaped"
			}
			if err != nil {
				t.Fatal(err)
			}
			if err := prepareUpdateSnapshot(context.Background(), format, version, from, target, key); err == nil {
				t.Fatal("unsafe destination or arguments accepted")
			}
			if problem == "nonempty" {
				if data, err := os.ReadFile(filepath.Join(target, "preserve")); err != nil || string(data) != "owned data" {
					t.Fatal("preexisting destination was changed")
				}
			}
		})
	}
	for _, extra := range []string{"-install-service", "-print-token", "-version", "-verify-release-files"} {
		args := []string{"-prepare-update", "deb", "-release-version", "1.0.5", extra, source, t.TempDir()}
		if err := run(context.Background(), args); err == nil || !strings.Contains(err.Error(), "other flags are forbidden") {
			t.Fatalf("mixed mode accepted: %v", err)
		}
	}
	target := t.TempDir()
	if err := os.Chmod(target, 0o700); err != nil {
		t.Fatal(err)
	}
	// This fixture is not signed by the production root used by run. Reaching
	// authentication proves that this mode parsed without serving/installing.
	args := []string{"-prepare-update", "deb", "-release-version", "1.0.5", source, target}
	if err := run(context.Background(), args); err == nil || !strings.Contains(err.Error(), "untrusted SHA256SUMS") {
		t.Fatalf("valid preparation flags did not reach authentication: %v", err)
	}
}

func TestPrepareUpdateAuthenticatesBeforeOpeningPackages(t *testing.T) {
	source, key := updateSnapshotFixture(t)
	if err := os.WriteFile(filepath.Join(source, "SHA256SUMS"), []byte("tampered"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Remove(filepath.Join(source, "sora-core_1.0.5_amd64.deb")); err != nil {
		t.Fatal(err)
	}
	target := t.TempDir()
	if err := os.Chmod(target, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := prepareUpdateSnapshot(context.Background(), "deb", "1.0.5", source, target, key); err == nil ||
		!strings.Contains(err.Error(), "untrusted SHA256SUMS") {
		t.Fatalf("package access preceded authentication: %v", err)
	}
}

func TestUpdateSnapshotOpenRootSurvivesSourceRename(t *testing.T) {
	parent := t.TempDir()
	source := filepath.Join(parent, "downloads")
	if err := os.Mkdir(source, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(source, "file"), []byte("abc"), 0o600); err != nil {
		t.Fatal(err)
	}
	input, err := os.OpenRoot(source)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = input.Close() }()
	if err := os.Rename(source, source+"-old"); err != nil {
		t.Fatal(err)
	}
	if err := os.Mkdir(source, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(source, "file"), []byte("bad"), 0o600); err != nil {
		t.Fatal(err)
	}
	target := t.TempDir()
	output, err := os.OpenRoot(target)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = output.Close() }()
	if err := copyUpdateSnapshotFile(context.Background(), input, output, "file", 3); err != nil {
		t.Fatal(err)
	}
	if data, err := os.ReadFile(filepath.Join(target, "file")); err != nil || string(data) != "abc" {
		t.Fatalf("source directory path was reopened: %q, %v", data, err)
	}
}
