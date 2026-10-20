package singbox

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// CENSOR-P2: sing-box must carry the full WS header set (not only Host),
// the early-data header name, and HTTPUpgrade headers; gRPC Xray-only
// fields must fail at render instead of dropping silently.

func p2Transport(t *testing.T, p *engine.Plan, proto string) map[string]any {
	t.Helper()
	cfg := render(t, p)
	for _, o := range cfg["outbounds"].([]any) {
		m := o.(map[string]any)
		if m["type"] == proto {
			tr, _ := m["transport"].(map[string]any)
			return tr
		}
	}
	t.Fatalf("no %s outbound rendered", proto)
	return nil
}

func TestCensorP2WSHeadersAndEarlyDataName(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVMess)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "ws", Path: "/ws", Host: "cdn.example.com",
		Headers:             map[string]string{"User-Agent": "Mozilla/5.0", "Host": "stale.example.com"},
		EarlyData:           2048,
		EarlyDataHeaderName: "Sec-WebSocket-Protocol",
	}
	tr := p2Transport(t, p, "vmess")
	headers, _ := tr["headers"].(map[string]any)
	if headers["User-Agent"] != "Mozilla/5.0" {
		t.Fatalf("ws headers lost the user agent: %v", tr)
	}
	if headers["Host"] != "cdn.example.com" {
		t.Fatalf("ws Host = %v, want the explicit Host field to win", headers["Host"])
	}
	if tr["early_data_header_name"] != "Sec-WebSocket-Protocol" {
		t.Fatalf("early_data_header_name = %v", tr["early_data_header_name"])
	}
}

func TestCensorP2HTTPUpgradeHeaders(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "httpupgrade", Path: "/up", Host: "cdn.example.com",
		Headers: map[string]string{"User-Agent": "Mozilla/5.0"},
	}
	tr := p2Transport(t, p, "trojan")
	headers, _ := tr["headers"].(map[string]any)
	if headers["User-Agent"] != "Mozilla/5.0" {
		t.Fatalf("httpupgrade headers = %v", tr)
	}
}

func TestCensorP2GRPCXrayOnlyFieldsRefused(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{Type: "grpc", Service: "tun", GRPCAuthority: "a.example.com"}
	if _, err := Render(p, testRuntime); err == nil || !strings.Contains(err.Error(), "Xray-only") {
		t.Fatalf("Render = %v, want an Xray-only refusal", err)
	}
}

func TestCensorP2DeterministicRenderAndEmptyService(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "ws", Path: "/ws", Host: "cdn.example.com",
		Headers: map[string]string{"User-Agent": "ua", "X-B": "2", "X-A": "1", "Accept": "*/*"},
	}
	a, err := Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	b, err := Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	if string(a) != string(b) {
		t.Fatal("repeated render of a header-carrying plan is not byte-identical")
	}
	p.Outbounds[0].Transport = engine.Transport{Type: "grpc"}
	tr := p2Transport(t, p, "trojan")
	if _, ok := tr["service_name"]; ok {
		t.Fatalf("empty service name must be omitted, got %v", tr)
	}
}
