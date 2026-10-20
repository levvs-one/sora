package ext

// Allocation benchmarks for the [opt40] ext runtime optimizations
// (PASS-opt40): ParseCatalog/ParseManifestFull single-decode paths,
// pre-sized limited reads for zip members and net.fetch bodies, the
// allocation-free checksum comparison in Verify, and the copy-free
// CSP head search. B/op and allocs/op are the decision metrics;
// ns/op on this VM is noise. Rejected candidates (token verify,
// hostAllowed) measured 0 B/op before any change and are not kept here.

import (
	"archive/zip"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"
)

// --- token verify ---

func benchCatalogJSON(b *testing.B, n int) []byte {
	pub := testPubKeyLine(&testing.T{})
	c := Catalog{Version: 1, UpdatedAt: "2026-10-20T00:00:00Z", MaxAge: 3600}
	for i := 0; i < n; i++ {
		c.Extensions = append(c.Extensions, Entry{
			ID: fmt.Sprintf("com.example.ext%d", i), Name: "Ext", Version: "1.0.0",
			Author: "A", AuthorID: "github:a", AuthorKey: pub,
			Permissions: []string{"connections.read"}, DownloadURL: "https://example.com/x.soraext",
			Sha256: strings.Repeat("ab", 32), Size: 1024, MinAppVer: "1.0.0",
		})
	}
	raw, err := json.Marshal(c)
	if err != nil {
		b.Fatal(err)
	}
	return raw
}

func BenchmarkOpt40ParseCatalog100(b *testing.B) {
	raw := benchCatalogJSON(b, 100)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, err := ParseCatalog(raw); err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkOpt40ParseCatalog500(b *testing.B) {
	raw := benchCatalogJSON(b, 500)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, err := ParseCatalog(raw); err != nil {
			b.Fatal(err)
		}
	}
}

// --- manifest ---

func BenchmarkOpt40ParseManifestFullPlain(b *testing.B) {
	m := testManifest(&testing.T{})
	raw, _ := json.Marshal(m)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, _, err := ParseManifestFull(raw); err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkOpt40ParseManifestFullExt(b *testing.B) {
	m := testManifest(&testing.T{})
	m.Permissions = append(m.Permissions, "net.fetch", "background")
	m.Capabilities = append(m.Capabilities, "background")
	base, _ := json.Marshal(m)
	var doc map[string]json.RawMessage
	_ = json.Unmarshal(base, &doc)
	doc["background_task"] = json.RawMessage(`{"interval_minutes":60,"entry":"worker.js"}`)
	doc["network_hosts"] = json.RawMessage(`["api.example.com","*.example.org"]`)
	raw, _ := json.Marshal(doc)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, _, err := ParseManifestFull(raw); err != nil {
			b.Fatal(err)
		}
	}
}

// --- package open/verify ---

func benchZip(b *testing.B, files map[string][]byte) []byte {
	strFiles := map[string]string{}
	for k, v := range files {
		strFiles[k] = string(v)
	}
	// manifest handled by caller inside files
	checksums := MakeChecksums(strFiles)
	sig, err := SignPayload(testPrivateKey(testSeed), "test key", sigFileChecksums, time.Now().Unix(), []byte(checksums))
	if err != nil {
		b.Fatal(err)
	}
	all := map[string][]byte{}
	for k, v := range files {
		all[k] = v
	}
	all[checksumsName] = []byte(checksums)
	all[signatureName] = []byte(sig)
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	for name, data := range all {
		w, err := zw.Create(name)
		if err != nil {
			b.Fatal(err)
		}
		if _, err := w.Write(data); err != nil {
			b.Fatal(err)
		}
	}
	if err := zw.Close(); err != nil {
		b.Fatal(err)
	}
	return buf.Bytes()
}

func benchManifestRaw(_ *testing.B) []byte {
	raw, _ := json.Marshal(testManifest(&testing.T{}))
	return raw
}

