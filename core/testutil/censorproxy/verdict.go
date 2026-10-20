package censorproxy

import "fmt"

// Verdict thresholds. CALIBRATION NOTE: these are initial values; calibrate
// on the first 2-3 runs against real browser baselines, then freeze. Changing
// a threshold is a separate commit with justification, otherwise the metric
// drifts to fit the result.
const (
	// BlockerThreshold: aggregate score >= 0.7 blocks the release.
	BlockerThreshold = 0.7
	// WarningThreshold: score in [0.4, 0.7) is a warning with mandatory review.
	WarningThreshold = 0.4
)

// Detector weights for the aggregate score; they must sum to 1.0.
// CALIBRATION NOTE: same rule as thresholds — calibrate on real runs,
// change in a separate commit.
var detectorWeights = []struct {
	name   string
	weight float64
	fn     detector
}{
	{"first-packet-entropy", 0.15, firstPacketEntropy},
	{"handshake-sizes", 0.10, handshakeSizes},
	{"in-out-balance", 0.10, inOutBalance},
	{"inter-arrival", 0.05, interArrival},
	{"ja4-freshness", 0.35, ja4Freshness},
	{"sni-consistency", 0.25, sniConsistency},
}

// Level is the release-gate verdict level.
type Level int

const (
	// LevelOK: score < 0.4.
	LevelOK Level = iota
	// LevelWarning: score in [0.4, 0.7).
	LevelWarning
	// LevelBlocker: score >= 0.7, release blocker.
	LevelBlocker
	// LevelInsufficient: not enough data for a verdict.
	LevelInsufficient
)

// String renders the level in Russian for CLI output.
func (l Level) String() string {
	switch l {
	case LevelOK:
		return "OK"
	case LevelWarning:
		return "WARNING"
	case LevelBlocker:
		return "BLOCKER"
	default:
		return "INSUFFICIENT"
	}
}

// Verdict is the stand outcome for one flow.
type Verdict struct {
	// Level is the gate level derived from Score.
	Level Level
	// Score is the weighted aggregate in [0,1]; 0 when Insufficient.
	Score float64
	// Results holds every detector outcome in run order.
	Results []DetectorResult
	// Insufficient means the flow was too short for any verdict: the flow
	// is "insufficient data", never "clean".
	Insufficient bool
	// Reason explains an insufficient verdict.
	Reason string
}

// Run executes all L1/L2 detectors over the flow and aggregates the verdict.
func Run(f *Flow, cfg Config) Verdict {
	cfg = cfg.withDefaults()
	if len(f.Packets) < cfg.MinPackets {
		return Verdict{
			Level:        LevelInsufficient,
			Insufficient: true,
			Reason: fmt.Sprintf("недостаточно данных: %d пакетов < минимума %d — поток не «чистый», а неизмеримый",
				len(f.Packets), cfg.MinPackets),
		}
	}
	var sum, wsum float64
	v := Verdict{}
	for _, d := range detectorWeights {
		r := d.fn(f, cfg)
		v.Results = append(v.Results, r)
		if r.Insufficient {
			continue
		}
		sum += d.weight * r.Score
		wsum += d.weight
	}
	if wsum == 0 {
		return Verdict{
			Level:        LevelInsufficient,
			Insufficient: true,
			Reason:       "ни один детектор не смог отработать — вердикт невозможен",
		}
	}
	v.Score = sum / wsum
	switch {
	case v.Score >= BlockerThreshold:
		v.Level = LevelBlocker
	case v.Score >= WarningThreshold:
		v.Level = LevelWarning
	default:
		v.Level = LevelOK
	}
	return v
}
