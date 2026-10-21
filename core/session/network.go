package session

import (
	"context"
	"net"
	"net/netip"
	"slices"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// DefaultNetworkInterval checks interfaces every two seconds to detect network
// changes promptly at low polling cost.
const DefaultNetworkInterval = 2 * time.Second

// NetworkFingerprint includes up interfaces other than loopback and Sora, IPv4
// addresses, and global IPv6 /64 prefixes. It detects network or lease changes,
// ignoring same-network privacy address rotation. Empty means offline.
func NetworkFingerprint() string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return ""
	}
	var parts []string
	for _, iface := range interfaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 || iface.Name == engine.TunDevice {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, a := range addrs {
			network, ok := a.(*net.IPNet)
			if !ok {
				continue
			}
			addr, ok := netip.AddrFromSlice(network.IP)
			if !ok {
				continue
			}
			addr = addr.Unmap()
			switch {
			case addr.Is4():
				parts = append(parts, iface.Name+" "+addr.String())
			case addr.IsGlobalUnicast():
				prefix, _ := addr.Prefix(64)
				parts = append(parts, iface.Name+" "+prefix.String())
			}
		}
	}
	slices.Sort(parts)
	return strings.Join(slices.Compact(parts), ",")
}

// networkWatch detects network changes and resume from sleep so dead old-path
// TCP connections can be closed without waiting for application timeouts.
type networkWatch struct {
	probe    func() string
	interval time.Duration
	last     string
	// pending holds a fingerprint change until a second consecutive
	// measurement confirms it, so flapping interfaces do not renew
	// connections on every poll.
	pending string
	// Keep wall and monotonic observations separately to detect suspend
	// gaps.
	lastWall, lastMono time.Time
}

// sleepGap is the wall-minus-monotonic advance required to detect suspend.
// Ordinary scheduling delays advance both clocks equally.
const sleepGap = 30 * time.Second

func newNetworkWatch(probe func() string, interval time.Duration) *networkWatch {
	now := time.Now()
	return &networkWatch{probe: probe, interval: interval, last: probe(), lastWall: now.Round(0), lastMono: now}
}

// changed reports why the session should renew its connections, or "".
// A network move is reported only after two consecutive polls agree on the
// new fingerprint, debouncing flapping interfaces. Waking from
// sleep is reported immediately: the old path is certainly dead.
func (w *networkWatch) changed() string {
	now := time.Now()
	// The monotonic clock stops while the machine sleeps and the wall clock
	// does not.
	slept := now.Round(0).Sub(w.lastWall)-now.Sub(w.lastMono) > sleepGap
	w.lastWall, w.lastMono = now.Round(0), now
	current := w.probe()
	moved := current != w.last && current != ""
	switch {
	case slept:
		w.last, w.pending = current, ""
		return "the machine woke from sleep"
	case moved:
		if w.pending == current {
			w.last, w.pending = current, ""
			return "the network changed"
		}
		w.pending = current
		return ""
	default:
		w.pending = ""
		w.last = current
		return ""
	}
}

// renewConnections closes stale network flows so applications reconnect
// promptly.
func (s *Session) renewConnections(ctx context.Context, why string) {
	if s.State() != StateConnected {
		return
	}
	// Surface the network move itself, not just the renewal, so the
	// client can show the connection state while flows re-establish.
	s.log.Append(Event{Kind: EventNetwork, Detail: why})
	s.log.Append(Event{Kind: EventLog, Detail: why + "; connections reopen"})
	s.reopenFlows(ctx)
}

// reopenFlows drops every live connection so applications reconnect on a
// fresh path. Engines without bulk close, including Xray, reapply the plan
// by restarting instead.
func (s *Session) reopenFlows(ctx context.Context) {
	if tracker, ok := s.eng.(engine.ConnectionTracker); ok {
		if err := tracker.CloseConnections(ctx); err == nil {
			return
		}
	}
	if err := s.eng.Apply(ctx, s.cfg.Plan); err != nil {
		s.log.Append(Event{
			Kind:   EventError,
			Reason: errs.CodeUnavailable,
			Key:    errs.KeyEngineStartFailed,
			Detail: s.mask(err.Error()),
		})
	}
}
