package probe

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/binary"
	"net"
	"time"

	"golang.org/x/net/icmp"
	"golang.org/x/net/ipv4"
	"golang.org/x/net/ipv6"

	"github.com/levvs-one/sora-client/core/errs"
)

// IANA protocol numbers that icmp.ParseMessage expects.
const (
	protocolICMP   = 1
	protocolICMPv6 = 58
)

// echo sends one ICMP echo request to host and times the matching reply.
//
// It prefers an unprivileged ping socket (Linux with ping_group_range) and
// falls back to a raw socket, which the privileged core can open on Linux and
// Windows. Replies are matched by peer, sequence number and a random payload,
// so concurrent echoes on raw sockets never take each other's replies.
func echo(ctx context.Context, host string, timeout time.Duration) (time.Duration, error) {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	ip, err := resolve(ctx, host)
	if err != nil {
		return 0, err
	}
	v4 := ip.To4() != nil
	conn, datagram, err := listen(v4)
	if err != nil {
		return 0, err
	}
	defer func() { _ = conn.Close() }()
	if deadline, ok := ctx.Deadline(); ok {
		_ = conn.SetDeadline(deadline)
	}
	// A cancelled request unblocks the read at once instead of at the deadline.
	stop := context.AfterFunc(ctx, func() { _ = conn.SetDeadline(time.Now()) })
	defer stop()

	var token [8]byte
	if _, err := rand.Read(token[:]); err != nil {
		return 0, errs.From(err)
	}
	id := int(binary.BigEndian.Uint16(token[:2]))
	seq := int(binary.BigEndian.Uint16(token[2:4]))
	payload := append([]byte("sora-probe-"), token[4:]...)
	var request, reply icmp.Type = ipv4.ICMPTypeEcho, ipv4.ICMPTypeEchoReply
	protocol := protocolICMP
	if !v4 {
		request, reply, protocol = ipv6.ICMPTypeEchoRequest, ipv6.ICMPTypeEchoReply, protocolICMPv6
	}
	message, err := (&icmp.Message{Type: request, Body: &icmp.Echo{ID: id, Seq: seq, Data: payload}}).Marshal(nil)
	if err != nil {
		return 0, errs.From(err)
	}
	var target net.Addr = &net.IPAddr{IP: ip}
	if datagram {
		target = &net.UDPAddr{IP: ip}
	}
	start := time.Now()
	if _, err := conn.WriteTo(message, target); err != nil {
		return 0, errs.From(err)
	}
	buffer := make([]byte, 1500)
	for {
		n, peer, err := conn.ReadFrom(buffer)
		if err != nil {
			if ctx.Err() != nil {
				return 0, errs.From(ctx.Err())
			}
			return 0, errs.From(err)
		}
		if !sameIP(peer, ip) {
			continue
		}
		parsed, err := icmp.ParseMessage(protocol, buffer[:n])
		if err != nil || parsed.Type != reply {
			continue
		}
		body, ok := parsed.Body.(*icmp.Echo)
		// Ping sockets replace the identifier with their own port, so there
		// only the sequence number and the payload identify the reply.
		if !ok || body.Seq != seq || (!datagram && body.ID != id) || !bytes.Equal(body.Data, payload) {
			continue
		}
		return time.Since(start), nil
	}
}

// listen opens a ping socket where the system allows one, otherwise a raw
// ICMP socket. datagram reports which one it is.
func listen(v4 bool) (conn *icmp.PacketConn, datagram bool, err error) {
	network, raw, address := "udp4", "ip4:icmp", "0.0.0.0"
	if !v4 {
		network, raw, address = "udp6", "ip6:ipv6-icmp", "::"
	}
	if conn, err := icmp.ListenPacket(network, address); err == nil {
		return conn, true, nil
	}
	conn, err = icmp.ListenPacket(raw, address)
	if err != nil {
		return nil, false, errs.Newf(errs.CodePermissionDenied, errs.KeyProbeInvalidEndpoint,
			"probe: this system does not allow ICMP echo: %v", err)
	}
	return conn, false, nil
}

// resolve returns the host's address, preferring IPv4.
func resolve(ctx context.Context, host string) (net.IP, error) {
	if ip := net.ParseIP(host); ip != nil {
		return ip, nil
	}
	addresses, err := net.DefaultResolver.LookupIPAddr(ctx, host)
	if err != nil {
		return nil, errs.From(err)
	}
	for _, address := range addresses {
		if address.IP.To4() != nil {
			return address.IP, nil
		}
	}
	if len(addresses) == 0 {
		return nil, errs.Newf(errs.CodeUnavailable, errs.KeyProbeInvalidEndpoint,
			"probe: the host has no address")
	}
	return addresses[0].IP, nil
}

func sameIP(peer net.Addr, ip net.IP) bool {
	switch a := peer.(type) {
	case *net.IPAddr:
		return a.IP.Equal(ip)
	case *net.UDPAddr:
		return a.IP.Equal(ip)
	}
	return false
}
