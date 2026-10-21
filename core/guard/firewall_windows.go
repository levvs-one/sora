//go:build windows

package guard

import (
	"context"
	"errors"
	"net/netip"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/tailscale/wf"
	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/session"
)

// WFP uses a stable sublayer for strict rules so a new process can adopt or remove them.
type WFP struct {
	mu              sync.Mutex
	enginesDir      string
	bypass          []netip.Prefix
	tunNetworks     []netip.Prefix
	blockedNetworks []netip.Prefix
	session         *wf.Session
	policy          session.Settings
}

// PlatformFirewall returns Windows WFP, matching engines by executable because
// Windows has no Unix UID.
func PlatformFirewall(opts FirewallOptions) (Firewall, error) {
	bypass := opts.Bypass
	if len(bypass) == 0 {
		bypass = DefaultBypassNetworks()
	}
	prefixes := make([]netip.Prefix, 0, len(bypass))
	for _, network := range bypass {
		prefix, err := netip.ParsePrefix(network)
		if err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
				"guard: the bypass network %q is not a network", network)
		}
		prefixes = append(prefixes, prefix.Masked())
	}
	return &WFP{enginesDir: opts.EnginesDir, bypass: prefixes}, nil
}

// SetTunNetworks receives the selected session subnets before arming.
func (w *WFP) SetTunNetworks(networks []netip.Prefix) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.tunNetworks = append([]netip.Prefix(nil), networks...)
}

// SetBlockedNetworks prevents tunnel destinations from falling through LAN permits.
func (w *WFP) SetBlockedNetworks(networks []netip.Prefix) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.blockedNetworks = append([]netip.Prefix(nil), networks...)
}

// Rule weights inside the sublayer: every permit outranks the final block.
const (
	weightPermit       = 10
	weightTunnelBlock  = 40
	weightTunnelPermit = 50
	weightBlock        = 0
)

var outbound = []wf.LayerID{wf.LayerALEAuthConnectV4, wf.LayerALEAuthConnectV6}

// Arm installs the filters. Arming an armed switch changes nothing.
func (w *WFP) Arm(context.Context, []uint16) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	if w.session != nil && !w.policy.StrictKillSwitch {
		return nil
	}
	session, err := wf.New(&wf.Options{
		Name:        "Sora kill switch",
		Description: "Blocks traffic that does not go through the Sora tunnel",
		Dynamic:     !w.policy.StrictKillSwitch,
	})
	if err != nil {
		return refused(err)
	}
	var installErr error
	if w.policy.StrictKillSwitch {
		installErr = w.installStrict(session)
	} else {
		installErr = w.install(session)
	}
	if err := installErr; err != nil {
		_ = session.Close()
		return refused(err)
	}
	if w.session != nil {
		if err := w.session.Close(); err != nil {
			_ = session.Close()
			return refused(err)
		}
	}
	w.session = session
	return nil
}

// Disarm removes the filters by closing the session that owns them. The
// session handle is cleared only after a successful close: on failure the
// filters may still be installed, and dropping the handle would make them
// unreachable while Armed() wrongly reports false (SORA-M10).
func (w *WFP) Disarm(context.Context) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	// Non-dynamic rules remain accessible even after the original owner died.
	connection, err := wf.New(nil)
	if err != nil {
		return refused(err)
	}
	defer func() { _ = connection.Close() }()
	rules, err := connection.Rules()
	if err != nil {
		return refused(err)
	}
	var failures error
	for _, rule := range rules {
		if rule.Sublayer == strictSublayer {
			failures = errors.Join(failures, connection.DeleteRule(rule.ID))
		}
	}
	layers, layerErr := connection.Sublayers()
	failures = errors.Join(failures, layerErr)
	for _, layer := range layers {
		if layer.ID == strictSublayer {
			failures = errors.Join(failures, connection.DeleteSublayer(strictSublayer))
		}
	}
	if w.session != nil {
		if err := w.session.Close(); err != nil {
			failures = errors.Join(failures, err)
		} else {
			w.session = nil
		}
	}
	return failures
}

