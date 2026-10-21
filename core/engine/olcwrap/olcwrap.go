// Package olcwrap runs OpenLibre olcrtc servers through the pinned
// olcrtc sidecar binary, following the zapret model of
// core/engine/bypass exactly: the sidecar runs in client mode
// ("cnc") under core/engine/supervise, digest-verified against
// engines.digests before it is ever executed (SORA-H5), and every
// olcrtc outbound of the plan is rewritten to a SOCKS5 outbound
// aimed at the sidecar's loopback listener, so all three engines
// carry it without knowing olcrtc exists.
//
// The sidecar's YAML configuration is rendered per unique tunnel
// configuration (provider, transport, room, key, parameters, plan
// resolver), written 0600 into the 0700 runtime home and deleted
// when the configuration stops. The local listener is authenticated
// with ephemeral per-session credentials, so no other local process
// can use it as an open proxy. Readiness is the listener itself,
// never a timer. A dead sidecar is restarted on the same port with
// backoff; while it is down the rewritten outbound simply refuses
// connections — the failure is closed, never a direct leak.
//
// Sora is a client only: a plan asking the sidecar for server mode
// ("srv") is refused, here and in plan validation.
package olcwrap

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/logs"
)

// Source names olcrtc in the log center.
const Source = "olcrtc"

// Config is one sidecar tunnel configuration: everything the YAML
// renderer needs, already resolved from a plan outbound and the
// plan's DNS. Two outbounds with equal Config.Key() share one
// sidecar process.
type Config struct {
	Provider  string
	Transport string
	Room      string
	Channel   string
	// AuthToken is the provider account token (wbstream); empty for
	// the guest flows.
	AuthToken string
	// Mode is "" or "cnc"; anything else is refused.
	Mode string
	// KeyHex is the 64-hex tunnel PSK (the outbound's Password).
	KeyHex string
	// Params holds transport parameters under their share-link
	// names; the renderer translates them to YAML (SPEC §3.2).
	Params map[string]string
	// DNS is the plan resolver as host:port. olcrtc requires one
	// and defaults to 8.8.8.8 when its config omits it; sora always
	// renders the plan's resolver instead (see PlanResolver).
	DNS string
	// EngineName, EngineURL and EngineToken are the direct-SFU
	// fields of provider "none". A share link cannot express them,
	// so a plan never carries them today; the renderer supports
	// them so the YAML stays complete if a future contract does.
	EngineName  string
	EngineURL   string
	EngineToken string
}

// Key returns the dedup identity of a configuration: one sidecar per
// distinct tunnel. Secrets enter only as hashes — the key names
// files and map entries, never logs.
func (c Config) Key() string {
	h := sha256.New()
	for _, f := range []string{c.Provider, c.Transport, c.Room, c.Channel, c.Mode, c.DNS} {
		fmt.Fprintf(h, "%s\x00", f)
	}
	for _, s := range []string{c.KeyHex, c.AuthToken, c.EngineToken} {
		sum := sha256.Sum256([]byte(s))
		fmt.Fprintf(h, "%x\x00", sum)
	}
	keys := make([]string, 0, len(c.Params))
	for k := range c.Params {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		fmt.Fprintf(h, "%s=%s\x00", k, c.Params[k])
	}
	return hex.EncodeToString(h.Sum(nil))
}

// ConfigFromOutbound resolves one olcrtc outbound plus the plan
// resolver into a sidecar configuration.
func ConfigFromOutbound(o engine.Outbound, dns string) Config {
	cfg := Config{KeyHex: o.Password, DNS: dns}
	if o.Olcrtc != nil {
		cfg.Provider = o.Olcrtc.Provider
		cfg.Transport = o.Olcrtc.Transport
		cfg.Room = o.Olcrtc.Room
		cfg.Channel = o.Olcrtc.Channel
		cfg.AuthToken = o.Olcrtc.AuthToken
		cfg.Mode = o.Olcrtc.Mode
		cfg.Params = o.Olcrtc.Params
	}
	return cfg
}

