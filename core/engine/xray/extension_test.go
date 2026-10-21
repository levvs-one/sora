package xray

import (
	"encoding/json"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func TestExtensionInboundRoutesBeforeDirectAndDNSRules(t *testing.T) {
	for _, target := range []string{"vless", "Proxy"} {
		p := enginetest.Plan(engine.ProtocolVLESS)
		p.LocalProxy.Enabled = false
		p.Options.AllowLAN = true
		p.ExtensionProxy = &engine.ExtensionProxy{Port: 23456, Username: "private-extension-user", Password: "private-extension-password-for-session", Target: target}
		raw, err := Render(p, testRuntime, nil)
		if err != nil {
			t.Fatal(err)
		}
		var cfg struct {
			Inbounds []struct {
				Tag      string
				Listen   string
				Port     int
				Settings struct {
					Auth     string
					Accounts []struct{ User, Pass string }
					UDP      bool
				}
			}
			Routing struct{ Rules []map[string]any }
		}
		if err := json.Unmarshal(raw, &cfg); err != nil {
			t.Fatal(err)
		}
		if len(cfg.Inbounds) != 1 {
			t.Fatal("private inbound must work without the ordinary listener")
		}
		in := cfg.Inbounds[0]
		if in.Tag != engine.ExtensionInbound || in.Listen != "127.0.0.1" || in.Port != 23456 || in.Settings.Auth != "password" ||
			len(in.Settings.Accounts) != 1 || in.Settings.Accounts[0].User != p.ExtensionProxy.Username || in.Settings.Accounts[0].Pass != p.ExtensionProxy.Password || in.Settings.UDP {
			t.Fatal("private inbound lost its binding or authentication")
		}
		first := cfg.Routing.Rules[0]
		field, want := "outboundTag", "o0001"
		if target == "Proxy" {
			field, want = "balancerTag", "b-1"
		}
		if len(first) != 2 || first["inboundTag"].([]any)[0] != engine.ExtensionInbound || first[field] != want {
			t.Fatal("extension route must precede every user rule and select only the VPN")
		}
		if cfg.Routing.Rules[2]["outboundTag"] != "direct" {
			t.Fatal("fixture must retain the matching regional direct rule")
		}
	}
}
