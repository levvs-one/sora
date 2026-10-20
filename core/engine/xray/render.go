package xray

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"slices"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Tags of the outbounds every configuration carries.
const (
	tagDirect   = "direct"
	tagBlock    = "block"
	tagDNS      = "dns-out"
	tagFragment = "fragment"
	tagInbound  = "mixed-in"
	tagTun      = "tun-in"
)

type obj map[string]any

// set omits zero values because Xray treats some empty values as explicit
// settings.
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
	}
	o[key] = value
	return o
}

// Selection pins select-group members in routing because Xray has no runtime
// selector. Changing a selection restarts the engine in about 100 ms.
type Selection map[string]string

// Render produces JSON for Xray stdin. Fixed tags such as "o0001" avoid
// overlapping balancer prefixes and exposing display names in logs; names
// remain in the plan.
func Render(p *engine.Plan, rt supervise.Runtime, sel Selection) ([]byte, error) {
	return render(p, rt, sel, nil)
}

// render is Render with probe-discovered fingerprint hints: a hint overrides
// the default uTLS fingerprint of its outbound (an explicit plan fingerprint
// still wins). The driver feeds hints from latency probes that only passed
// with a rotated fingerprint.
func render(p *engine.Plan, rt supervise.Runtime, sel Selection, fpHints map[string]string) ([]byte, error) {
	if p == nil {
		return nil, errors.New("xray: nil plan")
	}
	if p.Tun.Enabled && p.Tun.Stack != "" && p.Tun.Stack != "gvisor" {
		return nil, fmt.Errorf("xray: TUN uses gvisor; stack %q is not supported", p.Tun.Stack)
	}
	if len(p.Outbounds) == 1 && p.Outbounds[0].Protocol == engine.ProtocolXrayProfile {
		return renderProfile(p, rt)
	}
	r := renderer{
		plan: p, sel: sel, fpHints: fpHints,
		tags:    make(map[string]string, len(p.Outbounds)),
		groups:  make(map[string]engine.Group, len(p.Groups)),
		byGroup: make(map[string]string, len(p.Groups)),
	}
	for i, o := range p.Outbounds {
		r.tags[o.ID] = outboundTag(i)
	}
	for _, g := range p.Groups {
		r.groups[g.Name] = g
	}
	outbounds, err := r.outbounds()
	if err != nil {
		return nil, err
	}
	routing, err := r.routing()
	if err != nil {
		return nil, err
	}
	dns, err := r.dns()
	if err != nil {
		return nil, err
	}

	inbounds := sessionInbounds(p, rt)
	cfg := obj{"inbounds": inbounds, "outbounds": outbounds, "routing": routing, "dns": dns}
	frame(cfg, p, rt)
	if subjects := r.observed(); len(subjects) > 0 {
		cfg["observatory"] = obj{
			"subjectSelector":   subjects,
			"probeURL":          orDefault(p.Options.TestURL, rt.ProbeURL),
			"probeInterval":     "1m",
			"enableConcurrency": true,
		}
	}
	return json.Marshal(cfg)
}

// sessionInbounds creates only requested TUN and local proxy inbounds,
// replacing provider inbounds so subscriptions cannot open arbitrary listeners.
func sessionInbounds(p *engine.Plan, rt supervise.Runtime) []obj {
	listen := "127.0.0.1"
	if p.Options.AllowLAN {
		listen = "0.0.0.0"
	}
	// Xray's SOCKS inbound also handles HTTP. Open it only on request
	// because any local application can reach loopback.
	inbounds := make([]obj, 0, 2)
	if lp := p.LocalProxy; lp.Enabled {
		settings := obj{"udp": true}
		if lp.Username != "" {
			settings["auth"] = "password"
			settings["accounts"] = []obj{{"user": lp.Username, "pass": lp.Password}}
		}
		inbounds = append(inbounds, obj{
			"tag": tagInbound, "protocol": "socks", "listen": listen, "port": rt.LocalPort, "settings": settings,
			"sniffing": obj{"enabled": true, "destOverride": []string{"http", "tls", "quic"}, "routeOnly": true},
		})
	}
	if p.Tun.Enabled {
		// Xray creates TUN with default MTU 1500 when unset; Route
		// installs routes. Sniffing recovers domain names for
		// packet-based routing rules.
		inbounds = append(inbounds, obj{
			"tag": tagTun, "protocol": "tun",
			"settings": obj{"name": orDefault(p.Tun.DeviceName, engine.TunDevice), "MTU": p.Tun.MTU},
			"sniffing": obj{"enabled": true, "destOverride": []string{"http", "tls", "quic"}, "routeOnly": true},
		})
	}
	return inbounds
}

