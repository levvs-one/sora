// Command sora-core runs the Sora network core without a UI. It owns
// credentials, supervises engines, manages tunnel settings, and serves the
// control API independently of clients.
package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"os"
	"path/filepath"
	"runtime"
	"runtime/debug"
	"strconv"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/levvs-one/sora-client/core/censor"
	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/tunroute"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/ext"
	censorv1 "github.com/levvs-one/sora-client/core/gen/sora/censor/v1"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	extv1 "github.com/levvs-one/sora-client/core/gen/sora/ext/v1"
	leakv1 "github.com/levvs-one/sora-client/core/gen/sora/leak/v1"
	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
	"github.com/levvs-one/sora-client/core/guard"
	"github.com/levvs-one/sora-client/core/ipc"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/probe"
	"github.com/levvs-one/sora-client/core/profiles"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

// Version defines the API contract served by this build. Contract changes must
// update this value and the generated code together.
var Version = control.Version{Major: 1, Minor: 13, MinSupportedMinor: 1}

// Options configures a core instance.
type Options struct {
	// Diagnostic builds readiness information without owning or changing routing.
	Diagnostic bool
	// DataDir holds the token, the secret store and the engine home
	// directory.
	DataDir string
	// EnginesDir is searched first for engine binaries.
	EnginesDir string
	// Engine pins an engine kind. Empty selects the first compatible engine
	// in preference order for each plan.
	Engine engine.Kind
	// LocalPort is the tunnel's loopback port, used by the system proxy.
	// Zero selects a free port.
	LocalPort int
	// Bypass lists destinations that skip the tunnel.
	Bypass []string
	// Socket sets the control endpoint. Empty uses the platform address,
	// which requires root for manual runs.
	Socket string
	// Log receives core logs. Nil uses the default handler.
	Log *slog.Logger
	// Factory overrides engine creation. Nil uses mihomo; tests can supply
	// an engine without a binary or system changes.
	Factory session.Factory
	// NoDiagnostics builds a core that cannot produce a report.
	NoDiagnostics bool
	// AllowFileKeys enables a logged fallback when the platform key store
	// fails. Disabled by default because file keys provide weaker
	// protection.
	AllowFileKeys bool
	// AllowEnvBin honors the SORA_*_BIN environment overrides during engine
	// discovery. Disabled by default: the operator takes responsibility
	// for the pointed-at binary (SORA-H5).
	AllowEnvBin bool
}

// App holds an initialized core. Construction opens the store, token, and
// endpoint; Serve starts the control API, allowing readiness checks without
// listening.
type App struct {
	opts     Options
	log      *slog.Logger
	store    *secret.Store
	sessions *session.Manager
	prober   *probe.Prober
	plane    *control.Server
	listener *ipc.Listener
	server   *grpc.Server
	report   *diagnostics.Collector
	address  string
	local    string
	engines  *lazyEngines
	instance io.Closer
	// extSched is the extension background-work scheduler: wired (fetch
	// transport, kill switch) and running, but no worker is registered
	// until the app-side JS runner lands.
	extSched *ext.Scheduler
}

