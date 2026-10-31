package supervise

import (
	"context"
	"os"

	"github.com/levvs-one/sora-client/core/engine"
)

// TunSource supplies an adapter the platform owns, for systems where an engine
// cannot create one. Android's VpnService does this; it stays nil elsewhere.
var TunSource func(context.Context, engine.Tun) (*os.File, error)

// TunRelease tells the platform the session no longer needs the adapter.
var TunRelease func(context.Context) error

// tunChildFD is the descriptor the adapter gets in an engine: the first
// inherited file after stdin, stdout and stderr.
const tunChildFD = 3

// TunEnvironment is implemented by drivers that learn the adapter's descriptor
// from the environment rather than from their configuration.
type TunEnvironment interface {
	TunEnv(rt Runtime) []string
}
