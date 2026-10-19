//go:build linux

package guard_test

import (
	"context"
	"os"
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/guard"
)

// TestNftablesArmedProbesTheKernel is the Linux half of the honest-status
// promise: a fresh process (as after a crash) reports the table that is
// actually installed instead of its own empty memory.
func TestNftablesArmedProbesTheKernel(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("nftables is Linux-only")
	}
	dir := t.TempDir()
	state := dir + "/table.state"
	script := `#!/bin/sh
# Fake nft: "list" answers from the state file (kernel truth); stdin
# payloads install or delete the table like the batch-semantics fake.
if [ "$1" = "list" ]; then
	if [ -f "$SORA_FAKE_STATE" ]; then exit 0; else exit 1; fi
fi
input=$(cat)
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
	guard.NftBinForTest = nft
	t.Cleanup(func() { guard.NftBinForTest = "" })

	ctx := context.Background()
	newFirewall := func(t *testing.T) *guard.Nftables {
		t.Helper()
		firewall, err := guard.NewNftables(1000, nil)
		if err != nil {
			t.Fatalf("NewNftables() error = %v", err)
		}
		return firewall
	}

	// A stale table from a crashed core: the new process never armed it,
	// but Armed must still report the block.
	if err := os.WriteFile(state, []byte("stale"), 0o644); err != nil {
		t.Fatal(err)
	}
	if armed, err := newFirewall(t).Armed(ctx); err != nil || !armed {
		t.Errorf("Armed() = %v, %v with a stale table in the kernel", armed, err)
	}
	// No table, no block.
	if err := os.Remove(state); err != nil {
		t.Fatal(err)
	}
	if armed, err := newFirewall(t).Armed(ctx); err != nil || armed {
		t.Errorf("Armed() = %v, %v with no table installed", armed, err)
	}
	// The in-process fast path still works after a real Arm.
	firewall := newFirewall(t)
	if err := firewall.Arm(ctx, nil); err != nil {
		t.Fatalf("Arm() error = %v", err)
	}
	if armed, err := firewall.Armed(ctx); err != nil || !armed {
		t.Errorf("Armed() = %v, %v after Arm", armed, err)
	}
	if err := firewall.Disarm(ctx); err != nil {
		t.Fatalf("Disarm() error = %v", err)
	}
	if armed, err := firewall.Armed(ctx); err != nil || armed {
		t.Errorf("Armed() = %v, %v after Disarm", armed, err)
	}
}

// TestIngressArmedProbesTheKernelAfterACrash: the ingress table survives a
// crash like the kill-switch table, and a fresh decorator must report it.
func TestIngressArmedProbesTheKernelAfterACrash(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("nftables is Linux-only")
	}
	dir := t.TempDir()
	script := `#!/bin/sh
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

	ctx := context.Background()
	inner, err := guard.NewNftables(1000, nil)
	if err != nil {
		t.Fatalf("NewNftables() error = %v", err)
	}
	decorated := guard.WithIngress(inner, guard.DefaultIngressConfig())
	if err := decorated.Arm(ctx, nil); err != nil {
		t.Fatalf("Arm() error = %v", err)
	}

	// The crash: a brand-new decorator over a fresh Nftables.
	inner2, err := guard.NewNftables(1000, nil)
	if err != nil {
		t.Fatalf("NewNftables() error = %v", err)
	}
	afterCrash := guard.WithIngress(inner2, guard.DefaultIngressConfig())
	if armed, err := afterCrash.IngressArmed(ctx); err != nil || !armed {
		t.Errorf("IngressArmed() = %v, %v with the stale ingress table in the kernel", armed, err)
	}
	if armed, err := inner2.Armed(ctx); err != nil || !armed {
		t.Errorf("inner Armed() = %v, %v with the stale kill-switch table in the kernel", armed, err)
	}

	if err := decorated.Disarm(ctx); err != nil {
		t.Fatalf("Disarm() error = %v", err)
	}
	if armed, err := afterCrash.IngressArmed(ctx); err != nil || armed {
		t.Errorf("IngressArmed() = %v, %v after the tables were removed", armed, err)
	}
}
