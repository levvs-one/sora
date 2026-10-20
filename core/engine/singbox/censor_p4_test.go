package singbox

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// CENSOR-P4: sing-box render fails closed on the SS methods and
// plugins the pinned build refuses at load, with the plan context
// attached, instead of surfacing as a bare engine FATAL at start.
func TestRenderShadowsocksFailClosed(t *testing.T) {
	for _, tc := range []struct {
		name   string
		mutate func(*engine.Outbound)
		want   string
	}{
		{"chacha12-2022", func(o *engine.Outbound) {
			o.Cipher = "2022-blake3-chacha12-poly1305"
			o.Password = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
		}, "does not implement"},
		{"chacha8-2022", func(o *engine.Outbound) {
			o.Cipher = "2022-blake3-chacha8-poly1305"
			o.Password = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
		}, "does not implement"},
		{"gost-plugin", func(o *engine.Outbound) { o.Plugin = "gost-plugin"; o.PluginOpts = "host=example.com" }, "plugin binary sora does not ship"},
		{"alias chacha20-poly1305", func(o *engine.Outbound) { o.Cipher = "chacha20-poly1305" }, "does not implement"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			p := enginetest.Plan(engine.ProtocolShadowsocks)
			tc.mutate(&p.Outbounds[0])
			if _, err := Render(p, testRuntime); err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Render = %v, want fail-closed error containing %q", err, tc.want)
			}
		})
	}
}

// "Мелочи" §3: renders are byte-determined — the same plan renders
// byte-identically twice, and a plugin option set spelled in another
// order renders the identical plugin_opts string.
func TestRenderPluginOptsDeterministic(t *testing.T) {
	mk := func(opts string) *engine.Plan {
		p := enginetest.Plan(engine.ProtocolShadowsocks)
		p.Outbounds[0].Plugin = "v2ray-plugin"
		p.Outbounds[0].PluginOpts = opts
		return p
	}
	a, err := Render(mk("tls;host=example.com;path=/ws"), testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	b, err := Render(mk("tls;host=example.com;path=/ws"), testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	if string(a) != string(b) {
		t.Fatal("the same plan must render byte-identically twice")
	}
	c, err := Render(mk("path=/ws;host=example.com;tls"), testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	if string(a) != string(c) {
		t.Fatal("an option set spelled in another order must render byte-identically")
	}
	ob := ssPluginOutbound(t, render(t, mk("path=/ws;host=example.com;tls")))
	if ob["plugin_opts"] != "tls;host=example.com;path=/ws" {
		t.Fatalf("plugin_opts = %v, want canonical schema order", ob["plugin_opts"])
	}
}

// A zero AmneziaWG is disabled: the endpoint renders as plain
// WireGuard at the plain MTU, not as a 1280-MTU AWG endpoint.
func TestRenderWireGuardZeroAmnezia(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolWireGuard)
	p.Outbounds[0].Amnezia = &engine.AmneziaWG{}
	cfg := render(t, p)
	ep := cfg["endpoints"].([]any)[0].(map[string]any)
	if ep["mtu"] != float64(1420) {
		t.Fatalf("zero AmneziaWG must keep plain WireGuard rendering, mtu=%v", ep["mtu"])
	}
	if _, ok := ep["jc"]; ok {
		t.Fatal("zero AmneziaWG must not render AWG keys")
	}
}
