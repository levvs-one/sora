//go:build linux

package bypass

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestNFQWSRulesetRendersTableChainAndRules(t *testing.T) {
	got, err := nfqwsRuleset([]QueueSpec{
		{Queue: 200, TCPPorts: "80,443", UDPPorts: "443"},
		{Queue: 201, UDPPorts: "443"},
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		"add table inet sora_nfqws\n",
		"add chain inet sora_nfqws output { type filter hook output priority -150; policy accept; }\n",
		"add rule inet sora_nfqws output oif \"lo\" accept\n",
		"add rule inet sora_nfqws output tcp dport {80, 443} queue num 200\n",
		"add rule inet sora_nfqws output udp dport {443} queue num 200\n",
		"add rule inet sora_nfqws output udp dport {443} queue num 201\n",
	} {
		if !strings.Contains(got, want) {
			t.Errorf("ruleset missing %q:\n%s", want, got)
		}
	}
}

func TestNFQWSRulesetRejectsEmptySpec(t *testing.T) {
	if _, err := nfqwsRuleset([]QueueSpec{{Queue: 200}}); err == nil {
		t.Fatal("a spec with no ports must not render")
	}
}

// fakeNFT records every ruleset it is fed; failFirst makes the first
// invocation report a missing table, like real nft does when a batch
// starts by deleting a table that does not exist yet.
func fakeNFT(t *testing.T, log string, failFirst bool) string {
	t.Helper()
	body := "#!/bin/sh\ncat >> \"" + log + "\"\n"
	if failFirst {
		body += "if [ ! -f \"" + log + ".seen\" ]; then touch \"" + log + ".seen\"; " +
			"echo 'Error: Could not process rule: No such file or directory' >&2; exit 1; fi\n"
	}
	body += "exit 0\n"
	path := filepath.Join(t.TempDir(), "nft")
	if err := os.WriteFile(path, []byte(body), 0o755); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestNFTInterceptorSyncFallsBackToCreate(t *testing.T) {
	log := filepath.Join(t.TempDir(), "nft.log")
	NftBinForTest = fakeNFT(t, log, true)
	t.Cleanup(func() { NftBinForTest = "" })
	icept, err := newInterceptor()
	if err != nil {
		t.Fatal(err)
	}
	err = icept.Sync(context.Background(), []QueueSpec{{Queue: 200, UDPPorts: "443"}})
	if err != nil {
		t.Fatalf("sync: %v", err)
	}
	data, err := os.ReadFile(log)
	if err != nil {
		t.Fatal(err)
	}
	// Two batches: the atomic replace (delete + create) failed on the
	// delete, then the plain create landed.
	if got := strings.Count(string(data), "add table inet sora_nfqws"); got != 2 {
		t.Fatalf("nft saw %d table creates, want 2 (replace attempt + create fallback):\n%s", got, data)
	}
}

func TestNFTInterceptorSweepToleratesMissingTable(t *testing.T) {
	log := filepath.Join(t.TempDir(), "nft.log")
	// Every invocation reports the missing table.
	path := filepath.Join(t.TempDir(), "nft")
	body := "#!/bin/sh\ncat >> \"" + log + "\"\necho 'Error: Could not process rule: No such file or directory' >&2\nexit 1\n"
	if err := os.WriteFile(path, []byte(body), 0o755); err != nil {
		t.Fatal(err)
	}
	NftBinForTest = path
	t.Cleanup(func() { NftBinForTest = "" })
	icept, err := newInterceptor()
	if err != nil {
		t.Fatal(err)
	}
	if err := icept.Sweep(context.Background()); err != nil {
		t.Fatalf("sweep of a missing table must succeed, got %v", err)
	}
	if err := icept.Sync(context.Background(), nil); err != nil {
		t.Fatalf("an empty sync (clear) must tolerate a missing table, got %v", err)
	}
}
