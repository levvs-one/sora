//go:build windows

package main

import (
	"os"
	"path/filepath"

	"golang.org/x/sys/windows"
)

// takeDataDirLock opens (creating if needed) <dataDir>\lock and takes an
// exclusive, non-blocking byte-range lock on it. The returned file must
// stay open for the process lifetime: closing it (or process death)
// releases the lock, which is what makes the single-instance check
// race-free.
func takeDataDirLock(dataDir string) (*os.File, error) {
	f, err := os.OpenFile(filepath.Join(dataDir, "lock"), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return nil, err
	}
	var ol windows.Overlapped
	err = windows.LockFileEx(windows.Handle(f.Fd()),
		windows.LOCKFILE_EXCLUSIVE_LOCK|windows.LOCKFILE_FAIL_IMMEDIATELY,
		0, 1, 0, &ol)
	if err != nil {
		_ = f.Close()
		return nil, err
	}
	return f, nil
}
