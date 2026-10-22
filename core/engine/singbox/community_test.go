package singbox

import (
	"context"
	"os"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestNaiveRenderingAndNativeValidation(t *testing.T) {
	for _, quic := range []bool{false, true} {
		network := "tcp"
		if quic {
			network = "udp"
		}
		p := &engine.Plan{SessionID: "naive", Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolNaive,
			Server: "127.0.0.1", Port: 443, UserID: "alice", Password: "private-password", Transport: engine.Transport{Type: network},
			TLS:   engine.TLS{Enabled: true, ServerName: "front.example"},
			Naive: &engine.Naive{QUIC: quic, ExtraHeaders: map[string]string{"X-Test": "private-header"}, InsecureConcurrency: 2}}}}
		cfg := render(t, p)
		out := cfg["outbounds"].([]any)[0].(map[string]any)
		tls := out["tls"].(map[string]any)
		if out["type"] != "naive" || out["username"] != "alice" || out["password"] != "private-password" || out["insecure_concurrency"] != float64(2) ||
			out["extra_headers"].(map[string]any)["X-Test"] != "private-header" || tls["enabled"] != true || tls["server_name"] != "front.example" || out["transport"] != nil {
			t.Fatal("naive options were lost or generic transport was rendered")
		}
		if quic && out["quic"] != true || !quic && out["quic"] != nil {
			t.Fatal("QUIC flag lost")
		}
		redactor := engine.NewRedactor(p.Secrets()...)
		if redactor.String("private-header private-password") != "[masked] [masked]" {
			t.Fatal("naive credentials or extra headers escaped redaction")
		}
		if path := os.Getenv(Prober.EnvVar); path != "" {
			binary, err := Prober.Probe(context.Background(), path)
			if err != nil || !NaiveReady(context.Background(), binary) {
				t.Fatalf("Naive runtime unavailable: %v", err)
			}
			raw, err := Render(p, testRuntime)
			if err != nil {
				t.Fatal(err)
			}
			home := t.TempDir()
			rt := supervise.Runtime{HomeDir: home}
			if err := supervise.Check(context.Background(), supervise.Spec{Name: "sing-box", Path: path, Args: driver{}.CheckArgs(rt), Dir: home, Config: raw}); err != nil {
				t.Fatal(err)
			}
		}
		p.Options.Fragment.Enabled = true
		if _, err := Render(p, testRuntime); err == nil {
			t.Fatal("unsupported Cronet fragmentation was accepted")
		}
	}
}
