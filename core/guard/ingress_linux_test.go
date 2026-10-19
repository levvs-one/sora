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
# "sora_ingress" commands. A "list" invocation is the kernel-truth probe
# used by Armed()/IngressArmed().
if [ "$1" = "list" ]; then
	if [ -f "$SORA_FAKE_DIR/$4.state" ]; then exit 0; else exit 1; fi
fi
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
	if armed, err := decorated.IngressArmed(ctx); err != nil || !armed {
		t.Fatalf("IngressArmed() = %v, %v after Arm", armed, err)
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
	if armed, err := decorated.IngressArmed(ctx); err != nil || armed {
		t.Errorf("IngressArmed() = %v, %v after Disarm", armed, err)
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
	if err := os.WriteFile(nft, []byte("#!/bin/sh\nif [ \"$1\" = \"list\" ]; then exit 1; fi\nexit 0\n"), 0o755); err != nil {
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
	if armed, err := decorated.IngressArmed(testContext()); armed {
		t.Errorf("IngressArmed() = true after the kill switch refused (err = %v)", err)
	}
}

// fakeNftBatch is an nft stand-in with batch semantics: a batch that deletes
// a missing table aborts like the real nft, otherwise the delete and the
// install in one invocation commit atomically. Every stdin payload is
// appended to calls.log for assertions.
const fakeNftBatch = `#!/bin/sh
# A "list" invocation is the kernel-truth probe used by
# Armed()/IngressArmed().
if [ "$1" = "list" ]; then
	if [ -f "$SORA_FAKE_DIR/$4.state" ]; then exit 0; else exit 1; fi
fi
input=$(cat)
printf '%s\n====\n' "$input" >> "$SORA_FAKE_DIR/calls.log"
has_del=0
has_table=0
case "$input" in *"delete table inet sora_ingress"*) has_del=1;; esac
case "$input" in *"table inet sora_ingress {"*) has_table=1;; esac
if [ "$has_del" = 1 ]; then
	if [ ! -f "$SORA_FAKE_DIR/sora_ingress.state" ]; then
		echo "Error: Could not process rule: No such file or directory" >&2
		exit 1
	fi
	rm -f "$SORA_FAKE_DIR/sora_ingress.state"
fi
if [ "$has_table" = 1 ]; then
	echo "$input" > "$SORA_FAKE_DIR/sora_ingress.state"
fi
case "$input" in *"table inet sora {"*)
	case "$input" in *"sora_ingress"*) ;; *) echo "$input" > "$SORA_FAKE_DIR/sora.state";; esac;;
esac
exit 0
`

func writeFakeNftBatch(t *testing.T, dir string) {
	t.Helper()
	nft := dir + "/nft"
	if err := os.WriteFile(nft, []byte(fakeNftBatch), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("SORA_FAKE_DIR", dir)
	guard.NftBinForTest = nft
	t.Cleanup(func() { guard.NftBinForTest = "" })
}

func readNftCalls(t *testing.T, dir string) []string {
	t.Helper()
	raw, err := os.ReadFile(dir + "/calls.log")
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		t.Fatal(err)
	}
	var calls []string
	for _, part := range strings.Split(string(raw), "\n====\n") {
		if part != "" {
			calls = append(calls, part)
		}
	}
	return calls
}

// TestIngressArmReplacesAtomically pins the fail-open window shut: the
// first arm falls back to a plain install when the table does not exist
// yet, and every re-arm deletes and reinstalls the ingress table in a
// single nft invocation.
func TestIngressArmReplacesAtomically(t *testing.T) {
	dir := t.TempDir()
	writeFakeNftBatch(t, dir)

	inner, err := guard.NewNftables(1000, []string{"192.168.0.0/16"})
	if err != nil {
		t.Fatalf("NewNftables() error = %v", err)
	}
	decorated := guard.WithIngress(inner, guard.DefaultIngressConfig())
	ctx := testContext()

	if err := decorated.Arm(ctx, nil); err != nil {
		t.Fatalf("Arm() error = %v", err)
	}
	if _, err := os.Stat(dir + "/sora_ingress.state"); err != nil {
		t.Fatalf("the ingress table was not installed: %v", err)
	}

	if err := os.Remove(dir + "/calls.log"); err != nil {
		t.Fatal(err)
	}
	if err := decorated.Arm(ctx, nil); err != nil {
		t.Fatalf("second Arm() error = %v", err)
	}
	calls := readNftCalls(t, dir)
	// One call for the kill-switch replace, one for the ingress replace.
	if len(calls) != 2 {
		t.Fatalf("re-arm issued %d nft invocations, want 2 (kill switch + ingress): %q", len(calls), calls)
	}
	ingressCall := calls[1]
	if !strings.Contains(ingressCall, "delete table inet sora_ingress") ||
		!strings.Contains(ingressCall, "table inet sora_ingress {") {
		t.Errorf("the ingress re-arm was not a single delete-then-install batch:\n%s", ingressCall)
	}

	if err := decorated.Disarm(ctx); err != nil {
		t.Fatalf("Disarm() error = %v", err)
	}
	if _, err := os.Stat(dir + "/sora_ingress.state"); !os.IsNotExist(err) {
		t.Error("the ingress table survived Disarm")
	}
}

// TestIngressReArmRestoresExternallyRemovedTable covers the self-healing
// contract: a repeated Arm reinstalls the ingress rules even when something
// outside the decorator removed the table while armed.
func TestIngressReArmRestoresExternallyRemovedTable(t *testing.T) {
	dir := t.TempDir()
	writeFakeNftBatch(t, dir)

	inner, err := guard.NewNftables(1000, nil)
	if err != nil {
		t.Fatalf("NewNftables() error = %v", err)
	}
	decorated := guard.WithIngress(inner, guard.DefaultIngressConfig())
	ctx := testContext()

	if err := decorated.Arm(ctx, nil); err != nil {
		t.Fatalf("Arm() error = %v", err)
	}
	// Simulate an external flush while the session is up.
	if err := os.Remove(dir + "/sora_ingress.state"); err != nil {
		t.Fatal(err)
	}
	if err := decorated.Arm(ctx, nil); err != nil {
		t.Fatalf("re-Arm() error = %v", err)
	}
	installed, err := os.ReadFile(dir + "/sora_ingress.state")
	if err != nil {
		t.Fatalf("re-Arm did not restore the ingress table: %v", err)
	}
	if !strings.Contains(string(installed), "counter drop") {
		t.Errorf("the restored table is not the ingress ruleset:\n%s", installed)
	}
	if err := decorated.Disarm(ctx); err != nil {
		t.Fatalf("Disarm() error = %v", err)
	}
}
