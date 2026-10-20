package control_test

import (
	"context"
	"sync"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
)

// selectRecordingEngine is a fake engine that counts full applies and
// records fast selects separately, with artificial delays so a test can
// compare the cost of the two switch paths. A real engine pays process
// restart on Apply (Xray) or a controller call on Select; the delays
// stand in for those orders of magnitude.
type selectRecordingEngine struct {
	bus   *engine.EventBus
	state engine.State

	mu          sync.Mutex
	applied     int
	selects     [][2]string
	applyDelay  time.Duration
	selectDelay time.Duration
}

func newSelectRecordingEngine() *selectRecordingEngine {
	return &selectRecordingEngine{bus: engine.NewEventBus(8), state: engine.StateIdle}
}

func (e *selectRecordingEngine) Kind() engine.Kind { return engine.KindMihomo }
func (e *selectRecordingEngine) Capabilities() engine.Capabilities {
	return engine.Catalog[engine.KindMihomo]
}
func (e *selectRecordingEngine) Events() *engine.EventBus { return e.bus }
func (e *selectRecordingEngine) Version() engine.Version  { return engine.Version{Raw: "1.19.32"} }
func (e *selectRecordingEngine) State() engine.State      { return e.state }
func (e *selectRecordingEngine) Validate(context.Context, *engine.Plan) error {
	return nil
}

func (e *selectRecordingEngine) Apply(ctx context.Context, _ *engine.Plan) error {
	if e.applyDelay > 0 {
		if err := sleepCtx(ctx, e.applyDelay); err != nil {
			return err
		}
	}
	e.mu.Lock()
	e.applied++
	e.mu.Unlock()
	e.state = engine.StateRunning
	return nil
}

func (e *selectRecordingEngine) Stop(context.Context) error {
	e.state = engine.StateStopped
	return nil
}
func (e *selectRecordingEngine) Close() error { return nil }
func (e *selectRecordingEngine) Groups(context.Context) ([]engine.GroupStatus, error) {
	return nil, nil
}

func (e *selectRecordingEngine) Select(ctx context.Context, group, target string) error {
	if e.selectDelay > 0 {
		if err := sleepCtx(ctx, e.selectDelay); err != nil {
			return err
		}
	}
	e.mu.Lock()
	e.selects = append(e.selects, [2]string{group, target})
	e.mu.Unlock()
	return nil
}

func (e *selectRecordingEngine) Delay(context.Context, string, string, time.Duration) (time.Duration, error) {
	return 0, nil
}
func (e *selectRecordingEngine) Counters(context.Context) (engine.Counters, error) {
	return engine.Counters{}, nil
}

func (e *selectRecordingEngine) counts() (applied int, selects [][2]string) {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.applied, append([][2]string(nil), e.selects...)
}

func sleepCtx(ctx context.Context, d time.Duration) error {
	timer := time.NewTimer(d)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return nil
	}
}

