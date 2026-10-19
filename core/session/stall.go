package session

// Hysteria2 stall watchdog (S4). Some servers stop moving traffic without
// dropping the tunnel (hysteria2 v2.11.0 "stall without disconnect", QUIC
// window exhaustion, fixed upstream in PR #1703): the session stays
// established while every stream is dead. The detector below watches for
// exactly that — established, zero payload bytes over a window, while
// connections are open — and reopens the flows through the same mechanism
// network changes use, so applications reconnect on a fresh path.
//
// The detector is deliberately conservative:
//   - idle is not a stall: with no open connections the stall clock resets;
//   - the first seconds after (re)connect are a warmup: handshakes are still
//     settling and zero bytes are expected;
//   - consecutive stall reconnects back off exponentially so a wedged server
//     cannot spin the session in a reconnect loop;
//   - engines without per-connection visibility (Xray) cannot feed the
//     detector, so it stays dormant for them.

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

const (
	// stallWindow is how long the tunnel may move zero payload bytes while
	// connections are open before it counts as stalled (S4: 15–20 s).
	stallWindow = 20 * time.Second
	// stallWarmup is the grace period after (re)connect during which the
	// stall clock does not run.
	stallWarmup = 10 * time.Second
	// stallBackoffBase is the minimum gap between stall reconnects. It
	// doubles on every consecutive stall without intervening traffic and
	// resets once bytes move again.
	stallBackoffBase = time.Minute
	stallBackoffMax  = 8 * time.Minute
)

// stallWatch tracks payload progress while the session is connected.
// Observe it once per stats tick; it reports true when a stall reconnect
// is due. It is a pure byte counter: demand is "at least one open
// connection", so an idle tunnel with nothing open never trips it.
type stallWatch struct {
	mu            sync.Mutex
	now           func() time.Time
	connectedAt   time.Time
	baselined     bool
	lastTotal     uint64
	lastProgress  time.Time
	lastReconnect time.Time
	backoff       time.Duration
}

func newStallWatch() *stallWatch {
	return &stallWatch{now: time.Now, backoff: stallBackoffBase}
}

// markConnected starts the warmup after the session (re)connects. A fresh
// episode begins: the previous byte baseline is meaningless on the new
// path, but the reconnect backoff survives — a reconnect that did not
// restore traffic must not reset the loop protection.
func (w *stallWatch) markConnected() {
	w.mu.Lock()
	defer w.mu.Unlock()
	now := w.now()
	w.connectedAt = now
	w.lastProgress = now
	w.baselined = false
}

// observe records one sample: total payload bytes across the open
// connections and whether any connection is open (demand). It reports true
// when the stall window elapsed with demand but zero payload bytes,
// outside warmup and outside the reconnect backoff.
func (w *stallWatch) observe(total uint64, demand bool) bool {
	w.mu.Lock()
	defer w.mu.Unlock()
	now := w.now()
	if !w.baselined {
		w.lastTotal, w.lastProgress, w.baselined = total, now, true
		return false
	}
	if total != w.lastTotal {
		if total > w.lastTotal {
			// Bytes moved: the tunnel is alive, the episode ends, and
			// the reconnect backoff relaxes.
			w.backoff = stallBackoffBase
		}
		// A drop means the counters reset under a restarted engine or
		// freshly dropped flows: rebaseline on the new counters but
		// keep the backoff. A stall reconnect drops every flow, so
		// relaxing the backoff on a drop would reset the loop
		// protection on every trigger and the backoff could never
		// compound.
		w.lastTotal, w.lastProgress = total, now
		return false
	}
	if !demand {
		// Idle is not a stall: nothing wants the tunnel right now.
		w.lastProgress = now
		return false
	}
	if now.Sub(w.connectedAt) < stallWarmup {
		// Still settling after establish; the stall clock does not run.
		w.lastProgress = now
		return false
	}
	if now.Sub(w.lastProgress) < stallWindow {
		return false
	}
	if now.Sub(w.lastReconnect) < w.backoff {
		return false
	}
	w.lastReconnect = now
	w.lastProgress = now
	w.backoff = min(w.backoff*2, stallBackoffMax)
	return true
}

// checkStall samples the live connections and triggers a stall reconnect
// when the tunnel is established but moves no payload despite demand. It
// runs on the stats tick; transient read failures skip the tick instead of
// counting as a stall.
func (s *Session) checkStall(ctx context.Context) {
	if s.State() != StateConnected {
		return
	}
	tracker, ok := s.eng.(engine.ConnectionTracker)
	if !ok {
		// No per-connection visibility (Xray): the detector cannot run.
		return
	}
	conns, err := tracker.Connections(ctx)
	if err != nil {
		return
	}
	var total uint64
	for _, c := range conns {
		total += c.Upload + c.Download
	}
	if s.stall.observe(total, len(conns) > 0) {
		s.reconnectStalled(ctx, len(conns))
	}
}

// reconnectStalled journals the stall and reopens the flows through the
// existing reconnection mechanism: drop live connections so applications
// reconnect, or reapply the plan on engines without bulk close. The session
// state stays connected — the engine process itself is healthy, only the
// tunnel stopped moving traffic.
func (s *Session) reconnectStalled(ctx context.Context, open int) {
	if s.State() != StateConnected {
		return
	}
	s.log.Append(Event{
		Kind:   EventError,
		Reason: errs.CodeUnavailable,
		Key:    errs.KeyEngineStalled,
		Detail: fmt.Sprintf("the tunnel moved no traffic for %s with %d connections open; reopening flows",
			stallWindow, open),
	})
	s.reopenFlows(ctx)
}
