package control

// Internal pin for the engine-measure branch of the probe error-key split:
// asking for an engine measurement on a core with no measurer is a
// capability failure (core.probe.unsupported), not a bad endpoint.

import (
	"context"
	"sync"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestMeasureOutboundsEngineWithoutMeasurerReportsProbeUnsupported(t *testing.T) {
	s := &Server{}
	var wg sync.WaitGroup
	err := s.measureOutbounds(context.Background(),
		&corev1.ProbeOptions{Method: corev1.ProbeMethod_PROBE_METHOD_ENGINE},
		[]*corev1.OutboundSpec{{Id: "a"}}, "", nil, &wg, nil)
	if errs.KeyOf(err) != errs.KeyProbeUnsupported {
		t.Fatalf("engine measure without a measurer: key = %v, want %v (err = %v)",
			errs.KeyOf(err), errs.KeyProbeUnsupported, err)
	}
}
