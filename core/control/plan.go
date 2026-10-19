package control

import (
	"bytes"
	"compress/gzip"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/netip"
	"net/url"
	"runtime"
	"strconv"
	"strings"
	"time"

	"golang.org/x/net/idna"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/parser"
	"github.com/levvs-one/sora-client/core/routing"
)

// Enforce contract request limits before allocating plan data.
const (
	// MaxPlanBytes is the largest plan the contract accepts.
	MaxPlanBytes = 4 << 20
	// MaxImportBytes is the largest payload ParseImport accepts.
	MaxImportBytes = 16 << 20
	// MaxProbeEndpoints is the largest number of endpoints one probe
	// request
	// may carry.
	MaxProbeEndpoints = 256
)

// resolver resolves plan references to credentials for the engine. Resolved
// material is never returned to the client.
type resolver interface {
	Get(reference string) ([]byte, error)
}

// parseCredential reads the import pipeline's flat credential map. Only the
// JSON document produced by credentialDocument is accepted; anything else
// (a raw proxy URL, truncated or foreign bytes) fails closed instead of
// yielding an empty, partially configured credential (SORA-M8).
func parseCredential(material []byte) (map[string]string, error) {
	if len(bytes.TrimSpace(material)) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
			"control: credential material is empty")
	}
	out := make(map[string]string, 12)
	if err := json.Unmarshal(material, &out); err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
			"control: credential material is not a credential document: %v", err)
	}
	return out, nil
}

// credentialDocument serializes only supported credential fields for storage.
func credentialDocument(spec parser.OutboundSpec) ([]byte, error) {
	values := map[string]string{
		"uuid":         spec.UUID,
		"password":     spec.Password,
		"method":       spec.Cipher,
		"user":         spec.User,
		"flow":         spec.Flow,
		"public_key":   spec.PublicKey,
		"short_id":     spec.ShortID,
		"server_name":  spec.ServerName,
		"fingerprint":  spec.Fingerprint,
		"spider_x":     spec.SpiderX,
		"mode":         spec.Mode,
		"path":         spec.Path,
		"host_header":  spec.HostHeader,
		"service_name": spec.ServiceName,
		"alpn":         strings.Join(spec.ALPN, ","),
		"security":     spec.Security,
		"encryption":   spec.Options["encryption"],
	}
	// Copy only known obfuscation options from untrusted links. Normalize
	// the three password aliases to one vault key.
	values["obfs"] = spec.Options["obfs"]
	for _, key := range []string{"obfs_param", "obfs-password", "obfs_password"} {
		if value := spec.Options[key]; value != "" {
			values["obfs_param"] = value
			break
		}
	}
	// Hysteria2 performance tuning: bandwidth caps enable Brutal congestion
	// control in the engines instead of BBR. Hop ports arrive as mport
	// (official hy2 links) or ports (mihomo-style links).
	values["upmbps"] = spec.Options["upmbps"]
	values["downmbps"] = spec.Options["downmbps"]
	for _, key := range []string{"mport", "ports"} {
		if value := spec.Options[key]; value != "" {
			values["hop_ports"] = value
			break
		}
	}
	for _, key := range []string{"hop-interval", "hopinterval"} {
		if value := spec.Options[key]; value != "" {
			values["hop_interval"] = value
			break
		}
	}
	// TUIC tuning and the v4 token.
	values["congestion_control"] = spec.Options["congestion_control"]
	values["udp_relay_mode"] = spec.Options["udp_relay_mode"]
	values["token"] = spec.Options["token"]
	if strings.EqualFold(spec.Protocol, "wireguard") {
		key, addresses, peers := wireguardMaterial(spec)
		values["private_key"] = key
		values["addresses"] = strings.Join(addresses, ",")
		if len(peers) > 0 {
			raw, err := json.Marshal(peers)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
			}
			values["peers"] = string(raw)
		}
		if awg := amneziaMaterial(spec.Options); len(awg) > 0 {
			raw, err := json.Marshal(awg)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
			}
			values["amneziawg"] = string(raw)
		}
	}
	if spec.AllowInsecure {
		values["insecure"] = "1"
	}
	if profile := spec.Options["profile"]; profile != "" {
		packed, err := packProfile(profile)
		if err != nil {
			return nil, err
		}
		values["xray_profile"] = packed
	}
	for key, value := range values {
		if value == "" {
			delete(values, key)
		}
	}
	document, err := json.Marshal(values)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return document, nil
}

