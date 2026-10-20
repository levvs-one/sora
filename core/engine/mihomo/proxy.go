package mihomo

import (
	"fmt"
	"maps"
	"net"
	"net/netip"
	"strconv"
	"strings"
	"unicode"

	"github.com/levvs-one/sora-client/core/engine"
)

// buildProxy converts an outbound to a mihomo proxy. The caller sets its name
// to ensure plan-wide uniqueness. mux carries the plan's REALITY
// multiplexing policy (T007): mux on by default for REALITY outbounds.
func buildProxy(o engine.Outbound, mux engine.MuxOptions) (proxy, error) {
	return buildProxyPolicy(o, mux, engine.FingerprintPolicy{})
}

// buildProxyPolicy is buildProxy with the plan's fingerprint policy:
// the render path passes p.Options.Fingerprint so resolution matches
// the other engines (fingerprint_policy.go).
func buildProxyPolicy(o engine.Outbound, mux engine.MuxOptions, policy engine.FingerprintPolicy) (proxy, error) {
	udp := o.Protocol != engine.ProtocolHTTP && (o.Protocol != engine.ProtocolSOCKS5 || o.SOCKSUDP)
	px := proxy{Type: "ss", Tag: o.ID, UDP: &udp, IPVer: "dual"}
	// WireGuard uses its peer's server address.
	if o.Server == "" && o.Protocol != engine.ProtocolWireGuard {
		return proxy{}, fmt.Errorf("mihomo: outbound %s has no server", o.ID)
	}
	px.Server = o.Server
	px.Port = int(o.Port)

	switch o.Protocol {
	case engine.ProtocolShadowsocks:
		px.Type = "ss"
		px.Cipher = orDefault(o.Cipher, "aes-256-gcm")
		px.Password = o.Password
		if !engine.SupportsShadowsocksMethod(engine.KindMihomo, o.Cipher) {
			return proxy{}, fmt.Errorf("mihomo: shadowsocks outbound %s uses method %q, which mihomo does not implement", o.ID, px.Cipher)
		}
		if o.Plugin != "" {
			// An explicit SIP002 plugin goes through mihomo's plugin
			// path; the legacy Obfs mapping below stays for the native
			// simple-obfs fields. The plugin NAME must be translated:
			// mihomo's adapter matches its own spellings ("obfs", not
			// the SIP002 binary name "obfs-local"; "restls", not
			// "restls-plugin") and silently ignores any other name —
			// the outbound would run unobfuscated (CENSOR-P4, read
			// from the pinned adapter/outbound/shadowsocks.go).
			spec := engine.SSPluginByName(o.Plugin)
			if spec == nil || !engine.SupportsSSPlugin(engine.KindMihomo, o.Plugin) {
				return proxy{}, fmt.Errorf("mihomo: shadowsocks outbound %s uses plugin %q, which mihomo does not implement", o.ID, o.Plugin)
			}
			px.SSPlugin = spec.MihomoName
			if px.SSPlugin == "" {
				px.SSPlugin = spec.Name
			}
			if opts := ssPluginOpts(o.Plugin, o.PluginOpts); len(opts) > 0 {
				px.SSPluginOpts = opts
			}
		} else if o.Obfs != "" {
			px.Obfs = o.Obfs
			px.ObfsParam = o.ObfsParam
		}
	case engine.ProtocolVMess:
		px.Type = "vmess"
		px.UUID = o.UUID
		px.AlterID = new(int)
		px.Cipher = orDefault(o.Cipher, "auto")
	case engine.ProtocolVLESS:
		px.Type = "vless"
		px.UUID = o.UUID
		px.Flow = o.Flow
		px.Encryption = o.Encryption
	case engine.ProtocolTrojan:
		px.Type = "trojan"
		px.Password = o.Password
	case engine.ProtocolHysteria2:
		px.Type = "hysteria2"
		px.Password = o.Password
		if o.Obfs != "" {
			px.Obfs = o.Obfs
			px.ObfsPassword = o.ObfsParam
		}
		// Bandwidth caps switch the engine from BBR to Brutal congestion
		// control; zero means auto.
		if o.UpMbps > 0 {
			px.Up = strconv.Itoa(o.UpMbps) + " Mbps"
		}
		if o.DownMbps > 0 {
			px.Down = strconv.Itoa(o.DownMbps) + " Mbps"
		}
		if o.HopPorts != "" {
			px.Ports = o.HopPorts
		}
		if o.HopInterval > 0 {
			px.HopInterval = o.HopInterval
		}
	case engine.ProtocolTUIC:
		px.Type = "tuic"
		px.UUID = o.UUID
		px.Password = o.Password
		// v4 servers authenticate with a token instead of uuid+password.
		if o.Token != "" {
			px.Token = o.Token
		}
		// The effective congestion controller always renders (the
		// plan value, or DefaultTUICCongestion): mihomo silently
		// accepts an omitted or unknown controller and falls back
		// to its own default, so spelling the effective value is
		// what keeps a plan's controller identical across engines
		// (CENSOR-P3, verified with `mihomo -t`).
		px.CongestionController = o.EffectiveTUICCongestion()
		if o.UDPRelayMode != "" {
			px.UDPRelayMode = o.UDPRelayMode
		}
		// TUIC heartbeat in mihomo's spelling: milliseconds.
		px.HeartbeatInterval = o.EffectiveTUICHeartbeatSeconds() * 1000
	case engine.ProtocolAnyTLS:
		// AnyTLS mandates TLS on the wire; the plan carries the SNI and
		// the uTLS client fingerprint in TLS. Stream transports do not
		// apply to it.
		px.Type = "anytls"
		px.Password = o.Password
		if err := applyTLS(&px, o, policy); err != nil {
			return proxy{}, err
		}
		tls := true
		px.TLS = &tls
		return px, nil
	case engine.ProtocolWireGuard:
		px.Type = "wireguard"
		px.PrivateKey = o.PrivateKey
		px.MTU = 1420
		for _, address := range o.Addresses {
			prefix, err := netip.ParsePrefix(address)
			if err != nil {
				return proxy{}, fmt.Errorf("mihomo: wireguard outbound %s: address %q: %w", o.ID, address, err)
			}
			if prefix.Addr().Is4() && px.IP == "" {
				px.IP = prefix.Addr().String()
			} else if prefix.Addr().Is6() && px.IPv6 == "" {
				px.IPv6 = prefix.Addr().String()
			}
		}
		if px.IP == "" && px.IPv6 == "" {
			return proxy{}, fmt.Errorf("mihomo: wireguard outbound %s has no interface address", o.ID)
		}
		if !o.Amnezia.IsZero() {
			opts, err := amneziaOptions(o.Amnezia)
			if err != nil {
				return proxy{}, err
			}
			px.Amnezia = opts
		}
		peers, err := wireguardPeers(o)
		if err != nil {
			return proxy{}, err
		}
		// mihomo stores a single peer on the proxy and multiple peers
		// in the peers list.
		if len(peers) == 1 {
			p := peers[0]
			px.Server, px.Port = p.Server, p.Port
			px.PublicKey, px.PreSharedKey, px.AllowedIPs = p.PublicKey, p.PreSharedKey, p.AllowedIPs
			px.PersistentKeepalive = p.PersistentKeepalive
		} else {
			px.Peers = peers
		}

	case engine.ProtocolSOCKS5, engine.ProtocolHTTP:
		px.Type = "socks5"
		if o.Protocol == engine.ProtocolHTTP {
			px.Type = "http"
		}
		px.Username = o.UserID
		px.Password = o.Password
		// HTTPS proxies require TLS to avoid sending credentials in
		// cleartext.
		if err := applyTLS(&px, o, policy); err != nil {
			return proxy{}, err
		}
		return px, nil
	default:
		return proxy{}, fmt.Errorf("mihomo: protocol %q is not supported", o.Protocol)
	}

	if err := applyTransport(&px, o.Transport); err != nil {
		return proxy{}, err
	}
	if err := applyTLS(&px, o, policy); err != nil {
		return proxy{}, err
	}
	if engine.RealityMux(o, mux) {
		// mihomo DOES carry the vision flow (flow is passed through to
		// its VLESS stack above), so mux is suppressed under vision
		// here exactly as on the other engines — engine.RealityMux is
		// flow-aware (PASS3 deep S3a). Without vision: one TLS
		// connection instead of many parallel handshakes sharing one
		// SNI (T007).
		px.Smux = &smux{Enabled: true, Protocol: "smux"}
	}
	return px, nil
}

