package bypass

import (
	"fmt"

	"github.com/levvs-one/sora-client/core/engine"
)

// Strategy resolution: the step that turns a data-level strategy (a
// registry profile or a tuner genome) into the exact strategy an
// executor runs. Two primitives live here because they need facts only
// the caller has — the target SNI and the measured path length:
//
//   - MidSNIMarker in a split position means "the middle of the actual
//     SNI hostname" and resolves through MidSNISplit (split.go). The
//     marker is deliberately NOT a valid executor position: engine
//     validation refuses it, so an unresolved strategy can never reach
//     a binary and silently split at a guessed offset.
//   - AutoTTL with a delta and a measured hop count resolves through
//     FakeTTL (fakettl.go) into a fixed TTL. When the FakeTTL window
//     collapses (the server is too close for any fake to die strictly
//     between the censor and the server) resolution reports ok=false
//     and the caller must drop the candidate, not approximate it.

// MidSNIMarker is the split-position marker naming a split in the
// middle of the target's SNI hostname.
const MidSNIMarker = "midsni"

// ResolveStrategy resolves s against the target SNI and the measured
// hop distance to the server (hops <= 0 means "not measured": the
// autottl form is then kept for nfqws to calibrate itself, with its
// delta and FakeTTL window rendered by NFQWSArgs).
//
// ok=false (with a nil error) means the strategy has no faithful
// resolution — today that is exactly the FakeTTL window collapse —
// and the caller must skip the candidate rather than run a neighbour
// of it. A non-nil error means malformed input (a marker without an
// SNI, an invalid SNI, a negative delta).
func ResolveStrategy(s engine.BypassStrategy, sni string, hopsToServer int) (resolved engine.BypassStrategy, ok bool, err error) {
	out := s
	out.SplitPos = append([]string(nil), s.SplitPos...)
	resolvePos := func(pos string) (string, error) {
		if pos != MidSNIMarker {
			return pos, nil
		}
		if sni == "" {
			return "", fmt.Errorf("bypass: split position %q needs the target SNI to resolve against", MidSNIMarker)
		}
		return MidSNISplit(sni)
	}
	for i, pos := range out.SplitPos {
		r, err := resolvePos(pos)
		if err != nil {
			return engine.BypassStrategy{}, false, err
		}
		out.SplitPos[i] = r
	}
	if out.TLSRecord == MidSNIMarker {
		r, err := resolvePos(out.TLSRecord)
		if err != nil {
			return engine.BypassStrategy{}, false, err
		}
		out.TLSRecord = r
	}
	if out.AutoTTL && out.AutoTTLDelta > 0 && hopsToServer > 0 {
		ttl, viable, err := FakeTTL(hopsToServer, out.AutoTTLDelta)
		if err != nil {
			return engine.BypassStrategy{}, false, err
		}
		if !viable {
			// Window collapse: no TTL dies after the censor but
			// before this server. The honest move is to refuse the
			// candidate so the caller falls back to a non-fake
			// strategy (split/disorder), exactly as fakettl.go
			// prescribes.
			return engine.BypassStrategy{}, false, nil
		}
		out.TTL = ttl
		out.AutoTTL = false
		out.AutoTTLDelta = 0
	}
	return out, true, nil
}

// resolvePlanStrategies is the executor's own guard inside Apply:
// every bypass strategy in the plan is resolved and validated by the
// executor itself before any binary starts, so the invariant "an
// unresolved or malformed strategy never reaches a binary" does not
// depend on the caller having validated the plan (session.New does,
// but Apply is public and must not trust that).
//
// Apply has no single target SNI and no measured path length — a plan
// serves many hosts — so resolution runs with an empty SNI and
// hops=0: a strategy carrying the mid-SNI marker cannot be resolved
// here and is REFUSED (the error names the remedy: resolve against
// the target first, as the tuner and the session prober do), and the
// autottl form is kept for nfqws to calibrate natively. The resolved
// strategy is then validated through the same outbound validation
// plan validation uses; a strategy that fails it is refused here too.
// The plan is not mutated: the returned copy carries the resolved
// strategies (identical to the input for every strategy that passes).
func resolvePlanStrategies(p *engine.Plan) (*engine.Plan, error) {
	if p == nil {
		return nil, fmt.Errorf("bypass: apply of a nil plan")
	}
	out := *p
	out.Outbounds = append([]engine.Outbound(nil), p.Outbounds...)
	for i, o := range out.Outbounds {
		if o.Protocol != engine.ProtocolBypass || o.Bypass == nil {
			continue
		}
		resolved, ok, err := ResolveStrategy(*o.Bypass, "", 0)
		if err != nil {
			return nil, fmt.Errorf("bypass: outbound %s: %w", o.ID, err)
		}
		if !ok {
			return nil, fmt.Errorf("bypass: outbound %s: the strategy has no faithful resolution without a target SNI and a measured path length", o.ID)
		}
		probe := engine.Outbound{ID: o.ID, Protocol: engine.ProtocolBypass, Bypass: &resolved}
		if err := probe.Validate(); err != nil {
			return nil, fmt.Errorf("bypass: outbound %s: the executor refuses the strategy: %w", o.ID, err)
		}
		out.Outbounds[i].Bypass = &resolved
	}
	return &out, nil
}

// ArgsForTarget renders the tpws arguments for a strategy resolved
// against the target SNI (see ResolveStrategy). ok=false mirrors
// ResolveStrategy: the strategy cannot run faithfully for this target.
func ArgsForTarget(s engine.BypassStrategy, port int, sni string, hopsToServer int) ([]string, bool, error) {
	r, ok, err := ResolveStrategy(s, sni, hopsToServer)
	if err != nil || !ok {
		return nil, ok, err
	}
	return Args(r, port), true, nil
}

// NFQWSArgsForTarget renders the nfqws arguments for a strategy
// resolved against the target SNI and path length (see
// ResolveStrategy). This is the renderer the desync tuner and the
// registry profiles are verified through in tests: the argv a real
// binary would receive for a concrete target.
func NFQWSArgsForTarget(s engine.BypassStrategy, home, sni string, hopsToServer int) ([]string, bool, error) {
	r, ok, err := ResolveStrategy(s, sni, hopsToServer)
	if err != nil || !ok {
		return nil, ok, err
	}
	return NFQWSArgs(r, home), true, nil
}
