package ext

import (
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"strings"
	"testing"
)

// testPubKeyLineForFuzz is testPubKeyLine without the *testing.T dependency.
func testPubKeyLineForFuzz() string {
	priv := ed25519.NewKeyFromSeed(testSeed)
	pub := priv.Public().(ed25519.PublicKey)
	raw := append([]byte{'E', 'd'}, make([]byte, 8)...)
	raw = append(raw, pub...)
	return base64.StdEncoding.EncodeToString(raw)
}

// testManifestForFuzz is testManifest without the *testing.T dependency.
func testManifestForFuzz() *Manifest {
	return &Manifest{
		ManifestVersion: 1,
		ID:              "com.example.hello",
		Name:            "Hello Panel",
		Version:         "1.0.0",
		MinAppVersion:   "1.9.0",
		Description:     "An example panel.",
		Author:          Author{Name: "Example", Identity: "github:example", PublicKey: testPubKeyLineForFuzz()},
		Permissions:     []string{"connections.read", "notifications"},
		Capabilities:    []string{"ui-panel"},
		UI:              &UIManifest{Panels: []Panel{{ID: "main", Title: "Hello", Entry: "panel.html"}}},
	}
}

// FuzzParseManifest throws malformed, overlong and unicode-hostile inputs at
// the manifest validator. Invariants: it must never panic, and a successful
// parse must always describe a manifest that re-validates and satisfies the
// structural rules (id shape, semver, known/unique permissions and
// capabilities, safe panel entries).
func FuzzParseManifest(f *testing.F) {
	// Seed corpus: the canonical valid manifest, plus hostile variants.
	valid, err := json.Marshal(testManifestForFuzz())
	if err != nil {
		f.Fatal(err)
	}
	seeds := [][]byte{
		valid,
		[]byte(`{}`),
		[]byte(`{"manifest_version":1,"id":"com.example.x","name":"x","version":"1.0.0","min_app_version":"1.0.0","author":{"name":"a","identity":"i","public_key":"` + testPubKeyLineForFuzz() + `"},"permissions":[],"capabilities":[]}`),
		[]byte(strings.Repeat(`{"a":`, 5000)),                         // deep nesting
		[]byte(`{"manifest_version":1` + strings.Repeat(" ", 999999)), // truncated, huge
		[]byte("\xff\xfe\x00malformed utf-8 \x80\x81"),
		[]byte("null"),
		[]byte("[]"),
		[]byte(`"just a string"`),
		// Unicode tricks: lookalike dots, RTL overrides, zero-width chars.
		[]byte("{\"manifest_version\":1,\"id\":\"com\u3002example\u200bx\",\"name\":\"\u202ex\",\"version\":\"1.0.0\",\"min_app_version\":\"1.0.0\",\"author\":{\"name\":\"a\",\"identity\":\"i\",\"public_key\":\"" + testPubKeyLineForFuzz() + "\"}}"),
	}
	for _, s := range seeds {
		f.Add(s)
	}

	f.Fuzz(func(t *testing.T, data []byte) {
		m, err := ParseManifest(data)
		if err != nil {
			return // rejection is always acceptable
		}
		// A successful parse must re-validate: Validate is what Parse
		// already ran, so any failure here is an internal inconsistency.
		if err := m.Validate(); err != nil {
			t.Fatalf("ParseManifest accepted input that does not re-validate: %v\ninput: %.200q", err, data)
		}
		// Structural invariants, checked independently of Validate's code
		// path so a future Validate regression is caught here too.
		if !idPattern.MatchString(m.ID) {
			t.Fatalf("accepted bad id %q", m.ID)
		}
		if !semverPattern.MatchString(m.Version) || !semverPattern.MatchString(m.MinAppVersion) {
			t.Fatalf("accepted bad semver %q / %q", m.Version, m.MinAppVersion)
		}
		seen := map[string]bool{}
		for _, p := range m.Permissions {
			if !IsKnownPermission(p) {
				t.Fatalf("accepted unknown permission %q", p)
			}
			if seen[p] {
				t.Fatalf("accepted duplicate permission %q", p)
			}
			seen[p] = true
		}
		for _, c := range m.Capabilities {
			if !allowedCapabilities[c] {
				t.Fatalf("accepted unknown capability %q", c)
			}
		}
		if m.UI != nil {
			for _, p := range m.UI.Panels {
				if !isSafeEntry(p.Entry) {
					t.Fatalf("accepted unsafe panel entry %q", p.Entry)
				}
			}
		}
	})
}

// FuzzParseChecksums fuzzes the checksums.txt parser: no panics, and an
// accepted file must round-trip through MakeChecksums-style validation
// (every line a 64-hex digest plus a safe path, no duplicates).
func FuzzParseChecksums(f *testing.F) {
	f.Add("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  panel.html\n")
	f.Add("")
	f.Add("\xff\xfe bad \x80 bytes\n")
	f.Add("nothex  panel.html\n")
	f.Add("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  ../../evil\n")
	f.Add("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  a\n" +
		"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  a\n")

	f.Fuzz(func(t *testing.T, data string) {
		listed, err := parseChecksums(data)
		if err != nil {
			return
		}
		if len(listed) == 0 {
			t.Fatalf("parseChecksums accepted an empty listing from %q", data)
		}
		for name, hex := range listed {
			if len(hex) != 64 {
				t.Fatalf("accepted bad digest %q for %q", hex, name)
			}
			if !isSafeArchivePath(name) {
				t.Fatalf("accepted unsafe path %q", name)
			}
		}
	})
}
