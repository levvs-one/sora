package session

import (
	"context"
	"encoding/json"
	"errors"
	"net/netip"
	"slices"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

type strictTestGuard struct{ fakeGuard }

func (g *strictTestGuard) Restore(ctx context.Context) error {
	if g.Current().StrictKillSwitch {
		return nil
	}
	return g.fakeGuard.Restore(ctx)
}
func (g *strictTestGuard) Release(ctx context.Context) error { return g.fakeGuard.Restore(ctx) }

func TestStrictManagerShutdownAndFailedDisconnect(t *testing.T) {
	g := &strictTestGuard{}
	m, _ := testManager(t, g)
	if _, err := m.Connect(t.Context(), strictPlan("strict"), Settings{StrictKillSwitch: true, Reconnect: true}); err != nil {
		t.Fatal(err)
	}
	if err := m.Shutdown(t.Context()); err != nil {
		t.Fatal(err)
	}
	if !m.Status().StrictKillSwitch {
		t.Fatal("service shutdown released strict mode")
	}
	// Even a stopped session must allow the explicit disable operation.
	off := false
	if err := m.SetProtection(t.Context(), false, &off); err != nil {
		t.Fatal(err)
	}
	if m.Status().KillSwitch {
		t.Fatal("disable retained protection")
	}
	m, eng := testManager(t, g)
	if _, err := m.Connect(t.Context(), strictPlan("stop-failure"), Settings{StrictKillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	eng.stopErr = errors.New("engine failed to stop")
	if err := m.Disconnect(t.Context()); err == nil {
		t.Fatal("stop failure hidden")
	}
	if g.Current().KillSwitch {
		t.Fatal("stop error stranded the firewall")
	}
}

func TestStrictFailedStartupRemainsReleasableWithoutSession(t *testing.T) {
	g := &strictTestGuard{}
	m, eng := testManager(t, g)
	eng.apply = errors.New("engine failed to start")
	if _, err := m.Connect(t.Context(), strictPlan("strict"), Settings{StrictKillSwitch: true}); err == nil {
		t.Fatal("expected startup failure")
	}
	if !m.Status().StrictKillSwitch {
		t.Fatal("startup cleanup released strict intent")
	}
	if err := m.Disconnect(t.Context()); err != nil {
		t.Fatal(err)
	}
	if m.Status().KillSwitch {
		t.Fatal("disconnect without session did not release intent")
	}
}

func TestStrictReplacementCannotSilentlyDisableProtection(t *testing.T) {
	g := &strictTestGuard{}
	m, _ := testManager(t, g)
	if _, err := m.Connect(t.Context(), strictPlan("first"), Settings{StrictKillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := m.Connect(t.Context(), strictPlan("replacement"), Settings{}); err != nil {
		t.Fatal(err)
	}
	if !g.Current().StrictKillSwitch {
		t.Fatal("Connect silently disabled strict mode")
	}
	if err := m.Disconnect(t.Context()); err != nil {
		t.Fatal(err)
	}
}

func TestStrictEndpointsIncludeBothFamiliesAndWireGuardPeers(t *testing.T) {
	plan := &engine.Plan{Outbounds: []engine.Outbound{
		{Server: "203.0.113.2", Port: 443},
		{Server: "2001:db8::2", Port: 8443},
		{Peers: []engine.WireGuardPeer{{Endpoint: "[2001:db8::3]:51820"}}},
	}}
	endpoints, err := planEndpoints(t.Context(), plan)
	if err != nil {
		t.Fatal(err)
	}
	if len(endpoints) != 3 {
		t.Fatalf("endpoints=%v", endpoints)
	}
}

func strictPlan(id string) *engine.Plan {
	plan := testPlan(id)
	for i := range plan.Outbounds {
		plan.Outbounds[i].Server = "203.0.113.2"
	}
	return plan
}

func TestStrictEndpointTransports(t *testing.T) {
	cases := []struct {
		outbound engine.Outbound
		want     []string
	}{
		{engine.Outbound{Protocol: engine.ProtocolVLESS}, []string{"tcp"}},
		{engine.Outbound{Protocol: engine.ProtocolVMess, Transport: engine.Transport{Type: "ws"}}, []string{"tcp"}},
		{engine.Outbound{Protocol: engine.ProtocolTrojan}, []string{"tcp"}},
		{engine.Outbound{Protocol: engine.ProtocolAnyTLS}, []string{"tcp"}},
		{engine.Outbound{Protocol: engine.ProtocolHTTP}, []string{"tcp"}},
		{engine.Outbound{Protocol: engine.ProtocolSOCKS5}, []string{"tcp"}},
		{engine.Outbound{Protocol: engine.ProtocolSOCKS5, SOCKSUDP: true}, []string{"tcp", "udp"}},
		{engine.Outbound{Protocol: engine.ProtocolShadowsocks}, []string{"tcp", "udp"}},
		{engine.Outbound{Protocol: engine.ProtocolHysteria2}, []string{"udp"}},
		{engine.Outbound{Protocol: engine.ProtocolTUIC}, []string{"udp"}},
		{engine.Outbound{Protocol: engine.ProtocolWireGuard}, []string{"udp"}},
		{engine.Outbound{Protocol: engine.ProtocolVLESS, Transport: engine.Transport{Type: "quic"}}, []string{"udp"}},
		{engine.Outbound{Protocol: engine.ProtocolVMess, Transport: engine.Transport{Type: "kcp"}}, []string{"udp"}},
		{engine.Outbound{Protocol: engine.ProtocolVLESS, Transport: engine.Transport{Type: "xhttp"}, TLS: engine.TLS{ALPN: []string{"h3"}}}, []string{"udp"}},
		{engine.Outbound{Protocol: engine.ProtocolVLESS, Transport: engine.Transport{Type: "xhttp"}, TLS: engine.TLS{ALPN: []string{"h3", "h2"}}}, []string{"tcp", "udp"}},
	}
	for _, tc := range cases {
		t.Run(string(tc.outbound.Protocol)+tc.outbound.Transport.Type+strings.Join(tc.outbound.TLS.ALPN, ","), func(t *testing.T) {
			tc.outbound.Server, tc.outbound.Port = "203.0.113.2", 443
			endpoints, err := planEndpoints(t.Context(), &engine.Plan{Outbounds: []engine.Outbound{tc.outbound}})
			if err != nil {
				t.Fatal(err)
			}
			if len(endpoints) != len(tc.want) {
				t.Fatalf("endpoints=%v", endpoints)
			}
			for i, protocol := range tc.want {
				if endpoints[i].Protocol != protocol || endpoints[i].Address != netip.MustParseAddrPort("203.0.113.2:443") {
					t.Fatalf("endpoint=%v", endpoints[i])
				}
			}
		})
	}
}

func TestStrictProfileEndpointTransports(t *testing.T) {
	profile := json.RawMessage(`{"outbounds":[
 {"protocol":"vless","settings":{"vnext":[{"address":"203.0.113.2","port":443}]},"streamSettings":{"network":"ws"}},
 {"protocol":"vmess","settings":{"vnext":[{"address":"2001:db8::2","port":443}]},"streamSettings":{"network":"kcp"}},
 {"protocol":"wireguard","settings":{"peers":[{"endpoint":"[2001:db8::3]:51820"}]}}
 ]}`)
	endpoints, err := planEndpoints(t.Context(), &engine.Plan{Outbounds: []engine.Outbound{{Protocol: engine.ProtocolXrayProfile, Profile: profile}}})
	if err != nil {
		t.Fatal(err)
	}
	want := []Endpoint{
		{Address: netip.MustParseAddrPort("203.0.113.2:443"), Protocol: "tcp"},
		{Address: netip.MustParseAddrPort("[2001:db8::2]:443"), Protocol: "udp"},
		{Address: netip.MustParseAddrPort("[2001:db8::3]:51820"), Protocol: "udp"},
	}
	if !slices.Equal(endpoints, want) {
		t.Fatalf("endpoints=%v; want %v", endpoints, want)
	}
	data, err := json.Marshal(endpoints)
	if err != nil {
		t.Fatal(err)
	}
	var restored []Endpoint
	if err := json.Unmarshal(data, &restored); err != nil || !slices.Equal(restored, want) {
		t.Fatalf("journal lost endpoint restrictions: %s, %v", data, err)
	}
}
