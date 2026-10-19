package profiles

// Security is the Wi-Fi authentication family of the current network,
// detected best-effort by the platform fingerprint code. Unknown means the
// detector could not tell — it is not the same as open.
type Security string

const (
	// SecurityUnknown means the authentication family could not be read.
	SecurityUnknown Security = "unknown"
	// SecurityWired means the default route is not a Wi-Fi association.
	SecurityWired Security = "wired"
	// SecurityOpen means the access point advertises no link-layer
	// authentication (no RSN/WPA information elements, privacy bit clear).
	SecurityOpen Security = "open"
	// SecurityWEP means the access point uses WEP (privacy bit set, no
	// RSN/WPA information elements).
	SecurityWEP Security = "wep"
	// SecurityWPA means the access point advertises WPA/WPA2/WPA3
	// authentication suites. The generation is not distinguished: this is
	// a heuristic, not a proof of safety.
	SecurityWPA Security = "wpa"
)

// Risky reports whether the network offers no meaningful link-layer
// protection: open or WEP. WPA of any generation is not flagged.
func (s Security) Risky() bool {
	return s == SecurityOpen || s == SecurityWEP
}
