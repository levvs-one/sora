//go:build !linux

package diagnostics

// SystemEncryptedDNS is not implemented on this OS: detecting OS-level
// encrypted DNS (Windows DoH templates, macOS profiles) needs
// platform-specific plumbing that does not exist yet. Returning nil tells
// the encrypted-dns check to report "unknown" instead of pretending the
// bypass cannot happen.
func SystemEncryptedDNS() []string {
	return nil
}
