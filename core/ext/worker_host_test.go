package ext

import (
	"context"
	"errors"
	"io"
	"net"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"

	extv1 "github.com/levvs-one/sora-client/core/gen/sora/ext/v1"
)

func TestWorkerLifecycleStream(t *testing.T) {
	scheduler := NewScheduler(nil)
	host := NewHost(nil, Deps{Scheduler: scheduler, VerifyControl: func(token []byte) bool { return string(token) == "control" }})
	listener := bufconn.Listen(1 << 20)
	server := grpc.NewServer()
	extv1.RegisterExtensionHostServer(server, host)
	go func() { _ = server.Serve(listener) }()
	defer server.Stop()
	connection, err := grpc.NewClient("passthrough:///worker", grpc.WithTransportCredentials(insecure.NewCredentials()), grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) { return listener.Dial() }))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = connection.Close() }()
	client := extv1.NewExtensionHostClient(connection)
	request := func(token string, allowed bool) *extv1.WorkerClientMessage {
		m := bgManifest(t)
		if !allowed {
			m.Permissions = []string{"net.fetch"}
		}
		manifest := rawManifestWith(t, m, map[string]any{"background_task": map[string]any{"entry": "worker.js", "interval_minutes": 1}})
		return &extv1.WorkerClientMessage{ControlToken: []byte(token), ManifestJson: string(manifest), Source: "console.log('scheduled');", ConfigJson: `{"enabled":true,"interval_minutes":1}`}
	}
	for _, tc := range []struct {
		token   string
		allowed bool
		code    codes.Code
	}{{"bad", true, codes.Unauthenticated}, {"control", false, codes.InvalidArgument}} {
		stream, err := client.RunWorker(t.Context())
		if err != nil {
			t.Fatal(err)
		}
		if err = stream.Send(request(tc.token, tc.allowed)); err != nil {
			t.Fatal(err)
		}
		if _, err = stream.Recv(); status.Code(err) != tc.code {
			t.Fatalf("got %v want %v", err, tc.code)
		}
	}
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	stream, err := client.RunWorker(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if err = stream.Send(request("control", true)); err != nil {
		t.Fatal(err)
	}
	if _, err = stream.Recv(); err != nil {
		t.Fatal(err)
	}
	task, ok := scheduler.Task(bgManifest(t).ID)
	if !ok || task.Interval != MinWorkerInterval {
		t.Fatal("worker not registered with clamped schedule")
	}
	replacement, err := client.RunWorker(t.Context())
	if err != nil {
		t.Fatal(err)
	}
	if err = replacement.Send(request("control", true)); err != nil {
		t.Fatal(err)
	}
	if _, err = replacement.Recv(); err != nil {
		t.Fatal(err)
	}
	if _, err = stream.Recv(); !errors.Is(err, io.EOF) {
		t.Fatalf("replaced stream did not close: %v", err)
	}
	if current, ok := scheduler.Task(task.ExtensionID); !ok || current == task {
		t.Fatal("replacement worker lost registration")
	}
	stream = replacement
	if err = stream.CloseSend(); err != nil {
		t.Fatal(err)
	}
	if _, err = stream.Recv(); !errors.Is(err, io.EOF) {
		t.Fatalf("stream close: %v", err)
	}
	deadline := time.NewTimer(time.Second)
	defer deadline.Stop()
	tick := time.NewTicker(time.Millisecond)
	defer tick.Stop()
	for {
		if _, ok = scheduler.Task(task.ExtensionID); !ok {
			break
		}
		select {
		case <-deadline.C:
			t.Fatal("stream close did not unregister worker")
		case <-tick.C:
		}
	}
}
