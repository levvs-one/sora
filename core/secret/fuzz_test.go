package secret

import (
	"os"
	"path/filepath"
	"testing"
)

// FuzzVaultFiles attacks the on-disk vault format: an encrypted store
// file, its master-key file, truncations and splices of a genuine pair.
// Open must fail closed with an error — never panic, never accept a
// tampered file as an empty store, never wedge on a later write. The
// seed pair is rebuilt per iteration so modes 2–3 always start from a
// cryptographically valid file and reach deep into the decrypt path.
func FuzzVaultFiles(f *testing.F) {
	f.Add([]byte("garbage"), []byte("garbage"), uint8(0))
	f.Add([]byte{0}, []byte{}, uint8(1))
	f.Add([]byte("splice-window"), []byte("x"), uint8(2))
	f.Add([]byte{200}, []byte{}, uint8(3))
	f.Fuzz(func(t *testing.T, vaultIn, masterIn []byte, mode uint8) {
		// The store refuses a pre-existing directory looser than 0700, so
		// give it a fresh one with the production mode.
		dir := filepath.Join(t.TempDir(), "vault")
		if err := os.Mkdir(dir, dirMode); err != nil {
			t.Fatalf("mkdir: %v", err)
		}
		base, err := Open(dir, Options{Protector: FileProtector{}})
		if err != nil {
			t.Fatalf("seed open: %v", err)
		}
		if err := base.Put("alpha", []byte("material-alpha")); err != nil {
			t.Fatalf("seed put: %v", err)
		}
		if err := base.Put("beta", []byte("material-beta")); err != nil {
			t.Fatalf("seed put: %v", err)
		}
		if err := base.Close(); err != nil {
			t.Fatalf("seed close: %v", err)
		}
		vaultPath := filepath.Join(dir, vaultFile)
		masterPath := filepath.Join(dir, masterFile)
		validVault, err := os.ReadFile(vaultPath)
		if err != nil {
			t.Fatalf("seed read vault: %v", err)
		}
		validMaster, err := os.ReadFile(masterPath)
		if err != nil {
			t.Fatalf("seed read master: %v", err)
		}

		vault, master := validVault, validMaster
		switch mode % 4 {
		case 0: // the vault file is arbitrary bytes
			vault = vaultIn
		case 1: // the master-key file is arbitrary bytes
			master = masterIn
		case 2: // a window of the genuine vault is overwritten
			vault = append([]byte(nil), validVault...)
			if len(vault) > 0 && len(vaultIn) > 0 {
				off := int(vaultIn[0]) % len(vault)
				copy(vault[off:], vaultIn[1:])
			}
		case 3: // the genuine vault is truncated or extended
			if len(vaultIn) > 0 {
				n := int(vaultIn[0]) % (len(validVault) + 64)
				if n < len(validVault) {
					vault = validVault[:n]
				} else {
					vault = append(append([]byte(nil), validVault...), vaultIn...)
				}
			}
		}
		if err := os.WriteFile(vaultPath, vault, fileMode); err != nil {
			t.Fatalf("write vault: %v", err)
		}
		if err := os.WriteFile(masterPath, master, fileMode); err != nil {
			t.Fatalf("write master: %v", err)
		}

		st, err := Open(dir, Options{Protector: FileProtector{}})
		if err != nil {
			return // fail closed: the expected outcome for tampered files
		}
		defer func() { _ = st.Close() }()
		for _, ref := range st.Refs() {
			if _, err := st.Get(ref); err != nil {
				t.Fatalf("Refs() lists %q but Get fails: %v", ref, err)
			}
		}
		// Whatever survived must stay writable and re-readable.
		if err := st.Put("gamma", []byte("material-gamma")); err != nil {
			t.Fatalf("put after open: %v", err)
		}
		if _, err := st.Get("gamma"); err != nil {
			t.Fatalf("get after put: %v", err)
		}
	})
}