// applyTransport writes the nested options of the stream transport.
func applyTransport(px *proxy, t engine.Transport) error {
	headers := maps.Clone(t.Headers)
	if t.Host != "" && t.Type != "h2" && t.Type != "xhttp" {
		if headers == nil {
			headers = map[string]string{}
		}
		headers["Host"] = t.Host
	}
	switch t.Type {
	case "", "tcp", "raw":
		if len(t.Headers) > 0 {
			// A raw stream has no HTTP handshake to carry headers;
			// plan validation rejects the set, and this is the
			// render-time backstop (CENSOR-P2 fix). The check reads
			// t.Headers, not the merged headers map above: that map
			// can hold the Host field alone, which must not trigger
			// this refusal.
			return fmt.Errorf("mihomo: headers have no spelling on a raw stream and mihomo does not render them")
		}
		px.Network = "tcp"
	case "ws":
		px.Network = "ws"
		px.WSOpts = &wsOpts{Path: t.Path, Headers: headers, MaxEarlyData: t.EarlyData, EarlyDataHeaderName: t.EarlyDataHeaderName}
	case "httpupgrade":
		// mihomo carries HTTPUpgrade as a flavour of its websocket
		// transport.
		px.Network = "ws"
		px.WSOpts = &wsOpts{Path: t.Path, Headers: headers, V2RayHTTPUpgrade: true}
	case "grpc":
		if t.GRPCAuthority != "" || t.GRPCMultiMode {
			// mihomo's grpc-opts has no authority or multi-mode key
			// and its YAML loader ignores unknown keys: emitting them
			// would drop the fields silently. Catalog MissingFor
			// keeps such plans on Xray; this is the render backstop.
			return fmt.Errorf("mihomo: grpc authority and multi-mode are Xray-only and mihomo does not render them")
		}
		if len(t.Headers) > 0 {
			// grpc-opts spells only the service name and user agent;
			// a headers key would be silently ignored by the YAML
			// loader. Plan validation rejects the set; this is the
			// render backstop (CENSOR-P2 fix).
			return fmt.Errorf("mihomo: headers have no spelling on the grpc transport and mihomo does not render them")
		}
		px.Network = "grpc"
		px.GRPCOpts = &grpcOpts{ServiceName: t.Service, UserAgent: t.GRPCUserAgent}
	case "h2":
		if len(t.Headers) > 0 {
			// h2-opts spells only host and path; the header set is a
			// sing-box-only spelling on this transport, catalog-gated
			// via FeatureH2Headers, and this refusal is the render
			// backstop (CENSOR-P2 fix).
			return fmt.Errorf("mihomo: headers on the h2 transport are sing-box-only and mihomo does not render them")
		}
		px.Network = "h2"
		px.H2Opts = &h2Opts{Path: t.Path}
		if t.Host != "" {
			px.H2Opts.Host = []string{t.Host}
		}
	case "xhttp":
		px.Network = "xhttp"
		// Mode passes through verbatim: the pinned docs list "auto"
		// among the available mode values ("Mode. Available values:
		// auto, stream-one, stream-up, or packet-up"), so a plan's
		// explicit auto is legal here, not a leak (PASS3 deep A1
		// sub-check, resolved against the docs).
		opts := &xhttpOpts{Path: t.Path, Host: t.Host, Mode: t.Mode, Headers: maps.Clone(t.Headers),
			XPaddingBytes: t.XPaddingBytes, ReuseSettings: xhttpReuseSettings(t)}
		if t.DownloadAddress != "" {
			opts.DownloadSettings = &xhttpDownload{
				Server: t.DownloadAddress, Port: int(t.DownloadPort),
				ReuseSettings: xhttpReuseSettings(t),
			}
		}
		px.XHTTPOpts = opts
	default:
		return fmt.Errorf("mihomo: transport %q is not supported", t.Type)
	}
	return nil
}

