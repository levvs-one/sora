package xray

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// CENSOR-P2 fix (review §3): Xray's grpcSettings spells no generic
// headers map and a raw stream has no handshake to carry one, so the
// renderer refuses a header set on grpc/tcp instead of dropping it
// (plan validation is the primary gate, this is the backstop). WS and
// HTTPUpgrade keep carrying the set — the original P2 regression
// surface.

func TestCensorP2FixHeadersRefusedOnGRPCAndTCP(t *testing.T) {
	for _, typ := range []string{"grpc", "tcp", ""} {
		p := enginetest.Plan(engine.ProtocolTrojan)
		tr := engine.Transport{Type: typ, Headers: map[string]string{"User-Agent": "Mozilla/5.0"}}
		if typ == "grpc" {
			tr.Service = "tun"
		}
		p.Outbounds[0].Transport = tr
		if _, err := Render(p, testRuntime, nil); err == nil || !strings.Contains(err.Error(), "headers") {
			t.Errorf("transport %q with headers: Render = %v, want a named headers refusal", typ, err)
		}
	}
	for _, typ := range []string{"grpc", "tcp"} {
		p := enginetest.Plan(engine.ProtocolTrojan)
		tr := engine.Transport{Type: typ}
		if typ == "grpc" {
			tr.Service = "tun"
		}
		p.Outbounds[0].Transport = tr
		if _, err := Render(p, testRuntime, nil); err != nil {
			t.Errorf("transport %q without headers: Render = %v", typ, err)
		}
	}
}

func TestCensorP2FixHeadersStillCarriedOnWSAndHTTPUpgrade(t *testing.T) {
	for _, tc := range []struct {
		typ, settings string
	}{
		{"ws", "wsSettings"},
		{"httpupgrade", "httpupgradeSettings"},
		{"xhttp", "xhttpSettings"},
	} {
		p := enginetest.Plan(engine.ProtocolVMess)
		p.Outbounds[0].Transport = engine.Transport{
			Type: tc.typ, Path: "/p", Host: "cdn.example.com",
			Headers: map[string]string{"User-Agent": "Mozilla/5.0"},
		}
		ss := p2Stream(t, p, "vmess")
		settings, _ := ss[tc.settings].(map[string]any)
		headers, _ := settings["headers"].(map[string]any)
		if headers["User-Agent"] != "Mozilla/5.0" {
			t.Errorf("transport %q: headers = %v, want the plan set carried in %v", tc.typ, headers, settings)
		}
	}
}
