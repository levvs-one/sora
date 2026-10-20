package xray

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// CENSOR-P4: the Xray renderer must fail closed on Shadowsocks
// plugins/obfs and on methods the pin dropped, instead of emitting a
// config that loads (Xray ignores unknown keys) and runs without the
// promised obfuscation or with a substituted cipher.
func TestRenderShadowsocksFailClosed(t *testing.T) {
	for _, tc := range []struct {
		name   string
		mutate func(*engine.Outbound)
		want   string
	}{
		{"plugin", func(o *engine.Outbound) { o.Plugin = "v2ray-plugin"; o.PluginOpts = "tls;host=example.com" }, "does not implement"},
		{"obfs", func(o *engine.Outbound) { o.Obfs = "tls"; o.ObfsParam = "example.com" }, "does not implement"},
		{"aes-192", func(o *engine.Outbound) { o.Cipher = "aes-192-gcm" }, "does not implement"},
		{"stream", func(o *engine.Outbound) { o.Cipher = "aes-256-cfb" }, "does not implement"},
		{"chacha12-2022", func(o *engine.Outbound) { o.Cipher = "2022-blake3-chacha12-poly1305" }, "does not implement"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			p := enginetest.Plan(engine.ProtocolShadowsocks)
			tc.mutate(&p.Outbounds[0])
			if _, err := Render(p, testRuntime, nil); err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Render = %v, want fail-closed error containing %q", err, tc.want)
			}
		})
	}
	// A supported method still renders.
	p := enginetest.Plan(engine.ProtocolShadowsocks)
	if _, err := Render(p, testRuntime, nil); err != nil {
		t.Fatalf("plain SS render broke: %v", err)
	}
}

// A zero AmneziaWG is "disabled" (engine.AmneziaWG.IsZero): Xray must
// carry the plain WireGuard outbound instead of refusing it.
func TestRenderWireGuardZeroAmnezia(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolWireGuard)
	p.Outbounds[0].Amnezia = &engine.AmneziaWG{}
	if _, err := Render(p, testRuntime, nil); err != nil {
		t.Fatalf("zero AmneziaWG must render as plain WireGuard, got %v", err)
	}
	p.Outbounds[0].Amnezia = &engine.AmneziaWG{Jc: 4}
	if _, err := Render(p, testRuntime, nil); err == nil {
		t.Fatal("a populated AmneziaWG must still be refused by Xray")
	}
}
