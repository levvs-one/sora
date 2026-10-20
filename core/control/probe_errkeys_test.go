package control_test

// Pins for the probe error-key split (integration2 review of af146c22):
// "this core cannot probe/benchmark" and "the chain shape is invalid" used
// to ride the endpoint keys, so the app showed the endpoint strings for
// failures that have nothing to do with an endpoint. Each capability or
// shape failure now carries its own key; genuine endpoint failures keep
// theirs.

import (
	"context"
	"testing"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

type benchSampleStream struct {
	grpc.ServerStream
	ctx context.Context
}

func (s *benchSampleStream) Context() context.Context { return s.ctx }
func (s *benchSampleStream) Send(*corev1.BandwidthSample) error {
	return nil
}

func TestBenchmarkWithoutBenchmarkerReportsProbeUnsupported(t *testing.T) {
	// probeServer wires no Benchmarker, so the core cannot benchmark.
	server := probeServer(t, &fakeMeasurer{}, &fakeProber{})
	req := &corev1.BenchmarkServersRequest{
		ApiVersion:           &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1},
		ControlAuthenticator: testToken,
		ServerIds:            []string{"a"},
	}
	err := server.BenchmarkServers(req, &benchSampleStream{ctx: context.Background()})
	if errs.KeyOf(err) != errs.KeyProbeUnsupported {
		t.Fatalf("benchmark on a core without a benchmarker: key = %v, want %v (err = %v)",
			errs.KeyOf(err), errs.KeyProbeUnsupported, err)
	}
}

func TestProbeChainInvalidShapesCarryTheChainKey(t *testing.T) {
	server := probeServer(t, &fakeMeasurer{}, &fakeProber{})
	cases := map[string][]string{
		"no servers":   {},
		"one server":   {"a"},
		"four servers": {"a", "b", "c", "d"},
		"a repeat":     {"a", "b", "a"},
	}
	for name, ids := range cases {
		resp, err := server.ProbeChain(context.Background(), &corev1.ProbeChainRequest{
			ApiVersion:           &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1},
			ControlAuthenticator: testToken,
			ServerIds:            ids,
		})
		if err != nil {
			t.Fatalf("%s: ProbeChain returned a transport error: %v", name, err)
		}
		if got := resp.GetError().GetUserMessageKey(); got != string(errs.KeyProbeChainInvalid) {
			t.Errorf("%s: key = %q, want %q", name, got, errs.KeyProbeChainInvalid)
		}
	}
}

func TestProbeChainWithoutProberReportsProbeUnsupported(t *testing.T) {
	server := probeServer(t, &fakeMeasurer{}, nil)
	resp, err := server.ProbeChain(context.Background(), &corev1.ProbeChainRequest{
		ApiVersion:           &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1},
		ControlAuthenticator: testToken,
		ServerIds:            []string{"a", "b"},
	})
	if err != nil {
		t.Fatalf("ProbeChain returned a transport error: %v", err)
	}
	if got := resp.GetError().GetUserMessageKey(); got != string(errs.KeyProbeUnsupported) {
		t.Fatalf("chain probe on a core without a prober: key = %q, want %q", got, errs.KeyProbeUnsupported)
	}
}

func TestProbeServersWithoutEndpointsKeepsTheNoEndpointsKey(t *testing.T) {
	server := probeServer(t, &fakeMeasurer{}, &fakeProber{})
	stream := &probeStream{ctx: context.Background()}
	err := server.ProbeServers(&corev1.ProbeServersRequest{
		ApiVersion: &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1},
	}, stream)
	if errs.KeyOf(err) != errs.KeyProbeNoEndpoints {
		t.Fatalf("empty probe request: key = %v, want %v (err = %v)",
			errs.KeyOf(err), errs.KeyProbeNoEndpoints, err)
	}
}