func kinds(names []string) []engine.Kind {
	out := make([]engine.Kind, 0, len(names))
	for _, n := range names {
		out = append(out, engine.Kind(n))
	}
	return out
}

// planFromProto validates the request's outbounds and limits, then resolves
// credential references into the engine plan. Credentials remain inside the
// core.
func planFromProto(in *corev1.SessionPlan, sessionID string, secrets resolver) (*engine.Plan, error) {
	if in == nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanEmpty, "control: the request carries no plan")
	}
	if len(in.GetOutbounds()) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanEmpty, "control: the plan has no outbounds")
	}
	if len(in.GetOutbounds()) > engine.MaxOutbounds {
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyPlanTooLarge,
			"control: the plan carries %d outbounds, the limit is %d", len(in.GetOutbounds()), engine.MaxOutbounds)
	}
	if len(in.GetRoutes()) > engine.MaxRules {
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyPlanTooLarge,
			"control: the plan carries %d rules, the limit is %d", len(in.GetRoutes()), engine.MaxRules)
	}
	// session_identity is a reserved contract field the core does not
	// implement; accepting it would lie to the client about the session.
	if id := strings.TrimSpace(in.GetSessionIdentity()); id != "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: session_identity is not implemented")
	}

	defences := in.GetAntiCensorship()
	plan := &engine.Plan{
		SessionID: sessionID,
		Engines:   kinds(in.GetEngines()),
		// Keep engines at debug level so capture-level changes apply
		// immediately without restarting connections.
		Options: engine.Options{Mode: "rule", LogLevel: "debug", TestURL: engine.TestURLProduction, IPv6: in.GetIpv6(), Fragment: engine.Fragment{
			Enabled:  defences.GetTlsFragment(),
			Packets:  defences.GetFragmentPackets(),
			Length:   defences.GetFragmentLength(),
			Interval: defences.GetFragmentInterval(),
		}},
		// A TUN adapter needs routes to carry traffic.
		Tun: engine.Tun{
			Enabled:    in.GetTunnelMode() == corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
			Stack:      in.GetTunStack(),
			AutoRoute:  true,
			DeviceName: engine.TunDevice,
			// Windows races DNS across adapters; strict routing
			// blocks other adapters' DNS to prevent leaks.
			StrictRoute: runtime.GOOS == "windows",
		},
		PrivateControl: !in.GetNetworkControlAllowed(),
	}
	if plan.Tun.Stack != "" && !plan.Tun.Enabled {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanTunnel, "control: selecting a stack requires TUN mode")
	}
	// System proxy mode requires the configured listener and cannot use
	// proxy authentication.
	local := in.GetLocalProxy()
	plan.LocalProxy = engine.LocalProxy{
		Enabled:  local.GetEnabled() || !plan.Tun.Enabled,
		Username: local.GetUsername(),
		Password: local.GetPassword(),
	}
	if !plan.Tun.Enabled && local.GetUsername() != "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanLocalProxy,
			"control: the system proxy cannot carry a login for the local proxy")
	}
	if (local.GetUsername() == "") != (local.GetPassword() == "") {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanLocalProxy,
			"control: the local proxy login needs both a username and a password")
	}
	seen := make(map[string]struct{}, len(in.GetOutbounds()))
	for index, spec := range in.GetOutbounds() {
		outbound, err := outboundFromProto(index, spec, secrets)
		if err != nil {
			return nil, err
		}
		if _, duplicate := seen[outbound.ID]; duplicate {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanDuplicateID,
				"control: two outbounds share the id %q", outbound.ID)
		}
		seen[outbound.ID] = struct{}{}
		plan.Outbounds = append(plan.Outbounds, outbound)
	}
	if mode := in.GetTunnelMode(); mode == corev1.TunnelMode_TUNNEL_MODE_UNSPECIFIED {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanTunnel,
			"control: the plan does not say which tunnel it wants")
	}
	groups, err := groupsFromProto(in.GetGroups(), seen)
	if err != nil {
		return nil, err
	}
	plan.Groups = groups
	for _, g := range groups {
		seen[g.Name] = struct{}{}
	}
	// Derive rule types from destinations so the contract's
	// destination/target pairs have consistent semantics across engines.
	for _, route := range in.GetRoutes() {
		rule, err := ruleFromProto(route)
		if err != nil {
			return nil, err
		}
		if _, ok := seen[rule.Target]; !ok && !isBuiltInTarget(rule.Target) {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanUnknownTarget,
				"control: rule %q points at %q, which is not in this plan", rule.Value, rule.Target)
		}
		plan.Rules = append(plan.Rules, rule)
	}
	routingOpts := in.GetRouting()
	if target := routingOpts.GetProxyTarget(); target != "" {
		if _, ok := seen[target]; !ok {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanUnknownTarget,
				"control: the routing target %q is not an outbound or a group of this plan", target)
		}
	}
	plan.Rules, err = routing.Apply(plan.Rules, routing.Options{
		Preset: routingOpts.GetPreset(), ProxyTarget: routingOpts.GetProxyTarget(), BlockAds: routingOpts.GetBlockAds(),
	})
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyPlanRuleInvalid)
	}
	// block_private is a contract field no engine implements; accepting it
	// would let a client believe private DNS answers are filtered while the
	// core resolves them plainly.
	if in.GetDnsPolicy().GetBlockPrivate() {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanDNSInvalid,
			"control: dns block_private is not implemented")
	}
	plan.DNS = dnsFromProto(in.GetDnsPolicy(), plan.Tun.Enabled)
	if err := checkDNS(plan.DNS); err != nil {
		return nil, err
	}
	// Proxy chains (1.10): ordered outbound ids, traffic enters the first
	// and exits the last.
	if chain := in.GetChain(); len(chain) > 0 {
		if err := applyChain(plan, chain); err != nil {
			return nil, err
		}
	}
	// zapret alongside the VPN tunnel (1.10, F11): direct traffic gets
	// DPI-resistant handshakes while the tunnel carries the rest.
	if in.GetZapretWithVpn() {
		if err := applyZapretWithVPN(plan, in.GetZapretStrategy()); err != nil {
			return nil, err
		}
	}
	for _, entry := range in.GetBypassSettings().GetRules() {
		if err := checkBypass(entry); err != nil {
			return nil, err
		}
	}
	if err := plan.Validate(); err != nil {
		return nil, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyPlanGroupsInvalid)
	}
	return plan, nil
}

