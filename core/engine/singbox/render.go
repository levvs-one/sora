package singbox

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"runtime"
	"sort"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Official SagerNet rule sets replace geoip and geosite databases removed in
// sing-box 1.12. sing-box downloads them itself at runtime, so the commit SHA
// pinned into the URL is the only integrity anchor: with a branch tip in the
// URL, compromising either SagerNet repository would silently swap everyone's
// routing rules (A20-16). The refs below are the heads of the rule-set
// branches, pinned 2026-10-20:
//
//	sing-geosite: ea962e34bf255b69f3a66690e4a53900d48b48ea (2026-10-19, "Update rule-set")
//	sing-geoip:   eb32cd6ed4a16fcb3bf9a36ccebf28e45716ae84 (2026-10-12, "Update rule-set")
//
// Source of truth: the "sha" of the head commit at
// https://api.github.com/repos/SagerNet/{sing-geosite,sing-geoip}/commits/rule-set
// (also visible at https://api.github.com/repos/SagerNet/<repo>/branches/rule-set).
// To refresh: take the new head SHAs, verify each serves its files with
//
//	curl -o /dev/null -w "%{http_code}" \
//	  https://raw.githubusercontent.com/<repo>/<sha>/geosite-category-ads-all.srs
//
// (files sit at the branch ROOT, not under a rule-set/ path — the rule-set/
// segment in old URLs was the branch name, which no longer appears once a SHA
// is pinned), then replace the refs below. Refresh cadence: together with the
// geo databases in packaging/engines. The price of pinning is stale data
// between refreshes; the gain is that no third party can move the data under us.
const (
	geoSiteRuleSetRef = "ea962e34bf255b69f3a66690e4a53900d48b48ea" // SagerNet/sing-geosite rule-set @ 2026-10-19
	geoIPRuleSetRef   = "eb32cd6ed4a16fcb3bf9a36ccebf28e45716ae84" // SagerNet/sing-geoip rule-set @ 2026-10-12
)

const (
	geoSiteRuleSetURL = "https://raw.githubusercontent.com/SagerNet/sing-geosite/" + geoSiteRuleSetRef + "/geosite-%s.srs"
	geoIPRuleSetURL   = "https://raw.githubusercontent.com/SagerNet/sing-geoip/" + geoIPRuleSetRef + "/geoip-%s.srs"
)

// protocolNaive is the plan protocol string for NaiveProxy. It has no
// engine.Protocol constant yet: the link parser, the credential vault and
// plan validation still need to learn naive+https:// links. The renderer
// matches it by string so this mapping starts working the moment they do.
const protocolNaive = engine.Protocol("naive")

// obj models configuration JSON. set omits zero values because some empty
// values are explicit settings upstream.
type obj map[string]any

func (o obj) set(key string, value any) obj {
	switch v := value.(type) {
	case string:
		if v == "" {
			return o
		}
	case int:
		if v == 0 {
			return o
		}
	case bool:
		if !v {
			return o
		}
	case []string:
		if len(v) == 0 {
			return o
		}
	case obj:
		if len(v) == 0 {
			return o
		}
	case nil:
		return o
	}
	o[key] = value
	return o
}

// Render produces credential-bearing JSON for engine stdin. The output must
// never enter diagnostic archives.
//
// Render targets the oldest supported build: options a newer engine
// deprecated are still emitted. Drivers that know the probed version use
// renderVersioned to drop them.
func Render(p *engine.Plan, rt supervise.Runtime) ([]byte, error) {
	return renderVersioned(p, rt, engine.Version{})
}

// renderVersioned renders for one concrete engine build.
func renderVersioned(p *engine.Plan, rt supervise.Runtime, ver engine.Version) ([]byte, error) {
	if p == nil {
		return nil, errors.New("singbox: nil plan")
	}
	// Capacity hints: the maps and slices below are sized for the plan so
	// rendering does not grow them repeatedly.
	n := len(p.Outbounds) + len(p.Groups)
	r := renderer{plan: p, ver: ver,
		tags: make(map[string]string, n),
		used: make(map[string]bool, n+1)}
	r.used["direct"] = true
	if err := r.assignTags(); err != nil {
		return nil, err
	}
	outbounds, endpoints, err := r.outbounds()
	if err != nil {
		return nil, err
	}
	route, err := r.route()
	if err != nil {
		return nil, err
	}
	dns, resolver, err := r.dns()
	if err != nil {
		return nil, err
	}
	route["default_domain_resolver"] = obj{"server": resolver}

	listen := "127.0.0.1"
	if p.Options.AllowLAN {
		listen = "0.0.0.0"
	}
	// Open only requested listeners because all local applications can
	// reach loopback.
	inbounds := make([]obj, 0, 2)
	if lp := p.LocalProxy; lp.Enabled {
		mixed := obj{"type": "mixed", "tag": "mixed-in", "listen": listen, "listen_port": rt.LocalPort}
		if lp.Username != "" {
			mixed["users"] = []obj{{"username": lp.Username, "password": lp.Password}}
		}
		inbounds = append(inbounds, mixed)
	}
	if p.Tun.Enabled {
		inbounds = append(inbounds, r.tun(p.Tun))
	}

	cfg := obj{
		"log":       logConfig(p.Options.LogLevel),
		"dns":       dns,
		"inbounds":  inbounds,
		"outbounds": outbounds,
		"route":     route,
		"experimental": obj{
			"clash_api": obj{"external_controller": rt.ControlAddr, "secret": rt.Secret},
			// Persist selector choices and fake-IP mappings because
			// new plans restart sing-box.
			"cache_file": obj{"enabled": true, "path": "cache.db", "store_fakeip": p.DNS.Mode == string(engine.DNSFakeIP)},
		},
	}
	if len(endpoints) > 0 {
		cfg["endpoints"] = endpoints
	}
	if len(r.httpClients) > 0 {
		// Remote rule-set downloads ride this client; route() sets
		// route.default_http_client to its tag.
		cfg["http_clients"] = r.httpClients
	}
	return json.Marshal(cfg)
}

