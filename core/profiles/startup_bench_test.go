package profiles

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"testing"
)

// populatedDir builds a data dir with 100 saved profiles and a ~9k-entry
// ASN table (236 KB of JSON, under the 1 MB cap).
func populatedDir(b *testing.B) string {
	b.Helper()
	dir := b.TempDir()
	s, err := NewStore(dir)
	if err != nil {
		b.Fatal(err)
	}
	for i := 0; i < 100; i++ {
		if _, err := s.Save(Profile{Name: fmt.Sprintf("p%d", i), Triggers: Triggers{SSIDs: []string{fmt.Sprintf("ssid-%d", i)}}}); err != nil {
			b.Fatal(err)
		}
	}
	asn := map[string]string{}
	for i := 0; i < 9000; i++ {
		asn[fmt.Sprintf("10.%d.%d.0/24", i/250, i%250)] = "AS12345"
	}
	raw, _ := json.Marshal(asn)
	if err := os.WriteFile(filepath.Join(dir, asnTableName), raw, 0o600); err != nil {
		b.Fatal(err)
	}
	return dir
}

// BenchmarkNewStorePopulated measures store construction over a populated
// data dir. The ASN table is parsed lazily on the first lookup, so this
// must stay in the low milliseconds even with a large table; the eager
// version measured ~100 ms and ~3.9 MB/op on the audit VM.
func BenchmarkNewStorePopulated(b *testing.B) {
	dir := populatedDir(b)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, err := NewStore(dir); err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkLoadASNTable measures the deferred first-use cost that
// BenchmarkNewStorePopulated avoids: one full parse of the 9k-entry table.
func BenchmarkLoadASNTable(b *testing.B) {
	dir := populatedDir(b)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		nets, _ := loadASNTable(dir)
		if len(nets) != 9000 {
			b.Fatalf("nets=%d", len(nets))
		}
	}
}
