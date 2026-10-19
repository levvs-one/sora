package custom

import (
	"context"
	"net"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// fakeSecrets is an in-memory Secrets implementation for tests.
type fakeSecrets struct {
	mu    sync.Mutex
	items map[string][]byte
}

func newFakeSecrets() *fakeSecrets { return &fakeSecrets{items: map[string][]byte{}} }

func (f *fakeSecrets) Get(reference string) ([]byte, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	v, ok := f.items[reference]
	if !ok {
		return nil, errs.Newf(errs.CodeNotFound, errs.KeySecretNotFound, "no secret")
	}
	return append([]byte(nil), v...), nil
}

func (f *fakeSecrets) Put(reference string, material []byte) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.items[reference] = append([]byte(nil), material...)
	return nil
}

func (f *fakeSecrets) Delete(reference string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	delete(f.items, reference)
	return nil
}

func openTestStore(t *testing.T, secrets Secrets) *Store {
	t.Helper()
	s, err := Open(t.TempDir(), secrets)
	if err != nil {
		t.Fatalf("Open: %v", err)
	}
	return s
}

func validServer() Server {
	return Server{
		Name:     "My server",
		Protocol: ProtocolVLESS,
		Address:  "example.com",
		Port:     443,
	}
}

func TestSaveRoundTrip(t *testing.T) {
	vault := newFakeSecrets()
	s := openTestStore(t, vault)
	stored, err := s.Save(validServer(), []byte("super-secret-uuid"))
	if err != nil {
		t.Fatalf("Save: %v", err)
	}
	if stored.ID == "" {
		t.Fatal("Save did not assign an id")
	}
	if stored.SecretRef == "" {
		t.Fatal("Save did not set a secret reference")
	}
	got, ok := s.Get(stored.ID)
	if !ok || got.Name != "My server" || got.Port != 443 {
		t.Fatalf("Get = %+v, %v", got, ok)
	}
	material, err := vault.Get(stored.SecretRef)
	if err != nil || string(material) != "super-secret-uuid" {
		t.Fatalf("vault material = %q, err %v", material, err)
	}
}

// flakySecrets fails Delete on demand to simulate a vault outage.
type flakySecrets struct {
	*fakeSecrets
	failDelete bool
}

func (f *flakySecrets) Delete(reference string) error {
	if f.failDelete {
		return errs.Newf(errs.CodeInternal, errs.KeyInternal, "vault outage")
	}
	return f.fakeSecrets.Delete(reference)
}

func TestDeleteVaultFailureKeepsServer(t *testing.T) {
	vault := &flakySecrets{fakeSecrets: newFakeSecrets(), failDelete: true}
	s := openTestStore(t, vault)
	stored, err := s.Save(validServer(), []byte("cred"))
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Delete(stored.ID); err == nil {
		t.Fatal("Delete with a failing vault succeeded, want an error")
	}
	// The server and its secret must survive for a retry: a failed vault
	// delete must never orphan a secret the metadata no longer names.
	if _, ok := s.Get(stored.ID); !ok {
		t.Error("server lost after failed delete")
	}
	if _, err := vault.Get(stored.SecretRef); err != nil {
		t.Error("secret lost after failed delete")
	}
	vault.failDelete = false
	if err := s.Delete(stored.ID); err != nil {
		t.Fatalf("retry Delete: %v", err)
	}
	if _, ok := s.Get(stored.ID); ok {
		t.Error("server still present after retry")
	}
	if _, err := vault.Get(stored.SecretRef); err == nil {
		t.Error("secret still in vault after retry")
	}
}

// breakPersist blocks the temp file of the atomic rename in persistLocked,
// so the write fails while the metadata file stays readable (reload paths
// keep working). It returns a repair function.
func breakPersist(t *testing.T, dir string) func() {
	t.Helper()
	tmp := filepath.Join(dir, fileName) + ".tmp"
	if err := os.Mkdir(tmp, 0o700); err != nil {
		t.Fatal(err)
	}
	return func() {
		if err := os.RemoveAll(tmp); err != nil {
			t.Fatal(err)
		}
	}
}

