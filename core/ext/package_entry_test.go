package ext

import (
	"archive/zip"
	"bytes"
	"encoding/json"
	"strings"
	"testing"
	"time"
)

// buildSignedPackage assembles a signed .soraext from explicit manifest
// bytes and an explicit content file set, so a test can declare an entry
// in the manifest and then NOT ship the file (the case checkDeclaredEntries
// exists for). Checksums cover exactly the shipped files, so the checksum
// and signature layers pass and only the existence check can refuse.
func buildSignedPackage(t *testing.T, manRaw []byte, files map[string]string) []byte {
	t.Helper()
	strFiles := map[string]string{manifestName: string(manRaw)}
	for k, v := range files {
		strFiles[k] = v
	}
	checksums := MakeChecksums(strFiles)
	sig, err := SignPayload(testPrivateKey(testSeed), "test key", sigFileChecksums, time.Now().Unix(), []byte(checksums))
	if err != nil {
		t.Fatal(err)
	}
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	write := func(name string, data []byte) {
		w, err := zw.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.Write(data); err != nil {
			t.Fatal(err)
		}
	}
	write(manifestName, manRaw)
	write(checksumsName, []byte(checksums))
	write(signatureName, []byte(sig))
	names := make([]string, 0, len(files))
	for k := range files {
		names = append(names, k)
	}
	for _, k := range names {
		write(k, []byte(files[k]))
	}
	if err := zw.Close(); err != nil {
		t.Fatal(err)
	}
	return buf.Bytes()
}

func TestVerifyRejectsMissingPanelFile(t *testing.T) {
	m := testManifest(t) // declares panel "panel.html"
	raw, err := json.Marshal(m)
	if err != nil {
		t.Fatal(err)
	}
	pkg, err := OpenBytes(buildSignedPackage(t, raw, map[string]string{"other.txt": "x"}))
	if err != nil {
		t.Fatalf("OpenBytes: %v", err)
	}
	if err := pkg.Verify(); err == nil || !strings.Contains(err.Error(), "panel.html") {
		t.Fatalf("a package missing its declared panel file must fail Verify, got %v", err)
	}
	// Positive control: ship the panel and the same package verifies.
	pkg, err = OpenBytes(buildSignedPackage(t, raw, map[string]string{"panel.html": "<html></html>"}))
	if err != nil {
		t.Fatalf("OpenBytes: %v", err)
	}
	if err := pkg.Verify(); err != nil {
		t.Fatalf("complete package must verify: %v", err)
	}
}

func TestVerifyRejectsMissingRuntimeEntries(t *testing.T) {
	cases := []struct {
		name  string
		extra map[string]any
		files map[string]string
		want  string
	}{
		{
			name: "worker script",
			extra: map[string]any{
				"background_task": map[string]any{"interval_minutes": 30, "entry": "worker.js"},
			},
			files: map[string]string{},
			want:  "worker.js",
		},
		{
			name: "theme asset",
			extra: map[string]any{
				"theme": map[string]any{"entry": "theme.json"},
			},
			files: map[string]string{},
			want:  "theme.json",
		},
		{
			name: "network hook asset",
			extra: map[string]any{
				"network_hook": map[string]any{"entry": "hook.json"},
			},
			files: map[string]string{},
			want:  "hook.json",
		},
		{
			name: "routing asset",
			extra: map[string]any{
				"routing": map[string]any{"entry": "routing.json"},
			},
			files: map[string]string{},
			want:  "routing.json",
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			m := bgManifest(t)
			m.UI = &UIManifest{Panels: []Panel{{ID: "main", Title: "Hi", Entry: "panel.html"}}}
			m.Capabilities = []string{"background", "theme", "network-hook", "routing", "ui-panel"}
			m.Permissions = []string{"background", "net.fetch", "theme.apply", "net.hooks", "routing.rules", "ui.panel"}
			raw := rawManifestWith(t, m, tc.extra)
			files := map[string]string{"panel.html": "<html></html>"}
			for k, v := range tc.files {
				files[k] = v
			}
			pkg, err := OpenBytes(buildSignedPackage(t, raw, files))
			if err != nil {
				t.Fatalf("OpenBytes: %v", err)
			}
			if err := pkg.Verify(); err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("missing %s must fail Verify, got %v", tc.want, err)
			}
		})
	}
}

func TestOpenBytesRejectsAliasedPanelPath(t *testing.T) {
	// The manifest declares "panel.html"; the archive stores the file as
	// "./panel.html" and checksums list it under the alias. Accepting it
	// would serve a panel the CSP injector never matched and break
	// rollback re-verification (the on-disk name is canonical).
	m := testManifest(t)
	raw, err := json.Marshal(m)
	if err != nil {
		t.Fatal(err)
	}
	strFiles := map[string]string{manifestName: string(raw), "./panel.html": "<html></html>"}
	checksums := MakeChecksums(strFiles)
	sig, err := SignPayload(testPrivateKey(testSeed), "test key", sigFileChecksums, time.Now().Unix(), []byte(checksums))
	if err != nil {
		t.Fatal(err)
	}
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	for name, data := range map[string][]byte{
		manifestName: raw, checksumsName: []byte(checksums),
		signatureName: []byte(sig), "./panel.html": []byte("<html></html>"),
	} {
		w, err := zw.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.Write(data); err != nil {
			t.Fatal(err)
		}
	}
	if err := zw.Close(); err != nil {
		t.Fatal(err)
	}
	if _, err := OpenBytes(buf.Bytes()); err == nil {
		t.Fatal("an aliased (./) archive path must be rejected at open")
	}
}

func TestOpenBytesAcceptsDirectoryEntries(t *testing.T) {
	// Standard zips may carry explicit directory entries; they hold no
	// content, are never extracted, and must not fail the open.
	m := testManifest(t)
	raw, err := json.Marshal(m)
	if err != nil {
		t.Fatal(err)
	}
	data := buildSignedPackage(t, raw, map[string]string{"panel.html": "<html></html>", "assets/note.txt": "n"})
	// Rebuild with a directory entry inserted: unzip, rezip.
	zr, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		t.Fatal(err)
	}
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	if _, err := zw.Create("assets/"); err != nil {
		t.Fatal(err)
	}
	for _, f := range zr.File {
		rc, err := f.Open()
		if err != nil {
			t.Fatal(err)
		}
		var b bytes.Buffer
		if _, err := b.ReadFrom(rc); err != nil {
			t.Fatal(err)
		}
		_ = rc.Close()
		w, err := zw.Create(f.Name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.Write(b.Bytes()); err != nil {
			t.Fatal(err)
		}
	}
	if err := zw.Close(); err != nil {
		t.Fatal(err)
	}
	pkg, err := OpenBytes(buf.Bytes())
	if err != nil {
		t.Fatalf("a package with a directory entry must open: %v", err)
	}
	if err := pkg.Verify(); err != nil {
		t.Fatalf("a package with a directory entry must verify: %v", err)
	}
}
