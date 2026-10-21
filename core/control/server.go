// Package control implements sora.core.v1, validates untrusted requests, and
// redacts responses. It checks versions, authentication, shape, and limits
// before work. Sessions and credentials remain in their manager and store
// across control-plane rebuilds.
package control

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"math"
	"runtime"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/durationpb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/ext"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	leakv1 "github.com/levvs-one/sora-client/core/gen/sora/leak/v1"
	"github.com/levvs-one/sora-client/core/ipc"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/parser"
	"github.com/levvs-one/sora-client/core/probe"
	"github.com/levvs-one/sora-client/core/profiles"
	"github.com/levvs-one/sora-client/core/routing"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

// sessionSettings derives system settings from the request. Bypass rules exempt
// private destinations; the guard owns the kill switch, and the user UI owns
// the system proxy.
func sessionSettings(req *corev1.ConnectRequest) session.Settings {
	in := req.GetSessionPlan()
	settings := session.Settings{TunnelMode: "system", KillSwitch: req.GetKillSwitch() || req.GetStrictKillSwitch(), StrictKillSwitch: req.GetStrictKillSwitch(), Reconnect: req.GetReconnect(), AllowLAN: in.GetBypassSettings().GetEnabled()}
	if in.GetTunnelMode() == corev1.TunnelMode_TUNNEL_MODE_APPLICATION {
		settings.TunnelMode = "application"
	}
	settings.Bypass = append([]string(nil), in.GetBypassSettings().GetRules()...)
	return settings
}

// SessionIDLen is the length of core-generated session identifiers and the
// bound used to validate client identifiers.
const SessionIDLen = 16

// maxSessionIDLen bounds client identifiers used in logs, events, and engine
// directory names.
const maxSessionIDLen = 64

// Version is the contract version the core serves.
type Version struct {
	Major             uint32
	Minor             uint32
	MinSupportedMinor uint32
}

// String returns the version for logging.
func (v Version) String() string {
	return strings.Join([]string{itoa(v.Major), itoa(v.Minor)}, ".")
}

// itoa formats a small unsigned number without fmt.
func itoa(v uint32) string {
	if v == 0 {
		return "0"
	}
	var buf [10]byte
	i := len(buf)
	for v > 0 {
		i--
		buf[i] = byte('0' + v%10)
		v /= 10
	}
	return string(buf[i:])
}

// Capabilities lists supported features so clients can hide unavailable
// settings.
func Capabilities() []string {
	return []string{
		"import-parse",
		"secret-store",
		"event-stream",
		"kill-switch",
		"stats",
		"engine-selection",
		"tls-fragment",
		"native-diagnostics",
		"log-center",
		"connection-center",
		"log-export-formats",
	}
}

// Measurer times requests through compatible engines. Unsupported outbounds
// return engine.ErrNoEngine.
type Measurer interface {
	Measure(ctx context.Context, outbounds []engine.Outbound, opts engine.MeasureOptions) (<-chan engine.Measurement, error)
}

// Benchmarker measures download throughput through compatible engines.
// Unsupported outbounds yield a done sample carrying engine.ErrNoEngine.
// Results stream out of Benchmark; sora keeps no stored history of its
// own (the app stores whatever it displays).
type Benchmarker interface {
	Benchmark(ctx context.Context, outbounds []engine.Outbound, opts engine.BandwidthOptions) (<-chan probe.BandwidthSample, error)
}

// Prober checks endpoint reachability. Implementations may dial directly or
// through a platform tunnel.
type Prober interface {
	Probe(ctx context.Context, endpoints []*corev1.Endpoint, serverIDs []string) (<-chan *corev1.ProbeResult, error)
}

// Diagnostics collects reports and archives, redacting both before returning
// them.
type Diagnostics interface {
	Run(ctx context.Context, status session.Status) ([]string, error)
	Export(ctx context.Context, status session.Status) ([]byte, error)
}

// Fetcher retrieves subscriptions using bearer references. Fetches allow only
// HTTPS, bound redirects and body size, and do not cache responses.
type Fetcher interface {
	Fetch(ctx context.Context, reference string, opts subscription.FetchOptions) (subscription.Result, error)
}

// Server implements the control-plane service.
type Server struct {
	corev1.UnimplementedCoreControlServer
	// LeakService serves the egress self-tests (core/control/leak.go).
	// See reports/featlog-swarm-sw2.md.
	leakv1.UnimplementedLeakServiceServer

	version  Version
	auth     *Authenticator
	sessions *session.Manager
	// extSched is the extension background scheduler (Config.ExtScheduler);
	// it follows the kill switch via syncExtKillSwitch.
	extSched *ext.Scheduler
	// extProxyPort is the loopback mixed-listener port backing
	// ExtFetchTransport (Config.LocalProxyPort).
	extProxyPort int
	secrets      SecretStore
	parser       parser.LinkParser
	redactors    *redactorCache
	prober       Prober
	measurer     Measurer
	subs         *subscriptionBook
	logs         *logs.Center
	about        func() *corev1.About
	diagnostics  Diagnostics
	fetcher      Fetcher
	dataDir      string
	benchmarker  Benchmarker
	// profiles stores network profiles for automatic matching. Nil
	// disables the profile RPCs with explicit errors.
	profiles  *profiles.Store
	captureMu sync.Mutex
}

// SecretStore exposes credential resolution, writes, deletion, and reference
// listing to the control plane.
type SecretStore interface {
	Get(reference string) ([]byte, error)
	Put(reference string, material []byte) error
	Delete(reference string) error
	// Apply stores puts and removes deletes in one write, all or nothing.
	Apply(puts map[string][]byte, deletes []string) error
	// Refs lists stored references used to locate core records.
	Refs() []string
}

// redactorCache keeps each session's credential-seeded redactor available after
// its plan is discarded, preventing unmasked responses.
type redactorCache struct {
	mu    sync.Mutex
	byRef map[string]*engine.Redactor
}