// xhttpReuseSettings renders reuse-settings (XMUX) from the plan's
// xmux tuning. Unlike the original Xray implementation, mihomo's
// reuse-settings has NO default value: omitting the block disables
// connection reuse entirely — every request opens a new underlying
// connection (pinned docs, transport configuration). The block is
// therefore always emitted: the plan's tuning when the plan carries
// it, otherwise the docs' example default (max-concurrency "16-32")
// so the mihomo path reuses connections like the other engines
// instead of paying a fresh TCP+TLS handshake per request (PASS3
// deep A1). The default is only used when the plan tunes nothing:
// max-concurrency conflicts with max-connections, so a tuned plan
// must never grow a default concurrency on top of its connections.
func xhttpReuseSettings(t engine.Transport) *xhttpReuse {
	r := &xhttpReuse{}
	if t.XmuxMaxConcurrency > 0 {
		r.MaxConcurrency = strconv.Itoa(t.XmuxMaxConcurrency)
	}
	if t.XmuxMaxConnections > 0 {
		r.MaxConnections = strconv.Itoa(t.XmuxMaxConnections)
	}
	if t.XmuxMaxReuseTimes > 0 {
		r.CMaxReuseTimes = strconv.Itoa(t.XmuxMaxReuseTimes)
	}
	if t.XmuxMaxRequestTimes > 0 {
		r.HMaxRequestTimes = strconv.Itoa(t.XmuxMaxRequestTimes)
	}
	if r.MaxConcurrency == "" && r.MaxConnections == "" && r.CMaxReuseTimes == "" && r.HMaxRequestTimes == "" {
		r.MaxConcurrency = "16-32"
	}
	return r
}

