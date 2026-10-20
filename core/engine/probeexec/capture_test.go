package probeexec

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// TestProbeRealBinaries is the interop proof of CENSOR-FP: it runs
// the probe against the real pinned binaries in SORA_ENGINES_DIR and
// asserts the measured fact table (2026-10-20):
//
//   - ECH is REAL on all three engines: the captured outer SNI is
//     the pinned list's public_name, not the claimed SNI.
//   - The REALITY key-share knob is honoured by sing-box and mihomo
//     and does not exist on Xray (render-level refusal -> Rejected).
//   - Mihomo's unset key share offers NO hybrid by default.
//   - Xray's chrome/hellochrome_auto/hellochrome_133 all send the
//     one Chrome 133 JA4; versioned parrots are refused by sing-box.
func TestProbeRealBinaries(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("SORA_ENGINES_DIR not set: engine binaries not available")
	}
	r := Runner{Dir: dir, CaptureTimeout: 15 * time.Second}
	ctx := context.Background()
	const xrayChrome133JA4 = "t13d1516h2_8daaf6152771_d8a2da3f94cd"

	sb, err := r.Probe(ctx, engine.KindSingBox)
	if err != nil {
		t.Fatal(err)
	}
	if sb.ECH != engine.ProbeAccepted {
		t.Errorf("sing-box ECH = %v, want Accepted (notes: %v)", sb.ECH, sb.Notes)
	}
	if sb.KeyShare != engine.ProbeAccepted {
		t.Errorf("sing-box KeyShare = %v, want Accepted (notes: %v)", sb.KeyShare, sb.Notes)
	}
	// A versioned parrot on sing-box arrives only via the renderer's
	// degradation to the chrome alias: the hello comes back wearing
	// the alias's JA4, and the probe notes the substitution. (The
	// raw name IS refused by the binary at load — measured directly
	// in CENSOR-FP — so a capture wearing the 133 JA4 here would
	// mean the degradation stopped happening.)
	if sb.Fingerprints["hellochrome_133"] != engine.ProbeAccepted {
		t.Errorf("sing-box hellochrome_133 = %v, want Accepted-via-degradation", sb.Fingerprints["hellochrome_133"])
	}
	if sb.JA4["hellochrome_133"] != sb.JA4["chrome"] {
		t.Errorf("sing-box hellochrome_133 JA4 = %q, want the chrome alias's %q (degradation proof)", sb.JA4["hellochrome_133"], sb.JA4["chrome"])
	}
	degradationNoted := false
	for _, n := range sb.Notes {
		if strings.Contains(n, "renderer degradation") {
			degradationNoted = true
		}
	}
	if !degradationNoted {
		t.Errorf("sing-box probe must note the versioned-parrot degradation: %v", sb.Notes)
	}
	if sb.Fingerprints["chrome"] != engine.ProbeAccepted || !sb.PQKeyShare["chrome"] {
		t.Errorf("sing-box chrome = %v PQ=%v, want Accepted with hybrid offered", sb.Fingerprints["chrome"], sb.PQKeyShare["chrome"])
	}

	mh, err := r.Probe(ctx, engine.KindMihomo)
	if err != nil {
		t.Fatal(err)
	}
	if mh.ECH != engine.ProbeAccepted {
		t.Errorf("mihomo ECH = %v, want Accepted (notes: %v)", mh.ECH, mh.Notes)
	}
	if mh.KeyShare != engine.ProbeAccepted {
		t.Errorf("mihomo KeyShare = %v, want Accepted (notes: %v)", mh.KeyShare, mh.Notes)
	}

	xr, err := r.Probe(ctx, engine.KindXray)
	if err != nil {
		t.Fatal(err)
	}
	if xr.ECH != engine.ProbeAccepted {
		t.Errorf("xray ECH = %v, want Accepted (notes: %v)", xr.ECH, xr.Notes)
	}
	if xr.KeyShare != engine.ProbeRejected {
		t.Errorf("xray KeyShare = %v, want Rejected (no knob exists; the renderer refuses)", xr.KeyShare)
	}
	for _, name := range []string{"chrome", "hellochrome_auto", "hellochrome_133"} {
		if xr.JA4[name] != xrayChrome133JA4 {
			t.Errorf("xray %s JA4 = %q, want the measured Chrome 133 %q", name, xr.JA4[name], xrayChrome133JA4)
		}
	}
	// Every probe must carry its determinism note (мелочи §4).
	for kind, pr := range map[engine.Kind]*engine.EngineProbe{"sing-box": sb, "mihomo": mh, "xray": xr} {
		found := false
		for _, n := range pr.Notes {
			if strings.HasPrefix(n, "determinism:") {
				found = true
				if strings.Contains(n, "DIFFER") {
					t.Errorf("%s: %s", kind, n)
				}
			}
		}
		if !found {
			t.Errorf("%s: probe notes carry no determinism measurement: %v", kind, pr.Notes)
		}
	}
}

