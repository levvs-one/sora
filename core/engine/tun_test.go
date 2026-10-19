package engine

import (
	"net/netip"
	"slices"
	"strings"
	"testing"
)

func TestChooseTunPrefixAvoidsOverlappingNetworks(t *testing.T) {
	for _, occupied := range []string{"192.0.2.1/30", "192.0.2.3/32", "172.16.0.1/12"} {
		used := []netip.Prefix{netip.MustParsePrefix(occupied)}
		got, err := chooseTunPrefix(tunPools4, used)
		if err != nil {
			t.Fatal(err)
		}
		if got.Overlaps(used[0]) {
			t.Errorf("chosen %s overlaps %s", got, used[0])
		}
	}
}

func TestChooseTunPrefixIPv6AndExhaustion(t *testing.T) {
	used := []netip.Prefix{netip.MustParsePrefix(tunPools6[0]), netip.MustParsePrefix("172.19.0.0/16")}
	got, err := chooseTunPrefix(tunPools6, used)
	if err != nil || got.String() != tunPools6[1] {
		t.Fatalf("choice = %s, %v", got, err)
	}
	for _, pools := range [][]string{tunPools4, tunPools6} {
		used = nil
		for _, pool := range pools {
			used = append(used, netip.MustParsePrefix(pool))
		}
		if _, err := chooseTunPrefix(pools, used); err == nil {
			t.Fatal("exhausted pools must fail")
		}
	}
	if _, err := chooseTunPrefix([]string{"invalid"}, nil); err == nil {
		t.Fatal("invalid pool accepted")
	}
	if _, err := chooseTunPrefix(tunPools4, []netip.Prefix{netip.MustParsePrefix("192.0.2.0/24")}); err == nil {
		t.Fatal("an occupied parent network must exhaust all its adapter subnets")
	}
}

func TestPreparedTunKeepsSessionAddresses(t *testing.T) {
	if err := PrepareTun(nil); err == nil {
		t.Fatal("nil plan accepted")
	}
	p := &Plan{Tun: Tun{Enabled: true}, DNS: DNS{Mode: string(DNSFakeIP)}}
	if err := PrepareTun(p); err != nil {
		t.Fatal(err)
	}
	before := p.Tun.Addresses()
	if p.Tun.IPv4.Bits() != 30 || p.Tun.IPv6.Bits() != 126 || p.DNS.FakeIPRange == "" {
		t.Fatalf("tun = %+v, dns = %+v", p.Tun, p.DNS)
	}
	if err := PrepareTun(p); err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(before, p.Tun.Addresses()) {
		t.Fatal("a restart changed addresses")
	}
	want := []netip.Prefix{p.Tun.IPv4.Masked(), p.Tun.IPv6.Masked()}
	if !slices.Equal(want, p.Tun.Networks()) {
		t.Fatalf("networks = %v, want %v", p.Tun.Networks(), want)
	}
	p.Tun.Enabled = false
	if len(p.Tun.Networks()) != 0 {
		t.Fatal("proxy mode grants tunnel network permits")
	}
}

func TestTunAndFakeIPAvoidLANAndEachOther(t *testing.T) {
	for _, fake := range []string{"", "198.18.0.0/15", "198.19.0.0/16"} {
		p := &Plan{Tun: Tun{Enabled: true}, DNS: DNS{FakeIPRange: fake}}
		if err := PrepareTun(p); err != nil {
			t.Fatal(err)
		}
		pool := netip.MustParsePrefix(p.DNS.FakeIPRange)
		if pool.Overlaps(p.Tun.IPv4) {
			t.Fatal("adapter overlaps fake-IP pool")
		}
		for _, network := range []string{"10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "169.254.0.0/16", "fc00::/7", "fe80::/10"} {
			lan := netip.MustParsePrefix(network)
			if pool.Overlaps(lan) || p.Tun.IPv4.Overlaps(lan) || p.Tun.IPv6.Overlaps(lan) {
				t.Fatalf("session overlaps LAN %s", lan)
			}
		}
	}
	for _, fake := range []string{"172.19.0.0/16", "10.0.0.0/8", "198.18.0.0/14", "invalid"} {
		if err := PrepareTun(&Plan{Tun: Tun{Enabled: true}, DNS: DNS{FakeIPRange: fake}}); err == nil {
			t.Fatalf("unsafe pool accepted: %s", fake)
		}
	}
	for _, address := range []string{"172.20.0.1/30", "169.254.0.1/30", "198.18.0.1/30", "192.0.2.1/1"} {
		p := &Plan{Tun: Tun{Enabled: true, IPv4: netip.MustParsePrefix(address)}}
		if err := PrepareTun(p); err == nil {
			t.Fatalf("unsafe adapter accepted: %s", address)
		}
	}
}

// TestDeviceNameValidation locks SORA-M2: the TUN device name reaches
// privileged `ip` invocations, so only plain kernel interface names pass.
func TestDeviceNameValidation(t *testing.T) {
	for _, name := range []string{"sora0", "tun0", "sora-1", "sora_2", "sora.3", "a12345678901234"} {
		if err := validateInterfaceName("tun", name); err != nil {
			t.Errorf("validateInterfaceName(%q) = %v, want nil", name, err)
		}
	}
	for _, name := range []string{
		"", "sora0 xfrm", "-sora0", " sora0", "sora0 ", "sora0;reboot",
		"sora0|id", "sora0$(id)", "sora0`id`", "../etc", "a123456789012345",
		"sora\x00x",
	} {
		if err := validateInterfaceName("tun", name); err == nil {
			t.Errorf("validateInterfaceName(%q) = nil, want an error", name)
		}
	}
}

// TestTunValidateRejectsEvilDeviceName ensures a hostile device name fails
// plan validation instead of reaching the privileged routing layer.
func TestTunValidateRejectsEvilDeviceName(t *testing.T) {
	tun := Tun{Enabled: true, DeviceName: "sora0 evil"}
	if err := tun.validate(); err == nil {
		t.Fatal("Tun.validate() accepted a device name with a space")
	}
	tun.DeviceName = "sora0"
	if err := tun.validate(); err != nil {
		t.Fatalf("Tun.validate() = %v, want nil", err)
	}
}

// TestPrepareTunRejectsExplicitPrefixOverlappingLAN locks SORA-L19:
// caller-provided adapter prefixes must be checked against LAN interfaces,
// not just auto-selected ones. 127.0.0.0/8 is always present via loopback.
func TestPrepareTunRejectsExplicitPrefixOverlappingLAN(t *testing.T) {
	p := &Plan{Tun: Tun{Enabled: true, IPv4: netip.MustParsePrefix("127.0.0.1/30")}}
	err := PrepareTun(p)
	if err == nil {
		t.Fatal("an explicit adapter prefix overlapping LAN was accepted")
	}
	if !strings.Contains(err.Error(), "overlaps an existing interface") {
		t.Errorf("unexpected error: %v", err)
	}
}