// Config configures the control plane. Only Sessions is required; missing
// optional components report unavailable features.
type Config struct {
	// Version is the contract version the core serves.
	Version Version
	// Authenticator checks the token on Connect and Disconnect.
	Authenticator *Authenticator
	// Sessions owns the tunnel lifecycle.
	Sessions *session.Manager
	// Secrets stores credentials. Nil disables import and secret methods
	// with explicit errors.
	Secrets SecretStore
	// MaxImportItems bounds one import.
	MaxImportItems int
	// Prober measures endpoints; nil answers that probing is unavailable.
	Prober Prober
	// Measurer times real requests through engines; nil leaves only the
	// connection check.
	Measurer Measurer
	// Logs is the log center; nil answers that the core keeps no record.
	Logs *logs.Center
	// About describes the build of the core for the "About" screen; the
	// contract version is filled in here.
	About func() *corev1.About
	// Diagnostics collects reports and archives; nil answers that the
	// feature is
	// unavailable.
	Diagnostics Diagnostics
	// Fetcher retrieves subscriptions; nil answers that fetching is
	// unavailable.
	Fetcher Fetcher
	// DataDir is the owner-only core data directory. Empty disables
	// features that persist files (benchmark history, overrides).
	DataDir string
	// Benchmarker measures server throughput; nil answers that
	// benchmarking is unavailable.
	Benchmarker Benchmarker
	// Profiles stores network profiles for automatic matching; nil
	// disables the profile RPCs with explicit errors.
	Profiles *profiles.Store
	// ExtScheduler is the extension background-work scheduler (core/ext).
	// The control plane forwards the kill switch to it so background
	// extension work pauses while traffic is blocked. Nil means no
	// extension scheduler runs in this process (tests, diagnostics).
	ExtScheduler *ext.Scheduler
	// LocalProxyPort is the loopback port of the tunnel's mixed
	// (HTTP+SOCKS5) listener - the port supervise gives every engine.
	// Extension net.fetch rides it when the session plan enables the
	// local proxy (see Server.ExtFetchTransport). Zero disables the
	// tunnel transport: extension fetches then fail closed.
	LocalProxyPort int
}

// New creates a control plane, supplying the default version when unset.
func New(cfg Config) (*Server, error) {
	if cfg.Sessions == nil {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"control: no session manager")
	}
	if cfg.Authenticator == nil {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyUnauthenticated,
			"control: no authenticator")
	}
	if cfg.Version.Major == 0 {
		cfg.Version = Version{Major: 1, Minor: 0, MinSupportedMinor: 0}
	}
	server := &Server{
		version:      cfg.Version,
		auth:         cfg.Authenticator,
		sessions:     cfg.Sessions,
		secrets:      cfg.Secrets,
		parser:       parser.LinkParser{MaxItems: cfg.MaxImportItems},
		redactors:    &redactorCache{byRef: make(map[string]*engine.Redactor)},
		extSched:     cfg.ExtScheduler,
		extProxyPort: cfg.LocalProxyPort,
		prober:       cfg.Prober,
		measurer:     cfg.Measurer,
		logs:         cfg.Logs,
		about:        cfg.About,
		diagnostics:  cfg.Diagnostics,
		fetcher:      cfg.Fetcher,
		dataDir:      cfg.DataDir,
		benchmarker:  cfg.Benchmarker,
		profiles:     cfg.Profiles,
	}
	server.subs = newSubscriptionBook(server)
	return server, nil
}

// GetAbout returns core build information for the client's About screen.
func (s *Server) GetAbout(_ context.Context, req *corev1.GetAboutRequest) (*corev1.GetAboutResponse, error) {
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if s.about == nil {
		err := errs.Newf(errs.CodeUnsupported, errs.KeyInternal, "control: this core does not describe its build")
		return &corev1.GetAboutResponse{Error: toWire(err, nil, "")}, nil
	}
	about := s.about()
	about.Contract = s.apiVersion()
	return &corev1.GetAboutResponse{About: about}, nil
}

// GetRoutingPresets returns presets and their direct destinations in plan
// routing syntax.
func (s *Server) GetRoutingPresets(_ context.Context, req *corev1.GetRoutingPresetsRequest) (*corev1.GetRoutingPresetsResponse, error) {
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	out := &corev1.GetRoutingPresetsResponse{}
	for _, preset := range routing.Presets() {
		wire := &corev1.RoutingPreset{Id: preset.ID}
		for _, rule := range preset.Direct {
			wire.Direct = append(wire.Direct, string(rule.Type)+":"+rule.Value)
		}
		out.Presets = append(out.Presets, wire)
	}
	return out, nil
}

// Run updates subscriptions on schedule until ctx ends.
func (s *Server) Run(ctx context.Context) { s.subs.run(ctx) }

// SetDiagnostics attaches the collector during construction, after its session
// and engine dependencies exist. Call it before serving requests; concurrent
// calls are unsafe.
func (s *Server) SetDiagnostics(collector Diagnostics) {
	s.diagnostics = collector
}

// apiVersion returns the core's wire API version.
func (s *Server) apiVersion() *corev1.ApiVersion {
	capabilities := Capabilities()
	if s.version.Minor >= 12 && (runtime.GOOS == "linux" || runtime.GOOS == "windows") {
		capabilities = append(capabilities, "strict-kill-switch")
	}
	if provider, ok := s.measurer.(interface{ BypassAvailable() bool }); ok && provider.BypassAvailable() {
		capabilities = append(capabilities, "serverless")
	}
	if len(chainEngines(s.measurer)) > 0 {
		capabilities = append(capabilities, "chains")
	}
	return &corev1.ApiVersion{
		Major:             s.version.Major,
		Minor:             s.version.Minor,
		MinSupportedMinor: s.version.MinSupportedMinor,
		Capabilities:      capabilities,
	}
}

// checkVersion rejects incompatible clients and includes both versions in the
// error.
func (s *Server) checkVersion(client *corev1.ApiVersion) (uint32, error) {
	if client == nil {
		return 0, errs.Newf(errs.CodeVersionMismatch, errs.KeyAPIVersionMismatch,
			"control: the request carries no api version")
	}
	negotiated, err := Negotiate(client, s.apiVersion())
	if err != nil {
		return 0, errs.Newf(errs.CodeVersionMismatch, errs.KeyAPIVersionMismatch,
			"control: the client speaks %d.%d, the core speaks %s",
			client.GetMajor(), client.GetMinor(), s.version)
	}
	return negotiated, nil
}

// requestID returns the client's identifier or generates one for log
// correlation.
func requestID(sent string) string {
	if trimmed := strings.TrimSpace(sent); trimmed != "" {
		return trimmed
	}
	var buf [8]byte
	if _, err := rand.Read(buf[:]); err != nil {
		return ""
	}
	return "req_" + hex.EncodeToString(buf[:])
}

