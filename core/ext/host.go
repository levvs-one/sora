package ext

import (
	"context"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	extv1 "github.com/levvs-one/sora-client/core/gen/sora/ext/v1"
)

// RPC -> required permission. Empty means "any valid token". The map is
// closed: an RPC name that is not listed here is denied, so a newly added
// RPC cannot silently inherit token-only access.
var rpcPermissions = map[string]string{
	"GetConnections":       "connections.read",
	"GetServers":           "servers.read",
	"Notify":               "notifications",
	"WatchExtensionEvents": "",
	// Anti-DPI seam (contract 1.14): reads share bypass.read; applying a
	// layer is bypass.write; running the tuner is bypass.tune.
	"GetBypassCapabilities": "bypass.read",
	"GetBypassState":        "bypass.read",
	"GetBypassLayer":        "bypass.read",
	"WatchBypassEvents":     "bypass.read",
	"ApplyBypassLayer":      "bypass.write",
	"TuneDesync":            "bypass.tune",
}

// Connection is what the host exposes to extensions: process name and
// counters only. No PIDs, no paths, no raw IPs beyond the host string the
// connection center already shows the user.
type Connection struct {
	ID      string
	Process string
	Host    string
	Up      uint64
	Down    uint64
}

// Server is the extension-visible server subset.
type Server struct {
	ID        string
	Name      string
	Country   string
	LatencyMs int64 // -1 when unknown
}

// BackendState is one bypass backend's measured availability, as the
// GetBypassCapabilities dep reports it.
type BackendState struct {
	// Kind is "tpws" or "nfqws".
	Kind      string
	Available bool
	// Reason names the missing capability and the remedy when the
	// backend is unavailable; empty when available.
	Reason string
}

// BypassStateInfo is the core's effective bypass state, as the
// GetBypassState dep reports it. The semantics live with the producer
// (core/control): GlobalSource is "user", "extension", "core_default"
// or "none"; BindingsCount counts the bindings the last built plan
// actually carries.
type BypassStateInfo struct {
	Platform      string
	GlobalSource  string
	GlobalFrom    string
	SessionActive bool
	PendingApply  bool
	BindingsCount int
}

// TuneOutcome is one desync tuner run's result for the TuneDesync dep.
// Strategy is the winner's strategy in contract form, or nil when the
// winner has no faithful strategy rendering (or nothing worked).
type TuneOutcome struct {
	WinnerID       string
	WinnerDescribe string
	Score          float64
	Attempts       int32
	Strategy       *corev1.BypassStrategy
}

// BypassEvent is one bypass-relevant session event for the
// WatchBypassEvents dep: Kind is "censorship", "strategy" or "session".
type BypassEvent struct {
	Kind           string
	CensorshipKind string
	Explanation    string
	At             time.Time
}

// Deps are the core capabilities the host service needs. core/control will
// adapt its session state to these when wiring the service.
type Deps struct {
	// VerifyControl checks the core control token (app-only calls).
	VerifyControl func(token []byte) bool
	// ListConnections returns the live connection list.
	ListConnections func(ctx context.Context) ([]Connection, error)
	// ListServers returns the server list.
	ListServers func(ctx context.Context) ([]Server, error)
	// Notify shows a notification attributed to the extension.
	Notify func(ctx context.Context, extensionID, title, body string) error
	// WatchEvents streams core events as (kind, detail) pairs.
	WatchEvents func(ctx context.Context) (<-chan [2]string, error)
	// GrantedPermissions returns the permissions the user granted to the
	// extension and whether it is installed and enabled. When set, MintToken
	// enforces that a minted token is scoped to at most the granted
	// permissions, and refuses to mint for an unknown or disabled extension.
	// When nil, the control-token caller is trusted to pass exactly the
	// granted permissions, as MintTokenRequest documents.
	GrantedPermissions func(extensionID string) (perms []string, ok bool)
	// BypassCapabilities returns the measured bypass capability
	// snapshot: the executor platform and each backend's availability.
	BypassCapabilities func(ctx context.Context) (platform string, backends []BackendState, err error)
	// BypassLayers is the persistent store of per-extension bypass
	// layers. ApplyBypassLayer writes the calling extension's layer
	// into it and GetBypassLayer reads it back; nil disables both.
	BypassLayers *LayerStore
	// BypassState returns the effective bypass state for the calling
	// extension (see BypassStateInfo).
	BypassState func(ctx context.Context, extensionID string) (*BypassStateInfo, error)
	// TuneDesync runs the desync tuner once for the named engine
	// ("tpws"/"nfqws"; empty = the core default).
	TuneDesync func(ctx context.Context, engine string) (*TuneOutcome, error)
	// WatchBypassEvents subscribes to bypass-relevant session events.
	WatchBypassEvents func(ctx context.Context) (<-chan BypassEvent, error)
}

