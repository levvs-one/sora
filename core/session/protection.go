package session

import (
	"context"
	"encoding/json"
	"net"
	"net/netip"
	"strconv"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

func planEndpoints(ctx context.Context, plan *engine.Plan) ([]netip.AddrPort, error) {
	var endpoints []netip.AddrPort
	for _, outbound := range plan.Outbounds {
		peers := []engine.WireGuardPeer{{Endpoint: net.JoinHostPort(outbound.Server, strconv.Itoa(int(outbound.Port)))}}
		peers = append(peers, outbound.Peers...)
		if len(outbound.Profile) > 0 {
			var profile struct {
				Outbounds []struct {
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
					peers = append(peers, engine.WireGuardPeer{Endpoint: net.JoinHostPort(server.Address, strconv.Itoa(int(server.Port)))})
				}
				peers = append(peers, ob.Settings.Peers...)
			}
		}
		for _, peer := range peers {
			host, port, err := net.SplitHostPort(peer.Endpoint)
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
				endpoints = append(endpoints, netip.AddrPortFrom(addr.Unmap(), uint16(number)))
			}
		}
	}
	if len(endpoints) == 0 {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail, "session: strict mode needs VPN server endpoints")
	}
	return endpoints, nil
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