// New builds a core from its options.
func New(ctx context.Context, opts Options) (*App, error) {
	if strings.TrimSpace(opts.DataDir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySecretStoreUnavailable,
			"core: no data directory")
	}
	log := opts.Log
	if log == nil {
		log = slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelInfo}))
	}
	// The log center keeps core and engine logs in memory; the existing log
	// output remains active.
	center := logs.New(logs.DefaultSettings())
	log = slog.New(logs.NewHandler(center, log.Handler()))
	// Create the owner-only directory before any component writes to it, so
	// ownership is consistent.
	if err := os.MkdirAll(opts.DataDir, 0o700); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	if err := secureDataDir(opts.DataDir); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	app := &App{opts: opts, log: log}
	app.address = opts.Socket
	if app.address == "" {
		app.address = ipc.ListenAddress()
	}
	if !opts.Diagnostic {
		instance, err := lockInstance(app.address, opts.DataDir)
		if err != nil {
			return nil, err
		}
		app.instance = instance
		// Binding before recovery also protects a core started by an older build.
		listener, err := ipc.Listen(context.Background(), ipc.Options{Address: opts.Socket})
		if err != nil {
			_ = instance.Close()
			return nil, err
		}
		app.listener = listener
	}
	built := false
	defer func() {
		if !built {
			if app.store != nil {
				_ = app.store.Close()
			}
			if app.listener != nil {
				_ = app.listener.Close()
			}
			if app.instance != nil {
				_ = app.instance.Close()
			}
		}
	}()

	local, err := localAddress(opts.LocalPort)
	if err != nil {
		return nil, err
	}
	app.local = local
	// Engines and the kill switch must use the same port, chosen before
	// either starts.
	tunnelPort, err := portOf(local)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}

	// The control token persists with owner-only permissions and is printed
	// only on explicit request.
	auth, err := control.LoadOrCreateToken(opts.DataDir)
	if err != nil {
		return nil, err
	}
	store, err := secret.Open(filepath.Join(opts.DataDir, "secrets"), secret.Options{
		Protector: protectorFor(opts, log),
	})
	if err != nil {
		return nil, err
	}
	app.store = store

	factory := opts.Factory
	if factory == nil {
		if !opts.Diagnostic {
			if err := tunroute.Cleanup(ctx); err != nil {
				_ = store.Close()
				return nil, err
			}
		}
		// Discovery (digest verification plus a version probe per engine)
		// dominates startup time, but its result is only needed at first
		// use: it starts in the background and the control API does not
		// wait for it; see lazyEngines.
		engines, err := newLazyEngines(ctx, log, opts.EnginesDir, supervise.Config{
			HomeDir: filepath.Join(opts.DataDir, "engine"), LocalPort: int(tunnelPort), Logs: center,
			AllowEnvBin: opts.AllowEnvBin,
		}, opts.Engine)
		if err != nil {
			return nil, err
		}
		app.engines = engines
		factory = app.engines.Factory()
	}

	firewall, err := guard.PlatformFirewall(guard.FirewallOptions{
		// The kill switch matches engines by UID. When the core runs as
		// root the guard refuses to arm instead of silently exempting
		// every root process (SORA-H4); prefer the sora systemd service.
		EngineUID: os.Getuid(), EnginesDir: opts.EnginesDir, Bypass: opts.Bypass,
	})
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	// The platform firewall filters outbound only; without this wrap
	// inbound connections arriving on physical interfaces stay open
	// (the output chain's "ct direction reply accept" answers them).
	// Ingress protection drops inbound attempts that are not replies to
	// an established session, loopback, the tunnel, a VPN server
	// endpoint, or local networks. Local networks stay reachable by
	// default, so printers, Chromecast and file shares keep working —
	// an explicit exception, not a silent hole. The decorator forwards
	// CleanupStale and the session networks to the inner firewall, so
	// the stale-table cleanup below and Guard.Apply keep working
	// through it; on platforms without a process-managed firewall it is
	// a no-op over NoopFirewall.
	firewall = guard.WithIngress(firewall, guard.DefaultIngressConfig())
	// A crashed core can leave the kill-switch table behind, which would
	// keep blocking traffic with no live session. We hold the instance
	// lock from here on, so no other core owns the table (SORA-M4).
	if cleaner, ok := firewall.(interface {
		CleanupStale(context.Context) error
	}); ok {
		if err := cleaner.CleanupStale(ctx); err != nil {
			log.Warn("core: stale firewall cleanup failed", "err", err)
		}
	}
	system, err := guard.New(guard.Options{
		EnginePorts: []uint16{tunnelPort},
	}, firewall)
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	redactor := engine.NewRedactor()
	// Network profiles are auxiliary: a corrupt file disables matching with
	// a warning instead of failing the core.
	profStore, err := profiles.NewStore(opts.DataDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "sora-core: network profiles disabled: %v\n", err)
		profStore, _ = profiles.NewStore("")
	}
	manager := session.NewManager(session.ManagerConfig{
		Factory:  factory,
		Guard:    system,
		Redactor: redactor,
		Network:  session.NetworkFingerprint,
		Profiles: profStore,
		// T017: planned re-handshake so handshake age stops being a
		// cheap censor feature. MaxAge 45m ± 10m (spec
		// 17-long-sessions.md §3.2); 0 would disable it fail-closed.
		Rehandshake: session.RehandshakePolicy{MaxAge: 45 * time.Minute, Jitter: 10 * time.Minute},
	})
	app.sessions = manager

	if !opts.NoDiagnostics {
		collector, err := diagnostics.New(diagnostics.Options{
			Source:   &source{app: app},
			Redactor: redactor,
		})
		if err != nil {
			_ = store.Close()
			return nil, err
		}
		app.report = collector
	}
	// Keep a nil registry as a nil interface to avoid calling through a nil
	// pointer.
	var measurer control.Measurer
	var benchmarker control.Benchmarker
	if app.engines != nil {
		measurer = app.engines
		if b, err := probe.NewBenchmarker(probe.BenchmarkerConfig{
			NewEngine: app.engines.Factory(),
			SelectKind: func(o engine.Outbound) (engine.Kind, error) {
				return benchmarkSelectKind(app.engines.Availability(), o)
			},
		}); err != nil {
			_ = store.Close()
			return nil, err
		} else {
			benchmarker = b
		}
	}
	// The control prober carries the freeze recognizer (T007): every TLS
	// dial it runs feeds the shared probe.FreezeDetector passively, so
	// the "parallel handshakes stall, sequential ones succeed" pattern
	// becomes visible without an active probe. A confirmed freeze is
	// surfaced as a censorship journal event on the running session and
	// expedites the T042 subscription refresh — the same treatment every
	// other censorship verdict gets.
	prober := probe.New(probe.Config{})
	app.prober = prober
	freezeDet := &probe.FreezeDetector{}
	freezeDet.OnFreeze = func(v probe.FreezeVerdict) {
		cur := manager.Current()
		if cur == nil {
			return
		}
		verdict := censor.Verdict{
			Kind:        censor.KindHandshakeTimeout,
			Confidence:  v.Confidence,
			Explanation: "parallel TLS handshakes to " + v.SNI + " stall while sequential ones succeed: per-SNI concurrency freeze",
			Evidence:    v.Evidence,
			At:          time.Now().UTC(),
		}
		cur.Journal().Append(session.Event{
			Kind:   session.EventCensor,
			Detail: "censorship check: " + verdict.Explanation,
			Censor: &verdict,
		})
		serverID := ""
		if plan := cur.Plan(); plan != nil && len(plan.Outbounds) > 0 {
			serverID = plan.Outbounds[0].ID
		}
		if app.plane != nil {
			app.plane.ExpediteForCensorship(verdict, serverID)
		}
	}
	prober.SetFreezeDetector(freezeDet)

	// Extension background scheduler: the component exists from startup
	// (transport + kill-switch plumbing wired below), even though no
	// worker is registered until the app-side JS runner lands — see the
	// pass-1 extensions report. Registering a task without an executor
	// would be theater; running an idle scheduler is just plumbing.
	extSched := ext.NewScheduler(nil)
	plane, err := control.New(control.Config{
		Version:        Version,
		Authenticator:  auth,
		Sessions:       manager,
		Secrets:        store,
		Prober:         prober,
		Measurer:       measurer,
		Benchmarker:    benchmarker,
		DataDir:        opts.DataDir,
		Profiles:       profStore,
		Logs:           center,
		About:          app.about,
		Fetcher:        subscription.New(subscription.Options{}),
		ExtScheduler:   extSched,
		LocalProxyPort: int(tunnelPort),
	})
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	plane.SetDiagnostics(app.report)
	app.plane = plane
	// T042: session censorship verdicts expedite the refresh of the
	// subscription owning the failed server (block-wave endpoint
	// rotation outruns the hourly schedule). The manager is built before
	// the plane, so the hook is installed now that the consumer exists.
	manager.SetCensorshipHook(func(v censor.Verdict, serverID string) {
		plane.ExpediteForCensorship(v, serverID)
	})

	app.server = grpc.NewServer(
		// The transport rejects requests above the four-megabyte plan
		// limit before allocating their payload.
		grpc.MaxRecvMsgSize(control.MaxRecvMsgBytes),
		grpc.MaxSendMsgSize(control.MaxSendMsgBytes),
		// Peer credentials re-check the kernel-verified peer at connection
		// setup and record its privilege level; the interceptors enforce
		// per-method authorization from it (SORA-H2).
		grpc.Creds(ipc.PeerCredentials(ipc.DefaultAuthorize(ipc.Options{Address: opts.Socket}))),
		grpc.UnaryInterceptor(plane.UnaryAuthInterceptor()),
		grpc.StreamInterceptor(plane.StreamAuthInterceptor()),
		// Reap connections that never do anything: together with the
		// listener's connection cap this bounds silent-connection
		// FD exhaustion (SORA-M1). Active streams are not idle.
		grpc.KeepaliveParams(keepalive.ServerParameters{
			MaxConnectionIdle: 10 * time.Minute,
		}),
	)
	if err := mountControlServices(app.server, plane, opts.DataDir); err != nil {
		_ = store.Close()
		return nil, err
	}
	// Extension net.fetch rides the tunnel (control's lookup), never
	// direct: the transport fails closed while no tunnel proxy is live.
	extSched.SetFetchTransport(plane.ExtFetchTransport())
	app.extSched = extSched
	built = true
	return app, nil
}