// Armed includes strict filters held by earlier processes.
func (w *WFP) Armed(context.Context) (bool, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	connection, err := wf.New(nil)
	if err != nil {
		return false, err
	}
	defer func() { _ = connection.Close() }()
	rules, err := connection.Rules()
	if err != nil {
		return false, err
	}
	for _, rule := range rules {
		if rule.Sublayer == strictSublayer {
			return true, nil
		}
	}
	return w.session != nil, nil
}

// SetPolicy is applied before replacing the rules.
func (w *WFP) SetPolicy(s session.Settings) { w.mu.Lock(); defer w.mu.Unlock(); w.policy = s }

var strictSublayer = wf.SublayerID{Data1: 0x18ce701b, Data2: 0x251c, Data3: 0x4bc8, Data4: [8]byte{0x8f, 0x3b, 0x13, 0x23, 0x7b, 0x0e, 0x74, 0x91}}

func (w *WFP) installStrict(connection *wf.Session) error {
	layers, err := connection.Sublayers()
	if err != nil {
		return err
	}
	found := false
	for _, layer := range layers {
		if layer.ID == strictSublayer {
			found = true
		}
	}
	if !found {
		if err := connection.AddSublayer(&wf.Sublayer{ID: strictSublayer, Name: "Sora strict kill switch", Weight: 0xffff, Persistent: true}); err != nil {
			return err
		}
	}
	old, err := connection.Rules()
	if err != nil {
		return err
	}
	// Install the replacement before deleting the old block, including during recovery.
	var added []wf.RuleID
	if err := w.rules(func(rule *wf.Rule) error {
		rule.Persistent = w.policy.Reconnect
		if err := connection.AddRule(rule); err != nil {
			return err
		}
		added = append(added, rule.ID)
		return nil
	}, strictSublayer); err != nil {
		for _, id := range added {
			_ = connection.DeleteRule(id)
		}
		return err
	}
	for _, rule := range old {
		if rule.Sublayer == strictSublayer {
			if err := connection.DeleteRule(rule.ID); err != nil {
				return err
			}
		}
	}
	return nil
}

// Name identifies the implementation in a diagnostics line.
func (w *WFP) Name() string { return "wfp" }

func (w *WFP) install(session *wf.Session) error {
	guid, err := windows.GenerateGUID()
	if err != nil {
		return err
	}
	sublayer := wf.SublayerID(guid)
	// Highest sublayer priority ensures this block overrides other
	// programs' permits.
	if err := session.AddSublayer(&wf.Sublayer{ID: sublayer, Name: "Sora kill switch", Weight: 0xffff}); err != nil {
		return err
	}
	return w.rules(session.AddRule, sublayer)
}

