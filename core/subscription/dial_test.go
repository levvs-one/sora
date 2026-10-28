package subscription

import (
	"net/netip"
	"testing"
)

func TestAFetchFromTheInternetNeverReachesALocalAddress(t *testing.T) {
	for _, address := range []string{"127.0.0.1:443", "[::1]:443", "10.0.0.5:443", "192.168.1.1:443", "169.254.169.254:80", "[fe80::1]:443", "0.0.0.0:443"} {
		if checkDial(false, address) == nil {
			t.Errorf("%s was dialled for a subscription on the internet", address)
		}
	}
	if err := checkDial(false, "93.184.216.34:443"); err != nil {
		t.Errorf("a public address was refused: %v", err)
	}
	if err := checkDial(true, "192.168.1.1:443"); err != nil {
		t.Errorf("a subscription on the local network could not reach it: %v", err)
	}
}

func TestALocalSubscriptionIsRecognised(t *testing.T) {
	// Only IP literals grant private dials: hostnames are never trusted,
	// even if DNS would resolve them into the private range.
	for host, want := range map[string]bool{
		"127.0.0.1": true, "192.168.0.10": true, "::1": true,
		"localhost": false, "93.184.216.34": false, "example.com": false,
		"100.100.100.200": false, "192.0.2.1": false, "0.0.0.0": false,
		"224.0.0.1": false, "2001:db8::1": false,
	} {
		if got := isPrivateHost(host); got != want {
			t.Errorf("isPrivateHost(%q) = %v, want %v", host, got, want)
		}
	}
}

func TestSubscriptionAddressClassification(t *testing.T) {
	for _, host := range []string{
		"0.0.0.0", "127.0.0.1", "10.0.0.1", "100.64.0.1", "100.100.100.200",
		"169.254.169.254", "172.16.0.1", "192.168.1.1", "192.0.0.1", "192.0.2.1",
		"198.18.0.1", "198.51.100.1", "203.0.113.1", "224.0.0.1", "240.0.0.1",
		"::", "::1", "fe80::1", "fc00::1", "ff02::1", "2001:db8::1", "2002:7f00:1::",
		"64:ff9b::7f00:1", "64:ff9b::a00:1", "64:ff9b::6464:64c8", "::ffff:127.0.0.1",
		"2001:4860:4860::8888%eth0",
	} {
		if publicAddr(netip.MustParseAddr(host)) {
			t.Errorf("special-purpose address %s classified as public", host)
		}
	}
	for _, host := range []string{"93.184.216.34", "8.8.8.8", "2001:4860:4860::8888", "::ffff:8.8.8.8", "64:ff9b::808:808"} {
		if !publicAddr(netip.MustParseAddr(host)) {
			t.Errorf("public address %s refused", host)
		}
	}
	if publicAddr(netip.Addr{}) {
		t.Fatal("invalid address classified as public")
	}
	for _, address := range []string{"100.100.100.200:443", "192.0.2.1:443", "0.0.0.0:443"} {
		if checkDial(true, address) == nil {
			t.Errorf("local-origin permission admitted special-purpose destination %s", address)
		}
	}
}

func TestSubscriptionReferenceHostNormalisation(t *testing.T) {
	for reference, want := range map[string]string{
		"https://EXAMPLE.COM./sub?token=a%2Fb": "https://example.com/sub?token=a%2Fb",
		"https://bücher.example:8443/sub":      "https://xn--bcher-kva.example:8443/sub",
		"https://[::1]:8443/sub":               "https://[::1]:8443/sub",
	} {
		parsed, err := ValidateReference(reference)
		if err != nil || parsed.String() != want {
			t.Errorf("normalised reference = %v, error=%v, want %s", parsed, err, want)
		}
	}
	for _, reference := range []string{"https://１２７.０.０.１/sub", "https://127.0.0.1./sub", "https://127.0.0.1../sub", "https://localhost../sub", "https://[::1]bad/sub", "https://\u200d.example/sub"} {
		if _, err := ValidateReference(reference); err == nil {
			t.Errorf("ambiguous reference accepted: %s", reference)
		}
	}
}
