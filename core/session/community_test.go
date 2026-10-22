package session

import (
	"context"
	"net/netip"
	"slices"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestCommunityRecoveryEndpointsKeepTransportAndEveryMieruPort(t *testing.T) {
	p := &engine.Plan{Outbounds: []engine.Outbound{{Protocol: engine.ProtocolMieru, Server: "203.0.113.2", Port: 65534,
		Mieru: &engine.Mieru{PortRange: "65534-65535"}}}}
	endpoints, err := planEndpoints(context.Background(), p)
	if err != nil || len(endpoints) != 2 || endpoints[1].Address.Port() != 65535 {
		t.Fatalf("last valid port must terminate the range: %+v %v", endpoints, err)
	}
	for _, network := range []string{"tcp", "udp"} {
		p := &engine.Plan{Outbounds: []engine.Outbound{{Protocol: engine.ProtocolMieru, Server: "203.0.113.2", Port: 4200,
			Transport: engine.Transport{Type: network}, Mieru: &engine.Mieru{PortRange: "4200-4202"}}}}
		endpoints, err := planEndpoints(context.Background(), p)
		if err != nil || len(endpoints) != 3 {
			t.Fatalf("range: %+v %v", endpoints, err)
		}
		for _, value := range []string{"203.0.113.2:4200", "203.0.113.2:4201", "203.0.113.2:4202"} {
			if !slices.Contains(endpoints, Endpoint{Address: netip.MustParseAddrPort(value), Protocol: network}) {
				t.Fatalf("missing %s/%s", network, value)
			}
		}
	}
	for _, quic := range []bool{false, true} {
		want := "tcp"
		if quic {
			want = "udp"
		}
		got := endpointProtocols(engine.Outbound{Protocol: engine.ProtocolNaive, Naive: &engine.Naive{QUIC: quic}})
		if !slices.Equal(got, []string{want}) {
			t.Fatalf("naive quic=%v: %v", quic, got)
		}
	}
}

func TestCommunityIncompatibleSwitchPreservesCurrentTunnel(t *testing.T) {
	eng := newFakeEngine()
	manager := NewManager(ManagerConfig{Factory: func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
		available := []engine.Availability{{Kind: engine.KindXray, Usable: true, Version: engine.Version{Major: 26, Minor: 3, Patch: 27}}}
		if _, err := engine.SelectEngine(p, available, []engine.Kind{engine.KindXray}); err != nil {
			return nil, err
		}
		return eng, nil
	}})
	first, err := manager.Connect(t.Context(), testPlan("running"), Settings{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = manager.Disconnect(context.Background()) })
	for _, protocol := range []engine.Protocol{engine.ProtocolMieru, engine.ProtocolNaive} {
		p := testPlan("community")
		p.Outbounds[0].Protocol = protocol
		if _, err := manager.Connect(t.Context(), p, Settings{}); err == nil {
			t.Fatal("incompatible manual engine accepted")
		}
		if manager.Current() != first || first.State() != StateConnected {
			t.Fatal("incompatible selection stopped current tunnel")
		}
	}
}
