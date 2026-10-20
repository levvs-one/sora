package probe

import (
	"context"
	"errors"
	"net"
	"strconv"
	"testing"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func fastSeries() SeriesOptions {
	return SeriesOptions{Duration: 350 * time.Millisecond, Interval: 100 * time.Millisecond}
}

func TestSeriesClean(t *testing.T) {
	res := RunSeries(context.Background(), fastSeries(), func(ctx context.Context) error { return nil })
	if !res.Clean {
		t.Fatalf("result = %+v, want clean", res)
	}
	if res.TwoStage {
		t.Fatal("clean series flagged two-stage")
	}
	if res.Attempts < 3 {
		t.Fatalf("attempts = %d, want several in the window", res.Attempts)
	}
}

func TestSeriesBlockedFromStart(t *testing.T) {
	res := RunSeries(context.Background(), fastSeries(), func(ctx context.Context) error {
		return errors.New("blocked")
	})
	if res.Clean {
		t.Fatal("all-failed series reported clean")
	}
	if res.TwoStage {
		t.Fatal("failed-from-start is not two-stage: nothing turned mid-series")
	}
	if res.Failures != res.Attempts {
		t.Fatalf("failures = %d, attempts = %d", res.Failures, res.Attempts)
	}
	if res.FirstFailure.IsZero() {
		t.Fatal("first failure not recorded")
	}
}

func TestSeriesTwoStage(t *testing.T) {
	calls := 0
	res := RunSeries(context.Background(), fastSeries(), func(ctx context.Context) error {
		calls++
		if calls <= 2 {
			return nil
		}
		return errors.New("blocked")
	})
	if res.Clean {
		t.Fatal("series with failures reported clean")
	}
	if !res.TwoStage {
		t.Fatalf("result = %+v, want the two-stage signature", res)
	}
}

func TestSeriesFlakyIsNotTwoStage(t *testing.T) {
	calls := 0
	res := RunSeries(context.Background(), fastSeries(), func(ctx context.Context) error {
		calls++
		if calls%2 == 0 {
			return errors.New("blip")
		}
		return nil
	})
	if res.TwoStage {
		t.Fatal("interleaved failures flagged as two-stage")
	}
	if res.Clean {
		t.Fatal("flaky series reported clean")
	}
}

func TestSeriesContextCancel(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	start := time.Now()
	res := RunSeries(ctx, SeriesOptions{Duration: time.Hour, Interval: time.Hour}, func(ctx context.Context) error {
		return ctx.Err()
	})
	if time.Since(start) > 5*time.Second {
		t.Fatal("cancelled series did not return promptly")
	}
	if res.Clean {
		t.Fatal("cancelled series reported clean")
	}
	// Partial evidence, not an error: the caller still gets the attempts.
	if res.Attempts == 0 {
		t.Fatal("cancelled series returned zero attempts")
	}
}

func TestSeriesDefaults(t *testing.T) {
	o := SeriesOptions{}.normalized()
	if o.Duration != DefaultSeriesDuration || o.Interval != DefaultSeriesInterval || o.AttemptTimeout != DefaultSeriesInterval {
		t.Fatalf("defaults = %+v", o)
	}
}

// TestSeriesLivenessVerdictRule is the T055 regression test: "alive" is
// earned only by a clean series covering the whole confirmation window.
// A clean result over anything shorter — even many attempts — is only
// "alive for now", because a decided block may not be disseminated yet.
func TestSeriesLivenessVerdictRule(t *testing.T) {
	cases := []struct {
		name string
		res  SeriesResult
		want Liveness
	}{
		{"no attempts", SeriesResult{}, LivenessUnknown},
		{"clean full window", SeriesResult{Attempts: 16, Clean: true, Covered: SeriesConfirmationWindow}, LivenessAliveConfirmed},
		{"clean beyond window", SeriesResult{Attempts: 20, Clean: true, Covered: 20 * time.Minute}, LivenessAliveConfirmed},
		{"clean just short", SeriesResult{Attempts: 15, Clean: true, Covered: SeriesConfirmationWindow - time.Second}, LivenessAliveForNow},
		{"clean single probe", SeriesResult{Attempts: 1, Clean: true}, LivenessAliveForNow},
		{"two-stage", SeriesResult{Attempts: 16, Failures: 9, TwoStage: true, Covered: SeriesConfirmationWindow}, LivenessTwoStageBlocked},
		{"failed from start", SeriesResult{Attempts: 16, Failures: 16, Covered: SeriesConfirmationWindow}, LivenessFailing},
		{"flaky", SeriesResult{Attempts: 16, Failures: 3, Covered: SeriesConfirmationWindow}, LivenessFailing},
	}
	for _, tc := range cases {
		if got := tc.res.Liveness(); got != tc.want {
			t.Errorf("%s: Liveness() = %v, want %v", tc.name, got, tc.want)
		}
	}
}

// TestSeriesCleanShortWindowIsOnlyForNow runs a real short series: it
// must come back clean yet unconfirmed — the window, not the attempt
// count, is what confirms.
func TestSeriesCleanShortWindowIsOnlyForNow(t *testing.T) {
	res := RunSeries(context.Background(), fastSeries(), func(ctx context.Context) error { return nil })
	if !res.Clean {
		t.Fatalf("result = %+v, want clean", res)
	}
	if res.Covered <= 0 || res.Covered >= SeriesConfirmationWindow {
		t.Fatalf("covered = %v, want a positive span below the confirmation window", res.Covered)
	}
	if got := res.Liveness(); got != LivenessAliveForNow {
		t.Fatalf("Liveness() = %v, want alive-for-now for a sub-window clean series", got)
	}
}

func TestProbeSeriesAgainstListener(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	go func() {
		for {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			_ = conn.Close()
		}
	}()
	host, portStr, err := net.SplitHostPort(ln.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	port, err := strconv.ParseUint(portStr, 10, 32)
	if err != nil {
		t.Fatal(err)
	}
	p := New(Config{Timeout: time.Second})
	res, err := p.ProbeSeries(context.Background(), &corev1.Endpoint{Host: host, Port: uint32(port)}, fastSeries())
	if err != nil {
		t.Fatal(err)
	}
	if !res.Clean || res.Attempts < 3 {
		t.Fatalf("series against a live listener = %+v, want clean with several attempts", res)
	}
	if got := res.Liveness(); got != LivenessAliveForNow {
		t.Fatalf("Liveness() = %v, want alive-for-now (short window)", got)
	}
}

func TestProbeSeriesRefusedIsFailing(t *testing.T) {
	// Bind then release a port so nothing listens on it.
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	addr := ln.Addr().String()
	_ = ln.Close()
	host, portStr, err := net.SplitHostPort(addr)
	if err != nil {
		t.Fatal(err)
	}
	port, err := strconv.ParseUint(portStr, 10, 32)
	if err != nil {
		t.Fatal(err)
	}
	p := New(Config{Timeout: time.Second})
	res, err := p.ProbeSeries(context.Background(), &corev1.Endpoint{Host: host, Port: uint32(port)}, fastSeries())
	if err != nil {
		t.Fatal(err)
	}
	if res.Clean || res.Failures != res.Attempts {
		t.Fatalf("series against a refused port = %+v, want every attempt failed", res)
	}
	if got := res.Liveness(); got != LivenessFailing {
		t.Fatalf("Liveness() = %v, want failing", got)
	}
}

func TestProbeSeriesRejectsBadEndpoint(t *testing.T) {
	p := New(Config{})
	if _, err := p.ProbeSeries(context.Background(), &corev1.Endpoint{}, fastSeries()); err == nil {
		t.Fatal("empty endpoint must be rejected, not probed")
	}
}
