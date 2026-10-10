//go:build !linux && !windows

package diagnostics

import (
	"context"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// CapturePackets reports that native capture is unsupported on this platform.
func CapturePackets(context.Context, string, time.Duration) ([]byte, error) {
	return nil, errs.Newf(errs.CodeUnsupported, errs.KeyDiagnosticsFailed, "diagnostics: packet capture is unsupported on this platform")
}
