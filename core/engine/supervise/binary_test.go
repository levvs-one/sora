package supervise

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestBinaryVerifyDigest(t *testing.T) {
	for _, size := range []int{0, 1, 32769, 2 << 20} {
		t.Run(strconv.Itoa(size), func(t *testing.T) {
			raw := bytes.Repeat([]byte{0x81}, size)
			path := filepath.Join(t.TempDir(), "engine")
			if err := os.WriteFile(path, raw, 0o600); err != nil {
				t.Fatal(err)
			}
			sum := sha256.Sum256(raw)
			digest := hex.EncodeToString(sum[:])
			binary := Binary{Kind: engine.KindXray, Path: path}
			for _, expected := range []string{digest, " \t" + strings.ToUpper(digest) + "\n"} {
				if err := binary.VerifyDigest(expected); err != nil {
					t.Fatal(err)
				}
			}
			for _, expected := range []string{"", " ", "malformed", digest[:63], strings.Repeat("0", 64)} {
				if err := binary.VerifyDigest(expected); err == nil {
					t.Fatalf("accepted incorrect digest %q", expected)
				}
			}
			if err := os.WriteFile(path, append(raw, 0x82), 0o600); err != nil {
				t.Fatal(err)
			}
			if err := binary.VerifyDigest(digest); err == nil {
				t.Fatal("accepted an appended byte")
			}
		})
	}
	for _, path := range []string{filepath.Join(t.TempDir(), "missing"), t.TempDir()} {
		binary := Binary{Kind: engine.KindXray, Path: path}
		if err := binary.VerifyDigest(strings.Repeat("0", 64)); err == nil {
			t.Fatalf("accepted non-file %q", path)
		}
	}
}

func BenchmarkBinaryVerifyDigest(b *testing.B) {
	const size = 8 << 20
	raw := bytes.Repeat([]byte{0x81}, size)
	path := filepath.Join(b.TempDir(), "engine")
	if err := os.WriteFile(path, raw, 0o600); err != nil {
		b.Fatal(err)
	}
	sum := sha256.Sum256(raw)
	digest := hex.EncodeToString(sum[:])
	binary := Binary{Kind: engine.KindXray, Path: path}
	b.ReportAllocs()
	b.SetBytes(size)
	b.ResetTimer()
	for b.Loop() {
		if err := binary.VerifyDigest(digest); err != nil {
			b.Fatal(err)
		}
	}
}
