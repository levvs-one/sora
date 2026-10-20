package main

import (
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/probe"
)

// TestSeriesProbeLinesNeverOverclaim is the T055 regression test for the
// diagnostic surface: a clean but short series must print "alive for
// now", and only a clean full-window series may print "alive".
func TestSeriesProbeLinesNeverOverclaim(t *testing.T) {
	short := probe.SeriesResult{Attempts: 3, Clean: true, Covered: 2 * time.Minute}
	lines := seriesProbeLines("203.0.113.7:443", true, short)
	joined := strings.Join(lines, "\n")
	if !strings.Contains(joined, "alive for now") {
		t.Fatalf("short clean series must read alive-for-now, got:\n%s", joined)
	}
	if strings.Contains(joined, "liveness: alive —") {
		t.Fatalf("short clean series claimed confirmed liveness:\n%s", joined)
	}
	if err := seriesProbeError(short); err != nil {
		t.Fatalf("alive-for-now is a successful measurement, got error %v", err)
	}

	full := probe.SeriesResult{Attempts: 16, Clean: true, Covered: probe.SeriesConfirmationWindow}
	lines = seriesProbeLines("203.0.113.7:443", true, full)
	if !strings.Contains(strings.Join(lines, "\n"), "liveness: alive —") {
		t.Fatalf("full-window clean series must read alive, got:\n%s", strings.Join(lines, "\n"))
	}

	two := probe.SeriesResult{Attempts: 16, Failures: 9, TwoStage: true, Covered: probe.SeriesConfirmationWindow}
	lines = seriesProbeLines("203.0.113.7:443", false, two)
	if !strings.Contains(strings.Join(lines, "\n"), "two-stage blocking landed mid-series") {
		t.Fatalf("two-stage series must name the signature, got:\n%s", strings.Join(lines, "\n"))
	}
	if err := seriesProbeError(two); err == nil {
		t.Fatal("two-stage verdict must exit nonzero")
	}
}

func TestRunSeriesProbeRejectsBadTarget(t *testing.T) {
	if _, err := runSeriesProbe(t.Context(), "not-a-host-port", false, 0); err == nil {
		t.Fatal("target without a port must be rejected")
	}
	if _, err := runSeriesProbe(t.Context(), "127.0.0.1:0", false, 0); err == nil {
		t.Fatal("port 0 must be rejected")
	}
}
