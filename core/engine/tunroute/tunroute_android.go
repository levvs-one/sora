package tunroute

import (
	"context"

	"github.com/levvs-one/sora-client/core/engine"
)

// Android routes through the VpnService that owns the adapter.
func route(context.Context, engine.Tun, int) error { return nil }

func unroute(context.Context) error { return nil }

func cleanup(context.Context, engine.Tun) error { return nil }
