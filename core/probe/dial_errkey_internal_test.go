package probe

// Internal pin for the dial deadline branch: running out of time budget
// is a deadline failure, not a malformed endpoint, so it carries
// core.request.deadline_exceeded rather than core.probe.invalid_endpoint.

import (
	"context"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
)

func TestDialWithoutTimeLeftReportsTheDeadlineKey(t *testing.T) {
	p := &Prober{} // zero timeout: no time left by construction
	_, _, err := p.dial(context.Background(), "127.0.0.1", 443)
	if errs.KeyOf(err) != errs.KeyDeadlineExceeded {
		t.Fatalf("dial with no time left: key = %v, want %v (err = %v)",
			errs.KeyOf(err), errs.KeyDeadlineExceeded, err)
	}
}