// Host implements extv1.ExtensionHostServer.
type Host struct {
	extv1.UnimplementedExtensionHostServer

	mu     sync.Mutex
	issuer *TokenIssuer
	deps   Deps
}

// NewHost returns the service. issuer is usually the extension store's
// issuer so disabling an extension revokes its tokens everywhere at once.
func NewHost(issuer *TokenIssuer, deps Deps) *Host {
	return &Host{issuer: issuer, deps: deps}
}

// check verifies the token and the permission for rpc.
func (h *Host) check(token []byte, rpc string) (*Grant, error) {
	if len(token) == 0 {
		return nil, status.Error(codes.Unauthenticated, "ext: missing extension token")
	}
	g, ok := h.issuer.Verify(string(token))
	if !ok {
		return nil, status.Error(codes.Unauthenticated, "ext: bad or revoked extension token")
	}
	need, known := rpcPermissions[rpc]
	if !known {
		return nil, status.Error(codes.PermissionDenied, "ext: unknown RPC")
	}
	if need != "" && !g.Permissions[need] {
		return nil, status.Errorf(codes.PermissionDenied,
			"ext: the extension %q was not granted %q", g.ExtensionID, need)
	}
	return g, nil
}

// MintToken is app-only: it needs the control token, like Connect. The
// minted token is scoped to at most the requested permissions; when
// Deps.GrantedPermissions is wired, the request is additionally checked
// against what the user actually granted the extension.
func (h *Host) MintToken(ctx context.Context, req *extv1.MintTokenRequest) (*extv1.MintTokenResponse, error) {
	if h.deps.VerifyControl == nil || !h.deps.VerifyControl(req.GetControlToken()) {
		return nil, status.Error(codes.Unauthenticated, "ext: control authentication failed")
	}
	id := strings.TrimSpace(req.GetExtensionId())
	if id == "" {
		return nil, status.Error(codes.InvalidArgument, "ext: empty extension id")
	}
	if h.deps.GrantedPermissions != nil {
		granted, ok := h.deps.GrantedPermissions(id)
		if !ok {
			return nil, status.Errorf(codes.NotFound,
				"ext: %q is not installed or not enabled", id)
		}
		have := make(map[string]bool, len(granted))
		for _, p := range granted {
			have[p] = true
		}
		for _, p := range req.GetPermissions() {
			if !have[p] {
				return nil, status.Errorf(codes.PermissionDenied,
					"ext: permission %q was not granted to %q", p, id)
			}
		}
	}
	tok, err := h.issuer.Mint(id, req.GetPermissions())
	if err != nil {
		return nil, toStatus(err)
	}
	return &extv1.MintTokenResponse{ExtensionToken: []byte(tok)}, nil
}

// RevokeToken is app-only.
func (h *Host) RevokeToken(ctx context.Context, req *extv1.RevokeTokenRequest) (*extv1.RevokeTokenResponse, error) {
	if h.deps.VerifyControl == nil || !h.deps.VerifyControl(req.GetControlToken()) {
		return nil, status.Error(codes.Unauthenticated, "ext: control authentication failed")
	}
	h.issuer.Revoke(string(req.GetExtensionToken()))
	return &extv1.RevokeTokenResponse{}, nil
}