// frame adds session-level logging, stats, and loopback metrics for counters
// and automatic-group latency.
func frame(cfg obj, p *engine.Plan, rt supervise.Runtime) {
	cfg["log"] = obj{"loglevel": logLevel(p.Options.LogLevel)}
	cfg["stats"] = obj{}
	cfg["policy"] = obj{"system": obj{
		"statsInboundUplink": true, "statsInboundDownlink": true,
		"statsOutboundUplink": true, "statsOutboundDownlink": true,
	}}
	if rt.ControlAddr != "" {
		cfg["metrics"] = obj{"tag": "metrics", "listen": rt.ControlAddr}
	}
}

func outboundTag(i int) string { return fmt.Sprintf("o%04d", i+1) }

type renderer struct {
	plan     *engine.Plan
	sel      Selection
	tags     map[string]string
	groups   map[string]engine.Group
	balancer []obj
	byGroup  map[string]string // group name -> balancer tag
	fpHints  map[string]string // outbound ID -> probe-discovered uTLS fingerprint
}

func (r *renderer) outbounds() ([]obj, error) {
	out := make([]obj, 0, len(r.plan.Outbounds)+4)
	for _, o := range r.plan.Outbounds {
		ob, err := r.outbound(o)
		if err != nil {
			return nil, err
		}
		if o.Via != "" {
			// Proxy chains: dial this outbound through another one of the plan.
			ob["dialerProxy"] = r.tags[o.Via]
		}
		out = append(out, ob)
	}
	out = append(out,
		obj{"tag": tagDirect, "protocol": "freedom"},
		obj{"tag": tagBlock, "protocol": "blackhole"},
		obj{"tag": tagDNS, "protocol": "dns"},
	)
	if f := r.plan.Options.Fragment; f.Enabled {
		out = append(out, obj{"tag": tagFragment, "protocol": "freedom", "settings": obj{"fragment": obj{
			"packets":  orDefault(f.Packets, "tlshello"),
			"length":   orDefault(f.Length, "100-200"),
			"interval": orDefault(f.Interval, "10-20"),
		}}})
	}
	return out, nil
}

