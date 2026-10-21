package control

import (
	"context"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	leakv1 "github.com/levvs-one/sora-client/core/gen/sora/leak/v1"
	"github.com/levvs-one/sora-client/core/leak"
	"github.com/levvs-one/sora-client/core/session"
)

// leakTestTimeout bounds the whole self-test run: four probes with
// per-probe timeouts must fit inside it with room to stream results.
const leakTestTimeout = 30 * time.Second

// RunLeakTests streams the core's egress self-tests for the running session:
// direct DNS, IPv6, ICMP echo, and the OS resolvers. Every test needs the
// control authenticator, like ListConnections: the results describe where
// the machine's traffic can go. Without an active session there is no
// tunnel to test, so the call fails instead of inventing answers.
func (s *Server) RunLeakTests(req *leakv1.RunLeakTestsRequest, stream grpc.ServerStreamingServer[leakv1.LeakTestResult]) error {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return err
	}
	running := s.sessions.Current()
	if running == nil {
		// A streaming RPC has no response envelope for domain errors,
		// so the precondition travels as a gRPC status, like the
		// transport-exclusive errors in the other handlers.
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"control: leak self-tests need an active session")
		return status.Error(codes.FailedPrecondition, err.Error())
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return status.Error(codes.NotFound, err.Error())
	}
	ctx, cancel := requestDeadline(stream.Context(), leakTestTimeout)
	defer cancel()
	results, err := leak.Run(ctx, leakInput(running, s.killSwitchArmed(ctx, running)), req.GetTestIds())
	if err != nil {
		derr := errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: %s", err.Error())
		return status.Error(codes.InvalidArgument, derr.Error())
	}
	for _, r := range results {
		if err := stream.Send(&leakv1.LeakTestResult{
			Test:       &leakv1.LeakTest{Id: r.ID, Label: r.Label},
			Pass:       r.Pass,
			Skipped:    r.Skipped,
			Details:    r.Details,
			DurationMs: r.Duration.Milliseconds(),
		}); err != nil {
			return err
		}
	}
	return nil
}

// killSwitchArmed reports the kill switch as it actually is right now,
// probed against the platform through the guard - not as the session
// wishes it were. A table removed out-of-band must surface here as "not
// armed", or the diagnostics would keep reassuring the user behind a
// block that is gone. A probe failure keeps the desired state: the probe
// is the only part that can be wrong then.
func (s *Server) killSwitchArmed(ctx context.Context, running *session.Session) bool {
	armed := running.Status().KillSwitch
	if blocked, err := s.sessions.KillSwitchBlocked(ctx); err == nil {
		armed = blocked
	}
	return armed
}

// leakInput translates the running session into the self-test inputs: the
// platform-probed kill switch state (killSwitchArmed, not the session's
// wish), whether the tunnel is up and captures direct sockets, and the
// tunnel's DNS configuration.
func leakInput(running *session.Session, killSwitchArmed bool) leak.Input {
	st := running.Status()
	in := leak.Input{
		KillSwitchArmed: killSwitchArmed,
		TunnelUp:        st.State == session.StateConnected,
		// The system (TUN) mode captures plain sockets while the tunnel
		// is up; the application (proxy) mode does not.
		DirectCaptured: st.TunnelMode == "system",
	}
	if plan := running.Plan(); plan != nil {
		in.TunnelIPv6 = plan.Tun.IPv6.IsValid()
		in.DNSHijacked = hijacksDNS(st.TunnelMode, plan)
		for _, ds := range plan.DNS.Servers {
			in.TunnelResolvers = append(in.TunnelResolvers, ds.Address)
		}
	}
	return in
}

// hijacksDNS reports whether the running plan actually captures plain DNS
// traffic. DNS.HijackTun cannot be the signal: nothing in production ever
// fills the field, so the old check reported false on every real session.
// In system (TUN) mode every backend hijacks port 53 anyway - sing-box
// routes DNS to hijack-dns unconditionally, mihomo's TUN renders
// dns-hijack by default, and the core's tunroute steers DNS into the TUN -
// while in application mode plain OS DNS stays outside the engines
// entirely.
func hijacksDNS(tunnelMode string, plan *engine.Plan) bool {
	return plan != nil && tunnelMode == "system" && plan.Tun.Enabled
}