// groupTypes maps the contract's group types onto the plan's.
var groupTypes = map[corev1.GroupType]engine.GroupType{
	corev1.GroupType_GROUP_TYPE_SELECT:       engine.GroupSelect,
	corev1.GroupType_GROUP_TYPE_URL_TEST:     engine.GroupURLTest,
	corev1.GroupType_GROUP_TYPE_FALLBACK:     engine.GroupFallback,
	corev1.GroupType_GROUP_TYPE_LOAD_BALANCE: engine.GroupLoadBalance,
}

// groupsFromProto converts groups after collecting all names, allowing forward
// references. Plan validation rejects cycles.
func groupsFromProto(in []*corev1.GroupSpec, outbounds map[string]struct{}) ([]engine.Group, error) {
	if len(in) > engine.MaxGroups {
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyPlanTooLarge,
			"control: the plan carries %d groups, the limit is %d", len(in), engine.MaxGroups)
	}
	names := make(map[string]struct{}, len(in))
	out := make([]engine.Group, 0, len(in))
	for _, spec := range in {
		name := strings.TrimSpace(spec.GetName())
		kind, ok := groupTypes[spec.GetType()]
		switch {
		case name == "":
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanGroupsInvalid, "control: a group has no name")
		case !ok:
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanGroupsInvalid, "control: group %q has no type", name)
		}
		if _, clash := outbounds[name]; clash {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanGroupsInvalid, "control: group %q has the id of an outbound", name)
		}
		if _, dup := names[name]; dup {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanGroupsInvalid, "control: two groups are named %q", name)
		}
		names[name] = struct{}{}
		group := engine.Group{Name: name, Type: kind, Outbounds: spec.GetMembers(), URL: spec.GetTestUrl(), Tolerance: int(min(spec.GetToleranceMs(), 60000))}
		if d := spec.GetTestInterval(); d != nil {
			group.Interval = int(min(max(d.AsDuration(), time.Minute), 24*time.Hour) / time.Second)
		}
		out = append(out, group)
	}
	for _, g := range out {
		for _, member := range g.Outbounds {
			_, isOutbound := outbounds[member]
			_, isGroup := names[member]
			if !isOutbound && !isGroup && !isBuiltInTarget(member) {
				return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanGroupsInvalid,
					"control: group %q names %q, which is not in this plan", g.Name, member)
			}
		}
	}
	return out, nil
}