func (r *renderer) outbound(o engine.Outbound) (obj, error) {
	if o.TLS.Insecure && !o.TLS.Reality && (o.TLS.Enabled || o.Protocol == engine.ProtocolTrojan || o.Protocol == engine.ProtocolHysteria2) {
		return nil, fmt.Errorf("xray: outbound %s disables certificate verification; this build requires verification or certificate pinning", o.ID)
	}
	if o.TLS.KeyShare != "" {
		// Fail closed behind the FeatureRealityKeyShare gate: Xray
		// has no REALITY key_share knob — the uTLS parrot decides
		// which key shares the ClientHello offers — so rendering
		// here would silently offer a different share than the plan
		// pins (CENSOR-P1).
		return nil, fmt.Errorf("xray: outbound %s pins a REALITY key_share, which Xray does not expose (the fingerprint parrot decides the key share); use the sing-box or mihomo engine", o.ID)
	}
	tag := r.tags[o.ID]
	server := obj{"address": o.Server, "port": int(o.Port)}
	var settings obj
	protocol := string(o.Protocol)
	switch o.Protocol {
	case engine.ProtocolDirect:
		return obj{"tag": tag, "protocol": "freedom"}, nil
	case engine.ProtocolVLESS:
		user := obj{"id": o.UUID, "encryption": orDefault(o.Encryption, "none")}.set("flow", o.Flow)
		server["users"] = []obj{user}
		settings = obj{"vnext": []obj{server}}
	case engine.ProtocolVMess:
		server["users"] = []obj{{"id": o.UUID, "security": orDefault(o.Cipher, "auto")}}
		settings = obj{"vnext": []obj{server}}
	case engine.ProtocolTrojan:
		server["password"] = o.Password
		settings = obj{"servers": []obj{server}}
	case engine.ProtocolShadowsocks:
		// Xray has no SIP002 plugin support at all and its config
		// loader silently ignores unknown keys (verified on the
		// 26.10.17 pin: a plugin field loads with rc=0 and no
		// obfuscation happens). Rendering the outbound without its
		// plugin — or with a method Xray dropped (stream ciphers,
		// "none", aes-192-gcm, the chacha8/chacha12 2022 variants) —
		// would break the plan's promise silently, so refuse here;
		// selection (catalog MissingFor, same data) refuses earlier
		// (CENSOR-P4).
		if o.Plugin != "" {
			return nil, fmt.Errorf("xray: shadowsocks outbound %s uses plugin %q, which Xray does not implement: refusing to render it unobfuscated", o.ID, o.Plugin)
		}
		if o.Obfs != "" {
			return nil, fmt.Errorf("xray: shadowsocks outbound %s uses obfs %q, which Xray does not implement for shadowsocks: refusing to render it unobfuscated", o.ID, o.Obfs)
		}
		if !engine.SupportsShadowsocksMethod(engine.KindXray, o.Cipher) {
			return nil, fmt.Errorf("xray: shadowsocks outbound %s uses method %q, which Xray does not implement", o.ID, orDefault(o.Cipher, "aes-256-gcm"))
		}
		server["method"], server["password"] = orDefault(o.Cipher, "aes-256-gcm"), o.Password
		settings = obj{"servers": []obj{server}}
	case engine.ProtocolSOCKS5, engine.ProtocolHTTP:
		if o.Protocol == engine.ProtocolSOCKS5 {
			protocol = "socks"
		}
		if o.UserID != "" {
			server["users"] = []obj{{"user": o.UserID, "pass": o.Password}}
		}
		settings = obj{"servers": []obj{server}}
	case engine.ProtocolHysteria2:
		if o.Obfs != "" {
			// Reject unsupported obfuscation because Xray silently
			// ignores unknown keys.
			return nil, fmt.Errorf("xray: hysteria2 outbound %s uses obfs, which Sora does not render for Xray", o.ID)
		}
		return r.hysteria(o, tag), nil
	case engine.ProtocolWireGuard:
		return wireguard(o, tag)
	default:
		return nil, fmt.Errorf("xray: protocol %q is not supported", o.Protocol)
	}
	stream, err := r.stream(o)
	if err != nil {
		return nil, fmt.Errorf("xray: outbound %s: %w", o.ID, err)
	}
	ob := obj{"tag": tag, "protocol": protocol, "settings": settings}.set("streamSettings", stream)
	if engine.RealityMux(o, r.plan.Options.Mux) {
		// Vision and mux are mutually exclusive: upstream silently
		// ignores mux under xtls-rprx-vision, so emitting it would be
		// a lie in the config (T002 architectural decision: vision
		// wins). The vision exclusion lives in engine.RealityMux
		// itself, shared by all three renderers (PASS3 deep S3a).
		// Under vision the anti-parallelism role belongs to
		// XHTTP+xmux, not to outbound mux.
		ob["mux"] = obj{"enabled": true, "concurrency": engine.MuxConcurrency(r.plan.Options.Mux)}
	}
	return ob, nil
}

