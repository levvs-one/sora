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
	"github.com/levvs-one/sora-client/core/engine/olcwrap"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/ext"
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
	// ProbeChunkSize is the probe pipeline's chunk unit: ProbeServers splits
	// every request into chunks of at most this many servers and streams
	// each chunk's results as they complete, so probing thousands of
	// servers degrades into a longer stream instead of dying on a
	// per-request limit. Clients should likewise split large probes into
	// chunks of at most ProbeChunkSize: with 2x margin under the historic
	// 256 cap every chunk stays a small request message with a short,
	// cancellable stream.
	ProbeChunkSize = 128
	// MaxProbeEndpoints is the largest number of endpoints one probe
	// request may carry. It is a fail-fast safety bound only: below it the
	// server chunks the work itself (see ProbeChunkSize), above it the
	// request is rejected before anything is allocated. 4096 typical
	// outbound specs still fit under the 5 MiB gRPC receive limit
	// (MaxRecvMsgBytes).
	MaxProbeEndpoints = 4096
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
//
// The document is written field by field in sorted key order instead of
// through a map[string]string and json.Marshal: the map version cost
// ~1.9 KB and 22 allocations per server on the import/refresh path
// (bucket growth, key sorting, reflective marshal), the builder below
// needs one grown buffer. The output is byte-identical to
// json.Marshal of the same map — keys sorted, empty values omitted,
// strings escaped exactly as encoding/json escapes them — so stored
// documents and downgrade readers see no change.
func credentialDocument(spec parser.OutboundSpec) ([]byte, error) {
	// Copy only known obfuscation options from untrusted links. Normalize
	// the three password aliases to one vault key.
	firstOpt := func(keys ...string) string {
		for _, key := range keys {
			if value := spec.Options[key]; value != "" {
				return value
			}
		}
		return ""
	}
	obfsParam := firstOpt("obfs_param", "obfs-password", "obfs_password")
	// Hysteria2 performance tuning: bandwidth caps enable Brutal congestion
	// control in the engines instead of BBR. Hop ports arrive as mport
	// (official hy2 links) or ports (mihomo-style links).
	hopPorts := firstOpt("mport", "ports")
	hopInterval := firstOpt("hop-interval", "hopinterval")
	hopIntervalMax := firstOpt("hop-interval-max", "hopintervalmax")
	bbrProfile := firstOpt("bbr-profile", "bbr_profile")
	var privateKey, addresses, peers, amnezia string
	if strings.EqualFold(spec.Protocol, "wireguard") {
		key, addrs, wpeers := wireguardMaterial(spec)
		privateKey, addresses = key, strings.Join(addrs, ",")
		if len(wpeers) > 0 {
			raw, err := json.Marshal(wpeers)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
			}
			peers = string(raw)
		}
		if awg := amneziaMaterial(spec.Options); len(awg) > 0 {
			raw, err := json.Marshal(awg)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
			}
			amnezia = string(raw)
		}
	}
	// OpenLibre (olcrtc): the whole server definition rides the
	// document — provider, room, transport and every transport
	// parameter of the link — because the proto contract carries
	// only a room-shaped endpoint and the key (as "password"). Without
	// this block an imported olcrtc server lost everything but the
	// room and the key at the first restart (IMPORT.md blocker).
	var olcProvider, olcRoom, olcTransport, olcChannel, olcAuthToken, olcMode, olcParams, olcMeta string
	if strings.EqualFold(spec.Protocol, "olcrtc") {
		olcProvider = spec.Options["olcrtc_provider"]
		olcRoom = spec.Options["olcrtc_room"]
		if olcRoom == "" {
			olcRoom = spec.Host
		}
		olcTransport = spec.Transport
		olcChannel = spec.Options["olcrtc_channel"]
		olcAuthToken = spec.Options["olcrtc_auth_token"]
		olcMode = spec.Options["olcrtc_mode"]
		params := map[string]string{}
		meta := map[string]string{}
		for k, v := range spec.Options {
			switch {
			case k == "olcrtc_provider" || k == "olcrtc_room" || k == "olcrtc_channel" ||
				k == "olcrtc_auth_token" || k == "olcrtc_mode":
				// Carried by their own document fields above.
			case strings.HasPrefix(k, "olcrtc_meta_"):
				meta[strings.TrimPrefix(k, "olcrtc_meta_")] = v
			default:
				params[k] = v
			}
		}
		if len(params) > 0 {
			raw, err := json.Marshal(params)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
			}
			olcParams = string(raw)
		}
		if len(meta) > 0 {
			raw, err := json.Marshal(meta)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
			}
			olcMeta = string(raw)
		}
	}
	insecure := ""
	if spec.AllowInsecure {
		insecure = "1"
	}
	profile := ""
	if p := spec.Options["profile"]; p != "" {
		packed, err := packProfile(p)
		if err != nil {
			return nil, err
		}
		profile = packed
	}

	doc := credentialDoc{buf: make([]byte, 0, 384)}
	doc.buf = append(doc.buf, '{')
	// Sorted key order, mirroring json.Marshal's map key sort.
	doc.field("addresses", addresses)
	doc.field("alpn", strings.Join(spec.ALPN, ","))
	doc.field("amneziawg", amnezia)
	doc.field("bbr_profile", bbrProfile)
	// TUIC tuning and the v4 token.
	doc.field("congestion_control", spec.Options["congestion_control"])
	// XHTTP up/down split from the link's extra= JSON (09-xhttp §4). The
	// tuning travels inside the credential document, not the proto
	// contract, so no contract change is needed.
	doc.field("download_address", spec.DownloadAddress)
	doc.field("download_port", strconv.Itoa(int(spec.DownloadPort)))
	doc.field("downmbps", spec.Options["downmbps"])
	doc.field("encryption", spec.Options["encryption"])
	doc.field("fingerprint", spec.Fingerprint)
	doc.field("flow", spec.Flow)
	// TUIC heartbeat (keepalive) seconds, from the link's heartbeat
	// parameter (CENSOR-P3); restored by applyCredential.
	doc.field("heartbeat", spec.Options["heartbeat"])
	doc.field("hop_interval", hopInterval)
	doc.field("hop_interval_max", hopIntervalMax)
	doc.field("hop_ports", hopPorts)
	doc.field("host_header", spec.HostHeader)
	doc.field("insecure", insecure)
	doc.field("method", spec.Cipher)
	// REALITY ML-DSA-65 verify key (pqv in the link): public key
	// material that identifies the server, stored like the REALITY
	// public key it extends.
	doc.field("mldsa65_verify", spec.MLDSA65Verify)
	doc.field("mode", spec.Mode)
	doc.field("obfs", spec.Options["obfs"])
	doc.field("obfs_param", obfsParam)
	// OpenLibre fields, in the same sorted order (see above).
	doc.field("olcrtc_auth_token", olcAuthToken)
	doc.field("olcrtc_channel", olcChannel)
	doc.field("olcrtc_meta", olcMeta)
	doc.field("olcrtc_mode", olcMode)
	doc.field("olcrtc_params", olcParams)
	doc.field("olcrtc_provider", olcProvider)
	doc.field("olcrtc_room", olcRoom)
	doc.field("olcrtc_transport", olcTransport)
	doc.field("password", spec.Password)
	doc.field("path", spec.Path)
	doc.field("peers", peers)
	doc.field("private_key", privateKey)
	doc.field("public_key", spec.PublicKey)
	doc.field("security", spec.Security)
	doc.field("server_name", spec.ServerName)
	doc.field("service_name", spec.ServiceName)
	doc.field("short_id", spec.ShortID)
	doc.field("spider_x", spec.SpiderX)
	// SIP002 plugin/plugin_opts for Shadowsocks (T020). The raw "plugin"
	// query key stays in Options but is never stored under that name.
	doc.field("ss_plugin", spec.Options["ss_plugin"])
	doc.field("ss_plugin_opts", spec.Options["ss_plugin_opts"])
	doc.field("token", spec.Options["token"])
	doc.field("udp_relay_mode", spec.Options["udp_relay_mode"])
	doc.field("upmbps", spec.Options["upmbps"])
	doc.field("user", spec.User)
	doc.field("uuid", spec.UUID)
	// XHTTP padding range and xmux reuse tuning from the link's
	// extra= JSON (CENSOR-P1), travelling like the download split
	// above; restored by applyCredential into engine.Transport.
	doc.field("x_padding_bytes", spec.XPaddingBytes)
	doc.field("xmux_max_concurrency", itoaNonZero(spec.XmuxMaxConcurrency))
	doc.field("xmux_max_connections", itoaNonZero(spec.XmuxMaxConnections))
	doc.field("xmux_max_request_times", itoaNonZero(spec.XmuxMaxRequestTimes))
	doc.field("xmux_max_reuse_times", itoaNonZero(spec.XmuxMaxReuseTimes))
	doc.field("xray_profile", profile)
	doc.buf = append(doc.buf, '}')
	return doc.buf, nil
}

