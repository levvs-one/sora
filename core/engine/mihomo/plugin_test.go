package mihomo

import (
	"reflect"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestSSPluginOpts(t *testing.T) {
	cases := []struct {
		name   string
		plugin string
		opts   string
		want   map[string]any
	}{
		{"obfs-local tls", "obfs-local", "obfs=tls;obfs-host=example.com",
			map[string]any{"mode": "tls", "host": "example.com"}},
		{"obfs-local http no host", "obfs-local", "obfs=http",
			map[string]any{"mode": "http"}},
		{"v2ray-plugin tls", "v2ray-plugin", "tls;host=example.com;path=/ws",
			map[string]any{"mode": "websocket", "tls": true, "host": "example.com", "path": "/ws"}},
		{"v2ray-plugin explicit flags", "v2ray-plugin", "tls=1;mux=false;host=h.example",
			map[string]any{"mode": "websocket", "tls": true, "mux": false, "host": "h.example"}},
		{"unknown plugin passes through", "my-plugin", "foo=bar;flag",
			map[string]any{"foo": "bar", "flag": ""}},
		{"empty opts", "v2ray-plugin", "",
			map[string]any{"mode": "websocket"}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := ssPluginOpts(tc.plugin, tc.opts); !reflect.DeepEqual(got, tc.want) {
				t.Errorf("ssPluginOpts(%q, %q) = %v, want %v", tc.plugin, tc.opts, got, tc.want)
			}
		})
	}
}

func ssTestOutbound() engine.Outbound {
	return engine.Outbound{ID: "ss1", Name: "ss", Protocol: engine.ProtocolShadowsocks,
		Server: "ss.example.com", Port: 8388, Cipher: "aes-256-gcm", Password: "secret"}
}

func TestBuildProxyShadowsocksPlugin(t *testing.T) {
	// Explicit plugin wins over the native obfs mapping.
	o := ssTestOutbound()
	o.Plugin, o.PluginOpts = "v2ray-plugin", "tls;host=example.com"
	o.Obfs, o.ObfsParam = "tls", "example.com"
	px, err := buildProxy(o, engine.MuxOptions{})
	if err != nil {
		t.Fatal(err)
	}
	if px.SSPlugin != "v2ray-plugin" {
		t.Errorf("plugin = %q, want v2ray-plugin", px.SSPlugin)
	}
	want := map[string]any{"mode": "websocket", "tls": true, "host": "example.com"}
	if !reflect.DeepEqual(px.SSPluginOpts, want) {
		t.Errorf("plugin-opts = %v, want %v", px.SSPluginOpts, want)
	}
	if px.Obfs != "" {
		t.Errorf("native obfs must stay empty when a plugin is set, got %q", px.Obfs)
	}

	// Legacy path unchanged: native simple-obfs fields.
	o = ssTestOutbound()
	o.Obfs, o.ObfsParam = "tls", "example.com"
	px, err = buildProxy(o, engine.MuxOptions{})
	if err != nil {
		t.Fatal(err)
	}
	if px.SSPlugin != "" || px.Obfs != "tls" || px.ObfsParam != "example.com" {
		t.Errorf("legacy obfs mapping broken: %+v", px)
	}

	// Neither set: no plugin keys at all.
	px, err = buildProxy(ssTestOutbound(), engine.MuxOptions{})
	if err != nil {
		t.Fatal(err)
	}
	if px.SSPlugin != "" || px.SSPluginOpts != nil || px.Obfs != "" {
		t.Errorf("plain SS must not carry plugin keys: %+v", px)
	}
}
