//go:build linux

package bypass

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// The Linux capability probe: every fact is measured against the live
// host — the nft binary in the trusted system directories, a dry-run
// ruleset check (which validates against the kernel's nf_tables
// without installing anything), the nfnetlink_queue module state, the
// process's effective capabilities, and the queue numbers already
// bound in /proc/net/nfnetlink_queue. Nothing is inferred from the OS
// name: a kernel without the module probes NFQueue=false and the gate
// refuses honestly.

// capNetAdmin is CAP_NET_ADMIN in the Linux capability numbering.
const capNetAdmin = 12

func defaultProbeCapabilities(ctx context.Context) Capabilities {
	caps := Capabilities{Platform: "linux-nfqueue", ProbedAt: time.Now()}

	nft := resolveNFT()
	if nft != "" {
		if out, err := exec.CommandContext(ctx, nft, "--version").Output(); err == nil {
			caps.NFTVersion = strings.TrimSpace(string(out))
		}
		// Dry-run checks: -c validates the ruleset against the kernel
		// and installs nothing. The plain table checks nf_tables; the
		// queue rule additionally proves the nfqueue target exists,
		// which is the closest userspace can get to "the module will
		// accept packets" without binding a queue.
		if err := nftCheck(ctx, nft, "add table inet sora_probe\n"); err == nil {
			caps.NFTUsable = true
		}
		queueRuleset := "add table inet sora_probe\n" +
			"add chain inet sora_probe output { type filter hook output priority -150; policy accept; }\n" +
			"add rule inet sora_probe output udp dport 443 queue num " + strconv.Itoa(queueBase) + "\n"
		if err := nftCheck(ctx, nft, queueRuleset); err == nil {
			caps.NFQueue = true
		}
	}
	// The module list is deliberately NOT consulted for the verdict:
	// a loaded nfnetlink_queue whose queue rule does not validate is
	// not usable, and a built-in module may not appear in
	// /proc/modules at all. The dry-run check above is the kernel's
	// own answer, and it is the one the gate trusts.

	if os.Geteuid() == 0 {
		caps.Privileged, caps.PrivilegeVia = true, "root"
	} else if hasCapNetAdmin() {
		caps.Privileged, caps.PrivilegeVia = true, "CAP_NET_ADMIN"
	} else if helper := pkexecPath(); helper != "" {
		// The core normally runs as the privileged service; an
		// unprivileged core with pkexec present can still reach the
		// helper path the OS-integration ships. Recorded as data so
		// the gate's answer names how privilege would be obtained.
		caps.Privileged, caps.PrivilegeVia = true, "polkit helper ("+helper+")"
	}

	caps.QueuesBusy = busyQueues()
	return caps
}

// resolveNFT finds nft in the trusted system directories (never PATH:
// the probe's verdict feeds privileged work).
func resolveNFT() string {
	for _, dir := range nfqwsBinDirs {
		p := filepath.Join(dir, "nft")
		if fi, err := os.Stat(p); err == nil && !fi.IsDir() && fi.Mode()&0o111 != 0 {
			return p
		}
	}
	return ""
}

func nftCheck(ctx context.Context, nft, ruleset string) error {
	cmd := exec.CommandContext(ctx, nft, "-c", "-f", "-") //nolint:gosec // nft is the absolute path from the trusted system directories; the ruleset is a fixed probe string
	cmd.Stdin = strings.NewReader(ruleset)
	return cmd.Run()
}

// hasCapNetAdmin reads the effective capability mask from
// /proc/self/status.
func hasCapNetAdmin() bool {
	raw, err := os.ReadFile("/proc/self/status")
	if err != nil {
		return false
	}
	for _, line := range strings.Split(string(raw), "\n") {
		if !strings.HasPrefix(line, "CapEff:") {
			continue
		}
		mask, err := strconv.ParseUint(strings.TrimSpace(strings.TrimPrefix(line, "CapEff:")), 16, 64)
		if err != nil {
			return false
		}
		return mask&(1<<capNetAdmin) != 0
	}
	return false
}

// pkexecPath finds the polkit helper in the trusted directories.
func pkexecPath() string {
	for _, dir := range []string{"/usr/bin", "/bin"} {
		p := filepath.Join(dir, "pkexec")
		if fi, err := os.Stat(p); err == nil && !fi.IsDir() && fi.Mode()&0o111 != 0 {
			return p
		}
	}
	return ""
}

// busyQueues parses /proc/net/nfnetlink_queue: one line per bound
// queue, the queue number first. A missing file means no queue is
// bound (the module creates it on load) — that is "none busy", not an
// error: the NFQueue verdict itself comes from the dry-run check.
func busyQueues() []int {
	raw, err := os.ReadFile("/proc/net/nfnetlink_queue")
	if err != nil {
		return nil
	}
	var out []int
	for _, line := range strings.Split(string(raw), "\n") {
		fields := strings.Fields(line)
		if len(fields) == 0 {
			continue
		}
		if n, err := strconv.Atoi(fields[0]); err == nil {
			out = append(out, n)
		}
	}
	return out
}
