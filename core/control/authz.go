package control

import (
	"context"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/ipc"
)

// readOnlyMethods lists RPCs an AuthRead peer may call: version negotiation,
// status, statistics, events, and log inspection. Every other RPC mutates
// state, touches secrets or subscriptions, or exposes private data, and
// requires AuthControl (SORA-H2).
var readOnlyMethods = map[string]bool{
	corev1.CoreControl_Handshake_FullMethodName:         true,
	corev1.CoreControl_GetAbout_FullMethodName:          true,
	corev1.CoreControl_GetRoutingPresets_FullMethodName: true,
	corev1.CoreControl_GetStatus_FullMethodName:         true,
	corev1.CoreControl_GetStats_FullMethodName:         true,
	corev1.CoreControl_WatchEvents_FullMethodName:       true,
	corev1.CoreControl_QueryLogs_FullMethodName:         true,
	corev1.CoreControl_WatchLogs_FullMethodName:         true,
	corev1.CoreControl_GetLogSettings_FullMethodName:    true,
}

// peerLevel extracts the transport-verified privilege of the caller. Peers
// without peer credentials (never admitted by the ipc listener) report
// AuthNone and fail every method check.
func peerLevel(ctx context.Context) ipc.AuthLevel {
	return ipc.PeerLevelOf(ctx)
}

// checkMethodAuth rejects RPCs the peer's privilege level does not cover.
// Unknown methods default to control-only: fail closed.
func checkMethodAuth(ctx context.Context, fullMethod string) error {
	if readOnlyMethods[fullMethod] {
		if peerLevel(ctx) == ipc.AuthNone {
			return errs.Newf(errs.CodeUnauthenticated, errs.KeyUnauthenticated,
				"control: the peer is not admitted")
		}
		return nil
	}
	if peerLevel(ctx) != ipc.AuthControl {
		return errs.Newf(errs.CodePermissionDenied, errs.KeyPermissionDenied,
			"control: the method requires control authorization")
	}
	return nil
}

// UnaryAuthInterceptor enforces per-method authorization on unary RPCs.
// Register it on the gRPC server together with the ipc peer credentials.
func (s *Server) UnaryAuthInterceptor() grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
		if err := checkMethodAuth(ctx, info.FullMethod); err != nil {
			return nil, transportStatus(err)
		}
		return handler(ctx, req)
	}
}

// StreamAuthInterceptor enforces per-method authorization on streaming RPCs.
func (s *Server) StreamAuthInterceptor() grpc.StreamServerInterceptor {
	return func(srv any, stream grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
		if err := checkMethodAuth(stream.Context(), info.FullMethod); err != nil {
			return transportStatus(err)
		}
		return handler(srv, stream)
	}
}
