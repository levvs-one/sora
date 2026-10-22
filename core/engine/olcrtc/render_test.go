package olcrtc_test

import (
	"bytes"
	"encoding/json"
	"testing"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/mihomo"
	"github.com/levvs-one/sora-client/core/engine/olcrtc"
	"github.com/levvs-one/sora-client/core/engine/singbox"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
)

func TestNativeRenderersCarryOLCRTCOverAuthenticatedSOCKS(t *testing.T) {
	const key = "d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799"
	source := &engine.Plan{SessionID: "render", Outbounds: []engine.Outbound{{ID: "olc", Name: "OLCRTC", Protocol: engine.ProtocolOLCRTC, Server: "meet.example.org", Port: 443, Password: key, OLCRTC: &engine.OLCRTC{Provider: "jitsi", Room: "https://meet.example.org/room", Transport: "vp8channel", Parameters: map[string]string{"vp8-fps": "60", "vp8-batch": "64"}}}}, Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "olc"}}}
	listener := olcrtc.Listener{Port: 19876, Username: "session-username-01234567890123456789", Password: "session-password-01234567890123456789"}
	plan := olcrtc.Rewrite(source, map[string]olcrtc.Listener{"olc": listener})
	if source.Outbounds[0].Protocol != engine.ProtocolOLCRTC || plan.Outbounds[0].SOCKSUDP {
		t.Fatal("rewrite mutated source or enabled unsupported UDP")
	}
	cfg, err := olcrtc.Render(source.Outbounds[0], listener)
	if err != nil {
		t.Fatal(err)
	}
	var carrier map[string]any
	if err = yaml.Unmarshal(cfg, &carrier); err != nil {
		t.Fatal(err)
	}
	if carrier["mode"] != "cnc" || carrier["socks"].(map[string]any)["host"] != "127.0.0.1" || carrier["vp8"].(map[string]any)["batch_size"] != 64 {
		t.Fatal("carrier schema")
	}
	rt := supervise.Runtime{HomeDir: t.TempDir(), LocalPort: 19877, ControlAddr: "127.0.0.1:19878", Secret: "controller-password"}
	renderers := map[string]func(*engine.Plan) ([]byte, error){"sing-box": func(p *engine.Plan) ([]byte, error) { return singbox.Render(p, rt) }, "xray": func(p *engine.Plan) ([]byte, error) { return xray.Render(p, rt, nil) }, "mihomo": func(p *engine.Plan) ([]byte, error) {
		raw, err := mihomo.Render(p, mihomo.Runtime{HomeDir: rt.HomeDir, MixedPort: rt.LocalPort, ControllerAddr: rt.ControlAddr, Secret: rt.Secret})
		return []byte(raw), err
	}}
	for name, render := range renderers {
		for _, tun := range []bool{false, true} {
			t.Run(name+map[bool]string{false: "-proxy", true: "-tun"}[tun], func(t *testing.T) {
				p := *plan
				p.Tun = engine.Tun{Enabled: tun, Stack: "gvisor"}
				p.DNS = engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "dns", Transport: engine.DNSHTTPS, Address: "1.1.1.1"}}}
				raw, err := render(&p)
				if err != nil {
					t.Fatal(err)
				}
				if bytes.Contains(raw, []byte(key)) || !bytes.Contains(raw, []byte(listener.Username)) || !bytes.Contains(raw, []byte(listener.Password)) || !bytes.Contains(raw, []byte("19876")) {
					t.Fatal("native config lost bridge or leaked PSK")
				}
				if name != "mihomo" && !json.Valid(raw) {
					t.Fatal("invalid JSON")
				}
			})
		}
	}
}
