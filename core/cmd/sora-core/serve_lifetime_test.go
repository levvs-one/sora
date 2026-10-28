package main

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"testing"
	"testing/synctest"

	"google.golang.org/grpc"
	"google.golang.org/grpc/test/bufconn"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/ipc"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

type serveLifetimeProvider struct {
	started chan context.Context
}

func (p *serveLifetimeProvider) Fetch(ctx context.Context, _ string, _ subscription.FetchOptions) (subscription.Result, error) {
	p.started <- ctx
	<-ctx.Done()
	return subscription.Result{}, ctx.Err()
}

func TestServeReturnCancelsOwnedSubscriptionWork(t *testing.T) {
	for _, finish := range []string{"stopped-server", "closed-listener"} {
		t.Run(finish, func(t *testing.T) {
			synctest.Test(t, func(t *testing.T) {
				ctx, cancel := context.WithCancel(t.Context())
				defer cancel()
				vault, err := secret.Open(t.TempDir(), secret.Options{Protector: secret.FileProtector{}})
				if err != nil {
					t.Fatal(err)
				}
				t.Cleanup(func() { _ = vault.Close() })
				token := make([]byte, control.TokenLen)
				auth, err := control.NewAuthenticator(token)
				if err != nil {
					t.Fatal(err)
				}
				provider := &serveLifetimeProvider{started: make(chan context.Context, 1)}
				plane, err := control.New(control.Config{
					Version: Version, Authenticator: auth, Secrets: vault, Fetcher: provider,
					Sessions: session.NewManager(session.ManagerConfig{
						Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
							return nil, errors.New("serve lifetime fixture starts no engine")
						},
					}),
				})
				if err != nil {
					t.Fatal(err)
				}
				saved, err := plane.SaveSubscription(ctx, &corev1.SaveSubscriptionRequest{
					ApiVersion:           &corev1.ApiVersion{Major: Version.Major, Minor: Version.Minor},
					ControlAuthenticator: token,
					Settings:             &corev1.SubscriptionSettings{Url: "https://panel.example/serve-lifetime"},
				})
				if err != nil || saved.GetError() != nil {
					t.Fatalf("fixture subscription was not admitted: %v %v", err, saved.GetError())
				}
				synctest.Wait()
				var fetchCtx context.Context
				select {
				case fetchCtx = <-provider.started:
				default:
					t.Fatal("positive control never entered the provider")
				}
				if fetchCtx.Err() != nil {
					t.Fatal("live fixture fetch was already cancelled")
				}
				inner := bufconn.Listen(1 << 20)
				t.Cleanup(func() { _ = inner.Close() })
				server := grpc.NewServer()
				t.Cleanup(server.Stop)
				if finish == "stopped-server" {
					server.Stop()
				} else if err := inner.Close(); err != nil {
					t.Fatal(err)
				}
				app := &App{
					log:   slog.New(slog.NewTextHandler(io.Discard, nil)),
					plane: plane, server: server,
					listener: &ipc.Listener{Listener: inner},
				}
				err = app.Serve(ctx)
				if finish == "stopped-server" && err != nil {
					t.Errorf("normal stopped server became a failure: %v", err)
				}
				if finish == "closed-listener" && err == nil {
					t.Error("unexpected listener failure was hidden")
				}
				synctest.Wait()
				if ctx.Err() != nil {
					t.Error("Serve cancelled its caller instead of its owned scope")
				}
				if fetchCtx.Err() != context.Canceled {
					t.Error("background fetch outlived Serve return with a live caller")
				}
			})
		})
	}
}
