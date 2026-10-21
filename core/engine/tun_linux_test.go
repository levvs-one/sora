//go:build linux

package engine

import (
	"net/netip"
	"os"
	"os/exec"
	"strings"
	"testing"
)

func TestPrepareTunWithActiveAdapter(t *testing.T) {
	namespace, err := os.Readlink("/proc/self/ns/net")
	if err != nil {
		t.Fatal(err)
	}
	parent := os.Getenv("SORA_TUN_TEST_PARENT_NETNS")
	if parent == "" {
		if _, err := exec.LookPath("unshare"); err != nil {
			t.Skip(t, "unshare is required for isolated interface tests")
		}
		if _, err := exec.LookPath("ip"); err != nil {
			t.Skip(t, "ip is required for isolated interface tests")
		}
		if out, err := exec.CommandContext(t.Context(), "unshare", "-Urn", "true").CombinedOutput(); err != nil {
			t.Skipf("network namespaces unavailable: %v: %s", err, out)
		}
		self, err := os.Executable()
		if err != nil {
			t.Fatal(err)
		}
		cmd := exec.CommandContext(t.Context(), "unshare", "-Urn", "--", self, "-test.run=^TestPrepareTunWithActiveAdapter$", "-test.v")
		cmd.Env = append(os.Environ(), "SORA_TUN_TEST_PARENT_NETNS="+namespace)
		out, err := cmd.CombinedOutput()
		t.Logf("isolated interface tests:\n%s", out)
		if err != nil {
			t.Fatal(err)
		}
		return
	}
	if parent == namespace {
		t.Fatal("refusing to change interfaces in the parent network namespace")
	}
	ip := func(t *testing.T, args ...string) {
		t.Helper()
		if out, err := exec.CommandContext(t.Context(), "ip", args...).CombinedOutput(); err != nil {
			t.Fatalf("ip %v: %v: %s", args, err, out)
		}
	}
	ip(t, "link", "add", "other0", "type", "dummy")
	// The default device name and an explicit name must retain their pools
	// while the previous engine still owns the adapter.
	for _, name := range []string{"", "custom-tun"} {
		t.Run("own adapter "+name, func(t *testing.T) {
			device := name
			if device == "" {
				device = TunDevice
			}
			ip(t, "link", "add", device, "type", "dummy")
			defer ip(t, "link", "del", device)
			ip(t, "address", "add", tunPools4[0], "dev", device)
			ip(t, "-6", "address", "add", tunPools6[0], "dev", device, "nodad")
			p := &Plan{Tun: Tun{Enabled: true, DeviceName: name,
				IPv4: netip.MustParsePrefix(tunPools4[0]), IPv6: netip.MustParsePrefix(tunPools6[0])}}
			if err := PrepareTun(p); err != nil {
				t.Fatalf("reapply with own active adapter: %v", err)
			}
			if err := PrepareTun(p); err != nil {
				t.Fatalf("repeat preparation: %v", err)
			}
			p.Tun.IPv4, p.Tun.IPv6 = netip.Prefix{}, netip.Prefix{}
			if err := PrepareTun(p); err != nil {
				t.Fatalf("select pools with own active adapter: %v", err)
			}
			if p.Tun.IPv4.String() != tunPools4[0] || p.Tun.IPv6.String() != tunPools6[0] {
				t.Fatalf("own adapter changed the selected pools: %v", p.Tun.Addresses())
			}
			for _, prefix := range []string{tunPools4[0], tunPools6[0]} {
				ip(t, "address", "add", prefix, "dev", "other0")
				err := PrepareTun(p)
				ip(t, "address", "del", prefix, "dev", "other0")
				if err == nil || !strings.Contains(err.Error(), "overlaps an existing interface") {
					t.Errorf("other interface with %s must conflict: %v", prefix, err)
				}
			}
		})
	}
}
