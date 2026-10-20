package mihomo

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// CENSOR-P2: mihomo must carry the WS early-data header name and the
// gRPC user agent; gRPC authority/multi-mode must fail at render
// instead of being dropped by mihomo's lenient YAML loader.

func TestCensorP2WSEarlyDataHeaderNameAndGRPCUserAgent(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVMess)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "ws", Path: "/ws", Host: "cdn.example.com",
		EarlyData: 2048, EarlyDataHeaderName: "Sec-WebSocket-Protocol",
	}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "early-data-header-name: Sec-WebSocket-Protocol") {
		t.Fatalf("render is missing the early-data header name:\n%s", out)
	}

	p2 := enginetest.Plan(engine.ProtocolTrojan)
	p2.Outbounds[0].Transport = engine.Transport{Type: "grpc", Service: "tun", GRPCUserAgent: "ua/1.0"}
	out, err = Render(p2, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "grpc-user-agent: ua/1.0") {
		t.Fatalf("render is missing grpc-user-agent:\n%s", out)
	}
}

func TestCensorP2GRPCAuthorityRefused(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{Type: "grpc", Service: "tun", GRPCAuthority: "a.example.com"}
	if _, err := Render(p, testRuntime(t)); err == nil || !strings.Contains(err.Error(), "Xray-only") {
		t.Fatalf("Render = %v, want an Xray-only refusal", err)
	}
}

func TestCensorP2DeterministicRenderAndEmptyService(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "ws", Path: "/ws", Host: "cdn.example.com",
		Headers: map[string]string{"User-Agent": "ua", "X-B": "2", "X-A": "1", "Accept": "*/*"},
	}
	a, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	b, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if a != b {
		t.Fatal("repeated render of a header-carrying plan is not byte-identical")
	}
	p.Outbounds[0].Transport = engine.Transport{Type: "grpc"}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out, "grpc-service-name") {
		t.Fatalf("empty service name must be omitted:\n%s", out)
	}
}
