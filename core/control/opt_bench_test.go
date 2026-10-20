package control

// Micro-benchmarks for the control plane's hot paths, used by the zone-C
// optimizer to measure before/after on real code:
//
//   - the bandwidth stream: BenchmarkServers forwarding 1000 samples plus
//     resolveBenchmarkServers over 200 subscription servers;
//   - plan construction: planFromProto with 200 outbounds, and the
//     credential document round trip (per-outbound cost of credential
//     resolution);
//   - the session redactor cache (memoization hit vs miss).
//
// Run with: go test -bench=. -benchtime=2s -run=NONE ./control/

import (
	"context"
	"fmt"
	"testing"
	"time"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/parser"
	"github.com/levvs-one/sora-client/core/probe"
	"github.com/levvs-one/sora-client/core/session"
)

// benchStream is the discard sink for streaming RPCs: it counts sends the
// way a client would drain them, without any I/O.
type benchStream[T any] struct {
	grpc.ServerStream
	ctx  context.Context
	sent int
}

func (s *benchStream[T]) Context() context.Context { return s.ctx }
func (s *benchStream[T]) Send(*T) error            { s.sent++; return nil }

// benchBenchmarker replays a fixed sample slice, exactly like a completed
// benchmarker.Benchmark call would deliver them through the channel.
type benchBenchmarker struct {
	samples []probe.BandwidthSample
}

func (b *benchBenchmarker) Benchmark(ctx context.Context, outbounds []engine.Outbound, opts engine.BandwidthOptions) (<-chan probe.BandwidthSample, error) {
	out := make(chan probe.BandwidthSample, len(b.samples))
	for _, s := range b.samples {
		out <- s
	}
	close(out)
	return out, nil
}

func (b *benchBenchmarker) History() []probe.HistoryEntry { return nil }
func (b *benchBenchmarker) RecordLatency(string, time.Duration) {}

// benchToken returns a valid control token for authorize.
func benchToken(t *testing.B) []byte {
	t.Helper()
	token := make([]byte, TokenLen)
	for i := range token {
		token[i] = byte(i*7 + 3)
	}
	return token
}

func benchSpecs(n int) []*corev1.OutboundSpec {
	specs := make([]*corev1.OutboundSpec, 0, n)
	for i := 0; i < n; i++ {
		id := fmt.Sprintf("srv-%d", i)
		specs = append(specs, &corev1.OutboundSpec{
			Id:          id,
			DisplayName: "Server " + id,
			Protocol:    "vless",
			Endpoint:    &corev1.Endpoint{Host: fmt.Sprintf("edge-%d.example.com", i), Port: 443},
		})
	}
	return specs
}

// benchBenchServer builds a Server able to run BenchmarkServers: auth and
// the benchmarker are wired, the subscription book holds the given specs.
func benchBenchServer(t *testing.B, token []byte, specs []*corev1.OutboundSpec, samples []probe.BandwidthSample) *Server {
	t.Helper()
	auth, err := NewAuthenticator(token)
	if err != nil {
		t.Fatal(err)
	}
	srv, err := New(Config{
		Version:       Version{Major: 1, Minor: 3, MinSupportedMinor: 1},
		Authenticator: auth,
		Sessions: session.NewManager(session.ManagerConfig{
			TunUp:   func(context.Context, string) error { return nil },
			Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return nil, context.Canceled },
		}),
		Benchmarker: &benchBenchmarker{samples: samples},
	})
	if err != nil {
		t.Fatal(err)
	}
	srv.subs.lists["bench"] = specs
	return srv
}

// BenchmarkBandwidthStream1000Events runs the whole BenchmarkServers RPC:
// resolve ids, convert outbounds, and forward 1000 bandwidth samples as
// wire messages into the stream.
func BenchmarkBandwidthStream1000Events(b *testing.B) {
	token := benchToken(b)
	specs := benchSpecs(1)
	samples := make([]probe.BandwidthSample, 0, 1000)
	for i := 0; i < 1000; i++ {
		samples = append(samples, probe.BandwidthSample{
			ServerID: "srv-0", BytesPerSec: uint64(1_000_000 + i), ProgressPct: uint32(i / 10),
		})
	}
	samples = append(samples, probe.BandwidthSample{ServerID: "srv-0", Done: true, ProgressPct: 100})
	version := &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		srv := benchBenchServer(b, token, specs, samples)
		stream := &benchStream[corev1.BandwidthSample]{ctx: context.Background()}
		req := &corev1.BenchmarkServersRequest{
			ApiVersion:          version,
			ControlAuthenticator: token,
			ServerIds:           []string{"srv-0"},
			DurationS:           10,
			Concurrency:         2,
		}
		if err := srv.BenchmarkServers(req, stream); err != nil {
			b.Fatal(err)
		}
		if stream.sent != len(samples) {
			b.Fatalf("sent %d samples, want %d", stream.sent, len(samples))
		}
	}
}