// credentialDoc accumulates one credential document. field appends a
// "key":"value" pair, skipping empty values exactly like the map version
// did when it deleted empty entries before marshaling.
type credentialDoc struct {
	buf   []byte
	first bool
}

func (d *credentialDoc) field(key, value string) {
	if value == "" {
		return
	}
	if d.first {
		d.buf = append(d.buf, ',')
	}
	d.first = true
	d.buf = appendCredentialString(d.buf, key)
	d.buf = append(d.buf, ':')
	d.buf = appendCredentialString(d.buf, value)
}

// appendCredentialString appends s as a JSON string literal with exactly
// encoding/json's escaping. Printable ASCII that needs no escape (the
// overwhelming norm for credential values) is copied verbatim; anything
// else — quotes, backslashes, the HTML-sensitive <, >, &, control bytes,
// non-ASCII — goes through json.Marshal for that one string, so the
// output matches the old map marshal byte for byte on every input,
// including invalid UTF-8 (which Marshal rewrites to U+FFFD).
func appendCredentialString(buf []byte, s string) []byte {
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c < 0x20 || c > 0x7e || c == '"' || c == '\\' || c == '<' || c == '>' || c == '&' {
			raw, _ := json.Marshal(s)
			return append(buf, raw...)
		}
	}
	buf = append(buf, '"')
	buf = append(buf, s...)
	return append(buf, '"')
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
	plan, _, err := planFromProtoMerged(in, sessionID, secrets, nil)
	return plan, err
}