// benchmarkSelectKind picks the engine that carries one benchmarked
// outbound. The preference must be explicit: SelectEngine iterates the
// given order, so a nil order tries no engine at all and every server
// fails with ErrNoEngine — the wiring passed nil until the integration
// E2E caught it (WAVE-INTEGRATION), which left BenchmarkServers dead
// against a real core while unit tests around it stayed green.
func benchmarkSelectKind(availability []engine.Availability, o engine.Outbound) (engine.Kind, error) {
	sel, err := engine.SelectEngine(
		&engine.Plan{Outbounds: []engine.Outbound{o}},
		availability, engine.DefaultPreference)
	if err != nil {
		return "", err
	}
	return sel.Kind, nil
}

// mountControlServices registers every gRPC service the core exposes on
// server. It is a separate function so the wiring test runs the exact mount
// sequence the production binary uses: a proto service that is implemented
// but not mounted here answers UNIMPLEMENTED on the wire.
func mountControlServices(server *grpc.Server, plane *control.Server, dataDir string) error {
	corev1.RegisterCoreControlServer(server, plane)
	// User-added servers (SW7): shares the control socket and its auth
	// interceptors; every RPC additionally checks the API version and the
	// control authenticator, like the rest of the control plane.
	plane.MountCustomServices(server)
	// Leak self-tests: active egress probes over the control socket. The
	// service shares the socket's auth interceptors, so only control peers
	// reach it; the handler additionally checks the control authenticator.
	leakv1.RegisterLeakServiceServer(server, plane)
	// Obfuscation suite: shares the control socket and its auth
	// interceptors; ApplyObfsProfile stays control-only by default,
	// GetObfsCapabilities is listed as read-only.
	obfsv1.RegisterObfsControlServer(server, plane)
	// Censorship diagnosis (SW4): shares the control socket and its auth
	// interceptors; DetectCensorship additionally checks the control
	// authenticator, because verdicts describe the machine's network.
	censorv1.RegisterCensorControlServer(server, plane)
	// Extensions: the host service shares the control socket and its auth
	// interceptors, so only control peers reach it; per-extension tokens
	// and permission scopes are enforced inside the host.
	extStore, err := ext.OpenStore(filepath.Join(dataDir, "extensions"))
	if err != nil {
		return err
	}
	// GrantedPermissions closes the mint hole: without it Host.MintToken
	// trusts the app's permission list, so a confused control plane could
	// mint tokens for disabled extensions or with ungranted permissions.
	// With it, the core mints only for installed+enabled extensions and
	// only within the user-granted set.
	extDeps := plane.ExtHostDeps()
	extDeps.GrantedPermissions = func(id string) ([]string, bool) {
		inst, ok := extStore.Get(id)
		if !ok || !inst.Enabled {
			return nil, false
		}
		return inst.Granted, true
	}
	extv1.RegisterExtensionHostServer(server, ext.NewHost(extStore.Issuer(), extDeps))
	// Arm revocation enforcement from the on-disk cache of the last
	// signature-verified list, so a kill order received in an earlier run
	// keeps applying offline and across restarts (see ext.RevocationCache).
	// Best-effort: no cache is the documented policy state (installs
	// proceed), and a cache problem must not brick core startup.
	if rc, err := ext.NewRevocationCache(filepath.Join(dataDir, "extensions")); err == nil {
		if l, ok := rc.Load(); ok {
			ext.ApplyToStore(extStore, l)
		}
	}
	return nil
}

