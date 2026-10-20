//go:build windows

package secret

import "os"

// hardenFile relies on the installer's private data-directory DACL inherited by
// files.
func hardenFile(*os.File, os.FileMode) error { return nil }

// syncDir does nothing on Windows because directory handles cannot be flushed.
// Rename stays atomic, but directory metadata may lag after power loss.
func syncDir(string) error { return nil }

// checkOwnerOnly is a no-op on Windows: the data-directory DACL is enforced
// by secureDataDir in the service, and the master key is DPAPI-bound.
func checkOwnerOnly(string, os.FileMode) error { return nil }

// checkDataDir is a no-op on Windows for the same reason.
func checkDataDir(string) error { return nil }
