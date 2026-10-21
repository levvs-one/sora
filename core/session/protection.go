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
		type peerEndpoint struct {
			endpoint  string
			protocols []string
		}
		peers := []peerEndpoint{{net.JoinHostPort(outbound.Server, strconv.Itoa(int(outbound.Port))), endpointProtocols(outbound)}}
		for _, peer := range outbound.Peers {
			peers = append(peers, peerEndpoint{peer.Endpoint, []string{"udp"}})
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
					peers = append(peers, peerEndpoint{net.JoinHostPort(server.Address, strconv.Itoa(int(server.Port))), endpointProtocols(engine.Outbound{Protocol: ob.Protocol, Transport: engine.Transport{Type: ob.StreamSettings.Network}, TLS: engine.TLS{ALPN: ob.StreamSettings.TLSSettings.ALPN}})})
				}
				for _, peer := range ob.Settings.Peers {
					peers = append(peers, peerEndpoint{peer.Endpoint, []string{"udp"}})
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
			for _, addr := range addresses {
				for _, protocol := range peer.protocols {
					endpoints = append(endpoints, Endpoint{Address: netip.AddrPortFrom(addr.Unmap(), uint16(number)), Protocol: protocol})
				}
			}
		}
	}
	if len(endpoints) == 0 {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail, "session: strict mode needs VPN server endpoints")
	}
	return endpoints, nil
}

// UDP payloads inside stream protocols still use TCP on the physical link.
func endpointProtocols(outbound engine.Outbound) []string {
	switch outbound.Protocol {
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
