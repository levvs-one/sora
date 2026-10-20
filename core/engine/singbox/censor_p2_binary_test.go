package singbox

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// TestBinaryAcceptsCensorP2Transports is the runtime probe behind the
// CENSOR-P2 sing-box claims: the rendered WS header set with the
// early-data header name and the HTTPUpgrade headers must be accepted
// by the actual pinned binary (`sing-box check` rejects unknown keys),
// not merely assumed from the pin's documentation.
func TestBinaryAcceptsCensorP2Transports(t *testing.T) {
	bin := os.Getenv("SORA_SINGBOX_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_SINGBOX_BIN to check the render with sing-box")
		}
		bin = filepath.Join(dir, "sing-box")
	}
	p := enginetest.Plan(engine.ProtocolVMess, engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "ws", Path: "/ws", Host: "cdn.example.com",
		Headers:             map[string]string{"User-Agent": "Mozilla/5.0"},
		EarlyData:           2048,
		EarlyDataHeaderName: "Sec-WebSocket-Protocol",
	}
	p.Outbounds[1].Transport = engine.Transport{
		Type: "httpupgrade", Path: "/up", Host: "cdn.example.com",
		Headers: map[string]string{"User-Agent": "Mozilla/5.0"},
	}
	raw, err := Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	cfg := filepath.Join(t.TempDir(), "config.json")
	if err := os.WriteFile(cfg, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	cmd := exec.CommandContext(t.Context(), bin, "check", "-c", cfg)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("sing-box refused the CENSOR-P2 render: %v\n%s\n--- render ---\n%s", err, out, raw)
	}
}
