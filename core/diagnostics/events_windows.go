//go:build windows

package diagnostics

import (
	"context"
	"io"
	"os"
	"path/filepath"
	"unsafe"

	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/errs"
)

// ExportWindowsEvents asks Windows for a genuine EVTX file, without clearing
// the channel or exporting events belonging to other applications.
func ExportWindowsEvents(ctx context.Context) ([]byte, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	dir, err := os.MkdirTemp("", "sora-events-")
	if err != nil {
		return nil, err
	}
	defer func() { _ = os.RemoveAll(dir) }()
	path := filepath.Join(dir, "events.evtx")
	channel, _ := windows.UTF16PtrFromString("Application")
	query, _ := windows.UTF16PtrFromString("*[System[Provider[@Name='SoraLegacyCore'] and TimeCreated[timediff(@SystemTime) <= 86400000]]]")
	target, err := windows.UTF16PtrFromString(path)
	if err != nil {
		return nil, err
	}
	call := windows.NewLazySystemDLL("wevtapi.dll").NewProc("EvtExportLog")
	ok, _, nativeErr := call.Call(0, uintptr(unsafe.Pointer(channel)), uintptr(unsafe.Pointer(query)), uintptr(unsafe.Pointer(target)), 1)
	if ok == 0 {
		return nil, errs.Wrap(nativeErr, errs.CodeUnavailable, errs.KeyDiagnosticsFailed)
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer func() { _ = file.Close() }()
	data, err := io.ReadAll(io.LimitReader(file, DefaultMaxArchiveBytes+1))
	if err != nil {
		return nil, err
	}
	if len(data) > DefaultMaxArchiveBytes {
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyDiagnosticsTooLarge, "diagnostics: EVTX exceeds the size limit")
	}
	return data, nil
}
