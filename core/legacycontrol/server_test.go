package legacycontrol

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/json"
	"errors"
	"net"
	"testing"
	"time"

	"github.com/creachadair/jrpc2"
	"github.com/creachadair/jrpc2/channel"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
)

func testService(t *testing.T) (*control.Server, *logs.Center) {
	t.Helper()
	token := make([]byte, control.TokenLen)
	if _, err := rand.Read(token); err != nil {
		t.Fatal(err)
	}
	auth, err := control.NewAuthenticator(token)
	if err != nil {
		t.Fatal(err)
	}
	store, err := secret.Open(t.TempDir(), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = store.Close() })
	manager := session.NewManager(session.ManagerConfig{Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
		return nil, errors.New("transport test does not install a network engine")
	}})
	center := logs.New(logs.DefaultSettings())
	center.Write(time.Now(), logs.LevelInfo, "core", "transport integration started")
	service, err := control.New(control.Config{Version: control.Version{Major: 1, Minor: 7, MinSupportedMinor: 1},
		Authenticator: auth, Sessions: manager, Secrets: store, Logs: center})
	if err != nil {
		t.Fatal(err)
	}
	return service, center
}

func testClient(t *testing.T, notify func(*jrpc2.Request)) *jrpc2.Client {
	t.Helper()
	service, _ := testService(t)
	serverSide, clientSide := net.Pipe()
	finished := make(chan error, 1)
	go func() { finished <- serveConnection(t.Context(), serverSide, service) }()
	client := jrpc2.NewClient(channel.Line(clientSide, clientSide), &jrpc2.ClientOptions{
		OnNotify: notify,
		OnCancel: func(client *jrpc2.Client, response *jrpc2.Response) {
			ctx, cancel := context.WithTimeout(context.Background(), time.Second)
			defer cancel()
			_ = client.Notify(ctx, "$/cancelRequest", map[string]any{"id": json.RawMessage(response.ID())})
		},
	})
	t.Cleanup(func() {
		_ = client.Close()
		select {
		case <-finished:
		case <-time.After(2 * time.Second):
			t.Error("server retained the disconnected client")
		}
	})
	return client
}

func call(t *testing.T, client *jrpc2.Client, method string, request, response proto.Message) {
	t.Helper()
	payload, err := protojson.Marshal(request)
	if err != nil {
		t.Fatal(err)
	}
	var result string
	if err := client.CallResult(t.Context(), method, parameters{Payload: string(payload)}, &result); err != nil {
		t.Fatal(err)
	}
	if err := protojson.Unmarshal([]byte(result), response); err != nil {
		t.Fatal(err)
	}
}

func handshake(t *testing.T, client *jrpc2.Client) (*corev1.ApiVersion, []byte) {
	t.Helper()
	response := &corev1.HandshakeResponse{}
	call(t, client, "Handshake", &corev1.HandshakeRequest{ClientVersion: &corev1.ApiVersion{Major: 1, Minor: 7, MinSupportedMinor: 7}}, response)
	if response.GetError() != nil || len(response.GetControlAuthenticator()) != control.TokenLen {
		t.Fatalf("handshake: %v", response.GetError())
	}
	return response.GetNegotiatedVersion(), response.GetControlAuthenticator()
}

func TestSharedContract(t *testing.T) {
	client := testClient(t, nil)
	version, token := handshake(t, client)
	query := &corev1.QueryLogsResponse{}
	call(t, client, "QueryLogs", &corev1.QueryLogsRequest{ApiVersion: version, ControlAuthenticator: token}, query)
	if query.GetError() != nil || len(query.GetEntries()) != 1 || query.Entries[0].Message != "transport integration started" {
		t.Fatalf("query: %v", query)
	}
	parsed := &corev1.ParseImportResponse{}
	call(t, client, "ParseImport", &corev1.ParseImportRequest{ApiVersion: version, RequestId: "legacy-import", Payload: []byte("socks5://user:secret@127.0.0.1:1080#Local")}, parsed)
	if parsed.GetError() != nil || len(parsed.GetSessionPlan().GetOutbounds()) != 1 {
		t.Fatalf("import: %v", parsed.GetError())
	}
	var reply string
	input, err := protojson.Marshal(&corev1.QueryLogsRequest{ApiVersion: version, ControlAuthenticator: bytes.Repeat([]byte{1}, control.TokenLen)})
	if err != nil {
		t.Fatal(err)
	}
	if err := client.CallResult(t.Context(), "QueryLogs", parameters{Payload: string(input)}, &reply); err == nil {
		t.Fatal("invalid authenticator reached the shared log center")
	}
}

