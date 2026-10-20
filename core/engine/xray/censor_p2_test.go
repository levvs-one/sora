package xray

import (
	"encoding/json"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// CENSOR-P2: Xray must carry WS/HTTPUpgrade headers, the early-data
// header name, and the full gRPC field set it alone spells.

func p2Stream(t *testing.T, p *engine.Plan, proto string) map[string]any {
	t.Helper()
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Outbounds []map[string]any `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	for _, o := range cfg.Outbounds {
		if o["protocol"] == proto {
			ss, _ := o["streamSettings"].(map[string]any)
			return ss
		}
	}
	t.Fatalf("no %s outbound", proto)
	return nil
}

func TestCensorP2WSHeadersAndEarlyDataName(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVMess)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "ws", Path: "/ws", Host: "cdn.example.com",
		Headers:             map[string]string{"User-Agent": "Mozilla/5.0"},
		EarlyData:           2048,
		EarlyDataHeaderName: "Sec-WebSocket-Protocol",
	}
	ws, _ := p2Stream(t, p, "vmess")["wsSettings"].(map[string]any)
	headers, _ := ws["headers"].(map[string]any)
	if headers["User-Agent"] != "Mozilla/5.0" {
		t.Fatalf("wsSettings = %v", ws)
	}
	if ws["earlyDataHeaderName"] != "Sec-WebSocket-Protocol" {
		t.Fatalf("earlyDataHeaderName = %v", ws["earlyDataHeaderName"])
	}
}

func TestCensorP2GRPCFullFieldSet(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "grpc", Service: "tun",
		GRPCAuthority: "auth.example.com", GRPCMultiMode: true, GRPCUserAgent: "ua/1.0",
	}
	g, _ := p2Stream(t, p, "trojan")["grpcSettings"].(map[string]any)
	if g["serviceName"] != "tun" || g["authority"] != "auth.example.com" ||
		g["multiMode"] != true || g["user_agent"] != "ua/1.0" {
		t.Fatalf("grpcSettings = %v", g)
	}
}

func TestCensorP2HTTPUpgradeHeaders(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "httpupgrade", Path: "/up", Host: "cdn.example.com",
		Headers: map[string]string{"User-Agent": "Mozilla/5.0"},
	}
	hu, _ := p2Stream(t, p, "trojan")["httpupgradeSettings"].(map[string]any)
	headers, _ := hu["headers"].(map[string]any)
	if headers["User-Agent"] != "Mozilla/5.0" {
		t.Fatalf("httpupgradeSettings = %v", hu)
	}
}
