package parser

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/url"
	"strconv"
	"strings"

	"github.com/enfein/mieru/v3/apis/trafficpattern"
	pb "github.com/enfein/mieru/v3/pkg/appctl/appctlpb"
	"google.golang.org/protobuf/proto"

	"github.com/levvs-one/sora-client/core/engine"
)

func parseCommunityLinks(raw string, limit int) ([]OutboundSpec, error) {
	u, err := url.Parse(raw)
	if err != nil {
		// OLCRTC carries its own nested URI grammar.
		if strings.HasPrefix(strings.ToLower(raw), "olcrtc://") {
			o, e := parseOLCRTC(raw)
			return []OutboundSpec{o}, e
		}
		return nil, ErrInvalid
	}
	switch strings.ToLower(u.Scheme) {
	case "mieru":
		data, err := base64.StdEncoding.DecodeString(raw[len("mieru://"):])
		var cfg pb.ClientConfig
		if err != nil || proto.Unmarshal(data, &cfg) != nil || len(cfg.GetProfiles()) == 0 {
			return nil, ErrInvalid
		}
		var out []OutboundSpec
		for _, profile := range cfg.GetProfiles() {
			items, err := mieruProfile(profile, limit-len(out))
			if err != nil {
				return nil, err
			}
			out = append(out, items...)
		}
		return out, nil
	case "mierus":
		q, err := url.ParseQuery(u.RawQuery)
		if err != nil || u.User == nil || u.Port() != "" || (u.Path != "" && u.Path != "/") ||
			len(q["profile"]) != 1 || len(q["port"]) == 0 || len(q["port"]) != len(q["protocol"]) {
			return nil, ErrInvalid
		}
		p := &pb.ClientProfile{ProfileName: proto.String(q.Get("profile")), User: &pb.User{Name: proto.String(u.User.Username())}}
		pw, _ := u.User.Password()
		p.User.Password = proto.String(pw)
		server := &pb.ServerEndpoint{DomainName: proto.String(u.Hostname())}
		p.Servers = []*pb.ServerEndpoint{server}
		for key, values := range q {
			switch key {
			case "port", "protocol":
				continue
			case "profile", "mtu", "multiplexing", "handshake-mode", "traffic-pattern":
				if len(values) != 1 {
					return nil, ErrInvalid
				}
			default:
				return nil, ErrUnsupported
			}
		}
		if v := q.Get("mtu"); v != "" {
			n, err := strconv.ParseInt(v, 10, 32)
			if err != nil || n <= 0 {
				return nil, ErrInvalid
			}
			p.Mtu = proto.Int32(int32(n))
		}
		if v := q.Get("multiplexing"); v != "" {
			n, ok := pb.MultiplexingLevel_value[v]
			if !ok {
				return nil, ErrInvalid
			}
			p.Multiplexing = &pb.MultiplexingConfig{Level: pb.MultiplexingLevel(n).Enum()}
		}
		if v := q.Get("handshake-mode"); v != "" {
			n, ok := pb.HandshakeMode_value[v]
			if !ok {
				return nil, ErrInvalid
			}
			p.HandshakeMode = pb.HandshakeMode(n).Enum()
		}
		if v := q.Get("traffic-pattern"); v != "" {
			p.TrafficPattern, err = trafficpattern.Decode(v)
			if err != nil {
				return nil, ErrInvalid
			}
		}
		for i, value := range q["port"] {
			a, _, err := engine.MieruPorts(value)
			n, ok := pb.TransportProtocol_value[q["protocol"][i]]
			if err != nil || !ok || (n != int32(pb.TransportProtocol_TCP) && n != int32(pb.TransportProtocol_UDP)) {
				return nil, ErrInvalid
			}
			b := &pb.PortBinding{Protocol: pb.TransportProtocol(n).Enum()}
			if strings.Contains(value, "-") {
				b.PortRange = proto.String(value)
			} else {
				b.Port = proto.Int32(int32(a))
			}
			server.PortBindings = append(server.PortBindings, b)
		}
		return mieruProfile(p, limit)
	case "naive+https", "naive+quic":
		o, err := parseNaive(u)
		return []OutboundSpec{o}, err
	default:
		o, err := parseLink(raw)
		return []OutboundSpec{o}, err
	}
}

