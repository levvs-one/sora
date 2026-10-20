package control

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"net"
	"strings"
	"sync"
	"time"

	"golang.org/x/net/proxy"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
	"github.com/levvs-one/sora-client/core/errs"
	censorv1 "github.com/levvs-one/sora-client/core/gen/sora/censor/v1"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/profiles"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/tune/desync"
)

// TuneDesync is the production caller of the Geneva desync tuner
// (core/tune/desync): the user's explicit "pick a strategy" action.
//
// The discipline is the tuner's own doc, enforced here:
//   - explicit trigger only (this RPC; nothing runs it implicitly);
//   - rate-limited per network inside desync.Service;
//   - probes only the tuner's canary endpoints — the request carries
//     no target, so there is nothing a client could aim elsewhere;
//   - passive signals remain the preferred retune input
//     (Service.ShouldRetune over Service.Observe); this active run is
//     the fallback the user asked for;
//   - the winner binds to the F5 network profile (profileBinder) and
//     to the tuner's binding store, and rotates on silent death.
//
// Probing needs the candidate strategy live on the direct path, so a
// run requires NO live session: it connects short-lived probe
// sessions (one candidate at a time) and measures the canary
// handshakes through the engine's local proxy. Refusing to tune over
// a live tunnel is deliberate: swapping the zapret strategy under the
// user's traffic to test a guess would break the very connections
// the tuner exists to save.

// desyncServices holds one tuner Service per control Server: the
// rate-limit state must outlive a single RPC, and the Server struct
// (server.go) predates the tuner. Keyed weakly by pointer identity
// only for the process lifetime — a Server lives as long as the core.
var desyncServices sync.Map // *Server -> *desync.Service

// DesyncServiceForTest replaces the tuner Service in tests (the
// NftBinForTest convention); production code leaves it nil.
var DesyncServiceForTest *desync.Service

func (s *Server) desyncService() (*desync.Service, error) {
	if DesyncServiceForTest != nil {
		return DesyncServiceForTest, nil
	}
	if v, ok := desyncServices.Load(s); ok {
		return v.(*desync.Service), nil
	}
	store, err := desync.NewBindingStore(s.dataDir)
	if err != nil {
		return nil, err
	}
	svc, err := desync.NewService(store, profileBinder{srv: s})
	if err != nil {
		return nil, err
	}
	if s.logs != nil {
		// A stored winner the Service refuses to re-serve (stale data
		// versions, a genome that no longer converts) is an event the
		// user-facing journal must show — the alternative is a silent
		// stale strategy. The reason is one of the tuner's fixed
		// tokens; the fingerprint is deliberately NOT logged (it names
		// the user's network).
		svc.OnRefuse = func(_ profiles.Fingerprint, reason string) {
			s.logs.Write(time.Time{}, logs.LevelWarning, bypass.Source,
				"desync: the stored winner for this network was refused ("+reason+"); run tuning again to pick a fresh strategy")
		}
	}
	actual, _ := desyncServices.LoadOrStore(s, svc)
	return actual.(*desync.Service), nil
}

// profileBinder writes the winning registry profile onto the F5
// network profile matching the fingerprint (desync.ProfileBinder).
// No matching profile is not an error: the binding store still
// remembers the winner by network key; the F5 write lands when the
// user has (or creates) a profile for the network.
type profileBinder struct{ srv *Server }

func (b profileBinder) BindDesyncProfile(_ context.Context, fp profiles.Fingerprint, profileID string, _ desync.Params) error {
	store, err := b.srv.profileStore()
	if err != nil {
		return err
	}
	m := store.Match(fp)
	if m == nil {
		return nil
	}
	for _, p := range store.List() {
		if p.ID == m.ProfileID {
			p.Apply.DesyncProfile = profileID
			_, err := store.Save(p)
			return err
		}
	}
	return nil
}

