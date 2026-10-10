//go:build !windows

package diagnostics

import (
	"context"

	"github.com/levvs-one/sora-client/core/errs"
)

func ExportWindowsEvents(context.Context) ([]byte, error) {
	return nil, errs.Newf(errs.CodeUnsupported, errs.KeyDiagnosticsFailed, "diagnostics: EVTX is a Windows event log format")
}
