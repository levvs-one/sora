//go:build (!linux && !windows) || android

package guard

// PlatformFirewall returns NoopFirewall here. This package has no reversible
// macOS firewall implementation.
func PlatformFirewall(FirewallOptions) (Firewall, error) { return NoopFirewall{}, nil }