// TuneDesync implements sora.censor.v1.CensorControl.TuneDesync.
func (s *Server) TuneDesync(ctx context.Context, req *censorv1.TuneDesyncRequest) (*censorv1.TuneDesyncResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.auth.Check(req.GetControlAuthenticator()); err != nil {
		return nil, transportStatus(err)
	}
	engineName := strings.TrimSpace(req.GetEngine())
	switch engineName {
	case "", "nfqws", "tpws":
	default:
		err := errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: desync engine %q is not \"nfqws\" or \"tpws\"", engineName)
		return &censorv1.TuneDesyncResponse{Error: toWire(err, nil, id)}, nil
	}
	if engineName == "" {
		engineName = "nfqws"
	}
	if s.sessions.Current() != nil {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionBusy,
			"control: desync tuning runs probe sessions of its own; disconnect the current session first")
		return &censorv1.TuneDesyncResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.extProxyPort == 0 {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeyInternal,
			"control: desync tuning needs the engine local proxy port, which this core was not configured with")
		return &censorv1.TuneDesyncResponse{Error: toWire(err, nil, id)}, nil
	}
	svc, err := s.desyncService()
	if err != nil {
		cerr := errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
		return &censorv1.TuneDesyncResponse{Error: toWire(cerr, nil, id)}, nil
	}
	fp := profiles.Current()
	if s.profiles != nil {
		fp.ASN = s.profiles.Fingerprint().ASN
	}
	prober := &desyncSessionProber{srv: s}
	res, tuneErr := svc.Tune(ctx, fp, engineName, prober.Probe)
	if tuneErr != nil && !errors.Is(tuneErr, desync.ErrNoWorking) {
		var code errs.Code = errs.CodeInternal
		var key errs.Key = errs.KeyInternal
		if errors.Is(tuneErr, desync.ErrRateLimited) {
			code, key = errs.CodeResourceExhausted, errs.KeyInvalidRequest
		}
		cerr := errs.Newf(code, key, "control: %v", tuneErr)
		return &censorv1.TuneDesyncResponse{Error: toWire(cerr, nil, id)}, nil
	}
	if errors.Is(tuneErr, desync.ErrNoWorking) && prober.capabilityErr != nil {
		// Every candidate failed for the same host reason: the honest
		// answer is the capability refusal, not "no strategy worked".
		cerr := errs.Newf(errs.CodeFailedPrecondition, errs.KeyInternal,
			"control: desync tuning cannot run on this host: %v", prober.capabilityErr)
		return &censorv1.TuneDesyncResponse{Error: toWire(cerr, nil, id)}, nil
	}
	out := &censorv1.TuneDesyncResponse{Attempts: int32(res.Attempts), ProbeRan: true} //nolint:gosec // attempts are bounded by the search (<= 64)
	if res.Succeeded() {
		out.WinnerId = res.Best.Params.ID()
		out.WinnerDescribe = res.Best.Params.Describe()
		out.Score = res.Best.Score
		if b, ok := svc.Store.Lookup(fp); ok {
			out.BoundProfileId = b.ProfileID
			if b.ProfileID != "" {
				out.WinnerId = b.ProfileID
			}
		}
	}
	if s.logs != nil {
		s.logs.Write(time.Time{}, logs.LevelInfo, bypass.Source, res.Summary())
	}
	return out, nil
}

// desyncSessionProber measures one candidate the only honest way:
// live, through a probe session carrying exactly that strategy.
type desyncSessionProber struct {
	srv *Server
	// capabilityErr records the first host-capability refusal a
	// candidate hit, so the handler can name it when nothing worked.
	capabilityErr error
}

