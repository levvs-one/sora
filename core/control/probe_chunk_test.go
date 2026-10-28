package control_test

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"sync"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// chunkProber is a synthetic prober for chunking tests: it answers every
// endpoint as reachable in 7 ms and records the size of every Probe call so
// tests can assert the server chunks the work. failOn makes the n-th
// (1-based) batch fail; hangOn makes it wait for the context instead of
// answering, simulating a stuck chunk.
type chunkProber struct {
	mu      sync.Mutex
	batches []int
	failOn  int
	hangOn  int
}

func (f *chunkProber) Probe(ctx context.Context, endpoints []*corev1.Endpoint, ids []string) (<-chan *corev1.ProbeResult, error) {
	f.mu.Lock()
	f.batches = append(f.batches, len(endpoints))
	batch := len(f.batches)
	fail := f.failOn == batch
	hang := f.hangOn == batch
	f.mu.Unlock()
	if fail {
		return nil, errors.New("synthetic probe chunk failure")
	}
	out := make(chan *corev1.ProbeResult, len(endpoints))
	go func() {
		defer close(out)
		if hang {
			<-ctx.Done()
			return
		}
		for i := range endpoints {
			id := ""
			if i < len(ids) {
				id = ids[i]
			}
			select {
			case out <- &corev1.ProbeResult{ServerId: id, Reachable: true, LatencyMs: 7}:
			case <-ctx.Done():
				return
			}
		}
	}()
	return out, nil
}

func (f *chunkProber) batchSizes() []int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]int(nil), f.batches...)
}

// chunkProbeRequest builds a probe request with n synthetic outbounds.
func chunkProbeRequest(n int, method corev1.ProbeMethod) *corev1.ProbeServersRequest {
	specs := make([]*corev1.OutboundSpec, 0, n)
	for i := 0; i < n; i++ {
		specs = append(specs, &corev1.OutboundSpec{
			Id:       fmt.Sprintf("srv-%04d", i),
			Protocol: "shadowsocks",
			Endpoint: &corev1.Endpoint{Host: "203.0.113.9", Port: 8388},
		})
	}
	return &corev1.ProbeServersRequest{
		ApiVersion: &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1},
		Outbounds:  specs,
		Options:    &corev1.ProbeOptions{Method: method, TimeoutMs: 1500},
	}
}

func resultIDs(sent []*corev1.ProbeResult) map[string]int {
	ids := make(map[string]int, len(sent))
	for _, r := range sent {
		ids[r.GetServerId()]++
	}
	return ids
}

