//go:build linux

package profiles

import "testing"

var iwScanWPA = []byte(`BSS 12:34:56:78:9a:bc(on wlan0)
	TSF: 123456789 usec (0d, 00:02:03)
	freq: 5180
	beacon interval: 100 TUs
	capability: ESS Privacy ShortSlotTime (0x0431)
	signal: -55.00 dBm
	SSID: Home_Network
	RSN:	 * Version: 1
		 * Group cipher: CCMP
		 * Pairwise ciphers: CCMP
		 * Authentication suites: PSK
		 * Capabilities: 1-PTKSA-RC 1-GTKSA-RC (0x0000)
`)

var iwScanWEP = []byte(`BSS aa:bb:cc:dd:ee:ff(on wlan0)
	freq: 2412
	beacon interval: 100 TUs
	capability: ESS Privacy ShortPreamble ShortSlotTime (0x0423)
	signal: -70.00 dBm
	SSID: Old_Router
`)

var iwScanOpen = []byte(`BSS 11:22:33:44:55:66(on wlan0)
	freq: 2412
	beacon interval: 100 TUs
	capability: ESS ShortPreamble ShortSlotTime (0x0421)
	signal: -60.00 dBm
	SSID: Cafe_Open
`)

func TestSecurityFromIWScanWPA(t *testing.T) {
	if got := securityFromIWScan("12:34:56:78:9a:bc", iwScanWPA); got != SecurityWPA {
		t.Fatalf("got %q, want wpa", got)
	}
}

func TestSecurityFromIWScanWEP(t *testing.T) {
	if got := securityFromIWScan("aa:bb:cc:dd:ee:ff", iwScanWEP); got != SecurityWEP {
		t.Fatalf("got %q, want wep", got)
	}
}

func TestSecurityFromIWScanOpen(t *testing.T) {
	if got := securityFromIWScan("11:22:33:44:55:66", iwScanOpen); got != SecurityOpen {
		t.Fatalf("got %q, want open", got)
	}
}

func TestSecurityFromIWScanUnknownBSSID(t *testing.T) {
	if got := securityFromIWScan("00:00:00:00:00:00", iwScanWPA); got != SecurityUnknown {
		t.Fatalf("absent BSS must be unknown, got %q", got)
	}
	if got := securityFromIWScan("12:34:56:78:9a:bc", nil); got != SecurityUnknown {
		t.Fatalf("empty scan must be unknown, got %q", got)
	}
}

func TestSecurityFromIWScanBlockIsolation(t *testing.T) {
	// The WPA block comes first; the open target must not inherit its
	// authentication suites.
	mixed := append(append([]byte{}, iwScanWPA...), iwScanOpen...)
	if got := securityFromIWScan("11:22:33:44:55:66", mixed); got != SecurityOpen {
		t.Fatalf("block isolation broken: got %q, want open", got)
	}
	if got := securityFromIWScan("12:34:56:78:9a:bc", mixed); got != SecurityWPA {
		t.Fatalf("got %q, want wpa", got)
	}
}

func TestSecurityFromIWScanCaseInsensitiveBSSID(t *testing.T) {
	if got := securityFromIWScan("12:34:56:78:9A:BC", iwScanWPA); got != SecurityWPA {
		t.Fatalf("BSSID match must be case-insensitive, got %q", got)
	}
}

func TestParseIWBSSID(t *testing.T) {
	out := []byte("Connected to 12:34:56:78:9a:bc (on wlan0)\n\tSSID: Home_Network\n\tfreq: 5180\n")
	if got := parseIWBSSID(out); got != "12:34:56:78:9a:bc" {
		t.Fatalf("got %q, want the BSSID", got)
	}
	if got := parseIWBSSID([]byte("Not connected.\n")); got != "" {
		t.Fatalf("not connected must give empty BSSID, got %q", got)
	}
}

func TestCurrentSecurityFastPaths(t *testing.T) {
	if got := currentSecurity("", "Some_SSID"); got != SecurityUnknown {
		t.Fatalf("offline must be unknown, got %q", got)
	}
	if got := currentSecurity("eth0", ""); got != SecurityWired {
		t.Fatalf("wired must be wired, got %q", got)
	}
}

func TestSecurityRisky(t *testing.T) {
	for _, s := range []Security{SecurityOpen, SecurityWEP} {
		if !s.Risky() {
			t.Fatalf("%q must be risky", s)
		}
	}
	for _, s := range []Security{SecurityWPA, SecurityWired, SecurityUnknown, ""} {
		if s.Risky() {
			t.Fatalf("%q must not be risky", s)
		}
	}
}
