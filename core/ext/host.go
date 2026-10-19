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
		}
	}
	return status.Error(codes.Internal, err.Error())
}

// RegisterOn registers the service on a gRPC server. Wiring note: call this
// from the core's gRPC server setup (core/control/server.go) with the same
// *grpc.Server that serves CoreControl:
//
//	extHost := ext.NewHost(store.Issuer(), ext.Deps{
//		...,
//		GrantedPermissions: func(id string) ([]string, bool) {
//			inst, ok := store.Get(id)
//			if !ok || !inst.Enabled {
//				return nil, false
//			}
//			return inst.Granted, true
//		},
//	})
//	extv1.RegisterExtensionHostServer(grpcServer, extHost)
//
// Wiring GrantedPermissions makes MintToken enforce that minted tokens never
// exceed what the user granted (and never mint for unknown or disabled
// extensions). Disabling an extension revokes its tokens everywhere at once
// because the issuer is the store's.
func RegisterOn(register func(srv extv1.ExtensionHostServer), h *Host) {
	register(h)
}
