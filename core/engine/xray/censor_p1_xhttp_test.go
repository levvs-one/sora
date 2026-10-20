package xray

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

func xhttpPlan(t *testing.T) *engine.Plan {
	t.Helper()
	p := enginetest.Plan(engine.ProtocolVLESS)
	o := &p.Outbounds[0]
	o.Flow = "" // XHTTP cannot carry Vision; REALITY stays
	o.Transport = engine.Transport{
		Type: "xhttp", Mode: "stream-up", Path: "/xh",
		XmuxMaxConcurrency: 16, XmuxMaxReuseTimes: 10,
		XPaddingBytes: "100-1000",
	}
	return p
}

// TestCensorP1RenderXHTTPTuning pins the Xray leg of the XHTTP
// parity fix: xmux and xPaddingBytes reach xhttpSettings with the
// plan's exact values, and an untuned plan renders neither key.
func TestCensorP1RenderXHTTPTuning(t *testing.T) {
	raw, err := Render(xhttpPlan(t), testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		`"xmux":{"cMaxReuseTimes":10,"maxConcurrency":16}`,
		`"xPaddingBytes":"100-1000"`,
		`"mode":"stream-up"`,
	} {
		if !strings.Contains(string(raw), want) {
			t.Errorf("render lacks %s:\n%s", want, raw)
		}
	}
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Flow = "" // XHTTP cannot carry Vision; REALITY stays
	p.Outbounds[0].Transport = engine.Transport{Type: "xhttp", Mode: "stream-up", Path: "/xh"}
	raw, err = Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, absent := range []string{"xmux", "xPaddingBytes"} {
		if strings.Contains(string(raw), absent) {
			t.Errorf("an untuned plan must render no %s:\n%s", absent, raw)
		}
	}
	if !strings.Contains(string(raw), `"mode":"stream-up"`) {
		t.Errorf("explicit mode must pass through:\n%s", raw)
	}
	p.Outbounds[0].Transport.Mode = ""
	raw, err = Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(raw), `"mode":"`+engine.DefaultXHTTPMode+`"`) {
		t.Errorf("unset mode must render the shared default:\n%s", raw)
	}
}

// TestCensorP1RenderDeterministic pins field-order determinism for
// the XHTTP+REALITY surface (мелочи): two renders of one plan are
// byte-identical.
func TestCensorP1RenderDeterministic(t *testing.T) {
	p := xhttpPlan(t)
	a, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	b, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(a, b) {
		t.Fatal("two renders of one plan differ")
	}
}

// TestCensorP1BinaryAcceptsXHTTPTuning verifies the rendered xmux
// and xPaddingBytes against the pinned Xray binary itself.
func TestCensorP1BinaryAcceptsXHTTPTuning(t *testing.T) {
	bin := os.Getenv("SORA_XRAY_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_XRAY_BIN to check the render with xray")
		}
		bin = filepath.Join(dir, "xray")
	}
	raw, err := Render(xhttpPlan(t), testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	cfg := filepath.Join(t.TempDir(), "config.json")
	if err := os.WriteFile(cfg, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	if out, err := exec.CommandContext(t.Context(), bin, "run", "-test", "-c", cfg).CombinedOutput(); err != nil {
		t.Fatalf("xray refused the xmux/xPaddingBytes render: %v\n%s", err, out)
	}
}
