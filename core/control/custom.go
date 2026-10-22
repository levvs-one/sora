package control

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"maps"
	"net/netip"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/custom"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	customv1 "github.com/levvs-one/sora-client/core/gen/sora/custom/v1"
	"github.com/levvs-one/sora-client/core/parser"
)

// Custom servers live behind the same control-only authorization as the
// rest of the control plane: the shared gRPC interceptors admit only
// control peers (unknown methods default to control-only in checkMethodAuth),
// and every RPC additionally runs s.authorize over the in-request API
// version and control authenticator. Stored credentials never leave the core. Preview derives
// draft material exclusively from the supplied link.

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
	protocol := custom.Protocol(in.GetProtocolName())
	if protocol == "" {
		protocol, err = customProtocolFromWire(in.GetProtocol())
	}
	if err == nil {
		err = custom.ValidateProtocol(protocol)
	}
	if err != nil {
		return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	if err := custom.ValidatePort(in.GetPort()); err != nil {
		return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	// Updating a secret must retain the imported TLS and transport options
	// that the compact editor does not expose. Switching protocol starts fresh.
	material := in.GetCredentials()
	var current custom.Server
	if in.GetId() != "" {
		current, _ = st.Get(in.GetId())
	}
	if material != "" {
		values, err := parseCredential([]byte(material))
		if err == nil && current.SecretRef != "" && current.Protocol == protocol && !req.GetReplaceCredentials() {
			var previous []byte
			previous, err = c.srv.secrets.Get(current.SecretRef)
			if err == nil {
				var merged map[string]string
				merged, err = parseCredential(previous)
				if err == nil {
					maps.Copy(merged, values)
					values = merged
				}
			}
		}
		if err == nil && protocol == custom.ProtocolWireGuard {
			err = checkWireGuardCredential(values)
		}
		if err != nil {
			return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
		}
		raw, err := json.Marshal(values)
		if err != nil {
			return nil, err
		}
		material = string(raw)
	} else if current.SecretRef == "" || current.Protocol != protocol {
		err := errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds, "control: a new protocol needs credentials")
		return &customv1.SaveCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	stored, err := st.Save(custom.Server{
		ID:        in.GetId(),
		Name:      in.GetName(),
		Protocol:  protocol,
		Transport: in.GetTransport(),
		Security:  in.GetSecurity(),
		Address:   in.GetAddress(),
		Port:      uint16(in.GetPort()), //nolint:gosec // ValidatePort bounded this value to 1..65535.
	}, []byte(material))
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
	return &customv1.ListCustomServersResponse{Servers: out, Protocols: custom.Protocols()}, nil
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
		ProtocolName:   string(s.Protocol),
		Transport:      s.Transport,
		Security:       s.Security,
		Outbound:       customOutbound(s),
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
		spec := customOutbound(srv)
		out = append(out, spec)
	}
	return out
}

// checkWireGuardCredential makes sure a hand-entered WireGuard document has
// what the engines need: a private key, interface addresses and at least
// one peer with a public key and allowed IPs. applyCredential reads the
// same keys back at connect time.
func checkWireGuardCredential(values map[string]string) error {
	bad := func(what string) error {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds, "control: WireGuard %s", what)
	}
	if !isWireGuardKey(values["private_key"]) {
		return bad("private key must be 32 bytes of base64")
	}
	addresses := strings.Split(values["addresses"], ",")
	if values["addresses"] == "" {
		return bad("needs at least one interface address")
	}
	for _, a := range addresses {
		if _, err := netip.ParsePrefix(strings.TrimSpace(a)); err != nil {
			return bad("address " + strconv.Quote(a) + " is not a CIDR")
		}
	}
	var peers []engine.WireGuardPeer
	if err := json.Unmarshal([]byte(values["peers"]), &peers); err != nil || len(peers) == 0 {
		return bad("needs at least one peer")
	}
	for _, p := range peers {
		if !isWireGuardKey(p.PublicKey) || (p.PreSharedKey != "" && !isWireGuardKey(p.PreSharedKey)) {
			return bad("peer keys must be 32 bytes of base64")
		}
		if len(p.AllowedIPs) == 0 {
			return bad("peer needs allowed IPs")
		}
		for _, a := range p.AllowedIPs {
			if _, err := netip.ParsePrefix(a); err != nil {
				return bad("allowed IP " + strconv.Quote(a) + " is not a CIDR")
			}
		}
		if p.PersistentKeepalive < 0 || p.PersistentKeepalive > 65535 {
			return bad("keepalive must be 0 to 65535 seconds")
		}
	}
	return nil
}

func isWireGuardKey(key string) bool {
	raw, err := base64.StdEncoding.DecodeString(key)
	return err == nil && len(raw) == 32
}

// customOutbound is shared by List and subscription broadcasts so a server
// is also connectable when the user has no subscriptions.
func customOutbound(srv custom.Server) *corev1.OutboundSpec {
	spec := &corev1.OutboundSpec{
		Id: "custom/" + srv.ID, DisplayName: srv.Name, Protocol: string(srv.Protocol),
		Endpoint:  &corev1.Endpoint{Host: srv.Address, Port: uint32(srv.Port)},
		Transport: srv.Transport, Security: srv.Security,
	}
	if spec.Security == "" {
		switch srv.Protocol {
		case custom.ProtocolShadowsocks, custom.ProtocolWireGuard, "socks5", "http":
			spec.Security = "none"
		}
	}
	if srv.Protocol == custom.ProtocolWireGuard && spec.Transport == "" {
		spec.Transport = "udp"
	}
	if srv.SecretRef != "" {
		spec.Credentials = &corev1.CredentialsRef{Reference: srv.SecretRef}
	}
	return spec
}

func (c *customServer) PreviewCustomServer(_ context.Context, req *customv1.PreviewCustomServerRequest) (*customv1.PreviewCustomServerResponse, error) {
	if err := c.srv.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	// This is a pure preview of user-supplied input. It never resolves a vault
	// reference and cancelling the dialog leaves no imported secrets behind.
	result, err := (parser.LinkParser{MaxItems: 2}).Parse([]byte(req.GetLink()))
	if err == nil && (len(result.Servers) != 1 || result.Report.Invalid > 0 || result.Report.Unsupported > 0) {
		err = parser.ErrInvalid
	}
	if err != nil {
		return &customv1.PreviewCustomServerResponse{Error: toWire(importError(err), nil, "")}, nil
	}
	spec := result.Servers[0]
	// Password-only links carry the token in user info, whereas username and
	// password protocols keep those fields separate.
	if (spec.Protocol == "trojan" || spec.Protocol == "hysteria2") && spec.Password == "" {
		spec.Password = spec.User
	}
	if err := custom.ValidateProtocol(custom.Protocol(spec.Protocol)); err != nil {
		return &customv1.PreviewCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	document, err := credentialDocument(spec)
	if err != nil {
		return &customv1.PreviewCustomServerResponse{Error: toWire(err, nil, "")}, nil
	}
	name := spec.DisplayName
	if name == "" {
		name = spec.Host
	}
	return &customv1.PreviewCustomServerResponse{
		Server: &customv1.CustomServer{Name: name, Protocol: customProtocolToWire(custom.Protocol(spec.Protocol)),
			ProtocolName: spec.Protocol, Address: spec.Host, Port: uint32(spec.Port), Transport: spec.Transport, Security: spec.Security},
		CredentialDocument: string(document),
	}, nil
}