// protectorFor selects master-key protection and checks it during construction.
// Missing profile keys can break the platform store; only explicit opt-in
// permits a logged file-key fallback.
func protectorFor(opts Options, log *slog.Logger) secret.Protector {
	platform := platformProtector()
	_, err := platform.Protect([]byte("sora-core protector probe"))
	if err == nil {
		return platform
	}
	if !opts.AllowFileKeys {
		return platform
	}
	log.Warn("the machine key store is unavailable; falling back to a key file",
		"mechanism_wanted", platform.Name(),
		"problem", errs.Detail(err),
		"consequence", "the master key is protected by file permissions instead")
	return secret.FileProtector{}
}

// about describes this build for the "About" screen of the interface.
func (a *App) about() *corev1.About {
	out := &corev1.About{
		CoreVersion: buildVersion,
		Platform:    runtime.GOOS + "/" + runtime.GOARCH,
		GoVersion:   runtime.Version(),
		License:     "GPL-3.0-only",
		SourceUrl:   "https://github.com/levvs-one/sora",
	}
	if port, err := portOf(a.local); err == nil {
		out.LocalProxy = &corev1.Endpoint{Host: "127.0.0.1", Port: uint32(port)}
	}
	if info, ok := debug.ReadBuildInfo(); ok {
		for _, setting := range info.Settings {
			switch setting.Key {
			case "vcs.revision":
				out.Commit = setting.Value
			case "vcs.time":
				if at, err := time.Parse(time.RFC3339, setting.Value); err == nil {
					out.CommitTime = timestamppb.New(at)
				}
			}
		}
	}
	if a.engines != nil {
		for _, engine := range a.engines.Availability() {
			out.Engines = append(out.Engines, &corev1.EngineBuild{
				Kind: string(engine.Kind), Installed: engine.Usable, Version: engine.Version.String(),
			})
		}
	}
	return out
}

