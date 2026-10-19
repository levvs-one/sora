//go:build linux

package guard_test

import (
	"net/netip"
	"os"
	"runtime"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/guard"
)

// TestNftRulesetKeepsTheEngineAndCutsEverythingElse checks engine and
// local-network exemptions followed by a final output drop without host
// privileges.
func TestNftRulesetKeepsTheEngineAndCutsEverythingElse(t *testing.T) {
	ruleset := guard.NftRuleset(999, []string{"192.168.0.0/16"})
	wants := []string{
		"table inet sora {",
		"chain output {",
		"policy accept;",
		"meta skuid 999 accept",
		"oif lo accept",
		`oifname "sora0" accept`,
		"ct direction reply ct state established,related accept",
		"ip daddr 192.168.0.0/16 accept",
		"counter drop",
	}
	for _, want := range wants {
		if !strings.Contains(ruleset, want) {
			t.Errorf("the ruleset does not contain %q:\n%s", want, ruleset)
		}
	}
	// The final drop must follow every exception to keep tunnel traffic
	// working.
	if strings.LastIndex(ruleset, "counter drop") < strings.Index(ruleset, "meta skuid 999 accept") {
		t.Error("the drop rule comes before the engine exception")
	}
}

func TestNftRulesetKeepsPrivateSpaceByDefault(t *testing.T) {
	ruleset := guard.NftRuleset(0, nil)
	for _, network := range []string{"10.0.0.0/8", "192.168.0.0/16", "169.254.0.0/16", "fe80::/10"} {
		if !strings.Contains(ruleset, network) {
			t.Errorf("the ruleset does not keep %s reachable", network)
		}
	}
}

func TestNftRemoveIsSafeToRunTwice(t *testing.T) {
	// Treat nft's missing-table error as success because every exit path
	// can restore more than once.
	if !strings.HasPrefix(strings.TrimSpace(guard.NftRemove()), "delete table inet sora") {
		t.Errorf("the remove ruleset is %q", guard.NftRemove())
	}
}

func TestFirstLineKeepsAnNftMessageShort(t *testing.T) {
	if got := guard.FirstLine("table inet sora: Syntax error\nline 3\n"); got != "table inet sora: Syntax error" {
		t.Errorf("FirstLine() = %q", got)
	}
	if got := guard.FirstLine("   spaced   "); got != "spaced" {
		t.Errorf("FirstLine() = %q", got)
	}
}

func TestPlatformFirewallRefusesAnEngineWithoutAUser(t *testing.T) {
	if runtime.GOOS != "linux" {
		// Validate UIDs only on Linux; os.Getuid returns -1 on other
		// platforms.
		t.Skip("the engine is matched by user id on Linux only")
	}
	if _, err := guard.PlatformFirewall(guard.FirewallOptions{EngineUID: -1}); err == nil {
		t.Error("a kill switch accepted an engine without a user id")
	}
}

func TestPlatformFirewallIsUsable(t *testing.T) {
	switch runtime.GOOS {
	case "linux":
		// Skip host firewall changes requiring Linux root; rendering
		// tests cover the ruleset.
		t.Skip("the Linux kill switch is nftables; arming it in a test would change this machine")
	case "windows":
		t.Skip("the Windows kill switch blocks for real; firewall_windows_test.go checks what it lets through")
	}
	firewall, err := guard.PlatformFirewall(guard.FirewallOptions{EngineUID: 1000})
	if err != nil {
		t.Fatalf("PlatformFirewall() error = %v", err)
	}
	if firewall == nil {
		t.Fatal("PlatformFirewall() returned nothing")
	}
	// Noop arm and disarm must succeed because Android sessions invoke them
	// on every connection.
	if err := firewall.Arm(testContext(), []uint16{7890}); err != nil {
		t.Errorf("Arm() on a platform without a firewall = %v", err)
	}
	if err := firewall.Disarm(testContext()); err != nil {
		t.Errorf("Disarm() = %v", err)
	}
}

func TestDNSAndTunnelDestinationsPrecedeLANPermits(t *testing.T) {
	rules := guard.NftRuleset(999, []string{"0.0.0.0/0", "::/0"},
		netip.MustParsePrefix("192.0.2.0/30"), netip.MustParsePrefix("2001:db8:5340::/126"), netip.MustParsePrefix("198.18.0.0/16"))
	permit := strings.Index(rules, "ip daddr 0.0.0.0/0 accept")
	tunnel := strings.Index(rules, `oifname "sora0" accept`)
	for _, block := range []string{"th dport 53 counter drop", "ip daddr 192.0.2.0/30 counter drop", "ip6 daddr 2001:db8:5340::/126 counter drop", "ip daddr 198.18.0.0/16 counter drop"} {
		i := strings.Index(rules, block)
		if i <= tunnel || i >= permit {
			t.Fatalf("missing or misplaced block: %s", block)
		}
	}
}

