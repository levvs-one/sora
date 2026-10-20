package engine

import (
	"errors"
	"net"
	"net/netip"
	"slices"
	"strings"
	"testing"
)

// fakeAddrs injects a fixed interface list into prepareTun so the tests do
// not read the machine's interfaces: a host with a real 198.18.0.0/15
// interface used to break them.
func fakeAddrs(cidrs ...string) func() ([]net.Addr, error) {
	return func() ([]net.Addr, error) {
		addrs := make([]net.Addr, 0, len(cidrs))
		for _, cidr := range cidrs {
			_, ipnet, err := net.ParseCIDR(cidr)
			if err != nil {
				return nil, errors.New("test: bad cidr " + cidr)
			}
			addrs = append(addrs, ipnet)
		}
		return addrs, nil
	}
}

func TestPreparedTunKeepsSessionAddresses(t *testing.T) {
	if err := PrepareTun(nil); err == nil {
		t.Fatal("nil plan accepted")
	}
	addrs := fakeAddrs("192.168.1.5/24", "fe80::1/64")
	p := &Plan{Tun: Tun{Enabled: true}, DNS: DNS{Mode: string(DNSFakeIP)}}
	if err := prepareTun(p, addrs); err != nil {
		t.Fatal(err)
	}
	before := p.Tun.Addresses()
	if p.Tun.IPv4.Bits() != 30 || p.Tun.IPv6.Bits() != 126 || p.DNS.FakeIPRange == "" {
		t.Fatalf("tun = %+v, dns = %+v", p.Tun, p.DNS)
	}
	if err := prepareTun(p, addrs); err != nil {
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
	addrs := fakeAddrs("10.1.2.3/24", "192.168.1.5/24")
	for _, fake := range []string{"", "198.18.0.0/15", "198.19.0.0/16"} {
		p := &Plan{Tun: Tun{Enabled: true}, DNS: DNS{FakeIPRange: fake}}
		if err := prepareTun(p, addrs); err != nil {
			t.Fatal(err)
		}
		pool := netip.MustParsePrefix(p.DNS.FakeIPRange)
		if pool.Overlaps(p.Tun.IPv4) {
			t.Fatal("adapter overlaps fake-IP pool")
		}
		// S7: the empty plan default is the pool every renderer shares.
		if fake == "" && p.DNS.FakeIPRange != DefaultFakeIPRange {
			t.Fatalf("default fake-IP pool = %q, want the shared %q", p.DNS.FakeIPRange, DefaultFakeIPRange)
		}
		for _, network := range []string{"10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "169.254.0.0/16", "fc00::/7", "fe80::/10"} {
			lan := netip.MustParsePrefix(network)
			if pool.Overlaps(lan) || p.Tun.IPv4.Overlaps(lan) || p.Tun.IPv6.Overlaps(lan) {
				t.Fatalf("session overlaps LAN %s", lan)
			}
		}
	}
	for _, fake := range []string{"172.19.0.0/16", "10.0.0.0/8", "198.18.0.0/14", "invalid"} {
		if err := prepareTun(&Plan{Tun: Tun{Enabled: true}, DNS: DNS{FakeIPRange: fake}}, addrs); err == nil {
			t.Fatalf("unsafe pool accepted: %s", fake)
		}
	}
	for _, address := range []string{"172.20.0.1/30", "169.254.0.1/30", "198.18.0.1/30", "192.0.2.1/1"} {
		p := &Plan{Tun: Tun{Enabled: true, IPv4: netip.MustParsePrefix(address)}}
		if err := prepareTun(p, addrs); err == nil {
			t.Fatalf("unsafe adapter accepted: %s", address)
		}
	}
}

// TestFakeIPPoolFallsBackWhenTheDefaultIsTaken is the network-with-real-
// 198.18.0.0/15 case: TUN+FakeIP must start on a spare benchmark pool
// instead of refusing outright.
func TestFakeIPPoolFallsBackWhenTheDefaultIsTaken(t *testing.T) {
	p := &Plan{Tun: Tun{Enabled: true}, DNS: DNS{FakeIPRange: ""}}
	if err := prepareTun(p, fakeAddrs("198.18.1.5/15")); err != nil {
		t.Fatalf("prepareTun() error = %v", err)
	}
	if p.DNS.FakeIPRange != "198.51.100.0/24" {
		t.Fatalf("fallback pool = %q, want the first spare benchmark range", p.DNS.FakeIPRange)
	}
	p = &Plan{Tun: Tun{Enabled: true}, DNS: DNS{FakeIPRange: ""}}
	if err := prepareTun(p, fakeAddrs("198.18.1.5/15", "198.51.100.1/24")); err != nil {
		t.Fatalf("prepareTun() error = %v", err)
	}
	if p.DNS.FakeIPRange != "203.0.113.0/24" {
		t.Fatalf("second fallback pool = %q, want the second spare benchmark range", p.DNS.FakeIPRange)
	}
}

// TestFakeIPPoolFallbackSurvivesReprepare: PrepareTun persists the pool
// it picked into the plan, and the Connect path prepares the same plan
// more than once. The second pass must accept the core's own spare pool
// instead of rejecting it as a user configuration outside the benchmark
// range (the integration E2E caught exactly this on a host whose egress
// interface sits inside 198.18.0.0/15: TUN Connect always failed with
// "fake-IP pool must be within 198.18.0.0/15").
func TestFakeIPPoolFallbackSurvivesReprepare(t *testing.T) {
	p := &Plan{Tun: Tun{Enabled: true}, DNS: DNS{FakeIPRange: ""}}
	addrs := fakeAddrs("198.19.0.2/30")
	if err := prepareTun(p, addrs); err != nil {
		t.Fatalf("first prepareTun() error = %v", err)
	}
	if p.DNS.FakeIPRange != "198.51.100.0/24" {
		t.Fatalf("fallback pool = %q, want the first spare benchmark range", p.DNS.FakeIPRange)
	}
	if err := prepareTun(p, addrs); err != nil {
		t.Fatalf("second prepareTun() error = %v: the core rejected its own fallback pool", err)
	}
	if p.DNS.FakeIPRange != "198.51.100.0/24" {
		t.Fatalf("pool changed across reprepare: %q", p.DNS.FakeIPRange)
	}
}

// TestFakeIPPoolExhaustion: every benchmark range occupied is a hard but
// honest error — it reaches the UI through the localized plan error key,
// never as a raw string.
func TestFakeIPPoolExhaustion(t *testing.T) {
	p := &Plan{Tun: Tun{Enabled: true}, DNS: DNS{FakeIPRange: ""}}
	err := prepareTun(p, fakeAddrs("198.18.1.5/15", "198.51.100.1/24", "203.0.113.1/24"))
	if err == nil {
		t.Fatal("an occupied world accepted without a free fake-IP pool")
	}
	if p.DNS.FakeIPRange != "" {
		t.Fatalf("a failed preparation still pinned a pool: %q", p.DNS.FakeIPRange)
	}
}

// TestExplicitFakeIPPoolStaysHonest: a configured pool that overlaps a real
// interface is rejected instead of silently replaced — the user asked for
// it explicitly.
func TestExplicitFakeIPPoolStaysHonest(t *testing.T) {
	p := &Plan{Tun: Tun{Enabled: true}, DNS: DNS{FakeIPRange: "198.19.0.0/16"}}
	if err := prepareTun(p, fakeAddrs("198.19.1.5/16")); err == nil {
		t.Fatal("an explicitly configured overlapping pool was accepted")
	}
}

// TestFallbackPoolsAreSafeDocuments the fallback list: every pool is v4,
// outside private and link-local space, and the pools never overlap each
// other or the adapter subnets.
func TestFallbackPoolsAreSafe(t *testing.T) {
	lan := []string{"10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "169.254.0.0/16", "fc00::/7", "fe80::/10", "127.0.0.0/8"}
	seen := []netip.Prefix{}
	for _, candidate := range fakeIPPools {
		pool := netip.MustParsePrefix(candidate)
		if !pool.Addr().Is4() || pool.Bits() < benchmarkRange.Bits() {
			t.Errorf("fallback pool %s is not a tight IPv4 range", candidate)
		}
		for _, network := range lan {
			if pool.Overlaps(netip.MustParsePrefix(network)) {
				t.Errorf("fallback pool %s overlaps %s", candidate, network)
			}
		}
		for _, adapter := range append([]string{}, tunPools4...) {
			if pool.Overlaps(netip.MustParsePrefix(adapter)) {
				t.Errorf("fallback pool %s overlaps adapter subnet %s", candidate, adapter)
			}
		}
		for _, other := range seen {
			if pool.Overlaps(other) {
				t.Errorf("fallback pools %s and %s overlap", candidate, other)
			}
		}
		seen = append(seen, pool)
	}
	if fakeIPPools[0] != DefaultFakeIPRange {
		t.Errorf("the first fallback pool = %q, want the shared default %q", fakeIPPools[0], DefaultFakeIPRange)
	}
}

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

// TestTunValidateMTURange locks the widened TUN MTU bound: a plan that pins
// MTU 9000 explicitly must pass validation, because the TUN MTU is a
// local-device value that never reaches a wire limit (mihomo defaults to
// 9000; sing-box renders an explicit pin unchanged). Values below 576 or
// above 9000 stay rejected.
func TestTunValidateMTURange(t *testing.T) {
	for _, mtu := range []int{576, 1400, 1500, 9000} {
		tun := Tun{Enabled: true, MTU: mtu}
		if err := tun.validate(); err != nil {
			t.Errorf("Tun.validate() with MTU %d = %v, want nil", mtu, err)
		}
	}
	for _, mtu := range []int{-1, 1, 575, 9001, 65536} {
		tun := Tun{Enabled: true, MTU: mtu}
		if err := tun.validate(); err == nil {
			t.Errorf("Tun.validate() with MTU %d = nil, want an error", mtu)
		}
	}
}

// TestPrepareTunRejectsExplicitPrefixOverlappingLAN locks SORA-L19:
// caller-provided adapter prefixes must be checked against LAN interfaces,
// not just auto-selected ones. The loopback interface is faked in.
func TestPrepareTunRejectsExplicitPrefixOverlappingLAN(t *testing.T) {
	p := &Plan{Tun: Tun{Enabled: true, IPv4: netip.MustParsePrefix("127.0.0.1/30")}}
	err := prepareTun(p, fakeAddrs("127.0.0.1/8"))
	if err == nil {
		t.Fatal("an explicit adapter prefix overlapping LAN was accepted")
	}
	if !strings.Contains(err.Error(), "overlaps an existing interface") {
		t.Errorf("unexpected error: %v", err)
	}
}
