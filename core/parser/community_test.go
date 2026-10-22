package parser

import (
	"encoding/base64"
	"testing"

	pb "github.com/enfein/mieru/v3/pkg/appctl/appctlpb"
	"google.golang.org/protobuf/proto"
)

func TestCommunityImportsLinksListsAndStructuredSubscriptions(t *testing.T) {
	mieru := "mierus://alice:p%40ss%2Bword@[2001:db8::1]?profile=Community&port=4100-4102&protocol=UDP&multiplexing=MULTIPLEXING_HIGH&handshake-mode=HANDSHAKE_NO_WAIT"
	naive := "naive+quic://alice:p%40ss%2Bword@example.com/?sni=front.example&extra-headers=X-Test%3A%20secret%0D%0AX-Other%3A%20value#Community"
	for name, input := range map[string]string{
		"mierus":             mieru,
		"mierus-default-mtu": mieru + "&mtu=1400",
		"naive":              naive,
		"naive-default-port": "naive+https://alice:password@example.com#Name",
		"list":               mieru + "\n" + naive,
		"base64":             base64.StdEncoding.EncodeToString([]byte(mieru + "\n" + naive)),
		"clash":              "proxies:\n- {name: Community, type: mieru, server: '2001:db8::1', port-range: 4100-4102, transport: UDP, username: alice, password: 'p@ss+word', multiplexing: MULTIPLEXING_HIGH, handshake-mode: HANDSHAKE_NO_WAIT, udp: false}",
		"singbox":            `{"outbounds":[{"type":"naive","server":"example.com","server_port":443,"username":"alice","password":"p@ss+word","quic":true,"extra_headers":{"X-Test":"secret"},"tls":{"enabled":true,"server_name":"front.example"}}]}`,
	} {
		t.Run(name, func(t *testing.T) {
			r, err := (LinkParser{}).Parse([]byte(input))
			if err != nil || r.Report.Invalid != 0 || r.Report.Unsupported != 0 || len(r.Servers) == 0 {
				t.Fatalf("parse: %+v, %v", r.Report, err)
			}
			for _, o := range r.Servers {
				if o.Protocol == "mieru" && (o.Mieru == nil || o.Mieru.PortRange != "4100-4102" || o.Transport != "udp" || o.Password != "p@ss+word") {
					t.Fatal("mieru options lost")
				}
				if o.Protocol == "naive" && (o.Naive == nil || o.Port != 443 || o.Security != "tls") {
					t.Fatal("naive options lost")
				}
			}
			if name == "clash" && (r.Servers[0].Mieru.UDP == nil || *r.Servers[0].Mieru.UDP) {
				t.Fatal("explicit UDP forwarding flag lost")
			}
		})
	}
}

func TestMieruStandardLinkAndMultipleBindingsRemainDistinct(t *testing.T) {
	profile := &pb.ClientProfile{ProfileName: proto.String("Community"), Mtu: proto.Int32(1400), User: &pb.User{Name: proto.String("alice"), Password: proto.String("password")},
		Servers: []*pb.ServerEndpoint{{DomainName: proto.String("example.com"), PortBindings: []*pb.PortBinding{
			{Port: proto.Int32(443), Protocol: pb.TransportProtocol_TCP.Enum()},
			{Port: proto.Int32(443), Protocol: pb.TransportProtocol_UDP.Enum()},
			{PortRange: proto.String("443-445"), Protocol: pb.TransportProtocol_TCP.Enum()},
		}}}}
	raw, err := proto.Marshal(&pb.ClientConfig{Profiles: []*pb.ClientProfile{profile}})
	if err != nil {
		t.Fatal(err)
	}
	for _, input := range []string{
		"mieru://" + base64.StdEncoding.EncodeToString(raw),
		"mierus://alice:password@example.com?profile=Community&port=443&protocol=TCP&port=443&protocol=UDP&port=443-445&protocol=TCP",
	} {
		r, err := (LinkParser{}).Parse([]byte(input))
		if err != nil || len(r.Servers) != 3 || r.Report.SkippedDuplicates != 0 {
			t.Fatalf("binding expansion: %+v, %v", r.Report, err)
		}
		limited, _ := (LinkParser{MaxItems: 2}).Parse([]byte(input))
		if len(limited.Servers) != 0 || limited.Report.Invalid != 1 {
			t.Fatal("binding expansion exceeded item limit")
		}
	}
}

func TestCommunityRejectsMalformedAndUnsupportedOptions(t *testing.T) {
	for _, input := range []string{
		"mierus://alice:password@example.com?profile=A&port=443&protocol=bogus",
		"mierus://alice:password@example.com?profile=A&port=0&protocol=TCP",
		"mierus://alice:password@example.com?profile=A&port=65536&protocol=TCP",
		"mierus://alice:password@example.com?profile=A&port=900-800&protocol=TCP",
		"mierus://alice:password@example.com?profile=A&port=400-500junk&protocol=TCP",
		"mierus://alice:password@example.com?profile=A&port=443&port=444&protocol=TCP",
		"mierus://alice:@example.com?profile=A&port=443&protocol=TCP",
		"mierus://alice:password@example.com?profile=A&port=443&protocol=TCP&multiplexing=invalid",
		"mierus://alice:password@example.com?profile=A&port=443&protocol=TCP&traffic-pattern=invalid",
		"mierus://alice:password@example.com?profile=A&port=443&protocol=TCP&mtu=1280",
		"mieru://invalid",
		"naive+https://alice:password@/",
		"naive+quic://alice:password@example.com:65536/",
		"naive+https://alice:password@example.com/?extra-headers=X%0AInjected%3A%20value",
		"naive+https://alice:password@example.com/?insecure-concurrency=-1",
		"naive+https://alice:password@example.com/?extra-headers=X%3A1%0D%0Ax%3A2",
		"naive+https://alice:password@example.com/?insecure=1",
		"naive+https://alice:password@example.com/?padding=false",
		`{"outbounds":[{"type":"naive","server":"example.com","server_port":443,"quic":"false","tls":{"enabled":true}}]}`,
		`{"outbounds":[{"type":"naive","server":"example.com","server_port":443,"tls":{"enabled":true,"insecure":true}}]}`,
		"proxies:\n- {type: mieru, server: example.com, port: 443, port-range: 443-445, transport: TCP, username: alice, password: password}",
	} {
		r, _ := (LinkParser{}).Parse([]byte(input))
		if len(r.Servers) != 0 || r.Report.Invalid+r.Report.Unsupported != 1 {
			t.Fatalf("malformed input was accepted or miscounted: %s: %+v", input, r.Report)
		}
	}
}