// newSessionID generates or validates a session identifier. Client identifiers
// use a bounded opaque alphabet because they appear in logs, events, and paths.
func newSessionID(proposed string) (string, error) {
	trimmed := strings.TrimSpace(proposed)
	if trimmed == "" {
		var buf [SessionIDLen]byte
		if _, err := rand.Read(buf[:]); err != nil {
			return "", errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
		}
		return "s_" + hex.EncodeToString(buf[:]), nil
	}
	if len(trimmed) > maxSessionIDLen {
		return "", errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: the session id is longer than %d bytes", maxSessionIDLen)
	}
	for i := range len(trimmed) {
		c := trimmed[i]
		switch {
		case c >= 'a' && c <= 'z', c >= 'A' && c <= 'Z', c >= '0' && c <= '9', c == '-', c == '_':
		default:
			return "", errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
				"control: the session id has an unsupported character at %d", i)
		}
	}
	return trimmed, nil
}

// mask returns a plan redactor or nil without a plan. It masks credentials and
// server identifiers in errors and events.
func (s *Server) mask(plan *engine.Plan) func(string) string {
	if plan == nil {
		return nil
	}
	// Feed the two lists to the redactor separately instead of joining
	// them into a third slice first: for a 200-server plan the join
	// regrew and copied ~1400 strings (~26 KB) per Connect. Two Add
	// calls build the identical value set - Add deduplicates across
	// calls and its length-descending stable sort produces the same
	// final order, because the secrets-before-identifiers relative
	// order within each length class is preserved by both sorts.
	redactor := engine.NewRedactor(plan.Secrets()...)
	redactor.Add(plan.Identifiers()...)
	s.redactors.put(plan.SessionID, redactor)
	return redactor.String
}

// put caches a session redactor for responses after the plan is discarded.
func (c *redactorCache) put(sessionID string, redactor *engine.Redactor) {
	if sessionID == "" {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if len(c.byRef) >= maxCachedRedactors {
		// Clear the cache at the bound to limit memory across repeated
		// sessions.
		clear(c.byRef)
	}
	c.byRef[sessionID] = redactor
}

// get returns the redactor of a session, or nil.
func (c *redactorCache) get(sessionID string) *engine.Redactor {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.byRef[sessionID]
}

// drop forgets the redactor of a session that has ended.
func (c *redactorCache) drop(sessionID string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	delete(c.byRef, sessionID)
}

// maxCachedRedactors limits memory usage across sessions in a long-running
// core.
const maxCachedRedactors = 8

// wireStateValue maps session states to the contract. Unknown states fall back
// to disconnected instead of exposing an invalid enum.
func wireStateValue(state session.State) corev1.ConnectionStateValue {
	switch state {
	case session.StateDisconnected:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_DISCONNECTED
	case session.StateConnecting:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTING
	case session.StateConnected:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED
	case session.StateReconnecting:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_RECONNECTING
	case session.StateFailed:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_FAILED
	default:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_DISCONNECTED
	}
}

// wireStatus converts session status to the wire format.
func wireStatus(status session.Status) *corev1.ConnectionState {
	out := &corev1.ConnectionState{
		Value:      wireStateValue(status.State),
		SessionId:  status.SessionID,
		ChangedAt:  timestampOrNil(status.ChangedAt),
		RetryAfter: durationOrNil(status.RetryAfter),
	}
	if code, ok := wireCodes[status.Reason]; ok {
		out.Reason = code
	}
	return out
}

// requestDeadline preserves the request deadline or supplies a default to bound
// session operations.
func requestDeadline(ctx context.Context, fallback time.Duration) (context.Context, context.CancelFunc) {
	if _, ok := ctx.Deadline(); ok {
		return ctx, func() {}
	}
	return context.WithTimeout(ctx, fallback)
}

// Default deadlines bound system changes when clients omit a deadline.
const (
	connectTimeout    = 30 * time.Second
	disconnectTimeout = 15 * time.Second
	guardTimeout      = 10 * time.Second
	statsTimeout      = 5 * time.Second
	importTimeout     = 60 * time.Second
)

// Shared transport limits keep client and server message bounds consistent with
// plan limits.
const (
	// MaxRecvMsgBytes limits requests to the plan limit plus its message
	// envelope.
	MaxRecvMsgBytes = MaxPlanBytes + (1 << 20)
	// MaxSendMsgBytes limits responses, allowing the collector's bounded
	// log export plus its envelope.
	MaxSendMsgBytes = logs.MaxExportBytes + (1 << 20)
)

// Handshake negotiates the API version without a token so clients can
// initialize. Incompatible clients still receive the core's version to
// determine the required update. The control token is issued only to
// control-authorized peers; read-only peers never receive it, so the token
// cannot smuggle control rights past the method checks.
func (s *Server) Handshake(ctx context.Context, req *corev1.HandshakeRequest) (*corev1.HandshakeResponse, error) {
	negotiated, err := s.checkVersion(req.GetClientVersion())
	if err != nil {
		return &corev1.HandshakeResponse{
			NegotiatedVersion: s.apiVersion(),
			Error:             toWire(err, nil, ""),
		}, nil
	}
	answer := s.apiVersion()
	answer.Minor = negotiated
	resp := &corev1.HandshakeResponse{NegotiatedVersion: answer}
	if peerLevel(ctx) == ipc.AuthControl {
		resp.ControlAuthenticator = s.auth.Token()
	}
	return resp, nil
}

// Connect starts a session after checking version, authentication, limits, and
// plan validity. Failed checks leave the current session and system settings
// unchanged.
func (s *Server) Connect(ctx context.Context, req *corev1.ConnectRequest) (*corev1.ConnectResponse, error) {
	if req.GetStrictKillSwitch() && (s.version.Minor < 12 || req.GetApiVersion().GetMinor() < 12 || (runtime.GOOS != "linux" && runtime.GOOS != "windows")) {
		return nil, transportStatus(errs.Newf(errs.CodeVersionMismatch, errs.KeyAPIVersionMismatch, "control: strict mode needs API 1.12 on Linux or Windows"))
	}

	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.auth.Check(req.GetControlAuthenticator()); err != nil {
		return nil, transportStatus(err)
	}
	if size := proto.Size(req.GetSessionPlan()); size > MaxPlanBytes {
		err := errs.Newf(errs.CodeResourceExhausted, errs.KeyPlanTooLarge,
			"control: the plan is %d bytes, the limit is %d", size, MaxPlanBytes)
		return &corev1.ConnectResponse{Error: toWire(err, nil, id)}, nil
	}
	sessionID, err := newSessionID(req.GetSessionId())
	if err != nil {
		return &corev1.ConnectResponse{Error: toWire(err, nil, id)}, nil
	}
	plan, err := planFromProto(req.GetSessionPlan(), sessionID, s.secrets)
	if err != nil {
		return &corev1.ConnectResponse{Error: toWire(err, nil, id)}, nil
	}
	mask := s.mask(plan)

	ctx, cancel := requestDeadline(ctx, connectTimeout)
	defer cancel()
	started, err := s.sessions.Connect(ctx, plan, sessionSettings(req))
	if err != nil {
		return &corev1.ConnectResponse{Error: toWire(err, mask, id)}, nil
	}
	// A session can start with the kill switch already armed (restored
	// settings): background extension work must start out paused too.
	s.syncExtKillSwitch(started.Status().KillSwitch)
	return &corev1.ConnectResponse{
		Status: &corev1.SessionStatus{
			Connection:        wireStatus(started.Status()),
			NegotiatedVersion: s.apiVersion(),
			KillSwitch:        s.sessions.Status().KillSwitch, StrictKillSwitch: s.sessions.Status().StrictKillSwitch,
		},
	}, nil
}

// Disconnect stops the running session. Requests naming another session are
// rejected to avoid stopping another client's tunnel.
func (s *Server) Disconnect(ctx context.Context, req *corev1.DisconnectRequest) (*corev1.DisconnectResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.auth.Check(req.GetControlAuthenticator()); err != nil {
		return nil, transportStatus(err)
	}
	if wanted := strings.TrimSpace(req.GetSessionId()); wanted != "" {
		running := s.sessions.Current()
		if (running == nil && !s.sessions.Status().StrictKillSwitch) || (running != nil && running.ID() != wanted) {
			err := errs.Newf(errs.CodeNotFound, errs.KeyUnknownSession,
				"control: the request names a session that is not running")
			return &corev1.DisconnectResponse{Error: toWire(err, nil, id)}, nil
		}
	}
	ctx, cancel := requestDeadline(ctx, disconnectTimeout)
	defer cancel()
	if err := s.sessions.Disconnect(ctx); err != nil {
		return &corev1.DisconnectResponse{
			Status: &corev1.SessionStatus{Connection: wireStatus(s.sessions.Status())},
			Error:  toWire(err, nil, id),
		}, nil
	}
	if finished := s.sessions.Status().SessionID; finished != "" {
		s.redactors.drop(finished)
	}
	// The session is gone: mirror the manager's kill-switch state (an armed
	// switch stays armed across disconnects). Extension fetches stay
	// fail-closed regardless - the tunnel transport finds no live session
	// and refuses instead of dialing direct.
	s.syncExtKillSwitch(s.sessions.Status().KillSwitch)
	return &corev1.DisconnectResponse{
		Status: &corev1.SessionStatus{Connection: wireStatus(s.sessions.Status())},
	}, nil
}

// GetStatus returns session state and API version. Requests naming a different
// session are rejected.
func (s *Server) GetStatus(_ context.Context, req *corev1.GetStatusRequest) (*corev1.GetStatusResponse, error) {
	id := requestID("")
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.GetStatusResponse{
			Status: &corev1.SessionStatus{
				Connection:        wireStatus(session.Status{}),
				NegotiatedVersion: s.apiVersion(),
				KillSwitch:        s.sessions.Status().KillSwitch, StrictKillSwitch: s.sessions.Status().StrictKillSwitch,
			},
			Error: toWire(err, nil, id),
		}, nil
	}
	status := s.sessions.Status()
	return &corev1.GetStatusResponse{Status: &corev1.SessionStatus{
		Connection:        wireStatus(status),
		NegotiatedVersion: s.apiVersion(),
		KillSwitch:        s.sessions.Status().KillSwitch, StrictKillSwitch: s.sessions.Status().StrictKillSwitch,
	}}, nil
}