type renderer struct {
	plan *engine.Plan
	// ver is the engine build the config is for; the zero value keeps
	// every legacy option (Render's contract for unknown builds).
	ver      engine.Version
	tags     map[string]string // plan id or group name -> sing-box tag
	used     map[string]bool
	final    string
	ruleSets []obj
	// httpClients carries the client for remote rule-set downloads
	// (route.default_http_client selects its tag): with a detour when
	// the plan has a proxy to download through, an explicit direct
	// client when it does not; empty only when the plan has no remote
	// rule-sets at all.
	httpClients []obj
}

// assignTags gives outbounds and groups unique tags. Unique display names are
// preferred because the Clash API shows tags to users.
func (r *renderer) assignTags() error {
	unique := func(name, fallback string) string {
		tag := strings.TrimSpace(name)
		if tag == "" || r.used[tag] {
			tag = fallback
		}
		for n := 2; r.used[tag]; n++ {
			tag = fallback + "-" + strconv.Itoa(n)
		}
		r.used[tag] = true
		return tag
	}
	for _, o := range r.plan.Outbounds {
		r.tags[o.ID] = unique(o.Name, o.ID)
	}
	for _, g := range r.plan.Groups {
		if _, clash := r.tags[g.Name]; clash {
			return fmt.Errorf("singbox: group %q has the id of an outbound", g.Name)
		}
		r.tags[g.Name] = unique(g.Name, "group")
	}
	return nil
}

func (r *renderer) target(id string) (string, error) {
	if id == "direct" {
		return "direct", nil
	}
	tag, ok := r.tags[id]
	if !ok {
		return "", fmt.Errorf("singbox: target %q is not an outbound or a group of this plan", id)
	}
	return tag, nil
}

func (r *renderer) outbounds() (outbounds, endpoints []obj, err error) {
	outbounds = make([]obj, 0, len(r.plan.Outbounds)+len(r.plan.Groups)+1)
	for _, o := range r.plan.Outbounds {
		out, err := r.outbound(o)
		if err != nil {
			return nil, nil, err
		}
		if o.Protocol == engine.ProtocolWireGuard {
			endpoints = append(endpoints, out)
		} else {
			outbounds = append(outbounds, out)
		}
	}
	for _, g := range r.plan.Groups {
		group, err := r.group(g)
		if err != nil {
			return nil, nil, err
		}
		outbounds = append(outbounds, group)
	}
	return append(outbounds, obj{"type": "direct", "tag": "direct"}), endpoints, nil
}

