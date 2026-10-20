package session

import (
	"context"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/censor"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// minProbeInterval bounds how often the failure watcher may actively probe:
// a diagnosis must not become a measurement campaign, and repeated failures
// against the same target teach nothing new within the minute.
const minProbeInterval = time.Minute

// censorshipWatcher diagnoses network-level connect failures in the
// background and publishes the verdict back to the journal, where the control
// plane surfaces it. It reacts purely to journal events: the session runner
// is untouched.
type censorshipWatcher struct {
	session *Session
	det     *censor.Detector
	prober  *censor.Prober
	// probeFn, when set, replaces the prober's Probe. Tests use it to
	// feed recorded attempts without a network (same pattern as
	// probe.Prober's lookupIP seam).
	probeFn func(ctx context.Context, t censor.Target) censor.Attempt
	// shutdown is the manager-shared whitelist/shutdown classifier
	// (T047); nil disables path-mode classification.
	shutdown *censor.ShutdownDetector

	events      <-chan Event
	unsubscribe func()

	// onVerdict, when set, receives each published verdict with the
	// failed server's id. The manager uses it for the T042 hook
	// (expedited subscription refresh after a censorship verdict).
	onVerdict func(censor.Verdict, string)

	mu        sync.Mutex
	lastProbe time.Time
}

// WatchCensorshipFailures attaches the censorship failure watcher to the
// session. It is a no-op for nil arguments and attaches at most once per
// session; the watcher stops with the session. Call it once, right after the
// session starts. The journal subscription happens synchronously, so no
// event between the call and the watcher's first loop is missed.
func (s *Session) WatchCensorshipFailures(det *censor.Detector, prober *censor.Prober) {
	if det == nil || prober == nil {
		return
	}
	s.censorWatchOnce.Do(func() {
		events, unsubscribe := s.log.Subscribe(64)
		w := &censorshipWatcher{
			session:     s,
			det:         det,
			prober:      prober,
			probeFn:     s.censorProbeFn,
			shutdown:    s.shutdownDet,
			events:      events,
			unsubscribe: unsubscribe,
			onVerdict:   s.censorHook,
		}
		go w.run()
	})
}

func (w *censorshipWatcher) run() {
	defer w.unsubscribe()
	done := w.session.Done()
	for {
		select {
		case <-done:
			return
		case ev, ok := <-w.events:
			if !ok {
				return
			}
			w.onEvent(ev)
		}
	}
}

// onEvent handles one journal event. Only network-level failures are
// interesting: local failures (bad plan, auth, engine crash) are not
// censorship questions, and probing them would be noise.
func (w *censorshipWatcher) onEvent(ev Event) {
	if ev.Kind != EventError {
		return
	}
	switch censorActionFor(ev.Reason, ev.Key) {
	case censorSkip:
		return
	case censorRefused:
		// No probe needed: the RST answer is the evidence. A server that
		// answers and refuses is alive — report it so the user stops
		// blaming the path. Still rate-limited: a flapping closed port
		// must not flood the journal with identical verdicts.
		if !w.claimProbeSlot() {
			return
		}
		w.publish(censor.Verdict{
			Kind:        censor.KindNoInterference,
			Confidence:  0.85,
			Explanation: "The server answered and refused the connection itself. It is reachable, so this does not look like censorship.",
			Evidence:    []string{"the server answered the connection attempt and refused it"},
			At:          time.Now().UTC(),
		})
		return
	}

	target, ok := censorTargetOf(w.session.Plan())
	if !ok {
		return
	}
	if !w.claimProbeSlot() {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	probe := w.prober.Probe
	if w.probeFn != nil {
		probe = w.probeFn
	}
	attempt := probe(ctx, target)
	attempt.ServerID = serverIDOf(w.session.Plan())
	attempt.KnownGoodHost = w.knownGood()
	verdict := w.det.Detect(attempt)
	// T047: feed the direct-path attempt to the whitelist/shutdown
	// classifier. The probe is direct by construction (censor.Prober
	// dials without a tunnel), which is exactly the feeding contract.
	// A path-mode verdict replaces the per-server verdict: under a
	// whitelist the server is not the problem, and under a shutdown
	// nothing is. It also skips the T042 expedite hook on purpose —
	// under a whitelist a fresh subscription list changes nothing, and
	// under a shutdown there is no path to fetch one with. Retrying is
	// not a strategy against either mode.
	if w.shutdown != nil {
		w.shutdown.Observe(attempt)
		if a := w.shutdown.Assess(); a.Mode != censor.PathNormal {
			merged := verdict
			merged.Explanation = a.Explanation
			merged.Evidence = append(append([]string{}, a.Evidence...), merged.Evidence...)
			if a.Confidence > merged.Confidence {
				merged.Confidence = a.Confidence
			}
			w.session.log.Append(Event{
				Kind:   EventCensor,
				Detail: "network mode: " + a.Explanation,
				Censor: &merged,
			})
			return
		}
	}
	if verdict.Kind == censor.KindUnknown {
		// Stay silent: an "unknown" verdict on every failure is noise, and
		// the engine already reported the failure itself.
		return
	}
	w.publish(verdict)
}

// publish appends the verdict to the journal. The control plane surfaces the
// Detail line through the existing event stream; the structured verdict rides
// along for future consumers. The onVerdict hook fires after the journal
// append: consumers (T042 expedited refresh) act on the same verdict the
// user sees, never on a hidden one.
func (w *censorshipWatcher) publish(v censor.Verdict) {
	w.session.log.Append(Event{
		Kind:   EventCensor,
		Detail: "censorship check: " + v.Explanation,
		Censor: &v,
	})
	if w.onVerdict != nil {
		w.onVerdict(v, serverIDOf(w.session.Plan()))
	}
}

// knownGood reports whether the journal shows this host working before: the
// cheapest strong signal against "the name never existed".
func (w *censorshipWatcher) knownGood() bool {
	for _, e := range w.session.log.Since(0, 256) {
		if e.Kind == EventState && e.State == StateConnected {
			return true
		}
	}
	return false
}

// claimProbeSlot rate-limits verdict publications: at most one per interval
// per session, whether the verdict cost an active probe or was answered
// directly. Only the watcher's goroutine calls it, the mutex is for
// discipline.
func (w *censorshipWatcher) claimProbeSlot() bool {
	w.mu.Lock()
	defer w.mu.Unlock()
	now := time.Now()
	if now.Sub(w.lastProbe) < minProbeInterval {
		return false
	}
	w.lastProbe = now
	return true
}

// censorActionFor decides what a journal error deserves.
type censorAction int

const (
	// censorSkip means: not a censorship question, do nothing.
	censorSkip censorAction = iota
	// censorProbe means: network-level failure, worth one active probe.
	censorProbe
	// censorRefused means: answer the verdict directly, no probe needed.
	censorRefused
)

func censorActionFor(code errs.Code, key errs.Key) censorAction {
	switch key {
	case errs.KeyConnectionRefused:
		return censorRefused
	case errs.KeyTLSCertificate:
		// A bad certificate is a portal, a corporate MITM, or a broken
		// server — indistinguishable here. Probing would repeat the same
		// handshake and learn nothing; claiming interference would be a lie.
		return censorSkip
	case errs.KeyNetworkTimeout, errs.KeyNetworkFailed:
		return censorProbe
	}
	switch code {
	case errs.CodeTimeout, errs.CodeTLS:
		return censorProbe
	default:
		return censorSkip
	}
}

// censorTargetOf extracts the probe target from the plan's first usable
// outbound: the server the failed attempt was aimed at.
func censorTargetOf(plan *engine.Plan) (censor.Target, bool) {
	if plan == nil {
		return censor.Target{}, false
	}
	for _, ob := range plan.Outbounds {
		if strings.TrimSpace(ob.Server) == "" || ob.Port == 0 {
			continue
		}
		sni := ob.TLS.ServerName
		if sni == "" {
			sni = ob.Server
		}
		return censor.Target{
			Host:     ob.Server,
			Port:     int(ob.Port),
			SNI:      sni,
			TLS:      ob.TLS.Enabled,
			Protocol: string(ob.Protocol),
		}, true
	}
	return censor.Target{}, false
}

func serverIDOf(plan *engine.Plan) string {
	if plan == nil || len(plan.Outbounds) == 0 {
		return ""
	}
	return plan.Outbounds[0].ID
}