// TestProbeChunksLargeRequests is the synthetic >256/512/1024 regression
// test: requests that used to die with ResourceExhausted must now stream one
// result per server, processed in ProbeChunkSize pieces.
func TestProbeChunksLargeRequests(t *testing.T) {
	for _, n := range []int{300, 600, 1024} {
		t.Run(fmt.Sprintf("%d", n), func(t *testing.T) {
			p := &chunkProber{}
			stream := &probeStream{ctx: context.Background()}
			if err := probeServer(t, &fakeMeasurer{}, p).ProbeServers(
				chunkProbeRequest(n, corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream); err != nil {
				t.Fatalf("probe of %d servers failed: %v", n, err)
			}
			if len(stream.sent) != n {
				t.Fatalf("got %d results, want %d", len(stream.sent), n)
			}
			ids := resultIDs(stream.sent)
			for i := 0; i < n; i++ {
				id := fmt.Sprintf("srv-%04d", i)
				if ids[id] != 1 {
					t.Fatalf("server %s has %d results, want exactly 1", id, ids[id])
				}
			}
			batches := p.batchSizes()
			wantBatches := (n + control.ProbeChunkSize - 1) / control.ProbeChunkSize
			if len(batches) != wantBatches {
				t.Fatalf("got %d batches %v, want %d", len(batches), batches, wantBatches)
			}
			for _, b := range batches {
				if b <= 0 || b > control.ProbeChunkSize {
					t.Fatalf("batch size %d outside (0, %d]", b, control.ProbeChunkSize)
				}
			}
		})
	}
}

// TestProbeChunkBoundaries pins the chunking arithmetic at the edges,
// including the exact-fit and off-by-one cases.
func TestProbeChunkBoundaries(t *testing.T) {
	for _, tc := range []struct {
		n    int
		want []int
	}{
		{1, []int{1}},
		{control.ProbeChunkSize, []int{control.ProbeChunkSize}},
		{control.ProbeChunkSize + 1, []int{control.ProbeChunkSize, 1}},
		{2 * control.ProbeChunkSize, []int{control.ProbeChunkSize, control.ProbeChunkSize}},
	} {
		t.Run(fmt.Sprintf("%d", tc.n), func(t *testing.T) {
			p := &chunkProber{}
			stream := &probeStream{ctx: context.Background()}
			if err := probeServer(t, &fakeMeasurer{}, p).ProbeServers(
				chunkProbeRequest(tc.n, corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream); err != nil {
				t.Fatal(err)
			}
			if got := p.batchSizes(); !slices.Equal(got, tc.want) {
				t.Fatalf("batches = %v, want %v", got, tc.want)
			}
			if len(stream.sent) != tc.n {
				t.Fatalf("got %d results, want %d", len(stream.sent), tc.n)
			}
		})
	}
}

// TestProbeEmptyRequestRejected: an empty request is rejected up front; no
// empty chunk ever reaches the pipeline.
func TestProbeEmptyRequestRejected(t *testing.T) {
	p := &chunkProber{}
	stream := &probeStream{ctx: context.Background()}
	err := probeServer(t, &fakeMeasurer{}, p).ProbeServers(
		chunkProbeRequest(0, corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream)
	if err == nil {
		t.Fatal("expected an error for an empty probe request")
	}
	if errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Fatalf("code = %v, want %v", errs.CodeOf(err), errs.CodeInvalidArgument)
	}
	if len(p.batchSizes()) != 0 {
		t.Fatalf("empty request reached the prober: %v", p.batchSizes())
	}
}

// TestProbeRequestOverSafetyLimitRejected documents the fail-fast bound:
// beyond MaxProbeEndpoints the server still refuses before allocating
// anything, with a hint to chunk the request.
func TestProbeRequestOverSafetyLimitRejected(t *testing.T) {
	p := &chunkProber{}
	stream := &probeStream{ctx: context.Background()}
	err := probeServer(t, &fakeMeasurer{}, p).ProbeServers(
		chunkProbeRequest(control.MaxProbeEndpoints+1, corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream)
	if err == nil {
		t.Fatal("expected an error for an over-limit probe request")
	}
	if errs.CodeOf(err) != errs.CodeResourceExhausted {
		t.Fatalf("code = %v, want %v", errs.CodeOf(err), errs.CodeResourceExhausted)
	}
	if len(p.batchSizes()) != 0 {
		t.Fatalf("over-limit request reached the prober: %v", p.batchSizes())
	}
}

// TestProbePartialChunkFailure: when one chunk's prober call fails, the other
// chunks still stream their results; the failed chunk's servers simply have
// no fabricated samples. After the other chunks finish, a terminal status
// reports the failure without discarding their successful results.
func TestProbePartialChunkFailure(t *testing.T) {
	const n = 300
	p := &chunkProber{failOn: 2}
	stream := &probeStream{ctx: context.Background()}
	err := probeServer(t, &fakeMeasurer{}, p).ProbeServers(
		chunkProbeRequest(n, corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream)
	if status.Code(err) != codes.Internal {
		t.Fatalf("a failed chunk must have a terminal Internal status: %v", err)
	}
	// Batches 1 and 3 streamed; batch 2's servers have no results.
	if len(stream.sent) != n-control.ProbeChunkSize {
		t.Fatalf("got %d results, want %d (all but the failed chunk)", len(stream.sent), n-control.ProbeChunkSize)
	}
	ids := resultIDs(stream.sent)
	for i := 0; i < n; i++ {
		id := fmt.Sprintf("srv-%04d", i)
		want := 1
		if i >= control.ProbeChunkSize && i < 2*control.ProbeChunkSize {
			want = 0
		}
		if ids[id] != want {
			t.Fatalf("%s has %d results, want %d", id, ids[id], want)
		}
	}
	if got := len(p.batchSizes()); got != 3 {
		t.Fatalf("prober saw %d batches, want 3 (a failed chunk does not stop the rest)", got)
	}
}

// TestProbeMidChunkTimeout: when a chunk hangs, the stream context's deadline
// must terminate the probe promptly instead of wedging the handler forever.
// The results streamed before the hang are kept; the hung chunk yields
// nothing; a chunk submitted before the deadline may be cut short mid-flight.
func TestProbeMidChunkTimeout(t *testing.T) {
	const n = 300
	p := &chunkProber{hangOn: 2}
	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()
	stream := &probeStream{ctx: ctx}
	done := make(chan error, 1)
	go func() {
		done <- probeServer(t, &fakeMeasurer{}, p).ProbeServers(
			chunkProbeRequest(n, corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream)
	}()
	select {
	case err := <-done:
		if err != nil {
			t.Fatalf("probe returned an error: %v", err)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("ProbeServers hung past the chunk timeout; the handler must follow the stream context")
	}
	if len(stream.sent) < control.ProbeChunkSize || len(stream.sent) > 2*control.ProbeChunkSize {
		t.Fatalf("got %d results, want between %d and %d",
			len(stream.sent), control.ProbeChunkSize, 2*control.ProbeChunkSize)
	}
	ids := resultIDs(stream.sent)
	for i := 0; i < control.ProbeChunkSize; i++ {
		if id := fmt.Sprintf("srv-%04d", i); ids[id] != 1 {
			t.Fatalf("first chunk incomplete after timeout: %s has %d results", id, ids[id])
		}
	}
	for i := control.ProbeChunkSize; i < 2*control.ProbeChunkSize; i++ {
		if id := fmt.Sprintf("srv-%04d", i); ids[id] != 0 {
			t.Fatalf("hung chunk produced a result for %s", id)
		}
	}
	if got := len(p.batchSizes()); got < 2 || got > 3 {
		t.Fatalf("prober saw %d batches, want 2 or 3", got)
	}
}

// TestProbeChunksEnginePath exercises per-chunk measureOutbounds: the shared
// fakeMeasurer measures id "a" through an engine, every other outbound has
// no engine and falls back to the connection check inside its own chunk.
func TestProbeChunksEnginePath(t *testing.T) {
	const n = 300
	p := &chunkProber{}
	specs := make([]*corev1.OutboundSpec, 0, n)
	specs = append(specs, &corev1.OutboundSpec{
		Id: "a", Protocol: "shadowsocks",
		Endpoint: &corev1.Endpoint{Host: "203.0.113.9", Port: 8388},
	})
	for i := 1; i < n; i++ {
		specs = append(specs, &corev1.OutboundSpec{
			Id: fmt.Sprintf("srv-%04d", i), Protocol: "shadowsocks",
			Endpoint: &corev1.Endpoint{Host: "203.0.113.9", Port: 8388},
		})
	}
	req := &corev1.ProbeServersRequest{
		ApiVersion: &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1},
		Outbounds:  specs,
		Options:    &corev1.ProbeOptions{Method: corev1.ProbeMethod_PROBE_METHOD_UNSPECIFIED, TimeoutMs: 1500},
	}
	stream := &probeStream{ctx: context.Background()}
	if err := probeServer(t, &fakeMeasurer{}, p).ProbeServers(req, stream); err != nil {
		t.Fatal(err)
	}
	if len(stream.sent) != n {
		t.Fatalf("got %d results, want %d", len(stream.sent), n)
	}
	var engine, connect int
	for _, r := range stream.sent {
		switch r.GetMethod() {
		case "engine":
			engine++
			if r.GetServerId() != "a" {
				t.Fatalf("engine result for %q, want only %q", r.GetServerId(), "a")
			}
		case "connect":
			connect++
		default:
			t.Fatalf("result %s has method %q", r.GetServerId(), r.GetMethod())
		}
	}
	if engine != 1 || connect != n-1 {
		t.Fatalf("engine=%d connect=%d, want 1 and %d", engine, connect, n-1)
	}
	// The orphan fallback reached the prober in chunks as well.
	total := 0
	for _, b := range p.batchSizes() {
		if b <= 0 || b > control.ProbeChunkSize {
			t.Fatalf("batch size %d outside (0, %d]", b, control.ProbeChunkSize)
		}
		total += b
	}
	if total != n-1 {
		t.Fatalf("prober measured %d servers, want %d", total, n-1)
	}
}
