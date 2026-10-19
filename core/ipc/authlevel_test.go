package ipc_test

import (
	"context"
	"net"
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/ipc"
)

// TestServerHandshakeSeesThroughListenerWrapping is a regression test for
// the SORA-H2/SORA-M1 interaction: Listener.Accept wraps admitted
// connections in an accounting wrapper, and the transport credentials used
// by the gRPC server must still inspect the real peer. Before the fix,
// peerOf saw the wrapper instead of the unix socket, classified the
// legitimate same-user peer as unverified, and ServerHandshake refused the
// connection, breaking the control-plane handshake with a broken pipe.
func TestServerHandshakeSeesThroughListenerWrapping(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	address := endpointAddress(t)
	listener, err := ipc.Listen(ctx, ipc.Options{Address: address})
	if err != nil {
		t.Fatalf("Listen() error = %v", err)
	}

	accepted := make(chan net.Conn, 1)
	acceptErr := make(chan error, 1)
	go func() {
		connection, err := listener.Accept()
		if err != nil {
			acceptErr <- err
			return
		}
		accepted <- connection
	}()

	client, err := ipc.Dial(ctx, address)
	if err != nil {
		t.Fatalf("Dial() error = %v", err)
	}
	defer func() { _ = client.Close() }()

	var serverConn net.Conn
	select {
	case serverConn = <-accepted:
	case err := <-acceptErr:
		t.Fatalf("Accept() error = %v", err)
	}
	defer func() { _ = serverConn.Close() }()

	credentials := ipc.PeerCredentials(ipc.DefaultAuthorize(ipc.Options{Address: address}))
	_, authInfo, err := credentials.ServerHandshake(serverConn)
	if err != nil {
		t.Fatalf("ServerHandshake() through the listener wrapper error = %v", err)
	}
	info, ok := authInfo.(ipc.PeerAuthInfo)
	if !ok {
		t.Fatalf("ServerHandshake() AuthInfo is %T, want ipc.PeerAuthInfo", authInfo)
	}
	if runtime.GOOS == "linux" {
		// The test client runs as the same user as the listener, so it
		// holds full control under the SORA-H2 policy.
		if info.Level != ipc.AuthControl {
			t.Errorf("the same-user peer got level %v, want control", info.Level)
		}
	}
}