func wireguardPeers(o engine.Outbound) ([]wireguardPeer, error) {
	if len(o.Peers) == 0 {
		return nil, fmt.Errorf("mihomo: wireguard outbound %s has no peer", o.ID)
	}
	out := make([]wireguardPeer, 0, len(o.Peers))
	for _, peer := range o.Peers {
		host, portText, err := net.SplitHostPort(peer.Endpoint)
		if err != nil {
			return nil, fmt.Errorf("mihomo: wireguard outbound %s: peer endpoint: %w", o.ID, err)
		}
		port, err := strconv.Atoi(portText)
		if err != nil {
			return nil, fmt.Errorf("mihomo: wireguard outbound %s: peer port %q", o.ID, portText)
		}
		out = append(out, wireguardPeer{
			Server: host, Port: port, PublicKey: peer.PublicKey, PreSharedKey: peer.PreSharedKey,
			AllowedIPs: peer.AllowedIPs, PersistentKeepalive: peer.PersistentKeepalive,
		})
	}
	return out, nil
}

// amneziaOptions renders amnezia-wg-option keys. Numeric headers stay numbers
// for 1.x; 2.0 also accepts ranges.
//
// AmneziaWG 3.x (PASS2 deep S1, PASS3): the pinned mihomo (1.19.32;
// 3.0/3.1 support landed in 1.19.30, DisableCookies/RandomPadding
// fixed in 1.19.31) implements the 3.x parameters in its
// AmneziaWGOption — version, header-protection-key,
// content-padding-addition, the ranged timings, random-trailers,
// disable-cookies. The old blanket refusal ("mihomo only knows the
// 1.x/2.0 keys") contradicted the pin and cost the AWG 3.1 failover
// route. Two honest boundaries remain:
//   - version: 3 is mandatory with any 3.x field: without it mihomo
//     builds the legacy device and the 3.x fields do nothing — the
//     exact silent downgrade the old refusal guarded against.
//   - the id/ip/ib masquerade sugar has no mihomo fields at all
//     (FeatureAmneziaMasquerade stays sing-box-lx-only), and the
//     v1.5-only J1/J2/J3/Itime keys are incompatible with version 3;
//     both combinations fail closed here, as they do at selection.
func amneziaOptions(a *engine.AmneziaWG) (map[string]any, error) {
	if a.UsesMasquerade() {
		return nil, fmt.Errorf("mihomo: AmneziaWG id/ip/ib masquerade sugar is not implemented by mihomo's AmneziaWG stack: refusing to render a config that would silently drop the decoy")
	}
	v3 := a.UsesAWG31()
	if v3 && (a.J1 != "" || a.J2 != "" || a.J3 != "" || a.Itime != 0) {
		return nil, fmt.Errorf("mihomo: AmneziaWG J1/J2/J3/Itime are v1.5-only and incompatible with version 3: refusing the combination instead of dropping them silently")
	}
	out := map[string]any{}
	ints := map[string]int{"jc": a.Jc, "jmin": a.Jmin, "jmax": a.Jmax, "s1": a.S1, "s2": a.S2, "s3": a.S3, "s4": a.S4, "itime": a.Itime}
	for key, v := range ints {
		if v != 0 {
			out[key] = v
		}
	}
	strs := map[string]string{"h1": a.H1, "h2": a.H2, "h3": a.H3, "h4": a.H4,
		"i1": a.I1, "i2": a.I2, "i3": a.I3, "i4": a.I4, "i5": a.I5, "j1": a.J1, "j2": a.J2, "j3": a.J3}
	for key, v := range strs {
		if v == "" {
			continue
		}
		if n, err := strconv.ParseInt(v, 10, 64); err == nil && strings.HasPrefix(key, "h") {
			out[key] = n
			continue
		}
		out[key] = v
	}
	if v3 {
		out["version"] = 3
		if a.HeaderProtectionKey != "" {
			out["header-protection-key"] = a.HeaderProtectionKey
		}
		ranges := map[string]string{
			"content-padding-addition": a.ContentPaddingAddition,
			"rekey-after-time":         a.RekeyAfterTime,
			"rekey-timeout":            a.RekeyTimeout,
			"reject-after-time":        a.RejectAfterTime,
			"keepalive-timeout":        a.KeepaliveTimeout,
			"max-handshake-attempts":   a.MaxHandshakeAttempts,
		}
		for key, v := range ranges {
			if v != "" {
				out[key] = v
			}
		}
		if a.RandomTrailers {
			out["random-trailers"] = true
		}
		if a.DisableCookies {
			out["disable-cookies"] = true
		}
	}
	return out, nil
}

