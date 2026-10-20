//go:build !linux

package bypass

import "errors"

// newInterceptor has no implementation off Linux: NFQUEUE/nftables is
// the only interception the executor drives today. On Windows the
// winws executor is specified (NFQWS-MIGRATION.md §3) but not wired:
// discovery finds winws.exe, and Apply fails closed naming the pending
// WinDivert step instead of starting a process that would see no
// packets. Returning a nil interceptor with a nil error keeps the
// Engine's platform error (platformExecutorNote) as the single voice.
func newInterceptor() (interceptor, error) {
	return nil, errors.New(platformExecutorNote())
}