// GetConnections implements the connections.read API.
func (h *Host) GetConnections(ctx context.Context, req *extv1.GetConnectionsRequest) (*extv1.GetConnectionsResponse, error) {
	if _, err := h.check(req.GetExtensionToken(), "GetConnections"); err != nil {
		return nil, err
	}
	if h.deps.ListConnections == nil {
		return nil, status.Error(codes.Unimplemented, "ext: connections are not wired")
	}
	conns, err := h.deps.ListConnections(ctx)
	if err != nil {
		return nil, toStatus(err)
	}
	resp := &extv1.GetConnectionsResponse{}
	for _, c := range conns {
		resp.Connections = append(resp.Connections, &extv1.ExtensionConnection{
			Id: c.ID, Process: c.Process, Host: c.Host, UpBytes: c.Up, DownBytes: c.Down,
		})
	}
	return resp, nil
}

// GetServers implements the servers.read API.
func (h *Host) GetServers(ctx context.Context, req *extv1.GetServersRequest) (*extv1.GetServersResponse, error) {
	if _, err := h.check(req.GetExtensionToken(), "GetServers"); err != nil {
		return nil, err
	}
	if h.deps.ListServers == nil {
		return nil, status.Error(codes.Unimplemented, "ext: servers are not wired")
	}
	servers, err := h.deps.ListServers(ctx)
	if err != nil {
		return nil, toStatus(err)
	}
	resp := &extv1.GetServersResponse{}
	for _, s := range servers {
		resp.Servers = append(resp.Servers, &extv1.ExtensionServer{
			Id: s.ID, Name: s.Name, Country: s.Country, LatencyMs: s.LatencyMs,
		})
	}
	return resp, nil
}

// Notify implements the notifications API.
func (h *Host) Notify(ctx context.Context, req *extv1.NotifyRequest) (*extv1.NotifyResponse, error) {
	g, err := h.check(req.GetExtensionToken(), "Notify")
	if err != nil {
		return nil, err
	}
	title := strings.TrimSpace(req.GetTitle())
	body := strings.TrimSpace(req.GetBody())
	if title == "" || len(title) > 120 || len(body) > 500 {
		return nil, status.Error(codes.InvalidArgument, "ext: bad notification text")
	}
	if h.deps.Notify == nil {
		return nil, status.Error(codes.Unimplemented, "ext: notifications are not wired")
	}
	if err := h.deps.Notify(ctx, g.ExtensionID, title, body); err != nil {
		return nil, toStatus(err)
	}
	return &extv1.NotifyResponse{}, nil
}

// WatchExtensionEvents streams lifecycle and network events. It needs no
// permission beyond a valid token: every enabled extension may know whether
// the session is up. Only the event kind is forwarded — the detail is
// withheld on purpose: journal details carry the LAN network fingerprint
// (interface names and addresses), which no permission was granted for.
func (h *Host) WatchExtensionEvents(req *extv1.WatchExtensionEventsRequest, stream extv1.ExtensionHost_WatchExtensionEventsServer) error {
	if _, err := h.check(req.GetExtensionToken(), "WatchExtensionEvents"); err != nil {
		return err
	}
	if h.deps.WatchEvents == nil {
		return status.Error(codes.Unimplemented, "ext: events are not wired")
	}
	ch, err := h.deps.WatchEvents(stream.Context())
	if err != nil {
		return toStatus(err)
	}
	for {
		select {
		case <-stream.Context().Done():
			return nil
		case ev, ok := <-ch:
			if !ok {
				return nil
			}
			if err := stream.Send(&extv1.ExtensionEvent{
				Kind: ev[0], Detail: "", At: timestamppb.New(time.Now().UTC()),
			}); err != nil {
				return err
			}
		}
	}
}