// TestProbeMissingBinary: a directory without the binary is an
// error, not a fabricated probe.
func TestProbeMissingBinary(t *testing.T) {
	r := Runner{Dir: t.TempDir()}
	if _, err := r.Probe(context.Background(), engine.KindXray); err == nil {
		t.Fatal("missing binary must error")
	}
}

// TestCaptureBoundaries (мелочи §2): SNI and ALPN at their protocol
// edges, measured per engine. The measured truth (2026-10-20):
//   - A 253-byte SNI (the DNS name maximum) reaches the wire whole
//     on all three engines — and so does a 254-byte one: the TLS
//     server_name vector is length-prefixed at 16 bits, so the DNS
//     limit is not a wire limit and no engine enforces it. The real
//     wire edge is the uint16 length itself: a >64KiB SNI cannot be
//     encoded and the pipeline must refuse it (asserted below).
//   - ALPN belongs to the parrot on xray/mihomo: with a chrome
//     fingerprint the captured list is the parrot's [h2 http/1.1]
//     whatever the plan lists (the plan's extra protocols are lost
//     — a policy fact: ALPN beyond the parrot's set needs a parrot
//     that carries it). sing-box honours the plan's list whole.
func TestCaptureBoundaries(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("SORA_ENGINES_DIR not set: engine binaries not available")
	}
	r := Runner{Dir: dir, CaptureTimeout: 15 * time.Second}
	ctx := context.Background()
	label := strings.Repeat("a", 63)
	sni253 := label + "." + label + "." + label + "." + strings.Repeat("b", 61) // 63*3+61+3 dots = 253
	if len(sni253) != 253 {
		t.Fatalf("fixture: len(sni253) = %d", len(sni253))
	}
	mk := func(sni string, alpn []string) *engine.Plan {
		p := basePlan()
		p.Outbounds = []engine.Outbound{{
			ID: "probe", Protocol: engine.ProtocolVLESS, Server: "127.0.0.1",
			UUID: "11111111-1111-1111-1111-111111111111",
			TLS:  engine.TLS{Enabled: true, ServerName: sni, Fingerprint: "chrome", ALPN: alpn},
		}}
		return p
	}
	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindMihomo, engine.KindXray} {
		for _, sni := range []string{sni253, sni253 + "c"} {
			facts, err := r.capture(ctx, kind, mk(sni, nil))
			if err != nil {
				t.Errorf("%s: %d-byte SNI must capture, got %v", kind, len(sni), err)
			} else if facts.SNI != sni {
				t.Errorf("%s: captured SNI is %d bytes, want the whole %d", kind, len(facts.SNI), len(sni))
			}
		}
		// The uint16 edge: unencodable, must fail somewhere in the
		// pipeline (validation, render or dial) — never a hello.
		huge := strings.Repeat("a", 70000) + ".example.com"
		if _, err := r.capture(ctx, kind, mk(huge, nil)); err == nil {
			t.Errorf("%s: a 70012-byte SNI produced a capture; the uint16 length edge must refuse it", kind)
		}
		longALPN := []string{"h2", "http/1.1", "h3", "hq-29", "dot", "doq", "x-custom-proto-0123456789"}
		facts, err := r.capture(ctx, kind, mk("example.com", longALPN))
		if err != nil {
			t.Errorf("%s: long ALPN list must capture, got %v", kind, err)
		} else if kind == engine.KindSingBox {
			if strings.Join(facts.ALPN, ",") != strings.Join(longALPN, ",") {
				t.Errorf("sing-box: captured ALPN = %v, want the plan's list whole", facts.ALPN)
			}
		} else if strings.Join(facts.ALPN, ",") != "h2,http/1.1" {
			t.Errorf("%s: captured ALPN = %v, want the chrome parrot's [h2 http/1.1] (parrot-owned, measured)", kind, facts.ALPN)
		}
	}
	// ECH edges at the helper level: an empty pin is "no pin", a
	// maximal-size list still decodes (the engines' own limits are
	// theirs; sora's data layer must not invent one).
	if _, err := engine.ECHConfigListBytes(nil); err != nil {
		t.Errorf("empty ECH pin must decode as no-pin, got %v", err)
	}
	big := []string{strings.Repeat("QUJD", 16384)} // 48 KiB of decoded list
	if _, err := engine.ECHConfigListBytes(big); err != nil {
		t.Errorf("large ECH pin must decode, got %v", err)
	}
}
