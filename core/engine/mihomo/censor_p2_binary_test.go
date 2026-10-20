package mihomo

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// TestBinaryAcceptsCensorP2Transports is the runtime probe behind the
// CENSOR-P2 mihomo claims: the WS early-data header name and the gRPC
// user agent must be accepted by the actual pinned binary
// (`mihomo -t`), not merely assumed from the pin's documentation.
// Mihomo's loader ignores unknown YAML keys, so this test pins the
// positive spellings; the negative side (authority/multi-mode) is the
// renderer refusal in censor_p2_test.go.
func TestBinaryAcceptsCensorP2Transports(t *testing.T) {
	bin := os.Getenv("SORA_MIHOMO_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_MIHOMO_BIN to check the render with mihomo")
		}
		bin = filepath.Join(dir, "mihomo")
	}
	p := enginetest.Plan(engine.ProtocolVMess, engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "ws", Path: "/ws", Host: "cdn.example.com",
		Headers:             map[string]string{"User-Agent": "Mozilla/5.0"},
		EarlyData:           2048,
		EarlyDataHeaderName: "Sec-WebSocket-Protocol",
	}
	p.Outbounds[1].Transport = engine.Transport{Type: "grpc", Service: "tun", GRPCUserAgent: "ua/1.0"}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	home := t.TempDir()
	if dir := os.Getenv("SORA_ENGINES_DIR"); dir != "" {
		for _, name := range []string{"geoip.dat", "geosite.dat"} {
			raw, err := os.ReadFile(filepath.Join(dir, name))
			if err != nil {
				t.Fatal(err)
			}
			if err := os.WriteFile(filepath.Join(home, name), raw, 0o644); err != nil {
				t.Fatal(err)
			}
		}
	}
	cmd := exec.CommandContext(t.Context(), bin, "-d", home, "-f", "-", "-t")
	cmd.Stdin = strings.NewReader(out)
	if msg, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("mihomo refused the CENSOR-P2 render: %v\n%s\n--- render ---\n%s", err, msg, out)
	}
}
