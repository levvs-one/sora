package main

import (
	"context"
	"fmt"
	"net"
	"strconv"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/probe"
)

// Serial-probe diagnostic (T055): the operator-facing trigger for
// probe.RunSeries. Two-stage protocol blocking (detect → analyze →
// disseminate, ~5–15 min) makes a single probe worthless as a liveness
// verdict, so this mode probes one endpoint in a series and prints the
// honest verdict: "alive" only after a clean series covering the full
// confirmation window, "alive for now" for anything shorter, and the
// two-stage signature when a block lands mid-series.
//
// This is the production wiring that exists today. The in-app trigger
// (a button in the client, a series verdict in ProbeResult) still needs
// a proto field this repo cannot regenerate without buf/protoc — see
// the wiring note in core/probe/serial.go.

// runSeriesProbe probes target ("host:port") in a series. minutes <= 0
// uses the default window (the full confirmation window).
func runSeriesProbe(ctx context.Context, target string, useTLS bool, minutes int) (probe.SeriesResult, error) {
	host, portStr, err := net.SplitHostPort(target)
	if err != nil {
		return probe.SeriesResult{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
			"series probe: %q is not host:port", target)
	}
	port, err := strconv.ParseUint(portStr, 10, 16)
	if err != nil || port == 0 {
		return probe.SeriesResult{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
			"series probe: %q has no valid port", target)
	}
	opts := probe.SeriesOptions{}
	if minutes > 0 {
		opts.Duration = time.Duration(minutes) * time.Minute
	}
	prober := probe.New(probe.Config{TLS: useTLS})
	return prober.ProbeSeries(ctx, &corev1.Endpoint{Host: host, Port: uint32(port)}, opts)
}

// seriesProbeLines renders the series outcome for the operator. The
// verdict line never overclaims: it is generated from Liveness, so a
// short clean series reads "alive for now", not "alive".
func seriesProbeLines(target string, useTLS bool, res probe.SeriesResult) []string {
	transport := "tcp"
	if useTLS {
		transport = "tcp+tls"
	}
	lines := []string{
		fmt.Sprintf("series probe: %s (%s), attempts %d, failures %d, covered %s of the %s confirmation window",
			target, transport, res.Attempts, res.Failures,
			res.Covered.Round(time.Second), probe.SeriesConfirmationWindow),
	}
	switch res.Liveness() {
	case probe.LivenessAliveConfirmed:
		lines = append(lines, "liveness: alive — clean across the whole confirmation window")
	case probe.LivenessAliveForNow:
		lines = append(lines, "liveness: alive for now — every attempt passed, but the series is shorter "+
			"than the censor's dissemination cycle, so a decided block may not be visible yet")
	case probe.LivenessTwoStageBlocked:
		lines = append(lines, "liveness: blocked — the path worked at first, then every attempt failed: "+
			"two-stage blocking landed mid-series")
	case probe.LivenessFailing:
		lines = append(lines, "liveness: not alive — attempts failed (from the start or intermittently)")
	default:
		lines = append(lines, "liveness: unknown — no attempt completed")
	}
	return lines
}

// seriesProbeError maps a non-alive verdict to the exit error; alive
// and alive-for-now are successful measurements, not failures.
func seriesProbeError(res probe.SeriesResult) error {
	switch res.Liveness() {
	case probe.LivenessAliveConfirmed, probe.LivenessAliveForNow:
		return nil
	default:
		return errs.Newf(errs.CodeUnavailable, errs.KeyNetworkFailed,
			"series probe: liveness verdict is %s", res.Liveness())
	}
}