// isBuiltInTarget reports whether a target is provided by the engine instead of
// the plan.
func isBuiltInTarget(target string) bool {
	switch target {
	case "direct", "block", "reject":
		return true
	default:
		return false
	}
}

// applyChain links ordered outbound ids so each dials through the next:
// traffic enters chain[0] and exits the last hop.
func applyChain(plan *engine.Plan, chain []string) error {
	if len(chain) < 2 || len(chain) > engine.MaxChainHops {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
			"control: a proxy chain needs 2 to %d servers, got %d", engine.MaxChainHops, len(chain))
	}
	byID := make(map[string]int, len(plan.Outbounds))
	for i := range plan.Outbounds {
		byID[plan.Outbounds[i].ID] = i
	}
	seen := make(map[string]bool, len(chain))
	for i, id := range chain {
		if seen[id] {
			return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
				"control: the proxy chain repeats %q", id)
		}
		seen[id] = true
		idx, ok := byID[id]
		if !ok {
			return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanUnknownTarget,
				"control: the proxy chain names %q, which is not an outbound of this plan", id)
		}
		if i+1 < len(chain) {
			plan.Outbounds[idx].Via = chain[i+1]
		}
	}
	return nil
}

// zapretDirectOutboundID is the synthetic bypass outbound carrying direct
// traffic when zapret runs alongside the VPN tunnel (F11).
const zapretDirectOutboundID = "sora-zapret-direct"

// defaultZapretStrategy shapes direct traffic when the client enables
// zapret_with_vpn without sending its own strategy: the modern
// nfqws/winws desync set (fake, split2, disorder2, multisplit with
// autottl over TCP 80/443 and UDP 443, TLS and QUIC). It needs the nfqws
// backend; see core/engine/bypass/NFQWS-MIGRATION.md.
var defaultZapretStrategy = bypass.DefaultStrategy()

// applyZapretWithVPN routes direct traffic through zapret's tpws while the
// VPN tunnel carries the rest (F11). It appends a synthetic bypass outbound
// and retargets "direct" rules at it; the engine factory then wraps the plan
// with the tpws supervisor, failing honestly when tpws is not installed.
func applyZapretWithVPN(plan *engine.Plan, strategy *corev1.BypassStrategy) error {
	if !plan.Tun.Enabled {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanTunnel,
			"control: zapret_with_vpn needs TUN mode")
	}
	if runtime.GOOS != "linux" {
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing,
			"control: zapret_with_vpn runs on Linux, where tpws is shipped")
	}
	for _, o := range plan.Outbounds {
		if o.ID == zapretDirectOutboundID {
			return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanDuplicateID,
				"control: outbound id %q is reserved for zapret", zapretDirectOutboundID)
		}
	}
	bs := defaultZapretStrategy
	if strategy != nil {
		bs = engine.BypassStrategy{
			SplitPos: strategy.GetSplitPos(), Disorder: strategy.GetDisorder(), OOB: strategy.GetOob(),
			TLSRecord: strategy.GetTlsRecord(), HostCase: strategy.GetHostCase(),
			DomainCase: strategy.GetDomainCase(), MethodEOL: strategy.GetMethodEol(),
		}
	}
	plan.Outbounds = append(plan.Outbounds, engine.Outbound{
		ID: zapretDirectOutboundID, Name: "Zapret (direct traffic)",
		Protocol: engine.ProtocolBypass, Bypass: &bs,
	})
	for i := range plan.Rules {
		if plan.Rules[i].Target == "direct" {
			plan.Rules[i].Target = zapretDirectOutboundID
		}
	}
	return nil
}

// checkDNS validates resolvers and returns a problem-specific error key.
func checkDNS(dns engine.DNS) error {
	for _, server := range dns.Servers {
		if server.Address == "" {
			return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanDNSInvalid,
				"control: a resolver has no address")
		}
	}
	return nil
}

// checkBypass refuses an entry that is not a domain, an address or a network.
func checkBypass(entry string) error {
	trimmed := strings.TrimSpace(entry)
	if trimmed == "" {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanBypassInvalid,
			"control: a bypass entry is empty")
	}
	if strings.ContainsAny(trimmed, " \t\r\n") {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanBypassInvalid,
			"control: a bypass entry holds whitespace")
	}
	return nil
}

