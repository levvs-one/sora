package control_test

import (
	"bytes"
	"context"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestCancelledImportDoesNotPersistCredentials(t *testing.T) {
	for _, expired := range []bool{false, true} {
		name, want := "cancelled", codes.Canceled
		if expired {
			name, want = "expired", codes.DeadlineExceeded
		}
		t.Run(name, func(t *testing.T) {
			server, store := newTestServer(t)
			const retained = "existing-fixture"
			material := []byte(`{"password":"retained-fixture-value"}`)
			if err := store.Put(retained, material); err != nil {
				t.Fatal(err)
			}
			var ctx context.Context
			var cancel context.CancelFunc
			if expired {
				ctx, cancel = context.WithDeadline(context.Background(), time.Now().Add(-time.Second))
			} else {
				ctx, cancel = context.WithCancel(context.Background())
				cancel()
			}
			defer cancel()
			req := &corev1.ParseImportRequest{
				ApiVersion: clientVersion(),
				Payload:    []byte("vless://11111111-1111-4111-8111-111111111111@a.example:443"),
			}
			response, err := server.ParseImport(ctx, req)
			if status.Code(err) != want || response != nil {
				t.Errorf("cancelled request returned a result: code=%s, response=%v", status.Code(err), response != nil)
			}
			if refs := store.Refs(); len(refs) != 1 || refs[0] != retained {
				t.Errorf("cancelled import persisted credentials: references=%d", len(refs))
			}
			got, err := store.Get(retained)
			if err != nil || !bytes.Equal(got, material) {
				t.Fatal("existing credential changed")
			}
			response, err = server.ParseImport(context.Background(), req)
			if err != nil || response.GetError() != nil || len(response.GetSessionPlan().GetOutbounds()) != 1 || len(store.Refs()) != 2 {
				t.Fatalf("subsequent valid import failed: error=%v", err)
			}
		})
	}
}
