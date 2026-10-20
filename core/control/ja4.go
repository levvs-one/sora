package control

import (
	"context"

	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/engine"
)

// ja4FreshnessNotices is the production consumer of the JA4 self-check
// (S8): for every DISTINCT fingerprint a plan pins explicitly, it runs
// the assessor — diagnostics.AssessJA4 in production, a local
// ClientHello capture against a recording stand-in, no network
// traffic — and returns one journal line per fingerprint that measured
// stale: an outdated parrot, or a ClientHello that contradicts modern
// browsers (e.g. no X25519MLKEM768 post-quantum key share).
//
// Silence is deliberate everywhere else: unconfigured fingerprints
// (the engine default applies — its freshness is the CI gate's job, not
// a per-connect verdict), fingerprints the core cannot resolve or
// capture (nothing was measured: no claim), and fingerprints that
// measured fresh. Notices ride the session journal as EventLog lines,
// the same channel the obfs startup notices use, so WatchEvents shows
// them to the client.
func ja4FreshnessNotices(ctx context.Context, plan *engine.Plan) []string {
	return ja4FreshnessNoticesWith(ctx, plan, diagnostics.AssessJA4)
}

// assessJA4 is the signature of diagnostics.AssessJA4, extracted so
// tests can inject a fake capture without a real handshake.
type assessJA4 func(context.Context, diagnostics.JA4Input) diagnostics.JA4Report

func ja4FreshnessNoticesWith(ctx context.Context, plan *engine.Plan, assess assessJA4) []string {
	seen := make(map[string]bool)
	var out []string
	for _, o := range plan.Outbounds {
		fp := engine.NormalizeFingerprint(o.TLS.Fingerprint)
		if fp == "" || seen[fp] {
			continue
		}
		seen[fp] = true
		rep := assess(ctx, diagnostics.JA4Input{Fingerprint: fp})
		if rep.JA4 == "" || rep.Fresh {
			continue
		}
		out = append(out, "fingerprint check: "+rep.Detail)
	}
	return out
}