// Has reports whether a plan carries an olcrtc outbound.
func Has(p *engine.Plan) bool {
	return p != nil && slices.ContainsFunc(p.Outbounds, func(o engine.Outbound) bool {
		return o.Protocol == engine.ProtocolOLCRTC
	})
}

// Listener is one running sidecar's loopback endpoint and the
// ephemeral credentials its SOCKS5 listener demands.
type Listener struct {
	Port int
	User string
	Pass string
}

// Rewrite prepares a plan for an engine: every olcrtc outbound
// becomes a SOCKS5 outbound to its sidecar listener. listeners maps
// Config.Key() — computed under the plan resolver dns, the value
// the listeners were started with — to the running listener; an
// absent key uses port 1 with no credentials, for validation and
// engine selection without a running sidecar (the same convention
// as bypass.Rewrite). The caller's plan is never mutated.
func Rewrite(p *engine.Plan, dns string, listeners map[string]Listener) *engine.Plan {
	out := *p
	out.Outbounds = slices.Clone(p.Outbounds)
	for i, o := range out.Outbounds {
		if o.Protocol != engine.ProtocolOLCRTC {
			continue
		}
		lis, ok := listeners[ConfigFromOutbound(o, dns).Key()]
		port := 1
		if ok && lis.Port != 0 {
			port = lis.Port
		}
		rewritten := engine.Outbound{
			ID: o.ID, Name: o.Name, Protocol: engine.ProtocolSOCKS5,
			Server: "127.0.0.1", Port: uint16(port), Via: o.Via, //nolint:gosec // a loopback port from FreePort
		}
		if ok {
			rewritten.UserID, rewritten.Password = lis.User, lis.Pass
		}
		// SOCKSUDP stays false: the tunnel carries no UDP (v1), and
		// the rewritten outbound must not promise it.
		out.Outbounds[i] = rewritten
	}
	return &out
}

// UnsupportedCombination reports whether the provider×transport
// matrix (SPEC §3.1, from the olcrtc settings matrix) forbids the
// pairing outright: telemost carries neither datachannel nor
// seichannel.
func UnsupportedCombination(provider, transport string) bool {
	return provider == "telemost" && (transport == "datachannel" || transport == "seichannel")
}

// ValidateConnect applies the connection-time rules of an olcrtc
// configuration — the checks the import layer deliberately does not
// make, because they are properties of connecting, not of the link:
// the provider×transport matrix, the wbstream datachannel token
// rule, the unconnectability of provider none from a link, and the
// client-only mode rule. Errors carry catalog keys so clients can
// localize them.
func ValidateConnect(cfg Config) error {
	if cfg.Mode != "" && cfg.Mode != "cnc" {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyOlcrtcServerMode,
			"olcrtc: mode %q refused: sora is a client only and never runs an egress", cfg.Mode)
	}
	if !engine.OlcrtcProviders[cfg.Provider] || !engine.OlcrtcTransports[cfg.Transport] || !engine.IsOlcrtcKey(cfg.KeyHex) {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyOlcrtcInvalid,
			"olcrtc: provider %q, transport %q or the encryption key is not usable", cfg.Provider, cfg.Transport)
	}
	if cfg.Provider != "none" && cfg.Room == "" {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyOlcrtcInvalid,
			"olcrtc: provider %q needs a room id", cfg.Provider)
	}
	if cfg.Provider == "none" {
		// A link expresses no engine.url/engine.token for the direct
		// mode, so there is nothing honest to connect to.
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyOlcrtcNotConnectable,
			"olcrtc: provider \"none\" connects by a direct engine URL and token, which a share link does not carry")
	}
	if UnsupportedCombination(cfg.Provider, cfg.Transport) {
		return errs.Newf(errs.CodeUnsupported, errs.KeyOlcrtcCombination,
			"olcrtc: provider %q cannot carry the %q transport", cfg.Provider, cfg.Transport)
	}
	if cfg.Provider == "wbstream" && cfg.Transport == "datachannel" && cfg.AuthToken == "" {
		// The guest flow's token cannot publish data; without a
		// moderator account token this pairing is dead on arrival
		// (SPEC R-6), so say so instead of starting a sidecar.
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyOlcrtcTokenRequired,
			"olcrtc: wbstream datachannel needs a provider account token (the guest flow cannot publish data)")
	}
	return nil
}

