package control

// Proxy chain probing (F8). ProbeChain checks a 2-3 server chain before
// connecting: per-hop reachability via a fast TCP probe, the summed latency
// estimate, and which installed engines can carry the chain.
//
// Production status (2026-10-20): NOT WIRED on the client side. The RPC
// is implemented and tested, but no Dart code calls it — the chains UI
// connects without a pre-flight probe. Chains themselves work end to
// end (plan Via -> engine detour); only this probe is unconsumed.

import (
	"context"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// chainAvailability exposes engine discovery for chain support checks.
type chainAvailability interface {
	Availability() []engine.Availability
}

// ProbeChain probes the ordered servers and reports per-hop reachability,
// the summed latency estimate, and the installed engines able to carry the
// chain. It burns a little traffic and needs the control authenticator.
func (s *Server) ProbeChain(ctx context.Context, req *corev1.ProbeChainRequest) (*corev1.ProbeChainResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	ids := req.GetServerIds()
	if len(ids) < 2 || len(ids) > engine.MaxChainHops {
		err := errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeNoEndpoints,
			"control: a proxy chain needs 2 to %d servers, got %d", engine.MaxChainHops, len(ids))
		return &corev1.ProbeChainResponse{Error: toWire(err, nil, "")}, nil
	}
	seen := make(map[string]bool, len(ids))
	for _, id := range ids {
		if seen[id] {
			err := errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeNoEndpoints,
				"control: the proxy chain repeats %q", id)
			return &corev1.ProbeChainResponse{Error: toWire(err, nil, "")}, nil
		}
		seen[id] = true
	}
	if s.prober == nil {
		err := errs.Newf(errs.CodeUnsupported, errs.KeyProbeInvalidEndpoint,
			"control: this core cannot probe endpoints")
		return &corev1.ProbeChainResponse{Error: toWire(err, nil, "")}, nil
	}
	specs, missing := s.resolveBenchmarkServers(ids)
	if len(missing) > 0 {
		err := errs.Newf(errs.CodeNotFound, errs.KeySubscriptionNotFound,
			"control: the chain names unknown servers: %v", missing)
		return &corev1.ProbeChainResponse{Error: toWire(err, nil, "")}, nil
	}
	endpoints, probeIDs := endpointsOf(specs)
	results, err := s.prober.Probe(ctx, endpoints, probeIDs)
	if err != nil {
		return &corev1.ProbeChainResponse{Error: toWire(err, nil, "")}, nil
	}
	byID := make(map[string]*corev1.ProbeResult, len(ids))
	for r := range results {
		byID[r.GetServerId()] = r
	}
	out := &corev1.ProbeChainResponse{}
	for _, id := range ids {
		hop := &corev1.ChainHop{ServerId: id}
		if r := byID[id]; r != nil {
			hop.Reachable = r.GetReachable()
			hop.LatencyMs = r.GetLatencyMs()
			out.TotalLatencyMs += r.GetLatencyMs()
		}
		out.Hops = append(out.Hops, hop)
	}
	out.Engines = chainEngines(s.measurer)
	return out, nil
}

// chainEngines lists installed engines able to dial one outbound through
// another, in default preference order.
func chainEngines(measurer Measurer) []string {
	provider, ok := measurer.(chainAvailability)
	if !ok {
		return nil
	}
	var out []string
	for _, kind := range engine.DefaultPreference {
		for _, a := range provider.Availability() {
			if a.Kind != kind || !a.Usable {
				continue
			}
			if engine.BuildCapabilities(kind, a.Version, a.BuildTags).Supports(engine.FeatureChains) {
				out = append(out, string(kind))
			}
		}
	}
	return out
}
