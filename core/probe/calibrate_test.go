package probe

import "testing"

// TestCalibrateBrutal pins the T021 calibration rules: 0.9 safety margin,
// tariff passthrough, estimated upload fallback, clamps, and the refusal
// to calibrate from a non-measurement.
func TestCalibrateBrutal(t *testing.T) {
	t.Run("measured 100 down, no tariff", func(t *testing.T) {
		up, down, est, err := CalibrateBrutal(100, 0)
		if err != nil {
			t.Fatalf("CalibrateBrutal: %v", err)
		}
		if down != 90 {
			t.Fatalf("down = %d, want 90 (0.9 margin)", down)
		}
		if up != 9 || !est {
			t.Fatalf("up = %d est=%v, want 9 estimated", up, est)
		}
	})
	t.Run("measured 100 down, tariff 20 up", func(t *testing.T) {
		up, down, est, err := CalibrateBrutal(100, 20)
		if err != nil {
			t.Fatalf("CalibrateBrutal: %v", err)
		}
		if up != 20 || est {
			t.Fatalf("up = %d est=%v, want stated tariff 20", up, est)
		}
		if down != 90 {
			t.Fatalf("down = %d, want 90", down)
		}
	})
	t.Run("tiny measurement clamps to 1", func(t *testing.T) {
		up, down, _, err := CalibrateBrutal(0.5, 0)
		if err != nil {
			t.Fatalf("CalibrateBrutal: %v", err)
		}
		if down != 1 || up != 1 {
			t.Fatalf("down = %d up = %d, want clamped to 1", down, up)
		}
	})
	t.Run("huge measurement clamps to 100000", func(t *testing.T) {
		_, down, _, err := CalibrateBrutal(500000, 0)
		if err != nil {
			t.Fatalf("CalibrateBrutal: %v", err)
		}
		if down != brutalMaxMbps {
			t.Fatalf("down = %d, want %d", down, brutalMaxMbps)
		}
	})
	t.Run("non-positive measurement is refused", func(t *testing.T) {
		for _, m := range []float64{0, -3} {
			if _, _, _, err := CalibrateBrutal(m, 0); err == nil {
				t.Fatalf("CalibrateBrutal(%v) = nil, want error", m)
			}
		}
	})
	t.Run("negative tariff is refused", func(t *testing.T) {
		if _, _, _, err := CalibrateBrutal(100, -5); err == nil {
			t.Fatalf("CalibrateBrutal(negative tariff) = nil, want error")
		}
	})
}
