package deadcheck

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestDetectDeadSessionAlive(t *testing.T) {
	v := DetectDeadSession(context.Background(), DeadSessionInput{
		Probe: func(context.Context) (int64, error) { return 65536, nil },
	})
	if v.State != SessionAlive {
		t.Errorf("state = %v, want alive", v.State)
	}
	if v.Bytes != 65536 {
		t.Errorf("bytes = %d, want 65536", v.Bytes)
	}
}

func TestDetectDeadSessionNoTrafficOnHang(t *testing.T) {
	v := DetectDeadSession(context.Background(), DeadSessionInput{
		Timeout: 50 * time.Millisecond,
		Probe: func(ctx context.Context) (int64, error) {
			<-ctx.Done()
			return 0, ctx.Err()
		},
	})
	if v.State != SessionNoTraffic {
		t.Errorf("state = %v, want no_traffic for a hanging probe", v.State)
	}
}

func TestDetectDeadSessionNoTrafficOnEmpty(t *testing.T) {
	v := DetectDeadSession(context.Background(), DeadSessionInput{
		Probe: func(context.Context) (int64, error) { return 0, nil },
	})
	if v.State != SessionNoTraffic {
		t.Errorf("state = %v, want no_traffic for zero bytes", v.State)
	}
}

func TestDetectDeadSessionUnknownOnProbeError(t *testing.T) {
	// A probe that fails for its own reasons (DNS, refused) must not be
	// misread as the hostile "no traffic" signature.
	v := DetectDeadSession(context.Background(), DeadSessionInput{
		Probe: func(context.Context) (int64, error) { return 0, errors.New("connection refused") },
	})
	if v.State != SessionUnknown {
		t.Errorf("state = %v, want unknown for a failing probe", v.State)
	}
}

func TestDetectDeadSessionUnknownWithoutProbe(t *testing.T) {
	v := DetectDeadSession(context.Background(), DeadSessionInput{})
	if v.State != SessionUnknown {
		t.Errorf("state = %v, want unknown without a probe", v.State)
	}
}

func TestDetectDeadSessionRespectsCallerContext(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	v := DetectDeadSession(ctx, DeadSessionInput{
		Probe: func(ctx context.Context) (int64, error) {
			<-ctx.Done()
			return 0, ctx.Err()
		},
	})
	// Cancelled before start: the probe cannot prove aliveness, and the
	// cancellation is ours, not the network's — Unknown, not "no traffic".
	if v.State != SessionUnknown {
		t.Errorf("state = %v, want unknown on caller-cancelled context", v.State)
	}
	if v.Elapsed > 5*time.Second {
		t.Errorf("elapsed = %v, the detector ignored the caller context", v.Elapsed)
	}
}
