package mihomo

import (
	"encoding/base64"
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
		if o.Plugin != "" {
			// An explicit SIP002 plugin goes through mihomo's plugin
			// path; the legacy Obfs mapping below stays for the native
			// simple-obfs fields.
			px.SSPlugin = o.Plugin
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
		if o.CongestionControl != "" {
			px.CongestionController = o.CongestionControl
		}
		if o.UDPRelayMode != "" {
			px.UDPRelayMode = o.UDPRelayMode
		}
	case engine.ProtocolAnyTLS:
		// AnyTLS mandates TLS on the wire; the plan carries the SNI and
		// the uTLS client fingerprint in TLS. Stream transports do not
		// apply to it.
		px.Type = "anytls"
		px.Password = o.Password
		if err := applyTLS(&px, o); err != nil {
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
		if o.Amnezia != nil {
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
		if err := applyTLS(&px, o); err != nil {
			return proxy{}, err
		}
		return px, nil
	default:
		return proxy{}, fmt.Errorf("mihomo: protocol %q is not supported", o.Protocol)
	}

	if err := applyTransport(&px, o.Transport); err != nil {
		return proxy{}, err
	}
	if err := applyTLS(&px, o); err != nil {
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
		px.Network = "tcp"
	case "ws":
		px.Network = "ws"
		px.WSOpts = &wsOpts{Path: t.Path, Headers: headers, MaxEarlyData: t.EarlyData}
	case "httpupgrade":
		// mihomo carries HTTPUpgrade as a flavour of its websocket
		// transport.
		px.Network = "ws"
		px.WSOpts = &wsOpts{Path: t.Path, Headers: headers, V2RayHTTPUpgrade: true}
	case "grpc":
		px.Network = "grpc"
		px.GRPCOpts = &grpcOpts{ServiceName: t.Service}
	case "h2":
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
func applyTLS(px *proxy, o engine.Outbound) error {
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
		px.SNI = o.TLS.ServerName
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
		if o.TLS.RealityPublicKey == "" {
			return fmt.Errorf("mihomo: outbound %s uses reality without a public key", o.ID)
		}
		// REALITY only works behind a uTLS fingerprint; default to
		// engine.DefaultFingerprint when the plan carries none, like the
		// sing-box and Xray renderers do (legacy port of af8d343).
		px.Fingerprint = orDefault(o.TLS.Fingerprint, engine.DefaultFingerprint)
		px.Reality = &reality{PublicKey: o.TLS.RealityPublicKey, ShortID: o.TLS.RealityShortID}
		// PASS3 deep S2: the plan's REALITY key-share knob, third leg
		// of PASS2 S3. hybrid -> support-x25519mlkem768: true,
		// classical -> false explicitly; unset leaves the key out
		// (mihomo's default is not confirmed from the pinned docs).
		switch o.TLS.KeyShare {
		case "hybrid":
			v := true
			px.Reality.SupportMLKEM768 = &v
		case "classical":
			v := false
			px.Reality.SupportMLKEM768 = &v
		}
	} else if o.TLS.Fingerprint != "" {
		px.Fingerprint = o.TLS.Fingerprint
	}
	return nil
}

// mihomoECHConfig converts the plan's pinned ECHConfigList to the
// ech-opts.config spelling: one base64 string. The plan stores PEM
// lines (the shape sing-box takes); strip the armor, join the body,
// verify it really is base64, and re-encode it as a single string.
// Bare base64 lines (no armor) pass through the same path. More than
// one PEM block cannot be merged into mihomo's single config value —
// each block is a complete ECHConfigList, and concatenating two lists
// is not a list — so that shape fails closed instead of rendering a
// config mihomo would reject or misread.
func mihomoECHConfig(lines []string) (string, error) {
	if len(lines) == 0 {
		return "", nil
	}
	blocks := 0
	var body strings.Builder
	for _, ln := range lines {
		ln = strings.TrimSpace(ln)
		switch {
		case strings.HasPrefix(ln, "-----BEGIN"):
			blocks++
		case strings.HasPrefix(ln, "-----END"), ln == "":
			// armor trailer or blank line: no payload
		default:
			body.WriteString(ln)
		}
	}
	if blocks > 1 {
		return "", fmt.Errorf("mihomo: %d pinned ECH configs cannot be merged into the single ech-opts.config value", blocks)
	}
	raw, err := base64.StdEncoding.DecodeString(body.String())
	if err != nil || len(raw) == 0 {
		return "", fmt.Errorf("mihomo: the pinned ECH config is not PEM/base64 ECHConfigList data")
	}
	return base64.StdEncoding.EncodeToString(raw), nil
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
	case "v2ray-plugin":
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
