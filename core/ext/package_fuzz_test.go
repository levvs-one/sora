package ext

import (
	"archive/zip"
	"bytes"
	"encoding/json"
	"testing"
)

// zipForFuzz builds an in-memory archive without a *testing.T (fuzz seed
// phase only has *testing.F). Contents are not signed: OpenBytes checks
// presence and manifest shape, not signatures - Verify is exercised
// separately inside the fuzz body.
func zipForFuzz(files map[string]string) []byte {
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	for name, body := range files {
		w, err := zw.Create(name)
		if err != nil {
			panic(err)
		}
		if _, err := w.Write([]byte(body)); err != nil {
			panic(err)
		}
	}
	if err := zw.Close(); err != nil {
		panic(err)
	}
	return buf.Bytes()
}

func fuzzPackageSeed() []byte {
	manifest, err := json.Marshal(testManifestForFuzz())
	if err != nil {
		panic(err)
	}
	return zipForFuzz(map[string]string{
		manifestName:  string(manifest),
		checksumsName: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  panel.html\n",
		signatureName: "untrusted comment: signature from test\nRWTfake\n",
		"panel.html":  "<html></html>",
	})
}

// FuzzOpenBytes throws hostile archives at the .soraext opener: the one
// parser every sideloaded and catalog-downloaded byte stream passes
// through before any signature check. Invariants: no panics, and a
// successfully opened package respects every format limit and path
// rule the opener advertises (safe canonical paths, per-file and total
// size caps, file-count cap, manifest re-validates).
func FuzzOpenBytes(f *testing.F) {
	f.Add(fuzzPackageSeed())
	f.Add([]byte{})
	f.Add([]byte("not a zip at all"))
	f.Add(zipForFuzz(map[string]string{"../evil": "x"}))
	f.Add(zipForFuzz(map[string]string{manifestName: "{}"}))
	// A directory entry plus a canonical file: standard zips carry dir
	// entries and must keep opening.
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	if _, err := zw.Create("assets/"); err != nil {
		f.Fatal(err)
	}
	manifest, _ := json.Marshal(testManifestForFuzz())
	for name, body := range map[string]string{
		manifestName: string(manifest), checksumsName: "x", signatureName: "y",
		"assets/panel.html": "<html></html>",
	} {
		w, err := zw.Create(name)
		if err != nil {
			f.Fatal(err)
		}
		if _, err := w.Write([]byte(body)); err != nil {
			f.Fatal(err)
		}
	}
	if err := zw.Close(); err != nil {
		f.Fatal(err)
	}
	f.Add(buf.Bytes())

	f.Fuzz(func(t *testing.T, data []byte) {
		pkg, err := OpenBytes(data)
		if err != nil {
			return // rejection is always acceptable
		}
		if len(pkg.Files) > maxPackageFiles {
			t.Fatalf("opened %d files, cap is %d", len(pkg.Files), maxPackageFiles)
		}
		var total int64
		for name, content := range pkg.Files {
			if !isSafeArchivePath(name) {
				t.Fatalf("opened package with unsafe path %q", name)
			}
			if int64(len(content)) > maxSingleFile {
				t.Fatalf("file %q is %d bytes, cap is %d", name, len(content), maxSingleFile)
			}
			total += int64(len(content))
		}
		if total > maxUncompressedBytes {
			t.Fatalf("opened %d content bytes, cap is %d", total, maxUncompressedBytes)
		}
		if err := pkg.Manifest.Validate(); err != nil {
			t.Fatalf("opened package whose manifest does not re-validate: %v", err)
		}
		// Verify must never panic on an opened package, whatever the
		// checksums/signature bytes are.
		_ = pkg.Verify()
	})
}