// newSelectTestServer builds a control plane at API 1.12 whose factory
// hands every session the same recording engine.
func newSelectTestServer(t *testing.T, eng *selectRecordingEngine) (*control.Server, *secret.Store) {
	t.Helper()
	store, err := secret.Open(secretTestDir(t), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatalf("opening the secret store: %v", err)
	}
	t.Cleanup(func() { _ = store.Close() })
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatalf("NewAuthenticator() error = %v", err)
	}
	manager := session.NewManager(session.ManagerConfig{
		TunUp: noAdapter,
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return eng, nil
		},
	})
	server, err := control.New(control.Config{
		Version:       control.Version{Major: 1, Minor: 12, MinSupportedMinor: 1},
		Authenticator: auth,
		Sessions:      manager,
		Secrets:       store,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return server, store
}

func selectClientVersion() *corev1.ApiVersion {
	return &corev1.ApiVersion{Major: 1, Minor: 12, MinSupportedMinor: 1}
}

// pickPlan is the plan shape the Dart client builds for a manual pick
// since 1.12: both servers as outbounds, one select group holding them
// with the pick as its starting member, plus an automatic group the
// handler must refuse to switch.
func pickPlan(t *testing.T, store *secret.Store) *corev1.SessionPlan {
	t.Helper()
	outbound := func(id, name, host string) *corev1.OutboundSpec {
		reference, err := secret.NewReference()
		if err != nil {
			t.Fatalf("NewReference() error = %v", err)
		}
		material := []byte(`{"uuid":"11111111-1111-4111-8111-111111111111","server_name":"` + host + `"}`)
		if err := store.Put(reference, material); err != nil {
			t.Fatalf("seeding the store: %v", err)
		}
		return &corev1.OutboundSpec{
			Id:          id,
			DisplayName: name,
			Protocol:    "vless",
			Transport:   "tcp",
			Security:    "tls",
			Endpoint:    &corev1.Endpoint{Host: host, Port: 443},
			Credentials: &corev1.CredentialsRef{Reference: reference},
		}
	}
	return &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{
			outbound("out-1", "Berlin", "de1.example.com"),
			outbound("out-2", "Paris", "fr1.example.com"),
		},
		Groups: []*corev1.GroupSpec{
			{Name: "sora:pick", Type: corev1.GroupType_GROUP_TYPE_SELECT,
				Members: []string{"out-1", "out-2"}, Selected: "out-2"},
			{Name: "sora:auto", Type: corev1.GroupType_GROUP_TYPE_URL_TEST,
				Members: []string{"out-1", "out-2"}},
		},
		Routing: &corev1.RoutingOptions{ProxyTarget: "sora:pick"},
	}
}

func connectPickPlan(t *testing.T, server *control.Server, store *secret.Store) string {
	t.Helper()
	response, err := server.Connect(context.Background(), &corev1.ConnectRequest{
		ApiVersion:           selectClientVersion(),
		RequestId:            "req-connect",
		SessionPlan:          pickPlan(t, store),
		ControlAuthenticator: testToken,
	})
	if err != nil {
		t.Fatalf("Connect() error = %v", err)
	}
	if response.GetError() != nil {
		t.Fatalf("Connect() failed with %v", response.GetError())
	}
	sessionID := response.GetStatus().GetConnection().GetSessionId()
	if sessionID == "" {
		t.Fatal("the core did not name the session it started")
	}
	t.Cleanup(func() {
		_, _ = server.Disconnect(context.Background(), &corev1.DisconnectRequest{
			ApiVersion:           selectClientVersion(),
			ControlAuthenticator: testToken,
		})
	})
	return sessionID
}

func selectRequest(group, target string) *corev1.SelectServerRequest {
	return &corev1.SelectServerRequest{
		ApiVersion:           selectClientVersion(),
		ControlAuthenticator: testToken,
		RequestId:            "req-select",
		Group:                group,
		Target:               target,
	}
}

func TestSelectServerSwitchesWithoutAReconnect(t *testing.T) {
	eng := newSelectRecordingEngine()
	server, store := newSelectTestServer(t, eng)
	sessionID := connectPickPlan(t, server, store)
	appliedBefore, _ := eng.counts()

	req := selectRequest("sora:pick", "out-1")
	req.SessionId = sessionID
	response, err := server.SelectServer(context.Background(), req)
	if err != nil {
		t.Fatalf("SelectServer() error = %v", err)
	}
	if response.GetError() != nil {
		t.Fatalf("SelectServer() failed with %v", response.GetError())
	}
	if got := response.GetStatus().GetConnection().GetValue(); got != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED {
		t.Errorf("status after select = %s, want connected", got)
	}
	appliedAfter, selects := eng.counts()
	if appliedAfter != appliedBefore {
		t.Errorf("the engine was re-applied by a fast switch: %d applies before, %d after", appliedBefore, appliedAfter)
	}
	if len(selects) != 1 || selects[0] != [2]string{"sora:pick", "out-1"} {
		t.Errorf("engine selects = %v, want exactly [(sora:pick, out-1)]", selects)
	}
}

