package control

// Throughput benchmarks (F2). BenchmarkServers measures real download
// goodput per server through temporary engine sessions and streams progress;
// GetBenchmarks reads the persisted history. Benchmarks need the control
// authenticator: they burn traffic and spawn engine processes.

import (
	"context"
	"time"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

const (
	maxBenchmarkServers = 32

	minBenchmarkDuration = 5 * time.Second
	maxBenchmarkDuration = 60 * time.Second

	minBenchmarkConcurrency = 1
	maxBenchmarkConcurrency = 4
)

// BenchmarkServers streams throughput samples for the requested servers.
// Each server ends with exactly one done sample.
func (s *Server) BenchmarkServers(req *corev1.BenchmarkServersRequest, stream grpc.ServerStreamingServer[corev1.BandwidthSample]) error {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return err
	}
	if s.benchmarker == nil {
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyProbeInvalidEndpoint,
			"control: this core cannot benchmark throughput")
	}
	ids := req.GetServerIds()
	if len(ids) == 0 {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeNoEndpoints,
			"control: the benchmark request names no servers")
	}
	if len(ids) > maxBenchmarkServers {
		return errs.Newf(errs.CodeResourceExhausted, errs.KeyProbeTooMany,
			"control: the benchmark request names %d servers, the limit is %d", len(ids), maxBenchmarkServers)
	}

	specs, missing := s.resolveBenchmarkServers(ids)
	outbounds := make([]engine.Outbound, 0, len(specs))
	byID := make(map[string]string, len(specs))
	for i, spec := range specs {
		o, err := outboundFromProto(i, spec, s.secrets)
		if err != nil {
			// Unresolvable credentials fail this server, not the batch.
			if sendErr := stream.Send(&corev1.BandwidthSample{
				ServerId: spec.GetId(), Done: true,
				Error: toWire(err, nil, ""),
			}); sendErr != nil {
				return sendErr
			}
			continue
		}
		outbounds = append(outbounds, o)
		byID[o.ID] = spec.GetId()
	}

	duration := time.Duration(req.GetDurationS()) * time.Second
	switch {
	case duration <= 0:
		duration = 10 * time.Second
	case duration < minBenchmarkDuration:
		duration = minBenchmarkDuration
	case duration > maxBenchmarkDuration:
		duration = maxBenchmarkDuration
	}
	concurrency := int(req.GetConcurrency())
	switch {
	case concurrency <= 0:
		concurrency = 2
	case concurrency < minBenchmarkConcurrency:
		concurrency = minBenchmarkConcurrency
	case concurrency > maxBenchmarkConcurrency:
		concurrency = maxBenchmarkConcurrency
	}

	ctx, cancel := context.WithCancel(stream.Context())
	defer cancel()

	// Unknown ids fail fast with done samples.
	for _, id := range missing {
		if err := stream.Send(&corev1.BandwidthSample{
			ServerId: id, Done: true,
			Error: toWire(errs.Newf(errs.CodeNotFound, errs.KeySubscriptionNotFound,
				"control: unknown server %s", id), nil, ""),
		}); err != nil {
			return err
		}
	}

	samples, err := s.benchmarker.Benchmark(ctx, outbounds, engine.BandwidthOptions{
		URL:         req.GetUrl(),
		Duration:    duration,
		Concurrency: concurrency,
	})
	if err != nil {
		return transportStatus(err)
	}
	for sample := range samples {
		wire := &corev1.BandwidthSample{
			ServerId:     sample.ServerID,
			BytesPerSec:  sample.BytesPerSec,
			ProgressPct:  sample.ProgressPct,
			Done:         sample.Done,
		}
		if sample.Err != nil {
			wire.Error = toWire(errs.From(sample.Err), nil, "")
		}
		if err := stream.Send(wire); err != nil {
			return err
		}
	}
	return nil
}

// resolveBenchmarkServers maps server ids to their specs across all
// subscriptions. Unknown ids are returned separately.
func (s *Server) resolveBenchmarkServers(ids []string) (found []*corev1.OutboundSpec, missing []string) {
	s.subs.mu.Lock()
	defer s.subs.mu.Unlock()
	byID := map[string]*corev1.OutboundSpec{}
	for _, list := range s.subs.lists {
		for _, spec := range list {
			byID[spec.GetId()] = spec
		}
	}
	for _, id := range ids {
		if spec, ok := byID[id]; ok {
			found = append(found, spec)
		} else {
			missing = append(missing, id)
		}
	}
	return found, missing
}

// GetBenchmarks returns the stored throughput/latency history.
func (s *Server) GetBenchmarks(ctx context.Context, req *corev1.GetBenchmarksRequest) (*corev1.GetBenchmarksResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	if s.benchmarker == nil {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeyProbeInvalidEndpoint,
			"control: this core cannot benchmark throughput")
		return &corev1.GetBenchmarksResponse{Error: toWire(err, nil, "")}, nil
	}
	want := map[string]bool{}
	for _, id := range req.GetServerIds() {
		want[id] = true
	}
	out := &corev1.GetBenchmarksResponse{}
	for _, e := range s.benchmarker.History() {
		if len(want) > 0 && !want[e.ServerID] {
			continue
		}
		out.Benchmarks = append(out.Benchmarks, &corev1.BenchmarkRecord{
			ServerId:       e.ServerID,
			BytesPerSec:    e.BytesPerSec,
			LatencyMs:      e.LatencyMs,
			MeasuredAtUnix: e.MeasuredAt.Unix(),
		})
	}
	return out, nil
}

// feedBenchmarkLatency records a latency probe result into the benchmark
// history so the UI can sort by the smart score.
func (s *Server) feedBenchmarkLatency(serverID string, latency time.Duration) {
	if s.benchmarker == nil || serverID == "" {
		return
	}
	s.benchmarker.RecordLatency(serverID, latency)
}
