package bypass

import "testing"

func TestFakeTTL(t *testing.T) {
	for name, tc := range map[string]struct {
		hops, delta int
		wantTTL     int
		wantOK      bool
		wantErr     bool
	}{
		"typical path":       {hops: 12, delta: 2, wantTTL: 10, wantOK: true},
		"default delta":      {hops: 12, delta: DefaultTTLDelta, wantTTL: 10, wantOK: true},
		"long path clamps":   {hops: 200, delta: 2, wantTTL: 64, wantOK: true},
		"window collapse":    {hops: 3, delta: 2, wantOK: false},
		"collapse at two":    {hops: 2, delta: 2, wantOK: false},
		"zero delta far":     {hops: 12, delta: 0, wantTTL: 12, wantOK: true},
		"unknown distance":   {hops: 0, delta: 2, wantErr: true},
		"negative distance":  {hops: -3, delta: 2, wantErr: true},
		"negative delta":     {hops: 12, delta: -1, wantErr: true},
		"delta larger":       {hops: 5, delta: 9, wantOK: false},
		"exactly at minimum": {hops: 4, delta: 2, wantTTL: 2, wantOK: true},
	} {
		ttl, ok, err := FakeTTL(tc.hops, tc.delta)
		if tc.wantErr {
			if err == nil {
				t.Errorf("%s: expected an error", name)
			}
			continue
		}
		if err != nil {
			t.Errorf("%s: unexpected error: %v", name, err)
			continue
		}
		if ok != tc.wantOK {
			t.Errorf("%s: ok = %v, want %v", name, ok, tc.wantOK)
			continue
		}
		if ok && ttl != tc.wantTTL {
			t.Errorf("%s: ttl = %d, want %d", name, ttl, tc.wantTTL)
		}
	}
}

func TestFakeTTLWindowCollapseIsNotSilent(t *testing.T) {
	// The GGC case: server 3 hops away. A naive hops-1 formula would
	// return ttl=2 and look fine; with delta=2 the window is empty and
	// the caller must know.
	if _, ok, _ := FakeTTL(3, 2); ok {
		t.Fatal("3 hops with delta 2 must report window collapse, not a TTL")
	}
}