func TestSelectServerAcceptsADisplayNameTarget(t *testing.T) {
	eng := newSelectRecordingEngine()
	server, store := newSelectTestServer(t, eng)
	connectPickPlan(t, server, store)

	response, err := server.SelectServer(context.Background(), selectRequest("sora:pick", "Berlin"))
	if err != nil {
		t.Fatalf("SelectServer() error = %v", err)
	}
	if response.GetError() != nil {
		t.Fatalf("SelectServer() by display name failed with %v", response.GetError())
	}
	_, selects := eng.counts()
	if len(selects) != 1 || selects[0][1] != "Berlin" {
		t.Errorf("engine selects = %v, want the display name passed through", selects)
	}
}

func TestSelectServerNeedsASession(t *testing.T) {
	eng := newSelectRecordingEngine()
	server, _ := newSelectTestServer(t, eng)

	response, err := server.SelectServer(context.Background(), selectRequest("sora:pick", "out-1"))
	if err != nil {
		t.Fatalf("SelectServer() error = %v", err)
	}
	if got := response.GetError().GetUserMessageKey(); got != string(errs.KeySessionRequired) {
		t.Errorf("key = %q, want %q", got, errs.KeySessionRequired)
	}
}

func TestSelectServerRefusesWhatThePlanCannotSwitch(t *testing.T) {
	eng := newSelectRecordingEngine()
	server, store := newSelectTestServer(t, eng)
	connectPickPlan(t, server, store)

	tests := []struct {
		name, group, target string
	}{
		{"automatic group", "sora:auto", "out-1"},
		{"unknown group", "sora:nope", "out-1"},
		{"non-member target", "sora:pick", "out-99"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			response, err := server.SelectServer(context.Background(), selectRequest(tt.group, tt.target))
			if err != nil {
				t.Fatalf("SelectServer() error = %v", err)
			}
			if got := response.GetError().GetUserMessageKey(); got != string(errs.KeySelectUnsupported) {
				t.Errorf("key = %q, want %q (detail %q)", got, errs.KeySelectUnsupported,
					response.GetError().GetDetailRedacted())
			}
		})
	}
	if _, selects := eng.counts(); len(selects) != 0 {
		t.Errorf("refused selects still reached the engine: %v", selects)
	}
}

func TestSelectServerRefusesAForeignSession(t *testing.T) {
	eng := newSelectRecordingEngine()
	server, store := newSelectTestServer(t, eng)
	connectPickPlan(t, server, store)

	req := selectRequest("sora:pick", "out-1")
	req.SessionId = "s_not_the_running_one"
	response, err := server.SelectServer(context.Background(), req)
	if err != nil {
		t.Fatalf("SelectServer() error = %v", err)
	}
	if got := response.GetError().GetCode(); got != corev1.SoraErrorCode_SORA_ERROR_CODE_NOT_FOUND {
		t.Errorf("code = %s, want not found (%v)", got, response.GetError())
	}
	if _, selects := eng.counts(); len(selects) != 0 {
		t.Errorf("a foreign session's select reached the engine: %v", selects)
	}
}

func TestSelectServerRefusesABadToken(t *testing.T) {
	eng := newSelectRecordingEngine()
	server, _ := newSelectTestServer(t, eng)

	req := selectRequest("sora:pick", "out-1")
	req.ControlAuthenticator = []byte("not the token at all, and long enough to compare")
	_, err := server.SelectServer(context.Background(), req)
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("SelectServer() with a wrong token = %v, code = %s", err, status.Code(err))
	}
}