func (r *renderer) outbound(o engine.Outbound) (obj, error) {
	out := obj{"tag": r.tags[o.ID]}
	if o.Via != "" {
		// Proxy chains: dial this outbound through another one of the plan.
		out["dialer_proxy"] = r.tags[o.Via]
	}
	if o.Protocol != engine.ProtocolDirect && o.Protocol != engine.ProtocolWireGuard {
		out.set("server", o.Server).set("server_port", int(o.Port))
	}
	needsTLS := false
	switch o.Protocol {
	case engine.ProtocolDirect:
		out["type"] = "direct"
		return out, nil
	case engine.ProtocolVLESS:
		out.set("type", "vless").set("uuid", o.UUID).set("flow", o.Flow).set("packet_encoding", "xudp")
		if o.Encryption != "none" {
			out.set("encryption", o.Encryption)
		}
	case engine.ProtocolVMess:
		out.set("type", "vmess").set("uuid", o.UUID).set("security", orDefault(o.Cipher, "auto"))
	case engine.ProtocolTrojan:
		out.set("type", "trojan").set("password", o.Password)
		needsTLS = true
	case engine.ProtocolShadowsocks:
		// Fail closed on what the pinned build refuses at load
		// (measured, CENSOR-P4): unknown 2022 chacha variants and
		// plugin names the binary cannot resolve die here with the
		// plan context instead of as a bare engine FATAL at start.
		// Selection refuses the same facts earlier (catalog.go).
		if !engine.SupportsShadowsocksMethod(engine.KindSingBox, o.Cipher) {
			return nil, fmt.Errorf("singbox: shadowsocks outbound %s uses method %q, which sing-box does not implement", o.ID, orDefault(o.Cipher, "aes-256-gcm"))
		}
		if o.Plugin != "" && !engine.SupportsSSPlugin(engine.KindSingBox, o.Plugin) {
			return nil, fmt.Errorf("singbox: shadowsocks outbound %s uses plugin %q, which needs a plugin binary sora does not ship: refusing to render", o.ID, o.Plugin)
		}
		out.set("type", "shadowsocks").set("method", orDefault(o.Cipher, "aes-256-gcm")).set("password", o.Password)
		// An explicit SIP002 plugin wins over the legacy obfs-local
		// mapping; sing-box passes plugin/plugin_opts to the plugin
		// binary verbatim.
		switch {
		case o.Plugin != "":
			out.set("plugin", o.Plugin)
			if o.PluginOpts != "" {
				out.set("plugin_opts", o.PluginOpts)
			}
		case o.Obfs != "":
			opts := "obfs=" + o.Obfs
			if o.ObfsParam != "" {
				opts += ";obfs-host=" + o.ObfsParam
			}
			out.set("plugin", "obfs-local").set("plugin_opts", opts)
		}
	case engine.ProtocolHysteria2:
		out.set("type", "hysteria2").set("password", o.Password)
		// Bandwidth caps switch the engine from BBR to Hysteria (Brutal)
		// congestion control; zero means auto (BBR).
		if o.UpMbps > 0 {
			out["up_mbps"] = o.UpMbps
		}
		if o.DownMbps > 0 {
			out["down_mbps"] = o.DownMbps
		}
		// Port hopping: server_ports overrides server_port (sing-box
		// >= 1.11 ignores server_port when server_ports is set). The
		// plan spec is share-link spelling ("20000-30000,40000");
		// sing-box wants colon ranges with an explicit upper bound
		// ("20000:30000", "40000:40000") and rejects the plan
		// spelling at config load — the verbatim split that used to
		// sit here made every hopping plan unstartable on this
		// engine (CENSOR-P3, verified on lx.22: "bad port range:
		// 20000-30000"). SingBoxHopPorts is the single translation.
		if o.HopPorts != "" {
			ports, err := engine.SingBoxHopPorts(o.HopPorts)
			if err != nil {
				return nil, fmt.Errorf("singbox: outbound %s: %w", o.ID, err)
			}
			out["server_ports"] = ports
		}
		if o.HopInterval > 0 {
			out["hop_interval"] = strconv.Itoa(o.HopInterval) + "s"
		}
		// Randomized hop interval (sing-box 1.14, Hysteria 2.8 server
		// side): hop_interval_max >= hop_interval is enforced by plan
		// validation; only a valid range reaches the render.
		if o.HopIntervalMax > 0 {
			out["hop_interval_max"] = strconv.Itoa(o.HopIntervalMax) + "s"
		}
		// BBR congestion profile (sing-box 1.14 bbr_profile). Emitted
		// only when BBR is actually in charge: with bandwidth caps the
		// client runs Brutal instead and the profile would be dead text.
		if o.BBRProfile != "" && o.UpMbps == 0 && o.DownMbps == 0 {
			out["bbr_profile"] = o.BBRProfile
		}
		if o.Obfs != "" {
			// sing-box 1.14 Hysteria2 obfs types: salamander and gecko.
			out["obfs"] = obj{"type": o.Obfs, "password": o.ObfsParam}
		}
		needsTLS = true
	case engine.ProtocolTUIC:
		tuic := out.set("type", "tuic").set("uuid", o.UUID).set("password", o.Password)
		// The effective congestion controller always renders (the
		// plan value, or DefaultTUICCongestion from quic_defaults.go):
		// sing-box and mihomo then run the same controller for the
		// same plan instead of each falling back to its own default.
		tuic.set("congestion_control", o.EffectiveTUICCongestion())
		if o.UDPRelayMode != "" {
			tuic.set("udp_relay_mode", o.UDPRelayMode)
		}
		// Heartbeat (TUIC keepalive): sing-box spells it as a
		// duration string; the effective seconds come from the plan
		// or DefaultTUICHeartbeatSeconds (quic_defaults.go).
		tuic.set("heartbeat", strconv.Itoa(o.EffectiveTUICHeartbeatSeconds())+"s")
		needsTLS = true
	case engine.ProtocolAnyTLS:
		out.set("type", "anytls").set("password", o.Password)
		needsTLS = true
	case protocolNaive:
		// NaiveProxy speaks HTTPS CONNECT through Cronet, which owns the
		// whole TLS handshake: sing-box rejects uTLS fingerprints, ALPN
		// overrides, insecure mode and REALITY on this outbound, so the
		// generic TLS block must not apply. Needs an engine build with
		// the with_naive_outbound tag.
		if o.TLS.Insecure {
			return nil, fmt.Errorf("singbox: outbound %s: naive cannot skip certificate verification (Cronet manages its own TLS)", o.ID)
		}
		out.set("type", "naive").set("username", o.UserID).set("password", o.Password)
		out["tls"] = obj{"enabled": true}.set("server_name", orDefault(o.TLS.ServerName, o.Server))
		// UDP only survives as UDP-over-TCP on naive; version 2 is the
		// current framing. Without it UDP is silently blackholed.
		out["udp_over_tcp"] = obj{"enabled": true, "version": 2}
		return out, nil
	case engine.ProtocolSOCKS5:
		out.set("type", "socks").set("version", "5").set("username", o.UserID).set("password", o.Password)
		return out, nil
	case engine.ProtocolHTTP:
		out.set("type", "http").set("username", o.UserID).set("password", o.Password)
	case engine.ProtocolWireGuard:
		return wireguard(out, o)
	default:
		return nil, fmt.Errorf("singbox: protocol %q is not supported", o.Protocol)
	}
	if o.TLS.RealityMLDSA65Verify != "" {
		// Fail closed behind the FeatureRealityMLDSA65 gate: the
		// pinned binary rejects the field as unknown (probed
		// 2026-10-20), so a direct render must refuse rather than
		// complete a handshake without the pinned ML-DSA-65 check.
		return nil, fmt.Errorf("singbox: outbound %s pins a REALITY mldsa65Verify key, which sing-box does not implement: refusing to render a handshake without the ML-DSA-65 server check", o.ID)
	}
	if o.TLS.Enabled || needsTLS {
		tlsObj, err := r.tls(o)
		if err != nil {
			return nil, err
		}
		out["tls"] = tlsObj
	}
	transport, err := transport(o.Transport)
	if err != nil {
		return nil, fmt.Errorf("singbox: outbound %s: %w", o.ID, err)
	}
	if engine.RealityMux(o, r.plan.Options.Mux) {
		// sing-box DOES implement the vision flow (its VLESS outbound
		// documents xtls-rprx-vision, emitted verbatim above), so mux
		// is suppressed under vision here exactly as on the other
		// engines — engine.RealityMux is flow-aware (PASS3 deep S3a).
		// Without vision, one TLS connection carrying many streams
		// keeps the parallel-handshake count at one (T007).
		out["multiplex"] = obj{"enabled": true, "protocol": "smux",
			"max_streams": engine.MuxConcurrency(r.plan.Options.Mux)}
	}
	return out.set("transport", transport), nil
}

