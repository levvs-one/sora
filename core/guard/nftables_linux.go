//go:build linux

package guard

import (
	"context"
	"net/netip"
	"os/exec"
	"strings"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/session"
)

// Nftables manages a Linux output-hook table, removing it when the session
// ends.
type Nftables struct {
	mu      sync.Mutex
	uid     int
	bypass  []string
	command string
	armed   bool
	blocked []netip.Prefix
	policy  session.Settings
}

// NewNftables permits engine traffic owned by uid and the supplied bypass
// networks. Empty bypass uses private ranges to keep local resources reachable.
func NewNftables(uid int, bypass []string) (*Nftables, error) {
	if uid < 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: the engine has no user id")
	}
	if len(bypass) == 0 {
		bypass = DefaultBypassNetworks()
	}
	return &Nftables{uid: uid, bypass: bypass, command: "nft"}, nil
}

// SetBlockedNetworks retains session destinations across engine crashes.
func (n *Nftables) SetBlockedNetworks(networks []netip.Prefix) {
	n.mu.Lock()
	defer n.mu.Unlock()
	n.blocked = append([]netip.Prefix(nil), networks...)
}

// Arm installs or replaces the table, making repeated calls idempotent.
func (n *Nftables) Arm(ctx context.Context, _ []uint16) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	rules := NftRuleset(n.uid, n.bypass, n.blocked...)
	if n.policy.StrictKillSwitch {
		rules = StrictNftRuleset(n.uid, n.policy, n.blocked...)
	}
	// Add creates the table if missing; flush and rebuild happen in one transaction.
	rules = "add table inet sora\nflush table inet sora\n" + rules
	if err := n.apply(ctx, rules); err != nil {
		return err
	}
	n.armed = true
	return nil
}

// Disarm removes the table and succeeds if already removed.
func (n *Nftables) Disarm(ctx context.Context) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	if err := n.apply(ctx, "add table inet sora\n"+NftRemove()); err != nil {
		return err
	}
	n.armed = false
	return nil
}

// SetPolicy selects the strict exemptions for the next atomic replacement.
func (n *Nftables) SetPolicy(s session.Settings) { n.mu.Lock(); defer n.mu.Unlock(); n.policy = s }

// Armed probes the kernel table, including rules left by an earlier process.
func (n *Nftables) Armed(ctx context.Context) (bool, error) {
	n.mu.Lock()
	defer n.mu.Unlock()
	cmd := exec.CommandContext(ctx, n.command, "list", "table", "inet", nftTable) //nolint:gosec // fixed nft command
	output, err := cmd.CombinedOutput()
	if err != nil && strings.Contains(string(output), "No such file or directory") {
		return false, nil
	}
	return err == nil, err
}

// Name identifies the implementation in a diagnostics line.
func (n *Nftables) Name() string { return "nftables" }

// apply sends nft rules on stdin to avoid command-line length limits and
// exposing rules in process arguments.
func (n *Nftables) apply(ctx context.Context, ruleset string) error {
	process := exec.CommandContext(ctx, n.command, "-f", "-") //nolint:gosec // n.command is the nft binary found at construction; the ruleset arrives on stdin
	process.Stdin = strings.NewReader(ruleset)
	output, err := process.CombinedOutput()
	if err != nil {
		// nft output names table, chain, or syntax failures and
		// contains no secrets.
		return errs.Newf(errs.CodePermissionDenied, errs.KeyGuardFirewallFail,
			"guard: nft refused the ruleset: %s", FirstLine(string(output)))
	}
	return nil
}

// PlatformFirewall returns the Linux nftables kill switch.
func PlatformFirewall(opts FirewallOptions) (Firewall, error) {
	return NewNftables(opts.EngineUID, opts.Bypass)
}
