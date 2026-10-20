package session

// Dead-mode payload watchdog (T029 / T048).
//
// The hostile-environment failure mode (Iran's 76-day shutdown, RU
// regional shutdowns): the tunnel handshake succeeds, the session reports
// connected — and no payload ever flows. A handshake check cannot see it;
// only an active payload probe through the tunnel can. The detector
// (deadcheck.DetectDeadSession) is a pure verdict primitive; this file
// is its production wiring:
//
//   - shortly after a session connects, and periodically while it stays
//     connected, one payload measurement runs through the engine
//     (Engine.Delay against the standard connectivity URL, the same
//     primitive the benchmark pipeline uses);
//   - a NoTraffic verdict is journaled as what it is — "connected but no
//     traffic: the network appears shut down; this is not a sora bug" —
//     and marks the session dead-mode;
//   - while dead-mode is fresh, the T017 planned re-handshake defers
//     (see rehandshakeLoop): restarting a handshake cannot revive a shut
//     path, and a retry storm against a censor's shutdown only burns
//     handshakes (T047: do not retry-storm a dead network).
//
// Scope honesty: the probe measures the first outbound only, through the
// engine's own delay primitive. Engines whose Delay returns opaque errors
// yield "unknown", never a false dead-mode claim.

import (
	"context"
	"errors"
	"time"

	"github.com/levvs-one/sora-client/core/deadcheck"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

const (
	// deadSettleDelay lets a freshly connected session settle before the
	// first payload probe: engines are still opening control channels in
	// the first seconds, and a probe then would measure startup, not the
	// network.
	deadSettleDelay = 10 * time.Second
	// deadProbeInterval is the re-probe cadence while connected.
	deadProbeInterval = 2 * time.Minute
	// deadFreshWindow is how long a no-traffic verdict defers the planned
	// re-handshake and suppresses re-probing.
	deadFreshWindow = 10 * time.Minute
	// deadProbeTimeout bounds one engine delay measurement.
	deadProbeTimeout = 10 * time.Second
)

// noteDead records a no-traffic verdict time.
func (s *Session) noteDead(at time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.deadAt = at
}

// clearDead forgets the verdict: payload flowed again.
func (s *Session) clearDead() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.deadAt = time.Time{}
}

// DeadMode reports whether the session's last payload probe proved the
// tunnel carries no traffic and the verdict is still fresh.
func (s *Session) DeadMode() bool {
	return s.deadRecently(time.Now())
}

// deadRecently reports whether a no-traffic verdict is fresh at now.
func (s *Session) deadRecently(now time.Time) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	return !s.deadAt.IsZero() && now.Sub(s.deadAt) < deadFreshWindow
}

// payloadProbe moves real payload through the tunnel: one engine delay
// measurement of the standard connectivity URL via the first outbound.
// It returns a positive byte count when payload flowed. When the engine
// call itself consumed the whole context budget, the returned error is
// the context's — that is what lets the detector name the no-traffic
// signature instead of an opaque engine failure.
func (s *Session) payloadProbe(ctx context.Context) (int64, error) {
	plan := s.Plan()
	if plan == nil || len(plan.Outbounds) == 0 {
		return 0, errors.New("session: no outbound to probe through")
	}
	name := plan.Outbounds[0].Name
	if name == "" {
		return 0, errors.New("session: the first outbound has no engine name")
	}
	if _, err := s.eng.Delay(ctx, name, engine.TestURLProduction, deadProbeTimeout); err != nil {
		if ctx.Err() != nil {
			return 0, ctx.Err()
		}
		return 0, err
	}
	return 1, nil
}

// deadSessionLoop is the production caller of deadcheck.DetectDeadSession.
// It runs while s is the manager's current session: settle, probe, and —
// while payload flows — re-probe on the cadence. A no-traffic verdict is
// journaled once per episode and marks dead-mode; probing then pauses for
// the fresh window instead of hammering a shut network. A later Alive
// verdict clears the mark and is journaled too: recovery is news.
func (m *Manager) deadSessionLoop(s *Session) {
	settle := time.NewTimer(deadSettleDelay)
	defer settle.Stop()
	select {
	case <-s.Done():
		return
	case <-settle.C:
	}
	reported := false
	for {
		if m.currentSession() != s {
			return // superseded by a newer session
		}
		if s.State() != StateConnected {
			return
		}
		ctx, cancel := context.WithTimeout(context.Background(), deadProbeTimeout+5*time.Second)
		v := deadcheck.DetectDeadSession(ctx, deadcheck.DeadSessionInput{
			Probe:   s.payloadProbe,
			Timeout: deadProbeTimeout,
		})
		cancel()
		switch v.State {
		case deadcheck.SessionNoTraffic:
			s.noteDead(m.cfg.Now())
			if !reported {
				reported = true
				s.log.Append(Event{
					Kind:   EventError,
					Reason: errs.CodeTimeout,
					Key:    errs.KeyNetworkTimeout,
					Detail: "dead-mode: the tunnel connected but carries no traffic — " +
						"the network appears to be shut down (or this path drops all payload). " +
						"This is not a sora failure; no server or protocol change helps until " +
						"connectivity returns, and automatic retries are paused.",
				})
			}
		case deadcheck.SessionAlive:
			if reported {
				reported = false
				s.log.Append(Event{
					Kind:    EventLog,
					LogLine: "dead-mode cleared: payload flows through the tunnel again",
				})
			}
			s.clearDead()
		default:
			// Unknown proves nothing either way: keep the previous
			// mark (or its absence) and try again next cadence.
		}
		wait := deadProbeInterval
		if s.deadRecently(m.cfg.Now()) {
			wait = deadFreshWindow
		}
		t := time.NewTimer(wait)
		select {
		case <-s.Done():
			t.Stop()
			return
		case <-t.C:
		}
	}
}
