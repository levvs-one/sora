package session

import (
	"context"
	"errors"
	"fmt"
	"math/rand/v2"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/censor"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/profiles"
)

// Factory creates an engine for a plan, keeping discovery and test engines
// outside the session package.
type Factory func(ctx context.Context, plan *engine.Plan) (engine.Engine, error)

// ManagerConfig requires Factory; other fields default to desktop core
// settings.
type ManagerConfig struct {
	// Factory builds the engine for a plan. It is required.
	Factory Factory
	// Guard is shared across sequential sessions and restored on every exit
	// path. Two sessions cannot own system settings concurrently.
	Guard Guard
	// JournalCapacity is the history size of each session journal.
	JournalCapacity int
	// StatsInterval samples the engine counters.
	StatsInterval time.Duration
	// StopGrace bounds the engine shutdown.
	StopGrace time.Duration
	// Redactor masks secrets in the journal.
	Redactor *engine.Redactor
	// Now supplies timestamps.
	Now func() time.Time
	// TunUp waits for the adapter of a tun plan; see Config.TunUp.
	TunUp func(ctx context.Context, device string) error
	// Network fingerprints the networks of the machine; see Config.Network.
	Network func() string
	// Profiles matches saved network profiles on network changes; see
	// Config.Profiles. Nil disables profile matching.
	Profiles *profiles.Store
	// Rehandshake is the planned re-handshake policy (T017): a session
	// whose transport handshake outlives it is restarted on the same
	// plan so handshake age stops being a cheap censor feature. The
	// zero value disables it (fail-closed).
	Rehandshake RehandshakePolicy
	// OnCensorshipVerdict receives every censorship verdict a session's
	// failure watcher publishes, with the failed server's id. The
	// control plane uses it for the T042 expedited subscription
	// refresh. Can also be set later with SetCensorshipHook when the
	// consumer is built after the manager.
	OnCensorshipVerdict func(censor.Verdict, string)
}

// Manager owns at most one session. Connect stops and restores the old session
// before the new one changes proxy, firewall, or TUN settings.
type Manager struct {
	cfg ManagerConfig

	mu      sync.Mutex
	current *Session
	last    Status
	busy    bool
	// lastPlan/lastSettings remember the running session's inputs so the
	// T017 worker can restart the same session for a planned
	// re-handshake. They change only at a successful Connect.
	lastPlan     *engine.Plan
	lastSettings Settings
	// censorHook backs ManagerConfig.OnCensorshipVerdict and can be
	// installed after construction with SetCensorshipHook.
	censorHook func(censor.Verdict, string)
	// shutdown is the whitelist/shutdown classifier (T047), shared by
	// every session this manager runs: the classification is a property
	// of the network, and evidence must survive reconnects.
	shutdown *censor.ShutdownDetector
}

// NewManager validates the required factory at construction rather than on
// first connection.
func NewManager(cfg ManagerConfig) *Manager {
	if cfg.Factory == nil {
		panic("session: manager needs an engine factory")
	}
	if cfg.JournalCapacity <= 0 {
		cfg.JournalCapacity = DefaultJournalCapacity
	}
	if cfg.StatsInterval <= 0 {
		cfg.StatsInterval = DefaultStatsInterval
	}
	if cfg.StopGrace <= 0 {
		cfg.StopGrace = DefaultStopGrace
	}
	if cfg.Now == nil {
		cfg.Now = time.Now
	}
	if cfg.Guard == nil {
		cfg.Guard = NoopGuard{}
	}
	return &Manager{
		cfg:        cfg,
		last:       Status{State: StateDisconnected, ChangedAt: cfg.Now()},
		censorHook: cfg.OnCensorshipVerdict,
		shutdown:   censor.NewShutdownDetector(),
	}
}

// SetCensorshipHook installs (or replaces) the hook receiving censorship
// verdicts published by session failure watchers, with the failed
// server's id. It exists because the control plane — the hook's consumer
// — is constructed after the manager. Sessions started before the call
// keep whatever hook they captured at Connect.
func (m *Manager) SetCensorshipHook(fn func(censor.Verdict, string)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.censorHook = fn
}

