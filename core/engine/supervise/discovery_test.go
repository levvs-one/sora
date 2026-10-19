package supervise

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"time"
)

// fakeProber pretends to be an engine whose "binary" is a shell script.
func fakeProber() Prober {
	return Prober{
		Kind:   "fake-engine",
		Name:   "sing-box",
		EnvVar: "SORA_TEST_FAKE_BIN",
		Args:   []string{"version"},
		Pattern: regexp.MustCompile(`^sing-box version v?(\d+\.\d+\.\d+)`),
	}
}

func writeFakeEngine(t *testing.T, dir string) string {
	t.Helper()
	path := filepath.Join(dir, "sing-box")
	script := "#!/bin/sh\necho 'sing-box version 1.14.3'\n"
	if err := os.WriteFile(path, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	return path
}

func writeDigests(t *testing.T, dir, name string, sum []byte) {
	t.Helper()
	line := hex.EncodeToString(sum) + "  " + name + "\n"
	if err := os.WriteFile(filepath.Join(dir, digestsFile), []byte(line), 0o644); err != nil {
		t.Fatal(err)
	}
}

func sha256Of(t *testing.T, path string) []byte {
	t.Helper()
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	sum := sha256.Sum256(raw)
	return sum[:]
}

func discoverWithTimeout(t *testing.T, pr Prober, dir string, opts DiscoveryOptions) (Binary, error) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	return pr.Discover(ctx, dir, opts)
}

// TestDiscoverVerifiesDigest locks SORA-H5: only digest-verified binaries from
// the engines directory are executed.
func TestDiscoverVerifiesDigest(t *testing.T) {
	pr := fakeProber()

	t.Run("verified binary is discovered", func(t *testing.T) {
		dir := t.TempDir()
		path := writeFakeEngine(t, dir)
		writeDigests(t, dir, "sing-box", sha256Of(t, path))
		b, err := discoverWithTimeout(t, pr, dir, DiscoveryOptions{})
		if err != nil {
			t.Fatalf("Discover() error = %v", err)
		}
		if b.Path != path {
			t.Fatalf("Discover() path = %q, want %q", b.Path, path)
		}
	})

	t.Run("tampered binary is rejected", func(t *testing.T) {
		dir := t.TempDir()
		path := writeFakeEngine(t, dir)
		writeDigests(t, dir, "sing-box", sha256Of(t, path))
		// Tamper after the manifest was written.
		if err := os.WriteFile(path, []byte("#!/bin/sh\necho 'sing-box version 9.9.9'\n"), 0o755); err != nil {
			t.Fatal(err)
		}
		if _, err := discoverWithTimeout(t, pr, dir, DiscoveryOptions{}); err == nil {
			t.Fatal("Discover() accepted a binary whose digest does not match the manifest")
		} else if !strings.Contains(err.Error(), "digest mismatch") {
			t.Fatalf("Discover() error = %v, want a digest mismatch", err)
		}
	})

	t.Run("missing manifest fails closed", func(t *testing.T) {
		dir := t.TempDir()
		writeFakeEngine(t, dir)
		if _, err := discoverWithTimeout(t, pr, dir, DiscoveryOptions{}); err == nil {
			t.Fatal("Discover() accepted a binary with no engines.digests manifest")
		} else if !strings.Contains(err.Error(), "engines.digests") {
			t.Fatalf("Discover() error = %v, want it to mention engines.digests", err)
		}
	})

	t.Run("PATH is never consulted", func(t *testing.T) {
		binDir := t.TempDir()
		writeFakeEngine(t, binDir)
		t.Setenv("PATH", binDir+string(os.PathListSeparator)+os.Getenv("PATH"))
		dir := t.TempDir() // engines dir without the binary
		if _, err := discoverWithTimeout(t, pr, dir, DiscoveryOptions{}); err == nil {
			t.Fatal("Discover() found the engine via PATH; the PATH fallback must stay removed")
		}
	})

	t.Run("env override needs the explicit flag", func(t *testing.T) {
		dir := t.TempDir()
		path := writeFakeEngine(t, dir)
		t.Setenv(pr.EnvVar, path)
		if _, err := discoverWithTimeout(t, pr, t.TempDir(), DiscoveryOptions{}); err == nil {
			t.Fatal("Discover() honored the env override without --allow-env-bin")
		}
		b, err := discoverWithTimeout(t, pr, t.TempDir(), DiscoveryOptions{AllowEnvBin: true})
		if err != nil {
			t.Fatalf("Discover() with AllowEnvBin error = %v", err)
		}
		if b.Path != path {
			t.Fatalf("Discover() path = %q, want %q", b.Path, path)
		}
	})
}
