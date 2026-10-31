package xray

import (
	"context"
	"encoding/json"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestTheAccessLogListsRecentConnections(t *testing.T) {
	var f flows
	f.name(&engine.Plan{Outbounds: []engine.Outbound{{
		ID: "p", Protocol: engine.ProtocolXrayProfile,
		Profile: json.RawMessage(`{"outbounds":[{"tag":"vpn","protocol":"vless"},{"tag":"home","protocol":"freedom"}]}`),
	}}})
	now := time.Now()
	f.note("from tcp:192.0.2.2:5000 accepted tcp:example.com:443 [tun -> vpn]", now)
	f.note("from 192.0.2.2:5001 accepted udp:[2001:db8::1]:53 [tun >> sora-direct]", now.Add(time.Second))
	f.note("from tcp:192.0.2.2:5002 accepted tcp:example.ru:443 [tun -> home] email: a", now.Add(2*time.Second))
	f.note("from tcp:192.0.2.2:5003 accepted tcp:old.example:80 [tun -> vpn]", now.Add(-2*time.Minute))
	f.note("from 192.0.2.2:5004 rejected  tcp:rejected.example:80", now)
	f.note("app/dispatcher: default route for tcp:example.com:443", now)

	got := f.list(now.Add(3 * time.Second))
	if len(got) != 3 {
		t.Fatalf("got %d connections: %+v", len(got), got)
	}
	if got[0].Host != "example.ru" || got[0].Chain[0] != "direct" {
		t.Errorf("provider direct: %+v", got[0])
	}
	if got[1].Host != "2001:db8::1" || got[1].Network != "udp" || got[1].Port != 53 || got[1].Chain[0] != "direct" {
		t.Errorf("session direct: %+v", got[1])
	}
	if got[2].Host != "example.com" || got[2].Chain[0] != "p" || got[2].Closable {
		t.Errorf("through the profile: %+v", got[2])
	}
}

func TestTheConnectionListStaysBounded(t *testing.T) {
	var f flows
	now := time.Now()
	for i := range seenMax + 50 {
		f.note("from tcp:192.0.2.2:1 accepted tcp:host"+string(rune('a'+i%26))+".example:"+strconv.Itoa(i+1)+" [tun -> vpn]", now.Add(time.Duration(i)))
	}
	if got := f.list(now); len(got) > seenMax {
		t.Fatalf("kept %d", len(got))
	}
}

func TestXrayCannotCloseAConnection(t *testing.T) {
	e := &Engine{driver: &driver{}}
	if err := e.CloseConnection(context.Background(), "x"); err == nil {
		t.Fatal("closed a connection")
	}
	if err := e.CloseConnections(context.Background()); err == nil {
		t.Fatal("closed every connection")
	}
}

func TestOutboundConfigShowsTheServer(t *testing.T) {
	profile := engine.Outbound{ID: "p", Protocol: engine.ProtocolXrayProfile, Profile: json.RawMessage(`{"outbounds":[{"tag":"vpn"}]}`)}
	got, err := OutboundConfig(profile)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(got, "\n  ") || !strings.Contains(got, `"tag": "vpn"`) {
		t.Fatalf("profile: %s", got)
	}
	socks := engine.Outbound{ID: "s", Protocol: engine.ProtocolSOCKS5, Server: "192.0.2.1", Port: 1080}
	got, err = OutboundConfig(socks)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(got, "192.0.2.1") || !strings.Contains(got, "1080") {
		t.Fatalf("socks: %s", got)
	}
}