// planFromProtoMerged is planFromProto plus the Anti-DPI layer merge
// (core/control/bypass_ext.go): layers from enabled extensions granted
// bypass.write are woven in after the zapret handling and the outbound
// assembly, before plan.Validate — the freshest layer's global fills an
// empty zapret strategy, and layer bindings become bypass outbounds
// with routing rules that never override user rules. The returned
// provenance records what the merge did, for GetBypassState. A nil
// layers slice merges nothing and preserves the classic behaviour.
func planFromProtoMerged(in *corev1.SessionPlan, sessionID string, secrets resolver, layers []ext.LayerEntry) (*engine.Plan, *bypassProvenance, error) {
	prov := &bypassProvenance{Source: "none", BuiltAt: time.Now()}
	for _, e := range layers {
		if e.Layer.UpdatedAt.After(prov.NewestLayer) {
			prov.NewestLayer = e.Layer.UpdatedAt
		}
	}
	plan, err := planFromProtoLayers(in, sessionID, secrets, layers, prov)
	if err != nil {
		return nil, nil, err
	}
	return plan, prov, nil
}

func planFromProtoLayers(in *corev1.SessionPlan, sessionID string, secrets resolver, layers []ext.LayerEntry, prov *bypassProvenance) (*engine.Plan, error) {
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
		// Outbounds and rules are known up front: size for the request so
		// large plans do not regrow the slices one power of two at a time.
		Outbounds: make([]engine.Outbound, 0, len(in.GetOutbounds())),
		Rules:     make([]engine.Rule, 0, len(in.GetRoutes())),
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
	// LAN sharing (C7): the listener binds every interface, so it is
	// allowed only in TUN mode and only behind a full login. In the
	// system proxy mode the listener is forced for the OS proxy, which
	// cannot carry a login (the check below keeps refusing that), so an
	// allow_lan request there would open an unauthenticated LAN proxy.
	if local.GetAllowLan() && !plan.Tun.Enabled {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanLocalProxy,
			"control: sharing the local proxy on the local network needs TUN mode; the system proxy cannot carry a login")
	}
	if local.GetAllowLan() && (local.GetUsername() == "" || local.GetPassword() == "") {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanLocalProxy,
			"control: sharing the local proxy on the local network needs both a username and a password")
	}
	plan.Options.AllowLAN = local.GetAllowLan()
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
		if _, ok := seen[rule.Target]; !ok && !engine.IsBuiltInTarget(rule.Target) {
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
	//
	// Anti-DPI layer merge (1.14): an empty request strategy (nil or all
	// fields unset) is "no strategy given", so the freshest layer
	// global fills it and the provenance names that extension; a
	// non-empty request strategy is the user's and always wins. With
	// neither, applyZapretWithVPN's nil path applies the core default.
	if in.GetZapretWithVpn() {
		reqStrategy := in.GetZapretStrategy()
		switch {
		case !ext.IsEmptyBypassStrategy(reqStrategy):
			if err := applyZapretWithVPN(plan, reqStrategy); err != nil {
				return nil, err
			}
			prov.Source, prov.From = "user", ""
		default:
			var globalFrom string
			var globalStrategy *corev1.BypassStrategy
			for _, e := range layers {
				if e.Layer.Global != nil {
					globalFrom, globalStrategy = e.ID, e.Layer.Global
					break // layers arrive freshest first (LayerStore.List)
				}
			}
			if globalStrategy != nil {
				if err := applyZapretWithVPN(plan, globalStrategy); err != nil {
					return nil, err
				}
				prov.Source, prov.From = "extension", globalFrom
			} else {
				if err := applyZapretWithVPN(plan, nil); err != nil {
					return nil, err
				}
				prov.Source, prov.From = "core_default", ""
			}
		}
	}
	for _, entry := range in.GetBypassSettings().GetRules() {
		if err := checkBypass(entry); err != nil {
			return nil, err
		}
	}
	// A broken bypass strategy gets its own key, checked on its own
	// before the plan-wide validation below: plan.Validate joins every
	// failure into one error, and wrapping that join in the groups key
	// told the user the groups were at fault for a strategy the detail
	// named exactly (round-2 E2E). The probe outbound carries only the
	// strategy, so its validation can fail for nothing else — the
	// engine's own strategy rules decide, nothing is re-checked here.
	for _, o := range plan.Outbounds {
		if o.Protocol != engine.ProtocolBypass {
			continue
		}
		probe := engine.Outbound{ID: o.ID, Protocol: engine.ProtocolBypass, Bypass: o.Bypass}
		if err := probe.Validate(); err != nil {
			return nil, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyPlanBypassStrategyInvalid)
		}
	}
	// The OpenLibre connect gates get the same treatment, for the
	// same reason: they are checked on their own before the
	// plan-wide validation below, because that validation joins
	// every failure into one error and the wrap below (or the
	// session layer's outbounds wrap) would leave the gate's
	// specific, localized key visible only inside the generic
	// error's detail — a live Connect answered token_required
	// plans with the generic outbounds key (INTEROP.md).
	// ValidateConnect can fail for nothing but an olcrtc reason and
	// already carries the catalog key and code of the refusal, so
	// its error returns unwrapped, exactly as the engine factory's
	// catalog errors pass through the session layer. The gates do
	// not read the resolver, so ConfigFromOutbound needs none here;
	// the wrapper re-checks them at Apply regardless.
	for _, o := range plan.Outbounds {
		if o.Protocol != engine.ProtocolOLCRTC {
			continue
		}
		if err := olcwrap.ValidateConnect(olcwrap.ConfigFromOutbound(o, "")); err != nil {
			return nil, err
		}
	}
	// Anti-DPI bindings merge (1.14): layer bindings become bypass
	// outbounds plus routing rules, inserted after the user's rules and
	// before the final proxy-target rule. Conflicts with user rules are
	// skipped (the user wins); the merge counts what it applied into
	// the provenance for GetBypassState.
	mergeBypassBindings(plan, in, layers, prov)
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
		group := engine.Group{Name: name, Type: kind, Outbounds: spec.GetMembers(), Selected: strings.TrimSpace(spec.GetSelected()), URL: spec.GetTestUrl(), Tolerance: int(min(spec.GetToleranceMs(), 60000))}
		if d := spec.GetTestInterval(); d != nil {
			group.Interval = int(min(max(d.AsDuration(), time.Minute), 24*time.Hour) / time.Second)
		}
		out = append(out, group)
	}
	for _, g := range out {
		for _, member := range g.Outbounds {
			_, isOutbound := outbounds[member]
			_, isGroup := names[member]
			if !isOutbound && !isGroup && !engine.IsBuiltInTarget(member) {
				return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanGroupsInvalid,
					"control: group %q names %q, which is not in this plan", g.Name, member)
			}
		}
	}
	return out, nil
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

