package control

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"sync"
	"testing"
	"testing/synctest"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/parser"
)

func TestSharedImportAdmissionCancelsWaiterWithoutPersisting(t *testing.T) {
	for _, deadline := range []bool{false, true} {
		name := "cancel"
		if deadline {
			name = "deadline"
		}
		t.Run(name, func(t *testing.T) {
			synctest.Test(t, func(t *testing.T) {
				provider := &panel{body: servers("retained")}
				srv, store := bookServer(t, t.TempDir(), provider)
				saved := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://admission.example/sub/fixture"})
				id := saved.GetSettings().GetId()
				retained := map[string][]byte{}
				for _, ref := range store.Refs() {
					raw, err := store.Get(ref)
					if err != nil {
						t.Fatal(err)
					}
					retained[ref] = bytes.Clone(raw)
				}
				provider.set(servers("replacement"), nil)
				payload := []byte(servers("admission"))
				// Both parse failures and reference failures must release admission.
				for range 4 {
					if _, err := srv.parsePayload(context.Background(), []byte("not a subscription"), referenceOf); err == nil {
						t.Fatal("invalid payload accepted")
					}
					if _, err := srv.parsePayload(context.Background(), payload, func(parser.OutboundSpec) (string, error) {
						return "", errors.New("test reference failure")
					}); err == nil {
						t.Fatal("reference failure accepted")
					}
				}
				release, stopHolding := context.WithCancel(context.Background())
				parsing, cancelParsing := context.WithTimeout(context.Background(), 5*time.Second)
				var workers sync.WaitGroup
				defer func() {
					cancelParsing()
					stopHolding()
					workers.Wait()
				}()
				entered := make(chan struct{}, 4)
				failures := make(chan error, 4)
				for range 4 {
					workers.Go(func() {
						_, err := srv.parsePayload(parsing, payload, func(spec parser.OutboundSpec) (string, error) {
							entered <- struct{}{}
							<-release.Done()
							return referenceOf(spec)
						})
						failures <- err
					})
				}
				// Hold the existing reference callback after real parsing, without
				// a timing-dependent large payload or a replacement parser.
				synctest.Wait()
				if count := len(entered); count != 4 {
					t.Fatalf("active imports = %d, want four", count)
				}
				ctx, cancel := context.WithCancel(parsing)
				if deadline {
					cancel()
					ctx, cancel = context.WithTimeout(parsing, time.Second)
				}
				defer cancel()
				finished := make(chan error, 1)
				go func() {
					response, err := srv.ParseImport(ctx, &corev1.ParseImportRequest{
						ApiVersion: srv.apiVersion(), Payload: payload,
					})
					if response != nil {
						err = fmt.Errorf("returned a response with %d outbounds", len(response.GetSessionPlan().GetOutbounds()))
					}
					finished <- err
				}()
				refreshed := make(chan error, 1)
				go func() {
					_, err := srv.subs.refresh(ctx, id)
					refreshed <- err
				}()
				synctest.Wait()
				refreshEarly := false
				select {
				case err := <-refreshed:
					refreshEarly = true
					t.Errorf("refresh completed while four imports were active: %v", err)
				default:
				}
				early := false
				select {
				case err := <-finished:
					early = true
					t.Errorf("fifth import completed while four imports were active: %v", err)
				default:
				}
				want := codes.Canceled
				if deadline {
					want = codes.DeadlineExceeded
					time.Sleep(time.Second)
				} else {
					cancel()
				}
				synctest.Wait()
				if !early {
					if err := <-finished; status.Code(err) != want {
						t.Errorf("waiting import error = %v, want %v", err, want)
					}
				}
				if !refreshEarly {
					if err := <-refreshed; !errors.Is(err, ctx.Err()) {
						t.Errorf("waiting refresh error = %v, want %v", err, ctx.Err())
					}
				}
				if srv.subs.list()[0].GetUpdating() {
					t.Error("cancelled waiting refresh kept Updating")
				}
				if count := len(store.Refs()); count != len(retained) {
					t.Errorf("waiting work changed vault reference count: %d, want %d", count, len(retained))
				}
				for ref, before := range retained {
					after, err := store.Get(ref)
					if err != nil || !bytes.Equal(before, after) {
						t.Errorf("waiting work changed retained vault value %s", ref)
					}
				}
				stopHolding()
				workers.Wait()
				for range 4 {
					if err := <-failures; err != nil {
						t.Errorf("admitted parse failed: %v", err)
					}
				}
				response, err := srv.ParseImport(context.Background(), &corev1.ParseImportRequest{
					ApiVersion: srv.apiVersion(), Payload: payload,
				})
				if err != nil || response.GetError() != nil || len(response.GetSessionPlan().GetOutbounds()) != 1 {
					t.Fatalf("subsequent valid import failed: response=%v err=%v", response.GetError(), err)
				}
			})
		})
	}
}
