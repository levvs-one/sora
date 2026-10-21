package olcwrap

import (
	"strings"
	"testing"
)

// FuzzValidateAndRender drives the sidecar config surface with fuzzed
// fields: validation must refuse bad shapes with an error, and any
// config it accepts must render to YAML without panicking. The rendered
// key material must never appear in the config's dedup Key in clear.
func FuzzValidateAndRender(f *testing.F) {
	f.Add("wbstream", "datachannel", "room-01", "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", "1.1.1.1:53", "fps=60")
	f.Add("jitsi", "vp8channel", "https://meet.jit.si/room", "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", "", "")
	f.Add("none", "seichannel", "r", "zz", "host", "a=b&c")
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
		if key != "" && strings.Contains(cfg.Key(), key) {
			t.Fatal("dedup Key leaks the tunnel key in clear")
		}
		if err := ValidateConnect(cfg); err != nil {
			return
		}
		if _, err := RenderYAML(cfg, Listener{Port: 1080, User: "u", Pass: "p"}); err != nil {
			t.Fatalf("validated config failed to render: %v", err)
		}
	})
}
