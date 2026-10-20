package singbox

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func xhttpPlan() *engine.Plan {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Flow = "" // XHTTP cannot carry Vision; REALITY stays
	p.Outbounds[0].Transport = engine.Transport{
		Type: "xhttp", Mode: "stream-up", Path: "/xh",
		XmuxMaxConcurrency: 16, XmuxMaxReuseTimes: 10,
		XPaddingBytes: "100-1000",
	}
	return p
}

// TestCensorP1RenderXHTTPTuning pins the sing-box leg of the XHTTP
// parity fix: the lx spellings (xmux snake_case, x_padding_bytes)
// carry the plan's exact values, and an untuned plan renders
// neither key.
func TestCensorP1RenderXHTTPTuning(t *testing.T) {
	raw, err := Render(xhttpPlan(), testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		`"xmux":{"c_max_reuse_times":10,"max_concurrency":16}`,
		`"x_padding_bytes":"100-1000"`,
		`"mode":"stream-up"`,
	} {
		if !strings.Contains(string(raw), want) {
			t.Errorf("render lacks %s:\n%s", want, raw)
		}
	}
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Flow = "" // XHTTP cannot carry Vision; REALITY stays
	p.Outbounds[0].Transport = engine.Transport{Type: "xhttp", Path: "/xh"}
	raw, err = Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	for _, absent := range []string{"xmux", "x_padding_bytes"} {
		if strings.Contains(string(raw), absent) {
			t.Errorf("an untuned plan must render no %s:\n%s", absent, raw)
		}
	}
	if !strings.Contains(string(raw), `"mode":"`+engine.DefaultXHTTPMode+`"`) {
		t.Errorf("unset mode must render the shared default:\n%s", raw)
	}
}

// TestCensorP1RenderDeterministic pins field-order determinism for
// the XHTTP+REALITY surface (мелочи): two renders of one plan are
// byte-identical.
func TestCensorP1RenderDeterministic(t *testing.T) {
	p := xhttpPlan()
	a, err := Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	b, err := Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(a, b) {
		t.Fatal("two renders of one plan differ")
	}
}

// TestCensorP1BinaryAcceptsXHTTPTuning verifies the rendered xmux
// and x_padding_bytes against the pinned sing-box-lx binary itself:
// upstream spellings would be unknown fields there, so a pass is
// the probe behind the BuildCapabilities claim.
func TestCensorP1BinaryAcceptsXHTTPTuning(t *testing.T) {
	bin := os.Getenv("SORA_SINGBOX_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_SINGBOX_BIN to check the render with sing-box")
		}
		bin = filepath.Join(dir, "sing-box")
	}
	raw, err := Render(xhttpPlan(), testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	cfg := filepath.Join(t.TempDir(), "config.json")
	if err := os.WriteFile(cfg, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	if out, err := exec.CommandContext(t.Context(), bin, "check", "-c", cfg).CombinedOutput(); err != nil {
		t.Fatalf("sing-box refused the xmux/x_padding_bytes render: %v\n%s", err, out)
	}
}
