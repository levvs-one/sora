package singbox

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// TestBinaryAcceptsCensorP2FixH2Headers is the runtime probe behind
// the CENSOR-P2 fix h2 claim: the rendered http transport carrying the
// plan's header set must be accepted by the pinned binary (`sing-box
// check` rejects unknown keys, so acceptance proves the field). The
// same probe run rejected a headers key on the gRPC transport as an
// unknown field — the fact behind the plan-level grpc refusal.
func TestBinaryAcceptsCensorP2FixH2Headers(t *testing.T) {
	bin := os.Getenv("SORA_SINGBOX_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_SINGBOX_BIN to check the render with sing-box")
		}
		bin = filepath.Join(dir, "sing-box")
	}
	p := enginetest.Plan(engine.ProtocolVMess)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "h2", Path: "/h2", Host: "cdn.example.com",
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
		t.Fatalf("sing-box refused the h2 headers render: %v\n%s\n--- render ---\n%s", err, out, raw)
	}
}
