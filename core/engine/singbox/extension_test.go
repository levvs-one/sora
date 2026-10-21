package singbox

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func TestExtensionInboundPrecedesDirectRulesAndDNSHijack(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.LocalProxy.Enabled = false
	p.Options.AllowLAN = true
	p.ExtensionProxy = &engine.ExtensionProxy{Port: 23456, Username: "private-extension-user", Password: "private-extension-password-for-session", Target: "Proxy"}
	cfg := render(t, p)
	inbounds := cfg["inbounds"].([]any)
	if len(inbounds) != 1 {
		t.Fatal("private inbound must work without the ordinary listener")
	}
	in := inbounds[0].(map[string]any)
	user := in["users"].([]any)[0].(map[string]any)
	if in["tag"] != engine.ExtensionInbound || in["listen"] != "127.0.0.1" || in["listen_port"] != float64(23456) ||
		user["username"] != p.ExtensionProxy.Username || user["password"] != p.ExtensionProxy.Password {
		t.Fatal("private inbound lost its loopback binding or authentication")
	}
	rules := cfg["route"].(map[string]any)["rules"].([]any)
	first := rules[0].(map[string]any)
	if len(first) != 3 || first["inbound"].([]any)[0] != engine.ExtensionInbound || first["action"] != "route" || first["outbound"] != "Proxy" {
		t.Fatal("extension route must terminate before sniffing, DNS, regional and user rules")
	}
	if rules[4].(map[string]any)["outbound"] != "direct" {
		t.Fatal("fixture must retain the matching regional direct rule")
	}
}
