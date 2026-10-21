package control

// Throughput benchmarks. BenchmarkServers measures real download
// goodput per server through temporary engine sessions and streams progress;
// results are live samples only - the app stores whatever history it
// shows. Benchmarks need the control authenticator: they burn traffic
// and spawn engine processes.

import (
	"context"
	"sort"
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
			ServerId:    sample.ServerID,
			BytesPerSec: sample.BytesPerSec,
			ProgressPct: sample.ProgressPct,
			Done:        sample.Done,
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
//
// When several subscriptions carry the same server id, the winner is
// deterministic: lists are visited in the book's canonical order - the
// same order ListSubscriptions reports, a subscription's Created time
// with its id as the tie-break (subscriptions without a record, which
// only tests construct, sort by id alone) - and the spec from the
// latest subscription in that order wins.
func (s *Server) resolveBenchmarkServers(ids []string) (found []*corev1.OutboundSpec, missing []string) {
	s.subs.mu.Lock()
	defer s.subs.mu.Unlock()
	// Stored lists are parsed lazily after a restart (pendingLists);
	// force every pending parse now, under the held mutex as
	// ensureListsLocked requires. Without this, a benchmark request
	// that arrives before the first state snapshot scans the
	// still-empty lists map and reports every saved server as unknown.
	s.subs.ensureListsLocked()
	// Index only the requested ids, not the whole book: a request names
	// at most maxBenchmarkServers servers, while the subscriptions may
	// hold thousands. The previous full-book index allocated ~110 KB to
	// answer a 32-id lookup in a 2000-server book (measured); the
	// inverted index allocates proportionally to the request. The scan
	// still visits every list and lets later lists override earlier
	// ones, exactly like the full index did - only the storage shrinks.
	// "Later" is the deterministic book order defined above, never Go
	// map iteration order; the ordering key set is the subscriptions
	// (at most maxSubscriptions), not the servers, so the sort costs
	// proportionally to the subscription count.
	want := make(map[string]struct{}, len(ids))
	for _, id := range ids {
		want[id] = struct{}{}
	}
	ordered := make([]string, 0, len(s.subs.lists))
	for subID := range s.subs.lists {
		ordered = append(ordered, subID)
	}
	sort.Slice(ordered, func(i, j int) bool {
		a, b := ordered[i], ordered[j]
		var aCreated, bCreated time.Time
		if rec := s.subs.records[a]; rec != nil {
			aCreated = rec.Created
		}
		if rec := s.subs.records[b]; rec != nil {
			bCreated = rec.Created
		}
		if !aCreated.Equal(bCreated) {
			return aCreated.Before(bCreated)
		}
		return a < b
	})
	matched := make(map[string]*corev1.OutboundSpec, len(ids))
	for _, subID := range ordered {
		for _, spec := range s.subs.lists[subID] {
			id := spec.GetId()
			if _, ok := want[id]; ok {
				matched[id] = spec
			}
		}
	}
	if s.dataDir != "" {
		for _, spec := range s.CustomOutbounds() {
			if _, ok := want[spec.GetId()]; ok {
				matched[spec.GetId()] = spec
			}
		}
	}
	// At most len(ids) ids land in each bucket; duplicates in the
	// request are answered per occurrence, in request order.
	found = make([]*corev1.OutboundSpec, 0, len(ids))
	missing = make([]string, 0, len(ids))
	for _, id := range ids {
		if spec, ok := matched[id]; ok {
			found = append(found, spec)
		} else {
			missing = append(missing, id)
		}
	}
	return found, missing
}

// GetBenchmarks was removed (M3, PASS1-SWARM): no client ever called it
// - the app keeps its benchmark history locally - so the RPC, the
// history store behind it, and the latency feed that wrote into it are
// gone. The proto keeps the message shapes for wire compatibility; the
// method itself now falls through to UnimplementedCoreControlServer.