// applyZapretWithVPN runs zapret alongside the VPN tunnel (F11):
// direct traffic gets desync while the tunnel carries the rest.
//
// With an explicit strategy from the client (the proto carries only
// tpws fields, so it always selects tpws) it appends a synthetic
// bypass outbound and retargets "direct" rules at it; the engine
// factory then wraps the plan with the tpws supervisor, failing
// honestly when tpws is not installed.
//
// With no strategy it applies the core's built-in set
// (bypass.DefaultStrategy): the modern nfqws desync set. nfqws works
// at the packet layer, so there is nothing to retarget — the rules
// keep targeting "direct", the engine routes them untouched, and the
// nfqws executor desyncs them below the engine
// (core/engine/bypass/NFQWS-MIGRATION.md §4). The synthetic outbound
// still rides along so the factory wraps the plan and the executor
// starts; if nfqws is not installed, Apply fails closed naming it.
// bypassStrategyFromProto maps every BypassStrategy contract field onto
// the engine strategy. It is the single conversion for both call sites
// (zapret_strategy and a per-outbound bypass) so the two cannot drift
// apart again: the contract once carried only 7 of the engine's 29 fields
// and each site copied just those.
func bypassStrategyFromProto(strategy *corev1.BypassStrategy) engine.BypassStrategy {
	return engine.BypassStrategy{
		SplitPos:         strategy.GetSplitPos(),
		Disorder:         strategy.GetDisorder(),
		DisorderScope:    strategy.GetDisorderScope(),
		OOB:              strategy.GetOob(),
		OOBScope:         strategy.GetOobScope(),
		TLSRecord:        strategy.GetTlsRecord(),
		HostCase:         strategy.GetHostCase(),
		DomainCase:       strategy.GetDomainCase(),
		MethodEOL:        strategy.GetMethodEol(),
		HostDot:          strategy.GetHostDot(),
		HostTab:          strategy.GetHostTab(),
		HostNoSpace:      strategy.GetHostNoSpace(),
		MethodSpace:      strategy.GetMethodSpace(),
		UnixEOL:          strategy.GetUnixEol(),
		SplitAnyProtocol: strategy.GetSplitAnyProtocol(),
		TamperStart:      strategy.GetTamperStart(),
		TamperCutoff:     strategy.GetTamperCutoff(),
		OOBData:          strategy.GetOobData(),
		MSS:              strategy.GetMss(),
		Desync:           strategy.GetDesync(),
		FakeTLS:          strategy.GetFakeTls(),
		FakeQUIC:         strategy.GetFakeQuic(),
		Fooling:          strategy.GetFooling(),
		TTL:              int(strategy.GetTtl()),
		AutoTTL:          strategy.GetAutoTtl(),
		Repeats:          int(strategy.GetRepeats()),
		FilterTCP:        strategy.GetFilterTcp(),
		FilterUDP:        strategy.GetFilterUdp(),
		FilterL7:         strategy.GetFilterL7(),
	}
}

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
	if strategy == nil {
		bs := bypass.DefaultStrategy()
		plan.Outbounds = append(plan.Outbounds, engine.Outbound{
			ID: zapretDirectOutboundID, Name: "Zapret (direct traffic)",
			Protocol: engine.ProtocolBypass, Bypass: &bs,
		})
		return nil
	}
	bs := bypassStrategyFromProto(strategy)
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
	if outbound.Protocol == engine.ProtocolWireGuard {
		// WireGuard has no stream transport: the parser labels its
		// specs "udp" (a datagram protocol, not an engine transport),
		// and custom specs arrive with no transport at all, which the
		// default above turns into "tcp". Both spellings failed plan
		// validation ("unknown transport") or misdescribed the
		// outbound, so a WireGuard server imported from a link or a
		// .conf could never build a plan (B1 servers audit). The
		// engine's WireGuard outbound carries no transport type.
		//
		// Only those producer spellings ("", "tcp", "udp") are
		// normalized. Any other value is not a WireGuard transport
		// at all: an earlier version erased it unconditionally, so
		// wireguard/"bogus", wireguard/"ws" and wireguard/"grpc"
		// silently became valid plans (B1 review). Erasing "ws" or
		// "grpc" cannot be left to plan validation either — both are
		// legitimate transports for other protocols, so the plan
		// whitelist would accept them — hence the honest rejection
		// here, in the converter that knows the protocol.
		switch outbound.Transport.Type {
		case "", "tcp", "udp":
			outbound.Transport.Type = ""
		default:
			return engine.Outbound{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
				"control: outbound %q: wireguard has no stream transport, got %q", id, outbound.Transport.Type)
		}
	}
	if outbound.Name == "" {
		outbound.Name = id
	}
	if b := spec.GetBypass(); b != nil {
		bs := bypassStrategyFromProto(b)
		outbound.Bypass = &bs
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
	if outbound.Protocol == engine.ProtocolOLCRTC {
		// Normalize the contract spelling into the engine's shape,
		// mirroring the WireGuard normalization above: the proto
		// transport carries the olcrtc transport name (datachannel,
		// ...), which is not a stream transport, and the proto
		// security "olc2" names the OLC2 record layer, not TLS. The
		// credential document, when one was resolved, has already
		// filled Olcrtc from its authoritative fields; otherwise the
		// proto fields alone define the (credential-less) config.
		if outbound.Olcrtc == nil {
			outbound.Olcrtc = &engine.OlcrtcConfig{Transport: outbound.Transport.Type, Room: outbound.Server}
		}
		outbound.Transport.Type = ""
		outbound.TLS = engine.TLS{}
		outbound.Server = outbound.Olcrtc.Room
		outbound.Port = 0
	}
	// S2 auto-vision: VLESS + TCP + REALITY/TLS with an empty flow
	// gets xtls-rprx-vision here, at plan level, instead of passing the
	// empty flow through. Trojan is excluded: no engine honours a vision
	// flow for Trojan, and the plan-level flow would suppress Xray mux
	// while never reaching the wire. A manual flow is respected (never
	// overwritten), and the fact is recorded in Outbound.FlowAuto for
	// the UI badge.
	outbound.ApplyAutoVision()
	return outbound, nil
}

