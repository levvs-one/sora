package olcwrap

import (
	"errors"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
)

// FuzzValidateAndRender drives the sidecar config surface with fuzzed
// fields: validation must refuse bad shapes with an error, and any
// config it accepts must render without panicking. Rendering may still
// refuse a validated config with exactly one typed error — the
// non-decimal transport parameter (errs.KeyOlcrtcInvalid): parameter
// grammar is the parser's layer, ValidateConnect does not own it, so a
// hand-forged credential document is refused at render instead of at
// connect (wave-B finding F-4). Any other render error, or a panic, is
// a bug. The tunnel key must never appear in the dedup Key in clear.
func FuzzValidateAndRender(f *testing.F) {
	f.Add("wbstream", "datachannel", "room-01", "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", "1.1.1.1:53", "fps=60")
	f.Add("jitsi", "vp8channel", "https://meet.jit.si/room", "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", "", "")
	f.Add("none", "seichannel", "r", "zz", "host", "a=b&c")
	// Reviewer counterexamples to the first version's render invariant:
	// ValidateConnect passes, RenderYAML refuses the parameter grammar.
	f.Add("jitsi", "seichannel", "r", "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", "", "fps=abc")
	f.Add("jitsi", "videochannel", "r", "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", "", "video-w=notint")
	f.Fuzz(func(t *testing.T, provider, transport, room, key, dns, params string) {
		cfg := Config{
			Provider:  provider,
			Transport: transport,
			Room:      room,
			KeyHex:    key,
			DNS:       dns,
			Mode:      "cnc",
		}
		if params != "" {
			cfg.Params = map[string]string{}
			for _, kv := range strings.Split(params, "&") {
				k, v, _ := strings.Cut(kv, "=")
				cfg.Params[k] = v
			}
		}
		// The leak invariant only has meaning for a key long enough
		// that finding it verbatim inside the hex digest cannot be a
		// coincidence: the real PSK is 64 hex chars, so the check arms
		// at half that. (A one-character "key" appears in any digest;
		// the first version of this target fired on exactly that false
		// positive — corpus entry c423a06d891139f5, kept as regression.)
		if len(key) >= 32 && strings.Contains(cfg.Key(), key) {
			t.Fatal("dedup Key leaks the tunnel key in clear")
		}
		if err := ValidateConnect(cfg); err != nil {
			return
		}
		if _, err := RenderYAML(cfg, Listener{Port: 1080, User: "u", Pass: "p"}); err != nil {
			var typed *errs.Error
			if !errors.As(err, &typed) || typed.Key() != errs.KeyOlcrtcInvalid {
				t.Fatalf("validated config failed to render with an unexpected error: %v", err)
			}
		}
	})
}
