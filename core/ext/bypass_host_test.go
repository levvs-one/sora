package ext

// Behavioural gating pins for the six Anti-DPI host RPCs (M3): each
// RPC refuses a token without its permission with PermissionDenied
// (before any dep runs), layers are strictly per-extension, and
// ApplyBypassLayer has no extension-id field to spoof — the token
// alone names the layer's owner.

import (
	"context"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	extv1 "github.com/levvs-one/sora-client/core/gen/sora/ext/v1"
)

type bypassHostFixture struct {
	host       *Host
	issuer     *TokenIssuer
	layers     *LayerStore
	tuneCalls  int
	watchCalls int
}

func newBypassHostFixture(t *testing.T) *bypassHostFixture {
	t.Helper()
	f := &bypassHostFixture{issuer: NewTokenIssuer()}
	store, err := NewLayerStore("")
	if err != nil {
		t.Fatal(err)
	}
	f.layers = store
	closed := make(chan BypassEvent)
	close(closed)
	f.host = NewHost(f.issuer, Deps{
		BypassLayers: store,
		BypassCapabilities: func(context.Context) (string, []BackendState, error) {
			return "linux", []BackendState{{Kind: "tpws", Available: true}}, nil
		},
		BypassState: func(_ context.Context, _ string) (*BypassStateInfo, error) {
			return &BypassStateInfo{Platform: "linux", GlobalSource: "none"}, nil
		},
		TuneDesync: func(context.Context, string) (*TuneOutcome, error) {
			f.tuneCalls++
			return &TuneOutcome{WinnerID: "winner"}, nil
		},
		WatchBypassEvents: func(context.Context) (<-chan BypassEvent, error) {
			f.watchCalls++
			return closed, nil
		},
	})
	return f
}

func (f *bypassHostFixture) token(t *testing.T, id string, perms ...string) []byte {
	t.Helper()
	tok, err := f.issuer.Mint(id, perms)
	if err != nil {
		t.Fatal(err)
	}
	return []byte(tok)
}

type bypassEventStream struct {
	grpc.ServerStreamingServer[extv1.BypassEvent]
	ctx context.Context
}

func (s *bypassEventStream) Context() context.Context      { return s.ctx }
func (s *bypassEventStream) Send(*extv1.BypassEvent) error { return nil }

func wantPermissionDenied(t *testing.T, err error, what string) {
	t.Helper()
	if err == nil {
		t.Fatalf("%s: succeeded, want PermissionDenied", what)
	}
	if got := status.Code(err); got != codes.PermissionDenied {
		t.Fatalf("%s: code = %s (%v), want PermissionDenied", what, got, err)
	}
}

// TestBypassHostGatingMatrix: every one of the six bypass RPCs
// refuses a token that carries no bypass permission at all, and a
// token scoped to a different bypass permission where the matrix
// distinguishes them.
func TestBypassHostGatingMatrix(t *testing.T) {
	f := newBypassHostFixture(t)
	ctx := context.Background()
	noPerm := f.token(t, "com.example.a", "servers.read")
	calls := map[string]func(tok []byte) error{
		"GetBypassCapabilities": func(tok []byte) error {
			_, err := f.host.GetBypassCapabilities(ctx, &extv1.GetBypassCapabilitiesRequest{ExtensionToken: tok})
			return err
		},
		"GetBypassState": func(tok []byte) error {
			_, err := f.host.GetBypassState(ctx, &extv1.GetBypassStateRequest{ExtensionToken: tok})
			return err
		},
		"GetBypassLayer": func(tok []byte) error {
			_, err := f.host.GetBypassLayer(ctx, &extv1.GetBypassLayerRequest{ExtensionToken: tok})
			return err
		},
		"ApplyBypassLayer": func(tok []byte) error {
			_, err := f.host.ApplyBypassLayer(ctx, &extv1.ApplyBypassLayerRequest{
				ExtensionToken: tok, HasGlobal: true, Global: tpwsStrategy(),
			})
			return err
		},
		"TuneDesync": func(tok []byte) error {
			_, err := f.host.TuneDesync(ctx, &extv1.TuneDesyncRequest{ExtensionToken: tok, Engine: "nfqws"})
			return err
		},
		"WatchBypassEvents": func(tok []byte) error {
			return f.host.WatchBypassEvents(&extv1.WatchBypassEventsRequest{ExtensionToken: tok},
				&bypassEventStream{ctx: ctx})
		},
	}
	for name, call := range calls {
		wantPermissionDenied(t, call(noPerm), name+" without any bypass permission")
	}
	// Cross-scopes: a read token cannot write or tune; a write token
	// cannot read or watch; a tune token cannot read.
	readOnly := f.token(t, "com.example.a", "bypass.read")
	wantPermissionDenied(t, calls["ApplyBypassLayer"](readOnly), "ApplyBypassLayer with bypass.read only")
	wantPermissionDenied(t, calls["TuneDesync"](readOnly), "TuneDesync with bypass.read only")
	writeOnly := f.token(t, "com.example.a", "bypass.write")
	wantPermissionDenied(t, calls["GetBypassState"](writeOnly), "GetBypassState with bypass.write only")
	wantPermissionDenied(t, calls["GetBypassLayer"](writeOnly), "GetBypassLayer with bypass.write only")
	wantPermissionDenied(t, calls["WatchBypassEvents"](writeOnly), "WatchBypassEvents with bypass.write only")
	tuneOnly := f.token(t, "com.example.a", "bypass.tune")
	wantPermissionDenied(t, calls["GetBypassCapabilities"](tuneOnly), "GetBypassCapabilities with bypass.tune only")

	// Positive control: a fully-scoped token passes every gate (the
	// denied results above are the permission check, not a broken
	// fixture).
	full := f.token(t, "com.example.a", "bypass.read", "bypass.write", "bypass.tune")
	for name, call := range calls {
		if err := call(full); err != nil {
			t.Errorf("%s with all bypass permissions: %v", name, err)
		}
	}
}

