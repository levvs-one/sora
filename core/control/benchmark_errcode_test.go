package control_test

// Pin for the benchmark capability site's error code (integration2
// micro-details pass): the three sibling "core cannot probe/measure"
// sites (ProbeServers, ProbeChain, measureOutbounds) raise
// KeyProbeUnsupported with the catalog code CodeUnsupported, and the
// catalog entry for the key itself is CodeUnsupported. The benchmark
// site used to raise the same key with CodeFailedPrecondition, so the
// same failure classified two ways depending on the entry point.
//
// The alignment does not change the wire contract of this streaming
// RPC: BenchmarkServers returns the error itself (no SoraError body),
// and neither the old nor the new code is in transportOnly, so the
// gRPC status stays Unknown and the user message key is unchanged.

import (
	"context"
	"testing"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

type benchCodeStream struct {
	grpc.ServerStream
	ctx context.Context
}

func (s *benchCodeStream) Context() context.Context { return s.ctx }
func (s *benchCodeStream) Send(*corev1.BandwidthSample) error {
	return nil
}

func TestBenchmarkWithoutBenchmarkerKeyAndCodeMatchCatalog(t *testing.T) {
	server := probeServer(t, &fakeMeasurer{}, &fakeProber{})
	req := &corev1.BenchmarkServersRequest{
		ApiVersion:           &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1},
		ControlAuthenticator: testToken,
		ServerIds:            []string{"a"},
	}
	err := server.BenchmarkServers(req, &benchCodeStream{ctx: context.Background()})
	if err == nil {
		t.Fatal("benchmark on a core without a benchmarker: err = nil, want the unsupported failure")
	}
	if got := errs.KeyOf(err); got != errs.KeyProbeUnsupported {
		t.Fatalf("key = %v, want %v (err = %v)", got, errs.KeyProbeUnsupported, err)
	}
	entry, ok := errs.Lookup(errs.KeyProbeUnsupported)
	if !ok {
		t.Fatal("catalog has no entry for KeyProbeUnsupported")
	}
	if entry.Code != errs.CodeUnsupported {
		t.Fatalf("catalog code for the key = %v, want CodeUnsupported", entry.Code)
	}
	if got := errs.CodeOf(err); got != entry.Code {
		t.Fatalf("site code = %v, want the catalog code %v for key %v", got, entry.Code, errs.KeyProbeUnsupported)
	}
}