// applyTLS writes TLS, SNI, ALPN, uTLS fingerprint and Reality parameters.
func applyTLS(px *proxy, o engine.Outbound, policy engine.FingerprintPolicy) error {
	if o.Protocol == engine.ProtocolWireGuard {
		return nil
	}
	enabled := o.TLS.Enabled
	switch o.Protocol {
	case engine.ProtocolTrojan, engine.ProtocolHysteria2, engine.ProtocolTUIC:
		enabled = true
	}
	px.TLS = &enabled
	if o.TLS.ServerName != "" {
		// vless and vmess read the TLS server name from "servername"
		// only; the remaining TLS adapters (trojan, anytls, hysteria2,
		// tuic, http) read "sni" (see the ServerName field comment in
		// config.go). The wrong key is silently ignored by mihomo,
		// which then verifies the peer certificate against the dial
		// address: a REALITY or TLS handshake to an IP-addressed
		// server with a domain SNI always failed.
		switch o.Protocol {
		case engine.ProtocolVLESS, engine.ProtocolVMess:
			px.ServerName = o.TLS.ServerName
		default:
			px.SNI = o.TLS.ServerName
		}
	}
	if len(o.TLS.ALPN) > 0 {
		px.ALPN = o.TLS.ALPN
	}
	if o.TLS.ECH.Enabled {
		cfg, err := mihomoECHConfig(o.TLS.ECH.Config)
		if err != nil {
			return err
		}
		px.ECH = &echOpts{Enable: true, Config: cfg, QueryServerName: o.TLS.ECH.QueryServerName}
	}
	if o.TLS.Insecure {
		skip := true
		px.SkipCertVerify = &skip
	}
	if o.TLS.Reality {
		if o.TLS.RealityMLDSA65Verify != "" {
			// Fail closed behind the FeatureRealityMLDSA65 gate:
			// mihomo silently ignores unknown reality-opts keys
			// (probed on the pin, 2026-10-20), so rendering here
			// would drop the pinned ML-DSA-65 server check without
			// a trace.
			return fmt.Errorf("mihomo: outbound %s pins a REALITY mldsa65Verify key, which mihomo does not implement: refusing to render a handshake without the ML-DSA-65 server check", o.ID)
		}
		if o.TLS.RealityPublicKey == "" {
			return fmt.Errorf("mihomo: outbound %s uses reality without a public key", o.ID)
		}
		// REALITY only works behind a uTLS fingerprint; the name
		// resolves through the plan's policy, the single source every
		// renderer shares (fingerprint_policy.go) — explicit value
		// (normalized), per-protocol profile, then the canonical
		// default, as on the sing-box and Xray paths.
		px.Fingerprint = engine.ResolveFingerprint(engine.KindMihomo, o, policy)
		px.Reality = &reality{PublicKey: o.TLS.RealityPublicKey, ShortID: o.TLS.RealityShortID}
		// PASS3 deep S2: the plan's REALITY key-share knob, third leg
		// of PASS2 S3. hybrid -> support-x25519mlkem768: true,
		// classical -> false explicitly; unset leaves the key out.
		// The unset default is now MEASURED, not just undocumented:
		// a wire capture against the pinned 1.19.32 binary shows the
		// default ClientHello carrying NO X25519MLKEM768 group (a
		// ~590-byte hello vs ~1780 with the hybrid), so "" honestly
		// means "mihomo's default, which offers no hybrid" (CENSOR-FP).
		switch o.TLS.KeyShare {
		case "hybrid":
			v := true
			px.Reality.SupportMLKEM768 = &v
		case "classical":
			v := false
			px.Reality.SupportMLKEM768 = &v
		}
	} else if fp := engine.ResolveFingerprint(engine.KindMihomo, o, policy); fp != "" {
		px.Fingerprint = fp
	}
	return nil
}

