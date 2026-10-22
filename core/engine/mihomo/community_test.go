package mihomo

import (
	"context"
	"os"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestMieruRenderingAndNativeValidation(t *testing.T) {
	for _, network := range []string{"tcp", "udp"} {
		for _, ports := range []string{"", "4200-4210"} {
			p := &engine.Plan{SessionID: "mieru", Outbounds: []engine.Outbound{{ID: "out", Name: "Community", Protocol: engine.ProtocolMieru,
				Server: "127.0.0.1", Port: 4200, UserID: "alice", Password: "private-password", Transport: engine.Transport{Type: network},
				Mieru: &engine.Mieru{PortRange: ports, Multiplexing: "MULTIPLEXING_HIGH", HandshakeMode: "HANDSHAKE_NO_WAIT", TrafficPattern: "CCoQARoECAEQCiIYCAMQASoIMDAwMTAyMDMqCDA0MDUwNjA3"}}}}
			raw, err := Render(p, testRuntime(t))
			if err != nil {
				t.Fatal(err)
			}
			var cfg struct{ Proxies []map[string]any }
			if err := yaml.Unmarshal([]byte(raw), &cfg); err != nil {
				t.Fatal(err)
			}
			px := cfg.Proxies[0]
			if px["type"] != "mieru" || px["transport"] != strings.ToUpper(network) || px["username"] != "alice" || px["password"] != "private-password" ||
				px["multiplexing"] != "MULTIPLEXING_HIGH" || px["handshake-mode"] != "HANDSHAKE_NO_WAIT" || px["traffic-pattern"] == nil || px["network"] != nil || px["tls"] != nil {
				t.Fatal("mieru fields were lost or rendered as generic TLS/transport")
			}
			if ports == "" && px["port"] != 4200 || ports != "" && (px["port-range"] != ports || px["port"] != nil) {
				t.Fatal("port and port-range must be mutually exclusive")
			}
			if binary := os.Getenv(Prober.EnvVar); binary != "" {
				home := t.TempDir()
				rt := supervise.Runtime{HomeDir: home}
				if err := supervise.Check(context.Background(), supervise.Spec{Name: "mihomo", Path: binary, Args: driver{}.CheckArgs(rt), Dir: home, Config: []byte(raw)}); err != nil {
					t.Fatal(err)
				}
			}
		}
	}
}
