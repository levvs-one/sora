package censor

import (
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// LogEvent is the coarse journal view the detector can fall back to when no
// instrumented attempt exists: the session journal records what failed and
// why, but not wire timings. The detector treats such attempts as sparse
// evidence — enough for obvious signatures (refused, NXDOMAIN), never enough
// for a confident interference claim.
type LogEvent struct {
	At     time.Time
	Kind   string // journal event kind: "state", "error", "log", ...
	State  string // session state for Kind == "state"
	Detail string
	Code   errs.Code
	Key    errs.Key
}

// AttemptFromLog builds the best attempt the journal history supports. It is
// intentionally lossy: journal lines carry no timings or byte counts, so the
// result feeds the detector's low-confidence paths. Callers that need a real
// diagnosis should run Prober instead.
func AttemptFromLog(serverID string, target Target, events []LogEvent) Attempt {
	a := Attempt{ServerID: serverID, Target: target}
	for _, e := range events {
		if a.StartedAt.IsZero() && !e.At.IsZero() {
			a.StartedAt = e.At
		}
		switch e.Kind {
		case "state":
			if strings.Contains(strings.ToLower(e.State), "connected") {
				a.KnownGoodHost = true
			}
		case "error":
			if ev, ok := errorEvent(e); ok {
				a.Events = append(a.Events, ev)
			}
		}
	}
	return a
}

// errorEvent maps a journal error to the closest wire event. The mapping is
// conservative: anything it cannot recognize is dropped rather than guessed,
// because a guessed event manufactures evidence.
func errorEvent(e LogEvent) (Event, bool) {
	out := Event{At: e.At, Stage: StageUnknown, What: WhatError, Detail: string(e.Key)}
	d := strings.ToLower(e.Detail + " " + string(e.Key))
	switch {
	case strings.Contains(d, "refus"):
		out.Stage, out.Detail = StageTCP, "refused"
		return out, true
	case strings.Contains(d, "nxdomain") || strings.Contains(d, "no such host"):
		out.Stage, out.Detail = StageDNS, "nxdomain"
		return out, true
	case strings.Contains(d, "cert"):
		out.Stage, out.Detail = StageTLS, "certificate: "+trimDetail(e.Detail)
		return out, true
	case strings.Contains(d, "timeout") || strings.Contains(d, "deadline"):
		// Stage unknown: the journal does not record which leg stalled.
		// Guessing TCP would manufacture an IP-blocking claim from a
		// coarse line.
		out.What, out.Detail = WhatLocalTimeout, "timeout"
		return out, true
	case strings.Contains(d, "reset"):
		// Stage unknown: a coarse "reset" line cannot say whether the SYN,
		// the handshake, or the session died. Attributing it to TCP would
		// manufacture an RST-injection claim.
		out.What, out.Detail = WhatRemoteReset, "reset"
		return out, true
	case strings.Contains(d, "handshake") || strings.Contains(d, "tls"):
		// Stage unknown: without wire detail this is only "something failed
		// around TLS". It feeds the certificate rule's honest Unknown, and
		// nothing else.
		return out, true
	}
	return Event{}, false
}

func trimDetail(s string) string {
	s = strings.TrimSpace(s)
	if len(s) > 120 {
		s = s[:120] + "…"
	}
	return s
}