// mihomoECHConfig converts the plan's pinned ECHConfigList to the
// ech-opts.config spelling: one base64 string. The conversion itself
// is the shared engine helper (echconfig.go): strip any armor, verify
// the body is one base64 ECHConfigList, re-encode canonically. More
// than one PEM block cannot be merged into mihomo's single config
// value — each block is a complete ECHConfigList — so that shape
// fails closed here with the mihomo context attached.
func mihomoECHConfig(lines []string) (string, error) {
	if len(lines) == 0 {
		return "", nil
	}
	out, err := engine.ECHConfigListBase64(lines)
	if err != nil {
		return "", fmt.Errorf("mihomo: %w", err)
	}
	return out, nil
}

// ssPluginOpts translates a SIP002 plugin option string ("k=v;k;flag")
// into mihomo's plugin-opts map. obfs-local and v2ray-plugin get their
// native key names; anything else passes through generically and mihomo
// validates it (fail-closed on unknown plugins).
func ssPluginOpts(plugin, opts string) map[string]any {
	raw := map[string]string{}
	for _, part := range strings.Split(opts, ";") {
		if part = strings.TrimSpace(part); part == "" {
			continue
		}
		k, v, _ := strings.Cut(part, "=")
		raw[strings.TrimSpace(k)] = strings.TrimSpace(v)
	}
	switch plugin {
	case "obfs-local":
		// simple-obfs: "obfs=tls;obfs-host=example.com".
		out := map[string]any{}
		if m, ok := raw["obfs"]; ok {
			out["mode"] = m
		}
		if h, ok := raw["obfs-host"]; ok {
			out["host"] = h
		}
		return out
	case "v2ray-plugin", "gost-plugin":
		// gost-plugin's mihomo option shape mirrors v2ray-plugin's
		// (its adapter decodes the same fields and likewise requires
		// mode "websocket"); without the shared case it fell into the
		// generic passthrough and never got the mandatory mode.
		out := map[string]any{"mode": "websocket"}
		for k, v := range raw {
			switch k {
			case "tls", "mux":
				// Bare flags mean enabled; explicit values parse as bool.
				out[k] = v == "" || v == "1" || strings.EqualFold(v, "true")
			default:
				out[k] = v
			}
		}
		return out
	default:
		out := map[string]any{}
		for k, v := range raw {
			out[k] = v
		}
		return out
	}
}

// sanitizeName removes unsafe display-name characters. Commas, slashes, and
// controls can alter mihomo rules or break name-based URLs.
func sanitizeName(name, fallback string) string {
	src := name
	if src == "" {
		src = fallback
	}
	var b strings.Builder
	for _, r := range src {
		switch {
		case unicode.IsLetter(r) || unicode.IsDigit(r):
			b.WriteRune(r)
		case r == '-', r == '_', r == '.':
			b.WriteRune(r)
		case r == ' ':
			b.WriteRune('_')
		}
		if b.Len() > 96 {
			break
		}
	}
	out := strings.Trim(b.String(), "-_.")
	if out == "" {
		out = "server"
	}
	return out
}

// uniqueName appends a counter until the name is free.
func uniqueName(name string, used map[string]struct{}) string {
	candidate := name
	for i := 2; ; i++ {
		if _, taken := used[candidate]; !taken {
			used[candidate] = struct{}{}
			return candidate
		}
		candidate = fmt.Sprintf("%s-%d", name, i)
	}
}

func orDefault(v, fallback string) string {
	if strings.TrimSpace(v) == "" {
		return fallback
	}
	return v
}

func orDefaultInt(v, fallback int) int {
	if v <= 0 {
		return fallback
	}
	return v
}
