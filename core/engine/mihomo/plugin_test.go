package mihomo

import (
	"reflect"
	"strings"
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
		{"empty opts", "v2ray-plugin", "",
			map[string]any{"mode": "websocket"}},
		{"kcptun ints are typed", "kcptun", "key=k;mtu=1400;nocomp",
			map[string]any{"key": "k", "mtu": 1400, "nocomp": true}},
		{"shadow-tls version is typed", "shadow-tls", "host=example.com;password=pw;version=3",
			map[string]any{"host": "example.com", "password": "pw", "version": 3}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := ssPluginOpts(tc.plugin, tc.opts)
			if err != nil {
				t.Fatalf("ssPluginOpts(%q, %q): %v", tc.plugin, tc.opts, err)
			}
			if !reflect.DeepEqual(got, tc.want) {
				t.Errorf("ssPluginOpts(%q, %q) = %v, want %v", tc.plugin, tc.opts, got, tc.want)
			}
		})
	}
}

// CENSOR-P4 fix M3: an option with no mihomo spelling — or a key the
// catalog does not know at all — must fail the render closed with
// the option named, never pass through into a map mihomo's decode
// would silently ignore.
func TestSSPluginOptsUnrenderableFailsClosed(t *testing.T) {
	for _, tc := range []struct {
		name, plugin, opts, want string
	}{
		{"obfs-uri has no mihomo field", "obfs-local", "obfs=tls;obfs-uri=/x", "obfs-uri"},
		{"fast-open has no mihomo field", "obfs-local", "obfs=tls;fast-open", "fast-open"},
		{"unknown key", "v2ray-plugin", "bogus=1", "bogus"},
		{"v2ray cert is binary-only", "v2ray-plugin", "cert=/tmp/c.pem", "cert"},
		{"unknown plugin", "my-plugin", "foo=bar", "my-plugin"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got, err := ssPluginOpts(tc.plugin, tc.opts)
			if err == nil {
				t.Fatalf("ssPluginOpts(%q, %q) = %v, want error naming %q", tc.plugin, tc.opts, got, tc.want)
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("error %v must name %q", err, tc.want)
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
