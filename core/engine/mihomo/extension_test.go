package mihomo

import (
	"slices"
	"testing"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestExtensionListenerPinsProxyDespiteDirectModeAndRules(t *testing.T) {
	for _, mode := range []string{"rule", "direct", "global"} {
		p := testPlan()
		p.LocalProxy.Enabled = false
		p.Options.Mode, p.Options.AllowLAN = mode, true
		p.ExtensionProxy = &engine.ExtensionProxy{Port: 23456, Username: "private-extension-user", Password: "private-extension-password-for-session", Target: "srv-1"}
		raw, err := Render(p, testRuntime(t))
		if err != nil {
			t.Fatal(err)
		}
		var cfg struct {
			MixedPort int                 `yaml:"mixed-port"`
			Listeners []extensionListener `yaml:"listeners"`
			Rules     []string            `yaml:"rules"`
		}
		if err := yaml.Unmarshal([]byte(raw), &cfg); err != nil {
			t.Fatal(err)
		}
		if cfg.MixedPort != 0 || len(cfg.Listeners) != 2 {
			t.Fatal("private and TUN listeners must coexist without an ordinary proxy")
		}
		in := cfg.Listeners[0]
		if in.Name != engine.ExtensionInbound || in.Type != "socks" || in.Listen != "127.0.0.1" || in.Port != 23456 || in.Proxy != "Tokyo_01" ||
			len(in.Users) != 1 || in.Users[0].Username != p.ExtensionProxy.Username || in.Users[0].Password != p.ExtensionProxy.Password {
			t.Fatal("private inbound must authenticate and force the VPN proxy outside ordinary routing")
		}
		if !slices.Contains(cfg.Rules, "DOMAIN-SUFFIX,internal.local,DIRECT") {
			t.Fatal("fixture must retain the matching direct rule")
		}
	}
}
