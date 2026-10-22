package main

import (
	"context"
	"errors"
	"net"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/test/bufconn"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/session"
)

func TestCloseFinishesWithAnActiveWatch(t *testing.T) {
	listener := bufconn.Listen(1 << 20)
	t.Cleanup(func() { _ = listener.Close() })
	server := grpc.NewServer()
	t.Cleanup(server.Stop)
	healthpb.RegisterHealthServer(server, health.NewServer())
	go func() { _ = server.Serve(listener) }()
	conn, err := grpc.NewClient("passthrough:///shutdown", grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) { return listener.Dial() }))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()
	stream, err := healthpb.NewHealthClient(conn).Watch(ctx, &healthpb.HealthCheckRequest{})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := stream.Recv(); err != nil {
		t.Fatal(err)
	}
	app := &App{server: server, sessions: session.NewManager(session.ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return nil, errors.New("shutdown test opens no engine")
		},
	})}
	done := make(chan error, 1)
	go func() { done <- app.Close() }()
	select {
	case err := <-done:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("Close waited for a never-ending watch")
	}
	if _, err := stream.Recv(); err == nil {
		t.Fatal("watch survived core shutdown")
	}
}