func TestDeletePersistFailureRestoresSecret(t *testing.T) {
	dir := t.TempDir()
	vault := newFakeSecrets()
	s, err := Open(dir, vault)
	if err != nil {
		t.Fatal(err)
	}
	stored, err := s.Save(validServer(), []byte("cred"))
	if err != nil {
		t.Fatal(err)
	}
	repair := breakPersist(t, dir)
	if err := s.Delete(stored.ID); err == nil {
		t.Fatal("Delete with a broken persist succeeded, want an error")
	}
	if _, ok := s.Get(stored.ID); !ok {
		t.Error("server lost from memory after failed delete")
	}
	if material, err := vault.Get(stored.SecretRef); err != nil || string(material) != "cred" {
		t.Errorf("secret not restored: %q, err %v", material, err)
	}
	repair()
	if err := s.Delete(stored.ID); err != nil {
		t.Fatalf("retry Delete: %v", err)
	}
	if _, ok := s.Get(stored.ID); ok {
		t.Error("server still present after retry")
	}
}

func TestSavePersistFailureRestoresCredentials(t *testing.T) {
	dir := t.TempDir()
	vault := newFakeSecrets()
	s, err := Open(dir, vault)
	if err != nil {
		t.Fatal(err)
	}
	stored, err := s.Save(validServer(), []byte("old"))
	if err != nil {
		t.Fatal(err)
	}
	repair := breakPersist(t, dir)
	upd := stored
	upd.Name = "Rotated"
	if _, err := s.Save(upd, []byte("new")); err == nil {
		t.Fatal("Save with a broken persist succeeded, want an error")
	}
	// The failed rotation must change nothing: the vault still holds the
	// old material and the metadata still names the old server.
	if material, err := vault.Get(stored.SecretRef); err != nil || string(material) != "old" {
		t.Errorf("vault material = %q, err %v; want the pre-update secret", material, err)
	}
	if got, ok := s.Get(stored.ID); !ok || got.Name != "My server" {
		t.Errorf("metadata diverged: %+v, %v", got, ok)
	}
	repair()
	updated, err := s.Save(upd, []byte("new"))
	if err != nil {
		t.Fatalf("retry Save: %v", err)
	}
	if material, _ := vault.Get(updated.SecretRef); string(material) != "new" {
		t.Errorf("vault material = %q, want new", material)
	}
}

func TestOpenRejectsInvalidRecords(t *testing.T) {
	cases := map[string]string{
		"bad protocol": `[{"id":"srv1","name":"n","protocol":"socks5","address":"example.com","port":443,"secret_ref":"custom_srv1_cred","created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"}]`,
		"bad address":  `[{"id":"srv1","name":"n","protocol":"vless","address":"999.1.1.1","port":443,"secret_ref":"custom_srv1_cred","created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"}]`,
		"bad port":     `[{"id":"srv1","name":"n","protocol":"vless","address":"example.com","port":0,"secret_ref":"custom_srv1_cred","created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"}]`,
		"empty name":   `[{"id":"srv1","name":"  ","protocol":"vless","address":"example.com","port":443,"secret_ref":"custom_srv1_cred","created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"}]`,
	}
	for name, raw := range cases {
		t.Run(name, func(t *testing.T) {
			dir := t.TempDir()
			if err := os.WriteFile(filepath.Join(dir, fileName), []byte(raw), 0o600); err != nil {
				t.Fatal(err)
			}
			if _, err := Open(dir, newFakeSecrets()); err == nil {
				t.Error("Open of a file with an invalid record succeeded, want fail-closed")
			}
		})
	}
}

func TestSaveRejectsInvalidAddress(t *testing.T) {
	for _, addr := range []string{
		"",
		"   ",
		"999.1.1.1",        // numeric-looking but not an IP
		"256.256.256.256",  // numeric-looking but not an IP
		"bad_host.example", // underscore is not a hostname char
		"-lead.example",    // leading hyphen
		"trail-.example",   // trailing hyphen
		strings.Repeat("a", 254),
		"has space.example",
	} {
		s := openTestStore(t, newFakeSecrets())
		in := validServer()
		in.Address = addr
		if _, err := s.Save(in, []byte("cred")); err == nil {
			t.Errorf("Save with address %q succeeded, want an error", addr)
		}
	}
}