func (w *WFP) rules(addRule func(*wf.Rule) error, sublayer wf.SublayerID) error {
	add := func(name string, action wf.Action, weight uint64, conditions ...*wf.Match) error {
		for _, layer := range outbound {
			if !applies(layer, conditions) {
				continue
			}
			guid, err := windows.GenerateGUID()
			if err != nil {
				return err
			}
			if err := addRule(&wf.Rule{
				ID: wf.RuleID(guid), Name: "Sora: " + name, Layer: layer, Sublayer: sublayer,
				Weight: weight, Conditions: conditions, Action: action,
				Persistent: w.policy.StrictKillSwitch && w.policy.Reconnect,
			}); err != nil {
				return err
			}
		}
		return nil
	}
	permit := func(name string, conditions ...*wf.Match) error {
		return add(name, wf.ActionPermit, weightPermit, conditions...)
	}

	apps, err := w.executables()
	if err != nil {
		return err
	}
	// Require the core's account, LocalSystem for services, so
	// user-launched copies of engine executables cannot bypass the switch.
	owner, err := sameAccount()
	if err != nil {
		return err
	}
	for index, file := range apps {
		if w.policy.StrictKillSwitch && index != 0 {
			continue
		}
		id, err := wf.AppID(file)
		if err != nil {
			return err
		}
		conditions := []*wf.Match{
			{Field: wf.FieldALEAppID, Op: wf.MatchTypeEqual, Value: id},
			{Field: wf.FieldALEUserID, Op: wf.MatchTypeEqual, Value: owner},
		}
		if w.policy.StrictKillSwitch {
			conditions = append(conditions, &wf.Match{Field: wf.FieldIPRemotePort, Op: wf.MatchTypeEqual, Value: uint16(53)})
		}
		if err := add(filepath.Base(file), wf.ActionPermit, 30, conditions...); err != nil {
			return err
		}

	}
	if err := add("loopback", wf.ActionPermit, 30, &wf.Match{Field: wf.FieldFlags, Op: wf.MatchTypeFlagsAllSet, Value: wf.ConditionFlagIsLoopback}); err != nil {
		return err
	}
	for _, network := range w.tunNetworks {
		if err := add("through the tunnel", wf.ActionPermit, weightTunnelPermit, &wf.Match{Field: wf.FieldIPLocalAddress, Op: wf.MatchTypeEqual, Value: network},
			// Wintun is IF_TYPE_PROP_VIRTUAL (53); a bound source on a
			// physical adapter must not inherit the tunnel permit.
			&wf.Match{Field: wf.FieldNexthopInterfaceType, Op: wf.MatchTypeEqual, Value: uint32(53)}); err != nil {
			return err
		}
		// ALE_AUTH_CONNECT reauthorizes inbound replies too. Next-hop fields
		// are FWP_EMPTY there; arrival type is available on both v4/v6 layers.
		if err := add("reply through the tunnel", wf.ActionPermit, weightTunnelPermit,
			&wf.Match{Field: wf.FieldIPLocalAddress, Op: wf.MatchTypeEqual, Value: network},
			&wf.Match{Field: wf.FieldArrivalInterfaceType, Op: wf.MatchTypeEqual, Value: uint32(53)},
			&wf.Match{Field: wf.FieldFlags, Op: wf.MatchTypeFlagsAllSet, Value: wf.ConditionFlagIsReauthorize}); err != nil {
			return err
		}
	}
	for _, network := range append([]netip.Prefix{netip.MustParsePrefix(legacyFakeIPNetwork)}, w.blockedNetworks...) {
		if err := add("tunnel destination outside the tunnel", wf.ActionBlock, weightTunnelBlock,
			&wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: network}); err != nil {
			return err
		}
	}
	if err := add("DNS outside the tunnel", wf.ActionBlock, 20,
		&wf.Match{Field: wf.FieldIPRemotePort, Op: wf.MatchTypeEqual, Value: uint16(53)}); err != nil {
		return err
	}
	for _, ep := range w.policy.Endpoints {
		if err := add("VPN endpoint", wf.ActionPermit, 30,
			&wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: netip.PrefixFrom(ep.Addr(), ep.Addr().BitLen())},
			&wf.Match{Field: wf.FieldIPRemotePort, Op: wf.MatchTypeEqual, Value: ep.Port()},
		); err != nil {
			return err
		}
	}
	bypass := w.bypass
	if w.policy.StrictKillSwitch {
		bypass = nil
		if w.policy.AllowLAN {
			for _, network := range DefaultBypassNetworks() {
				bypass = append(bypass, netip.MustParsePrefix(network))
			}
		}
	}
	for _, network := range bypass {
		if err := permit("local network", &wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: network}); err != nil {
			return err
		}
	}
	// Permit DHCP and neighbor discovery to keep physical connectivity and
	// lease renewal working.
	udp := &wf.Match{Field: wf.FieldIPProtocol, Op: wf.MatchTypeEqual, Value: wf.IPProtoUDP}
	if err := permit("DHCP",
		udp,
		&wf.Match{Field: wf.FieldIPLocalPort, Op: wf.MatchTypeEqual, Value: uint16(68)},
		&wf.Match{Field: wf.FieldIPRemotePort, Op: wf.MatchTypeEqual, Value: uint16(67)},
		&wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: netip.MustParsePrefix("0.0.0.0/0")},
	); err != nil {
		return err
	}
	// Restrict IPv6 DHCP to server multicast; ports alone would permit
	// arbitrary destinations.
	if err := permit("DHCPv6",
		udp,
		&wf.Match{Field: wf.FieldIPLocalPort, Op: wf.MatchTypeEqual, Value: uint16(546)},
		&wf.Match{Field: wf.FieldIPRemotePort, Op: wf.MatchTypeEqual, Value: uint16(547)},
		&wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: netip.MustParsePrefix("ff02::1:2/128")},
	); err != nil {
		return err
	}
	if err := permit("DHCPv6 renewal", udp,
		&wf.Match{Field: wf.FieldIPLocalPort, Op: wf.MatchTypeEqual, Value: uint16(546)},
		&wf.Match{Field: wf.FieldIPRemotePort, Op: wf.MatchTypeEqual, Value: uint16(547)},
		&wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: netip.MustParsePrefix("fe80::/10")},
	); err != nil {
		return err
	}
	for _, kind := range []uint16{133, 135, 136} {
		// For ICMP the local port field carries the message type.
		if err := permit("neighbour discovery",
			&wf.Match{Field: wf.FieldIPProtocol, Op: wf.MatchTypeEqual, Value: wf.IPProtoICMPV6},
			&wf.Match{Field: wf.FieldIPLocalPort, Op: wf.MatchTypeEqual, Value: kind},
		); err != nil {
			return err
		}
	}
	return add("everything else", wf.ActionBlock, weightBlock)
}