// checkSession rejects requests naming a different running session. Empty
// identifiers accept the current session, as allowed by the contract.
func (s *Server) checkSession(named string) error {
	wanted := strings.TrimSpace(named)
	if wanted == "" {
		return nil
	}
	running := s.sessions.Current()
	if running == nil || running.ID() != wanted {
		return errs.Newf(errs.CodeNotFound, errs.KeyUnknownSession,
			"control: the request names a session that is not running")
	}
	return nil
}

// SetKillSwitch arms or disarms the kill switch of the running session.
func (s *Server) SetKillSwitch(ctx context.Context, req *corev1.SetKillSwitchRequest) (*corev1.SetKillSwitchResponse, error) {
	if req.GetStrict() && (s.version.Minor < 12 || req.GetApiVersion().GetMinor() < 12) {
		return nil, transportStatus(errs.Newf(errs.CodeVersionMismatch, errs.KeyAPIVersionMismatch, "control: strict mode needs API 1.12"))
	}

	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}

	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.SetKillSwitchResponse{Error: toWire(err, nil, id)}, nil
	}
	ctx, cancel := requestDeadline(ctx, guardTimeout)
	defer cancel()
	if err := s.sessions.SetProtection(ctx, req.GetEnabled(), req.Strict); err != nil {
		return &corev1.SetKillSwitchResponse{Enabled: s.sessions.Status().KillSwitch, Strict: s.sessions.Status().StrictKillSwitch, Error: toWire(err, nil, id)}, nil
	}
	// Background extension work follows the kill switch: while traffic is
	// blocked, workers must not run and their fetches must fail fast.
	s.syncExtKillSwitch(s.sessions.Status().KillSwitch)
	return &corev1.SetKillSwitchResponse{Enabled: s.sessions.Status().KillSwitch, Strict: s.sessions.Status().StrictKillSwitch}, nil
}

// syncExtKillSwitch mirrors the session's kill-switch state into the
// extension scheduler. It is called on Connect (a session may start with
// the switch already armed) and on every SetKillSwitch change. Nil-safe:
// without a scheduler there is nothing to pause.
func (s *Server) syncExtKillSwitch(armed bool) {
	if s.extSched != nil {
		s.extSched.SetKillSwitch(armed)
	}
}

