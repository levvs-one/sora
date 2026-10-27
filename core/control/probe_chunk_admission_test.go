package control_test

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"testing"
	"testing/synctest"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/probe"
)

// admissionProber models the real backend's public concurrent-request limit,
// keeping requests occupied until the test releases synthetic results.
type admissionProber struct {
	slots      chan struct{}
	release    chan struct{}
	afterFirst <-chan struct{}
	rejected   atomic.Int32
}

func (p *admissionProber) Probe(ctx context.Context, endpoints []*corev1.Endpoint, ids []string) (<-chan *corev1.ProbeResult, error) {
	select {
	case p.slots <- struct{}{}:
	default:
		p.rejected.Add(1)
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyProbeTooMany, "fixture request admission is full")
	}
	results := make(chan *corev1.ProbeResult)
	go func() {
		defer close(results)
		defer func() { <-p.slots }()
		select {
		case <-p.release:
		case <-ctx.Done():
			return
		}
		for i := range endpoints {
			id := ""
			if i < len(ids) {
				id = ids[i]
			}
			select {
			case results <- &corev1.ProbeResult{ServerId: id, Reachable: true, LatencyMs: 7}:
			case <-ctx.Done():
				return
			}
			if i == 0 && p.afterFirst != nil {
				select {
				case <-p.afterFirst:
				case <-ctx.Done():
					return
				}
			}
		}
	}()
	return results, nil
}

func TestProbeChunksRespectBackendAdmission(t *testing.T) {
	for _, count := range []int{600, 1024} {
		for _, mode := range []string{"outbounds", "endpoints", "mixed"} {
			t.Run(fmt.Sprintf("%s/%d", mode, count), func(t *testing.T) {
				synctest.Test(t, func(t *testing.T) {
					ctx, cancel := context.WithCancel(context.Background())
					defer cancel()
					p := &admissionProber{slots: make(chan struct{}, probe.MaxConcurrentRequests), release: make(chan struct{})}
					stream := &probeStream{ctx: ctx}
					req := chunkProbeRequest(count, corev1.ProbeMethod_PROBE_METHOD_CONNECT)
					if mode != "outbounds" {
						for i, spec := range req.GetOutbounds() {
							if mode == "mixed" && i == count/2 {
								break
							}
							req.Endpoints = append(req.Endpoints, spec.GetEndpoint())
						}
						req.Outbounds = req.Outbounds[len(req.Endpoints):]
					}
					done := make(chan error, 1)
					go func() {
						done <- probeServer(t, &fakeMeasurer{}, p).ProbeServers(req, stream)
					}()
					synctest.Wait()
					close(p.release)
					synctest.Wait()
					select {
					case err := <-done:
						if err != nil {
							t.Errorf("chunked probe failed: %v", err)
						}
					default:
						t.Fatal("chunked probe did not finish after releasing its backend")
					}
					if n := p.rejected.Load(); n != 0 {
						t.Errorf("one probe exhausted backend admission %d times", n)
					}
					if len(stream.sent) != count {
						t.Fatalf("got %d results, want %d", len(stream.sent), count)
					}
					ids := resultIDs(stream.sent)
					if ids[""] != len(req.GetEndpoints()) {
						t.Errorf("explicit endpoint results = %d, want %d", ids[""], len(req.GetEndpoints()))
					}
					delete(ids, "")
					if len(ids) != len(req.GetOutbounds()) {
						t.Errorf("outbound result IDs = %d, want %d", len(ids), len(req.GetOutbounds()))
					}
					for id, n := range ids {
						if n != 1 {
							t.Errorf("%s has %d results, want one", id, n)
						}
					}
				})
			})
		}
	}
}

type acknowledgingProbeStream struct {
	*probeStream
	first chan struct{}
	once  sync.Once
}

func (s *acknowledgingProbeStream) Send(result *corev1.ProbeResult) error {
	s.once.Do(func() { close(s.first) })
	return s.probeStream.Send(result)
}

func TestProbeStreamsWhileCurrentChunkIsStillRunning(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		first := make(chan struct{})
		p := &admissionProber{
			slots:   make(chan struct{}, probe.MaxConcurrentRequests),
			release: make(chan struct{}), afterFirst: first,
		}
		close(p.release)
		stream := &acknowledgingProbeStream{probeStream: &probeStream{ctx: ctx}, first: first}
		done := make(chan error, 1)
		go func() {
			done <- probeServer(t, &fakeMeasurer{}, p).ProbeServers(
				chunkProbeRequest(control.ProbeChunkSize+1, corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream)
		}()
		synctest.Wait()
		select {
		case err := <-done:
			if err != nil || len(stream.sent) != control.ProbeChunkSize+1 {
				t.Fatalf("streaming probe = %d results, %v", len(stream.sent), err)
			}
		default:
			t.Fatal("delivery waited for a chunk that itself was waiting for delivery")
		}
	})
}
