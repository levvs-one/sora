package singbox

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// TestBinaryAcceptsHy2HoppingAndTUICTuning is the `sing-box check`
// verification behind the CENSOR-P3 hop-port fix: the plan's
// share-link hop spelling ("20000-30000,40000") used to reach
// server_ports verbatim and the pinned binary rejects it ("bad port
// range: 20000-30000"), so every hopping plan was unstartable on
// sing-box while unit tests only asserted the rendered JSON shape.
// The render must now be accepted as-is, together with the TUIC
// heartbeat/congestion render.
func TestBinaryAcceptsHy2HoppingAndTUICTuning(t *testing.T) {
	bin := os.Getenv("SORA_SINGBOX_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_SINGBOX_BIN to check the render with sing-box")
		}
		bin = filepath.Join(dir, "sing-box")
	}
	hy2 := enginetest.Plan(engine.ProtocolHysteria2)
	hy2.Outbounds[0].HopPorts = "20000-30000,40000"
	hy2.Outbounds[0].HopInterval = 30
	hy2.Outbounds[0].UpMbps, hy2.Outbounds[0].DownMbps = 20, 100
	tuic := enginetest.Plan(engine.ProtocolTUIC)
	tuic.Outbounds[0].CongestionControl = "cubic"
	tuic.Outbounds[0].UDPRelayMode = "quic"
	tuic.Outbounds[0].TUICHeartbeat = 25
	for name, p := range map[string]*engine.Plan{"hy2-hopping": hy2, "tuic-tuning": tuic} {
		raw, err := Render(p, testRuntime)
		if err != nil {
			t.Fatalf("%s: Render: %v", name, err)
		}
		path := filepath.Join(t.TempDir(), "config.json")
		if err := os.WriteFile(path, raw, 0o600); err != nil {
			t.Fatal(err)
		}
		cmd := exec.CommandContext(t.Context(), bin, "check", "-c", path)
		if msg, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("%s: sing-box refused the render: %v\n%s\n--- render ---\n%s", name, err, msg, raw)
		}
	}
}
