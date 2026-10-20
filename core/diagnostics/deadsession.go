package diagnostics

import (
	"context"

	"github.com/levvs-one/sora-client/core/deadcheck"
)

// Aliases keeping the T029 detector's historical home: the implementation
// lives in core/deadcheck (a leaf package — session needs the detector and
// diagnostics already imports session, so the verdict primitive cannot
// stay here without an import cycle).
type (
	DeadSessionState   = deadcheck.DeadSessionState
	DeadSessionInput   = deadcheck.DeadSessionInput
	DeadSessionVerdict = deadcheck.DeadSessionVerdict
)

const (
	SessionAlive     = deadcheck.SessionAlive
	SessionNoTraffic = deadcheck.SessionNoTraffic
	SessionUnknown   = deadcheck.SessionUnknown
)

// DetectDeadSession runs the payload probe and classifies the session.
// Production status (2026-10-20): WIRED via the session manager's
// deadSessionLoop (core/session/deadmode.go), which payload-probes every
// connected session through its engine.
func DetectDeadSession(ctx context.Context, in DeadSessionInput) DeadSessionVerdict {
	return deadcheck.DetectDeadSession(ctx, in)
}
