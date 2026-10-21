package profiles

import (
	"os"
	"path/filepath"
	"testing"
)

// FuzzStoreLoad attacks the network-profiles store file: arbitrary
// bytes in profiles.json must yield a working store or a clean error,
// never a panic, and a store that opens must answer its lookups.
func FuzzStoreLoad(f *testing.F) {
	f.Add([]byte(`[]`))
	f.Add([]byte(`[{"id":"a","name":"home"}]`))
	f.Add([]byte(`{"not":"a list"}`))
	f.Add([]byte(``))
	f.Fuzz(func(t *testing.T, b []byte) {
		dir := t.TempDir()
		if err := os.WriteFile(filepath.Join(dir, fileName), b, 0o600); err != nil {
			t.Fatal(err)
		}
		st, err := NewStore(dir)
		if err != nil {
			return
		}
		_ = st.List()
		_, _ = st.TrustOf("ssid")
		_ = st.NetworkTrust(Fingerprint{})
	})
}
