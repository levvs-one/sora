//go:build linux

package guard_test

import (
	"os"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/guard"
)

// TestIngressFirewallInstallsAndRemovesTheLinuxTable arms the decorator over
// a real Nftables pointed at a fake nft binary, and checks the ingress
// table appears on Arm and disappears on Disarm. The fake keeps one state
// file per table name.
func TestIngressFirewallInstallsAndRemovesTheLinuxTable(t *testing.T) {
	dir := t.TempDir()
	script := `#!/bin/sh
# Fake nft: keeps one state file per table mentioned on stdin. Exact
# command matches: the "sora" patterns must not prefix-match the
# "sora_ingress" commands.
input=$(cat)
table=""
deleting=0
case "$input" in
"delete table inet sora_ingress")
	table=sora_ingress
	deleting=1
	;;
"delete table inet sora")
	table=sora
	deleting=1
	;;
*"table inet sora_ingress {"*)
	table=sora_ingress
	;;
*"table inet sora {"*)
	table=sora
	;;
esac
[ -z "$table" ] && exit 0
state="$SORA_FAKE_DIR/$table.state"
if [ "$deleting" = 1 ]; then
	if [ -f "$state" ]; then
		rm -f "$state"
		exit 0
	fi
	echo "Error: Could not process rule: No such file or directory" >&2
	exit 1
fi
echo "$input" > "$state"
exit 0
`
	nft := dir + "/nft"
	if err := os.WriteFile(nft, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("SORA_FAKE_DIR", dir)
	guard.NftBinForTest = nft
	t.Cleanup(func() { guard.NftBinForTest = "" })

	inner, err := guard.NewNftables(1000, []string{"192.168.0.0/16"})
	if err != nil {
		t.Fatalf("NewNftables() error = %v", err)
	}
	cfg := guard.DefaultIngressConfig()
	cfg.VPNEndpoints = []string{"203.0.113.7:443"}
	decorated := guard.WithIngress(inner, cfg)
	ctx := testContext()

	if err := decorated.Arm(ctx, nil); err != nil {
		t.Fatalf("Arm() error = %v", err)
	}
	if !decorated.IngressArmed() {
		t.Fatal("IngressArmed() = false after Arm")
	}
	for _, table := range []string{"sora", "sora_ingress"} {
		if _, err := os.Stat(dir + "/" + table + ".state"); err != nil {
			t.Fatalf("table %s was not installed: %v", table, err)
		}
	}
	// The installed ingress ruleset must keep established traffic and the
	// VPN endpoint, and end with the drop.
	installed, err := os.ReadFile(dir + "/sora_ingress.state")
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		"hook input",
		"ct state established,related accept",
		"ip saddr 203.0.113.7 accept",
		`iif "lo" accept`,
		"counter drop",
	} {
		if !strings.Contains(string(installed), want) {
			t.Errorf("installed ruleset does not contain %q:\n%s", want, installed)
		}
	}
	// A repeated Arm must replace, not fail.
	if err := decorated.Arm(ctx, nil); err != nil {
		t.Fatalf("second Arm() error = %v", err)
	}
	if err := decorated.Disarm(ctx); err != nil {
		t.Fatalf("Disarm() error = %v", err)
	}
	if decorated.IngressArmed() {
		t.Error("IngressArmed() = true after Disarm")
	}
	for _, table := range []string{"sora", "sora_ingress"} {
		if _, err := os.Stat(dir + "/" + table + ".state"); !os.IsNotExist(err) {
			t.Errorf("table %s survived Disarm", table)
		}
	}
	// Disarming twice must succeed.
	if err := decorated.Disarm(ctx); err != nil {
		t.Fatalf("second Disarm() error = %v", err)
	}
}

// TestIngressFirewallAbortsWhenTheKillSwitchRefuses locks the fail-closed
// ordering on Linux: uid 0 makes Nftables.Arm refuse, so the decorator
// must fail before touching the ingress table.
func TestIngressFirewallAbortsWhenTheKillSwitchRefuses(t *testing.T) {
	dir := t.TempDir()
	nft := dir + "/nft"
	if err := os.WriteFile(nft, []byte("#!/bin/sh\nexit 0\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	guard.NftBinForTest = nft
	t.Cleanup(func() { guard.NftBinForTest = "" })

	inner, err := guard.NewNftables(0, nil)
	if err != nil {
		t.Fatalf("NewNftables(0) error = %v", err)
	}
	decorated := guard.WithIngress(inner, guard.DefaultIngressConfig())
	if err := decorated.Arm(testContext(), nil); err == nil {
		t.Fatal("Arm() succeeded while the kill switch refused uid 0")
	}
	if decorated.IngressArmed() {
		t.Error("IngressArmed() = true after the kill switch refused")
	}
}
