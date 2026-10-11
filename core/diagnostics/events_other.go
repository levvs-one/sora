//go:build !windows

package diagnostics

import (
	"context"

	"github.com/levvs-one/sora-client/core/errs"
)

// ExportWindowsEvents reports that this platform has no Windows event channel.
func ExportWindowsEvents(context.Context) ([]byte, error) {
	return nil, errs.Newf(errs.CodeUnsupported, errs.KeyDiagnosticsFailed, "diagnostics: EVTX is a Windows event log format")
}
