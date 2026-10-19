package singbox

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func ssPluginOutbound(t *testing.T, cfg map[string]any) map[string]any {
	t.Helper()
	for _, ob := range cfg["outbounds"].([]any) {
		m := ob.(map[string]any)
		if m["type"] == "shadowsocks" {
			return m
		}
	}
	t.Fatal("no shadowsocks outbound rendered")
	return nil
}

// TestRenderShadowsocksPlugin: an explicit SIP002 plugin renders verbatim
// and wins over the legacy obfs-local mapping; the legacy path must not
// emit an empty obfs-host anymore.
func TestRenderShadowsocksPlugin(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolShadowsocks)
	p.Outbounds[0].Plugin = "v2ray-plugin"
	p.Outbounds[0].PluginOpts = "tls;host=example.com"
	p.Outbounds[0].Obfs = "tls"
	ob := ssPluginOutbound(t, render(t, p))
	if ob["plugin"] != "v2ray-plugin" || ob["plugin_opts"] != "tls;host=example.com" {
		t.Fatalf("plugin must render verbatim, got %v", ob)
	}

	p = enginetest.Plan(engine.ProtocolShadowsocks)
	p.Outbounds[0].Obfs = "tls"
	ob = ssPluginOutbound(t, render(t, p))
	if ob["plugin"] != "obfs-local" || ob["plugin_opts"] != "obfs=tls" {
		t.Fatalf("legacy obfs must not emit an empty obfs-host, got %v", ob)
	}

	p = enginetest.Plan(engine.ProtocolShadowsocks)
	p.Outbounds[0].Obfs = "http"
	p.Outbounds[0].ObfsParam = "example.com"
	ob = ssPluginOutbound(t, render(t, p))
	if ob["plugin_opts"] != "obfs=http;obfs-host=example.com" {
		t.Fatalf("obfs-host must survive when set, got %v", ob)
	}
}
