package desync

import (
	"math"
	"time"
)

// ProbeReport is what one candidate's canary probe measured. The caller
// fills it from two fetches: a blocked endpoint (SNI/DNS/HTTP that the
// censor is known to interfere with) and a control endpoint (unblocked,
// ordinary traffic).
//
// The caller decides what "received" means for the blocked endpoint —
// e.g. a completed TLS handshake with a censored SNI, or the expected
// canary bytes. The fitness function trusts the report; garbage in,
// garbage out.
type ProbeReport struct {
	// BlockedOK reports the forbidden content was received with this
	// candidate. The hard gate: false means fitness 0.
	BlockedOK bool
	// BlockedLatency is how long the blocked fetch took.
	BlockedLatency time.Duration

	// ControlOK reports the control fetch completed at all.
	ControlOK bool
	// ControlRST reports an injected RST (or equivalent active
	// interference) on the control fetch. The hard gate: any sign the
	// candidate breaks ordinary TCP zeroes the fitness — this is the
	// Geneva lesson, "don't break the underlying connection".
	ControlRST bool
	// ControlLatency is the control fetch latency with this candidate.
	ControlLatency time.Duration
	// ControlBaseline is the control latency with no desync (MethodNone).
	// Zero disables the latency term.
	ControlBaseline time.Duration

	// ExtraPackets counts the additional packets the candidate injected
	// (splits, fakes, repeats). Brevity: fewer is better, less to
	// fingerprint.
	ExtraPackets int
}

// Score computes the Geneva-style fitness in [0,1]:
//
//	fitness = (forbidden content received) x (TCP not broken) x (brevity)
//
// BlockedOK and a clean control fetch are hard gates (0 when violated);
// latency degradation and extra packets are soft penalties. A candidate
// that fetches the forbidden content without disturbing ordinary traffic
// and with no extra packets scores exactly 1.
func Score(r ProbeReport) float64 {
	if !r.BlockedOK {
		return 0
	}
	// Hard gate: the candidate must not break ordinary TCP. An injected
	// RST or a failed control fetch means the strategy is destructive —
	// Geneva discards these outright, no matter how well they evade.
	if !r.ControlOK || r.ControlRST {
		return 0
	}
	fitness := 1.0
	// Soft penalty: latency regression on ordinary traffic. A candidate
	// that doubles control latency is half as fit.
	if r.ControlBaseline > 0 && r.ControlLatency > r.ControlBaseline {
		fitness *= float64(r.ControlBaseline) / float64(r.ControlLatency)
	}
	// Soft penalty: brevity. Each extra packet is one more thing the
	// censor can fingerprint and one more chance to break a picky server.
	if r.ExtraPackets > 0 {
		fitness *= 1.0 / (1.0 + float64(r.ExtraPackets))
	}
	if math.IsNaN(fitness) || fitness < 0 {
		return 0
	}
	if fitness > 1 {
		return 1
	}
	return fitness
}

// Scored pairs a genome with its measured fitness.
type Scored struct {
	Params Params
	Report ProbeReport
	Score  float64
}

// Working reports whether the candidate evaded without breaking TCP.
func (s Scored) Working() bool { return s.Score > 0 }