// GetBypassCapabilities implements the bypass.read capability probe:
// the answer is the dep's measured snapshot, never an assumption.
func (h *Host) GetBypassCapabilities(ctx context.Context, req *extv1.GetBypassCapabilitiesRequest) (*extv1.GetBypassCapabilitiesResponse, error) {
	if _, err := h.check(req.GetExtensionToken(), "GetBypassCapabilities"); err != nil {
		return nil, err
	}
	if h.deps.BypassCapabilities == nil {
		return nil, status.Error(codes.Unimplemented, "ext: bypass capabilities are not wired")
	}
	platform, backends, err := h.deps.BypassCapabilities(ctx)
	if err != nil {
		return nil, toStatus(err)
	}
	resp := &extv1.GetBypassCapabilitiesResponse{Platform: platform}
	for _, b := range backends {
		resp.Backends = append(resp.Backends, &extv1.BackendInfo{
			Kind: b.Kind, Available: b.Available, Reason: b.Reason,
		})
	}
	return resp, nil
}

// GetBypassState implements the bypass.read state read.
func (h *Host) GetBypassState(ctx context.Context, req *extv1.GetBypassStateRequest) (*extv1.GetBypassStateResponse, error) {
	g, err := h.check(req.GetExtensionToken(), "GetBypassState")
	if err != nil {
		return nil, err
	}
	if h.deps.BypassState == nil {
		return nil, status.Error(codes.Unimplemented, "ext: bypass state is not wired")
	}
	info, err := h.deps.BypassState(ctx, g.ExtensionID)
	if err != nil {
		return nil, toStatus(err)
	}
	if info == nil {
		return nil, status.Error(codes.Internal, "ext: bypass state is not wired")
	}
	return &extv1.GetBypassStateResponse{
		Platform:      info.Platform,
		GlobalSource:  info.GlobalSource,
		GlobalFrom:    info.GlobalFrom,
		SessionActive: info.SessionActive,
		PendingApply:  info.PendingApply,
		BindingsCount: int32(info.BindingsCount), //nolint:gosec // bounded by the plan's rule limit at merge time
	}, nil
}

// GetBypassLayer returns the calling extension's own stored layer. An
// extension with no layer gets the empty layer, not an error: "no
// layer" is a normal state, and layers of other extensions are never
// visible here.
func (h *Host) GetBypassLayer(ctx context.Context, req *extv1.GetBypassLayerRequest) (*extv1.GetBypassLayerResponse, error) {
	g, err := h.check(req.GetExtensionToken(), "GetBypassLayer")
	if err != nil {
		return nil, err
	}
	if h.deps.BypassLayers == nil {
		return nil, status.Error(codes.Unimplemented, "ext: bypass layers are not wired")
	}
	resp := &extv1.GetBypassLayerResponse{}
	layer, ok := h.deps.BypassLayers.Get(g.ExtensionID)
	if !ok {
		return resp, nil
	}
	resp.HasGlobal = layer.Global != nil
	resp.Global = layer.Global
	for _, b := range layer.Bindings {
		resp.Bindings = append(resp.Bindings, &extv1.BypassBinding{Match: b.Match, Strategy: b.Strategy})
	}
	resp.UpdatedAtUnix = layer.UpdatedAt.Unix()
	return resp, nil
}

// ApplyBypassLayer replaces the calling extension's stored layer. An
// empty layer (no global, no bindings) clears it. The store validates
// fail-closed; the layer takes effect at the next plan build and never
// overrides user rules (the merge lives in core/control).
func (h *Host) ApplyBypassLayer(ctx context.Context, req *extv1.ApplyBypassLayerRequest) (*extv1.ApplyBypassLayerResponse, error) {
	g, err := h.check(req.GetExtensionToken(), "ApplyBypassLayer")
	if err != nil {
		return nil, err
	}
	if h.deps.BypassLayers == nil {
		return nil, status.Error(codes.Unimplemented, "ext: bypass layers are not wired")
	}
	layer := Layer{}
	if req.GetHasGlobal() {
		layer.Global = req.GetGlobal()
	}
	for _, b := range req.GetBindings() {
		layer.Bindings = append(layer.Bindings, Binding{Match: b.GetMatch(), Strategy: b.GetStrategy()})
	}
	if layer.IsEmpty() {
		if err := h.deps.BypassLayers.Delete(g.ExtensionID); err != nil {
			return nil, toStatus(err)
		}
		return &extv1.ApplyBypassLayerResponse{UpdatedAtUnix: time.Now().UTC().Unix()}, nil
	}
	if err := h.deps.BypassLayers.Set(g.ExtensionID, layer); err != nil {
		return nil, toStatus(err)
	}
	stored, _ := h.deps.BypassLayers.Get(g.ExtensionID)
	return &extv1.ApplyBypassLayerResponse{UpdatedAtUnix: stored.UpdatedAt.Unix()}, nil
}