// GetStats returns session traffic counters. With no session, it returns zero
// counters without an error.
func (s *Server) GetStats(ctx context.Context, req *corev1.GetStatsRequest) (*corev1.GetStatsResponse, error) {
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.GetStatsResponse{
			Stats: &corev1.StatsTick{},
			Error: toWire(err, nil, ""),
		}, nil
	}
	running := s.sessions.Current()
	if running == nil {
		return &corev1.GetStatsResponse{Stats: &corev1.StatsTick{}}, nil
	}
	ctx, cancel := requestDeadline(ctx, statsTimeout)
	defer cancel()
	counters, err := running.Counters(ctx)
	if err != nil {
		var mask func(string) string
		if redactor := s.redactors.get(running.ID()); redactor != nil {
			mask = redactor.String
		}
		return &corev1.GetStatsResponse{
			Stats: &corev1.StatsTick{},
			Error: toWire(err, mask, ""),
		}, nil
	}
	return &corev1.GetStatsResponse{Stats: &corev1.StatsTick{
		BytesUp:           counters.BytesUp,
		BytesDown:         counters.BytesDown,
		ActiveConnections: counter(counters.ActiveConnections),
	}}, nil
}

// WatchEvents subscribes before replaying history up to the journal head, then
// streams live events. Sequence deduplication prevents gaps and repeats across
// replay and reconnects.
func (s *Server) WatchEvents(req *corev1.WatchEventsRequest, stream grpc.ServerStreamingServer[corev1.CoreEvent]) error {
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return transportStatus(err)
	}
	ctx := stream.Context()
	running := s.sessions.Current()
	if running == nil {
		// End the stream immediately when there is no session.
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"control: there is no session to watch")
	}
	if wanted := strings.TrimSpace(req.GetSessionId()); wanted != "" && wanted != running.ID() {
		return errs.Newf(errs.CodeNotFound, errs.KeyUnknownSession,
			"control: the request names a session that is not running")
	}
	feed := newEventFeed(running.Journal(), req.GetAfterSequence(), s.redactors.get(running.ID()))
	defer feed.close()

	for _, event := range feed.history() {
		if err := stream.Send(toWireEvent(event, feed.redactor)); err != nil {
			return err
		}
	}
	for {
		select {
		case <-ctx.Done():
			return nil
		case event, ok := <-feed.live:
			if !ok {
				return nil
			}
			if !feed.unsent(event) {
				continue
			}
			if err := stream.Send(toWireEvent(event, feed.redactor)); err != nil {
				return err
			}
		}
	}
}

// eventFeed coordinates journal replay and live delivery with
// subscription-first ordering and sequence deduplication.
type eventFeed struct {
	journal     *session.Journal
	redactor    *engine.Redactor
	live        <-chan session.Event
	unsubscribe func()
	after       uint64
	head        uint64
}

// newEventFeed subscribes to the journal and remembers where the history ends.
func newEventFeed(journal *session.Journal, after uint64, redactor *engine.Redactor) *eventFeed {
	live, unsubscribe := journal.Subscribe(streamBuffer)
	feed := &eventFeed{
		journal:     journal,
		redactor:    redactor,
		live:        live,
		unsubscribe: unsubscribe,
		after:       after,
	}
	// Read the head after subscribing so replay and live delivery cover
	// every event.
	feed.head = journal.Latest()
	return feed
}

// history returns events after the client's cursor through the head captured at
// subscription.
func (f *eventFeed) history() []session.Event {
	events := f.journal.Since(f.after, 0)
	// The usual case - no event in the window sits above the captured
	// head - returns the journal's fresh slice as is instead of copying
	// every (large) Event into a second slice of the same size: a full
	// 512-event replay paid that copy on every WatchEvents reconnect.
	for _, event := range events {
		if event.Sequence > f.head {
			// Events above the captured head already belong to live
			// delivery.
			out := make([]session.Event, 0, len(events))
			for _, kept := range events {
				if kept.Sequence > f.head {
					continue
				}
				out = append(out, kept)
			}
			return out
		}
	}
	return events
}

// unsent reports whether a live event still has to go out. One appended
// between the subscription and the head read reaches the live queue and the
// replay both; the replay already sent it.
func (f *eventFeed) unsent(event session.Event) bool {
	return event.Sequence > f.head && event.Sequence > f.after
}

// close releases the subscription.
func (f *eventFeed) close() {
	if f.unsubscribe != nil {
		f.unsubscribe()
	}
}

// streamBuffer bounds each subscriber's queue to contract batch limits. Slow
// clients lose events without unbounded memory growth.
const streamBuffer = 128

// NetworkEventPrefix marks LogBatch lines that carry a network-move event
// (session.EventNetwork). The client matches this prefix to surface the
// connection state while flows re-establish.
const NetworkEventPrefix = "network-changed: "

func toWireEvent(event session.Event, redactor *engine.Redactor) *corev1.CoreEvent {
	var mask func(string) string
	if redactor != nil {
		mask = redactor.String
	}
	out := &corev1.CoreEvent{
		Sequence:  event.Sequence,
		SessionId: "",
		EmittedAt: timestampOrNil(event.At),
	}
	switch event.Kind {
	case session.EventState:
		out.Payload = &corev1.CoreEvent_StateChanged{StateChanged: &corev1.StateChanged{
			State: &corev1.ConnectionState{
				Value:      wireStateValue(event.State),
				Reason:     reasonCode(event.Reason),
				ChangedAt:  timestampOrNil(event.At),
				RetryAfter: durationOrNil(event.RetryAfter),
			},
		}}
	case session.EventCounters:
		out.Payload = &corev1.CoreEvent_StatsTick{StatsTick: &corev1.StatsTick{
			BytesUp:           event.Counters.BytesUp,
			BytesDown:         event.Counters.BytesDown,
			ActiveConnections: counter(event.Counters.ActiveConnections),
		}}
	case session.EventLog:
		out.Payload = &corev1.CoreEvent_LogBatch{LogBatch: &corev1.LogBatch{
			Lines: []string{maskText(mask, event.LogLine)},
		}}
	case session.EventProbe:
		probe := &corev1.ProbeResult{}
		if event.Probe != nil {
			probe.ServerId = event.Probe.ServerID
			probe.Reachable = event.Probe.Reachable
			probe.LatencyMs = latency(event.Probe.LatencyMS)
		}
		probe.Error = toWire(errOrNil(event), mask, "")
		out.Payload = &corev1.CoreEvent_ProbeResult{ProbeResult: probe}
	case session.EventError:
		out.Payload = &corev1.CoreEvent_Error{Error: toWire(errOrNil(event), mask, "")}
	case session.EventGroup:
		moved := &corev1.GroupSwitched{}
		if event.Switch != nil {
			moved.Group, moved.Previous, moved.Selected = event.Switch.Group, event.Switch.Previous, event.Switch.Selected
		}
		out.Payload = &corev1.CoreEvent_GroupSwitched{GroupSwitched: moved}
	case session.EventNetwork:
		// Network moves surface as a marked log line; the client matches
		// NetworkEventPrefix to show the connection state.
		out.Payload = &corev1.CoreEvent_LogBatch{LogBatch: &corev1.LogBatch{
			Lines: []string{NetworkEventPrefix + maskText(mask, event.Detail)},
		}}
	case session.EventProfile:
		// A saved network profile matched the current network; the client
		// applies it.
		matched := &corev1.ProfileMatched{}
		if event.Profile != nil {
			matched.ProfileId = event.Profile.ProfileID
			matched.ProfileName = event.Profile.Name
			matched.AutoApply = event.Profile.AutoApply
		}
		out.Payload = &corev1.CoreEvent_ProfileMatched{ProfileMatched: matched}
	default:
		out.Payload = &corev1.CoreEvent_LogBatch{LogBatch: &corev1.LogBatch{
			Lines: []string{maskText(mask, event.Detail)},
		}}
	}
	return out
}

