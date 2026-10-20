package mihomo

import (
	"reflect"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// CENSOR-P4: mihomo plugin names must be translated to the spellings
// mihomo's adapter actually matches. Before the fix, an imported
// SIP002 "obfs-local" reached mihomo verbatim and was silently
// ignored (the adapter knows "obfs"), so the plan ran unobfuscated.
func TestBuildProxyPluginNameTranslation(t *testing.T) {
	for _, tc := range []struct {
		plugin, opts, wantName string
	}{
		{"obfs-local", "obfs=tls;obfs-host=example.com", "obfs"},
		{"v2ray-plugin", "tls;host=example.com", "v2ray-plugin"},
		{"gost-plugin", "host=example.com", "gost-plugin"},
		{"shadow-tls", "host=example.com;password=pw", "shadow-tls"},
		{"restls-plugin", "host=example.com;password=pw", "restls"},
		{"jls-plugin", "host=example.com;username=u;password=p", "jls"},
		{"kcptun", "key=k", "kcptun"},
	} {
		o := ssTestOutbound()
		o.Plugin, o.PluginOpts = tc.plugin, tc.opts
		px, err := buildProxy(o, engine.MuxOptions{})
		if err != nil {
			t.Fatalf("%s: %v", tc.plugin, err)
		}
		if px.SSPlugin != tc.wantName {
			t.Errorf("plugin %s rendered as %q, want mihomo name %q", tc.plugin, px.SSPlugin, tc.wantName)
		}
	}
	// Unknown or non-mihomo plugins fail closed at render.
	o := ssTestOutbound()
	o.Plugin = "nosuch-plugin"
	if _, err := buildProxy(o, engine.MuxOptions{}); err == nil || !strings.Contains(err.Error(), "does not implement") {
		t.Fatalf("unknown plugin must fail closed, got %v", err)
	}
	// A method mihomo dropped fails closed at render.
	o = ssTestOutbound()
	o.Cipher = "2022-blake3-chacha12-poly1305"
	if _, err := buildProxy(o, engine.MuxOptions{}); err == nil || !strings.Contains(err.Error(), "does not implement") {
		t.Fatalf("chacha12-2022 must fail closed on mihomo, got %v", err)
	}
}

// gost-plugin options get the websocket shape its mihomo adapter
// requires (mode is mandatory there), like v2ray-plugin's.
func TestSSPluginOptsGostShape(t *testing.T) {
	got := ssPluginOpts("gost-plugin", "tls;host=example.com")
	want := map[string]any{"mode": "websocket", "tls": true, "host": "example.com"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("ssPluginOpts(gost-plugin) = %v, want %v", got, want)
	}
}