// atoiNonNegative parses an optional tuning value from a credential
// document. Garbage and negatives become "unset" so a malformed link
// parameter cannot wedge the engine config; hard validation happens in
// engine.Outbound.Validate.
// itoaNonZero renders a tuning value for the credential document:
// zero means "engine default" and is omitted entirely (doc.field
// skips empty values), so an untuned server document stays
// byte-identical to the form written before the field existed.
func itoaNonZero(v int) string {
	if v == 0 {
		return ""
	}
	return strconv.Itoa(v)
}

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
	outbound.Plugin = values["ss_plugin"]
	outbound.PluginOpts = values["ss_plugin_opts"]
	outbound.UpMbps = atoiNonNegative(values["upmbps"])
	outbound.DownMbps = atoiNonNegative(values["downmbps"])
	outbound.HopPorts = values["hop_ports"]
	outbound.HopInterval = atoiNonNegative(values["hop_interval"])
	outbound.HopIntervalMax = atoiNonNegative(values["hop_interval_max"])
	outbound.BBRProfile = values["bbr_profile"]
	outbound.CongestionControl = values["congestion_control"]
	outbound.UDPRelayMode = values["udp_relay_mode"]
	outbound.TUICHeartbeat = atoiNonNegative(values["heartbeat"])
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
		outbound.TLS.RealityMLDSA65Verify = values["mldsa65_verify"]
		outbound.TLS.SpiderX = values["spider_x"]
	}
	outbound.Transport.Path = values["path"]
	outbound.Transport.Host = values["host_header"]
	outbound.Transport.Service = values["service_name"]
	outbound.Transport.Mode = values["mode"]
	// XHTTP up/down split from the link's extra= JSON (09-xhttp §4): the
	// address rides the credential document; the port is bounded again
	// here so a forged document cannot smuggle an invalid one.
	outbound.Transport.DownloadAddress = values["download_address"]
	if port := atoiNonNegative(values["download_port"]); port <= 65535 {
		outbound.Transport.DownloadPort = uint16(port)
	}
	// XHTTP padding and xmux tuning from the same extra= data
	// (CENSOR-P1); atoiNonNegative keeps a forged document from
	// smuggling negative tuning into the plan.
	outbound.Transport.XPaddingBytes = values["x_padding_bytes"]
	outbound.Transport.XmuxMaxConcurrency = atoiNonNegative(values["xmux_max_concurrency"])
	outbound.Transport.XmuxMaxConnections = atoiNonNegative(values["xmux_max_connections"])
	outbound.Transport.XmuxMaxRequestTimes = atoiNonNegative(values["xmux_max_request_times"])
	outbound.Transport.XmuxMaxReuseTimes = atoiNonNegative(values["xmux_max_reuse_times"])
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
	// OpenLibre: the document is authoritative for the olcrtc
	// configuration (the proto endpoint carries only the room). A
	// document without olcrtc fields leaves the outbound untouched,
	// so non-olcrtc servers restore exactly as before.
	//
	// The guard is symmetric (review remark Z-2): ANY olcrtc
	// configuration field — provider, transport, room, channel,
	// auth token, mode or params — makes the whole block present,
	// and every field is restored. (olcrtc_meta is not a
	// configuration field: subscription metadata rides the document
	// itself and is never restored into a plan config, complete
	// documents included.) credentialDocument writes provider and transport
	// atomically with the rest of the block for every olcrtc server
	// (the parser guarantees both), and there is no honest default
	// provider to invent, so a block that carries only supplementary
	// fields (channel/token/mode/…) has no legitimate producer: it
	// is a broken document and fails closed with a clear error —
	// the same treatment broken WireGuard peers and broken olcrtc
	// params get above — instead of silently dropping the fields it
	// does carry. In particular a lone olcrtc_mode never resurrects
	// a config: "srv" from such a document is refused here, and
	// "srv" in a complete document is refused by validation, so no
	// document shape makes sora run an egress.
	hasOlcrtc := false
	for _, key := range []string{"olcrtc_provider", "olcrtc_transport", "olcrtc_room",
		"olcrtc_channel", "olcrtc_auth_token", "olcrtc_mode", "olcrtc_params"} {
		if values[key] != "" {
			hasOlcrtc = true
			break
		}
	}
	if hasOlcrtc {
		cfg := &engine.OlcrtcConfig{
			Provider:  values["olcrtc_provider"],
			Transport: values["olcrtc_transport"],
			Room:      values["olcrtc_room"],
			Channel:   values["olcrtc_channel"],
			AuthToken: values["olcrtc_auth_token"],
			Mode:      values["olcrtc_mode"],
		}
		if cfg.Room == "" {
			cfg.Room = outbound.Server
		}
		if cfg.Transport == "" && engine.OlcrtcTransports[outbound.Transport.Type] {
			// The proto transport honestly carries the olcrtc
			// transport name for an olcrtc outbound; the "tcp"
			// stream default of other protocols does not, and must
			// not be dressed up as one.
			cfg.Transport = outbound.Transport.Type
		}
		if raw := values["olcrtc_params"]; raw != "" {
			// Fail closed like the WireGuard peers above: a broken
			// parameter document must not silently become a
			// default-tuned tunnel.
			if err := json.Unmarshal([]byte(raw), &cfg.Params); err != nil {
				return fmt.Errorf("invalid olcrtc parameters: %w", err)
			}
		}
		if cfg.Provider == "" || cfg.Transport == "" {
			return fmt.Errorf("incomplete olcrtc credential document: olcrtc fields are present but the provider or transport is missing")
		}
		outbound.Olcrtc = cfg
	}
	return nil
}