// executables includes installed engines and the core for subscription updates
// and measurements.
func (w *WFP) executables() ([]string, error) {
	self, err := os.Executable()
	if err != nil {
		return nil, err
	}
	files := []string{self}
	// An empty enginesDir would turn the glob into "*.exe" and permit
	// arbitrary executables from the working directory: fail closed
	// instead (SORA-L20).
	if strings.TrimSpace(w.enginesDir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"wfp: the engines directory is not set")
	}
	engines, err := filepath.Glob(filepath.Join(w.enginesDir, "*.exe"))
	if err != nil {
		return nil, err
	}
	return append(files, engines...), nil
}

// sameAccount grants WFP filter access only to processes running as the core
// account.
func sameAccount() (*windows.SECURITY_DESCRIPTOR, error) {
	token := windows.GetCurrentProcessToken()
	user, err := token.GetTokenUser()
	if err != nil {
		return nil, err
	}
	sid := user.User.Sid.String()
	sd, err := windows.SecurityDescriptorFromString("O:SYG:SYD:(A;;CC;;;" + sid + ")")
	if err != nil {
		return nil, err
	}
	// Convert to absolute form because wf performs its own self-relative
	// conversion and Windows rejects repeating it.
	return sd.ToAbsolute()
}

// applies restricts address conditions to matching-family layers; WFP rejects
// cross-family networks.
func applies(layer wf.LayerID, conditions []*wf.Match) bool {
	for _, c := range conditions {
		if prefix, ok := c.Value.(netip.Prefix); ok {
			if prefix.Addr().Is4() != (layer == wf.LayerALEAuthConnectV4) {
				return false
			}
		}
		if c.Value == wf.IPProtoICMPV6 && layer == wf.LayerALEAuthConnectV4 {
			return false
		}
	}
	return true
}

func refused(err error) error {
	return errs.Newf(errs.CodePermissionDenied, errs.KeyGuardFirewallFail,
		"guard: the filtering platform refused the kill switch: %v", err)
}
