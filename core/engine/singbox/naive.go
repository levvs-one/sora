package singbox

import (
	"context"
	"os/exec"
	"slices"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// NaiveReady checks the actual build and its library before replacing a live
// session. A build tag alone cannot establish that purego can load Cronet.
func NaiveReady(ctx context.Context, b supervise.Binary) bool {
	if !slices.Contains(b.BuildTags, "with_naive_outbound") {
		return false
	}
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, b.Path, "check", "-c", "stdin", "--disable-color") //nolint:gosec // engine discovery already verified this executable
	supervise.HideWindow(cmd)
	cmd.Env = supervise.SafeEnv()
	cmd.Stdin = strings.NewReader(`{"outbounds":[{"type":"naive","server":"127.0.0.1","server_port":443,"tls":{"enabled":true}}]}`)
	return cmd.Run() == nil
}