// outboundFromProto converts one outbound and resolves its credential
// reference.
func outboundFromProto(index int, spec *corev1.OutboundSpec, secrets resolver) (engine.Outbound, error) {
	id := strings.TrimSpace(spec.GetId())
	if id == "" {
		return engine.Outbound{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
			"control: outbound %d has no id", index)
	}
	port := spec.GetEndpoint().GetPort()
	if port > 0xffff {
		return engine.Outbound{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
			"control: outbound %q has port %d, which is not a port", id, port)
	}
	outbound := engine.Outbound{
		ID:       id,
		Name:     spec.GetDisplayName(),
		Protocol: engine.Protocol(spec.GetProtocol()),
		Server:   spec.GetEndpoint().GetHost(),
		Port:     uint16(port),
		Transport: engine.Transport{
			Type: orDefault(spec.GetTransport(), "tcp"),
		},
		TLS: engine.TLS{Enabled: !strings.EqualFold(spec.GetSecurity(), "none")},
	}
	if outbound.Name == "" {
		outbound.Name = id
	}
	if b := spec.GetBypass(); b != nil {
		outbound.Bypass = &engine.BypassStrategy{
			SplitPos: b.GetSplitPos(), Disorder: b.GetDisorder(), OOB: b.GetOob(), TLSRecord: b.GetTlsRecord(),
			HostCase: b.GetHostCase(), DomainCase: b.GetDomainCase(), MethodEOL: b.GetMethodEol(),
		}
	}
	if reference := spec.GetCredentials().GetReference(); reference != "" {
		if secrets == nil {
			return engine.Outbound{}, errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
				"control: outbound %q needs a secret but the core has no store", id)
		}
		material, err := secrets.Get(reference)
		if err != nil {
			return engine.Outbound{}, errs.Wrap(err, errs.CodeNotFound, errs.KeySecretNotFound)
		}
		values, err := parseCredential(material)
		if err != nil {
			return engine.Outbound{}, err
		}
		if err := applyCredential(&outbound, values); err != nil {
			return engine.Outbound{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
				"control: outbound %q: %v", id, err)
		}
	}
	return outbound, nil
}

// atoiNonNegative parses an optional tuning value from a credential
// document. Garbage and negatives become "unset" so a malformed link
// parameter cannot wedge the engine config; hard validation happens in
// engine.Outbound.Validate.
func atoiNonNegative(s string) int {
	n, err := strconv.Atoi(strings.TrimSpace(s))
	if err != nil || n < 0 {
		return 0
	}
	return n
}

// applyCredential restores only fields written by credentialDocument from
// stored material.
func applyCredential(outbound *engine.Outbound, values map[string]string) error {
	outbound.UUID = values["uuid"]
	outbound.Password = values["password"]
	outbound.Cipher = values["method"]
	outbound.UserID = values["user"]
	outbound.Flow = values["flow"]
	outbound.Obfs = values["obfs"]
	outbound.ObfsParam = values["obfs_param"]
	outbound.UpMbps = atoiNonNegative(values["upmbps"])
	outbound.DownMbps = atoiNonNegative(values["downmbps"])
	outbound.HopPorts = values["hop_ports"]
	outbound.HopInterval = atoiNonNegative(values["hop_interval"])
	outbound.CongestionControl = values["congestion_control"]
	outbound.UDPRelayMode = values["udp_relay_mode"]
	outbound.Token = values["token"]
	outbound.PublicKey = values["public_key"]
	outbound.ShortID = values["short_id"]
	outbound.Encryption = values["encryption"]
	outbound.TLS.ServerName = values["server_name"]
	outbound.TLS.Fingerprint = values["fingerprint"]
	if insecure, ok := values["insecure"]; ok {
		outbound.TLS.Insecure = insecure == "1" || strings.EqualFold(insecure, "true")
	}
	if alpn := values["alpn"]; alpn != "" {
		outbound.TLS.ALPN = strings.Split(alpn, ",")
	}
	// REALITY requires its public key and short ID in the engine's TLS
	// block.
	if strings.EqualFold(values["security"], "reality") {
		outbound.TLS.Enabled = true
		outbound.TLS.Reality = true
		outbound.TLS.RealityPublicKey = values["public_key"]
		outbound.TLS.RealityShortID = values["short_id"]
		outbound.TLS.SpiderX = values["spider_x"]
	}
	outbound.Transport.Path = values["path"]
	outbound.Transport.Host = values["host_header"]
	outbound.Transport.Service = values["service_name"]
	outbound.Transport.Mode = values["mode"]
	outbound.PrivateKey = values["private_key"]
	if addresses := values["addresses"]; addresses != "" {
		outbound.Addresses = strings.Split(addresses, ",")
	}
	if peers := values["peers"]; peers != "" {
		// Fail closed: a broken peer document must not silently become a
		// peerless outbound (SORA-L17).
		if err := json.Unmarshal([]byte(peers), &outbound.Peers); err != nil {
			return fmt.Errorf("invalid WireGuard peers: %w", err)
		}
	}
	if packed := values["xray_profile"]; packed != "" {
		profile, err := unpackProfile(packed)
		if err != nil {
			return err
		}
		outbound.Profile = profile
	}
	if raw := values["amneziawg"]; raw != "" {
		awg, err := amneziaFrom(raw)
		if err != nil {
			return err
		}
		outbound.Amnezia = awg
	}
	return nil
}