// Engine runs an engine with the olcrtc sidecars its plan needs.
type Engine struct {
	engine.Engine
	binary string
	home   string
	logs   *logs.Center

	mu       sync.Mutex
	procs    map[string]*sidecar
	redactor *engine.Redactor
}

type sidecar struct {
	key       string
	cfg       Config
	listener  Listener
	proc      *supervise.Process
	cancel    context.CancelFunc
	configRel string
}

// Wrap adds olcrtc sidecars to an engine. binary is the discovered,
// digest-verified olcrtc executable ("" when not installed — the
// registry refuses such plans before wrapping); home is the runtime
// olcrtc working directory.
func Wrap(inner engine.Engine, binary, home string, center *logs.Center) *Engine {
	return &Engine{Engine: inner, binary: binary, home: home, logs: center,
		procs: map[string]*sidecar{}, redactor: engine.NewRedactor()}
}

// Validate checks connection rules, then the plan the engine will
// run (the rewritten one). A plan without olcrtc outbounds is the
// inner engine's alone.
func (e *Engine) Validate(ctx context.Context, p *engine.Plan) error {
	if !Has(p) {
		return e.Engine.Validate(ctx, p)
	}
	dns, err := PlanResolver(p)
	if err != nil {
		return err
	}
	for _, o := range p.Outbounds {
		if o.Protocol == engine.ProtocolOLCRTC {
			if err := ValidateConnect(ConfigFromOutbound(o, dns)); err != nil {
				return err
			}
		}
	}
	return e.Engine.Validate(ctx, Rewrite(p, dns, nil))
}

// Apply starts the sidecars the plan needs, stops the ones it no
// longer needs, and applies the rewritten plan. Every gate runs
// before any state changes: a plan that cannot connect fails closed
// with the engine untouched, like bypass.Apply. If starting a later
// sidecar or the inner Apply fails, the sidecars this call started
// are stopped again (and their configs deleted) before the error
// returns: a sidecar holds the user's key inside a live provider
// room, so it must not outlive a session the caller was told never
// started. Sidecars an earlier successful Apply started are not
// touched by the rollback — they belong to the running session and
// keep its keep/restart semantics.
func (e *Engine) Apply(ctx context.Context, p *engine.Plan) error {
	if !Has(p) {
		// A later plan of the same session may drop olcrtc
		// entirely: retire every sidecar and delegate untouched.
		e.stopAll()
		return e.Engine.Apply(ctx, p)
	}
	if e.binary == "" {
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing,
			"olcrtc: plan needs the olcrtc sidecar in the engines directory")
	}
	dns, err := PlanResolver(p)
	if err != nil {
		return err
	}
	needed := map[string]Config{}
	for _, o := range p.Outbounds {
		if o.Protocol != engine.ProtocolOLCRTC {
			continue
		}
		cfg := ConfigFromOutbound(o, dns)
		if err := ValidateConnect(cfg); err != nil {
			return err
		}
		needed[cfg.Key()] = cfg
	}
	e.mu.Lock()
	e.redactor = engine.NewRedactor(append(p.Secrets(), p.Identifiers()...)...)
	e.mu.Unlock()
	// Retire configurations the plan no longer needs.
	e.mu.Lock()
	for k, sc := range e.procs {
		if _, keep := needed[k]; !keep {
			sc.stop(e.home)
			delete(e.procs, k)
		}
	}
	e.mu.Unlock()
	listeners := make(map[string]Listener, len(needed))
	// started tracks exactly the sidecars this call raised, so a
	// failure below can roll them back without touching sidecars a
	// previous successful Apply left running.
	var started []*sidecar
	rollbackStarted := func() {
		e.mu.Lock()
		for _, sc := range started {
			if cur, ok := e.procs[sc.key]; ok && cur == sc {
				delete(e.procs, sc.key)
			}
		}
		e.mu.Unlock()
		for _, sc := range started {
			sc.stop(e.home)
		}
	}
	for k, cfg := range needed {
		sc := e.current(k)
		if sc == nil {
			if sc, err = e.start(ctx, cfg); err != nil {
				rollbackStarted()
				return err
			}
			if published := e.publish(k, sc); published == sc {
				started = append(started, sc)
			} else {
				// A concurrent Apply won the race for this key:
				// publish already stopped our duplicate, and the
				// winner's sidecar is not ours to roll back.
				sc = published
			}
		}
		listeners[k] = sc.listener
	}
	if err := e.Engine.Apply(ctx, Rewrite(p, dns, listeners)); err != nil {
		rollbackStarted()
		return err
	}
	return nil
}