// TuneDesync implements the bypass.tune tuner run. The request carries
// no target by design; the dep probes only the core's canaries.
func (h *Host) TuneDesync(ctx context.Context, req *extv1.TuneDesyncRequest) (*extv1.TuneDesyncResponse, error) {
	if _, err := h.check(req.GetExtensionToken(), "TuneDesync"); err != nil {
		return nil, err
	}
	if h.deps.TuneDesync == nil {
		return nil, status.Error(codes.Unimplemented, "ext: bypass tuning is not wired")
	}
	out, err := h.deps.TuneDesync(ctx, req.GetEngine())
	if err != nil {
		return nil, toStatus(err)
	}
	if out == nil {
		return &extv1.TuneDesyncResponse{}, nil
	}
	return &extv1.TuneDesyncResponse{
		WinnerId:       out.WinnerID,
		WinnerDescribe: out.WinnerDescribe,
		Score:          out.Score,
		Attempts:       out.Attempts,
		HasStrategy:    out.Strategy != nil,
		Strategy:       out.Strategy,
	}, nil
}

// WatchBypassEvents streams bypass-relevant session events to an
// extension with bypass.read. Unlike WatchExtensionEvents, the event
// payload is the point here (a censorship verdict's kind and
// explanation are exactly what an Anti-DPI panel exists to show), and
// bypass.read is the permission that was granted for it.
func (h *Host) WatchBypassEvents(req *extv1.WatchBypassEventsRequest, stream extv1.ExtensionHost_WatchBypassEventsServer) error {
	if _, err := h.check(req.GetExtensionToken(), "WatchBypassEvents"); err != nil {
		return err
	}
	if h.deps.WatchBypassEvents == nil {
		return status.Error(codes.Unimplemented, "ext: bypass events are not wired")
	}
	ch, err := h.deps.WatchBypassEvents(stream.Context())
	if err != nil {
		return toStatus(err)
	}
	for {
		select {
		case <-stream.Context().Done():
			return nil
		case ev, ok := <-ch:
			if !ok {
				return nil
			}
			at := ev.At
			if at.IsZero() {
				at = time.Now().UTC()
			}
			if err := stream.Send(&extv1.BypassEvent{
				Kind: ev.Kind, CensorshipKind: ev.CensorshipKind,
				Explanation: ev.Explanation, At: timestamppb.New(at),
			}); err != nil {
				return err
			}
		}
	}
}

// toStatus maps core errors to gRPC statuses, preserving codes.
func toStatus(err error) error {
	if err == nil {
		return nil
	}
	if e, ok := err.(*errs.Error); ok {
		switch e.Code() {
		case errs.CodeInvalidArgument:
			return status.Error(codes.InvalidArgument, e.Error())
		case errs.CodeUnauthenticated:
			return status.Error(codes.Unauthenticated, e.Error())
		case errs.CodeNotFound:
			return status.Error(codes.NotFound, e.Error())
		case errs.CodeUnavailable:
			return status.Error(codes.Unavailable, e.Error())
		case errs.CodeResourceExhausted:
			return status.Error(codes.ResourceExhausted, e.Error())
		case errs.CodeFailedPrecondition:
			return status.Error(codes.FailedPrecondition, e.Error())
		}
	}
	return status.Error(codes.Internal, err.Error())
}