// buildSession runs the pre-start phase shared by Connect and by the
// switch rollback: prepare the plan, build its engine through the
// factory and validate it. Nothing here touches a running previous
// session, so a failure leaves the current tunnel exactly as it was.
func (m *Manager) buildSession(ctx context.Context, plan *engine.Plan, settings Settings) (*Session, error) {
	if err := engine.PrepareTun(plan); err != nil {
		return nil, errs.Wrap(err, errs.CodeFailedPrecondition, errs.KeyPlanTunnel)
	}
	built, err := m.cfg.Factory(ctx, plan)
	if err != nil {
		return nil, err
	}
	created, err := New(Config{
		Plan:          plan,
		Engine:        built,
		Guard:         m.cfg.Guard,
		Journal:       NewJournal(m.cfg.JournalCapacity),
		StatsInterval: m.cfg.StatsInterval,
		StopGrace:     m.cfg.StopGrace,
		Redactor:      m.cfg.Redactor,
		Settings:      settings,
		Now:           m.cfg.Now,
		TunUp:         m.cfg.TunUp,
		Network:       m.cfg.Network,
		Profiles:      m.cfg.Profiles,
	})
	if err != nil {
		// Surface a failing Close instead of swallowing it (SORA-L13).
		if closeErr := built.Close(); closeErr != nil {
			err = errors.Join(err, closeErr)
		}
		return nil, err
	}
	if err := built.Validate(ctx, plan); err != nil {
		if closeErr := built.Close(); closeErr != nil {
			err = errors.Join(err, closeErr)
		}
		return nil, validationErr(err)
	}
	if err := ctx.Err(); err != nil {
		if closeErr := built.Close(); closeErr != nil {
			err = errors.Join(err, closeErr)
		}
		return nil, err
	}
	return created, nil
}

// closeBuilt closes the engine of a built-but-never-started session,
// joining a close failure onto err instead of swallowing it (SORA-L13).
func closeBuilt(s *Session, err error) error {
	if s == nil {
		return err
	}
	if closeErr := s.eng.Close(); closeErr != nil {
		return errors.Join(err, closeErr)
	}
	return err
}

// adopt makes a successfully started session the manager's current one
// and remembers its inputs for a planned re-handshake or a switch
// rollback. It also attaches the manager-owned watchers.
func (m *Manager) adopt(created *Session, plan *engine.Plan, settings Settings) {
	m.mu.Lock()
	m.current = created
	m.last = created.Status()
	m.lastPlan = plan
	m.lastSettings = settings
	created.censorHook = m.censorHook
	created.shutdownDet = m.shutdown
	m.mu.Unlock()
	// Diagnose network-level failures in the background: the watcher reacts
	// to journal events only and never touches the session runner (SW4).
	created.WatchCensorshipFailures(&censor.Detector{}, &censor.Prober{})
	// T017: the worker restarts this session on the same plan when the
	// transport handshake outlives the policy.
	go m.rehandshakeLoop(created)
	// T029: the dead-mode watchdog payload-probes the connected tunnel;
	// a no-traffic verdict marks dead-mode and pauses the re-handshake
	// worker instead of retry-storming a shut network.
	go m.deadSessionLoop(created)
}

// rollbackToPrevious makes one attempt to bring the previous session
// back after a switch failed past the point of no return (the previous
// session is already stopped and sessions are single-use, so the
// rollback is a fresh build+start from the remembered plan/settings,
// never a restart of the stopped object). On success the restored
// session becomes current and its journal says why it exists. The
// rollback builds and starts on stopCtx — the caller's context
// detached from cancellation — not on the switch's own context: a
// switch often fails precisely because that context was cancelled
// (the RPC went away), and reusing it would make the rollback fail
// for the same unrelated reason and strand the user with no tunnel.
func (m *Manager) rollbackToPrevious(stopCtx context.Context, switchErr error) (*Session, error) {
	m.mu.Lock()
	plan, settings := m.lastPlan, m.lastSettings
	m.mu.Unlock()
	if plan == nil {
		return nil, errors.New("session: no previous plan to roll back to")
	}
	restored, err := m.buildSession(stopCtx, plan, settings)
	if err != nil {
		return nil, err
	}
	if err := restored.Start(stopCtx); err != nil {
		cleanupErr := restored.Stop(stopCtx)
		if cleanupErr != nil {
			// The failed rollback still owns unrestored settings;
			// keep it as current so Disconnect can retry the cleanup
			// instead of losing the owner (same rule as a failed
			// startup in Connect).
			m.mu.Lock()
			m.current = restored
			m.mu.Unlock()
			return nil, errors.Join(err, cleanupErr)
		}
		return nil, err
	}
	restored.Journal().Append(Event{
		Kind:    EventLog,
		LogLine: fmt.Sprintf("rollback: restored the previous session after the server switch failed: %v", switchErr),
	})
	m.adopt(restored, plan, settings)
	return restored, nil
}

