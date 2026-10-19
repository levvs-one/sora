//go:build windows

package guard

import (
	"context"
	"net/netip"
	"sync"

	"github.com/tailscale/wf"
	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/errs"
)

// wfpIngressBackend owns a dynamic WFP session with receive-path filters,
// mirroring the outbound kill switch. Inbound connection attempts (SYNs,
// first UDP datagrams) are evaluated at ALE_AUTH_RECV_ACCEPT; established
// flows bypass re-authorization, so the final block drops only new inbound
// that matches no permit — the WFP equivalent of conntrack's
// established/related accept.
type wfpIngressBackend struct {
	mu      sync.Mutex
	cfg     IngressConfig
	bypass  []netip.Prefix
	session *wf.Session
}

// inbound layers see connection setup for both address families.
var inbound = []wf.LayerID{wf.LayerALEAuthRecvAcceptV4, wf.LayerALEAuthRecvAcceptV6}

func newIngressBackend(inner Firewall, cfg IngressConfig) (ingressBackend, error) {
	if _, ok := inner.(NoopFirewall); ok {
		// No process-managed firewall on this platform: nothing to
		// install, nothing to remove.
		return nil, nil
	}
	w, ok := inner.(*WFP)
	if !ok {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
			"guard: ingress protection needs the WFP firewall, got %T", inner)
	}
	// bypass is set once at construction and never mutated afterwards.
	return &wfpIngressBackend{cfg: cfg, bypass: w.bypass}, nil
}

// arm installs the receive filters. Arming an armed backend changes
// nothing.
func (b *wfpIngressBackend) arm(ctx context.Context) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	if b.session != nil {
		return nil
	}
	endpoints, err := parseIngressEndpoints(b.cfg.VPNEndpoints)
	if err != nil {
		return err
	}
	session, err := wf.New(&wf.Options{
		Name:        "Sora ingress guard",
		Description: "Drops inbound connections that bypass the Sora tunnel",
		Dynamic:     true,
	})
	if err != nil {
		return refused(err)
	}
	if err := b.install(session, endpoints); err != nil {
		_ = session.Close()
		return refused(err)
	}
	b.session = session
	return nil
}

// disarm removes the filters by closing the session that owns them. The
// handle is cleared only after a successful close so a failure keeps the
// filters reachable and a retry possible (SORA-M10 pattern).
func (b *wfpIngressBackend) disarm(ctx context.Context) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	if b.session == nil {
		return nil
	}
	if err := b.session.Close(); err != nil {
		return refused(err)
	}
	b.session = nil
	return nil
}

func (b *wfpIngressBackend) install(session *wf.Session, endpoints []netip.Addr) error {
	guid, err := windows.GenerateGUID()
	if err != nil {
		return err
	}
	sublayer := wf.SublayerID(guid)
	// Same highest sublayer priority as the kill switch so this block
	// overrides other programs' permits.
	if err := session.AddSublayer(&wf.Sublayer{ID: sublayer, Name: "Sora ingress guard", Weight: 0xffff}); err != nil {
		return err
	}
	return b.rules(session.AddRule, sublayer, endpoints)
}

func (b *wfpIngressBackend) rules(addRule func(*wf.Rule) error, sublayer wf.SublayerID, endpoints []netip.Addr) error {
	add := func(name string, action wf.Action, weight uint64, conditions ...*wf.Match) error {
		for _, layer := range inbound {
			if !applies(layer, conditions) {
				continue
			}
			guid, err := windows.GenerateGUID()
			if err != nil {
				return err
			}
			if err := addRule(&wf.Rule{
				ID: wf.RuleID(guid), Name: "Sora ingress: " + name, Layer: layer, Sublayer: sublayer,
				Weight: weight, Conditions: conditions, Action: action,
			}); err != nil {
				return err
			}
		}
		return nil
	}
	if err := add("loopback", wf.ActionPermit, weightPermit,
		&wf.Match{Field: wf.FieldFlags, Op: wf.MatchTypeFlagsAllSet, Value: wf.ConditionFlagIsLoopback}); err != nil {
		return err
	}
	// Inbound arriving on the virtual tunnel adapter came through the
	// tunnel; only physical interfaces are hardened. Wintun is
	// IF_TYPE_PROP_VIRTUAL (53), same constant as the outbound rules.
	if err := add("through the tunnel", wf.ActionPermit, weightTunnelPermit,
		&wf.Match{Field: wf.FieldArrivalInterfaceType, Op: wf.MatchTypeEqual, Value: uint32(53)}); err != nil {
		return err
	}
	for _, addr := range endpoints {
		if err := add("VPN server endpoint", wf.ActionPermit, weightPermit,
			&wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: netip.PrefixFrom(addr, addr.BitLen())}); err != nil {
			return err
		}
	}
	if b.cfg.AllowLAN {
		for _, network := range b.bypass {
			if err := add("local network", wf.ActionPermit, weightPermit,
				&wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: network}); err != nil {
				return err
			}
		}
	}
	return add("everything else", wf.ActionBlock, weightBlock)
}
