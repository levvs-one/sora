package control_test

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// TestNativeDiagnosticsRequireAuthenticationAndTheOwnedSession locks the raw
// capture formats (SORA-H3): packet payloads and event logs cannot be redacted
// to the archive's guarantee, so the core refuses to produce them for any
// caller, authenticated or not.
func TestNativeDiagnosticsRequireAuthenticationAndTheOwnedSession(t *testing.T) {
	server, _ := newTestServer(t)
	for _, format := range []corev1.DiagnosticFormat{
		corev1.DiagnosticFormat_DIAGNOSTIC_FORMAT_PCAPNG,
		corev1.DiagnosticFormat_DIAGNOSTIC_FORMAT_EVTX,
		corev1.DiagnosticFormat(999),
	} {
		// Unauthenticated callers are refused before the format is examined.
		_, err := server.ExportDiagnostics(context.Background(), &corev1.ExportDiagnosticsRequest{ApiVersion: clientVersion(), Format: format})
		if status.Code(err) != codes.Unauthenticated {
			t.Fatalf("raw format %v without a token: expected Unauthenticated, got %v", format, err)
		}
		// Authenticated callers are refused the raw format itself:
		// the format is gone, not gated.
		answer, err := server.ExportDiagnostics(context.Background(), &corev1.ExportDiagnosticsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken, Format: format})
		if err != nil {
			t.Fatalf("raw format %v (authenticated): unexpected transport error: %v", format, err)
		}
		if answer.GetError().GetCode() != corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT || len(answer.GetArchive()) != 0 {
			t.Fatalf("raw format %v (authenticated): expected INVALID_ARGUMENT and no archive, got %v", format, answer)
		}
	}
}