func (r *renderer) stream(o engine.Outbound) (obj, error) {
	s := obj{}
	t := o.Transport
	if err := checkStreamCompat(o); err != nil {
		return nil, err
	}
	switch t.Type {
	case "", "tcp":
	case "ws":
		s["network"] = "ws"
		ws := obj{}.set("path", t.Path).set("host", t.Host).set("maxEarlyData", t.EarlyData).
			set("earlyDataHeaderName", t.EarlyDataHeaderName)
		if len(t.Headers) > 0 {
			// Xray was dropping the plan's WS headers while sing-box
			// and mihomo emit them: the masquerade header set (UA and
			// friends) silently vanished on this engine (CENSOR-P2).
			// Verified accepted by the pinned binary (run -test).
			ws.set("headers", t.Headers)
		}
		s["wsSettings"] = ws
	case "grpc":
		s["network"] = "grpc"
		// authority, multiMode and user_agent are Xray's spellings
		// (verified on the pin); sing-box renders none of them and
		// mihomo only the user agent, so catalog gates keep plans
		// that set authority/multi-mode on this engine.
		s["grpcSettings"] = obj{}.set("serviceName", t.Service).
			set("authority", t.GRPCAuthority).set("multiMode", t.GRPCMultiMode).
			set("user_agent", t.GRPCUserAgent)
	case "httpupgrade":
		s["network"] = "httpupgrade"
		hu := obj{}.set("path", t.Path).set("host", t.Host)
		if len(t.Headers) > 0 {
			hu.set("headers", t.Headers)
		}
		s["httpupgradeSettings"] = hu
	case "xhttp":
		s["network"] = "xhttp"
		xs := obj{"mode": orDefault(t.Mode, "auto")}.set("path", t.Path).set("host", t.Host)
		if len(t.Headers) > 0 {
			// PASS3 deep A4: Xray was the only renderer dropping
			// the transport headers (sing-box and mihomo emit
			// them); subscriptions whose CDN fronting rides on
			// custom headers beyond Host lost them silently here.
			xs.set("headers", t.Headers)
		}
		if t.DownloadAddress != "" || t.DownloadPort != 0 {
			ds, err := r.xhttpDownloadSettings(o)
			if err != nil {
				return nil, err
			}
			xs["downloadSettings"] = ds
		}
		s["xhttpSettings"] = xs
	default:
		// Xray removed the h2 transport in favour of XHTTP.
		return nil, fmt.Errorf("transport %q is not supported by Xray", t.Type)
	}
	needsTLS := o.Protocol == engine.ProtocolTrojan
	switch {
	case o.TLS.Reality:
		s["security"] = "reality"
		s["realitySettings"] = obj{
			"serverName": o.TLS.ServerName, "publicKey": o.TLS.RealityPublicKey,
			"fingerprint": r.realityFingerprint(o),
		}.set("shortId", o.TLS.RealityShortID).set("spiderX", orDefault(o.TLS.SpiderX, engine.DefaultSpiderX)). // "/" is the documented safe default path
															set("mldsa65Verify", o.TLS.RealityMLDSA65Verify)
	case o.TLS.Enabled || needsTLS:
		s["security"] = "tls"
		tlsSettings := obj{}.set("serverName", o.TLS.ServerName).set("alpn", o.TLS.ALPN).
			set("fingerprint", engine.ResolveFingerprint(engine.KindXray, o, r.plan.Options.Fingerprint))
		if o.TLS.ECH.Enabled {
			// ECH on Xray (transport/internet/tls/ech.go), probed on
			// the pinned 26.10.17 binary (CENSOR-FP): the pinned list
			// renders as ONE base64 string in echConfigList and a
			// wire capture shows the outer SNI becoming the list's
			// public_name — real ECH. Without a pinned list Xray
			// fetches the ECHConfigList itself when echForceQuery is
			// "full". (The loader does not parse echConfigList at
			// config-test time, so only the capture proves this —
			// the runtime probe re-measures it per binary.)
			if len(o.TLS.ECH.Config) > 0 {
				b64, err := engine.ECHConfigListBase64(o.TLS.ECH.Config)
				if err != nil {
					return nil, fmt.Errorf("xray: outbound %s: %w", o.ID, err)
				}
				tlsSettings["echConfigList"] = b64
			} else {
				tlsSettings["echForceQuery"] = "full"
			}
			if o.TLS.ECH.QueryServerName != "" {
				// Xray has no query_server_name spelling for ECH:
				// the pinned list carries its own public_name and
				// the DNS query uses the server name. Refuse rather
				// than silently drop the override (sing-box and
				// mihomo render it).
				return nil, fmt.Errorf("xray: outbound %s sets ECH query_server_name %q, which Xray does not spell; use the sing-box or mihomo engine", o.ID, o.TLS.ECH.QueryServerName)
			}
		}
		s["tlsSettings"] = tlsSettings
	}
	if r.plan.Options.Fragment.Enabled && s["security"] != nil {
		// Dial proxy connections through the fragment outbound to split
		// ClientHello before transmission.
		s["sockopt"] = obj{"dialerProxy": tagFragment}
	}
	return s, nil
}

// realityFingerprint resolves the uTLS fingerprint of a REALITY outbound:
// the plan's explicit value (normalized) wins, then a probe-discovered
// working fingerprint (normalized, so it can never diverge from the XHTTP
// downlink leg, which normalizes the same hint), then the plan's
// fingerprint policy — whose canonical default is the
// "hellochrome_auto" alias, always the newest verified Chrome parrot of
// the engine's vendored uTLS — because Xray's pinned "chrome" alias sends
// Chrome 133, which TSPU fingerprints and blocks (see
// engine.DefaultXrayFingerprint and fingerprint_policy.go).
func (r *renderer) realityFingerprint(o engine.Outbound) string {
	if fp := engine.NormalizeFingerprint(o.TLS.Fingerprint); fp != "" {
		return fp
	}
	if fp := engine.NormalizeFingerprint(r.fpHints[o.ID]); fp != "" {
		return fp
	}
	return engine.ResolveFingerprint(engine.KindXray, o, r.plan.Options.Fingerprint)
}

