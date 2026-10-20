package control_test

import (
	"context"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"net"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	censorv1 "github.com/levvs-one/sora-client/core/gen/sora/censor/v1"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/ipc"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/tune/desync"
)

// desyncPlane builds a control plane whose session factory returns
// stub engines, with a (closed) local-proxy port: probe sessions
// connect, but every canary handshake is refused instantly, so a tune
// run honestly finds no working strategy. The Service is the real
// one, over an in-memory binding store.
func desyncPlane(t *testing.T) (censorv1.CensorControlClient, *session.Manager, func()) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatal(err)
	}
	manager := session.NewManager(session.ManagerConfig{
		TunUp:   noAdapter,
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil },
	})
	store, err := desync.NewBindingStore("")
	if err != nil {
		t.Fatal(err)
	}
	svc, err := desync.NewService(store, nil)
	if err != nil {
		t.Fatal(err)
	}
	control.DesyncServiceForTest = svc
	t.Cleanup(func() { control.DesyncServiceForTest = nil })

	plane, err := control.New(control.Config{
		Version:        control.Version{Major: 1, Minor: 13, MinSupportedMinor: 1},
		Authenticator:  auth,
		Sessions:       manager,
		LocalProxyPort: 9, // discard port: listening never, dials refused at once
	})
	if err != nil {
		t.Fatal(err)
	}
	address := testEndpointAddress(t)
	listener, err := ipc.Listen(ctx, ipc.Options{Address: address})
	if err != nil {
		t.Fatal(err)
	}
	grpcServer := grpc.NewServer(
		grpc.Creds(ipc.PeerCredentials(ipc.DefaultAuthorize(ipc.Options{Address: address}))),
		grpc.UnaryInterceptor(plane.UnaryAuthInterceptor()),
	)
	censorv1.RegisterCensorControlServer(grpcServer, plane)
	served := make(chan error, 1)
	go func() { served <- grpcServer.Serve(listener) }()
	conn, err := grpc.NewClient("passthrough:///sora-core",
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return ipc.Dial(ctx, address)
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatal(err)
	}
	return censorv1.NewCensorControlClient(conn), manager, func() {
		cancel()
		_ = conn.Close()
		grpcServer.Stop()
		<-served
	}
}

func tuneRequest(engine string) *censorv1.TuneDesyncRequest {
	return &censorv1.TuneDesyncRequest{
		ApiVersion:           clientVersion(),
		ControlAuthenticator: testToken,
		RequestId:            "req-tune-test",
		Engine:               engine,
	}
}

func TestTuneDesyncNoWorkingStrategyIsAnOutcome(t *testing.T) {
	client, _, done := desyncPlane(t)
	defer done()
	resp, err := client.TuneDesync(context.Background(), tuneRequest("nfqws"))
	if err != nil {
		t.Fatalf("TuneDesync: %v", err)
	}
	if resp.GetError() != nil {
		t.Fatalf("no-working-strategy must be an outcome, not an error: %v", resp.GetError())
	}
	if !resp.GetProbeRan() || resp.GetAttempts() == 0 {
		t.Fatalf("the search must have run: %+v", resp)
	}
	if resp.GetWinnerId() != "" {
		t.Fatalf("winner = %q with every handshake refused", resp.GetWinnerId())
	}
	// The run consumed this network's rate budget: an immediate
	// second run is refused as rate-limited, honestly.
	resp2, err := client.TuneDesync(context.Background(), tuneRequest("nfqws"))
	if err != nil {
		t.Fatalf("second TuneDesync: %v", err)
	}
	if resp2.GetError() == nil || resp2.GetError().GetCode() != corev1.SoraErrorCode_SORA_ERROR_CODE_RESOURCE_EXHAUSTED {
		t.Fatalf("second run = %+v, want a resource-exhausted refusal", resp2.GetError())
	}
}

func TestTuneDesyncRejectsUnknownEngine(t *testing.T) {
	client, _, done := desyncPlane(t)
	defer done()
	resp, err := client.TuneDesync(context.Background(), tuneRequest("winws-magic"))
	if err != nil {
		t.Fatalf("TuneDesync: %v", err)
	}
	if resp.GetError() == nil || !strings.Contains(resp.GetError().GetDetailRedacted(), "winws-magic") {
		t.Fatalf("an unknown engine must be refused by name: %+v", resp.GetError())
	}
}

func TestTuneDesyncRefusesOverLiveSession(t *testing.T) {
	client, manager, done := desyncPlane(t)
	defer done()
	plan := &engine.Plan{SessionID: "test-session-001", Outbounds: []engine.Outbound{{ID: "d", Protocol: engine.ProtocolDirect}}}
	if _, err := manager.Connect(context.Background(), plan, session.Settings{}); err != nil {
		t.Fatalf("connect stub session: %v", err)
	}
	defer func() { _ = manager.Disconnect(context.Background()) }()
	resp, err := client.TuneDesync(context.Background(), tuneRequest(""))
	if err != nil {
		t.Fatalf("TuneDesync: %v", err)
	}
	if resp.GetError() == nil || resp.GetError().GetCode() != corev1.SoraErrorCode_SORA_ERROR_CODE_FAILED_PRECONDITION {
		t.Fatalf("tuning over a live session must fail precondition: %+v", resp.GetError())
	}
}
