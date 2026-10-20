//go:build unix

package main

import (
	"os"
	"path/filepath"
	"syscall"
)

// takeDataDirLock opens (creating if needed) <dataDir>/lock and takes an
// exclusive, non-blocking flock on it. The returned file must stay open
// for the process lifetime: closing it (or process death) releases the
// lock, which is what makes the single-instance check race-free.
func takeDataDirLock(dataDir string) (*os.File, error) {
	f, err := os.OpenFile(filepath.Join(dataDir, "lock"), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return nil, err
	}
	if err := syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		_ = f.Close()
		return nil, err
	}
	return f, nil
}
