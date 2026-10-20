package mihomo

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// CENSOR-P2 fix (review §3): mihomo's grpc-opts and h2-opts spell no
// headers key and its YAML loader silently ignores unknown keys, so
// the renderer refuses a header set on grpc, h2 and tcp instead of
// dropping it (plan validation is the primary gate for grpc/tcp; the
// h2 set is sing-box-only and catalog-gated via FeatureH2Headers).

func TestCensorP2FixHeadersRefusedOnGRPCAndTCPAndH2(t *testing.T) {
	mk := func(typ string, headers map[string]string) *engine.Plan {
		p := enginetest.Plan(engine.ProtocolTrojan)
		tr := engine.Transport{Type: typ, Path: "/p", Headers: headers}
		if typ == "grpc" {
			tr.Service = "tun"
		}
		p.Outbounds[0].Transport = tr
		return p
	}
	for _, typ := range []string{"grpc", "tcp", "", "h2"} {
		p := mk(typ, map[string]string{"User-Agent": "Mozilla/5.0"})
		if _, err := Render(p, testRuntime(t)); err == nil || !strings.Contains(err.Error(), "headers") {
			t.Errorf("transport %q with headers: Render = %v, want a named headers refusal", typ, err)
		}
	}
	for _, typ := range []string{"grpc", "tcp", "h2"} {
		if _, err := Render(mk(typ, nil), testRuntime(t)); err != nil {
			t.Errorf("transport %q without headers: Render = %v", typ, err)
		}
	}
}

func TestCensorP2FixHeadersStillCarriedOnWSAndXHTTP(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVMess)
	p.Outbounds[0].Transport = engine.Transport{
		Type: "ws", Path: "/ws",
		Headers: map[string]string{"User-Agent": "Mozilla/5.0"},
	}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "User-Agent: Mozilla/5.0") {
		t.Fatalf("ws render lost the header set:\n%s", out)
	}

	p2 := enginetest.Plan(engine.ProtocolVMess)
	p2.Outbounds[0].Transport = engine.Transport{
		Type: "xhttp", Path: "/x",
		Headers: map[string]string{"User-Agent": "Mozilla/5.0"},
	}
	out, err = Render(p2, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "User-Agent: Mozilla/5.0") {
		t.Fatalf("xhttp render lost the header set:\n%s", out)
	}
}
