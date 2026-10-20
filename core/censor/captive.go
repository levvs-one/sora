package censor

import (
	"context"
	"io"
	"net/http"
	"strings"
	"time"
)

// Captive portal detection (T014, CENSORSHIP-METER P0.3).
//
// A hotel/airport portal intercepts plain HTTP and answers with its own
// page or a redirect. Without this check, every portal looks like mass
// censorship ("everything is blocked!") and the client cries wolf: the
// RFC 8910-era OS endpoints exist precisely to answer this question
// deterministically — the exact expected response (204 / a known body)
// means "no portal", anything else served instead means "portal".
//
// The check is DIRECT-path only (a portal sits between the device and
// the network; probing through the tunnel would hide it) and read-only:
// it follows no login flow, it only names the state.
type CaptiveState int

const (
	// CaptiveUnknown means no endpoint answered: the network is down or
	// filtered below HTTP — no claim either way.
	CaptiveUnknown CaptiveState = iota
	// CaptiveNone means an OS endpoint answered exactly as specified:
	// no portal is intercepting.
	CaptiveNone
	// CaptivePortal means an endpoint answered with somebody else's
	// content: a redirect or a foreign body.
	CaptivePortal
)

// String renders the state for reports.
func (s CaptiveState) String() string {
	switch s {
	case CaptiveNone:
		return "none"
	case CaptivePortal:
		return "portal"
	default:
		return "unknown"
	}
}

// CaptiveReport is the check's answer.
type CaptiveReport struct {
	State    CaptiveState
	Evidence []string
}

// captiveEndpoint is one OS connectivity-check URL and its exact
// expected answer: a status code and, when the endpoint returns a body,
// a required substring.
type captiveEndpoint struct {
	name       string
	url        string
	wantStatus int
	wantBody   string
}

// defaultCaptiveEndpoints are the well-known OS endpoints (Android,
// Apple, Windows): three vendors, so one vendor's outage is not a
// portal verdict.
func defaultCaptiveEndpoints() []captiveEndpoint {
	return []captiveEndpoint{
		{name: "android", url: "http://connectivitycheck.gstatic.com/generate_204", wantStatus: http.StatusNoContent},
		{name: "apple", url: "http://captive.apple.com/hotspot-detect.html", wantStatus: http.StatusOK, wantBody: "Success"},
		{name: "windows", url: "http://www.msftconnecttest.com/connecttest.txt", wantStatus: http.StatusOK, wantBody: "Microsoft Connect Test"},
	}
}

const captiveBodyLimit = 4096

// DetectCaptivePortal probes the OS connectivity endpoints DIRECTLY.
// The client must not follow redirects (a redirect IS the portal
// signal) and must not use a proxy (the question is about this path).
// Injected endpoints/client are a test seam.
func DetectCaptivePortal(ctx context.Context, endpoints []captiveEndpoint, client *http.Client) CaptiveReport {
	if len(endpoints) == 0 {
		endpoints = defaultCaptiveEndpoints()
	}
	if client == nil {
		client = &http.Client{
			Timeout:   5 * time.Second,
			Transport: &http.Transport{Proxy: nil},
			CheckRedirect: func(*http.Request, []*http.Request) error {
				return http.ErrUseLastResponse
			},
		}
	}
	var answered, nones int
	var evidence []string
	for _, ep := range endpoints {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, ep.url, nil)
		if err != nil {
			continue
		}
		resp, err := client.Do(req)
		if err != nil {
			continue // no answer is no signal
		}
		body, _ := io.ReadAll(io.LimitReader(resp.Body, captiveBodyLimit))
		_ = resp.Body.Close()
		answered++
		switch {
		case resp.StatusCode == ep.wantStatus && (ep.wantBody == "" || strings.Contains(string(body), ep.wantBody)):
			nones++
			evidence = append(evidence, ep.name+": exact expected answer")
		case resp.StatusCode >= 300 && resp.StatusCode < 400:
			evidence = append(evidence, ep.name+": redirected ("+resp.Status+") to "+resp.Header.Get("Location"))
			return CaptiveReport{State: CaptivePortal, Evidence: evidence}
		default:
			evidence = append(evidence, ep.name+": foreign answer ("+resp.Status+")")
			return CaptiveReport{State: CaptivePortal, Evidence: evidence}
		}
	}
	if answered == 0 {
		return CaptiveReport{State: CaptiveUnknown, Evidence: []string{"no connectivity endpoint answered"}}
	}
	if nones == answered {
		return CaptiveReport{State: CaptiveNone, Evidence: evidence}
	}
	// Some answered exactly, some not at all: not a portal claim — a
	// dead endpoint is an outage, not an interception.
	return CaptiveReport{State: CaptiveNone, Evidence: evidence}
}
