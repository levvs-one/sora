package ext

import (
	"archive/zip"
	"bytes"
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"testing"
	"time"
)

// testSeed is a fixed ed25519 seed so signatures are reproducible.
var testSeed = []byte{
	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
	0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
	0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
}

// testPubKeyLine returns the minisign public key line for testSeed.
func testPubKeyLine(t *testing.T) string {
	t.Helper()
	priv := ed25519.NewKeyFromSeed(testSeed)
	pub := priv.Public().(ed25519.PublicKey)
	raw := append([]byte{'E', 'd'}, make([]byte, 8)...)
	raw = append(raw, pub...)
	return base64.StdEncoding.EncodeToString(raw)
}

// testManifest returns a minimal valid manifest using the test key.
func testManifest(t *testing.T) *Manifest {
	t.Helper()
	return &Manifest{
		ManifestVersion: 1,
		ID:              "com.example.hello",
		Name:            "Hello Panel",
		Version:         "1.0.0",
		MinAppVersion:   "1.9.0",
		Description:     "An example panel.",
		Author:          Author{Name: "Example", Identity: "github:example", PublicKey: testPubKeyLine(t)},
		Permissions:     []string{"connections.read", "notifications", "ui.panel"},
		Capabilities:    []string{"ui-panel"},
		UI:              &UIManifest{Panels: []Panel{{ID: "main", Title: "Hello", Entry: "panel.html"}}},
	}
}

// buildPackage assembles a signed .soraext in memory. mutate lets a test
// tamper with the files after signing.
func buildPackage(t *testing.T, m *Manifest, extra map[string]string, mutate func(files map[string][]byte)) []byte {
	return buildPackageWithSeed(t, m, testSeed, extra, mutate)
}

// buildPackageWithSeed is buildPackage signing with an explicit ed25519
// seed, so tests can build packages whose signer differs from the
// manifest's declared author key.
func buildPackageWithSeed(t *testing.T, m *Manifest, seed []byte, extra map[string]string, mutate func(files map[string][]byte)) []byte {
	t.Helper()
	manRaw, err := json.Marshal(m)
	if err != nil {
		t.Fatal(err)
	}
	strFiles := map[string]string{
		manifestName: string(manRaw),
		"panel.html": "<html><body>hi</body></html>",
	}
	for k, v := range extra {
		strFiles[k] = v
	}
	checksums := MakeChecksums(strFiles)
	sig, err := SignPayload(seed, "test key", sigFileChecksums, time.Now().Unix(), []byte(checksums))
	if err != nil {
		t.Fatal(err)
	}
	binFiles := map[string][]byte{
		manifestName:  manRaw,
		"panel.html":  []byte("<html><body>hi</body></html>"),
		checksumsName: []byte(checksums),
		signatureName: []byte(sig),
	}
	for k, v := range extra {
		binFiles[k] = []byte(v)
	}
	if mutate != nil {
		mutate(binFiles)
	}
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	for _, name := range []string{manifestName, checksumsName, signatureName, "panel.html"} {
		w, err := zw.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.Write(binFiles[name]); err != nil {
			t.Fatal(err)
		}
	}
	for k, v := range extra {
		w, err := zw.Create(k)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.Write([]byte(v)); err != nil {
			t.Fatal(err)
		}
	}
	if err := zw.Close(); err != nil {
		t.Fatal(err)
	}
	return buf.Bytes()
}

func TestManifestValid(t *testing.T) {
	m := testManifest(t)
	raw, _ := json.Marshal(m)
	if _, err := ParseManifest(raw); err != nil {
		t.Fatalf("valid manifest rejected: %v", err)
	}
	// Hyphens inside labels are legal reverse-DNS.
	m.ID = "org.sora.hello-panel"
	raw, _ = json.Marshal(m)
	if _, err := ParseManifest(raw); err != nil {
		t.Fatalf("hyphenated id rejected: %v", err)
	}
}

func TestManifestRejects(t *testing.T) {
	base := testManifest(t)
	cases := []struct {
		name   string
		mutate func(*Manifest)
	}{
		{"bad version field", func(m *Manifest) { m.ManifestVersion = 2 }},
		{"bad id", func(m *Manifest) { m.ID = "not a dns name!" }},
		{"single label id", func(m *Manifest) { m.ID = "hello" }},
		{"bad semver", func(m *Manifest) { m.Version = "1.0" }},
		{"empty name", func(m *Manifest) { m.Name = "" }},
		{"unknown permission", func(m *Manifest) { m.Permissions = []string{"root.shell"} }},
		{"duplicate permission", func(m *Manifest) { m.Permissions = []string{"notifications", "notifications"} }},
		{"unknown capability", func(m *Manifest) { m.Capabilities = []string{"teleport"} }},
		{"traversal entry", func(m *Manifest) { m.UI.Panels[0].Entry = "../../evil.html" }},
		{"absolute entry", func(m *Manifest) { m.UI.Panels[0].Entry = "/etc/panel.html" }},
		{"non-html entry", func(m *Manifest) { m.UI.Panels[0].Entry = "panel.js" }},
		{"bad author key", func(m *Manifest) { m.Author.PublicKey = "nope" }},
		{"panels without the ui.panel permission", func(m *Manifest) {
			m.Permissions = []string{"connections.read", "notifications"}
		}},
		{"panels without the ui-panel capability", func(m *Manifest) {
			m.Capabilities = []string{}
		}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			m := *base
			m.Permissions = append([]string(nil), base.Permissions...)
			m.Capabilities = append([]string(nil), base.Capabilities...)
			ui := *base.UI
			ui.Panels = append([]Panel(nil), base.UI.Panels...)
			m.UI = &ui
			m.Author = base.Author
			tc.mutate(&m)
			raw, _ := json.Marshal(m)
			if _, err := ParseManifest(raw); err == nil {
				t.Fatalf("expected rejection for %s", tc.name)
			}
		})
	}
}

