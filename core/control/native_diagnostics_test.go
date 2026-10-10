package control_test

import (
	"context"
	"testing"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestNativeDiagnosticsRequireAuthenticationAndTheOwnedSession(t *testing.T) {
	server, store := newTestServer(t)
	for _, format := range []corev1.DiagnosticFormat{corev1.DiagnosticFormat_DIAGNOSTIC_FORMAT_PCAPNG, corev1.DiagnosticFormat_DIAGNOSTIC_FORMAT_EVTX} {
		_, err := server.ExportDiagnostics(context.Background(), &corev1.ExportDiagnosticsRequest{ApiVersion: clientVersion(), Format: format})
		if status.Code(err) != codes.Unauthenticated {
			t.Fatalf("unauthenticated native export: %v", err)
		}
	}
	request := &corev1.ExportDiagnosticsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken, Format: corev1.DiagnosticFormat_DIAGNOSTIC_FORMAT_PCAPNG}
	answer, err := server.ExportDiagnostics(context.Background(), request)
	if err != nil || answer.GetError().GetUserMessageKey() != "core.plan.tunnel_unsupported" || len(answer.GetArchive()) != 0 {
		t.Fatalf("capture without TUN: %v, %v", answer, err)
	}
	connected, err := server.Connect(context.Background(), &corev1.ConnectRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken, SessionPlan: validPlan(t, store)})
	if err != nil || connected.GetError() != nil {
		t.Fatalf("connect: %v, %v", connected, err)
	}
	defer func() {
		_, _ = server.Disconnect(context.Background(), &corev1.DisconnectRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken})
	}()
	request.SessionId = "foreign-session"
	answer, err = server.ExportDiagnostics(context.Background(), request)
	if err != nil || answer.GetError().GetUserMessageKey() != "core.plan.tunnel_unsupported" || len(answer.GetArchive()) != 0 {
		t.Fatalf("capture of foreign session: %v, %v", answer, err)
	}
	request.Format = 999
	answer, err = server.ExportDiagnostics(context.Background(), request)
	if err != nil || answer.GetError().GetCode() != corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT {
		t.Fatalf("unknown format: %v, %v", answer, err)
	}
}