// TestSelectServerIsFasterThanAFullConnect measures the two switch
// paths on the fake engine: a full Connect pays the engine apply delay
// (a process restart on a real engine), a SelectServer pays only the
// controller call. The numbers are logged for the report; the assert
// keeps a wide margin so the test is about the order of magnitude, not
// about scheduler luck.
func TestSelectServerIsFasterThanAFullConnect(t *testing.T) {
	eng := newSelectRecordingEngine()
	eng.applyDelay = 120 * time.Millisecond
	eng.selectDelay = time.Millisecond
	server, store := newSelectTestServer(t, eng)

	start := time.Now()
	connectPickPlan(t, server, store)
	connectDur := time.Since(start)

	start = time.Now()
	response, err := server.SelectServer(context.Background(), selectRequest("sora:pick", "out-1"))
	selectDur := time.Since(start)
	if err != nil {
		t.Fatalf("SelectServer() error = %v", err)
	}
	if response.GetError() != nil {
		t.Fatalf("SelectServer() failed with %v", response.GetError())
	}
	t.Logf("full Connect = %v, SelectServer = %v (%.1fx faster)", connectDur, selectDur,
		float64(connectDur)/float64(selectDur))
	if selectDur >= connectDur/4 {
		t.Errorf("SelectServer took %v, want well under the full Connect's %v", selectDur, connectDur)
	}
}

// TestSelectServerWireShape pins the 1.12 contract additions in the
// generated descriptor: GroupSpec.selected is field 7 and the
// SelectServer messages carry the fields the client stub sends.
func TestSelectServerWireShape(t *testing.T) {
	file := corev1.File_sora_core_v1_core_control_proto
	field := func(message, name string) protoreflect.FieldDescriptor {
		m := file.Messages().ByName(protoreflect.Name(message))
		if m == nil {
			t.Fatalf("message %s is missing from the descriptor", message)
		}
		f := m.Fields().ByName(protoreflect.Name(name))
		if f == nil {
			t.Fatalf("%s.%s is missing from the descriptor", message, name)
		}
		return f
	}
	if got := field("GroupSpec", "selected").Number(); got != 7 {
		t.Errorf("GroupSpec.selected is field %d, want 7", got)
	}
	want := map[string]protoreflect.FieldNumber{
		"api_version": 1, "control_authenticator": 2, "request_id": 3,
		"session_id": 4, "group": 5, "target": 6,
	}
	for name, number := range want {
		if got := field("SelectServerRequest", name).Number(); got != number {
			t.Errorf("SelectServerRequest.%s is field %d, want %d", name, got, number)
		}
	}
	if got := field("SelectServerResponse", "status").Number(); got != 1 {
		t.Errorf("SelectServerResponse.status is field %d, want 1", got)
	}
	if got := field("SelectServerResponse", "error").Number(); got != 2 {
		t.Errorf("SelectServerResponse.error is field %d, want 2", got)
	}
	method := file.Services().ByName("CoreControl").Methods().ByName("SelectServer")
	if method == nil {
		t.Fatal("the CoreControl service has no SelectServer method")
	}
	if got := method.Input().Name(); got != "SelectServerRequest" {
		t.Errorf("SelectServer input = %s, want SelectServerRequest", got)
	}
	if got := method.Output().Name(); got != "SelectServerResponse" {
		t.Errorf("SelectServer output = %s, want SelectServerResponse", got)
	}
	// The selected member also survives a wire round trip.
	spec := &corev1.GroupSpec{Name: "g", Selected: "out-2"}
	raw, err := proto.Marshal(spec)
	if err != nil {
		t.Fatalf("marshaling GroupSpec: %v", err)
	}
	back := &corev1.GroupSpec{}
	if err := proto.Unmarshal(raw, back); err != nil {
		t.Fatalf("unmarshaling GroupSpec: %v", err)
	}
	if back.GetSelected() != "out-2" {
		t.Errorf("selected after a wire round trip = %q, want out-2", back.GetSelected())
	}
}