func (p *desyncSessionProber) Probe(ctx context.Context, params desync.Params) desync.ProbeReport {
	var rep desync.ProbeReport
	strat, ok := params.BypassStrategy()
	if !ok {
		return rep
	}
	// hopsToServer is honestly 0 — "not measured". Nothing in the
	// tree measures path length today (no traceroute or TTL probe in
	// core/probe or the diagnostics), so the fixed-TTL FakeTTL branch
	// of ResolveStrategy is NOT reachable from this production path:
	// autottl candidates keep their autottl form and nfqws calibrates
	// natively (--dpi-desync-autottl=<delta>:<min>-<max>). FakeTTL
	// runs for callers that DO hold a measured hop count, through
	// bypass.ArgsForTarget / bypass.NFQWSArgsForTarget. Narrowing the
	// contract here is deliberate: inventing a hop count to reach the
	// branch would ship fakes calibrated on a guess.
	resolved, ok, err := bypass.ResolveStrategy(strat, desync.BlockedCanary.SNI, 0)
	if err != nil || !ok {
		return rep
	}
	strat = resolved
	plan := &engine.Plan{
		SessionID:  "desync-probe",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Outbounds: []engine.Outbound{
			{ID: "desync-probe", Name: "desync probe", Protocol: engine.ProtocolBypass, Bypass: &strat},
		},
	}
	if _, err := p.srv.sessions.Connect(ctx, plan, session.Settings{}); err != nil {
		var ce *bypass.CapabilityError
		if errors.As(err, &ce) && p.capabilityErr == nil {
			p.capabilityErr = ce
		}
		return rep
	}
	defer func() { _ = p.srv.sessions.Disconnect(context.Background()) }()

	rep.ExtraPackets = stratExtraPackets(strat)
	if ok, latency, rst := p.handshake(ctx, desync.ControlCanary); ok {
		rep.ControlOK, rep.ControlLatency = true, latency
	} else if rst {
		rep.ControlRST = true
	}
	if ok, latency, _ := p.handshake(ctx, desync.BlockedCanary); ok {
		rep.BlockedOK, rep.BlockedLatency = true, latency
	}
	return rep
}

// handshake dials one canary through the engine's local SOCKS proxy
// and completes a TLS handshake with real certificate verification:
// the candidate only "works" if the handshake a browser would accept
// completes through it. The canary allowlist is enforced here, on the
// production path (desync.IsCanary): a target that is not one of the
// two sanctioned canaries is never dialled, whatever a future caller
// hands in — active probing fingerprints itself, so the prober's
// target set is closed by construction AND by this guard.
func (p *desyncSessionProber) handshake(ctx context.Context, canary desync.Canary) (ok bool, latency time.Duration, rst bool) {
	if !desync.IsCanary(canary) {
		return false, 0, false
	}
	dialer, err := proxy.SOCKS5("tcp", net.JoinHostPort("127.0.0.1", fmt.Sprintf("%d", p.srv.extProxyPort)), nil, proxy.Direct)
	if err != nil {
		return false, 0, false
	}
	start := time.Now()
	conn, err := dialer.Dial("tcp", net.JoinHostPort(canary.Host, fmt.Sprintf("%d", canary.Port)))
	if err != nil {
		return false, 0, isResetErr(err)
	}
	defer conn.Close()
	if deadline, has := ctx.Deadline(); has {
		_ = conn.SetDeadline(deadline)
	}
	tconn := tls.Client(conn, &tls.Config{ServerName: canary.SNI, MinVersion: tls.VersionTLS12})
	if err := tconn.HandshakeContext(ctx); err != nil {
		return false, 0, isResetErr(err)
	}
	return true, time.Since(start), false
}

func isResetErr(err error) bool {
	return err != nil && strings.Contains(err.Error(), "connection reset by peer")
}

// stratExtraPackets estimates the packets a strategy adds, for the
// fitness brevity term: one per split point, one for a fake, and the
// repeats multiplier on the fake.
func stratExtraPackets(s engine.BypassStrategy) int {
	n := len(s.SplitPos)
	if len(s.Desync) > 0 {
		n += len(s.Desync) - 1
	}
	for _, m := range s.Desync {
		if m == "fake" {
			n++
			if s.Repeats > 1 {
				n += s.Repeats - 1
			}
		}
	}
	if s.Disorder || s.OOB {
		n++
	}
	return n
}