// TestBypassHostTuneDesyncGateRunsBeforeDep: without bypass.tune the
// tuner dep is never invoked.
func TestBypassHostTuneDesyncGateRunsBeforeDep(t *testing.T) {
	f := newBypassHostFixture(t)
	tok := f.token(t, "com.example.a", "bypass.read", "bypass.write")
	_, err := f.host.TuneDesync(context.Background(), &extv1.TuneDesyncRequest{ExtensionToken: tok, Engine: "nfqws"})
	wantPermissionDenied(t, err, "TuneDesync without bypass.tune")
	if f.tuneCalls != 0 {
		t.Errorf("tuner dep ran %d times behind a denied gate", f.tuneCalls)
	}
}

// TestBypassHostWatchGateRunsBeforeStream: without bypass.read the
// watch dep is never invoked — the refusal happens before any
// stream is opened.
func TestBypassHostWatchGateRunsBeforeStream(t *testing.T) {
	f := newBypassHostFixture(t)
	tok := f.token(t, "com.example.a", "bypass.write")
	err := f.host.WatchBypassEvents(&extv1.WatchBypassEventsRequest{ExtensionToken: tok},
		&bypassEventStream{ctx: context.Background()})
	wantPermissionDenied(t, err, "WatchBypassEvents without bypass.read")
	if f.watchCalls != 0 {
		t.Errorf("watch dep ran %d times behind a denied gate", f.watchCalls)
	}
}

// TestBypassHostLayerIsolation: a layer applied by extension A is
// invisible to extension B, whose own layer reads back empty.
func TestBypassHostLayerIsolation(t *testing.T) {
	f := newBypassHostFixture(t)
	ctx := context.Background()
	tokA := f.token(t, "com.example.a", "bypass.read", "bypass.write")
	if _, err := f.host.ApplyBypassLayer(ctx, &extv1.ApplyBypassLayerRequest{
		ExtensionToken: tokA, HasGlobal: true, Global: tpwsStrategy(),
		Bindings: []*extv1.BypassBinding{{Match: "domain:example.com", Strategy: tpwsStrategy()}},
	}); err != nil {
		t.Fatalf("ApplyBypassLayer (A): %v", err)
	}
	tokB := f.token(t, "com.example.b", "bypass.read", "bypass.write")
	gotB, err := f.host.GetBypassLayer(ctx, &extv1.GetBypassLayerRequest{ExtensionToken: tokB})
	if err != nil {
		t.Fatalf("GetBypassLayer (B): %v", err)
	}
	if gotB.GetHasGlobal() || len(gotB.GetBindings()) != 0 || gotB.GetUpdatedAtUnix() != 0 {
		t.Errorf("extension B sees %+v, want its own empty layer", gotB)
	}
	gotA, err := f.host.GetBypassLayer(ctx, &extv1.GetBypassLayerRequest{ExtensionToken: tokA})
	if err != nil {
		t.Fatalf("GetBypassLayer (A): %v", err)
	}
	if !gotA.GetHasGlobal() || len(gotA.GetBindings()) != 1 {
		t.Errorf("extension A reads back %+v, want its applied layer", gotA)
	}
}

// TestBypassHostApplyHasNoSpoofableID: ApplyBypassLayerRequest
// carries no extension_id field at all (checked on the proto
// descriptor), so identity comes only from the token: a layer
// applied with A's token lands under A and nowhere else.
func TestBypassHostApplyHasNoSpoofableID(t *testing.T) {
	fields := (&extv1.ApplyBypassLayerRequest{}).ProtoReflect().Descriptor().Fields()
	for i := 0; i < fields.Len(); i++ {
		if name := string(fields.Get(i).Name()); name == "extension_id" {
			t.Fatal("ApplyBypassLayerRequest grew an extension_id field: the host must keep ignoring it (owner = token)")
		}
	}
	f := newBypassHostFixture(t)
	tokA := f.token(t, "com.example.a", "bypass.write")
	if _, err := f.host.ApplyBypassLayer(context.Background(), &extv1.ApplyBypassLayerRequest{
		ExtensionToken: tokA, HasGlobal: true, Global: tpwsStrategy(),
	}); err != nil {
		t.Fatalf("ApplyBypassLayer: %v", err)
	}
	if _, ok := f.layers.Get("com.example.a"); !ok {
		t.Error("the layer was not stored under the token's extension")
	}
	if _, ok := f.layers.Get("com.example.b"); ok {
		t.Error("the layer leaked under another extension id")
	}
}
