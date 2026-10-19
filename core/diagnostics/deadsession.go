package diagnostics

import (
	"context"
	"errors"
	"time"
)

// "Connected but no traffic" detector (T029, P38-5).
//
// The Iranian failure mode: the tunnel handshake succeeds, the session
// reports connected, but no payload flows (selective throttling /
// post-connect drop). A handshake check cannot see it; only a payload
// probe can. This detector is pure: the caller supplies the probe (fetch
// N bytes through the tunnel), the detector bounds it and names the
// outcome. Wiring the probe into the session manager and the failover
// policy is specified separately — this is the verdict primitive.

// DeadSessionState is the payload-health outcome.
type DeadSessionState int

const (
	// SessionAlive means payload flowed through the tunnel.
	SessionAlive DeadSessionState = iota
	// SessionNoTraffic means the tunnel is up but no payload arrived
	// within the budget: the "connected but no traffic" signature.
	SessionNoTraffic
	// SessionUnknown means the probe itself failed: the tunnel state is
	// unproven, which is not the same as "no traffic".
	SessionUnknown
)

// String renders the state for logs and the meter UI.
func (s DeadSessionState) String() string {
	switch s {
	case SessionAlive:
		return "alive"
	case SessionNoTraffic:
		return "no_traffic"
	default:
		return "unknown"
	}
}

// DeadSessionInput configures one payload-health probe.
type DeadSessionInput struct {
	// Probe moves payload through the tunnel and reports bytes
	// transferred. It must honor ctx.
	Probe func(ctx context.Context) (int64, error)
	// Timeout bounds the probe. Zero selects the default.
	Timeout time.Duration
}

// DeadSessionVerdict is the probe outcome.
type DeadSessionVerdict struct {
	State    DeadSessionState
	Bytes    int64
	Elapsed  time.Duration
	Evidence []string
}

// defaultDeadSessionTimeout bounds one payload probe: long enough for a
// slow tunnel, short enough to fail over fast (P38-5).
const defaultDeadSessionTimeout = 10 * time.Second

// isProbeTimeout reports whether err means the probe exhausted its
// budget (context deadline or a network timeout), as opposed to failing
// for its own reasons.
func isProbeTimeout(err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return true
	}
	var nerr interface{ Timeout() bool }
	if errors.As(err, &nerr) && nerr.Timeout() {
		return true
	}
	return false
}

// DetectDeadSession runs the payload probe and classifies the session.
// A hanging probe with zero bytes is the hostile-network signature; a
// probe that errors for its own reasons is Unknown, never a false
// "no traffic" claim.
func DetectDeadSession(ctx context.Context, in DeadSessionInput) DeadSessionVerdict {
	timeout := in.Timeout
	if timeout <= 0 {
		timeout = defaultDeadSessionTimeout
	}
	if in.Probe == nil {
		return DeadSessionVerdict{State: SessionUnknown, Evidence: []string{
			"no probe supplied: the session state is unproven",
		}}
	}
	qctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	start := time.Now()
	n, err := in.Probe(qctx)
	elapsed := time.Since(start)
	if ctx.Err() != nil {
		// The caller gave up first: nothing is proven about the network,
		// and claiming "no traffic" would blame the path for our own
		// cancellation.
		return DeadSessionVerdict{State: SessionUnknown, Bytes: n, Elapsed: elapsed, Evidence: []string{
			"the probe was cancelled by the caller before proving anything",
		}}
	}
	if err != nil {
		if n == 0 && isProbeTimeout(err) {
			// The probe ran its whole budget and nothing arrived: the
			// hostile "connected but no traffic" signature.
			return DeadSessionVerdict{State: SessionNoTraffic, Elapsed: elapsed, Evidence: []string{
				"the tunnel is up but no payload arrived within the budget: connected but no traffic",
			}}
		}
		// Any other failure (refused, DNS, TLS) means the probe could not
		// run: the tunnel state is unproven, not "no traffic".
		return DeadSessionVerdict{State: SessionUnknown, Bytes: n, Elapsed: elapsed, Evidence: []string{
			"the payload probe failed before proving anything: " + err.Error(),
		}}
	}
	if n == 0 {
		return DeadSessionVerdict{State: SessionNoTraffic, Elapsed: elapsed, Evidence: []string{
			"the probe completed with zero bytes: connected but no traffic",
		}}
	}
	return DeadSessionVerdict{State: SessionAlive, Bytes: n, Elapsed: elapsed, Evidence: []string{
		"payload flowed through the tunnel",
	}}
}
