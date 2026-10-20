package engine

import (
	"fmt"
	"net"
	"net/netip"
	"slices"
)

// Adapter subnets and fake addresses have separate reservations. Neither uses
// private/link-local space, which the kill switch keeps reachable.
var tunPools4 = []string{"192.0.2.1/30", "192.0.2.5/30", "192.0.2.9/30"}
var tunPools6 = []string{"2001:db8:5340::1/126", "2001:db8:5341::1/126", "2001:db8:5342::1/126"}

// fakeIPPools lists the fake-address pools in priority order. The default is
// the RFC 2544 benchmarking range the renderers share (S7); the spares are
// the other documentation/benchmark ranges. All sit outside private and
// link-local space, so the kill switch never keeps them reachable.
// benchmarkRangeOf validates an explicitly configured pool; the spares are
// only picked when the default is genuinely occupied by the machine.
var fakeIPPools = []string{"198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24"}

// benchmarkRange is the range an explicitly configured fake-IP pool must
// stay within. Reject custom LAN pools rather than allowing cached fake
// addresses onto LAN.
var benchmarkRange = netip.MustParsePrefix("198.18.0.0/15")

// PrepareTun chooses session addresses before the guard and engines use them.
// Restarts retain the choice so network watchers and firewall permits agree.
func PrepareTun(p *Plan) error {
	return prepareTun(p, net.InterfaceAddrs)
}

// prepareTun is PrepareTun with the interface list injected. Production
// callers pass net.InterfaceAddrs; tests pass a fake so the suite does not
// depend on the machine's interfaces (a host with a real 198.18.0.0/15
// interface used to break the tests).
func prepareTun(p *Plan, listAddrs func() ([]net.Addr, error)) error {
	if p == nil {
		return fmt.Errorf("tun: nil plan")
	}
	if !p.Tun.Enabled {
		return nil
	}
	addrs, err := listAddrs()
	if err != nil {
		return fmt.Errorf("tun: read interface addresses: %w", err)
	}
	used := make([]netip.Prefix, 0, len(addrs))
	for _, addr := range addrs {
		prefix, err := netip.ParsePrefix(addr.String())
		if err != nil {
			return fmt.Errorf("tun: read interface prefix: %w", err)
		}
		used = append(used, prefix)
	}
	fake := p.DNS.FakeIPRange
	configured := fake != ""
	if !configured {
		// A real 198.18.0.0/15 network makes the default unusable; fall
		// back to another benchmark range instead of refusing to start
		// TUN+FakeIP.
		candidate, err := pickFakeIPPool(used)
		if err != nil {
			return err
		}
		fake = candidate
	}
	fakePrefix, err := netip.ParsePrefix(fake)
	if configured {
		// The benchmark range is reserved for synthesized addresses.
		// Reject custom LAN pools rather than allowing cached fake
		// addresses onto LAN.
		if err != nil || !fakePrefix.Addr().Is4() || fakePrefix.Bits() < benchmarkRange.Bits() || !benchmarkRange.Contains(fakePrefix.Addr()) {
			return fmt.Errorf("tun: fake-IP pool must be within %s", benchmarkRange)
		}
	} else if err != nil || !fakePrefix.Addr().Is4() || fakePrefix.Bits() < benchmarkRange.Bits() {
		return fmt.Errorf("tun: fake-IP pool is not usable: %s", fake)
	}
	// Keep the selected pool across restarts, including when both adapter
	// addresses were supplied by the caller.
	if slices.ContainsFunc(used, fakePrefix.Overlaps) {
		return fmt.Errorf("tun: fake-IP pool overlaps an existing interface")
	}
	used = append(used, fakePrefix)
	if !p.Tun.IPv4.IsValid() {
		p.Tun.IPv4, err = chooseTunPrefix(tunPools4, used)
		if err != nil {
			return err
		}
	}
	if !p.Tun.IPv6.IsValid() {
		p.Tun.IPv6, err = chooseTunPrefix(tunPools6, used)
		if err != nil {
			return err
		}
	}
	if p.Tun.IPv4.Overlaps(fakePrefix) || !p.Tun.IPv4.Addr().Is4() || !p.Tun.IPv6.Addr().Is6() || p.Tun.IPv4.Bits() != 30 || p.Tun.IPv6.Bits() != 126 {
		return fmt.Errorf("tun: adapters must use separate IPv4 /30 and IPv6 /126 subnets")
	}
	// Caller-provided prefixes skip chooseTunPrefix, so they must be checked
	// against LAN interfaces here as well (SORA-L19).
	for _, prefix := range []netip.Prefix{p.Tun.IPv4, p.Tun.IPv6} {
		if slices.ContainsFunc(used, prefix.Overlaps) {
			return fmt.Errorf("tun: adapter subnet %s overlaps an existing interface", prefix)
		}
	}
	for _, address := range []netip.Addr{p.Tun.IPv4.Addr(), p.Tun.IPv6.Addr()} {
		if !address.IsGlobalUnicast() || address.IsPrivate() {
			return fmt.Errorf("tun: adapter subnets must be outside private and link-local networks")
		}
	}
	if p.Tun.DeviceName == "" {
		p.Tun.DeviceName = TunDevice
	}
	// The device name reaches privileged `ip` invocations; reject anything
	// but a plain kernel interface name here as well as in Tun.validate
	// (SORA-M2).
	if err := validateInterfaceName("tun", p.Tun.DeviceName); err != nil {
		return err
	}
	p.DNS.FakeIPRange = fakePrefix.Masked().String()
	return nil
}

// pickFakeIPPool returns the first fake-address pool that does not overlap
// any existing interface, so a network that genuinely owns 198.18.0.0/15
// falls back to another benchmark range instead of failing to start
// TUN+FakeIP. When even the spares are taken the error stays honest: it
// reaches the UI through the localized plan error key at the session
// layer, never as a raw string.
func pickFakeIPPool(used []netip.Prefix) (string, error) {
	for _, candidate := range fakeIPPools {
		pool := netip.MustParsePrefix(candidate)
		if !slices.ContainsFunc(used, pool.Overlaps) {
			return candidate, nil
		}
	}
	return "", fmt.Errorf("tun: every fake-IP pool overlaps an existing interface")
}

func chooseTunPrefix(candidates []string, used []netip.Prefix) (netip.Prefix, error) {
	for _, candidate := range candidates {
		prefix, err := netip.ParsePrefix(candidate)
		if err != nil {
			return netip.Prefix{}, fmt.Errorf("tun: invalid address pool: %w", err)
		}
		if !slices.ContainsFunc(used, prefix.Overlaps) {
			return prefix, nil
		}
	}
	return netip.Prefix{}, fmt.Errorf("tun: all address pools overlap existing interfaces")
}

// Addresses supplies the adapter addresses to renderers. Defaults also permit
// validation of plans before session preparation.
func (t Tun) Addresses() []string {
	a4, a6 := t.IPv4, t.IPv6
	if !a4.IsValid() {
		a4 = netip.MustParsePrefix(tunPools4[0])
	}
	if !a6.IsValid() {
		a6 = netip.MustParsePrefix(tunPools6[0])
	}
	return []string{a4.String(), a6.String()}
}

// Networks limits firewall permits to the running session's adapter subnets.
func (t Tun) Networks() []netip.Prefix {
	if !t.Enabled {
		return nil
	}
	addresses := t.Addresses()
	return []netip.Prefix{netip.MustParsePrefix(addresses[0]).Masked(), netip.MustParsePrefix(addresses[1]).Masked()}
}