func TestSaveAcceptsValidAddresses(t *testing.T) {
	for _, addr := range []string{
		"example.com",
		"a.b.c.example",
		"localhost",
		"127.0.0.1",
		"::1",
		"2001:db8::1",
		"example.com.", // trailing dot
		"xn--nxasmq6b.example",
	} {
		s := openTestStore(t, newFakeSecrets())
		in := validServer()
		in.Address = addr
		if _, err := s.Save(in, []byte("cred")); err != nil {
			t.Errorf("Save with address %q failed: %v", addr, err)
		}
	}
}

func TestSaveRejectsEmptyCredentialsOnCreate(t *testing.T) {
	for _, cred := range [][]byte{nil, {}} {
		s := openTestStore(t, newFakeSecrets())
		if _, err := s.Save(validServer(), cred); err == nil {
			t.Error("Save with empty credentials succeeded, want an error")
		}
	}
}

func TestSaveRejectsPathTraversalIDs(t *testing.T) {
	dir := t.TempDir()
	s, err := Open(dir, newFakeSecrets())
	if err != nil {
		t.Fatalf("Open: %v", err)
	}
	for _, id := range []string{"../evil", "..", "a/b", `a\b`, ".", "a..b/c"} {
		in := validServer()
		in.ID = id
		if _, err := s.Save(in, []byte("cred")); err == nil {
			t.Errorf("Save with id %q succeeded, want an error", id)
		}
		if err := s.Delete(id); err == nil {
			t.Errorf("Delete with id %q succeeded, want an error", id)
		}
	}
	// Nothing may escape the store directory, and no metadata file is
	// created by rejected writes.
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 0 {
		names := make([]string, 0, len(entries))
		for _, e := range entries {
			names = append(names, e.Name())
		}
		t.Fatalf("unexpected files in store dir: %v", names)
	}
}

func TestMetadataFileIsOwnerOnlyAndHoldsNoSecrets(t *testing.T) {
	dir := t.TempDir()
	s, err := Open(dir, newFakeSecrets())
	if err != nil {
		t.Fatal(err)
	}
	secret := "top-secret-material-123"
	stored, err := s.Save(validServer(), []byte(secret))
	if err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(dir, fileName)
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Errorf("servers.json mode = %o, want 600", info.Mode().Perm())
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), secret) {
		t.Error("servers.json contains credential material")
	}
	if !strings.Contains(string(raw), stored.SecretRef) {
		t.Error("servers.json does not reference the vault entry")
	}
}

func TestUpdateKeepsCredentialsWhenEmpty(t *testing.T) {
	vault := newFakeSecrets()
	s := openTestStore(t, vault)
	stored, err := s.Save(validServer(), []byte("original"))
	if err != nil {
		t.Fatal(err)
	}
	upd := stored
	upd.Name = "Renamed"
	upd.Port = 8443
	updated, err := s.Save(upd, nil)
	if err != nil {
		t.Fatalf("update: %v", err)
	}
	if updated.SecretRef != stored.SecretRef {
		t.Error("update changed the secret reference")
	}
	material, _ := vault.Get(updated.SecretRef)
	if string(material) != "original" {
		t.Errorf("vault material = %q, want original", material)
	}
	if updated.Name != "Renamed" || updated.Port != 8443 {
		t.Errorf("update did not apply: %+v", updated)
	}
}

func TestUpdateReplacesCredentials(t *testing.T) {
	vault := newFakeSecrets()
	s := openTestStore(t, vault)
	stored, err := s.Save(validServer(), []byte("old"))
	if err != nil {
		t.Fatal(err)
	}
	updated, err := s.Save(stored, []byte("new"))
	if err != nil {
		t.Fatalf("update: %v", err)
	}
	material, _ := vault.Get(updated.SecretRef)
	if string(material) != "new" {
		t.Errorf("vault material = %q, want new", material)
	}
}

func TestUpdateUnknownID(t *testing.T) {
	s := openTestStore(t, newFakeSecrets())
	in := validServer()
	in.ID = "no-such-id"
	if _, err := s.Save(in, []byte("cred")); err == nil {
		t.Error("update of unknown id succeeded, want NotFound")
	} else if errs.From(err).Code() != errs.CodeNotFound {
		t.Errorf("update error code = %v, want NotFound", errs.From(err).Code())
	}
}