// fingerprintRotation is the uTLS fingerprint try-order for Xray
// probes. The order itself is policy data now — the single canonical
// list in engine (fingerprint_policy.go, CanonicalRotation), shared
// with the other engines' retry paths: index 0 is the render default;
// real browser templates go first, randomized last. This alias keeps
// the Xray driver's attempt indexing (engine.go) on the same data.
var fingerprintRotation = engine.CanonicalRotation

// realityWithoutVision reports a VLESS+REALITY outbound without an XTLS
// vision flow. Without vision the inner TLS session runs inside the outer
// REALITY TLS — TLS-in-TLS, a detectable signal — while vision lets Xray
// strip the inner handshake. Warning-only: the connection still works.
func realityWithoutVision(o engine.Outbound) bool {
	if o.Protocol != engine.ProtocolVLESS || !o.TLS.Reality {
		return false
	}
	switch o.Flow {
	case "xtls-rprx-vision", "xtls-rprx-vision-udp443":
		return false
	}
	return true
}

// checkStreamCompat refuses transport/security combinations that Xray
// documents as unsupported, instead of rendering a config that fails at
// runtime. Compatibility matrix:
// https://xtls.github.io/en/config/transport.html
func checkStreamCompat(o engine.Outbound) error {
	t := o.Transport.Type
	if (o.Transport.DownloadAddress != "" || o.Transport.DownloadPort != 0) && t != "xhttp" {
		return fmt.Errorf("xray: outbound %s: downloadSettings is an XHTTP-only option, not %q", o.ID, t)
	}
	if o.TLS.Reality && (t == "ws" || t == "httpupgrade") {
		return fmt.Errorf("xray: outbound %s: REALITY does not support the %s transport (use tcp, xhttp or grpc)", o.ID, t)
	}
	if o.Flow != "" && t != "" && t != "tcp" && !o.HasVLESSEncryption() {
		// Upstream: XTLS is available only under TCP+TLS/REALITY —
		// or under VLESS Encryption, which imposes no underlying
		// transport restrictions (PASS3 deep S3b).
		// https://xtls.github.io/en/config/outbounds/vless.html
		return fmt.Errorf("xray: outbound %s: flow %q requires the TCP transport or VLESS Encryption, not %q", o.ID, o.Flow, t)
	}
	return nil
}

// xhttpDownloadSettings renders the XHTTP downlink detour: the downlink
// rides a separate server, so uplink and downlink can use different
// domains. Xray dials it as an independent stream, so it carries its own
// address, port and security; the security mirrors the main stream with
// the SNI pointed at the downlink host.
func (r *renderer) xhttpDownloadSettings(o engine.Outbound) (obj, error) {
	t := o.Transport
	if t.DownloadAddress == "" || t.DownloadPort == 0 {
		return nil, fmt.Errorf("xray: outbound %s: XHTTP downloadSettings needs both a download address and a download port", o.ID)
	}
	if t.Mode == "stream-one" {
		// stream-one carries both directions on one connection, so a
		// separate downlink is contradictory; stream-up is the two-leg mode.
		return nil, fmt.Errorf("xray: outbound %s: XHTTP downloadSettings is incompatible with mode stream-one (use stream-up)", o.ID)
	}
	fp, err := r.xhttpDownlinkFingerprint(o)
	if err != nil {
		return nil, err
	}
	ds := obj{"address": t.DownloadAddress, "port": int(t.DownloadPort), "network": "xhttp"}.
		set("xhttpSettings", obj{}.set("path", t.Path))
	switch {
	case o.TLS.Reality:
		ds["security"] = "reality"
		ds["realitySettings"] = obj{
			"serverName": t.DownloadAddress, "publicKey": o.TLS.RealityPublicKey,
			"fingerprint": fp,
		}.set("shortId", o.TLS.RealityShortID).set("spiderX", orDefault(o.TLS.SpiderX, engine.DefaultSpiderX)). // "/" is the documented safe default path
															set("mldsa65Verify", o.TLS.RealityMLDSA65Verify)
	case o.TLS.Enabled || o.Protocol == engine.ProtocolTrojan:
		ds["security"] = "tls"
		ds["tlsSettings"] = obj{"serverName": t.DownloadAddress}.
			set("alpn", o.TLS.ALPN).set("fingerprint", fp)
	}
	return ds, nil
}

