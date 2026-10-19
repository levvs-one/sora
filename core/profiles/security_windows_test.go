//go:build windows

package profiles

import "testing"

var netshNetworks = []byte(`Interface name : Wi-Fi

There are 3 networks currently visible.

SSID 1 : Home_Network
    Network type            : Infrastructure
    Authentication          : WPA2-Personal
    Encryption              : CCMP
    BSSID 1                 : 12:34:56:78:9a:bc
         Signal             : 85%

SSID 2 : Cafe_Open
    Network type            : Infrastructure
    Authentication          : Open
    Encryption              : None

SSID 3 : Old_Router
    Network type            : Infrastructure
    Authentication          : Shared
    Encryption              : WEP
`)

func TestParseNetshNetworks(t *testing.T) {
	cases := []struct {
		ssid string
		want Security
	}{
		{"Home_Network", SecurityWPA},
		{"Cafe_Open", SecurityOpen},
		{"Old_Router", SecurityWEP},
		{"No_Such_Network", SecurityUnknown},
	}
	for _, tc := range cases {
		if got := parseNetshNetworks(netshNetworks, tc.ssid); got != tc.want {
			t.Errorf("parseNetshNetworks(%q) = %q, want %q", tc.ssid, got, tc.want)
		}
	}
}

func TestParseNetshNetworksEmpty(t *testing.T) {
	if got := parseNetshNetworks(nil, "Home_Network"); got != SecurityUnknown {
		t.Fatalf("empty output must be unknown, got %q", got)
	}
}
