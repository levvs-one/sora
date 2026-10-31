package main

import (
	"context"
	"log/slog"

	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/vpnhost"
)

// watchVPN makes engines use the adapter the app owns and ends the session
// when the system takes the VPN away.
func (a *App) watchVPN(ctx context.Context, host *vpnhost.Client, manager *session.Manager) {
	supervise.TunSource = host.Open
	supervise.TunRelease = host.Release
	go host.Watch(ctx, func() {
		if err := manager.Disconnect(ctx); err != nil {
			slog.Warn("the system took the VPN away, and the session did not stop", "error", err)
		}
	}, func() {
		if current := manager.Current(); current != nil {
			current.RenewNetwork(ctx)
		}
	})
}