// BenchmarkResolveBenchmarkServers32of200 resolves 32 ids out of a 200
// server subscription book, the same lookup the benchmark stream performs
// per request.
func BenchmarkResolveBenchmarkServers32of200(b *testing.B) {
	token := benchToken(b)
	specs := benchSpecs(200)
	srv := benchBenchServer(b, token, specs, nil)
	ids := make([]string, 0, 32)
	for i := 0; i < 32; i += 2 {
		ids = append(ids, fmt.Sprintf("srv-%d", i))
	}
	for i := 0; i < 16; i++ {
		ids = append(ids, fmt.Sprintf("missing-%d", i))
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		found, missing := srv.resolveBenchmarkServers(ids)
		if len(found) != 16 || len(missing) != 16 {
			b.Fatalf("found %d, missing %d; want 16 and 16", len(found), len(missing))
		}
	}
}

// benchPlan200 builds a 200-server session plan: outbounds, rules that
// reference them, and two groups.
func benchPlan200() *corev1.SessionPlan {
	in := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM}
	for i := 0; i < 200; i++ {
		id := fmt.Sprintf("srv-%d", i)
		in.Outbounds = append(in.Outbounds, &corev1.OutboundSpec{
			Id:          id,
			DisplayName: "Server " + id,
			Protocol:    "vless",
			Endpoint:    &corev1.Endpoint{Host: fmt.Sprintf("edge-%d.example.com", i), Port: 443},
		})
	}
	for i := 0; i < 20; i++ {
		in.Routes = append(in.Routes, &corev1.RoutingRule{
			Destination: fmt.Sprintf("domain:sub%d.example.com", i),
			OutboundId:  fmt.Sprintf("srv-%d", i),
		})
	}
	in.Groups = []*corev1.GroupSpec{
		{Name: "fast", Type: corev1.GroupType_GROUP_TYPE_URL_TEST, Members: []string{"srv-0", "srv-1", "srv-2"}},
		{Name: "all", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"fast", "srv-3"}},
	}
	return in
}

// BenchmarkPlanFromProto200Servers measures plan construction for a 200
// server session: validation, outbound conversion, groups, rules and the
// final plan validation.
func BenchmarkPlanFromProto200Servers(b *testing.B) {
	in := benchPlan200()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		plan, err := planFromProto(in, "s-1", nil)
		if err != nil {
			b.Fatal(err)
		}
		if len(plan.Outbounds) != 200 {
			b.Fatalf("plan has %d outbounds, want 200", len(plan.Outbounds))
		}
	}
}

// BenchmarkCredentialRoundTrip measures the per-outbound credential cost of
// plan construction: serialize the credential document (import time),
// parse it back and apply it to an outbound (plan time).
func BenchmarkCredentialRoundTrip(b *testing.B) {
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?type=xhttp&security=reality" +
		"&pbk=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw&sid=6ba85179e30d4fc2&sni=www.example.com&fp=chrome" +
		"&path=%2Fx&host=cdn.example.com&mode=stream-one&encryption=none&alpn=h2,http%2F1.1#Edge"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		b.Fatalf("parse: %v, servers: %d", err, len(result.Servers))
	}
	spec := result.Servers[0]

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		document, err := credentialDocument(spec)
		if err != nil {
			b.Fatal(err)
		}
		values, err := parseCredential(document)
		if err != nil {
			b.Fatal(err)
		}
		var o engine.Outbound
		if err := applyCredential(&o, values); err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkRedactorCacheHit measures a memoization hit: the session
// redactor is already cached.
func BenchmarkRedactorCacheHit(b *testing.B) {
	c := &redactorCache{byRef: make(map[string]*engine.Redactor)}
	for i := 0; i < maxCachedRedactors; i++ {
		c.put(fmt.Sprintf("session-%d", i), engine.NewRedactor())
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if r := c.get("session-3"); r == nil {
			b.Fatal("expected a cached redactor")
		}
	}
}

// BenchmarkRedactorCacheMiss measures a memoization miss: the session has
// no cached redactor.
func BenchmarkRedactorCacheMiss(b *testing.B) {
	c := &redactorCache{byRef: make(map[string]*engine.Redactor)}
	for i := 0; i < maxCachedRedactors; i++ {
		c.put(fmt.Sprintf("session-%d", i), engine.NewRedactor())
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if r := c.get("gone"); r != nil {
			b.Fatal("expected no cached redactor")
		}
	}
}