// reasonCode maps an event's error class to the contract, or returns no cause.
func reasonCode(reason errs.Code) corev1.SoraErrorCode {
	if code, ok := wireCodes[reason]; ok {
		return code
	}
	return corev1.SoraErrorCode_SORA_ERROR_CODE_UNSPECIFIED
}

// errOrNil reconstructs an event error so toWire applies the same redaction and
// key handling as for responses.
func errOrNil(event session.Event) error {
	if event.Key == "" && event.Reason == "" {
		return nil
	}
	return errs.New(event.Reason, event.Key, nil).WithDetail(event.Detail)
}

// maskText applies a masking function when there is one.
func maskText(mask func(string) string, text string) string {
	if mask == nil {
		return text
	}
	return mask(text)
}

// ParseImport parses a subscription into a plan with credential references.
// Credentials go directly to the vault; failed parsing leaves the store
// unchanged.
func (s *Server) ParseImport(_ context.Context, req *corev1.ParseImportRequest) (*corev1.ParseImportResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	payload := req.GetPayload()
	if len(payload) == 0 {
		err := errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionEmpty,
			"control: the import payload is empty")
		return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
	}
	if len(payload) > MaxImportBytes {
		err := errs.Newf(errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge,
			"control: the import payload is %d bytes, the limit is %d", len(payload), MaxImportBytes)
		return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.secrets == nil {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
			"control: this core cannot store credentials, so it cannot import")
		return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
	}
	servers, err := s.parsePayload(payload, referenceOf)
	if err != nil {
		return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
	}
	puts := make(map[string][]byte, len(servers))
	plan := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		// One outbound per imported server: size for them up front.
		Outbounds: make([]*corev1.OutboundSpec, 0, len(servers)),
	}
	for _, server := range servers {
		puts[server.reference] = server.document
		plan.Outbounds = append(plan.Outbounds, server.spec)
	}
	if err := s.secrets.Apply(puts, nil); err != nil {
		return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
	}
	// Routing remains client-defined because only the imported outbounds
	// are known here.
	return &corev1.ParseImportResponse{SessionPlan: plan}, nil
}

// importedServer is one parsed server, ready for the vault.
type importedServer struct {
	spec      *corev1.OutboundSpec
	reference string
	document  []byte
}

// parsePayload detects the format before parsing, rejecting unknown input
// instead of returning an empty import. It prepares servers without writing;
// refFor supplies vault references for one atomic update.
func (s *Server) parsePayload(payload []byte, refFor func(parser.OutboundSpec) (string, error)) ([]importedServer, error) {
	if _, err := (parser.ImportDetector{MaxItems: s.parser.MaxItems}).Detect(payload); err != nil {
		return nil, importError(err)
	}
	result, err := s.parser.Parse(payload)
	if err != nil {
		return nil, importError(err)
	}
	if len(result.Servers) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionNoServers,
			"control: the payload produced no usable server")
	}
	out := make([]importedServer, 0, len(result.Servers))
	for _, server := range result.Servers {
		reference, err := refFor(server)
		if err != nil {
			return nil, err
		}
		document, err := credentialDocument(server)
		if err != nil {
			return nil, err
		}
		out = append(out, importedServer{spec: outboundToProto(server, reference), reference: reference, document: document})
	}
	return out, nil
}

// importError maps parser sentinel errors to catalog errors at the control
// boundary.
func importError(err error) error {
	switch {
	case errors.Is(err, parser.ErrEmptySource):
		return errs.Wrap(err, errs.CodeInvalidArgument, errs.KeySubscriptionEmpty)
	case errors.Is(err, parser.ErrInputTooLarge):
		return errs.Wrap(err, errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge)
	case errors.Is(err, parser.ErrUnsupported):
		return errs.Wrap(err, errs.CodeUnsupported, errs.KeySubscriptionFormat)
	default:
		return errs.Wrap(err, errs.CodeInvalidArgument, errs.KeySubscriptionFormat)
	}
}

