package session

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestOLCRTCStrictEndpointsDoNotResolveTheRoomAsAProxyHost(t *testing.T) {
	endpoints, err := planEndpoints(t.Context(), &engine.Plan{Outbounds: []engine.Outbound{{ID: "room", Protocol: engine.ProtocolOLCRTC, Server: "unresolved.invalid", Port: 443}}})
	if err != nil || len(endpoints) != 0 {
		t.Fatal("dynamic provider was treated as a fixed VPN endpoint")
	}
}