func mieruProfile(p *pb.ClientProfile, limit int) ([]OutboundSpec, error) {
	if p.GetProfileName() == "" || len(p.GetServers()) == 0 || p.GetUser().GetName() == "" || p.GetUser().GetPassword() == "" {
		return nil, ErrInvalid
	}
	// mihomo does not expose a profile MTU or an upstream dialer.
	if p.GetMtu() != 0 || p.GetDialer() != nil {
		return nil, ErrUnsupported
	}
	var out []OutboundSpec
	for _, s := range p.GetServers() {
		host := s.GetDomainName()
		if host == "" {
			host = s.GetIpAddress()
		}
		if len(s.GetPortBindings()) == 0 {
			return nil, ErrInvalid
		}
		for _, binding := range s.GetPortBindings() {
			if len(out) >= limit {
				return nil, ErrInvalid
			}
			if binding.GetProtocol() != pb.TransportProtocol_TCP && binding.GetProtocol() != pb.TransportProtocol_UDP {
				return nil, ErrInvalid
			}
			m := &engine.Mieru{}
			if p.Multiplexing != nil {
				m.Multiplexing = p.GetMultiplexing().GetLevel().String()
			}
			if p.HandshakeMode != nil {
				m.HandshakeMode = p.GetHandshakeMode().String()
			}
			if p.TrafficPattern != nil {
				m.TrafficPattern = trafficpattern.Encode(p.TrafficPattern)
			}
			port := portNumber(int(binding.GetPort()))
			if value := binding.GetPortRange(); value != "" {
				if binding.GetPort() != 0 {
					return nil, ErrInvalid
				}
				var err error
				port, _, err = engine.MieruPorts(value)
				if err != nil {
					return nil, ErrInvalid
				}
				m.PortRange = value
			}
			o := OutboundSpec{Protocol: "mieru", Host: host, Port: port, Transport: strings.ToLower(binding.GetProtocol().String()),
				Security: "none", User: p.GetUser().GetName(), Password: p.GetUser().GetPassword(), DisplayName: p.GetProfileName(), Mieru: m, Options: map[string]string{}}
			if err := validateCommunitySpec(o); err != nil {
				return nil, err
			}
			out = append(out, o)
		}
	}
	return out, nil
}

func parseNaive(u *url.URL) (OutboundSpec, error) {
	q, err := url.ParseQuery(u.RawQuery)
	if err != nil || (u.Path != "" && u.Path != "/") || u.Opaque != "" {
		return OutboundSpec{}, ErrInvalid
	}
	o := OutboundSpec{Protocol: "naive", Host: u.Hostname(), Port: 443, Security: "tls", Transport: "tcp",
		DisplayName: u.Fragment, Options: map[string]string{}, Naive: &engine.Naive{QUIC: strings.EqualFold(u.Scheme, "naive+quic")}}
	if o.Naive.QUIC {
		o.Transport = "udp"
	}
	if u.Port() != "" {
		o.Port, err = parsePort(u.Port())
		if err != nil {
			return OutboundSpec{}, ErrInvalid
		}
	}
	if u.User != nil {
		o.User = u.User.Username()
		var hasPassword bool
		o.Password, hasPassword = u.User.Password()
		if !hasPassword {
			o.Password, o.User = o.User, ""
		}
	}
	for key, values := range q {
		if len(values) != 1 {
			return OutboundSpec{}, ErrInvalid
		}
		v := values[0]
		switch key {
		case "sni":
			o.ServerName = v
		case "insecure-concurrency":
			o.Naive.InsecureConcurrency, err = strconv.Atoi(v)
			if err != nil {
				return OutboundSpec{}, ErrInvalid
			}
		case "extra-headers":
			o.Naive.ExtraHeaders = map[string]string{}
			for _, line := range strings.Split(v, "\r\n") {
				k, value, ok := strings.Cut(line, ":")
				k = strings.TrimSpace(k)
				if !ok || k == "" {
					return OutboundSpec{}, ErrInvalid
				}
				for existing := range o.Naive.ExtraHeaders {
					if strings.EqualFold(existing, k) {
						return OutboundSpec{}, ErrInvalid
					}
				}
				o.Naive.ExtraHeaders[k] = strings.TrimSpace(value)
			}
		default:
			return OutboundSpec{}, ErrUnsupported
		}
	}
	return o, validateCommunitySpec(o)
}

