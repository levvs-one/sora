package probe

import (
	"errors"
	"math"
	"time"
)

// Hysteria2 brutal auto-calibration (T021, spec 21-hysteria2.md §4).
//
// Brutal congestion control is Hysteria2's main advantage, but it only
// engages when the client states its bandwidth caps — and users almost
// never type their tariff correctly. The client therefore measures the
// download path once (Benchmarker), and this function turns the measured
// figure into caps with a safety margin. The logic lives in the core so
// it is one implementation with tests; the trigger (first successful
// Hysteria2 connect without caps, then the "re-measure" button) belongs
// to the client, which owns the credential document the caps are written
// into.
//
// NOT WIRED: no caller yet — the trigger needs the client-side seam
// (post-connect hook + credential write + 7-day cooldown bookkeeping,
// spec §4.3–4.5). The function is deliberately not invoked from the core:
// a background self-measurement would burn ~100 MB of user traffic and
// observe the network, both forbidden by the spec.

// brutalSafetyMargin: brutal must not sit exactly on the measured
// ceiling — the measurement is the path at one moment (CGNAT, evening
// congestion), not the tariff.
const brutalSafetyMargin = 0.9

// brutalUpShare sizes the upload cap when the user never provided a
// tariff: a tenth of the measured download, labelled an estimate.
const brutalUpShare = 0.1

// BrutalCapBounds are the sane extremes for a stated cap: brutal below
// 1 Mbps is meaningless, above 100 Gbps is a typo.
const (
	brutalMinMbps = 1
	brutalMaxMbps = 100000
)

// CalibrationCooldown is the minimum spacing between two calibrations of
// one server: re-measuring is button-only (spec §4.4), never a silent
// background habit, because the measurement itself is visible traffic.
const CalibrationCooldown = 7 * 24 * time.Hour

// CalibrateBrutal derives Hysteria2 brutal caps from a measured download
// rate. measuredDownMbps is the benchmark result through the tunnel;
// userUpMbps is the user's stated upload tariff, or 0 when unknown.
//
// down = measured × 0.9. up = the stated tariff when present, else
// down × 0.1 with upEstimated=true so the client can label it an
// estimate instead of presenting it as a fact. Both caps are clamped to
// [1, 100000] Mbps. A non-positive or non-finite measurement is an
// error: calibrating from nothing would write fiction into the config.
func CalibrateBrutal(measuredDownMbps float64, userUpMbps int) (upMbps, downMbps int, upEstimated bool, err error) {
	if measuredDownMbps <= 0 || math.IsNaN(measuredDownMbps) || math.IsInf(measuredDownMbps, 0) {
		return 0, 0, false, errors.New("probe: brutal calibration needs a positive measured download rate")
	}
	if userUpMbps < 0 {
		return 0, 0, false, errors.New("probe: brutal calibration got a negative upload tariff")
	}
	downMbps = clampBrutal(int(math.Floor(measuredDownMbps * brutalSafetyMargin)))
	if userUpMbps > 0 {
		upMbps = clampBrutal(userUpMbps)
		return upMbps, downMbps, false, nil
	}
	upMbps = clampBrutal(int(math.Floor(float64(downMbps) * brutalUpShare)))
	return upMbps, downMbps, true, nil
}

func clampBrutal(v int) int {
	if v < brutalMinMbps {
		return brutalMinMbps
	}
	if v > brutalMaxMbps {
		return brutalMaxMbps
	}
	return v
}
