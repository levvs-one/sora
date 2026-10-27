package control_test

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/probe"
)

func TestProbeChunkFailureReturnsStatusAfterPartialResults(t *testing.T) {
	for _, count := range []int{1, 300} {
		t.Run(fmt.Sprint(count), func(t *testing.T) {
			failedBatch := 1
			wantResults := 0
			if count > 1 {
				failedBatch = 2
				wantResults = count - control.ProbeChunkSize
			}
			p := &chunkProber{failOn: failedBatch}
			stream := &probeStream{ctx: context.Background()}
			err := probeServer(t, &fakeMeasurer{}, p).ProbeServers(
				chunkProbeRequest(count, corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream)
			if status.Code(err) != codes.Internal {
				t.Errorf("failed chunk terminal status = %v, want Internal", err)
			}
			if err != nil && (strings.Contains(err.Error(), "synthetic") ||
				!strings.HasSuffix(status.Convert(err).Message(), string(errs.KeyInternal))) {
				t.Errorf("terminal status must carry the catalog key without raw detail: %v", err)
			}
			if len(stream.sent) != wantResults {
				t.Fatalf("partial results = %d, want %d", len(stream.sent), wantResults)
			}
			for _, result := range stream.sent {
				if !result.GetReachable() || result.GetError() != nil {
					t.Fatal("unmeasured endpoints must not become unreachable samples")
				}
			}
		})
	}
}

func TestProbeSaturatedBackendReturnsResourceStatus(t *testing.T) {
	p := &admissionProber{slots: make(chan struct{}, probe.MaxConcurrentRequests), release: make(chan struct{})}
	for range probe.MaxConcurrentRequests {
		p.slots <- struct{}{}
	}
	stream := &probeStream{ctx: context.Background()}
	err := probeServer(t, &fakeMeasurer{}, p).ProbeServers(
		chunkProbeRequest(1, corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream)
	if status.Code(err) != codes.ResourceExhausted {
		t.Errorf("busy backend terminal status = %v, want ResourceExhausted", err)
	}
	if len(stream.sent) != 0 {
		t.Errorf("busy backend fabricated %d results", len(stream.sent))
	}
	if err != nil && (strings.Contains(err.Error(), "fixture") ||
		!strings.HasSuffix(status.Convert(err).Message(), string(errs.KeyProbeTooMany))) {
		t.Errorf("busy backend status exposed detail or lost its key: %v", err)
	}
}

type failedSetupMeasurer struct{}

func (failedSetupMeasurer) Measure(context.Context, []engine.Outbound, engine.MeasureOptions) (<-chan engine.Measurement, error) {
	return nil, errs.Newf(errs.CodeUnavailable, errs.KeyEngineStartFailed, "fixture-private-startup-detail")
}

func TestProbeMeasurementSetupFailureReturnsStatus(t *testing.T) {
	for _, count := range []int{1, 300} {
		t.Run(fmt.Sprint(count), func(t *testing.T) {
			stream := &probeStream{ctx: context.Background()}
			err := probeServer(t, failedSetupMeasurer{}, &fakeProber{}).ProbeServers(
				chunkProbeRequest(count, corev1.ProbeMethod_PROBE_METHOD_ENGINE), stream)
			if status.Code(err) != codes.Unavailable {
				t.Errorf("measurement setup status = %v, want Unavailable", err)
			}
			if len(stream.sent) != 0 {
				t.Errorf("failed setup fabricated %d results", len(stream.sent))
			}
			if err != nil && (strings.Contains(err.Error(), "fixture-private") ||
				!strings.HasSuffix(status.Convert(err).Message(), string(errs.KeyEngineStartFailed))) {
				t.Errorf("setup status exposed detail or lost its key: %v", err)
			}
		})
	}
}
