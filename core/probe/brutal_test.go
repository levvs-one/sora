package probe

import (
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

func hy2TestOutbound() engine.Outbound {
	return engine.Outbound{ID: "hy2-1", Protocol: engine.ProtocolHysteria2, Server: "hy.example.com", Port: 443, Password: "secret"}
}

// TestBrutalCalibratorMeasuredThenCached pins the CENSOR-P3 seam:
// a fresh measurement calibrates once, the cooldown then serves the
// cache without a new measurement, and expiry demands one again.
func TestBrutalCalibratorMeasuredThenCached(t *testing.T) {
	c := NewBrutalCalibrator()
	now := time.Unix(1_700_000_000, 0)
	c.now = func() time.Time { return now }

	out, res, err := c.Apply(hy2TestOutbound(), 100, 0)
	if err != nil {
		t.Fatal(err)
	}
	if res.Source != SourceMeasured || out.UpMbps != 9 || out.DownMbps != 90 || !res.UpEstimated {
		t.Fatalf("first apply = %+v on %+v, want measured 9/90 estimated", res, out)
	}
	// Inside the cooldown a different (worse) network must not
	// recalibrate: the cached caps are served.
	now = now.Add(24 * time.Hour)
	out, res, err = c.Apply(hy2TestOutbound(), 10, 0)
	if err != nil {
		t.Fatal(err)
	}
	if res.Source != SourceCached || out.DownMbps != 90 {
		t.Fatalf("cooldown apply = %+v, want cached 90", res)
	}
	// After the cooldown, no measurement means no caps — honestly.
	now = now.Add(CalibrationCooldown)
	out, res, err = c.Apply(hy2TestOutbound(), 0, 0)
	if err != nil {
		t.Fatal(err)
	}
	if res.Source != SourceNone || out.UpMbps != 0 || out.DownMbps != 0 {
		t.Fatalf("expired+unmeasured apply = %+v on %+v, want none", res, out)
	}
	// And a fresh measurement recalibrates from the new network.
	out, res, err = c.Apply(hy2TestOutbound(), 50, 20)
	if err != nil {
		t.Fatal(err)
	}
	if res.Source != SourceMeasured || out.UpMbps != 20 || out.DownMbps != 45 || res.UpEstimated {
		t.Fatalf("recalibrated = %+v on %+v, want 20/45 stated", res, out)
	}
}

// TestBrutalCalibratorManualCapsWin: plan data is never overwritten,
// and it does not consult or fill the cache.
func TestBrutalCalibratorManualCapsWin(t *testing.T) {
	c := NewBrutalCalibrator()
	o := hy2TestOutbound()
	o.UpMbps, o.DownMbps = 15, 60
	out, res, err := c.Apply(o, 1000, 0)
	if err != nil {
		t.Fatal(err)
	}
	if res.Source != SourceManual || out.UpMbps != 15 || out.DownMbps != 60 {
		t.Fatalf("manual apply = %+v on %+v, want untouched 15/60", res, out)
	}
	if len(c.cache) != 0 {
		t.Fatal("manual caps must not fill the calibration cache")
	}
}

// TestBrutalCalibratorIgnoresOtherProtocolsAndBadMeasurements.
func TestBrutalCalibratorIgnoresOtherProtocolsAndBadMeasurements(t *testing.T) {
	c := NewBrutalCalibrator()
	o := hy2TestOutbound()
	o.Protocol = engine.ProtocolTUIC
	if _, res, err := c.Apply(o, 100, 0); err != nil || res.Source != SourceNone {
		t.Fatalf("tuic apply = %+v, %v, want none", res, err)
	}
	// A non-positive measurement is "no measurement": no caps, no error.
	out, res, err := c.Apply(hy2TestOutbound(), -5, 0)
	if err != nil || res.Source != SourceNone || out.UpMbps != 0 {
		t.Fatalf("negative measurement = %+v on %+v, %v, want none", res, out, err)
	}
}
