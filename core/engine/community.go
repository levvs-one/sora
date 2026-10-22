package engine

import (
	"errors"
	"strconv"
	"strings"

	"github.com/enfein/mieru/v3/apis/trafficpattern"
	pb "github.com/enfein/mieru/v3/pkg/appctl/appctlpb"
)

// Mieru holds the options supported by the pinned mihomo adapter.
type Mieru struct {
	UDP            *bool
	PortRange      string
	Multiplexing   string
	HandshakeMode  string
	TrafficPattern string
}

// Naive keeps Cronet options separate from generic stream transports.
type Naive struct {
	QUIC                bool
	ExtraHeaders        map[string]string
	InsecureConcurrency int
	Certificate         []string
}

// MieruPorts also supplies the complete endpoint range to the kill switch.
func MieruPorts(value string) (uint16, uint16, error) {
	first, last, ok := strings.Cut(value, "-")
	if !ok {
		last = first
	}
	parse := func(s string) (uint16, error) {
		n, err := strconv.ParseUint(s, 10, 16)
		if err != nil || n == 0 || strings.Trim(s, "0123456789") != "" {
			return 0, errors.New("invalid mieru port")
		}
		return uint16(n), nil
	}
	a, err := parse(first)
	if err != nil {
		return 0, 0, err
	}
	b, err := parse(last)
	if err != nil || a > b {
		return 0, 0, errors.New("invalid mieru port range")
	}
	return a, b, nil
}

func (o Outbound) validateCommunity() error {
	if o.Transport.Type != "" && o.Transport.Type != "tcp" && o.Transport.Type != "udp" {
		return errors.New("community protocol requires TCP or UDP")
	}
	if o.Protocol == ProtocolMieru {
		m := o.Mieru
		if m == nil || o.UserID == "" || o.Password == "" || o.TLS.Enabled {
			return errors.New("mieru requires credentials and its native transport security")
		}
		if m.PortRange != "" {
			first, _, err := MieruPorts(m.PortRange)
			if err != nil || first != o.Port || !strings.Contains(m.PortRange, "-") {
				return errors.New("invalid mieru port range")
			}
		}
		if m.Multiplexing != "" {
			if _, ok := pb.MultiplexingLevel_value[m.Multiplexing]; !ok {
				return errors.New("invalid mieru multiplexing")
			}
		}
		if m.HandshakeMode != "" {
			if _, ok := pb.HandshakeMode_value[m.HandshakeMode]; !ok {
				return errors.New("invalid mieru handshake mode")
			}
		}
		if m.TrafficPattern != "" {
			p, err := trafficpattern.Decode(m.TrafficPattern)
			if err != nil || trafficpattern.Validate(p) != nil {
				return errors.New("invalid mieru traffic pattern")
			}
		}
		return nil
	}
	n := o.Naive
	if n == nil || !o.TLS.Enabled || o.TLS.Insecure || o.TLS.Reality || o.TLS.Fingerprint != "" || len(o.TLS.ALPN) != 0 {
		return errors.New("naive requires verified Cronet TLS without uTLS, REALITY or custom ALPN")
	}
	if (o.Transport.Type == "udp") != n.QUIC || n.InsecureConcurrency < 0 || n.InsecureConcurrency > 256 {
		return errors.New("invalid naive transport or concurrency")
	}
	if len(n.ExtraHeaders) > MaxHeaderCount {
		return errors.New("too many naive headers")
	}
	for k, v := range n.ExtraHeaders {
		if !validHeaderToken(k) || strings.ContainsAny(v, "\r\n\x00") {
			return errors.New("invalid naive header")
		}
	}
	return nil
}