// xhttpDownlinkFingerprint resolves the uTLS fingerprint for the XHTTP
// downlink detour so it can never silently diverge from the uplink: the
// plan's explicit fingerprint (normalized) wins, then the outbound's own
// probe-discovered hint. Unlike the main stream's reality fingerprint —
// which falls back to the canonical auto default — the downlink refuses an
// empty or Xray-unknown fingerprint with an honest render error. The
// downlink dials a different server than the uplink, so a silent default
// (or a name Xray would reject at startup) would put a different — or
// broken — ClientHello on the wire: exactly the fingerprint-mismatch
// detect signal this resolution exists to prevent. To use the auto parrot,
// spell it out in the plan ("hellochrome_auto").
func (r *renderer) xhttpDownlinkFingerprint(o engine.Outbound) (string, error) {
	fp := engine.NormalizeFingerprint(o.TLS.Fingerprint)
	if fp == "" {
		fp = engine.NormalizeFingerprint(r.fpHints[o.ID])
	}
	if fp == "" {
		return "", fmt.Errorf("xray: outbound %s: XHTTP downloadSettings needs an explicit uTLS fingerprint (plan TLS.Fingerprint): refusing to silently default the downlink parrot", o.ID)
	}
	if !xrayAcceptsFingerprint(fp) {
		return "", fmt.Errorf("xray: outbound %s: XHTTP downloadSettings fingerprint %q is not accepted by Xray", o.ID, fp)
	}
	return fp, nil
}

// xrayAcceptsFingerprint reports whether Xray understands the fingerprint
// name: the engine-union aliases ("chrome", "firefox", ...), the randomized
// variants, or an Xray versioned/auto parrot ("hellochrome_155",
// "hellochrome_auto", ...).
func xrayAcceptsFingerprint(fp string) bool {
	return engine.IsKnownFingerprint(fp) || engine.IsRandomizedFingerprint(fp) || engine.IsVersionedParrot(fp)
}

func (*renderer) hysteria(o engine.Outbound, tag string) obj {
	// Xray's "hysteria" outbound is the native Hysteria2 implementation:
	// upstream requires settings.version == 2 and rejects anything else,
	// so there is no legacy v1 mapping here.
	// https://xtls.github.io/en/config/outbounds/hysteria.html
	// Salamander obfs is refused in outbound() because Xray's hysteria
	// transport config exposes no obfs option.
	// Bandwidth hints switch the client from BBR to Brutal congestion
	// control; zero means auto (BBR). The hints live in hysteriaSettings,
	// the transport config Xray documents for brutal:
	// https://xtls.github.io/en/config/outbounds/hysteria.html
	hy := obj{"version": 2, "auth": o.Password}
	if o.UpMbps > 0 {
		hy["up_mbps"] = o.UpMbps
	}
	if o.DownMbps > 0 {
		hy["down_mbps"] = o.DownMbps
	}
	// Port hopping has no Xray spelling: plans that hop never reach this
	// renderer (FeatureHy2PortHop in the engine catalog).
	tls := obj{}.set("serverName", o.TLS.ServerName).set("alpn", o.TLS.ALPN)
	stream := obj{"network": "hysteria", "hysteriaSettings": hy, "security": "tls", "tlsSettings": tls}
	return obj{
		"tag": tag, "protocol": "hysteria",
		"settings":       obj{"version": 2, "address": o.Server, "port": int(o.Port)},
		"streamSettings": stream,
	}
}

func wireguard(o engine.Outbound, tag string) (obj, error) {
	if len(o.Addresses) == 0 {
		return nil, fmt.Errorf("xray: wireguard outbound %s has no interface address", o.ID)
	}
	// T012: Xray has no AmneziaWG support at all. Rendering the outbound
	// without its obfuscation parameters would put plain WireGuard on the
	// wire while the plan promises obfuscation - the exact silent no-op
	// this check exists to prevent. Fail closed: the caller must pick an
	// engine with FeatureAmneziaWG instead.
	if !o.Amnezia.IsZero() {
		return nil, fmt.Errorf("xray: wireguard outbound %s sets AmneziaWG obfuscation parameters, which xray does not implement: refusing to render an unobfuscated outbound", o.ID)
	}
	peers := make([]obj, 0, len(o.Peers))
	for _, p := range o.Peers {
		peers = append(peers, obj{"publicKey": p.PublicKey, "endpoint": p.Endpoint}.
			set("preSharedKey", p.PreSharedKey).set("allowedIPs", p.AllowedIPs).set("keepAlive", p.PersistentKeepalive))
	}
	if len(peers) == 0 {
		return nil, fmt.Errorf("xray: wireguard outbound %s has no peer", o.ID)
	}
	return obj{"tag": tag, "protocol": "wireguard", "settings": obj{
		"secretKey": o.PrivateKey, "address": o.Addresses, "peers": peers, "mtu": 1420,
	}}, nil
}

