package mihomo

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// CENSOR-P4 fix M3, render backstop: a plan that reaches the mihomo
// renderer directly (bypassing selection) with an option mihomo
// cannot spell must fail the render with the option named — the
// pre-fix renderer translated through a per-plugin switch and
// silently dropped obfs-uri / fast-open, and passed unknown keys
// through into a map mihomo's decode ignores.
func TestBuildProxyPluginOptionWithoutMihomoSpellingFails(t *testing.T) {
	for _, tc := range []struct{ plugin, opts, want string }{
		{"obfs-local", "obfs=tls;obfs-uri=/x", "obfs-uri"},
		{"obfs-local", "obfs=tls;fast-open", "fast-open"},
		{"v2ray-plugin", "host=example.com;bogus=1", "bogus"},
	} {
		o := ssTestOutbound()
		o.Plugin, o.PluginOpts = tc.plugin, tc.opts
		if _, err := buildProxy(o, engine.MuxOptions{}); err == nil || !strings.Contains(err.Error(), tc.want) {
			t.Fatalf("%s opts %q: buildProxy err = %v, want refusal naming %q", tc.plugin, tc.opts, err, tc.want)
		}
	}
	// And the carried set still renders fully.
	o := ssTestOutbound()
	o.Plugin, o.PluginOpts = "obfs-local", "obfs=tls;obfs-host=example.com"
	px, err := buildProxy(o, engine.MuxOptions{})
	if err != nil {
		t.Fatalf("carried obfs options must render: %v", err)
	}
	if px.SSPlugin != "obfs" || px.SSPluginOpts["mode"] != "tls" || px.SSPluginOpts["host"] != "example.com" {
		t.Fatalf("rendered plugin = %q opts = %v", px.SSPlugin, px.SSPluginOpts)
	}
}
