package singbox

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// CENSOR-P2 fix (review §3): the sing-box http (h2) transport spells a
// headers map on the pin but this renderer emitted only host/path, so
// the masquerade set dropped; on grpc and tcp the renderer now refuses
// a header set no engine can spell (plan validation is the primary
// gate, this is the backstop).

func TestCensorP2FixH2HeadersRendered(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVMess)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "h2", Path: "/h2", Host: "cdn.example.com",
		Headers: map[string]string{"User-Agent": "Mozilla/5.0", "X-A": "1"},
	}
	tr := p2Transport(t, p, "vmess")
	if tr["type"] != "http" {
		t.Fatalf("h2 transport type = %v, want http", tr["type"])
	}
	headers, _ := tr["headers"].(map[string]any)
	if headers["User-Agent"] != "Mozilla/5.0" || headers["X-A"] != "1" {
		t.Fatalf("h2 headers = %v, want the full plan set in %v", headers, tr)
	}
	// The Host field keeps its own spelling (the host list), it is not
	// folded into the header set on this transport.
	if _, ok := headers["Host"]; ok {
		t.Fatalf("h2 headers must not gain a folded Host entry: %v", headers)
	}
}

func TestCensorP2FixHeadersRefusedOnGRPCAndTCP(t *testing.T) {
	for _, typ := range []string{"grpc", "tcp", ""} {
		p := enginetest.Plan(engine.ProtocolTrojan)
		tr := engine.Transport{Type: typ, Headers: map[string]string{"User-Agent": "Mozilla/5.0"}}
		if typ == "grpc" {
			tr.Service = "tun"
		}
		p.Outbounds[0].Transport = tr
		if _, err := Render(p, testRuntime); err == nil || !strings.Contains(err.Error(), "headers") {
			t.Errorf("transport %q with headers: Render = %v, want a named headers refusal", typ, err)
		}
	}
	// Empty set still renders on both transports.
	for _, typ := range []string{"grpc", "tcp"} {
		p := enginetest.Plan(engine.ProtocolTrojan)
		tr := engine.Transport{Type: typ}
		if typ == "grpc" {
			tr.Service = "tun"
		}
		p.Outbounds[0].Transport = tr
		if _, err := Render(p, testRuntime); err != nil {
			t.Errorf("transport %q without headers: Render = %v", typ, err)
		}
	}
}

func TestCensorP2FixH2DeterministicRender(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "h2", Path: "/h2",
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
		t.Fatal("repeated h2 render with headers is not byte-identical")
	}
}