// amneziaKeys lists supported AmneziaWG parameters using the parser's lowercase
// interface keys.
var amneziaKeys = []string{"jc", "jmin", "jmax", "s1", "s2", "s3", "s4", "h1", "h2", "h3", "h4",
	"i1", "i2", "i3", "i4", "i5", "j1", "j2", "j3", "itime"}

// amneziaMaterial copies only known AmneziaWG keys from an untrusted import.
func amneziaMaterial(options map[string]string) map[string]string {
	out := map[string]string{}
	for _, key := range amneziaKeys {
		if v := strings.TrimSpace(options[key]); v != "" {
			out[key] = v
		}
	}
	return out
}

// amneziaFrom restores AmneziaWG parameters and rejects invalid numeric values.
func amneziaFrom(raw string) (*engine.AmneziaWG, error) {
	var v map[string]string
	if err := json.Unmarshal([]byte(raw), &v); err != nil {
		return nil, err
	}
	number := func(key string) (int, error) {
		if v[key] == "" {
			return 0, nil
		}
		n, err := strconv.Atoi(v[key])
		if err != nil {
			return 0, fmt.Errorf("amneziawg %s: %q is not a number", key, v[key])
		}
		return n, nil
	}
	a := &engine.AmneziaWG{H1: v["h1"], H2: v["h2"], H3: v["h3"], H4: v["h4"],
		I1: v["i1"], I2: v["i2"], I3: v["i3"], I4: v["i4"], I5: v["i5"], J1: v["j1"], J2: v["j2"], J3: v["j3"]}
	for key, field := range map[string]*int{"jc": &a.Jc, "jmin": &a.Jmin, "jmax": &a.Jmax,
		"s1": &a.S1, "s2": &a.S2, "s3": &a.S3, "s4": &a.S4, "itime": &a.Itime} {
		n, err := number(key)
		if err != nil {
			return nil, err
		}
		*field = n
	}
	return a, nil
}

// wireguardMaterial collects keys, addresses, and peers from .conf sections or
// wireguard:// user info and query fields.
func wireguardMaterial(spec parser.OutboundSpec) (key string, addresses []string, peers []engine.WireGuardPeer) {
	key = spec.Options["privatekey"]
	if key == "" {
		// A malformed escape must not silently empty the key: keep the
		// raw password so the engine reports the real format problem.
		if unescaped, err := url.PathUnescape(spec.Password); err == nil {
			key = unescaped
		} else {
			key = spec.Password
		}
	}
	for _, a := range strings.Split(spec.Options["address"], ",") {
		a = strings.TrimSpace(a)
		switch {
		case a == "":
			continue
		case !strings.Contains(a, "/") && strings.Contains(a, ":"):
			a += "/128"
		case !strings.Contains(a, "/"):
			a += "/32"
		}
		addresses = append(addresses, a)
	}
	split := func(list []string) []string {
		var out []string
		for _, v := range list {
			if v = strings.TrimSpace(v); v != "" {
				out = append(out, v)
			}
		}
		return out
	}
	for _, p := range spec.Peers {
		peers = append(peers, engine.WireGuardPeer{
			PublicKey: p.PublicKey, PreSharedKey: p.PreSharedKey, Endpoint: p.Endpoint,
			AllowedIPs: split(p.AllowedIPs), PersistentKeepalive: p.PersistentKeepalive,
		})
	}
	if len(peers) == 0 && spec.Options["publickey"] != "" {
		peers = append(peers, engine.WireGuardPeer{
			PublicKey:    spec.Options["publickey"],
			PreSharedKey: spec.Options["presharedkey"],
			Endpoint:     net.JoinHostPort(spec.Host, strconv.Itoa(int(spec.Port))),
			AllowedIPs:   split(strings.Split(spec.Options["allowedips"], ",")),
		})
	}
	return key, addresses, peers
}

