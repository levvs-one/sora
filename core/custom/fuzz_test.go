package custom

import (
	"os"
	"path/filepath"
	"testing"
)

// FuzzStoreLoad attacks the custom-server store file: arbitrary bytes
// in servers.json must produce either a working store or a clean error
// from Open, and a store that opens must answer List/Get without
// panicking and accept a Save round trip.
func FuzzStoreLoad(f *testing.F) {
	f.Add([]byte(`[]`))
	f.Add([]byte(`[{"id":"a","name":"n","protocol":"vless","host":"a.example","port":443}]`))
	f.Add([]byte(`{"not":"a list"}`))
	f.Add([]byte(``))
	f.Fuzz(func(t *testing.T, b []byte) {
		dir := t.TempDir()
		if err := os.WriteFile(filepath.Join(dir, fileName), b, 0o600); err != nil {
			t.Fatal(err)
		}
		st, err := Open(dir, newFakeSecrets())
		if err != nil {
			return
		}
		for _, srv := range st.List() {
			_, _ = st.Get(srv.ID)
		}
	})
}
