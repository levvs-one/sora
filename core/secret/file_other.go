//go:build !windows

package secret

import (
	"os"
	"syscall"

	"github.com/levvs-one/sora-client/core/errs"
)

// platformProtector uses an owner-only key file under the service account.
// Desktop keyrings require a session and do not provide stronger same-user
// isolation.
func platformProtector() Protector { return FileProtector{} }

// hardenFile explicitly limits access to the owner because service-manager
// umasks may be permissive.
func hardenFile(file *os.File, mode os.FileMode) error {
	if err := file.Chmod(mode); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return nil
}

// checkOwnerOnly fails closed when path is not owner-only (wantMode) or not
// owned by this user. MkdirAll and file creation modes do not repair
// permissions weakened later, so the store verifies on every open (SORA-L3).
func checkOwnerOnly(path string, wantMode os.FileMode) error {
	info, err := os.Stat(path)
	if err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	if perm := info.Mode().Perm(); perm != wantMode.Perm() {
		return errs.Newf(errs.CodePermissionDenied, errs.KeySecretStoreUnavailable,
			"secret store: %s has permissions %o, want %o", path, perm, wantMode.Perm())
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok {
		return errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable,
			"secret store: cannot read ownership of %s", path)
	}
	if int(stat.Uid) != os.Geteuid() {
		return errs.Newf(errs.CodePermissionDenied, errs.KeySecretStoreUnavailable,
			"secret store: %s is not owned by this user", path)
	}
	return nil
}

// checkDataDir verifies the store directory before any key material is
// touched.
func checkDataDir(dir string) error {
	return checkOwnerOnly(dir, dirMode)
}

// syncDir flushes rename metadata for power-loss durability. Unsupported
// filesystem sync is tolerated without affecting atomic replacement.
func syncDir(dir string) error {
	handle, err := os.Open(dir) //nolint:gosec // dir is the vault's own directory
	if err != nil {
		return nil //nolint:nilerr // best effort, as documented above
	}
	defer func() { _ = handle.Close() }()
	_ = handle.Sync()
	return nil
}
