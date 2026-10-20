package singbox

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// TestCensorP1RenderKeyShare pins the sing-box leg of the plan's
// REALITY key-share knob: tls.reality.key_share carries the plan
// value verbatim, and an unset knob renders nothing (the engine
// default must stay the engine's, not a sora invention).
func TestCensorP1RenderKeyShare(t *testing.T) {
	for _, ks := range []string{"hybrid", "classical"} {
		p := enginetest.Plan(engine.ProtocolVLESS)
		p.Outbounds[0].TLS.KeyShare = ks
		raw, err := Render(p, testRuntime)
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(raw), `"key_share":"`+ks+`"`) {
			t.Fatalf("KeyShare %q must render as tls.reality.key_share:\n%s", ks, raw)
		}
	}
	p := enginetest.Plan(engine.ProtocolVLESS)
	raw, err := Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), "key_share") {
		t.Fatalf("an unset KeyShare must render no key_share key:\n%s", raw)
	}
}

// TestCensorP1BinaryAcceptsKeyShareRender is the `sing-box check`
// verification behind the sing-box KeyShare claim (CENSOR-P1): the
// pinned lx binary must accept the rendered key_share shape as-is.
// Its wire-level effect (classical drops the hybrid group) is pinned
// by the fingerprint-policy captures, not here.
func TestCensorP1BinaryAcceptsKeyShareRender(t *testing.T) {
	bin := os.Getenv("SORA_SINGBOX_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_SINGBOX_BIN to check the render with sing-box")
		}
		bin = filepath.Join(dir, "sing-box")
	}
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].TLS.KeyShare = "hybrid"
	raw, err := Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	cfg := filepath.Join(t.TempDir(), "config.json")
	if err := os.WriteFile(cfg, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	if out, err := exec.CommandContext(t.Context(), bin, "check", "-c", cfg).CombinedOutput(); err != nil {
		t.Fatalf("sing-box refused the key_share render: %v\n%s", err, out)
	}
}
