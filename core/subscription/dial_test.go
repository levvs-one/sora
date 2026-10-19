package subscription

import "testing"

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
	// even if DNS would resolve them into the private range (SORA-L11).
	for host, want := range map[string]bool{
		"127.0.0.1": true, "192.168.0.10": true, "::1": true,
		"localhost": false, "93.184.216.34": false, "example.com": false,
	} {
		if got := isPrivateHost(host); got != want {
			t.Errorf("isPrivateHost(%q) = %v, want %v", host, got, want)
		}
	}
}