func (e *Engine) current(k string) *sidecar {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.procs[k]
}

func (e *Engine) publish(k string, sc *sidecar) *sidecar {
	e.mu.Lock()
	defer e.mu.Unlock()
	if cur, ok := e.procs[k]; ok {
		sc.stop(e.home)
		return cur
	}
	e.procs[k] = sc
	return sc
}

// start renders the configuration, writes it 0600 into the runtime
// home, launches the sidecar under supervision and waits for its
// listener — readiness is the open port, cross-checked against the
// process still being alive, never a bare sleep.
func (e *Engine) start(ctx context.Context, cfg Config) (*sidecar, error) {
	port, err := supervise.FreePort()
	if err != nil {
		return nil, err
	}
	user, pass, err := ephemeralCreds()
	if err != nil {
		return nil, err
	}
	yaml, err := RenderYAML(cfg, Listener{Port: port, User: user, Pass: pass})
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(e.home, 0o700); err != nil {
		return nil, fmt.Errorf("olcrtc: create runtime home: %w", err)
	}
	key := cfg.Key()
	rel := "olcrtc-" + key[:16] + ".yaml"
	path := filepath.Join(e.home, rel)
	if err := writeConfigFile(path, yaml); err != nil {
		return nil, err
	}
	pctx, cancel := context.WithCancel(context.Background())
	sc := &sidecar{key: key, cfg: cfg, listener: Listener{Port: port, User: user, Pass: pass},
		cancel: cancel, configRel: rel}
	spec := supervise.Spec{Name: "olcrtc", Path: e.binary, Args: []string{path}, Dir: e.home, Lines: e.logLine}
	if sc.proc, err = supervise.Start(pctx, spec); err != nil {
		cancel()
		_ = os.Remove(path)
		return nil, err
	}
	if err := waitListening(ctx, sc.proc, port); err != nil {
		sc.stop(e.home)
		return nil, err
	}
	go e.keep(pctx, sc, spec)
	return sc, nil
}

// keep restarts a dead sidecar on the same port with the same
// configuration, so the engine's rewritten outbounds stay valid.
// The restart budget is the supervisor backoff's, shared with the
// other helpers; a sidecar that cannot stay up leaves its port
// refusing connections (fail-closed) and its log lines explain why.
func (e *Engine) keep(ctx context.Context, sc *sidecar, spec supervise.Spec) {
	backoff := engine.DefaultBackoff()
	for attempt := 0; ; attempt++ {
		e.mu.Lock()
		proc := sc.proc
		e.mu.Unlock()
		if err := proc.Wait(ctx); ctx.Err() != nil {
			return
		} else if e.logs != nil {
			e.logs.Write(time.Time{}, logs.LevelWarning, Source,
				e.mask(fmt.Sprintf("olcrtc stopped (%v); starting it again", err)))
		}
		if backoff.Wait(ctx, attempt) != nil {
			return
		}
		next, err := supervise.Start(ctx, spec)
		if err != nil {
			continue
		}
		e.mu.Lock()
		sc.proc = next
		e.mu.Unlock()
	}
}

func (sc *sidecar) stop(home string) {
	sc.cancel()
	if sc.proc != nil {
		_ = sc.proc.Stop(context.Background(), time.Second)
	}
	if sc.configRel != "" {
		_ = os.Remove(filepath.Join(home, sc.configRel))
	}
}