// ruleFromProto converts one routing rule.
func ruleFromProto(route *corev1.RoutingRule) (engine.Rule, error) {
	destination := strings.TrimSpace(route.GetDestination())
	if destination == "" {
		return engine.Rule{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanRuleInvalid,
			"control: a rule has no destination")
	}
	target := strings.TrimSpace(route.GetOutboundId())
	if target == "" {
		return engine.Rule{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanRuleInvalid,
			"control: rule %q has no target", destination)
	}
	kind := ruleTypeOf(destination)
	value := ruleValue(kind, destination)
	if kind == engine.RuleDomain || kind == engine.RuleDomainSuffix {
		ascii, err := ruleIDNA.ToASCII(value)
		if err != nil {
			return engine.Rule{}, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyPlanRuleInvalid)
		}
		value = ascii
	}
	return engine.Rule{Type: kind, Value: value, Target: target}, nil
}

// Convert only exact and suffix domains, preserving process names and patterns.
var ruleIDNA = idna.New(idna.MapForLookup(), idna.StrictDomainName(true), idna.ValidateLabels(true), idna.VerifyDNSLength(true), idna.BidiRule())

// ruleValue strips the type prefix: the engines add their own.
func ruleValue(kind engine.RuleType, destination string) string {
	if prefix, ok := rulePrefixes[kind]; ok {
		return strings.TrimPrefix(destination, prefix)
	}
	return destination
}

// rulePrefixes follows Xray syntax: "domain:" includes subdomains; "full:"
// matches one exact name.
var rulePrefixes = map[engine.RuleType]string{
	engine.RuleGeoSite:      "geosite:",
	engine.RuleGeoIP:        "geoip:",
	engine.RuleRuleSet:      "ruleset:",
	engine.RuleDomainSuffix: "domain:",
	engine.RuleDomain:       "full:",
	engine.RuleProcess:      "process:",
}

// ruleTypeOf derives the rule type from the shape of a destination.
func ruleTypeOf(destination string) engine.RuleType {
	switch {
	case strings.HasPrefix(destination, "geosite:"):
		return engine.RuleGeoSite
	case strings.HasPrefix(destination, "geoip:"):
		return engine.RuleGeoIP
	case strings.HasPrefix(destination, "ruleset:"):
		return engine.RuleRuleSet
	case strings.HasPrefix(destination, "domain:"):
		return engine.RuleDomainSuffix
	case strings.HasPrefix(destination, "full:"):
		return engine.RuleDomain
	case strings.HasPrefix(destination, "process:"):
		return engine.RuleProcess
	case strings.Contains(destination, "/"):
		return engine.RuleIPCIDR
	default:
		// An IP literal is an IP rule even though IPv6 literals contain
		// colons; only a bare number is a port (SORA-M14).
		if addr, err := netip.ParseAddr(destination); err == nil && addr.IsValid() {
			return engine.RuleIPCIDR
		}
		if _, err := strconv.Atoi(destination); err == nil {
			return engine.RulePort
		}
		return engine.RuleDomainKeyword
	}
}

// defaultTunResolvers supplies DNS for TUN plans without resolvers.
// Address-based DNS over HTTPS avoids bootstrap resolution and encrypts
// lookups.
var defaultTunResolvers = []string{"https://1.1.1.1/dns-query", "https://8.8.8.8/dns-query"}