// TestManifestWithoutPanelsNeedsNoUiPermission pins the positive side of
// the panels gate: a manifest that embeds no UI must not be forced to ask
// for the ui.panel permission.
func TestManifestWithoutPanelsNeedsNoUiPermission(t *testing.T) {
	m := testManifest(t)
	m.UI = nil
	m.Permissions = []string{"connections.read"}
	m.Capabilities = []string{}
	raw, _ := json.Marshal(m)
	if _, err := ParseManifest(raw); err != nil {
		t.Fatalf("a panel-less manifest must not need ui.panel: %v", err)
	}
}

func TestManifestUnknownFieldsRejected(t *testing.T) {
	m := testManifest(t)
	raw, _ := json.Marshal(m)
	var obj map[string]any
	if err := json.Unmarshal(raw, &obj); err != nil {
		t.Fatal(err)
	}
	obj["future_field"] = true
	raw2, _ := json.Marshal(obj)
	if _, err := ParseManifest(raw2); err == nil {
		t.Fatal("unknown manifest fields must be rejected")
	}
}

func TestSignRoundtrip(t *testing.T) {
	payload := []byte("checksums-content")
	sig, err := SignPayload(testSeed, "test", sigFileChecksums, 1700000000, payload)
	if err != nil {
		t.Fatal(err)
	}
	if err := VerifyPayload(testPubKeyLine(t), sig, sigFileChecksums, payload); err != nil {
		t.Fatalf("roundtrip failed: %v", err)
	}
}

func TestSignTamperFails(t *testing.T) {
	payload := []byte("checksums-content")
	sig, err := SignPayload(testSeed, "test", sigFileChecksums, 1700000000, payload)
	if err != nil {
		t.Fatal(err)
	}
	if err := VerifyPayload(testPubKeyLine(t), sig, sigFileChecksums, []byte("checksums-content!")); err == nil {
		t.Fatal("tampered payload must fail verification")
	}
	// Wrong key.
	other := make([]byte, 32)
	for i := range other {
		other[i] = byte(i + 1)
	}
	priv := ed25519.NewKeyFromSeed(other)
	pub := priv.Public().(ed25519.PublicKey)
	raw := append([]byte{'E', 'd'}, make([]byte, 8)...)
	otherLine := base64.StdEncoding.EncodeToString(append(raw, pub...))
	if err := VerifyPayload(otherLine, sig, sigFileChecksums, payload); err == nil {
		t.Fatal("wrong key must fail verification")
	}
}

func TestTeamSignatureFailsClosed(t *testing.T) {
	if SigningConfigured() {
		t.Skip("team key is configured; placeholder test not applicable")
	}
	sig, err := SignPayload(testSeed, "test", sigFileCatalog, 1700000000, []byte("{}"))
	if err != nil {
		t.Fatal(err)
	}
	if err := VerifyCatalogSignature(sig, []byte("{}")); err == nil {
		t.Fatal("team signature check must fail closed while the key is a placeholder")
	}
}

func TestPackageVerifyOK(t *testing.T) {
	data := buildPackage(t, testManifest(t), nil, nil)
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatalf("open failed: %v", err)
	}
	if err := pkg.Verify(); err != nil {
		t.Fatalf("verify failed: %v", err)
	}
}

func TestPackageTamperFails(t *testing.T) {
	data := buildPackage(t, testManifest(t), nil, func(files map[string][]byte) {
		files["panel.html"] = []byte("<html>evil</html>")
	})
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatalf("open failed: %v", err)
	}
	if err := pkg.Verify(); err == nil {
		t.Fatal("tampered file must fail verification")
	}
}

func TestPackageExtraFileFails(t *testing.T) {
	data := buildPackage(t, testManifest(t), map[string]string{"evil.js": "x"}, nil)
	// The extra file is listed in checksums (built from the same map), so it
	// passes; instead test an unlisted file added after signing.
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	pkg.Files["unlisted.js"] = []byte("evil")
	if err := pkg.Verify(); err == nil {
		t.Fatal("unlisted file must fail verification")
	}
}

func TestPackageBadSignatureFails(t *testing.T) {
	data := buildPackage(t, testManifest(t), nil, func(files map[string][]byte) {
		files[signatureName] = []byte("untrusted comment: x\nbm90LWEtc2lnbmF0dXJl\n")
	})
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatalf("open failed: %v", err)
	}
	if err := pkg.Verify(); err == nil {
		t.Fatal("bad signature must fail verification")
	}
}

func TestPackageNotZip(t *testing.T) {
	if _, err := OpenBytes([]byte("this is not a zip")); err == nil {
		t.Fatal("non-zip must be rejected")
	}
}
