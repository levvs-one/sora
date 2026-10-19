package control

import (
	"context"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/censor"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	censorv1 "github.com/levvs-one/sora-client/core/gen/sora/censor/v1"
	"github.com/levvs-one/sora-client/core/session"
)

// DetectCensorship implements sora.censor.v1.CensorControl. It classifies one
// failed connection attempt — from the session's journal history, from
// client-supplied wire events, or from a fresh active probe — and returns the
// verdict with a suggested obfuscation preset.
//
// The RPC never claims more than the evidence supports: sparse input yields
// an UNKNOWN verdict with low confidence, not a guess.
func (s *Server) DetectCensorship(ctx context.Context, req *censorv1.DetectCensorshipRequest) (*censorv1.DetectCensorshipResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.auth.Check(req.GetControlAuthenticator()); err != nil {
		return nil, transportStatus(err)
	}

	attempt, probeRan, err := s.censorAttempt(ctx, req)
	if err != nil {
		return &censorv1.DetectCensorshipResponse{Error: toWire(err, nil, id)}, nil
	}
	v := censor.Detector{}.Detect(attempt)
	return &censorv1.DetectCensorshipResponse{
		Verdict:  censorVerdictToProto(v),
		ProbeRan: probeRan,
	}, nil
}

// censorAttempt builds the detector input from the request: a fresh active
// probe when asked, the named session's journal history when a session is
// named, or the client-supplied events otherwise.
func (s *Server) censorAttempt(ctx context.Context, req *censorv1.DetectCensorshipRequest) (censor.Attempt, bool, error) {
	if req.GetRunActiveProbe() {
		target, err := censorTargetFromRequest(req)
		if err != nil {
			return censor.Attempt{}, false, err
		}
		pctx, cancel := context.WithTimeout(ctx, 30*time.Second)
		defer cancel()
		attempt := (&censor.Prober{}).Probe(pctx, target)
		attempt.ServerID = strings.TrimSpace(req.GetServerId())
		attempt.KnownGoodHost = req.GetKnownGoodHost()
		return attempt, true, nil
	}
	if sessionID := strings.TrimSpace(req.GetSessionId()); sessionID != "" {
		sess := s.sessions.Current()
		if sess == nil || sess.ID() != sessionID {
			return censor.Attempt{}, false, errs.Newf(errs.CodeNotFound, errs.KeyUnknownSession,
				"control: no live session %q", sessionID)
		}
		attempt := censor.AttemptFromLog(sessionID, censorTargetFromPlan(sess.Plan()), censorLogEvents(sess.Journal()))
		if sid := strings.TrimSpace(req.GetServerId()); sid != "" {
			attempt.ServerID = sid
		}
		return attempt, false, nil
	}
	events, startedAt := censorEventsFromProto(req.GetEvents())
	return censor.Attempt{
		ServerID:      strings.TrimSpace(req.GetServerId()),
		Target:        censorTargetFromRequestOrEmpty(req),
		KnownGoodHost: req.GetKnownGoodHost(),
		StartedAt:     startedAt,
		Events:        events,
	}, false, nil
}

