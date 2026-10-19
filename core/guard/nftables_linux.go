//go:build linux

package guard

import (
	"context"
	"net/netip"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
)

// Nftables manages a Linux output-hook table, removing it when the session
// ends. The engine is matched by its UID; when the core itself runs as root
// the exception would degrade to "skuid 0 accept" and silently exempt every
// root process (including DNS) from the kill switch, so Arm refuses in that
// case instead of arming a switch that leaks (SORA-H4). Run the core as a
// dedicated unprivileged user — the sora systemd service does.
type Nftables struct {
	mu      sync.Mutex
	uid     int
	bypass  []string
	command string
	armed   bool
	blocked []netip.Prefix
}

// systemBinDirs are the trusted locations for the nft helper binary. A
// privileged daemon must not resolve helpers through PATH: a PATH-planted
// binary would otherwise execute with the core's (possibly root) privileges
// (audit R2 follow-up: exec.LookPath consults PATH, so it cannot provide
// this guarantee on its own).
var systemBinDirs = []string{"/usr/sbin", "/sbin", "/usr/bin", "/bin"}

// resolveSystemBin returns the absolute path of a privileged helper binary
// from the trusted system directories, failing closed when absent.
func resolveSystemBin(name string) (string, error) {
	for _, dir := range systemBinDirs {
		p := filepath.Join(dir, name)
		if fi, err := os.Stat(p); err == nil && !fi.IsDir() && fi.Mode()&0o111 != 0 {
			return p, nil
		}
	}
	return "", errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
		"guard: %s not found in the system directories (/usr/sbin, /sbin, /usr/bin, /bin)", name)
}

// NftBinForTest overrides the nft binary path used by NewNftables. It
// exists so tests can plant a fake nft; production code must leave it empty
// so the binary always comes from the trusted system directories.
var NftBinForTest string

// NewNftables permits engine traffic owned by uid and the supplied bypass
// networks. Empty bypass uses private ranges to keep local resources reachable.
// The nft binary is resolved to an absolute path at construction from the
// trusted system directories: a PATH-planted "nft" must never run with the
// core's (possibly root) privileges (audit R2). A missing nft fails closed
// here instead of later at Arm.
func NewNftables(uid int, bypass []string) (*Nftables, error) {
	if uid < 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: the engine has no user id")
	}
	if len(bypass) == 0 {
		bypass = DefaultBypassNetworks()
	}
	nftBin := NftBinForTest
	if nftBin == "" {
		var err error
		nftBin, err = resolveSystemBin("nft")
		if err != nil {
			return nil, err
		}
	}
	return &Nftables{uid: uid, bypass: bypass, command: nftBin}, nil
}

// SetBlockedNetworks retains session destinations across engine crashes.
func (n *Nftables) SetBlockedNetworks(networks []netip.Prefix) {
	n.mu.Lock()
	defer n.mu.Unlock()
	n.blocked = append([]netip.Prefix(nil), networks...)
}

// Arm installs or replaces the table, making repeated calls idempotent.
// It refuses when the core runs as root (uid 0): the engine exception would
// become "meta skuid 0 accept" and silently let every root process bypass
// the kill switch. Failing closed here is deliberate — see SORA-H4.
func (n *Nftables) Arm(ctx context.Context, _ []uint16) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	if n.uid == 0 {
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
			"guard: refusing to arm the kill switch as root: the engine exception would match every root process; run the core as an unprivileged user")
	}
	// Remove any previous table first (stale after a crash, or a repeated
	// Arm): installing over an existing table fails with "File exists"
	// (SORA-M4).
	if err := n.deleteTable(ctx); err != nil {
		return err
	}
	if err := n.apply(ctx, NftRuleset(n.uid, n.bypass, n.blocked...)); err != nil {
		return err
	}
	n.armed = true
	return nil
}

// Disarm removes the table and succeeds if already removed (SORA-M5).
func (n *Nftables) Disarm(ctx context.Context) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	if err := n.deleteTable(ctx); err != nil {
		return err
	}
	n.armed = false
	return nil
}

// CleanupStale removes a table left behind by a crashed core. Call it once
// at startup while holding the instance lock: with no live session owning
// the table, leftover rules would keep blocking traffic (SORA-M4).
func (n *Nftables) CleanupStale(ctx context.Context) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	return n.deleteTable(ctx)
}

// deleteTable removes the owned table, treating a missing table as success
// so repeated restores and crash recovery are safe.
func (n *Nftables) deleteTable(ctx context.Context) error {
	if err := n.apply(ctx, NftRemove()); err != nil {
		if isMissingTable(err) {
			return nil
		}
		return err
	}
	return nil
}

// isMissingTable reports nft's "the table does not exist" failure, which is
// not an error for idempotent cleanup.
func isMissingTable(err error) bool {
	return err != nil && strings.Contains(err.Error(), "No such file or directory")
}

// Armed reports whether this process installed the table.
func (n *Nftables) Armed(context.Context) (bool, error) {
	n.mu.Lock()
	defer n.mu.Unlock()
	return n.armed, nil
}

// Name identifies the implementation in a diagnostics line.
func (n *Nftables) Name() string { return "nftables" }

// apply sends nft rules on stdin to avoid command-line length limits and
// exposing rules in process arguments.
func (n *Nftables) apply(ctx context.Context, ruleset string) error {
	process := exec.CommandContext(ctx, n.command, "-f", "-") //nolint:gosec // n.command is the absolute nft path resolved at construction; the ruleset arrives on stdin
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
