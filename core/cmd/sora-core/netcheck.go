package main

import (
	"context"
	"fmt"
	"net"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/probe"
)

// Censorship-event operator checks (T008/T010): the production
// triggers for probe.ProbeQUIC and diagnostics.DetectDNSIntercept.
// Both probes existed as tested primitives with no caller; like the
// T055 series probe, their production wiring today is the core
// binary's operator mode — an in-app trigger still needs proto
// fields this repo cannot regenerate (see CENSOR-SURV.md).
//
// The QUIC check runs against the persistent BanTracker file in the
// data dir: bans recorded by earlier runs (or earlier probes in this
// one) steer this probe's source-port rotation, and bans this probe
// records are saved back, so a core restart inside the 420 s window
// does not silently forget them. A corrupt tracker file is reported
// as a reset in the output and the check proceeds with an empty
// tracker — visible, never silent.

// banTrackerFileName is the BanTracker snapshot inside the data dir.
const banTrackerFileName = "censor-ban-tracker.json"

// quicProbeFn is the probe the operator mode runs; tests substitute
// it because sandboxed CI kernels may refuse loopback UDP replies
// outright (the probe package's own tests inject dials for the same
// reason). Production always uses probe.ProbeQUICWithTracker.
var quicProbeFn = probe.ProbeQUICWithTracker

// runQUICProbe probes host[:port] (default 443) for QUIC censorship.
func runQUICProbe(ctx context.Context, dataDir, target string) ([]string, error) {
	host, port, err := quicTarget(target)
	if err != nil {
		return nil, err
	}
	path := filepath.Join(dataDir, banTrackerFileName)
	tracker, restored, lerr := probe.LoadBanTracker(path)
	var resetNote string
	if lerr != nil {
		// Honest reset: the file existed but could not be trusted.
		tracker = probe.NewBanTracker()
		restored = 0
		resetNote = "ban tracker state reset: " + lerr.Error()
	}
	res, err := quicProbeFn(ctx, host, port, tracker)
	if err != nil {
		return nil, err
	}
	if serr := probe.SaveBanTracker(path, tracker); serr != nil {
		return nil, serr
	}
	lines := []string{}
	if resetNote != "" {
		lines = append(lines, resetNote)
	}
	lines = append(lines,
		fmt.Sprintf("quic probe: %s:%d verdict=%s rtt=%s local_port=%d (ban tracker: %d live bans restored, %d now recorded)",
			host, port, quicVerdictName(res.Verdict), res.RTT.Round(1_000_000), res.LocalPort,
			restored, len(tracker.Snapshot())),
		"advice: "+res.Advice(),
	)
	if res.Verdict == probe.VerdictBlocked {
		// The reaction is part of the chain, not a hope: the blocked
		// 4-tuple is in the tracker (ProbeQUICWithTracker recorded
		// it), the next dial rotates the source port, and the tracker
		// file just saved carries the ban across restarts.
		lines = append(lines, "reaction: the blocked 4-tuple was recorded in the ban tracker; the next QUIC dial rotates the source port instead of renewing the 420s ban")
	}
	return lines, nil
}

// quicTarget parses "host" or "host:port" (default port 443).
func quicTarget(target string) (string, int, error) {
	target = strings.TrimSpace(target)
	if target == "" {
		return "", 0, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
			"quic probe: the target is empty")
	}
	if host, portStr, err := net.SplitHostPort(target); err == nil {
		port, perr := strconv.Atoi(portStr)
		if perr != nil || port <= 0 || port > 65535 {
			return "", 0, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
				"quic probe: %q has no valid port", target)
		}
		return host, port, nil
	}
	return target, 443, nil
}

func quicVerdictName(v probe.Verdict) string {
	switch v {
	case probe.VerdictOpen:
		return "open"
	case probe.VerdictBlocked:
		return "blocked"
	case probe.VerdictFiltered:
		return "filtered"
	case probe.VerdictDown:
		return "down"
	default:
		return "unknown"
	}
}

// runDNSInterceptCheck probes the documented DNAT-intercept target
// (8.8.8.8, canary youtube.com) for DNS impersonation/injection.
func runDNSInterceptCheck(ctx context.Context) []string {
	rep := diagnostics.DetectDNSIntercept(ctx, diagnostics.InterceptInput{})
	lines := []string{fmt.Sprintf("dns intercept check: verdict=%s", rep.Verdict)}
	for _, ev := range rep.Evidence {
		lines = append(lines, "evidence: "+ev)
	}
	return lines
}