// Connect stops any previous session and restores its settings before starting
// the new plan. When the new session fails to start after the previous
// one was stopped, Connect makes one attempt to restore the previous
// session from the remembered plan and returns the original switch
// error either way. When both the old and the new sessions want the
// kill switch and the guard supports holding it, the block is held
// across the whole switch (and across a rollback), so it never lifts.
func (m *Manager) Connect(ctx context.Context, plan *engine.Plan, settings Settings) (*Session, error) {
	m.mu.Lock()
	if m.busy {
		m.mu.Unlock()
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionBusy,
			"session: another connect or disconnect is running")
	}
	m.busy = true
	previous := m.current
	prevSettings := m.lastSettings
	m.mu.Unlock()

	defer m.release()

	// The hold decision below — and any rollback — must use the
	// previous session's LIVE kill-switch state, not the settings it
	// was connected with: Session.SetKillSwitch toggles the guard and
	// the session status in place but never touches lastSettings, so
	// deciding from lastSettings both misses a hold for a switch the
	// user armed live (the previous Stop then really lifts the block
	// for the switch window) and takes a spurious hold for one they
	// disarmed live. Sync the remembered settings to the live value
	// so a rollback restores what was actually in force, too.
	if previous != nil {
		if live := previous.Status().KillSwitch; live != prevSettings.KillSwitch {
			prevSettings.KillSwitch = live
			m.mu.Lock()
			if m.current == previous {
				m.lastSettings.KillSwitch = live
			}
			m.mu.Unlock()
		}
	}

	created, err := m.buildSession(ctx, plan, settings)
	if err != nil {
		return nil, err
	}
	stopCtx := context.WithoutCancel(ctx)

	// Panic safety for the built session: an engine is third-party
	// code and its Apply can panic mid-switch, after its session's
	// guard Apply is already in force. Without cleanup that session
	// would stay half-started with no owner able to restore it, and
	// the block would stick even after the hold is released (a
	// release rightly leaves a block an applied session still
	// wants). On panic only — normal returns are untouched — stop
	// the built session (or close its engine when Start was never
	// attempted), then re-panic: a panic in Connect propagates as a
	// panic, never as a swallowed error.
	createdStartAttempted := false
	createdOwned := false // adopted, or kept as current for Disconnect cleanup
	defer func() {
		if r := recover(); r != nil {
			if !createdOwned {
				if createdStartAttempted {
					_ = created.Stop(stopCtx)
				} else {
					_ = closeBuilt(created, nil)
				}
			}
			panic(r)
		}
	}()

	// Kill-switch continuity: hold the shared guard's block before the
	// previous session's Stop can restore it, and release only after
	// the new session (or the rollback) is running. Guards without
	// BlockHolder keep the previous behaviour.
	var releaseHold func(context.Context) error
	if previous != nil && prevSettings.KillSwitch && settings.KillSwitch {
		release, holdErr := acquireBlockHold(ctx, m.cfg.Guard)
		if holdErr != nil {
			// Fail closed before touching the previous session: the
			// switch is refused, the working tunnel stays up.
			m.setLast(previous.Status())
			return nil, closeBuilt(created, errs.Wrap(holdErr, errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail))
		}
		releaseHold = release
	}
	releaseBlock := func() error {
		if releaseHold == nil {
			return nil
		}
		release := releaseHold
		releaseHold = nil
		return release(stopCtx)
	}
	// releaseBlockLogged releases the hold (releaseBlock itself is
	// idempotent: it consumes releaseHold, so the deferred call below
	// and the explicit calls on the return paths can never release
	// twice) and journals a failure instead of swallowing it. A failed
	// release means the guard could not drop a block nobody wants any
	// more; the guard keeps that disarm retryable (see core/guard), so
	// the next Restore retries it — but the failure must be visible
	// somewhere, and the session journal is the least invasive place:
	// returning it would mask the switch's own result, which callers
	// already act on. The log target is whichever session is current
	// when the release runs, falling back to the built session.
	releaseBlockLogged := func() {
		err := releaseBlock()
		if err == nil {
			return
		}
		target := m.currentSession()
		if target == nil {
			target = created
		}
		if target == nil {
			target = previous
		}
		if target != nil {
			target.Journal().Append(Event{
				Kind:    EventError,
				Reason:  errs.CodeOf(err),
				Key:     errs.KeyGuardRestoreFailed,
				LogLine: fmt.Sprintf("kill-switch hold release failed; the block stays armed and the guard will retry dropping it on the next restore: %v", err),
				Detail:  err.Error(),
			})
		}
	}
	if releaseHold != nil {
		// Deferred immediately after the acquire: a panic anywhere in
		// the switch below (an engine's Apply is third-party code)
		// must not leak the hold — with the hold stuck, every later
		// Restore keeps the block armed forever and Disconnect can
		// never lift it.
		defer releaseBlockLogged()
	}

	if previous != nil {
		if err := previous.Stop(stopCtx); err != nil {
			err = closeBuilt(created, err)
			releaseBlockLogged()
			m.setLast(previous.Status())
			return nil, err
		}
		m.setLast(previous.Status())
	}
	m.mu.Lock()
	m.current = nil
	m.mu.Unlock()
	createdStartAttempted = true
	if err := created.Start(ctx); err != nil {
		// Stop failed startups because they may still own an engine or
		// device. Capture the failure status before Stop replaces it
		// with disconnected.
		status := created.Status()
		cleanupErr := created.Stop(stopCtx)
		if cleanupErr != nil {
			m.mu.Lock()
			m.current = created
			m.mu.Unlock()
			createdOwned = true
			err = errs.Wrap(errors.Join(err, cleanupErr), errs.CodeOf(cleanupErr), errs.KeyOf(cleanupErr))
			releaseBlockLogged()
			m.setLast(status)
			return nil, err
		}
		if previous != nil {
			// The previous session was stopped for this switch and
			// was working: one rollback attempt from the remembered
			// plan. The caller still gets the switch error, never
			// the rollback's.
			if _, rbErr := m.rollbackToPrevious(stopCtx, err); rbErr == nil {
				releaseBlockLogged()
				return nil, err
			}
		}
		releaseBlockLogged()
		m.setLast(status)
		return nil, err
	}

	m.adopt(created, plan, settings)
	createdOwned = true
	releaseBlockLogged()
	return created, nil
}