// source feeds the diagnostics collector from the running core.
type source struct{ app *App }

func (s *source) Status() session.Status { return s.app.sessions.Status() }

func (s *source) RecentEvents(limit int) []session.Event {
	current := s.app.sessions.Current()
	if current == nil {
		return nil
	}
	events := current.Journal().Since(0, limit)
	if len(events) > limit {
		events = events[len(events)-limit:]
	}
	return events
}

func (s *source) EngineLines() []string {
	lines := []string{
		"component: sora-core",
		"contract: " + fmt.Sprintf("%d.%d", Version.Major, Version.Minor),
		"platform: " + platformName(),
		"tunnel: " + s.app.local,
		"endpoint: " + s.app.address,
	}
	if s.app.engines == nil {
		return append(lines, "engine: provided by the caller")
	}
	for _, a := range s.app.engines.Availability() {
		if a.Usable {
			lines = append(lines, "engine "+string(a.Kind)+": "+a.Version.Raw)
		} else {
			lines = append(lines, "engine "+string(a.Kind)+": not installed")
		}
	}
	if sel := s.app.engines.LastSelection(); sel.Kind != "" {
		lines = append(lines, "engine selected: "+string(sel.Kind))
	}
	for _, why := range s.app.engines.LastSelection().Rejected {
		lines = append(lines, "engine passed over: "+why)
	}
	// T011: subnet reputation is part of the diagnostics readout — a
	// carpet-ban wave must be visible in the report the user exports,
	// not only in selection internals. Subnet prefixes are not server
	// addresses; the collector's redactor still masks the lines.
	if s.app.prober != nil {
		lines = append(lines, s.app.prober.Subnets().SummaryLines()...)
	}
	return lines
}

