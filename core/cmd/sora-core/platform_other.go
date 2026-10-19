//go:build !windows

package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"syscall"

	"golang.org/x/sys/unix"

	"github.com/levvs-one/sora-client/core/secret"
)

// platformProtector uses an owner-only key file and directory without a
// session-dependent keychain. Protection depends on the service account's
// security.
func platformProtector() secret.Protector { return secret.FileProtector{} }

// platformName returns the platform name for reports.
func platformName() string { return runtime.GOOS }

// secureDataDir fails closed when the data directory is not owner-only or
// not owned by this user. MkdirAll does not repair the permissions of an
// existing directory, so creation-time modes are not enough (SORA-L3).
func secureDataDir(dir string) error {
	info, err := os.Stat(dir)
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return fmt.Errorf("core: %s is not a directory", dir)
	}
	if perm := info.Mode().Perm(); perm != 0o700 {
		return fmt.Errorf("core: data directory %s has permissions %o, want 700", dir, perm)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok {
		return fmt.Errorf("core: cannot read ownership of %s", dir)
	}
	if int(stat.Uid) != os.Geteuid() {
		return fmt.Errorf("core: data directory %s is not owned by this user", dir)
	}
	return nil
}

// Hold the inode through shutdown; unlinking it would let another process lock
// a different inode while this service is still restoring its routes.
func lockInstance(address, _ string) (io.Closer, error) {
	//nolint:gosec // IPC clients must traverse the socket directory; the lock itself is owner-only
	if err := os.MkdirAll(filepath.Dir(address), 0o755); err != nil {
		return nil, err
	}
	file, err := os.OpenFile(address+".lock", os.O_CREATE|os.O_RDWR, 0o600) //nolint:gosec // fixed suffix beside the operator-selected IPC endpoint
	if err != nil {
		return nil, err
	}
	if err := unix.Flock(int(file.Fd()), unix.LOCK_EX|unix.LOCK_NB); err != nil {
		_ = file.Close()
		return nil, fmt.Errorf("core: another instance owns %s: %w", address, err)
	}
	return file, nil
}
