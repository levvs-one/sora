package xray

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// TestBinaryAcceptsCensorP2Transports is the runtime probe behind the
// CENSOR-P2 Xray claims: WS headers with the early-data header name,
// HTTPUpgrade headers and the full gRPC field set (authority,
// multiMode, user_agent) must be accepted by the actual pinned binary
// (`xray run -test`), not merely assumed from the pin's documentation.
func TestBinaryAcceptsCensorP2Transports(t *testing.T) {
	bin := os.Getenv("SORA_XRAY_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_XRAY_BIN to check the render with Xray")
		}
		bin = filepath.Join(dir, "xray")
	}
	p := enginetest.Plan(engine.ProtocolVMess, engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "ws", Path: "/ws", Host: "cdn.example.com",
		Headers:             map[string]string{"User-Agent": "Mozilla/5.0"},
		EarlyData:           2048,
		EarlyDataHeaderName: "Sec-WebSocket-Protocol",
	}
	p.Outbounds[1].Transport = engine.Transport{
		Type: "grpc", Service: "tun",
		GRPCAuthority: "auth.example.com", GRPCMultiMode: true, GRPCUserAgent: "ua/1.0",
	}
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	cfg := filepath.Join(t.TempDir(), "config.json")
	if err := os.WriteFile(cfg, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	cmd := exec.CommandContext(t.Context(), bin, "run", "-test", "-c", cfg)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("xray refused the CENSOR-P2 render: %v\n%s\n--- render ---\n%s", err, out, raw)
	}

	// HTTPUpgrade headers ride the same claim.
	p.Outbounds[1].Transport = engine.Transport{
		Type: "httpupgrade", Path: "/up", Host: "cdn.example.com",
		Headers: map[string]string{"User-Agent": "Mozilla/5.0"},
	}
	raw, err = Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(cfg, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	cmd = exec.CommandContext(t.Context(), bin, "run", "-test", "-c", cfg)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("xray refused the CENSOR-P2 httpupgrade render: %v\n%s", err, out)
	}
}