// Serve runs the control plane until the context ends.
func (a *App) Serve(ctx context.Context) error {
	stop := context.AfterFunc(ctx, func() { _ = a.listener.Close() })
	defer stop()
	a.log.Info("core listening", "endpoint", a.address, "tunnel", a.local)
	// Subscription updates must continue without a connected UI.
	go a.plane.Run(ctx)
	if a.extSched != nil {
		a.extSched.Start(ctx)
		defer a.extSched.Stop()
	}
	err := a.server.Serve(a.listener)
	if ctx.Err() != nil {
		// Closing the listener on cancellation is a normal service
		// shutdown.
		return nil //nolint:nilerr // the error is the closed listener of a requested stop
	}
	if errors.Is(err, grpc.ErrServerStopped) {
		return nil
	}
	return err
}

// Close restores session settings, then closes the endpoint and secret store.
func (a *App) Close() error {
	var problems []error
	// Shutdown needs an independent deadline to restore the proxy after
	// caller cancellation.
	stopCtx, cancel := context.WithTimeout(context.WithoutCancel(context.Background()), 20*time.Second)
	defer cancel()
	if err := a.sessions.Shutdown(stopCtx); err != nil {
		problems = append(problems, err)
	}
	if a.server != nil {
		a.server.GracefulStop()
	}
	if a.listener != nil {
		if err := a.listener.Close(); err != nil && !errors.Is(err, net.ErrClosed) {
			problems = append(problems, err)
		}
	}
	if a.store != nil {
		if err := a.store.Close(); err != nil {
			problems = append(problems, err)
		}
	}
	if a.instance != nil {
		problems = append(problems, a.instance.Close())
	}
	return errors.Join(problems...)
}

// Address returns the endpoint clients dial.
func (a *App) Address() string { return a.address }

// TunnelAddress returns the loopback address used by the system proxy.
func (a *App) TunnelAddress() string { return a.local }

// localAddress selects the tunnel's loopback address before the engine starts,
// so the guard can use it across sessions.
func localAddress(port int) (string, error) {
	if port == 0 {
		free, err := supervise.FreePort()
		if err != nil {
			return "", err
		}
		port = free
	}
	if port < 1 || port > 0xffff {
		return "", errs.Newf(errs.CodeInvalidArgument, errs.KeyEngineStartFailed,
			"core: %d is not a port", port)
	}
	return net.JoinHostPort("127.0.0.1", strconv.Itoa(port)), nil
}

// portOf extracts the port from an address.
func portOf(address string) (uint16, error) {
	_, portText, err := net.SplitHostPort(address)
	if err != nil {
		return 0, err
	}
	port, err := strconv.ParseUint(portText, 10, 16)
	return uint16(port), err
}