func (r *renderer) tls(o engine.Outbound) (obj, error) {
	t := obj{"enabled": true}
	t.set("server_name", o.TLS.ServerName).set("insecure", o.TLS.Insecure).set("alpn", o.TLS.ALPN)
	// The fingerprint resolves through the plan's policy, the single
	// source every renderer shares (fingerprint_policy.go): explicit
	// plan value (normalized), per-protocol profile, then the REALITY
	// default — the "chrome" alias, which sing-box resolves to
	// utls.HelloChrome_Auto of its vendored uTLS.
	fingerprint := engine.ResolveFingerprint(engine.KindSingBox, o, r.plan.Options.Fingerprint)
	if o.TLS.Reality {
		reality := obj{"enabled": true, "public_key": o.TLS.RealityPublicKey}.set("short_id", o.TLS.RealityShortID)
		if o.TLS.KeyShare != "" {
			// tls.reality.key_share of the lx fork (PASS2 S3), probed
			// on the pinned lx.22 binary: "hybrid"/"classical" are
			// accepted, anything else is refused at load, and a wire
			// capture shows classical dropping the X25519MLKEM768
			// group from the ClientHello (CENSOR-FP).
			reality["key_share"] = o.TLS.KeyShare
		}
		t["reality"] = reality
	}
	if fingerprint != "" {
		t["utls"] = obj{"enabled": true, "fingerprint": fingerprint}
	}
	if o.TLS.ECH.Enabled {
		// Without a pinned config the engine fetches the ECHConfigList
		// from the server's HTTPS DNS record. query_server_name exists
		// since sing-box 1.13, below the 1.14.3/1.15 floor, so it is
		// always safe to emit.
		ech := obj{"enabled": true}
		if len(o.TLS.ECH.Config) > 0 {
			// The pinned list is canonicalized to the PEM label the
			// binary actually accepts — "ECH CONFIGS", probed on
			// lx.22: the historical "ECHCONFIG" label makes the
			// binary refuse the whole config at startup ("invalid
			// ECH configs pem", CENSOR-FP).
			pem, err := engine.ECHConfigPEM(o.TLS.ECH.Config)
			if err != nil {
				return nil, fmt.Errorf("singbox: outbound %s: %w", o.ID, err)
			}
			ech["config"] = pem
		}
		ech.set("query_server_name", o.TLS.ECH.QueryServerName)
		t["ech"] = ech
	}
	if r.plan.Options.Fragment.Enabled && o.Protocol != engine.ProtocolHysteria2 && o.Protocol != engine.ProtocolTUIC {
		// QUIC protocols have no TCP ClientHello to split.
		t["fragment"] = true
	}
	return t, nil
}

func transport(t engine.Transport) (obj, error) {
	// wsHeaders merges the plan's header set with the Host field: the
	// explicit Host wins, exactly as in the mihomo renderer, so a
	// subscription's custom headers (User-Agent and friends — the
	// browser-masquerade data) reach the wire identically on every
	// engine. Previously only Host was emitted and every other header
	// was lost silently on this engine (CENSOR-P2).
	wsHeaders := func() obj {
		if len(t.Headers) == 0 && t.Host == "" {
			return nil
		}
		out := make(obj, len(t.Headers)+1)
		for k, v := range t.Headers {
			out[k] = v
		}
		if t.Host != "" {
			out["Host"] = t.Host
		}
		return out
	}
	switch t.Type {
	case "", "tcp":
		return nil, nil
	case "ws":
		out := obj{"type": "ws"}.set("path", t.Path).set("headers", wsHeaders())
		if t.EarlyData > 0 {
			// 0-RTT: the first payload bytes ride the handshake.
			out["max_early_data"] = t.EarlyData
			out.set("early_data_header_name", t.EarlyDataHeaderName)
		}
		return out, nil
	case "grpc":
		// sing-box's gRPC transport spells only the service name (plus
		// timeouts the plan does not carry). Authority, multi-mode and
		// user-agent are Xray spellings; catalog MissingFor keeps such
		// plans off this engine, and this refusal is the render-time
		// backstop so the fields can never drop silently.
		if t.GRPCAuthority != "" || t.GRPCMultiMode || t.GRPCUserAgent != "" {
			return nil, fmt.Errorf("transport grpc: authority, multi-mode and user-agent are Xray-only and sing-box does not render them")
		}
		return obj{"type": "grpc"}.set("service_name", t.Service), nil
	case "h2":
		out := obj{"type": "http"}.set("path", t.Path)
		if t.Host != "" {
			out["host"] = []string{t.Host}
		}
		return out, nil
	case "httpupgrade":
		out := obj{"type": "httpupgrade"}.set("host", t.Host).set("path", t.Path)
		if len(t.Headers) > 0 {
			// Verified on the pin: httpupgrade accepts a headers map;
			// dropping it lost the masquerade headers other engines
			// emit for the same plan (CENSOR-P2).
			out["headers"] = t.Headers
		}
		return out, nil
	case "xhttp":
		out := obj{"type": "xhttp", "mode": orDefault(t.Mode, "auto")}.set("host", t.Host).set("path", t.Path)
		if len(t.Headers) > 0 {
			out["headers"] = t.Headers
		}
		return out, nil
	}
	return nil, fmt.Errorf("transport %q is not supported by sing-box", t.Type)
}