func TestDeleteRemovesServerAndCredentials(t *testing.T) {
	vault := newFakeSecrets()
	s := openTestStore(t, vault)
	a, _ := s.Save(validServer(), []byte("cred-a"))
	b, _ := s.Save(validServer(), []byte("cred-b"))
	if err := s.Delete(a.ID); err != nil {
		t.Fatalf("Delete: %v", err)
	}
	if _, ok := s.Get(a.ID); ok {
		t.Error("deleted server still listed")
	}
	if _, err := vault.Get(a.SecretRef); err == nil {
		t.Error("deleted server credentials still in vault")
	}
	if _, ok := s.Get(b.ID); !ok {
		t.Error("sibling server vanished")
	}
	// Repeatable cleanup: unknown ids succeed.
	if err := s.Delete("no-such-id"); err != nil {
		t.Errorf("Delete of unknown id: %v", err)
	}
	if err := s.Delete(a.ID); err != nil {
		t.Errorf("second Delete: %v", err)
	}
}

func TestListKeepsInsertionOrder(t *testing.T) {
	s := openTestStore(t, newFakeSecrets())
	var ids []string
	for _, name := range []string{"one", "two", "three"} {
		in := validServer()
		in.Name = name
		stored, err := s.Save(in, []byte("cred"))
		if err != nil {
			t.Fatal(err)
		}
		ids = append(ids, stored.ID)
	}
	list := s.List()
	if len(list) != 3 {
		t.Fatalf("List len = %d", len(list))
	}
	for i, id := range ids {
		if list[i].ID != id || list[i].Name != []string{"one", "two", "three"}[i] {
			t.Errorf("List[%d] = %+v, want id %s", i, list[i], id)
		}
	}
}

func TestOpenRejectsCorruptFile(t *testing.T) {
	dir := t.TempDir()
	if err := os.MkdirAll(dir, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, fileName), []byte("{not json"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := Open(dir, newFakeSecrets()); err == nil {
		t.Error("Open of corrupt file succeeded, want an error")
	}
}

func TestSaveValidationTable(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(*Server)
	}{
		{"empty name", func(s *Server) { s.Name = "  " }},
		{"bad protocol", func(s *Server) { s.Protocol = "socks5" }},
		{"zero port", func(s *Server) { s.Port = 0 }},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			s := openTestStore(t, newFakeSecrets())
			in := validServer()
			tc.mutate(&in)
			if _, err := s.Save(in, []byte("cred")); err == nil {
				t.Error("Save succeeded, want an error")
			}
		})
	}
}

func TestProbeTCPReachable(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Skipf("no loopback: %v", err)
	}
	defer ln.Close()
	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			_ = c.Close()
		}
	}()
	port := uint16(ln.Addr().(*net.TCPAddr).Port)
	lat, err := ProbeTCP(context.Background(), "127.0.0.1", port, 5*time.Second)
	if err != nil {
		t.Fatalf("ProbeTCP: %v", err)
	}
	if lat <= 0 || lat > 5*time.Second {
		t.Errorf("latency = %v, want within the timeout", lat)
	}
}

func TestProbeTCPRefused(t *testing.T) {
	// Grab a port and close it so nothing listens there.
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Skipf("no loopback: %v", err)
	}
	port := uint16(ln.Addr().(*net.TCPAddr).Port)
	_ = ln.Close()
	if _, err := ProbeTCP(context.Background(), "127.0.0.1", port, 5*time.Second); err == nil {
		t.Error("ProbeTCP to a closed port succeeded, want an error")
	}
}

func TestClampProbeTimeout(t *testing.T) {
	if got := ClampProbeTimeout(0); got != DefaultProbeTimeout {
		t.Errorf("zero -> %v", got)
	}
	if got := ClampProbeTimeout(time.Millisecond); got != MinProbeTimeout {
		t.Errorf("tiny -> %v", got)
	}
	if got := ClampProbeTimeout(time.Hour); got != MaxProbeTimeout {
		t.Errorf("huge -> %v", got)
	}
	if got := ClampProbeTimeout(7 * time.Second); got != 7*time.Second {
		t.Errorf("normal -> %v", got)
	}
}

func TestValidatePortBounds(t *testing.T) {
	for _, port := range []uint32{0, 65536, 1 << 20} {
		if err := ValidatePort(port); err == nil {
			t.Errorf("ValidatePort(%d) succeeded, want an error", port)
		}
	}
	for _, port := range []uint32{1, 443, 65535} {
		if err := ValidatePort(port); err != nil {
			t.Errorf("ValidatePort(%d): %v", port, err)
		}
	}
}
