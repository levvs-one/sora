package control

import (
	"context"
	"time"

	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// dnsLeakTimeout bounds the whole leak check. The feature contract requires
// the check to finish in under 10 seconds.
const dnsLeakTimeout = 10 * time.Second

// CheckDnsLeaks runs DNS leak diagnostics for the running session: which
// resolvers the session uses versus what the OS would use, and whether the
// kill switch covers DNS. It needs an active session; without one it
// reports KeySessionRequired ("not connected" in UI terms).
func (s *Server) CheckDnsLeaks(ctx context.Context, req *corev1.CheckDnsLeaksRequest) (*corev1.CheckDnsLeaksResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	running := s.sessions.Current()
	if running == nil {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"control: DNS leak check needs an active session")
		return &corev1.CheckDnsLeaksResponse{Error: toWire(err, nil, "")}, nil
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.CheckDnsLeaksResponse{Error: toWire(err, nil, "")}, nil
	}
	var tunnel []diagnostics.TunnelResolver
	var hijacked bool
	if plan := running.Plan(); plan != nil {
		for _, ds := range plan.DNS.Servers {
			tunnel = append(tunnel, diagnostics.TunnelResolver{
				Address:   ds.Address,
				Port:      ds.Port,
				Transport: string(ds.Transport),
			})
		}
		// The old signal was len(plan.DNS.HijackTun) > 0 — a field
		// nothing in production fills, so this was false on every real
		// session and the system-resolvers check failed spuriously
		// without a kill switch.
		hijacked = hijacksDNS(running.Status().TunnelMode, plan)
	}
	ctx, cancel := requestDeadline(ctx, dnsLeakTimeout)
	defer cancel()
	checks := diagnostics.CheckDnsLeaks(ctx, diagnostics.DnsLeakInput{
		TunnelResolvers: tunnel,
		DnsHijacked:     hijacked,
		// The platform-probed block state, not the session's wish:
		// a manually removed table must read as "not covered".
		KillSwitchArmed: s.killSwitchArmed(ctx, running),
	})
	out := &corev1.CheckDnsLeaksResponse{}
	for _, c := range checks {
		out.Checks = append(out.Checks, &corev1.DnsLeakCheck{
			Id:       c.ID,
			Label:    c.Label,
			Expected: c.Expected,
			Actual:   c.Actual,
			Leaked:   c.Leaked,
			FixHint:  c.FixHint,
		})
	}
	return out, nil
}