// target resolves routing targets to outbound tags or automatic-group balancer
// tags.
func (r *renderer) target(id string, depth int) (field, tag string, err error) {
	switch id {
	case "direct":
		return "outboundTag", tagDirect, nil
	case "reject":
		return "outboundTag", tagBlock, nil
	case "dns":
		return "outboundTag", tagDNS, nil
	}
	if tag, ok := r.tags[id]; ok {
		return "outboundTag", tag, nil
	}
	g, ok := r.groups[id]
	if !ok {
		return "", "", fmt.Errorf("xray: target %q is not an outbound or a group of this plan", id)
	}
	if depth > len(r.groups) {
		return "", "", fmt.Errorf("xray: group %q is part of a cycle", id)
	}
	if len(g.Outbounds) == 0 {
		return "", "", fmt.Errorf("xray: group %q has no members", g.Name)
	}
	switch g.Type {
	case engine.GroupSelect:
		member := g.Outbounds[0]
		if pinned, ok := r.sel[g.Name]; ok && slices.Contains(g.Outbounds, pinned) {
			member = pinned
		}
		return r.target(member, depth+1)
	case engine.GroupURLTest, engine.GroupLoadBalance:
		return "balancerTag", r.balancerFor(g), nil
	}
	return "", "", fmt.Errorf("xray: group type %q is not supported", g.Type)
}

func (r *renderer) balancerFor(g engine.Group) string {
	if tag, ok := r.byGroup[g.Name]; ok {
		return tag
	}
	tag := "b-" + strconv.Itoa(len(r.balancer)+1)
	r.byGroup[g.Name] = tag
	members := make([]string, 0, len(g.Outbounds))
	for _, id := range g.Outbounds {
		if t, ok := r.tags[id]; ok {
			members = append(members, t)
		}
	}
	if len(members) == 0 {
		// A group of only groups has no plain members: keep the
		// selector nil so it marshals as null, as before.
		members = nil
	}
	strategy := "leastPing"
	if g.Type == engine.GroupLoadBalance {
		strategy = "roundRobin"
	}
	b := obj{"tag": tag, "selector": members, "strategy": obj{"type": strategy}}
	if len(members) > 0 {
		b["fallbackTag"] = members[0]
	}
	r.balancer = append(r.balancer, b)
	return tag
}

// observed lists automatic-group members measured by the observatory.
func (r *renderer) observed() []string {
	n := 0
	for _, b := range r.balancer {
		n += len(b["selector"].([]string))
	}
	seen := make(map[string]bool, n)
	out := make([]string, 0, n)
	for _, b := range r.balancer {
		for _, t := range b["selector"].([]string) {
			if !seen[t] {
				seen[t] = true
				out = append(out, t)
			}
		}
	}
	return out
}

func (r *renderer) routing() (obj, error) {
	// +2: the TUN DNS rule and the explicit final rule.
	rules := make([]obj, 0, len(r.plan.Rules)+2)
	if r.plan.Tun.Enabled {
		// TCP carries retries after truncated UDP responses and must use the
		// same resolver instead of forwarding the machine's DNS address abroad.
		rules = append(rules, obj{"inboundTag": []string{tagTun}, "network": "tcp,udp", "port": "53", "outboundTag": tagDNS})
	}
	final := obj{"network": "tcp,udp", "outboundTag": tagDirect}
	for _, rule := range r.plan.Rules {
		field, tag, err := r.target(rule.Target, 0)
		if err != nil {
			return nil, err
		}
		if rule.Type == engine.RuleMatchAll {
			final = obj{"network": "tcp,udp", field: tag}
			break
		}
		match, err := match(rule)
		if err != nil {
			return nil, err
		}
		match[field] = tag
		rules = append(rules, match)
	}
	// Add an explicit final rule because Xray otherwise uses its first
	// outbound for unmatched traffic.
	rules = append(rules, final)
	out := obj{"domainStrategy": "IPIfNonMatch", "rules": rules}
	if len(r.balancer) > 0 {
		out["balancers"] = r.balancer
	}
	return out, nil
}

