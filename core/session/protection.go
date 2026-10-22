package session

import (
	"context"
	"encoding/json"
	"net"
	"net/netip"
	"slices"
	"strconv"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

func planEndpoints(ctx context.Context, plan *engine.Plan) ([]Endpoint, error) {
	var endpoints []Endpoint
	for _, outbound := range plan.Outbounds {
		if outbound.Protocol == engine.ProtocolOLCRTC {
			continue
		}
		type peerEndpoint struct {
			endpoint  string
			protocols []string
			last      uint16
		}
		peers := []peerEndpoint{{endpoint: net.JoinHostPort(outbound.Server, strconv.Itoa(int(outbound.Port))), protocols: endpointProtocols(outbound)}}
		if outbound.Mieru != nil && outbound.Mieru.PortRange != "" {
			_, last, err := engine.MieruPorts(outbound.Mieru.PortRange)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyGuardFirewallFail)
			}
			peers[0].last = last
		}
		for _, peer := range outbound.Peers {
			peers = append(peers, peerEndpoint{endpoint: peer.Endpoint, protocols: []string{"udp"}})
		}
		if len(outbound.Profile) > 0 {
			var profile struct {
				Outbounds []struct {
					Protocol       engine.Protocol
					StreamSettings struct {
						Network     string
						TLSSettings struct{ ALPN []string }
					}
					Settings struct {
						Vnext []struct {
							Address string
							Port    uint16
						}
						Servers []struct {
							Address string
							Port    uint16
						}
						Peers []engine.WireGuardPeer
					}
				}
			}
			if err := json.Unmarshal(outbound.Profile, &profile); err != nil {
				return nil, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyGuardFirewallFail)
			}
			for _, ob := range profile.Outbounds {
				for _, server := range append(ob.Settings.Vnext, ob.Settings.Servers...) {
					peers = append(peers, peerEndpoint{endpoint: net.JoinHostPort(server.Address, strconv.Itoa(int(server.Port))), protocols: endpointProtocols(engine.Outbound{Protocol: ob.Protocol, Transport: engine.Transport{Type: ob.StreamSettings.Network}, TLS: engine.TLS{ALPN: ob.StreamSettings.TLSSettings.ALPN}})})
				}
				for _, peer := range ob.Settings.Peers {
					peers = append(peers, peerEndpoint{endpoint: peer.Endpoint, protocols: []string{"udp"}})
				}
			}
		}
		for _, peer := range peers {
			host, port, err := net.SplitHostPort(peer.endpoint)
			if err != nil || host == "" || port == "0" {
				continue
			}
			number, err := strconv.ParseUint(port, 10, 16)
			if err != nil {
				return nil, err
			}
			addresses, err := net.DefaultResolver.LookupNetIP(ctx, "ip", host)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeUnavailable, errs.KeyGuardFirewallFail)
			}
			last := uint16(number)
			if peer.last != 0 {
				last = peer.last
			}
			for value := uint16(number); ; value++ {
				for _, addr := range addresses {
					for _, protocol := range peer.protocols {
						if len(endpoints) >= 65536 {
							return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyGuardFirewallFail, "session: too many recovery endpoints")
						}
						endpoints = append(endpoints, Endpoint{Address: netip.AddrPortFrom(addr.Unmap(), value), Protocol: protocol})
					}
				}
				if value == last {
					break
				}
			}
		}
	}
	if len(endpoints) == 0 && !plan.Protocols()[engine.ProtocolOLCRTC] {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail, "session: strict mode needs VPN server endpoints")
	}
	return endpoints, nil
}

// UDP payloads inside stream protocols still use TCP on the physical link.
func endpointProtocols(outbound engine.Outbound) []string {
	switch outbound.Protocol {
	case engine.ProtocolMieru:
		if outbound.Transport.Type == "udp" {
			return []string{"udp"}
		}
		return []string{"tcp"}
	case engine.ProtocolNaive:
		if outbound.Naive != nil && outbound.Naive.QUIC {
			return []string{"udp"}
		}
		return []string{"tcp"}
	case engine.ProtocolHysteria2, engine.ProtocolTUIC, engine.ProtocolWireGuard:
		return []string{"udp"}
	case engine.ProtocolShadowsocks:
		return []string{"tcp", "udp"}
	case engine.ProtocolSOCKS5, "socks":
		if outbound.SOCKSUDP {
			return []string{"tcp", "udp"}
		}
	}
	switch outbound.Transport.Type {
	case "quic", "kcp", "mkcp":
		return []string{"udp"}
	}
	// HTTP/3 rides QUIC; an h3 ALPN that also lists h2 or http/1.1 may fall
	// back to TCP, so both stay open.
	if slices.Contains(outbound.TLS.ALPN, "h3") {
		if len(outbound.TLS.ALPN) == 1 {
			return []string{"udp"}
		}
		return []string{"tcp", "udp"}
	}
	return []string{"tcp"}
}

// SetProtection serializes changes with connection replacement and disconnect.
// An empty session after recovery must still permit explicit release.
func (m *Manager) SetProtection(ctx context.Context, enabled bool, strict *bool) error {
	m.mu.Lock()
	if m.busy {
		m.mu.Unlock()
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionBusy, "session: another operation is running")
	}
	m.busy = true
	current := m.current
	m.mu.Unlock()
	defer m.release()
	if !enabled || (strict != nil && !*strict) {
		if g, ok := m.cfg.Guard.(interface{ Release(context.Context) error }); ok {
			if current != nil {
				current.guardMu.Lock()
				defer current.guardMu.Unlock()
			}
			if err := g.Release(ctx); err != nil {
				return err
			}
			if current != nil {
				current.mu.Lock()
				current.status.KillSwitch = false
				current.status.StrictKillSwitch = false
				current.mu.Unlock()
			}
			return nil
		}
	}
	if current != nil {
		return current.SetProtection(ctx, enabled, strict)
	}
	if !enabled || (strict != nil && !*strict) {
		return m.cfg.Guard.Restore(ctx)
	}
	return errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired, "session: there is no session to arm")
}