// amneziaKeys lists supported AmneziaWG parameters using the parser's lowercase
// interface keys. The 3.1 section (lowercase spellings match the documented
// interface keys on engine.AmneziaWG) was silently dropped here before: a
// 3.1 config imported from a .conf or link lost HeaderProtectionKey and the
// rest on the way to the engine, degrading to 1.x/2.0 behavior without any
// complaint (open Q20 of the first detail pass).
var amneziaKeys = []string{"jc", "jmin", "jmax", "s1", "s2", "s3", "s4", "h1", "h2", "h3", "h4",
	"i1", "i2", "i3", "i4", "i5", "j1", "j2", "j3", "itime",
	"headerprotectionkey", "contentpaddingaddition",
	"rekeyaftertime", "rekeytimeout", "rejectaftertime", "keepalivetimeout",
	"maxhandshakeattempts", "randomtrailers", "disablecookies",
	"masqueradeprotocol", "masqueradedomain", "masqueradebrowser"}

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
	// AmneziaWG 3.1: range/protection values are strings, kept verbatim —
	// the engine validator owns shape checks; two booleans accept the same
	// "1"/"true" spelling the credential parser uses for insecure.
	a.HeaderProtectionKey = v["headerprotectionkey"]
	a.ContentPaddingAddition = v["contentpaddingaddition"]
	a.RekeyAfterTime = v["rekeyaftertime"]
	a.RekeyTimeout = v["rekeytimeout"]
	a.RejectAfterTime = v["rejectaftertime"]
	a.KeepaliveTimeout = v["keepalivetimeout"]
	a.MaxHandshakeAttempts = v["maxhandshakeattempts"]
	truthy := func(s string) bool { return s == "1" || strings.EqualFold(s, "true") }
	a.RandomTrailers = truthy(v["randomtrailers"])
	a.DisableCookies = truthy(v["disablecookies"])
	a.MasqueradeProtocol = v["masqueradeprotocol"]
	a.MasqueradeDomain = v["masqueradedomain"]
	a.MasqueradeBrowser = v["masqueradebrowser"]
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
//
// Flow/FlowAuto carry the EFFECTIVE flow: the link's explicit flow when set,
// otherwise the plan-level auto-vision result (see effectiveFlow). The UI
// badge therefore always agrees with what the engine will put on the wire.
func outboundToProto(spec parser.OutboundSpec, reference string) *corev1.OutboundSpec {
	flow, flowAuto := effectiveFlow(spec)
	return &corev1.OutboundSpec{
		Id:              spec.StableKey(),
		DisplayName:     spec.DisplayName,
		Protocol:        spec.Protocol,
		DisplayProtocol: spec.DisplayProtocol,
		Transport:       spec.Transport,
		Security:        spec.Security,
		Flow:            flow,
		FlowAuto:        flowAuto,
		Endpoint:        &corev1.Endpoint{Host: spec.Host, Port: uint32(spec.Port)},
		Credentials:     &corev1.CredentialsRef{Reference: reference},
	}
}

// effectiveFlow computes the wire-level flow for an imported server. The
// predicate is engine.Outbound.ApplyAutoVision — the very same method
// outboundFromProto applies when assembling the plan — so the UI-level
// value and the plan-level value cannot drift apart: one source of truth.
//
// The inputs mirror outboundFromProto exactly: Flow starts as the link's
// explicit flow (restored from the credential document there), TLS.Enabled
// is security != "none", and REALITY is security == "reality".
func effectiveFlow(spec parser.OutboundSpec) (flow string, auto bool) {
	outbound := engine.Outbound{
		Protocol:  engine.Protocol(spec.Protocol),
		Transport: engine.Transport{Type: orDefault(spec.Transport, "tcp")},
		TLS: engine.TLS{
			Enabled: !strings.EqualFold(spec.Security, "none"),
			Reality: strings.EqualFold(spec.Security, "reality"),
		},
		Flow: spec.Flow,
	}
	outbound.ApplyAutoVision()
	return outbound.Flow, outbound.FlowAuto
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
