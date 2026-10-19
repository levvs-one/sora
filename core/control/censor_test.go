package control_test

import (
	"context"
	"net"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	censorv1 "github.com/levvs-one/sora-client/core/gen/sora/censor/v1"
	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
	"github.com/levvs-one/sora-client/core/ipc"
	"github.com/levvs-one/sora-client/core/session"
)

// censorClient spins up the control plane with only the censor service
// registered and returns a client for it.
func censorClient(t *testing.T) (censorv1.CensorControlClient, func()) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)

	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatalf("NewAuthenticator() error = %v", err)
	}
	manager := session.NewManager(session.ManagerConfig{
		TunUp:   noAdapter,
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil },
	})
	plane, err := control.New(control.Config{
		Version:       control.Version{Major: 1, Minor: 2, MinSupportedMinor: 1},
		Authenticator: auth,
		Sessions:      manager,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	address := testEndpointAddress(t)
	listener, err := ipc.Listen(ctx, ipc.Options{Address: address})
	if err != nil {
		t.Fatalf("Listen() error = %v", err)
	}
	grpcServer := grpc.NewServer(
		grpc.Creds(ipc.PeerCredentials(ipc.DefaultAuthorize(ipc.Options{Address: address}))),
		grpc.UnaryInterceptor(plane.UnaryAuthInterceptor()),
	)
	censorv1.RegisterCensorControlServer(grpcServer, plane)
	served := make(chan error, 1)
	go func() { served <- grpcServer.Serve(listener) }()

	connection, err := grpc.NewClient(
		"passthrough:///sora-core",
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return ipc.Dial(ctx, address)
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("the client refused to start: %v", err)
	}
	client := censorv1.NewCensorControlClient(connection)
	return client, func() {
		cancel()
		_ = connection.Close()
		grpcServer.Stop()
		<-served
	}
}

func censorBaseRequest() *censorv1.DetectCensorshipRequest {
	return &censorv1.DetectCensorshipRequest{
		ApiVersion:           clientVersion(),
		ControlAuthenticator: testToken,
		RequestId:            "req-censor-test",
		ServerId:             "srv-test",
		TargetHost:           "vpn.example.com",
		TargetPort:           443,
		Sni:                  "vpn.example.com",
		Protocol:             "vless",
	}
}

func sniBlockEvents() []*censorv1.AttemptEvent {
	return []*censorv1.AttemptEvent{
		{Stage: censorv1.AttemptStage_ATTEMPT_STAGE_DNS, Kind: censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_RESOLVED, OffsetMs: 50, Detail: "203.0.113.7"},
		{Stage: censorv1.AttemptStage_ATTEMPT_STAGE_TCP, Kind: censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_CONNECTED, OffsetMs: 150},
		{Stage: censorv1.AttemptStage_ATTEMPT_STAGE_TLS, Kind: censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_SENT, OffsetMs: 170, Detail: "client_hello"},
		{Stage: censorv1.AttemptStage_ATTEMPT_STAGE_TLS, Kind: censorv1.AttemptEventKind_ATTEMPT_EVENT_KIND_REMOTE_RESET, OffsetMs: 400},
	}
}

func TestDetectCensorshipSNIBlocking(t *testing.T) {
	client, stop := censorClient(t)
	defer stop()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req := censorBaseRequest()
	req.Events = sniBlockEvents()
	resp, err := client.DetectCensorship(ctx, req)
	if err != nil {
		t.Fatalf("DetectCensorship() error = %v", err)
	}
	if resp.GetError() != nil {
		t.Fatalf("response error = %v", resp.GetError())
	}
	v := resp.GetVerdict()
	if v.GetKind() != censorv1.CensorshipKind_CENSORSHIP_KIND_SNI_BLOCKING {
		t.Fatalf("kind = %v, want SNI_BLOCKING", v.GetKind())
	}
	if v.GetConfidence() < 0.75 {
		t.Fatalf("confidence = %v, want >= 0.75", v.GetConfidence())
	}
	prof := v.GetSuggestedProfile()
	if prof.GetPreset() != obfsv1.ObfsPreset_OBFS_PRESET_BALANCED {
		t.Fatalf("preset = %v, want the real BALANCED preset, not an invented id", prof.GetPreset())
	}
	if prof.GetDisplayName() == "" || prof.GetWhy() == "" {
		t.Fatalf("suggestion must be human-readable, got %+v", prof)
	}
	if v.GetExplanation() == "" || len(v.GetEvidence()) == 0 {
		t.Fatalf("verdict must explain itself, got %+v", v)
	}
	if resp.GetProbeRan() {
		t.Fatalf("probe_ran must be false for an events-only request")
	}
}

// The RPC must not invent claims: with no events the verdict is UNKNOWN with
// low confidence.
func TestDetectCensorshipEmptyStaysUnknown(t *testing.T) {
	client, stop := censorClient(t)
	defer stop()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	resp, err := client.DetectCensorship(ctx, censorBaseRequest())
	if err != nil {
		t.Fatalf("DetectCensorship() error = %v", err)
	}
	v := resp.GetVerdict()
	if v.GetKind() != censorv1.CensorshipKind_CENSORSHIP_KIND_UNKNOWN {
		t.Fatalf("kind = %v, want UNKNOWN for an empty attempt", v.GetKind())
	}
	if v.GetConfidence() >= 0.35 {
		t.Fatalf("confidence = %v, must stay below the claim floor", v.GetConfidence())
	}
	if v.GetSuggestedProfile() != nil {
		t.Fatalf("an unknown verdict must not suggest a preset")
	}
}

func TestDetectCensorshipRejectsBadAuth(t *testing.T) {
	client, stop := censorClient(t)
	defer stop()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req := censorBaseRequest()
	req.ControlAuthenticator = []byte("wrong")
	if _, err := client.DetectCensorship(ctx, req); err == nil {
		t.Fatal("want an auth error for a wrong authenticator")
	}
}

func TestDetectCensorshipUnknownSession(t *testing.T) {
	client, stop := censorClient(t)
	defer stop()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req := censorBaseRequest()
	req.SessionId = "no-such-session"
	resp, err := client.DetectCensorship(ctx, req)
	if err != nil {
		t.Fatalf("DetectCensorship() transport error = %v", err)
	}
	if resp.GetError() == nil {
		t.Fatal("want a NOT_FOUND response error for an unknown session")
	}
}

func TestDetectCensorshipBadProbeTarget(t *testing.T) {
	client, stop := censorClient(t)
	defer stop()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req := censorBaseRequest()
	req.RunActiveProbe = true
	req.TargetHost = ""
	resp, err := client.DetectCensorship(ctx, req)
	if err != nil {
		t.Fatalf("DetectCensorship() transport error = %v", err)
	}
	if resp.GetError() == nil {
		t.Fatal("want an INVALID_ARGUMENT response error for an empty probe target")
	}
}