func TestLegacyFakeIPCannotUseEngineOrLANPermits(t *testing.T) {
	rules := guard.NftRuleset(999, []string{"0.0.0.0/0"})
	block := strings.Index(rules, "ip daddr 172.19.0.0/16 counter drop")
	if block <= strings.Index(rules, `oifname "sora0" accept`) || block >= strings.Index(rules, "meta skuid 999 accept") || block >= strings.Index(rules, "ip daddr 0.0.0.0/0 accept") {
		t.Fatal("legacy fake addresses must leave only through Sora TUN")
	}
}

// TestArmRefusesRootUid locks SORA-H4: arming the kill switch as root would
// render "meta skuid 0 accept" and silently exempt every root process, so Arm
// must fail closed before touching the system.
func TestArmRefusesRootUid(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("the engine is matched by user id on Linux only")
	}
	// NewNftables resolves nft at construction from the trusted system
	// directories (audit R2): plant a fake through the test hook so the test
	// does not depend on nft being installed.
	dir := t.TempDir()
	if err := os.WriteFile(dir+"/nft", []byte("#!/bin/sh\nexit 0\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", dir+":"+os.Getenv("PATH"))
	guard.NftBinForTest = dir + "/nft"
	t.Cleanup(func() { guard.NftBinForTest = "" })
	firewall, err := guard.NewNftables(0, nil)
	if err != nil {
		t.Fatalf("NewNftables(0) error = %v", err)
	}
	if err := firewall.Arm(testContext(), []uint16{7890}); err == nil {
		t.Fatal("Arm() as root succeeded; the kill switch would leak root traffic")
	} else if !strings.Contains(err.Error(), "root") {
		t.Fatalf("Arm() as root failed without explaining why: %v", err)
	}
	if armed, err := firewall.Armed(testContext()); err != nil || armed {
		t.Fatalf("Armed() = %v, %v after a refused Arm", armed, err)
	}
}

// TestArmAndDisarmAreIdempotent locks SORA-M4/SORA-M5: a repeated Arm
// replaces the table instead of failing, and Disarm tolerates an already
// missing table. A fake nft binary simulates kernel state, including the
// atomicity of a single nft batch: a combined delete+add either replaces
// the table or aborts without applying anything.
func TestArmAndDisarmAreIdempotent(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("nftables is Linux-only")
	}
	dir := t.TempDir()
	state := dir + "/table.state"
	script := `#!/bin/sh
# Fake nft: reads a ruleset on stdin, keeps "table state" in $SORA_FAKE_STATE.
# A batch carrying both the delete and the new table is atomic: it replaces
# the table when present and aborts (applying nothing) when absent.
input=$(cat)
echo "$input" > "$SORA_FAKE_LAST_INPUT"
echo x >> "$SORA_FAKE_INVOCATIONS"
case "$input" in
*"delete table inet sora"*)
	if [ -f "$SORA_FAKE_STATE" ]; then
		rm -f "$SORA_FAKE_STATE"
	else
		echo "Error: Could not process rule: No such file or directory" >&2
		exit 1
	fi
	;;
esac
case "$input" in
*"table inet sora {"*)
	touch "$SORA_FAKE_STATE"
	exit 0
	;;
esac
exit 0
`
	nft := dir + "/nft"
	if err := os.WriteFile(nft, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", dir+":"+os.Getenv("PATH"))
	t.Setenv("SORA_FAKE_STATE", state)
	t.Setenv("SORA_FAKE_LAST_INPUT", dir+"/last.input")
	t.Setenv("SORA_FAKE_INVOCATIONS", dir+"/invocations")
	// The production code resolves nft from the trusted system directories
	// (audit R2); the fake binary is injected through the test hook.
	guard.NftBinForTest = nft
	t.Cleanup(func() { guard.NftBinForTest = "" })

	firewall, err := guard.NewNftables(1000, nil)
	if err != nil {
		t.Fatalf("NewNftables() error = %v", err)
	}
	ctx := testContext()
	if err := firewall.Arm(ctx, nil); err != nil {
		t.Fatalf("first Arm() error = %v", err)
	}
	// A repeated Arm must replace, not fail with "File exists".
	if err := firewall.Arm(ctx, nil); err != nil {
		t.Fatalf("second Arm() error = %v", err)
	}
	if err := firewall.Disarm(ctx); err != nil {
		t.Fatalf("first Disarm() error = %v", err)
	}
	// Disarming an already removed table must succeed.
	if err := firewall.Disarm(ctx); err != nil {
		t.Fatalf("second Disarm() error = %v", err)
	}
	// Crash recovery: a stale table left behind is cleaned on the next Arm.
	if err := os.WriteFile(state, []byte("stale"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := firewall.CleanupStale(ctx); err != nil {
		t.Fatalf("CleanupStale() error = %v", err)
	}
	if _, err := os.Stat(state); !os.IsNotExist(err) {
		t.Fatal("CleanupStale() left the stale table behind")
	}
}

// invocations counts how many times the fake nft ran.
func invocations(t *testing.T, path string) int {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return 0
		}
		t.Fatal(err)
	}
	return len(strings.Split(strings.TrimRight(string(data), "\n"), "\n"))
}