// rehandshakeLoop implements the T017 planned re-handshake. It ticks once
// a minute; when the session's transport handshake is overdue for renewal
// it restarts the session on the same plan and exits — the new session
// gets its own worker. The trigger is one-shot per session and
// fail-closed: a disabled policy never starts the loop, a superseded
// session is never touched, and a recent censorship verdict defers the
// restart (spec 17-long-sessions.md §3.5: new handshakes during a freeze
// or block wave only burn more handshakes).
func (m *Manager) rehandshakeLoop(s *Session) {
	policy := m.cfg.Rehandshake
	if policy.MaxAge <= 0 {
		return
	}
	// Session-local jitter source: the deadline must not tick on a grid
	// shared across processes or machines.
	var idSeed uint64
	if id := s.ID(); id != "" {
		idSeed = uint64(id[0])
	}
	r := rand.New(rand.NewPCG(uint64(m.cfg.Now().UnixNano()), idSeed))
	deadline := policy.Deadline(s.HandshakeAt(), r)
	if deadline.IsZero() {
		return
	}
	t := time.NewTicker(time.Minute)
	defer t.Stop()
	for {
		select {
		case <-s.Done():
			return
		case now := <-t.C:
			if m.currentSession() != s {
				return // superseded by a newer session
			}
			if !policy.Overdue(now, deadline) {
				continue
			}
			if frozenRecently(s, now) {
				continue // T017 §3.5: defer while interference is fresh
			}
			if s.deadRecently(now) {
				continue // T029/T047: dead-mode — a fresh handshake cannot revive a shut path
			}
			s.Journal().Append(Event{
				Kind:    EventLog,
				LogLine: "planned re-handshake: the transport handshake outlived the session age policy; restarting on the same plan",
			})
			if err := m.rehandshake(s); err != nil {
				// A busy manager or a failed restart is not fatal: the
				// next tick retries, and the journal line above says why
				// the restart was wanted.
				continue
			}
			return
		}
	}
}