// wireguard renders an endpoint: sing-box 1.13 removed the WireGuard outbound.
func wireguard(out obj, o engine.Outbound) (obj, error) {
	if len(o.Addresses) == 0 {
		return nil, fmt.Errorf("singbox: wireguard outbound %s has no interface address", o.ID)
	}
	// The endpoint map grows to ~30 keys with AmneziaWG parameters;
	// rehashing a one-entry literal several times per endpoint dominated
	// the render of WireGuard-heavy plans, so rebuild it pre-sized.
	sized := make(obj, 32)
	for k, v := range out {
		sized[k] = v
	}
	out = sized
	out.set("type", "wireguard").set("address", o.Addresses).set("private_key", o.PrivateKey).set("mtu", 1420)
	if a := o.Amnezia; !a.IsZero() {
		if a.J1 != "" || a.J2 != "" || a.J3 != "" || a.Itime != 0 {
			return nil, fmt.Errorf("singbox: AmneziaWG J1/J2/J3/Itime require another engine")
		}
		out["mtu"] = 1280
		out.set("jc", a.Jc).set("jmin", a.Jmin).set("jmax", a.Jmax).
			set("s1", a.S1).set("s2", a.S2).set("s3", a.S3).set("s4", a.S4).
			set("h1", a.H1).set("h2", a.H2).set("h3", a.H3).set("h4", a.H4).
			set("i1", a.I1).set("i2", a.I2).set("i3", a.I3).set("i4", a.I4).set("i5", a.I5)
		// AmneziaWG 3.x (sing-box-lx with_awg): header protection,
		// content padding, trailers, ranged timings, and the id/ip/ib
		// masquerade sugar. Range parameters stay numbers when they
		// are plain ints and "min-max" strings otherwise, both forms
		// the engine accepts.
		out.set("header_protection_key", a.HeaderProtectionKey)
		awgRange(out, "content_padding_addition", a.ContentPaddingAddition)
		out.set("random_trailers", a.RandomTrailers).set("disable_cookies", a.DisableCookies)
		awgRange(out, "rekey_after_time", a.RekeyAfterTime)
		awgRange(out, "rekey_timeout", a.RekeyTimeout)
		awgRange(out, "reject_after_time", a.RejectAfterTime)
		awgRange(out, "keepalive_timeout", a.KeepaliveTimeout)
		awgRange(out, "max_handshake_attempts", a.MaxHandshakeAttempts)
		out.set("id", a.MasqueradeDomain).set("ip", a.MasqueradeProtocol).set("ib", a.MasqueradeBrowser)
	}
	peers := make([]obj, 0, len(o.Peers))
	for _, peer := range o.Peers {
		host, portText, err := net.SplitHostPort(peer.Endpoint)
		if err != nil {
			return nil, fmt.Errorf("singbox: wireguard outbound %s: peer endpoint: %w", o.ID, err)
		}
		port, _ := strconv.Atoi(portText)
		allowed := peer.AllowedIPs
		if len(allowed) == 0 {
			allowed = []string{"0.0.0.0/0", "::/0"}
		}
		peers = append(peers, obj{"address": host, "port": port, "public_key": peer.PublicKey, "allowed_ips": allowed}.
			set("pre_shared_key", peer.PreSharedKey).set("persistent_keepalive_interval", peer.PersistentKeepalive))
	}
	if len(peers) == 0 {
		return nil, fmt.Errorf("singbox: wireguard outbound %s has no peer", o.ID)
	}
	out["peers"] = peers
	return out, nil
}

// awgRange renders an AmneziaWG int-or-"min-max" parameter: a plain
// integer stays a JSON number, a range passes through as a string.
func awgRange(out obj, key, raw string) {
	if raw == "" {
		return
	}
	trimmed := strings.TrimSpace(raw)
	if isPlainInt(trimmed) {
		if n, err := strconv.Atoi(trimmed); err == nil {
			out[key] = n
			return
		}
	}
	out[key] = raw
}

// isPlainInt reports whether s has the exact shape strconv.Atoi accepts
// as a plain integer: an optional sign followed by at least one digit.
// Range spellings ("32-96") fail the scan, so awgRange keeps them as
// strings without paying for Atoi's syntax-error allocation per call.
func isPlainInt(s string) bool {
	if s == "" {
		return false
	}
	if s[0] == '+' || s[0] == '-' {
		s = s[1:]
	}
	if s == "" {
		return false
	}
	for i := 0; i < len(s); i++ {
		if s[i] < '0' || s[i] > '9' {
			return false
		}
	}
	return true
}

func (r *renderer) group(g engine.Group) (obj, error) {
	members := make([]string, 0, len(g.Outbounds))
	for _, id := range g.Outbounds {
		tag, err := r.target(id)
		if err != nil {
			return nil, err
		}
		members = append(members, tag)
	}
	if len(members) == 0 {
		return nil, fmt.Errorf("singbox: group %q has no members", g.Name)
	}
	out := obj{"tag": r.tags[g.Name], "outbounds": members}
	switch g.Type {
	case engine.GroupSelect:
		out["type"] = "selector"
		if g.Selected != "" {
			// The selector's default is the member it starts on;
			// without it sing-box starts on the first member and the
			// plan's Selected would be silently dropped at Connect.
			tag, err := r.target(g.Selected)
			if err != nil {
				return nil, err
			}
			out["default"] = tag
		}
	case engine.GroupURLTest:
		out.set("type", "urltest").set("url", orDefault(g.URL, r.plan.Options.TestURL)).set("tolerance", g.Tolerance)
		if g.Interval > 0 {
			out["interval"] = strconv.Itoa(g.Interval) + "s"
		}
	default:
		return nil, fmt.Errorf("singbox: group type %q is not supported", g.Type)
	}
	return out, nil
}