// TestArmReplacesTableInOneTransaction locks the atomic replace: a repeated
// Arm must delete and reinstall the table with a single nft invocation, so
// no packet can slip through between two separate calls.
func TestArmReplacesTableInOneTransaction(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("nftables is Linux-only")
	}
	dir := t.TempDir()
	state := dir + "/table.state"
	lastInput := dir + "/last.input"
	countFile := dir + "/invocations"
	script := `#!/bin/sh
input=$(cat)
echo "$input" > "$SORA_FAKE_LAST_INPUT"
echo x >> "$SORA_FAKE_INVOCATIONS"
case "$input" in
*"delete table inet sora"*)
	if [ -f "$SORA_FAKE_STATE" ]; then
		rm -f "$SORA_FAKE_STATE"
	else
		echo "Error: Could not process rule: No such file or directory" >&2
		exit 1
	fi
	;;
esac
case "$input" in
*"table inet sora {"*)
	touch "$SORA_FAKE_STATE"
	exit 0
	;;
esac
exit 0
`
	nft := dir + "/nft"
	if err := os.WriteFile(nft, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("SORA_FAKE_STATE", state)
	t.Setenv("SORA_FAKE_LAST_INPUT", lastInput)
	t.Setenv("SORA_FAKE_INVOCATIONS", countFile)
	guard.NftBinForTest = nft
	t.Cleanup(func() { guard.NftBinForTest = "" })

	firewall, err := guard.NewNftables(1000, nil)
	if err != nil {
		t.Fatalf("NewNftables() error = %v", err)
	}
	ctx := testContext()
	// First install: the table is missing, so the combined batch aborts
	// and Arm retries with the table alone — two invocations, ending
	// armed.
	if err := firewall.Arm(ctx, nil); err != nil {
		t.Fatalf("first Arm() error = %v", err)
	}
	if got := invocations(t, countFile); got != 2 {
		t.Fatalf("first Arm() used %d nft invocations, want 2 (aborted batch + retry)", got)
	}
	before := invocations(t, countFile)
	// Repeated Arm: exactly one nft invocation carrying both the delete
	// and the new table.
	if err := firewall.Arm(ctx, nil); err != nil {
		t.Fatalf("second Arm() error = %v", err)
	}
	if got := invocations(t, countFile) - before; got != 1 {
		t.Fatalf("repeated Arm() used %d nft invocations, want 1 atomic batch", got)
	}
	input, err := os.ReadFile(lastInput)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(input), "delete table inet sora") ||
		!strings.Contains(string(input), "table inet sora {") {
		t.Fatalf("the atomic Arm batch does not delete and reinstall the table:\n%s", input)
	}
	if _, err := os.Stat(state); err != nil {
		t.Fatal("the atomic Arm batch left no table behind")
	}
}

// TestNftReplaceRendersDeleteThenTable checks the batch payload order: the
// delete must precede the new table so the kernel replaces rather than
// collides.
func TestNftReplaceRendersDeleteThenTable(t *testing.T) {
	batch := guard.NftReplace(999, []string{"192.168.0.0/16"})
	del := strings.Index(batch, "delete table inet sora")
	add := strings.Index(batch, "table inet sora {")
	if del < 0 || add < 0 || del > add {
		t.Fatalf("NftReplace() does not render delete-then-add:\n%s", batch)
	}
	if !strings.Contains(batch, "meta skuid 999 accept") {
		t.Fatalf("NftReplace() lost the engine exception:\n%s", batch)
	}
}