// dnsFromProto converts the resolver settings of a request.
func dnsFromProto(policy *corev1.DnsPolicy, tun bool) engine.DNS {
	servers := policy.GetServers()
	if len(servers) == 0 && tun {
		servers = defaultTunResolvers
	}
	if len(servers) == 0 {
		return engine.DNS{}
	}
	out := engine.DNS{
		Enabled: true,
		Mode:    "rule",
		Sniff:   true,
	}
	for index, address := range servers {
		if len(out.Servers) >= engine.MaxDNSServers {
			break
		}
		host, port, transport := splitDNSServer(address)
		out.Servers = append(out.Servers, engine.DNSServer{
			Tag:       "dns-" + strconv.Itoa(index),
			Transport: transport,
			Address:   host,
			Port:      port,
		})
	}
	return out
}

// splitDNSServer splits a resolver such as "tls://dns.example.com:853". Invalid
// numeric ports leave the address unchanged.
func splitDNSServer(address string) (host string, port uint16, transport engine.DNSTransport) {
	transport = engine.DNSPlain
	rest := strings.TrimSpace(address)
	for _, candidate := range []struct {
		prefix    string
		transport engine.DNSTransport
	}{
		{"https://", engine.DNSHTTPS},
		{"h3://", engine.DNSH3},
		{"tls://", engine.DNSTLS},
		{"tcp://", engine.DNSTCP},
		{"quic://", engine.DNSQUIC},
	} {
		if strings.HasPrefix(strings.ToLower(rest), candidate.prefix) {
			transport = candidate.transport
			rest = rest[len(candidate.prefix):]
			break
		}
	}
	rest = strings.TrimSuffix(rest, "/dns-query")
	// Prefer net.SplitHostPort for host:port and [ipv6]:port; a naive cut
	// on the first colon mangles IPv6 literals (SORA-M13).
	if host, portStr, err := net.SplitHostPort(rest); err == nil {
		if parsed, err := strconv.ParseUint(portStr, 10, 16); err == nil {
			return host, uint16(parsed), transport
		}
		return rest, 0, transport
	}
	// Fall back to a trailing :port for bare names and addresses. A bare
	// IPv6 literal holds more than one colon and must stay whole.
	if i := strings.LastIndexByte(rest, ':'); i >= 0 && !strings.Contains(rest[:i], ":") {
		if parsed, err := strconv.ParseUint(rest[i+1:], 10, 16); err == nil {
			return rest[:i], uint16(parsed), transport
		}
	}
	return rest, 0, transport
}

// orDefault returns value when it is not empty and fallback otherwise.
func orDefault(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}

// referenceOf derives a stable secret reference from server identity.
// Re-imports overwrite credentials instead of accumulating duplicate entries
// that cannot be safely removed.
func referenceOf(spec parser.OutboundSpec) (string, error) {
	sum := sha256.Sum256([]byte(spec.StableKey()))
	// The digest avoids exposing host or server names in references that
	// may be stored or logged.
	return "s1_" + hex.EncodeToString(sum[:16]), nil
}

// outboundToProto converts a parsed server for the client, exposing only a
// credential reference. The core resolves it when applying the plan.
func outboundToProto(spec parser.OutboundSpec, reference string) *corev1.OutboundSpec {
	return &corev1.OutboundSpec{
		Id:              spec.StableKey(),
		DisplayName:     spec.DisplayName,
		Protocol:        spec.Protocol,
		DisplayProtocol: spec.DisplayProtocol,
		Transport:       spec.Transport,
		Security:        spec.Security,
		Endpoint:        &corev1.Endpoint{Host: spec.Host, Port: uint32(spec.Port)},
		Credentials:     &corev1.CredentialsRef{Reference: reference},
	}
}

// packProfile compresses provider configuration to fit the secret store's 64
// KiB entry limit.
func packProfile(profile string) (string, error) {
	var b bytes.Buffer
	w := gzip.NewWriter(&b)
	if _, err := w.Write([]byte(profile)); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	if err := w.Close(); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return base64.StdEncoding.EncodeToString(b.Bytes()), nil
}

// unpackProfile decompresses a stored profile and rejects output above the plan
// limit before reading it all into memory.
func unpackProfile(packed string) (json.RawMessage, error) {
	raw, err := base64.StdEncoding.DecodeString(packed)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyPlanOutbounds)
	}
	r, err := gzip.NewReader(bytes.NewReader(raw))
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyPlanOutbounds)
	}
	profile, err := io.ReadAll(io.LimitReader(r, MaxPlanBytes+1))
	if err != nil || len(profile) > MaxPlanBytes {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds, "control: a stored Xray profile is unreadable or too large")
	}
	return profile, nil
}