// route orders sniffing and DNS hijacking before the unchanged plan rule order.
func (r *renderer) route() (obj, error) {
	rules := make([]obj, 0, len(r.plan.Rules)+2)
	rules = append(rules, obj{"action": "sniff"}, obj{"protocol": "dns", "action": "hijack-dns"})
	final := "direct"
	for _, rule := range r.plan.Rules {
		if rule.Type == engine.RuleMatchAll {
			if rule.Target == "reject" {
				rules = append(rules, obj{"action": "reject"})
				continue
			}
			tag, err := r.target(rule.Target)
			if err != nil {
				return nil, err
			}
			final = tag
			break
		}
		match, err := r.match(rule)
		if err != nil {
			return nil, err
		}
		switch rule.Target {
		case "reject":
			match["action"] = "reject"
		case "dns":
			match["action"] = "hijack-dns"
		default:
			tag, err := r.target(rule.Target)
			if err != nil {
				return nil, err
			}
			match["action"], match["outbound"] = "route", tag
		}
		rules = append(rules, match)
	}
	r.final = final
	out := obj{"rules": rules, "final": final, "auto_detect_interface": !r.plan.Tun.Enabled || runtime.GOOS != "linux"}
	if len(r.ruleSets) > 0 {
		// Rule-set downloads must reach hosts the local network blocks
		// (GitHub raw is filtered in some regions): send them through
		// the default route when it leads through a proxy, otherwise
		// through the first proxy of the plan.
		//
		// sing-box 1.14 deprecated the per-rule-set download_detour
		// (removal in 1.16) in favor of reusable HTTP clients: one
		// client carries the detour and route.default_http_client
		// selects it for every remote rule-set. The client is rendered
		// ALWAYS when remote rule-sets exist — with no proxy in the
		// plan it is an explicit direct client (tag only). Rendering
		// nothing there relied on the implicit default HTTP client
		// that 1.16 removes: a direct-only plan with remote rule-sets
		// would lose its downloads at the next engine bump (PASS3
		// deep A5, the unfinished half of the 1.14 migration).
		tag := "rule-sets"
		for n := 2; r.used[tag]; n++ {
			tag = "rule-sets-" + strconv.Itoa(n)
		}
		r.used[tag] = true
		client := obj{"tag": tag}
		if detour := r.ruleSetDetour(); detour != "" {
			client["detour"] = detour
		}
		r.httpClients = []obj{client}
		out["default_http_client"] = tag
		out["rule_set"] = r.ruleSets
	}
	return out, nil
}

// ruleSetDetour picks the outbound for remote rule-set downloads. The
// default route wins when it leads through a proxy; otherwise the first
// proxy outbound of the plan is used so geo data still downloads where
// the direct path is filtered. Empty means direct: no detour is rendered.
func (r *renderer) ruleSetDetour() string {
	if r.final != "direct" {
		return r.final
	}
	for _, o := range r.plan.Outbounds {
		if o.Protocol != engine.ProtocolDirect {
			return r.tags[o.ID]
		}
	}
	return ""
}

func (r *renderer) match(rule engine.Rule) (obj, error) {
	v := rule.Value
	switch rule.Type {
	case engine.RuleDomain:
		return obj{"domain": []string{v}}, nil
	case engine.RuleDomainSuffix:
		return obj{"domain_suffix": []string{v}}, nil
	case engine.RuleDomainKeyword:
		return obj{"domain_keyword": []string{v}}, nil
	case engine.RuleIPCIDR:
		return obj{"ip_cidr": []string{v}}, nil
	case engine.RulePort, engine.RuleSrcPort:
		port, err := strconv.Atoi(v)
		if err != nil {
			return nil, fmt.Errorf("singbox: rule %s: %q is not a port", rule.Type, v)
		}
		if rule.Type == engine.RuleSrcPort {
			return obj{"source_port": []int{port}}, nil
		}
		return obj{"port": []int{port}}, nil
	case engine.RuleProcess:
		return obj{"process_name": []string{v}}, nil
	case engine.RuleProtocol:
		return obj{"network": []string{strings.ToLower(v)}}, nil
	case engine.RuleGeoIP:
		if strings.EqualFold(v, "private") || strings.EqualFold(v, "lan") {
			return obj{"ip_is_private": true}, nil
		}
		return obj{"rule_set": []string{r.remoteRuleSet("geoip-"+strings.ToLower(v), fmt.Sprintf(geoIPRuleSetURL, strings.ToLower(v)))}}, nil
	case engine.RuleGeoSite:
		return obj{"rule_set": []string{r.remoteRuleSet("geosite-"+strings.ToLower(v), fmt.Sprintf(geoSiteRuleSetURL, strings.ToLower(v)))}}, nil
	case engine.RuleRuleSet:
		if !strings.HasPrefix(v, "https://") {
			return nil, fmt.Errorf("singbox: rule set %q must be an https URL", v)
		}
		return obj{"rule_set": []string{r.remoteRuleSet("rule-set-"+strconv.Itoa(len(r.ruleSets)+1), v)}}, nil
	}
	return nil, fmt.Errorf("singbox: rule type %q is not supported", rule.Type)
}

func (r *renderer) remoteRuleSet(tag, url string) string {
	for _, rs := range r.ruleSets {
		if rs["url"] == url {
			return rs["tag"].(string)
		}
	}
	format := "binary"
	if strings.HasSuffix(url, ".json") {
		format = "source"
	}
	r.ruleSets = append(r.ruleSets, obj{"type": "remote", "tag": tag, "format": format, "url": url})
	return tag
}