func match(rule engine.Rule) (obj, error) {
	v := rule.Value
	switch rule.Type {
	case engine.RuleDomain:
		return obj{"domain": []string{"full:" + v}}, nil
	case engine.RuleDomainSuffix:
		return obj{"domain": []string{"domain:" + v}}, nil
	case engine.RuleDomainKeyword:
		return obj{"domain": []string{"keyword:" + v}}, nil
	case engine.RuleGeoSite:
		return obj{"domain": []string{"geosite:" + strings.ToLower(v)}}, nil
	case engine.RuleIPCIDR:
		return obj{"ip": []string{v}}, nil
	case engine.RuleGeoIP:
		cc := strings.ToLower(v)
		if cc == "lan" {
			cc = "private"
		}
		return obj{"ip": []string{"geoip:" + cc}}, nil
	case engine.RulePort:
		return obj{"port": v}, nil
	case engine.RuleSrcPort:
		return obj{"sourcePort": v}, nil
	case engine.RuleProcess:
		return obj{"process": []string{v}}, nil
	case engine.RuleProtocol:
		return obj{"network": strings.ToLower(v)}, nil
	}
	return nil, fmt.Errorf("xray: rule type %q is not supported", rule.Type)
}

// dns renders resolvers. Proxy-only DNS follows routing; other resolvers use
// direct "+local" dialing.
func (r *renderer) dns() (obj, error) {
	// +1: the localhost fallback.
	servers := make([]any, 0, len(r.plan.DNS.Servers)+1)
	for _, s := range r.plan.DNS.Servers {
		addr := s.Address
		if s.Port != 0 {
			addr = net.JoinHostPort(s.Address, strconv.Itoa(int(s.Port)))
		}
		local := "+local"
		if s.ProxyOnly {
			local = ""
		}
		switch s.Transport {
		case engine.DNSSystem:
			servers = append(servers, "localhost")
		case engine.DNSPlain, "":
			servers = append(servers, addr)
		case engine.DNSTCP:
			servers = append(servers, "tcp"+local+"://"+addr)
		case engine.DNSTLS:
			servers = append(servers, "tls://"+addr)
		case engine.DNSHTTPS:
			servers = append(servers, "https"+local+"://"+addr+"/dns-query")
		case engine.DNSQUIC:
			servers = append(servers, "quic+local://"+addr)
		default:
			if s.Transport == engine.DNSH3 {
				return nil, fmt.Errorf("xray: dns transport %q is not supported (xray has no DNS-over-HTTP/3); use https:// for DNS over HTTPS, or the sing-box/mihomo engine for DoH3", s.Transport)
			}
			return nil, fmt.Errorf("xray: dns transport %q is not supported", s.Transport)
		}
	}
	if len(servers) == 0 {
		servers = append(servers, "localhost")
	}
	strategy := "UseIPv4"
	if r.plan.Options.IPv6 {
		strategy = "UseIP"
	}
	return obj{"servers": servers, "queryStrategy": strategy}.set("disableCache", r.plan.DNS.DisableCache), nil
}

func logLevel(level string) string {
	switch level {
	case "silent":
		return "none"
	case "debug", "info", "warning", "error":
		return level
	}
	return "warning"
}

func orDefault(v, fallback string) string {
	if v == "" {
		return fallback
	}
	return v
}

// RenderProbe exposes each outbound through its own loopback SOCKS inbound to
// batch measurements without changing session routing.
func RenderProbe(outbounds []engine.Outbound, ports []int) ([]byte, error) {
	if len(outbounds) != len(ports) {
		return nil, errors.New("xray: one port per outbound is required")
	}
	r := renderer{plan: &engine.Plan{Outbounds: outbounds},
		tags:   make(map[string]string, len(outbounds)),
		groups: map[string]engine.Group{}, byGroup: map[string]string{}}
	inbounds := make([]obj, 0, len(outbounds))
	rendered := make([]obj, 0, len(outbounds))
	rules := make([]obj, 0, len(outbounds))
	for i, o := range outbounds {
		in := "in-" + strconv.Itoa(i+1)
		inbounds = append(inbounds, obj{"tag": in, "protocol": "socks", "listen": "127.0.0.1", "port": ports[i]})
		if o.Protocol == engine.ProtocolXrayProfile {
			obs, first, err := probeProfile(o, i)
			if err != nil {
				return nil, err
			}
			rendered = append(rendered, obs...)
			rules = append(rules, obj{"inboundTag": []string{in}, "outboundTag": first})
			continue
		}
		r.tags[o.ID] = outboundTag(i)
		ob, err := r.outbound(o)
		if err != nil {
			return nil, err
		}
		rendered = append(rendered, ob)
		rules = append(rules, obj{"inboundTag": []string{in}, "outboundTag": r.tags[o.ID]})
	}
	return json.Marshal(obj{
		"log":       obj{"loglevel": "error"},
		"inbounds":  inbounds,
		"outbounds": rendered,
		"routing":   obj{"rules": rules},
	})
}