// censorTargetFromRequest validates the probe target. The core dials it, so
// the host and port are validated like any other untrusted input.
func censorTargetFromRequest(req *censorv1.DetectCensorshipRequest) (censor.Target, error) {
	host := strings.TrimSpace(req.GetTargetHost())
	port := int(req.GetTargetPort())
	if host == "" || port <= 0 || port > 65535 {
		return censor.Target{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: probe needs a valid target host and port")
	}
	if strings.ContainsAny(host, " \t\r\n") {
		return censor.Target{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: probe target host is malformed")
	}
	return censor.Target{
		Host:     host,
		Port:     port,
		SNI:      strings.TrimSpace(req.GetSni()),
		TLS:      true,
		Protocol: strings.TrimSpace(req.GetProtocol()),
	}, nil
}

func censorTargetFromRequestOrEmpty(req *censorv1.DetectCensorshipRequest) censor.Target {
	t, err := censorTargetFromRequest(req)
	if err != nil {
		return censor.Target{Protocol: strings.TrimSpace(req.GetProtocol())}
	}
	return t
}

// censorTargetFromPlan reads the probe target from the session plan's first
// outbound: the server the failed attempt was aimed at.
func censorTargetFromPlan(plan *engine.Plan) censor.Target {
	if plan == nil {
		return censor.Target{}
	}
	for _, ob := range plan.Outbounds {
		if strings.TrimSpace(ob.Server) == "" {
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
		}
	}
	return censor.Target{}
}

// censorLogEvents adapts journal history to the detector's coarse input.
func censorLogEvents(j *session.Journal) []censor.LogEvent {
	if j == nil {
		return nil
	}
	events := j.Since(0, 256)
	out := make([]censor.LogEvent, 0, len(events))
	for _, e := range events {
		out = append(out, censor.LogEvent{
			At:     e.At,
			Kind:   string(e.Kind),
			State:  e.State.String(),
			Detail: e.Detail,
			Code:   e.Reason,
			Key:    e.Key,
		})
	}
	return out
}

func censorEventsFromProto(evs []*censorv1.AttemptEvent) ([]censor.Event, time.Time) {
	timed := false
	for _, e := range evs {
		if e != nil && e.GetOffsetMs() != 0 {
			timed = true
			break
		}
	}
	out := make([]censor.Event, 0, len(evs))
	if !timed {
		// The client sent no timing at all. Do not invent it: anchoring
		// every event to "now" would read as an instant reset and let the
		// time-windowed signatures claim on ordering alone. Leave the
		// attempt timing-free so those rules stay silent.
		for _, e := range evs {
			if e == nil {
				continue
			}
			out = append(out, censor.Event{
				Stage:  censorStageFromProto(e.GetStage()),
				What:   censorWhatFromProto(e.GetKind()),
				Detail: e.GetDetail(),
			})
		}
		return out, time.Time{}
	}
	// Offset-only input: anchor every event to one base so the signatures
	// using time-to-break keep working.
	base := time.Now().UTC()
	for _, e := range evs {
		if e == nil {
			continue
		}
		out = append(out, censor.Event{
			Stage:  censorStageFromProto(e.GetStage()),
			What:   censorWhatFromProto(e.GetKind()),
			Detail: e.GetDetail(),
			At:     base.Add(time.Duration(e.GetOffsetMs()) * time.Millisecond),
		})
	}
	return out, base
}

func censorVerdictToProto(v censor.Verdict) *censorv1.CensorshipVerdict {
	out := &censorv1.CensorshipVerdict{
		Kind:        censorKindToProto(v.Kind),
		Confidence:  v.Confidence,
		Explanation: v.Explanation,
		Evidence:    v.Evidence,
	}
	if v.HasProfile {
		out.SuggestedProfile = &censorv1.ObfuscationProfileRef{
			Preset:      v.Profile.Preset,
			DisplayName: v.Profile.DisplayName,
			Why:         v.Profile.Why,
		}
	}
	return out
}

func censorKindToProto(k censor.Kind) censorv1.CensorshipKind {
	switch k {
	case censor.KindNoInterference:
		return censorv1.CensorshipKind_CENSORSHIP_KIND_NO_INTERFERENCE
	case censor.KindRSTInjection:
		return censorv1.CensorshipKind_CENSORSHIP_KIND_RST_INJECTION
	case censor.KindHandshakeTimeout:
		return censorv1.CensorshipKind_CENSORSHIP_KIND_HANDSHAKE_TIMEOUT
	case censor.KindDNSPoisoning:
		return censorv1.CensorshipKind_CENSORSHIP_KIND_DNS_POISONING
	case censor.KindSNIBlocking:
		return censorv1.CensorshipKind_CENSORSHIP_KIND_SNI_BLOCKING
	case censor.KindIPBlocking:
		return censorv1.CensorshipKind_CENSORSHIP_KIND_IP_BLOCKING
	default:
		return censorv1.CensorshipKind_CENSORSHIP_KIND_UNKNOWN
	}
}

func censorStageFromProto(s censorv1.AttemptStage) censor.Stage {
	switch s {
	case censorv1.AttemptStage_ATTEMPT_STAGE_DNS:
		return censor.StageDNS
	case censorv1.AttemptStage_ATTEMPT_STAGE_TCP:
		return censor.StageTCP
	case censorv1.AttemptStage_ATTEMPT_STAGE_TLS:
		return censor.StageTLS
	case censorv1.AttemptStage_ATTEMPT_STAGE_APP:
		return censor.StageApp
	case censorv1.AttemptStage_ATTEMPT_STAGE_DATA:
		return censor.StageData
	default:
		return censor.StageUnknown
	}
}

func censorWhatFromProto(w censorv1.AttemptEventKind) censor.What {
	switch w {
	case censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_RESOLVED:
		return censor.WhatResolved
	case censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_CONNECTED:
		return censor.WhatConnected
	case censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_SENT:
		return censor.WhatSent
	case censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_RECEIVED:
		return censor.WhatReceived
	case censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_REMOTE_RESET:
		return censor.WhatRemoteReset
	case censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_REMOTE_CLOSE:
		return censor.WhatRemoteClose
	case censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_LOCAL_TIMEOUT:
		return censor.WhatLocalTimeout
	case censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_TLS_ALERT:
		return censor.WhatTLSAlert
	case censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_ERROR:
		return censor.WhatError
	default:
		return censor.WhatUnknown
	}
}

// Compile-time contract: Server serves sora.censor.v1 alongside sora.core.v1.
// (The UnimplementedCensorControlServer embedding lives on the Server struct
// in server.go.)
var _ censorv1.CensorControlServer = (*Server)(nil)