// dns uses the sing-box 1.12 server format and returns the proxy-hostname
// resolver tag. Bootstrap resolution must not pass through the proxy it
// resolves.
func (r *renderer) dns() (obj, string, error) {
	d := r.plan.DNS
	// +2 servers: the local bootstrap fallback and the fakeip server.
	servers := make([]obj, 0, len(d.Servers)+2)
	direct, remote, bootstrap := "", "", ""
	byAddress := make(map[string]string, len(d.Servers))
	var byHostname []obj
	for i, s := range d.Servers {
		tag := orDefault(s.Tag, "dns-"+strconv.Itoa(i+1))
		server := obj{"tag": tag}
		switch s.Transport {
		case engine.DNSSystem:
			server["type"] = "local"
		case engine.DNSFakeIP:
			continue
		case engine.DNSPlain, engine.DNSTCP, engine.DNSTLS, engine.DNSHTTPS, engine.DNSH3, engine.DNSQUIC, "":
			// DoH3 is a first-class server type since sing-box 1.12:
			// "type": "h3" with server/server_port. The h3:// address
			// string was the legacy H3 server spelling, removed in
			// 1.14 (the old comment claiming there was no legacy
			// "type" spelling was wrong). An unset port is omitted:
			// sing-box defaults it per type (443 for https and h3,
			// 853 for tls and quic, 53 for udp and tcp).
			server.set("type", orDefault(string(s.Transport), "udp")).set("server", s.Address).set("server_port", int(s.Port))
		default:
			return nil, "", fmt.Errorf("singbox: dns transport %q is not supported", s.Transport)
		}
		// Corporate MITM proxies break DoT/DoH/DoQ validation; the plan
		// can opt a server out of certificate verification.
		if s.SkipVerify {
			switch s.Transport {
			case engine.DNSTLS, engine.DNSHTTPS, engine.DNSH3, engine.DNSQUIC:
				server["tls"] = obj{"enabled": true, "insecure": true}
			}
		}
		if s.ProxyOnly {
			// Proxy-only DNS uses the default route to keep queries
			// off the local network.
			server.set("detour", r.proxyFinal())
			if remote == "" {
				remote = tag
			}
		} else {
			if direct == "" {
				direct = tag
			}
			if bootstrap == "" && (s.Transport == engine.DNSSystem || net.ParseIP(s.Address) != nil) {
				bootstrap = tag
			}
		}
		if s.Transport != engine.DNSSystem && net.ParseIP(s.Address) == nil {
			byHostname = append(byHostname, server)
		}
		byAddress[s.Address] = tag
		servers = append(servers, server)
	}
	if bootstrap == "" {
		bootstrap = "local"
		servers = append(servers, obj{"type": "local", "tag": bootstrap})
	}
	if direct == "" {
		direct = bootstrap
	}
	// Resolver hostnames require an IP-addressed or system bootstrap
	// resolver.
	for _, server := range byHostname {
		server["domain_resolver"] = bootstrap
	}
	// Capacity covers the nameserver policies, the fake-IP filter rules
	// and the final query_type rule.
	rules := make([]obj, 0, len(d.NameserverPolicy)+len(engine.DefaultFakeIPFilter)+1)
	patterns := make([]string, 0, len(d.NameserverPolicy))
	for pattern := range d.NameserverPolicy {
		patterns = append(patterns, pattern)
	}
	sort.Strings(patterns)
	for _, pattern := range patterns {
		addresses := d.NameserverPolicy[pattern]
		if len(addresses) == 0 {
			continue
		}
		tag, ok := byAddress[addresses[0]]
		if !ok {
			return nil, "", fmt.Errorf("singbox: dns policy for %q names a server that is not in the plan", pattern)
		}
		suffix := strings.TrimPrefix(strings.TrimPrefix(pattern, "+."), "*.")
		rules = append(rules, obj{"domain_suffix": []string{suffix}, "server": tag})
	}
	if d.Mode == string(engine.DNSFakeIP) {
		fakeip := obj{"type": "fakeip", "tag": "fakeip", "inet4_range": orDefault(d.FakeIPRange, engine.DefaultFakeIPRange)}
		// AAAA reaches the fakeip server only when IPv6 is on (S7).
		// Without an IPv6 pool the server answers AAAA with nothing
		// while the query_type rule still steers AAAA at it, so
		// IPv6-capable apps stall on resolution instead of falling
		// back; with IPv6 off the pool would hand out unusable
		// addresses, so AAAA resolves for real instead.
		queryTypes := []string{"A"}
		if r.plan.Options.IPv6 {
			queryTypes = []string{"A", "AAAA"}
			fakeip["inet6_range"] = orDefault(d.FakeIPRange6, engine.DefaultFakeIPRange6)
		}
		servers = append(servers, fakeip)
		// mihomo's fake-ip-filter equivalent: LAN/mDNS names, NTP, STUN
		// and OS connectivity checks must resolve to real addresses, or
		// printers, router panels, WebRTC and time sync break behind
		// fake answers.
		final := orDefault(remote, direct)
		suffixes, regexes := fakeIPFilterRules(d)
		for _, suffix := range suffixes {
			rules = append(rules, obj{"domain_suffix": []string{suffix}, "server": final})
		}
		for _, re := range regexes {
			rules = append(rules, obj{"domain_regex": []string{re}, "server": final})
		}
		rules = append(rules, obj{"query_type": queryTypes, "server": "fakeip"})
	}
	strategy := "ipv4_only"
	if r.plan.Options.IPv6 {
		// The user enabled IPv6: prefer it instead of pinning the
		// engine default (prefer_ipv4), which would deprioritize the
		// address family the flag just turned on.
		strategy = "prefer_ipv6"
	}
	if len(rules) == 0 {
		// An empty rule list marshals as null, matching the
		// pre-optimization output; sing-box accepts both spellings.
		rules = nil
	}
	out := obj{"servers": servers, "final": orDefault(remote, direct), "strategy": strategy}.
		set("rules", rules).set("disable_cache", d.DisableCache)
	return out, bootstrap, nil
}

// fakeIPFilterRules converts the plan's fake-IP filter patterns into
// sing-box DNS rule matchers. Plain suffix patterns (*.lan,
// +.example.com, localhost) become domain_suffix items; patterns with
// interior wildcards (ntp.*.com, +.stun.*.*) — which have no
// domain_suffix spelling — become domain_regex items. Nothing is
// silently dropped: skipping an entry would hand its domains fake IPs
// on sing-box while mihomo resolves them for real (S7).
func fakeIPFilterRules(d engine.DNS) (suffixes, regexes []string) {
	filters := d.FakeIPFilter
	if len(filters) == 0 {
		filters = engine.DefaultFakeIPFilter
	}
	suffixes = make([]string, 0, len(filters))
	regexes = make([]string, 0, len(filters))
	for _, f := range filters {
		suffix, regex := fakeIPFilterPattern(strings.TrimSpace(f))
		switch {
		case suffix != "":
			suffixes = append(suffixes, suffix)
		case regex != "":
			regexes = append(regexes, regex)
		}
	}
	return suffixes, regexes
}