func validateCommunitySpec(o OutboundSpec) error {
	if err := o.validate(); err != nil {
		return err
	}
	probe := engine.Outbound{ID: "import", Protocol: engine.Protocol(o.Protocol), Server: o.Host, Port: o.Port,
		UserID: o.User, Password: o.Password, Transport: engine.Transport{Type: o.Transport},
		TLS:   engine.TLS{Enabled: o.Security == "tls", ServerName: o.ServerName, Insecure: o.AllowInsecure, ALPN: o.ALPN, Fingerprint: o.Fingerprint},
		Mieru: o.Mieru, Naive: o.Naive}
	if probe.Validate() != nil {
		return ErrInvalid
	}
	return nil
}

func mapCommunitySpec(m map[string]any) (OutboundSpec, error) {
	// Typed decoding rejects strings in numeric/boolean fields instead of
	// silently changing a subscription's intended transport or credentials.
	var v struct {
		UDP                                                    *bool
		Type, Server, Username, Password, Name, Tag, Transport string
		Port                                                   int
		ServerPort                                             int    `json:"server_port"`
		PortRange                                              string `json:"port-range"`
		Multiplexing                                           string
		HandshakeMode                                          string `json:"handshake-mode"`
		TrafficPattern                                         string `json:"traffic-pattern"`
		QUIC                                                   bool
		ExtraHeaders                                           map[string]string `json:"extra_headers"`
		InsecureConcurrency                                    int               `json:"insecure_concurrency"`
		TLS                                                    struct {
			Enabled     bool
			ServerName  string `json:"server_name"`
			Certificate []string
		}
	}
	raw, err := json.Marshal(m)
	if err != nil || json.Unmarshal(raw, &v) != nil {
		return OutboundSpec{}, ErrInvalid
	}
	o := OutboundSpec{Protocol: v.Type, Host: v.Server, Port: portNumber(v.Port), User: v.Username, Password: v.Password,
		DisplayName: v.Name, Transport: "tcp", Security: "none", Options: map[string]string{}}
	allowed := "type server username password name tag"
	if o.DisplayName == "" {
		o.DisplayName = v.Tag
	}
	if v.Type == "mieru" {
		allowed += " port port-range transport multiplexing handshake-mode traffic-pattern udp"
		if v.Transport != "TCP" && v.Transport != "UDP" {
			return OutboundSpec{}, ErrInvalid
		}
		o.Transport = strings.ToLower(v.Transport)
		o.Mieru = &engine.Mieru{UDP: v.UDP, PortRange: v.PortRange, Multiplexing: v.Multiplexing, HandshakeMode: v.HandshakeMode, TrafficPattern: v.TrafficPattern}
		if v.PortRange != "" {
			if v.Port != 0 {
				return OutboundSpec{}, ErrInvalid
			}
			o.Port, _, err = engine.MieruPorts(v.PortRange)
			if err != nil {
				return OutboundSpec{}, ErrInvalid
			}
		}
	} else {
		allowed += " server_port quic extra_headers insecure_concurrency tls"
		o.Port, o.Security, o.ServerName = portNumber(v.ServerPort), "tls", v.TLS.ServerName
		if !v.TLS.Enabled {
			return OutboundSpec{}, ErrInvalid
		}
		tls, _ := m["tls"].(map[string]any)
		for key := range tls {
			if key != "enabled" && key != "server_name" && key != "certificate" {
				return OutboundSpec{}, ErrUnsupported
			}
		}
		o.Naive = &engine.Naive{QUIC: v.QUIC, ExtraHeaders: v.ExtraHeaders, InsecureConcurrency: v.InsecureConcurrency, Certificate: v.TLS.Certificate}
		if v.QUIC {
			o.Transport = "udp"
		}
	}
	for key := range m {
		if !strings.Contains(" "+allowed+" ", " "+key+" ") {
			return OutboundSpec{}, fmt.Errorf("%w: community option", ErrUnsupported)
		}
	}
	return o, validateCommunitySpec(o)
}
