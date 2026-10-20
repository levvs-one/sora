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

// TestBinaryAcceptsXHTTPDownloadSettings is the `mihomo -t` verification
// the catalog's mihomo entry waited for (PASS3 deep A1): a split XHTTP
// plan renders download-settings with a reuse-settings leg and tuned
// reuse-settings on the uplink, and the pinned mihomo binary must accept
// the rendered shapes as-is. It gates the FeatureXHTTPDownloadSplit and
// FeatureXHTTPXmux claims for mihomo in the catalog: if a future mihomo
// renames or drops these fields, this test fails before the claims can
// silently route plans into a config the engine refuses.
//
// The plan also sets XPaddingBytes, and the render string is asserted
// below — but `mihomo -t` silently ignores unknown keys, so neither
// proves the pin HONOURS x-padding-bytes. That proof is traffic-level:
// interop.TestMihomoXHTTPPaddingOnTheWire captures the client→server
// bytes of a live session and shows the filler run tracking the
// rendered range (CENSOR-P1 review Low item).
func TestBinaryAcceptsXHTTPDownloadSettings(t *testing.T) {
	bin := os.Getenv("SORA_MIHOMO_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_MIHOMO_BIN to check the render with mihomo")
		}
		bin = filepath.Join(dir, "mihomo")
	}
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Flow = ""
	p.Outbounds[0].Transport = engine.Transport{
		Type: "xhttp", Path: "/x", Host: "cdn.example.com", Mode: "stream-up",
		DownloadAddress: "dl.example.com", DownloadPort: 8443,
		XmuxMaxConnections: 8, XmuxMaxReuseTimes: 64,
		XPaddingBytes: "100-1000",
	}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"download-settings:", "reuse-settings:", "c-max-reuse-times: \"64\"", "x-padding-bytes: 100-1000"} {
		if !strings.Contains(out, want) {
			t.Fatalf("render is missing %q:\n%s", want, out)
		}
	}
	home := t.TempDir()
	// The render carries GEOIP/GEOSITE rules; production runs mihomo with
	// the shipped geo databases in its home, so seed the test home from
	// the engines dir instead of letting -t try to download them.
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
		t.Fatalf("mihomo refused the split XHTTP render: %v\n%s\n--- render ---\n%s", err, msg, out)
	}
}