func TestWatchesCannotBlockCancellationOrDisconnect(t *testing.T) {
	seen := make(chan struct{}, 16)
	client := testClient(t, func(request *jrpc2.Request) {
		if request.Method() == "CoreEvent" {
			seen <- struct{}{}
		}
	})
	version, token := handshake(t, client)
	request, err := protojson.Marshal(&corev1.WatchLogsRequest{ApiVersion: version, ControlAuthenticator: token})
	if err != nil {
		t.Fatal(err)
	}
	var cancel []context.CancelFunc
	finished := make(chan error, 8)
	for range 8 {
		ctx, stop := context.WithCancel(t.Context())
		cancel = append(cancel, stop)
		go func() {
			var result any
			finished <- client.CallResult(ctx, "WatchLogs", parameters{Payload: string(request), StreamID: "watch"}, &result)
		}()
	}
	for range 8 {
		select {
		case <-seen:
		case <-time.After(2 * time.Second):
			t.Fatal("a watch did not start")
		}
	}
	status := &corev1.GetStatusResponse{}
	call(t, client, "GetStatus", &corev1.GetStatusRequest{ApiVersion: version}, status)
	disconnected := &corev1.DisconnectResponse{}
	call(t, client, "Disconnect", &corev1.DisconnectRequest{ApiVersion: version, RequestId: "disconnect", ControlAuthenticator: token}, disconnected)
	input, err := protojson.Marshal(&corev1.GetLogSettingsRequest{ApiVersion: version, ControlAuthenticator: token})
	if err != nil {
		t.Fatal(err)
	}
	var result string
	var overloaded *jrpc2.Error
	if err := client.CallResult(t.Context(), "GetLogSettings", parameters{Payload: string(input)}, &result); !errors.As(err, &overloaded) || overloaded.Code != -32001 {
		t.Fatalf("busy control did not reject additional work: %v", err)
	}
	for _, stop := range cancel {
		stop()
	}
	for range 8 {
		select {
		case err := <-finished:
			if err == nil {
				t.Error("watch ignored cancellation")
			}
		case <-time.After(2 * time.Second):
			t.Fatal("cancel notification was blocked by active watches")
		}
	}
	call(t, client, "GetStatus", &corev1.GetStatusRequest{ApiVersion: version}, &corev1.GetStatusResponse{})
}

func TestOversizedFrameClosesConnection(t *testing.T) {
	service, _ := testService(t)
	server, client := net.Pipe()
	defer func() { _ = client.Close() }()
	finished := make(chan error, 1)
	go func() { finished <- serveConnection(t.Context(), server, service) }()
	_ = client.SetWriteDeadline(time.Now().Add(2 * time.Second))
	_, _ = client.Write(bytes.Repeat([]byte{'x'}, requestLimit+1))
	select {
	case <-finished:
	case <-time.After(2 * time.Second):
		t.Fatal("oversized request retained its connection")
	}
}

func TestServiceCancellationClosesActiveConnection(t *testing.T) {
	service, _ := testService(t)
	serverSide, clientSide := net.Pipe()
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	finished := make(chan error, 1)
	go func() { finished <- serveConnection(ctx, serverSide, service) }()
	seen := make(chan struct{}, 1)
	client := jrpc2.NewClient(channel.Line(clientSide, clientSide), &jrpc2.ClientOptions{
		OnNotify: func(request *jrpc2.Request) {
			if request.Method() == "CoreEvent" {
				seen <- struct{}{}
			}
		},
	})
	defer func() { _ = client.Close() }()
	version, token := handshake(t, client)
	request, err := protojson.Marshal(&corev1.WatchLogsRequest{ApiVersion: version, ControlAuthenticator: token})
	if err != nil {
		t.Fatal(err)
	}
	watch := make(chan error, 1)
	go func() {
		var result any
		watch <- client.CallResult(t.Context(), "WatchLogs", parameters{Payload: string(request), StreamID: "shutdown"}, &result)
	}()
	select {
	case <-seen:
	case <-time.After(2 * time.Second):
		t.Fatal("watch did not start")
	}
	cancel()
	select {
	case <-finished:
	case <-time.After(2 * time.Second):
		t.Fatal("service cancellation retained the connection")
	}
	select {
	case <-watch:
	case <-time.After(2 * time.Second):
		t.Fatal("service cancellation retained the watch")
	}
}
