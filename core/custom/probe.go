package custom

import (
	"context"
	"errors"
	"net"
	"syscall"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Probe bounds for TestCustomServer. The handshake opens TCP and closes it
// immediately; no protocol bytes and no credentials ever go over the wire.
const (
	// DefaultProbeTimeout applies when the caller passes zero.
	DefaultProbeTimeout = 5 * time.Second
	// MinProbeTimeout keeps accidental tiny values from spinning.
	MinProbeTimeout = time.Second
	// MaxProbeTimeout bounds how long one reachability check may take.
	MaxProbeTimeout = 30 * time.Second
)

// ClampProbeTimeout normalizes a caller-supplied timeout to the probe bounds.
func ClampProbeTimeout(d time.Duration) time.Duration {
	switch {
	case d <= 0:
		return DefaultProbeTimeout
	case d < MinProbeTimeout:
		return MinProbeTimeout
	case d > MaxProbeTimeout:
		return MaxProbeTimeout
	default:
		return d
	}
}

// ProbeTCP opens a TCP connection to address:port and closes it at once,
// reporting the handshake latency. It sends nothing, so secrets are never
// involved. The address must already be validated; the timeout is clamped
// to the probe bounds.
func ProbeTCP(ctx context.Context, address string, port uint16, timeout time.Duration) (time.Duration, error) {
	timeout = ClampProbeTimeout(timeout)
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	start := time.Now()
	dialer := net.Dialer{}
	conn, err := dialer.DialContext(ctx, "tcp", net.JoinHostPort(address, itoa(port)))
	if err != nil {
		return 0, classifyProbeError(address, port, err)
	}
	_ = conn.Close()
	return time.Since(start), nil
}

// classifyProbeError maps dial failures to the shared error catalog without
// leaking anything but the endpoint the user asked to test.
func classifyProbeError(address string, port uint16, err error) error {
	target := address + ":" + itoa(port)
	switch {
	case errors.Is(err, context.DeadlineExceeded) || isTimeout(err):
		return errs.Newf(errs.CodeDeadlineExceeded, errs.KeyNetworkTimeout,
			"custom: TCP probe to %s timed out", target)
	case errors.Is(err, syscall.ECONNREFUSED):
		return errs.Newf(errs.CodeUnavailable, errs.KeyConnectionRefused,
			"custom: TCP probe to %s refused", target)
	default:
		return errs.Newf(errs.CodeUnavailable, errs.KeyNetworkFailed,
			"custom: TCP probe to %s failed", target)
	}
}

// isTimeout reports network timeouts that do not surface as
// context.DeadlineExceeded.
func isTimeout(err error) bool {
	var netErr net.Error
	return errors.As(err, &netErr) && netErr.Timeout()
}

// itoa formats a port without fmt, mirroring the control plane's helper.
func itoa(v uint16) string {
	if v == 0 {
		return "0"
	}
	var buf [5]byte
	i := len(buf)
	for v > 0 {
		i--
		buf[i] = byte('0' + v%10)
		v /= 10
	}
	return string(buf[i:])
}
