package control

import (
	"context"
	"path/filepath"
	"sync"
	"time"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/custom"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	customv1 "github.com/levvs-one/sora-client/core/gen/sora/custom/v1"
)

// Custom servers live behind the same control-only authorization as the
// rest of the control plane: the shared gRPC interceptors admit only
// control peers (unknown methods default to control-only in checkMethodAuth),
// and every RPC additionally runs s.authorize over the in-request API
// version and control authenticator. Responses never carry credential
// material: the wire form marks secrets write-only.

// customStoreState lazily opens the custom-server store once per control
// Server, so MountCustomServices and CustomOutbounds share one instance
// without touching the Server struct.
type customStoreState struct {
	once  sync.Once
	store *custom.Store
	err   error
}

var customStores sync.Map // *Server -> *customStoreState

func customStateFor(s *Server) *customStoreState {
	v, _ := customStores.LoadOrStore(s, &customStoreState{})
	st := v.(*customStoreState)
	st.once.Do(func() {
		if s.dataDir == "" {
			st.err = errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
				"control: custom servers need a data directory")
			return
		}
		st.store, st.err = custom.Open(filepath.Join(s.dataDir, "custom"), s.secrets)
	})
	return st
}

// customServer implements customv1.CustomServersServer on top of the
// control Server's authenticator, secret vault, and data directory.
type customServer struct {
	customv1.UnimplementedCustomServersServer
	srv *Server
}

// MountCustomServices registers the CustomServers gRPC service on gs.
// Wiring (see reports/featlog-swarm-sw7.md): call once from main next to
// RegisterCoreControlServer, e.g.
// plane.MountCustomServices(app.server).
// A store that fails to open does not take the core down: every RPC then
// answers with an explicit "unavailable" error.
func (s *Server) MountCustomServices(gs *grpc.Server) {
	customv1.RegisterCustomServersServer(gs, &customServer{srv: s})
}

// noteCustomServersChanged re-emits the merged subscription states after a
// custom server is added or removed, so the client's combined server list
// (and therefore the plan builder) sees the change without a restart.
func (s *Server) noteCustomServersChanged() {
	if s.subs != nil {
		s.subs.broadcastCustomChange()
	}
}

// store resolves the lazily opened custom-server store.
func (c *customServer) store() (*custom.Store, error) {
	st := customStateFor(c.srv)
	if st.err != nil {
		return nil, st.err
	}
	return st.store, nil
}

