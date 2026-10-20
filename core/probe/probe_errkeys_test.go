package probe_test

// Pin for the probe error-key split: a genuinely malformed endpoint (no
// host, impossible port) keeps core.probe.invalid_endpoint — the key the
// capability and chain-shape failures used to borrow.

import (
	"context"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/probe"
)

func TestProbeMalformedEndpointsKeepTheInvalidEndpointKey(t *testing.T) {
	prober := probe.New(probe.Config{Timeout: 50 * time.Millisecond, Concurrency: 2})
	endpoints := []*corev1.Endpoint{
		{Host: "", Port: 8388},
		{Host: "example.com", Port: 0},
	}
	results, err := prober.Probe(context.Background(), endpoints, nil)
	if err != nil {
		t.Fatalf("Probe: %v", err)
	}
	seen := 0
	for r := range results {
		seen++
		if got := r.GetError().GetUserMessageKey(); got != string(errs.KeyProbeInvalidEndpoint) {
			t.Errorf("malformed endpoint: key = %q, want %q", got, errs.KeyProbeInvalidEndpoint)
		}
	}
	if seen != len(endpoints) {
		t.Fatalf("got %d results, want %d", seen, len(endpoints))
	}
}
