//go:build linux

package profiles

import "testing"

func TestParseProcNetRouteFindsDefaultGateway(t *testing.T) {
	raw := []byte("Iface\tDestination\tGateway \tFlags\tRefCnt\tUse\tMetric\tMask\t\tMTU\tWindow\tIRTT\n" +
		"eth0\t00000000\t0101A8C0\t0003\t0\t0\t100\t00000000\t0\t0\t0\n" +
		"eth0\t0001A8C0\t00000000\t0001\t0\t0\t100\t00FFFFFF\t0\t0\t0\n")
	iface, gw := parseProcNetRoute(raw)
	if iface != "eth0" || gw != "192.168.1.1" {
		t.Fatalf("got %q %q, want eth0 192.168.1.1", iface, gw)
	}
}

func TestParseProcNetRouteSkipsUnspecifiedGateway(t *testing.T) {
	raw := []byte("Iface\tDestination\tGateway\tFlags\neth0\t00000000\t00000000\t0003\n")
	iface, gw := parseProcNetRoute(raw)
	if iface != "" || gw != "" {
		t.Fatalf("unspecified gateway must not match, got %q %q", iface, gw)
	}
}

func TestParseProcNetRouteEmpty(t *testing.T) {
	iface, gw := parseProcNetRoute([]byte("Iface\tDestination\tGateway\n"))
	if iface != "" || gw != "" {
		t.Fatalf("no default route must give empties, got %q %q", iface, gw)
	}
}

func TestParseIWLinkExtractsSSID(t *testing.T) {
	out := []byte("Connected to 12:34:56:78:9a:bc (on wlan0)\n\tSSID: Home_Network\n\tfreq: 5180\n")
	if got := parseIWLink(out); got != "Home_Network" {
		t.Fatalf("got %q, want Home_Network", got)
	}
}

func TestParseIWLinkNotConnected(t *testing.T) {
	if got := parseIWLink([]byte("Not connected.\n")); got != "" {
		t.Fatalf("got %q, want empty", got)
	}
}

func TestResolveSystemBinFindsSh(t *testing.T) {
	p, err := resolveSystemBin("sh")
	if err != nil || p == "" {
		t.Fatalf("sh must resolve from system dirs: %v", p)
	}
}

func TestResolveSystemBinRejectsPlantedName(t *testing.T) {
	if _, err := resolveSystemBin("definitely-not-a-real-binary-xyz"); err == nil {
		t.Fatal("missing binary must fail closed")
	}
}
