//go:build (!linux && !windows) || android

package profiles

// The core still has to compile on platforms Sora does not ship yet
// (macOS). There the network cannot be read, so the fingerprint stays
// empty and no profile ever matches automatically.

func defaultRoute() (iface, gateway string) { return "", "" }

func currentSSID(string) string { return "" }

func currentSecurity(string, string) Security { return SecurityUnknown }
