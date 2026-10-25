package control_test

import (
	"context"
	"net"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/ext"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	extv1 "github.com/levvs-one/sora-client/core/gen/sora/ext/v1"
	"github.com/levvs-one/sora-client/core/ipc"
)

func TestReadPeerCannotAcquireControlThroughUnaryOrWorkerStream(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	plane, store := newTestServer(t)
	address := testEndpointAddress(t)
	listener, err := ipc.Listen(ctx, ipc.Options{Address: address})
	if err != nil {
		t.Fatal(err)
	}
	server := grpc.NewServer(
		// Only platform role classification is injected. The local transport,
		// gRPC credentials, both interceptors and service handlers are real.
		grpc.Creds(ipc.PeerCredentials(func(ipc.Peer) ipc.AuthLevel { return ipc.AuthRead })),
		grpc.UnaryInterceptor(plane.UnaryAuthInterceptor()),
		grpc.StreamInterceptor(plane.StreamAuthInterceptor()),
	)
	corev1.RegisterCoreControlServer(server, plane)
	extv1.RegisterExtensionHostServer(server, ext.NewHost(plane.ExtHostDeps()))
	served := make(chan error, 1)
	go func() { served <- server.Serve(listener) }()
	t.Cleanup(func() {
		server.Stop()
		_ = listener.Close()
		select {
		case <-served:
		case <-time.After(3 * time.Second):
			t.Error("isolated transport did not stop")
		}
	})
	connection, err := grpc.NewClient("passthrough:///sora-read-boundary",
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) { return ipc.Dial(ctx, address) }),
		grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = connection.Close() }()
	client := corev1.NewCoreControlClient(connection)
	handshake, err := client.Handshake(ctx, &corev1.HandshakeRequest{ClientVersion: clientVersion()})
	if err != nil || handshake.GetError() != nil || handshake.GetNegotiatedVersion().GetMajor() != 1 || len(handshake.GetControlAuthenticator()) != 0 {
		t.Fatalf("read handshake disclosed a token or failed: %v, %v", handshake, err)
	}
	if _, err := client.GetStatus(ctx, &corev1.GetStatusRequest{ApiVersion: clientVersion()}); err != nil {
		t.Fatalf("read status refused: %v", err)
	}
	if _, err := client.Connect(ctx, &corev1.ConnectRequest{
		ApiVersion: clientVersion(), ControlAuthenticator: testToken, SessionPlan: validPlan(t, store),
	}); status.Code(err) != codes.PermissionDenied {
		t.Fatalf("read peer with a known valid token reached Connect: %v", err)
	}
	if _, err := client.Disconnect(ctx, &corev1.DisconnectRequest{
		ApiVersion: clientVersion(), ControlAuthenticator: testToken,
	}); status.Code(err) != codes.PermissionDenied {
		t.Fatalf("read peer with a known valid token reached Disconnect: %v", err)
	}
	workers := extv1.NewExtensionHostClient(connection)
	worker, err := workers.RunWorker(ctx)
	if err != nil {
		t.Fatal(err)
	}
	// Even a valid token cannot bypass the streaming method's peer privilege.
	_ = worker.Send(&extv1.WorkerClientMessage{ControlToken: testToken})
	if _, err := worker.Recv(); status.Code(err) != codes.PermissionDenied {
		t.Fatalf("read peer reached the worker host: %v", err)
	}
	after, err := client.GetStatus(ctx, &corev1.GetStatusRequest{ApiVersion: clientVersion()})
	if err != nil || after.GetStatus().GetConnection().GetValue() != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_DISCONNECTED {
		t.Fatalf("refused operations changed the session: %v, %v", after, err)
	}
}