// SaveCustomServer creates a server (empty id) or updates an existing one.
// The credentials field is write-only: it is stored in the vault and never
// echoed back.
func (c *customServer) SaveCustomServer(_ context.Context, req *customv1.SaveCustomServerRequest) (*customv1.SaveCustomServerResponse, error) {
	if err := c.srv.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	st, err := c.store()
	if err != nil {
		return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	in := req.GetServer()
	if in == nil {
		err := errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: the custom server is missing")
		return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	protocol, err := customProtocolFromWire(in.GetProtocol())
	if err != nil {
		return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	if err := custom.ValidatePort(in.GetPort()); err != nil {
		return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	// The vault material is read back by applyCredential at connect time;
	// refuse anything that is not a credential document now instead of
	// failing every later connect.
	if material := in.GetCredentials(); material != "" {
		if _, err := parseCredential([]byte(material)); err != nil {
			return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
		}
	}
	stored, err := st.Save(custom.Server{
		ID:       in.GetId(),
		Name:     in.GetName(),
		Protocol: protocol,
		Address:  in.GetAddress(),
		Port:     uint16(in.GetPort()), //nolint:gosec // ValidatePort bounded this value to 1..65535.
	}, []byte(in.GetCredentials()))
	if err != nil {
		return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	c.srv.noteCustomServersChanged()
	return &customv1.SaveCustomServerResponse{Server: customServerToWire(stored)}, nil
}

// ListCustomServers returns every stored custom server. Credentials are
// never returned; HasCredentials reports whether the vault holds them.
func (c *customServer) ListCustomServers(_ context.Context, req *customv1.ListCustomServersRequest) (*customv1.ListCustomServersResponse, error) {
	if err := c.srv.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	st, err := c.store()
	if err != nil {
		return &customv1.ListCustomServersResponse{Error: toWire(err, nil, "")}, nil
	}
	servers := st.List()
	out := make([]*customv1.CustomServer, 0, len(servers))
	for _, s := range servers {
		out = append(out, customServerToWire(s))
	}
	return &customv1.ListCustomServersResponse{Servers: out}, nil
}

// DeleteCustomServer removes a server together with its vault credentials.
// Unknown ids succeed for repeatable cleanup.
func (c *customServer) DeleteCustomServer(_ context.Context, req *customv1.DeleteCustomServerRequest) (*customv1.DeleteCustomServerResponse, error) {
	if err := c.srv.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	st, err := c.store()
	if err != nil {
		return &customv1.DeleteCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	if err := custom.ValidateID(req.GetId()); err != nil {
		return &customv1.DeleteCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	if err := st.Delete(req.GetId()); err != nil {
		return &customv1.DeleteCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	c.srv.noteCustomServersChanged()
	return &customv1.DeleteCustomServerResponse{}, nil
}

// TestCustomServer dials the stored server's address with a TCP handshake
// and reports reachability. Nothing is sent, so no credentials are
// involved, and none are returned.
func (c *customServer) TestCustomServer(ctx context.Context, req *customv1.TestCustomServerRequest) (*customv1.TestCustomServerResponse, error) {
	if err := c.srv.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	st, err := c.store()
	if err != nil {
		return &customv1.TestCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	if err := custom.ValidateID(req.GetId()); err != nil {
		return &customv1.TestCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	srv, ok := st.Get(req.GetId())
	if !ok {
		err := errs.Newf(errs.CodeNotFound, errs.KeyNotFound,
			"control: the custom server does not exist")
		return &customv1.TestCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	lat, err := custom.ProbeTCP(ctx, srv.Address, srv.Port,
		time.Duration(req.GetTimeoutMs())*time.Millisecond)
	if err != nil {
		return &customv1.TestCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	return &customv1.TestCustomServerResponse{
		Reachable: true,
		LatencyMs: uint64(max(0, lat.Milliseconds())),
	}, nil
}

// customServerToWire renders a stored server for the wire. The credentials
// field is deliberately left empty: secrets are write-only.
func customServerToWire(s custom.Server) *customv1.CustomServer {
	return &customv1.CustomServer{
		Id:             s.ID,
		Name:           s.Name,
		Protocol:       customProtocolToWire(s.Protocol),
		Address:        s.Address,
		Port:           uint32(s.Port),
		HasCredentials: s.SecretRef != "",
	}
}

// customProtocolFromWire maps the contract enum to the core protocol name.
func customProtocolFromWire(p customv1.CustomProtocol) (custom.Protocol, error) {
	switch p {
	case customv1.CustomProtocol_CUSTOM_PROTOCOL_VLESS:
		return custom.ProtocolVLESS, nil
	case customv1.CustomProtocol_CUSTOM_PROTOCOL_VMESS:
		return custom.ProtocolVMESS, nil
	case customv1.CustomProtocol_CUSTOM_PROTOCOL_TROJAN:
		return custom.ProtocolTrojan, nil
	case customv1.CustomProtocol_CUSTOM_PROTOCOL_SHADOWSOCKS:
		return custom.ProtocolShadowsocks, nil
	case customv1.CustomProtocol_CUSTOM_PROTOCOL_WIREGUARD:
		return custom.ProtocolWireGuard, nil
	default:
		return "", errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: unsupported custom server protocol")
	}
}

// customProtocolToWire maps the core protocol name to the contract enum.
func customProtocolToWire(p custom.Protocol) customv1.CustomProtocol {
	switch p {
	case custom.ProtocolVLESS:
		return customv1.CustomProtocol_CUSTOM_PROTOCOL_VLESS
	case custom.ProtocolVMESS:
		return customv1.CustomProtocol_CUSTOM_PROTOCOL_VMESS
	case custom.ProtocolTrojan:
		return customv1.CustomProtocol_CUSTOM_PROTOCOL_TROJAN
	case custom.ProtocolShadowsocks:
		return customv1.CustomProtocol_CUSTOM_PROTOCOL_SHADOWSOCKS
	case custom.ProtocolWireGuard:
		return customv1.CustomProtocol_CUSTOM_PROTOCOL_WIREGUARD
	default:
		return customv1.CustomProtocol_CUSTOM_PROTOCOL_UNSPECIFIED
	}
}

// CustomOutbounds converts stored custom servers to OutboundSpec entries so
// the client's combined server list can include them without touching the
// subscription book. Wiring: merged into the states returned by
// subscriptionBook.list/stateLocked (withCustomOutbounds) and into the
// extension host's ListServers (deduplicated by id).
func (s *Server) CustomOutbounds() []*corev1.OutboundSpec {
	st := customStateFor(s)
	if st.err != nil || st.store == nil {
		return nil
	}
	var out []*corev1.OutboundSpec
	for _, srv := range st.store.List() {
		spec := &corev1.OutboundSpec{
			Id:          "custom/" + srv.ID,
			DisplayName: srv.Name,
			Protocol:    string(srv.Protocol),
			Endpoint:    &corev1.Endpoint{Host: srv.Address, Port: uint32(srv.Port)},
		}
		// Shadowsocks carries its own encryption; outboundFromProto turns
		// TLS on for every other security value.
		if srv.Protocol == custom.ProtocolShadowsocks {
			spec.Security = "none"
		}
		if srv.SecretRef != "" {
			spec.Credentials = &corev1.CredentialsRef{Reference: srv.SecretRef}
		}
		out = append(out, spec)
	}
	return out
}