func BenchmarkOpt40OpenBytesLarge4MiB(b *testing.B) {
	files := map[string][]byte{
		manifestName: benchManifestRaw(b),
		"panel.html": []byte("<html><head></head><body>hi</body></html>"),
		"big.js":     bytes.Repeat([]byte("abcdefgh"), (4<<20)/8),
	}
	raw := benchZip(b, files)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		pkg, err := OpenBytes(raw)
		if err != nil {
			b.Fatal(err)
		}
		_ = pkg
	}
}

func BenchmarkOpt40OpenBytesMany500(b *testing.B) {
	files := map[string][]byte{manifestName: benchManifestRaw(b), "panel.html": []byte("<html></html>")}
	for i := 0; i < 500; i++ {
		files[fmt.Sprintf("assets/f%03d.js", i)] = bytes.Repeat([]byte("x"), 4096)
	}
	raw := benchZip(b, files)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		pkg, err := OpenBytes(raw)
		if err != nil {
			b.Fatal(err)
		}
		_ = pkg
	}
}

func BenchmarkOpt40VerifyMany500(b *testing.B) {
	files := map[string][]byte{manifestName: benchManifestRaw(b), "panel.html": []byte("<html></html>")}
	for i := 0; i < 500; i++ {
		files[fmt.Sprintf("assets/f%03d.js", i)] = bytes.Repeat([]byte("x"), 4096)
	}
	raw := benchZip(b, files)
	pkg, err := OpenBytes(raw)
	if err != nil {
		b.Fatal(err)
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if err := pkg.Verify(); err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkOpt40VerifyLarge4MiB(b *testing.B) {
	files := map[string][]byte{
		manifestName: benchManifestRaw(b),
		"panel.html": []byte("<html></html>"),
		"big.js":     bytes.Repeat([]byte("abcdefgh"), (4<<20)/8),
	}
	raw := benchZip(b, files)
	pkg, err := OpenBytes(raw)
	if err != nil {
		b.Fatal(err)
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if err := pkg.Verify(); err != nil {
			b.Fatal(err)
		}
	}
}

// --- CSP ---

func BenchmarkOpt40InjectCSP64K(b *testing.B) {
	html := append([]byte("<html><head><title>t</title></head><body>"), bytes.Repeat([]byte("y"), 64<<10)...)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = injectPanelCSP(html)
	}
}

func BenchmarkOpt40InjectCSP1M(b *testing.B) {
	html := append([]byte("<html><head><title>t</title></head><body>"), bytes.Repeat([]byte("y"), 1<<20)...)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = injectPanelCSP(html)
	}
}

// --- fetch ---

type zzRT struct{ body []byte }

func (t zzRT) RoundTrip(req *http.Request) (*http.Response, error) {
	_, _ = io.Copy(io.Discard, req.Body)
	return &http.Response{
		StatusCode:    200,
		Status:        "200 OK",
		Header:        http.Header{"Content-Type": []string{"application/json"}},
		Body:          io.NopCloser(bytes.NewReader(t.body)),
		ContentLength: int64(len(t.body)),
		Request:       req,
	}, nil
}

func benchFetcher(b *testing.B, respBody []byte) *Fetcher {
	hub := NewLogHub()
	f, err := NewFetcherForExtensionWithTransport("com.example.hello",
		&ManifestExt{NetworkHosts: []string{"api.example.com", "*.example.org"}},
		FetchLimits{RatePerMinute: 1e9, RateBurst: 1e9}, zzRT{body: respBody}, hub)
	if err != nil {
		b.Fatal(err)
	}
	return f
}

func BenchmarkOpt40FetchSmall(b *testing.B) {
	f := benchFetcher(b, []byte("pong"))
	req := FetchRequest{Method: "GET", URL: "https://api.example.com/ping?token=secret"}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		resp, err := f.Fetch(context.Background(), req)
		if err != nil {
			b.Fatal(err)
		}
		_ = resp
	}
}

func BenchmarkOpt40FetchLarge1MiB(b *testing.B) {
	f := benchFetcher(b, bytes.Repeat([]byte("z"), 1<<20))
	req := FetchRequest{Method: "GET", URL: "https://api.example.com/data"}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		resp, err := f.Fetch(context.Background(), req)
		if err != nil {
			b.Fatal(err)
		}
		_ = resp
	}
}
