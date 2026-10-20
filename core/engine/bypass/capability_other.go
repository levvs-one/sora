//go:build !linux

package bypass

import (
	"context"
	"time"
)

// Off Linux there is no queue executor yet (the winws/WinDivert step
// is pending), so the probe honestly reports an incapable platform:
// the gate refuses nfqws strategies naming the pending executor, and
// tpws strategies gate on their binary alone.
func defaultProbeCapabilities(_ context.Context) Capabilities {
	return Capabilities{Platform: "unsupported", ProbedAt: time.Now()}
}