// Stop stops the engine, then every sidecar (mirroring bypass: the
// engine goes first so nothing dials a listener being torn down).
func (e *Engine) Stop(ctx context.Context) error {
	err := e.Engine.Stop(ctx)
	e.stopAll()
	return err
}

// Close closes the engine and stops every sidecar.
func (e *Engine) Close() error {
	err := e.Engine.Close()
	e.stopAll()
	return err
}

func (e *Engine) stopAll() {
	e.mu.Lock()
	defer e.mu.Unlock()
	for k, sc := range e.procs {
		sc.stop(e.home)
		delete(e.procs, k)
	}
}

// mask redacts one sidecar output line. The binary's logs name rooms
// and provider endpoints; the redactor is seeded from the applied
// plan's secrets and identifiers (the encryption key among them, as
// the outbound's Password), so a hex key in sidecar output is masked
// before it can reach the log center.
func (e *Engine) mask(line string) string {
	e.mu.Lock()
	r := e.redactor
	e.mu.Unlock()
	if r != nil {
		return r.String(line)
	}
	return engine.NewRedactor().String(line)
}

// lineLevel classifies one sidecar output line like the bypass
// helper's: a leading level word wins, error/fatal keywords promote,
// the rest stays info.
func lineLevel(line string) logs.Level {
	first, _, _ := strings.Cut(line, " ")
	if level, ok := logs.ParseLevel(strings.Trim(first, "[]:")); ok {
		return level
	}
	lower := strings.ToLower(line)
	if strings.Contains(lower, "error") || strings.Contains(lower, "fatal") {
		return logs.LevelError
	}
	if strings.Contains(lower, "warn") {
		return logs.LevelWarning
	}
	return logs.LevelInfo
}

func (e *Engine) logLine(line string) {
	if e.logs != nil {
		e.logs.Write(time.Time{}, lineLevel(line), Source, e.mask(line))
	}
}

// writeConfigFile writes the rendered sidecar configuration with
// owner-only permissions: it carries the tunnel key in plain text
// for the length of the session (the binary reads configuration
// only from a file — the honest residual risk of the sidecar path,
// bounded by 0600 inside the 0700 runtime home and deletion at
// stop).
func writeConfigFile(path string, data []byte) error {
	if err := os.WriteFile(path, data, 0o600); err != nil {
		return fmt.Errorf("olcrtc: write sidecar config: %w", err)
	}
	// WriteFile does not tighten the mode of an existing file; a
	// config left by a crashed run must not keep wider permissions.
	if err := os.Chmod(path, 0o600); err != nil {
		return fmt.Errorf("olcrtc: set sidecar config permissions: %w", err)
	}
	return nil
}

// ephemeralCreds mints the per-session SOCKS credentials of one
// sidecar listener, so the listener is never an open local proxy.
func ephemeralCreds() (user, pass string, err error) {
	var raw [24]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "", "", fmt.Errorf("olcrtc: mint listener credentials: %w", err)
	}
	return "sora-" + hex.EncodeToString(raw[:6]), hex.EncodeToString(raw[6:]), nil
}

var dialer net.Dialer

// waitListening polls the sidecar's port until it accepts, the
// process dies, or the timeout passes — the RunWithAddress
// equivalent for a binary that announces readiness only by
// listening. The cap is generous because the listener opens only
// after the provider conference joins, which involves a WebSocket
// signalling round and a WebRTC negotiation; the caller's context
// still bounds the wait.
func waitListening(ctx context.Context, proc *supervise.Process, port int) error {
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	addr := "127.0.0.1:" + strconv.Itoa(port)
	for {
		if conn, err := (&dialer).DialContext(ctx, "tcp", addr); err == nil {
			return conn.Close()
		}
		if err := proc.Err(); err != nil {
			return errs.Wrap(err, errs.CodeUnavailable, errs.KeyEngineStartFailed)
		}
		select {
		case <-ctx.Done():
			return errs.Newf(errs.CodeUnavailable, errs.KeyEngineStartFailed,
				"olcrtc: sidecar did not start listening on %s", addr)
		case <-time.After(20 * time.Millisecond):
		}
	}
}