// PutSecret stores one piece of credential material under a reference.
func (s *Server) PutSecret(_ context.Context, req *corev1.PutSecretRequest) (*corev1.PutSecretResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	reference := req.GetCredentials().GetReference()
	if err := secret.ValidateReference(reference); err != nil {
		return &corev1.PutSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.secrets == nil {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
			"control: this core has no secret store")
		return &corev1.PutSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	if err := s.secrets.Put(reference, req.GetMaterial()); err != nil {
		return &corev1.PutSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	return &corev1.PutSecretResponse{Credentials: req.GetCredentials()}, nil
}

// DeleteSecret removes stored material and succeeds for missing references.
func (s *Server) DeleteSecret(_ context.Context, req *corev1.DeleteSecretRequest) (*corev1.DeleteSecretResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := secret.ValidateReference(req.GetCredentials().GetReference()); err != nil {
		return &corev1.DeleteSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.secrets == nil {
		return &corev1.DeleteSecretResponse{}, nil
	}
	if err := s.secrets.Delete(req.GetCredentials().GetReference()); err != nil {
		return &corev1.DeleteSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	return &corev1.DeleteSecretResponse{}, nil
}

// FetchSubscription fetches servers with credentials stored as references. The
// subscription reference is a bearer token and is never logged, returned, or
// used in filenames.
func (s *Server) FetchSubscription(ctx context.Context, req *corev1.FetchSubscriptionRequest) (*corev1.FetchSubscriptionResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if s.fetcher == nil {
		err := errs.Newf(errs.CodeUnsupported, errs.KeySubscriptionFetch,
			"control: this core cannot fetch subscriptions over the network")
		return &corev1.FetchSubscriptionResponse{Error: toWire(err, nil, id)}, nil
	}
	ctx, cancel := requestDeadline(ctx, importTimeout)
	defer cancel()
	fetched, err := s.fetcher.Fetch(ctx, req.GetReference(), subscription.FetchOptions{UserAgent: req.GetUserAgent()})
	if err != nil {
		return &corev1.FetchSubscriptionResponse{Error: toWire(err, nil, id)}, nil
	}
	// Reuse import validation and storage, but return the server list
	// required by fetch.
	imported, importErr := s.ParseImport(ctx, &corev1.ParseImportRequest{
		ApiVersion: req.GetApiVersion(),
		RequestId:  req.GetRequestId(),
		Payload:    fetched.Body,
	})
	if importErr != nil {
		return nil, importErr
	}
	if imported.GetError() != nil {
		return &corev1.FetchSubscriptionResponse{Error: imported.GetError()}, nil
	}
	return &corev1.FetchSubscriptionResponse{
		Outbounds: imported.GetSessionPlan().GetOutbounds(),
		Info:      subscriptionInfoToWire(fetched.Info),
	}, nil
}

func subscriptionInfoToWire(info subscription.Info) *corev1.SubscriptionInfo {
	out := &corev1.SubscriptionInfo{
		Title: info.Title, HasUsage: info.HasUsage,
		UploadBytes: info.Upload, DownloadBytes: info.Download, TotalBytes: info.Total,
		WebPageUrl: info.WebPageURL, SupportUrl: info.SupportURL, Announce: info.Announce,
	}
	if info.UpdateInterval > 0 {
		out.UpdateInterval = durationpb.New(info.UpdateInterval)
	}
	if !info.Expire.IsZero() {
		out.Expire = timestamppb.New(info.Expire)
	}
	return out
}

// ProbeServers streams results using the stream context. Endpoints use TCP;
// outbounds use a compatible engine with optional TCP fallback. Each result
// identifies its method.
//
// Large probes are chunked: the request is processed in ProbeChunkSize
// pieces and each chunk's results stream as they complete, so probing
// thousands of servers degrades into a longer stream instead of dying on a
// per-request limit. A failing chunk does not abort the others: the first
// chunk error is remembered, the remaining chunks still run, and the RPC
// then returns that error (mapped through transportStatus, as before) -
// partial results, no silent loss.
func (s *Server) ProbeServers(req *corev1.ProbeServersRequest, stream grpc.ServerStreamingServer[corev1.ProbeResult]) error {
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return transportStatus(err)
	}
	ctx, cancel := context.WithCancel(stream.Context())
	defer cancel()
	id := requestID(req.GetRequestId())
	endpoints := req.GetEndpoints()
	outbounds := req.GetOutbounds()
	total := len(endpoints) + len(outbounds)
	if total == 0 {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeNoEndpoints,
			"control: the probe request carries no endpoints")
	}
	if total > MaxProbeEndpoints {
		return errs.Newf(errs.CodeResourceExhausted, errs.KeyProbeTooMany,
			"control: the probe request carries %d servers, the limit is %d; split it into chunks of at most %d",
			total, MaxProbeEndpoints, ProbeChunkSize)
	}

	results := make(chan *corev1.ProbeResult, total)
	var wg sync.WaitGroup
	connect := func(endpoints []*corev1.Endpoint, ids []string) error {
		if len(endpoints) == 0 {
			return nil
		}
		if s.prober == nil {
			return errs.Newf(errs.CodeUnsupported, errs.KeyProbeInvalidEndpoint,
				"control: this core cannot probe endpoints")
		}
		found, err := s.prober.Probe(ctx, endpoints, ids)
		if err != nil {
			return err
		}
		wg.Add(1)
		go func() {
			defer wg.Done()
			for r := range found {
				r.Method = probeConnect
				results <- r
			}
		}()
		return nil
	}

	// note remembers the first chunk failure; the remaining chunks still
	// run so one bad piece does not sink the whole probe.
	var firstErr error
	note := func(err error) {
		if err != nil && firstErr == nil {
			firstErr = err
		}
	}
	opts := req.GetOptions()
	for _, chunk := range chunkServers(endpoints, ProbeChunkSize) {
		if ctx.Err() != nil {
			break
		}
		note(connect(chunk, nil))
	}
	for _, chunk := range chunkServers(outbounds, ProbeChunkSize) {
		if ctx.Err() != nil {
			break
		}
		note(s.measureOutbounds(ctx, opts, chunk, id, results, &wg, connect))
	}
	go func() {
		wg.Wait()
		close(results)
	}()
	for result := range results {
		if err := stream.Send(result); err != nil {
			return err
		}
	}
	if firstErr != nil {
		return transportStatus(firstErr)
	}
	return nil
}

// chunkServers splits xs into consecutive pieces of at most size. Empty
// input yields no pieces, so empty chunks never reach the pipeline.
func chunkServers[T any](xs []T, size int) [][]T {
	if size <= 0 || len(xs) == 0 {
		return nil
	}
	chunks := make([][]T, 0, (len(xs)+size-1)/size)
	for i := 0; i < len(xs); i += size {
		end := i + size
		if end > len(xs) {
			end = len(xs)
		}
		chunks = append(chunks, xs[i:end])
	}
	return chunks
}

// Probe methods as the results name them.
const (
	probeEngine  = "engine"
	probeConnect = "connect"
)

// measureOutbounds resolves one chunk of outbounds of a probe request and
// measures them through engines, falling back to a connection check where
// the options allow.
func (s *Server) measureOutbounds(ctx context.Context, opts *corev1.ProbeOptions, specs []*corev1.OutboundSpec, id string,
	results chan<- *corev1.ProbeResult, wg *sync.WaitGroup, connect func([]*corev1.Endpoint, []string) error) error {
	if opts.GetMethod() == corev1.ProbeMethod_PROBE_METHOD_CONNECT || s.measurer == nil {
		if opts.GetMethod() == corev1.ProbeMethod_PROBE_METHOD_ENGINE {
			return errs.Newf(errs.CodeUnsupported, errs.KeyProbeInvalidEndpoint,
				"control: this core cannot measure through an engine")
		}
		endpoints, ids := endpointsOf(specs)
		return connect(endpoints, ids)
	}

	// Mask measured outbound values because engine errors may include
	// servers or credentials.
	redactor := engine.NewRedactor()
	outbounds := make([]engine.Outbound, 0, len(specs))
	bySpec := make(map[string]*corev1.OutboundSpec, len(specs))
	for i, spec := range specs {
		o, err := outboundFromProto(i, spec, s.secrets)
		if err != nil {
			results <- &corev1.ProbeResult{ServerId: spec.GetId(), Method: probeEngine, Error: toWire(err, nil, id)}
			continue
		}
		redactor.Add(o.Secrets()...)
		redactor.Add(o.Identifiers()...)
		outbounds = append(outbounds, o)
		bySpec[o.ID] = spec
	}
	measured, err := s.measurer.Measure(ctx, outbounds, engine.MeasureOptions{
		URL:         opts.GetUrl(),
		Timeout:     time.Duration(opts.GetTimeoutMs()) * time.Millisecond,
		Concurrency: int(opts.GetConcurrency()),
		Engines:     kinds(opts.GetEngines()),
	})
	if err != nil {
		return err
	}
	auto := opts.GetMethod() == corev1.ProbeMethod_PROBE_METHOD_UNSPECIFIED
	// Keep a wait-group member active while forwarding results so fallback
	// tasks can still be added.
	wg.Add(1)
	go func() {
		defer wg.Done()
		var orphans []*corev1.OutboundSpec
		for m := range measured {
			if auto && errors.Is(m.Err, engine.ErrNoEngine) {
				orphans = append(orphans, bySpec[m.OutboundID])
				continue
			}
			result := &corev1.ProbeResult{ServerId: m.OutboundID, Method: probeEngine, Engine: string(m.Engine)}
			if m.Err != nil {
				result.Error = toWire(m.Err, redactor.String, id)
			} else {
				result.Reachable = true
				result.LatencyMs = latencyMS(m.Latency)
			}
			results <- result
		}
		endpoints, ids := endpointsOf(orphans)
		if err := connect(endpoints, ids); err != nil {
			for _, spec := range orphans {
				results <- &corev1.ProbeResult{ServerId: spec.GetId(), Method: probeConnect, Error: toWire(err, nil, id)}
			}
		}
	}()
	return nil
}

// latencyMS converts latency to wire milliseconds, clamping overflow.
func latencyMS(d time.Duration) uint32 {
	ms := d.Milliseconds()
	switch {
	case ms <= 0:
		return 0
	case ms >= math.MaxUint32:
		return math.MaxUint32
	}
	return uint32(ms)
}

func endpointsOf(specs []*corev1.OutboundSpec) ([]*corev1.Endpoint, []string) {
	endpoints := make([]*corev1.Endpoint, 0, len(specs))
	ids := make([]string, 0, len(specs))
	for _, spec := range specs {
		endpoints = append(endpoints, spec.GetEndpoint())
		ids = append(ids, spec.GetId())
	}
	return endpoints, ids
}

// RunDiagnostics returns a redacted report of the running session.
func (s *Server) RunDiagnostics(ctx context.Context, req *corev1.RunDiagnosticsRequest) (*corev1.RunDiagnosticsResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.RunDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.diagnostics == nil {
		err := errs.Newf(errs.CodeUnsupported, errs.KeyDiagnosticsFailed,
			"control: this core cannot collect diagnostics")
		return &corev1.RunDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	ctx, cancel := requestDeadline(ctx, importTimeout)
	defer cancel()
	lines, err := s.diagnostics.Run(ctx, s.sessions.Status())
	if err != nil {
		return &corev1.RunDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	return &corev1.RunDiagnosticsResponse{Report: &corev1.DiagnosticReport{Lines: lines}}, nil
}

// ExportDiagnostics returns an archive built from already-redacted core values.
// Clients cannot expand its contents. Raw capture formats (PCAPNG, EVTX) are
// refused outright: packet payloads and event logs cannot be redacted to the
// archive's guarantee, so the core will not produce them.
func (s *Server) ExportDiagnostics(ctx context.Context, req *corev1.ExportDiagnosticsRequest) (*corev1.ExportDiagnosticsResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if req.GetFormat() != corev1.DiagnosticFormat_DIAGNOSTIC_FORMAT_UNSPECIFIED {
		if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
			return nil, err
		}
		if !s.captureMu.TryLock() {
			return &corev1.ExportDiagnosticsResponse{Error: toWire(errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionBusy, "control: another native capture is running"), nil, id)}, nil
		}
		defer s.captureMu.Unlock()
		var data []byte
		var err error
		switch req.GetFormat() {
		case corev1.DiagnosticFormat_DIAGNOSTIC_FORMAT_PCAPNG:
			running := s.sessions.Current()
			if running == nil || running.State() != session.StateConnected || !running.Plan().Tun.Enabled || req.GetSessionId() != running.ID() {
				err = errs.Newf(errs.CodeFailedPrecondition, errs.KeyPlanTunnel, "control: a packet capture requires the current connected Sora TUN")
				break
			}
			capture, cancel := context.WithCancel(ctx)
			defer cancel()
			go func() {
				select {
				case <-running.Done():
					cancel()
				case <-capture.Done():
				}
			}()
			data, err = diagnostics.CapturePackets(capture, engine.TunDevice, 10*time.Second)
		case corev1.DiagnosticFormat_DIAGNOSTIC_FORMAT_EVTX:
			data, err = diagnostics.ExportWindowsEvents(ctx)
		default:
			err = errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest, "control: unknown diagnostic format")
		}
		if err != nil {
			return &corev1.ExportDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
		}
		return &corev1.ExportDiagnosticsResponse{Archive: data}, nil
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.ExportDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.diagnostics == nil {
		err := errs.Newf(errs.CodeUnsupported, errs.KeyDiagnosticsFailed,
			"control: this core cannot export diagnostics")
		return &corev1.ExportDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	ctx, cancel := requestDeadline(ctx, importTimeout)
	defer cancel()
	archive, err := s.diagnostics.Export(ctx, s.sessions.Status())
	if err != nil {
		return &corev1.ExportDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	return &corev1.ExportDiagnosticsResponse{Archive: archive}, nil
}