// rehandshake restarts s on the plan and settings it was connected with.
// Connect stops the previous session before starting the new one (the
// guard/TUN cannot be owned twice), so there is a brief gap — shorter
// than a manual reconnect, and announced in the journal by the caller.
func (m *Manager) rehandshake(s *Session) error {
	m.mu.Lock()
	plan, settings, current := m.lastPlan, m.lastSettings, m.current
	m.mu.Unlock()
	if current != s || plan == nil {
		return errors.New("session: re-handshake target was superseded")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	_, err := m.Connect(ctx, plan, settings)
	return err
}

// currentSession returns the running session, or nil.
func (m *Manager) currentSession() *Session {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.current
}

// freezeInterferenceWindow is how long a censorship verdict defers the
// T017 planned re-handshake: the siberian backoff is ~120 s, so five
// minutes keeps new handshakes out of the freeze's tail.
const freezeInterferenceWindow = 5 * time.Minute

// frozenRecently reports whether the session journal carries a recent
// censorship verdict naming interference. A planned re-handshake during
// a freeze or block wave only feeds the censor more handshakes (T017
// §3.5), so the worker defers. Unknown and no-interference verdicts are
// not interference.
func frozenRecently(s *Session, now time.Time) bool {
	for _, e := range s.Journal().Since(0, 256) {
		if e.Kind != EventCensor || e.Censor == nil {
			continue
		}
		if now.Sub(e.Censor.At) > freezeInterferenceWindow {
			continue
		}
		switch e.Censor.Kind {
		case censor.KindUnknown, censor.KindNoInterference:
		default:
			return true
		}
	}
	return false
}

// Disconnect stops the current session and succeeds if none exists.
func (m *Manager) Disconnect(ctx context.Context) error {
	m.mu.Lock()
	if m.busy {
		m.mu.Unlock()
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionBusy,
			"session: another connect or disconnect is running")
	}
	m.busy = true
	current := m.current
	m.mu.Unlock()

	defer m.release()

	if current == nil {
		m.setLast(Status{State: StateDisconnected, ChangedAt: m.cfg.Now()})
		return nil
	}
	err := current.Stop(ctx)
	m.setLast(current.Status())
	if err == nil {
		m.mu.Lock()
		m.current = nil
		m.mu.Unlock()
	}
	return err
}

// Current returns the running session, or nil when there is none.
func (m *Manager) Current() *Session {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.current
}

// Status returns current or last-session state, remaining available after
// session termination.
func (m *Manager) Status() Status {
	m.mu.Lock()
	current, last := m.current, m.last
	m.mu.Unlock()
	// Read live state so failure or reconnection is not reported as an old
	// connected snapshot.
	if current != nil {
		return current.Status()
	}
	return last
}

// KillSwitchBlocked reports whether the kill-switch block is actually in
// force right now, checked against the platform through the guard. The
// session status only records what was asked for; when a table is removed
// out-of-band the wish and the reality diverge, and diagnostics must
// report the reality. Callers fall back to the desired state only when
// the probe itself errors.
func (m *Manager) KillSwitchBlocked(ctx context.Context) (bool, error) {
	return m.cfg.Guard.Blocked(ctx)
}

// Shutdown stops the session and restores system settings for service stop,
// SIGTERM, or self-update.
func (m *Manager) Shutdown(ctx context.Context) error {
	return m.Disconnect(ctx)
}

// release clears the busy flag that serialises connect and disconnect.
func (m *Manager) release() {
	m.mu.Lock()
	m.busy = false
	m.mu.Unlock()
}

// setLast records the status a client will see after the session is gone.
func (m *Manager) setLast(status Status) {
	m.mu.Lock()
	m.last = status
	m.mu.Unlock()
}
