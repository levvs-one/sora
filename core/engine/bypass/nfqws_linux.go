//go:build linux

package bypass

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// The Linux interceptor: the sora_nfqws nftables table, applied with
// the same discipline as the kill switch in core/guard — the nft
// helper resolved from the trusted system directories (never PATH: it
// runs with the core's privileges), rulesets fed on stdin, and the
// whole table replaced in one transaction so no intermediate state is
// ever live.

// nfqwsBinDirs mirrors guard.systemBinDirs: the trusted locations for
// privileged helper binaries.
var nfqwsBinDirs = []string{"/usr/sbin", "/sbin", "/usr/bin", "/bin"}

// NftBinForTest overrides the nft binary path. It exists so tests can
// plant a fake nft; production code must leave it empty so the binary
// always comes from the trusted system directories (same convention
// as guard.NftBinForTest).
var NftBinForTest string

// nftInterceptor steers output traffic into NFQUEUEs via nftables.
type nftInterceptor struct {
	command string
}

func newInterceptor() (interceptor, error) {
	command := NftBinForTest
	if command == "" {
		for _, dir := range nfqwsBinDirs {
			p := filepath.Join(dir, "nft")
			if fi, err := os.Stat(p); err == nil && !fi.IsDir() && fi.Mode()&0o111 != 0 {
				command = p
				break
			}
		}
	}
	if command == "" {
		return nil, fmt.Errorf("bypass: nft not found in the system directories (/usr/sbin, /sbin, /usr/bin, /bin): nfqws interception needs nftables")
	}
	return &nftInterceptor{command: command}, nil
}

// Sync replaces the sora_nfqws table with exactly the given queue
// specs; an empty list removes the table.
func (n *nftInterceptor) Sync(ctx context.Context, specs []QueueSpec) error {
	if len(specs) == 0 {
		return n.Sweep(ctx)
	}
	body, err := nfqwsRuleset(specs)
	if err != nil {
		return err
	}
	// Atomic replace first: delete + recreate in one batch, so the
	// kernel never holds a half-updated table. The batch aborts when
	// the table does not exist yet; fall back to a plain install.
	if err := n.apply(ctx, "delete table inet "+nftTable+"\n"+body); err != nil {
		if cerr := n.apply(ctx, body); cerr != nil {
			return fmt.Errorf("bypass: nft rejected the nfqws ruleset: %w", cerr)
		}
	}
	return nil
}

// Sweep removes the sora_nfqws table; a missing table is success (the
// same tolerance the guard's CleanupStale relies on).
func (n *nftInterceptor) Sweep(ctx context.Context) error {
	err := n.apply(ctx, "delete table inet "+nftTable+"\n")
	if err != nil && isMissingTable(err) {
		return nil
	}
	return err
}

// nfqwsRuleset renders the full table: one output chain at mangle
// priority (desync runs before the filter-priority kill switch, the
// order zapret itself uses), loopback exempt (the engines and their
// control channels live there), then one queue rule per spec from the
// shared QueueSpec renderer.
func nfqwsRuleset(specs []QueueSpec) (string, error) {
	var b strings.Builder
	b.WriteString("add table inet " + nftTable + "\n")
	b.WriteString("add chain inet " + nftTable + " output { type filter hook output priority -150; policy accept; }\n")
	b.WriteString("add rule inet " + nftTable + " output oif \"lo\" accept\n")
	for _, spec := range specs {
		rules, err := spec.AddRules()
		if err != nil {
			return "", err
		}
		for _, rule := range rules {
			b.WriteString(rule)
			b.WriteByte('\n')
		}
	}
	return b.String(), nil
}

func (n *nftInterceptor) apply(ctx context.Context, ruleset string) error {
	process := exec.CommandContext(ctx, n.command, "-f", "-") //nolint:gosec // n.command is the absolute nft path resolved from the trusted system directories; the ruleset arrives on stdin
	process.Stdin = strings.NewReader(ruleset)
	out, err := process.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%w: %s", err, strings.TrimSpace(string(out)))
	}
	if msg := strings.TrimSpace(string(out)); msg != "" {
		return fmt.Errorf("nft: %s", msg)
	}
	return nil
}

func isMissingTable(err error) bool {
	return err != nil && strings.Contains(err.Error(), "No such file or directory")
}