// fakeIPFilterPattern maps one mihomo-style filter pattern onto either a
// sing-box domain_suffix or a domain_regex. An empty pattern maps to
// ("", "") and is ignored by the caller.
//
// `*` compiles to `.+` — one or more characters, dots included — a
// deliberate superset of mihomo's label wildcard. Over-matching a filter
// entry is harmless (the domain simply resolves for real instead of
// receiving a fake address), while under-matching would leak NTP/STUN
// past the filter. A leading `*.`/`+.` also matches subdomains; `+.`
// additionally matches the bare domain itself (mihomo semantics).
// The expression is anchored and case-insensitive: sing-box matches
// domain_regex with RE2 MatchString semantics, so unanchored patterns
// would match substrings.
func fakeIPFilterPattern(pattern string) (suffix, regex string) {
	rest := strings.TrimSpace(pattern)
	sub, self := false, true
	switch {
	case strings.HasPrefix(rest, "+."):
		rest, sub, self = rest[len("+."):], true, true
	case strings.HasPrefix(rest, "*."):
		rest, sub, self = rest[len("*."):], true, false
	case strings.HasPrefix(rest, "."):
		rest, sub, self = rest[1:], true, true
	}
	rest = strings.TrimSuffix(rest, ".")
	if rest == "" {
		return "", ""
	}
	if !strings.Contains(rest, "*") {
		// domain_suffix already matches the domain itself and every
		// subdomain, so *.lan, +.x and x collapse to one entry.
		return rest, ""
	}
	var b strings.Builder
	b.WriteString("(?i)^")
	if sub {
		b.WriteString("(.+\\.)")
		if self {
			b.WriteByte('?')
		}
	}
	for _, r := range rest {
		switch r {
		case '*':
			b.WriteString(".+")
		case '.', '+', '?', '(', ')', '|', '[', ']', '{', '}', '^', '$', '\\':
			b.WriteByte('\\')
			b.WriteRune(r)
		default:
			b.WriteRune(r)
		}
	}
	b.WriteString("$")
	return "", b.String()
}

// proxyFinal is the default route when it leads through a proxy, or empty.
func (r *renderer) proxyFinal() string {
	if r.final == "direct" {
		return ""
	}
	return r.final
}

// tunDefaultMTU replaces the jumbo 9000 default: a 9000-byte TUN MTU lets
// local apps negotiate MSS 8960, and those segments must then cross the
// proxied path, where MTUs shrink (tunnels, PPPoE) and filtered ICMP breaks
// PMTUD, causing stalls and black holes. 1500 yields MSS 1460, sane on every
// common path; 1400 is the PPPoE-safe alternative the plan may pin
// explicitly. sing-box exposes no MSS-clamping knob, so the interface MTU is
// the only renderer-side lever.
const tunDefaultMTU = 1500

// tunMTU honors an explicit plan MTU; zero or negative means "not set".
func tunMTU(mtu int) int {
	if mtu <= 0 {
		return tunDefaultMTU
	}
	return mtu
}

func (r *renderer) tun(t engine.Tun) obj {
	autoRoute := runtime.GOOS != "linux"
	out := obj{
		"type": "tun", "tag": "tun-in",
		"address":      t.Addresses(),
		"auto_route":   autoRoute,
		"strict_route": t.StrictRoute,
		"mtu":          tunMTU(t.MTU),
	}
	// sing-box 1.15 rewrote TUN around its own TCP/IP stack: the stack
	// option is deprecated there (removed in 1.17) and must not be
	// emitted. Older builds (the 1.14-based lx. fork) still honor an
	// explicit stack, so it stays for them. "mixed" means the system
	// TCP stack plus the gVisor UDP stack (not TCP on gVisor): the UDP
	// path (QUIC, DNS, VoIP, games) is what suffers under "mixed".
	// The zero version (Render without a probed build) keeps the legacy
	// spelling.
	if r.ver.Less(engine.Version{Major: 1, Minor: 15}) {
		out["stack"] = orDefault(t.Stack, "mixed")
	}
	if runtime.GOOS == "linux" {
		// multi_queue scales packet I/O with CPU cores but needs
		// sing-tun's own TCP/IP stack (sing-box 1.15+): the pinned
		// 1.14-based lx fork rejects it as an unknown field (verified
		// with `sing-box check` against 1.14.3-lx.22).
		if !r.ver.Less(engine.Version{Major: 1, Minor: 15}) {
			out["multi_queue"] = true
		}
		// auto_redirect is upstream's recommended Linux routing, but it
		// hard-requires auto_route: sing-box refuses the inbound
		// otherwise. On Linux the core owns routing (tunroute and the
		// atomic kill switch), so auto_route stays off and
		// auto_redirect stays unset with it; it switches on
		// automatically if Linux routing ever moves back to the engine.
		if autoRoute {
			out["auto_redirect"] = true
		}
	}
	return out.set("interface_name", t.DeviceName).
		// Custom routes replace the default route when auto_route installs
		// them (Windows/macOS; Linux routing belongs to tunroute). Same
		// field mihomo renders as route-address; the values are CIDRs, so
		// sing-box gets route_address rather than the rule-set-tagged
		// route_address_set added in 1.11.
		set("route_address", t.RouteAddressSets).
		// Package filters apply only on Android; desktop application
		// routing uses process rules.
		set("include_package", t.IncludeApps).set("exclude_package", t.ExcludeApps)
}

func logConfig(level string) obj {
	switch level {
	case "silent":
		return obj{"disabled": true}
	case "warning":
		level = "warn"
	case "":
		level = "warn"
	}
	return obj{"level": level, "timestamp": false}
}

func orDefault(v, fallback string) string {
	if v == "" {
		return fallback
	}
	return v
}
