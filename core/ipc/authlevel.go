package ipc

import (
	"context"
	"errors"
	"net"

	"google.golang.org/grpc/credentials"
	grpcpeer "google.golang.org/grpc/peer"
)

// AuthLevel is the privilege a peer holds on the control API. The transport
// admits AuthRead and AuthControl peers; method-level checks in the control
// plane decide which of the two may call a given RPC (SORA-H2).
type AuthLevel int

const (
	// AuthNone admits nothing; the connection is refused.
	AuthNone AuthLevel = iota
	// AuthRead may call read-only RPCs: status, statistics, events, logs.
	AuthRead
	// AuthControl may call the full control API.
	AuthControl
)

// String names the level for logs; it never carries peer identity.
func (l AuthLevel) String() string {
	switch l {
	case AuthRead:
		return "read"
	case AuthControl:
		return "control"
	default:
		return "none"
	}
}

// PeerAuthInfo carries the kernel-verified peer and its authorization level
// into RPC handlers via the gRPC credentials mechanism.
type PeerAuthInfo struct {
	Peer  Peer
	Level AuthLevel
}

// AuthType implements credentials.AuthInfo.
func (PeerAuthInfo) AuthType() string { return "sora-peer" }

// peerCredentials authenticates local peers at connection setup and records
// their authorization level for method-level checks. It performs no
// cryptography: identity comes from the kernel (SO_PEERCRED, pipe tokens),
// privilege from the platform policy (polkit actions, socket group).
type peerCredentials struct {
	authorize func(Peer) AuthLevel
}

// PeerCredentials returns server-side transport credentials that admit only
// authorized peers and expose their AuthLevel to handlers through
// credentials.AuthInfoFromContext. Pass DefaultAuthorize for the standard
// platform policy.
func PeerCredentials(authorize func(Peer) AuthLevel) credentials.TransportCredentials {
	if authorize == nil {
		authorize = func(Peer) AuthLevel { return AuthNone }
	}
	return peerCredentials{authorize: authorize}
}

// Info implements credentials.TransportCredentials.
func (peerCredentials) Info() credentials.ProtocolInfo {
	return credentials.ProtocolInfo{SecurityProtocol: "sora-peer", SecurityVersion: "1"}
}

// Clone implements credentials.TransportCredentials.
func (c peerCredentials) Clone() credentials.TransportCredentials { return c }

// OverrideServerName implements credentials.TransportCredentials. Local
// endpoints have no server name to verify.
func (peerCredentials) OverrideServerName(string) error { return nil }

// ClientHandshake implements credentials.TransportCredentials. These
// credentials are server-side only.
func (peerCredentials) ClientHandshake(_ context.Context, _ string, _ net.Conn) (net.Conn, credentials.AuthInfo, error) {
	return nil, nil, errors.New("ipc: sora peer credentials are server-side only")
}

// ServerHandshake implements credentials.TransportCredentials. It admits the
// peer when the platform policy grants at least read access and records the
// privilege level for the control plane's method checks.
func (c peerCredentials) ServerHandshake(rawConn net.Conn) (net.Conn, credentials.AuthInfo, error) {
	peer := peerOf(rawConn)
	level := c.authorize(peer)
	if level == AuthNone {
		return nil, nil, errors.New("ipc: the peer is not authorized")
	}
	return rawConn, PeerAuthInfo{Peer: peer, Level: level}, nil
}

// PeerLevelOf extracts the peer's authorization level from an RPC context.
// Contexts without peer credentials report AuthNone.
func PeerLevelOf(ctx context.Context) AuthLevel {
	if p, ok := grpcpeer.FromContext(ctx); ok && p != nil {
		if info, ok := p.AuthInfo.(PeerAuthInfo); ok {
			return info.Level
		}
	}
	return AuthNone
}
