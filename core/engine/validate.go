package engine

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"regexp"
	"slices"
	"sort"
	"strconv"
	"strings"
)

// Secrets returns every value of the plan that must never reach a log, an
// event or a diagnostic archive.
func (p *Plan) Secrets() []string {
	if p == nil {
		return nil
	}
	out := make([]string, 0, len(p.Outbounds)*4+1)
	for _, o := range p.Outbounds {
		out = o.appendSecrets(out)
	}
	if len(p.LocalProxy.Password) >= 4 {
		out = append(out, p.LocalProxy.Password)
	}
	return out
}

// Secrets lists the secret fields of one outbound. Values shorter than four
// characters are skipped: masking them would destroy ordinary log text.
func (o Outbound) Secrets() []string {
	return o.appendSecrets(make([]string, 0, 12))
}

// appendSecrets appends the outbound's secrets to dst in the same order
// Secrets has always returned them. Building a plan's list through it
// allocates one backing array for the whole plan instead of two per
// outbound (a candidates slice and a filtered copy): on the Connect path
// that was ~1000 allocations for a 200-server plan.
func (o Outbound) appendSecrets(dst []string) []string {
	add := func(c string) {
		if len(c) >= 4 {
			dst = append(dst, c)
		}
	}
	add(o.UUID)
	add(o.Password)
	add(o.UserID)
	add(o.ObfsParam)
	add(o.PluginOpts)
	add(o.Token)
	add(o.PrivateKey)
	if o.Amnezia != nil {
		// The header-protection key is key material like the private
		// key: it must never reach a log, an event or a diagnostic
		// archive.
		add(o.Amnezia.HeaderProtectionKey)
	}
	if o.Encryption != "none" {
		add(o.Encryption)
	}
	// A WebSocket/XHTTP path and custom header values are routinely
	// used as bearer tokens by providers ("secret path" deployments);
	// they were registered nowhere, so a dial error echoing the
	// request line or headers leaked them (CENSOR-LEAK).
	add(o.Transport.Path)
	headerKeys := make([]string, 0, len(o.Transport.Headers))
	for k := range o.Transport.Headers {
		headerKeys = append(headerKeys, k)
	}
	sort.Strings(headerKeys)
	for _, k := range headerKeys {
		add(o.Transport.Headers[k])
	}
	for _, p := range o.Peers {
		add(p.PreSharedKey)
	}
	for _, s := range profileSecrets(o.Profile) {
		add(s)
	}
	return dst
}

// Identifiers returns the server host and host:port for privacy redaction.
// These are not credentials but identify user connections and providers.
func (o Outbound) Identifiers() []string {
	return o.appendIdentifiers(make([]string, 0, 7))
}

// appendIdentifiers appends the outbound's identifiers to dst in the same
// order Identifiers has always returned them; see appendSecrets for why
// the plan-level builders go through it.
func (o Outbound) appendIdentifiers(dst []string) []string {
	if o.Server != "" {
		dst = append(dst, o.Server)
		if o.Port != 0 {
			dst = append(dst, net.JoinHostPort(o.Server, strconv.Itoa(int(o.Port))))
		}
	}
	if o.TLS.ServerName != "" {
		dst = append(dst, o.TLS.ServerName)
	}
	// REALITY parameters are public but identify the server (SORA-L9).
	if o.TLS.RealityPublicKey != "" {
		dst = append(dst, o.TLS.RealityPublicKey)
	}
	if o.TLS.RealityShortID != "" {
		dst = append(dst, o.TLS.RealityShortID)
	}
	if o.TLS.RealityMLDSA65Verify != "" {
		dst = append(dst, o.TLS.RealityMLDSA65Verify)
	}
	if o.TLS.SpiderX != "" {
		dst = append(dst, o.TLS.SpiderX)
	}
	dst = append(dst, o.Name)
	if o.Transport.Host != "" {
		dst = append(dst, o.Transport.Host)
	}
	if o.Transport.Service != "" {
		dst = append(dst, o.Transport.Service)
	}
	if o.Transport.GRPCAuthority != "" {
		dst = append(dst, o.Transport.GRPCAuthority)
	}
	if o.Transport.DownloadAddress != "" {
		dst = append(dst, o.Transport.DownloadAddress)
		if o.Transport.DownloadPort != 0 {
			dst = append(dst, net.JoinHostPort(o.Transport.DownloadAddress, strconv.Itoa(int(o.Transport.DownloadPort))))
		}
	}
	// An Xray profile carries its own server addresses, SNI names and
	// REALITY dest inside the profile JSON; without extracting them
	// here they were registered with no redactor at all (CENSOR-LEAK).
	return append(dst, profileIdentifiers(o.Profile)...)
}

// Identifiers returns plan server identifiers for redaction alongside Secrets.
func (p *Plan) Identifiers() []string {
	if p == nil {
		return nil
	}
	out := make([]string, 0, len(p.Outbounds)*6)
	for _, o := range p.Outbounds {
		out = o.appendIdentifiers(out)
	}
	return out
}

// Warnings returns codes for allowed risky settings. Clients localize them; the
// core stores no user-facing text.
func (o Outbound) Warnings() []string {
	var out []string
	if o.TLS.Insecure && o.Protocol != ProtocolDirect {
		out = append(out, "insecure-certificate")
	}
	if o.TLS.Enabled && o.TLS.ServerName == "" && o.Protocol != ProtocolDirect {
		out = append(out, "tls-server-name-missing")
	}
	if o.Transport.Type == "ws" && !o.TLS.Enabled {
		out = append(out, "websocket-without-tls")
	}
	if o.Transport.EarlyData > 0 {
		// 0-RTT puts the first payload bytes — for VMess/Trojan the
		// opening of an authenticated stream — into the handshake
		// flight: replayable by an on-path observer and a distinct
		// first-flight shape for DPI entropy heuristics (TSPU cascade).
		// It stays opt-in data, never a default, and the UI must be
		// able to say it is on.
		out = append(out, "websocket-early-data-0rtt")
	}
	if o.Transport.Type == "xhttp" {
		// XHTTP is under active development upstream: the client and
		// server cores must run matching versions, or the stream fails
		// with "strange glitches". The core cannot probe the server's
		// version, so every XHTTP outbound carries the reminder.
		out = append(out, "xhttp-version-sync")
		// Reverse proxies (nginx default 128) cap concurrent streams;
		// above it the connection breaks instead of degrading.
		if o.Transport.XmuxMaxConcurrency > 128 {
			out = append(out, "xhttp-xmux-proxy-limit")
		}
	}
	out = append(out, o.shadowsocksWarnings()...)
	// REALITY hardening (T002): vision/TLS-in-TLS and dest-shape warnings.
	out = append(out, o.RealityWarnings()...)
	return out
}

// Validate checks one outbound on its own, without engine capabilities.
// validProtocols whitelists the protocols a plan may hold, so an unknown
// protocol fails validation with a clear error instead of surfacing late at
// eng.Apply (SORA-L16).
var validProtocols = map[Protocol]bool{
	ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
	ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolTUIC: true,
	ProtocolWireGuard: true, ProtocolSOCKS5: true, ProtocolHTTP: true,
	ProtocolAnyTLS: true, ProtocolBypass: true, ProtocolXrayProfile: true,
	ProtocolDirect: true,
}

// validTransports whitelists the stream transports a plan may hold. "h2" is
// accepted at plan level for sing-box; engines that dropped it (Xray) reject
// it when rendering.
var validTransports = map[string]bool{
	"": true, "tcp": true, "ws": true, "grpc": true,
	"h2": true, "httpupgrade": true, "xhttp": true,
}

func (o Outbound) Validate() error {
	var errs []error
	if o.ID == "" {
		errs = append(errs, errors.New("outbound: empty id"))
	} else if len(o.ID) > MaxIDLen {
		errs = append(errs, fmt.Errorf("outbound %q: id longer than %d bytes", o.ID, MaxIDLen))
	}
	if err := validateDisplayName("outbound "+o.ID, o.Name); err != nil {
		errs = append(errs, err)
	}
	if !validProtocols[o.Protocol] {
		errs = append(errs, fmt.Errorf("outbound %s: unknown protocol %q", o.ID, o.Protocol))
	}
	if !validTransports[o.Transport.Type] {
		errs = append(errs, fmt.Errorf("outbound %s: unknown transport %q", o.ID, o.Transport.Type))
	}
	serverless := o.Protocol == ProtocolDirect || o.Protocol == ProtocolBypass
	if !serverless && o.Port == 0 {
		errs = append(errs, fmt.Errorf("outbound %s: port must be between 1 and 65535", o.ID))
	}
	if err := validateServer("outbound "+o.ID, o.Server, !serverless); err != nil {
		errs = append(errs, err)
	}
	if o.Protocol == ProtocolBypass {
		errs = append(errs, o.Bypass.validate(o.ID))
	}
	if o.Protocol == ProtocolHysteria2 {
		errs = append(errs, validateHysteria2Tuning(o)...)
	}
	if o.Protocol == ProtocolTUIC {
		errs = append(errs, validateTUICTuning(o)...)
	}
	if o.Protocol == ProtocolXrayProfile {
		var profile struct {
			Outbounds []json.RawMessage `json:"outbounds"`
		}
		if err := json.Unmarshal(o.Profile, &profile); err != nil || len(profile.Outbounds) == 0 {
			errs = append(errs, fmt.Errorf("outbound %s: the Xray profile has no outbounds", o.ID))
		}
	}
	if len(o.TLS.ALPN) > 8 {
		errs = append(errs, fmt.Errorf("outbound %s: too many ALPN entries", o.ID))
	}
	errs = append(errs, o.TLS.validate("outbound "+o.ID)...)
	if len(o.Transport.Headers) > MaxHeaderCount {
		errs = append(errs, fmt.Errorf("outbound %s: more than %d headers", o.ID, MaxHeaderCount))
	}
	// WebSocket 0-RTT rides the handshake; other transports have no
	// handshake to ride, so a stray value is a config bug, not a hint.
	if o.Transport.EarlyData < 0 {
		errs = append(errs, fmt.Errorf("outbound %s: early data %d must not be negative", o.ID, o.Transport.EarlyData))
	}
	if o.Transport.EarlyData > 0 && o.Transport.Type != "ws" {
		errs = append(errs, fmt.Errorf("outbound %s: early data needs the ws transport, not %q", o.ID, o.Transport.Type))
	}
	for k, v := range o.Transport.Headers {
		if !validHeaderToken(k) || strings.ContainsAny(v, "\r\n") {
			errs = append(errs, fmt.Errorf("outbound %s: header %q is not a safe HTTP header", o.ID, k))
		}
	}
	errs = append(errs, validateTransportFields(o)...)
	errs = append(errs, validateVMessTrojan(o)...)
	if o.Amnezia != nil {
		if o.Protocol != ProtocolWireGuard {
			errs = append(errs, fmt.Errorf("outbound %s: AmneziaWG parameters require the wireguard protocol", o.ID))
		} else {
			errs = append(errs, validateAmneziaWG(o.ID, o.Amnezia)...)
		}
	}
	// REALITY hardening (T002): malformed keys or shortIds fail here, not
	// at the engine.
	if err := o.ValidateReality(); err != nil {
		errs = append(errs, err)
	}
	errs = append(errs, validateXHTTP(o)...)
	return errors.Join(errs...)
}

// validateTransportFields rejects transport-scoped fields riding on a
// transport that cannot honour them. Every renderer drops unknown fields
// for its transport silently, so a stray value is a config bug, not a
// hint — the same discipline as the early-data and XHTTP checks above.
func validateTransportFields(o Outbound) []error {
	t := o.Transport
	var errs []error
	bad := func(format string, args ...any) {
		args = append([]any{o.ID}, args...)
		errs = append(errs, fmt.Errorf("outbound %s: "+format, args...))
	}
	if t.EarlyDataHeaderName != "" {
		if t.Type != "ws" {
			bad("early data header name needs the ws transport, not %q", t.Type)
		} else if t.EarlyData <= 0 {
			bad("early data header name %q has no effect without early data", t.EarlyDataHeaderName)
		} else if !validHeaderToken(t.EarlyDataHeaderName) {
			bad("early data header name %q is not a safe HTTP header name", t.EarlyDataHeaderName)
		}
	}
	if t.Service != "" && t.Type != "grpc" {
		bad("grpc service name %q needs the grpc transport, not %q", t.Service, t.Type)
	}
	if t.Type != "grpc" {
		if t.GRPCAuthority != "" {
			bad("grpc authority %q needs the grpc transport, not %q", t.GRPCAuthority, t.Type)
		}
		if t.GRPCMultiMode {
			bad("grpc multi-mode needs the grpc transport, not %q", t.Type)
		}
		if t.GRPCUserAgent != "" {
			bad("grpc user agent needs the grpc transport, not %q", t.Type)
		}
	}
	if strings.ContainsAny(t.GRPCUserAgent, "\r\n") || strings.ContainsAny(t.GRPCAuthority, "\r\n") {
		bad("grpc authority and user agent must not contain line breaks")
	}
	return errs
}

// validVMessSecurity is the VMess AEAD security set every pinned engine
// accepts, verified by running the binaries (2026-10-20): sing-box
// 1.14.3-lx.22 and mihomo 1.19.32 both refuse anything else at load
// ("unsupported security type"), while Xray 26.10.17 accepts even a
// nonsense value and silently falls back — so the whitelist must live
// here, at plan level, not in the engines. Notably absent:
// "aes-128-ctr", which older stacks listed but both Clash-lineage and
// sing-box pins reject today.
var validVMessSecurity = map[string]bool{
	"": true, "auto": true, "aes-128-gcm": true, "chacha20-poly1305": true,
	"none": true, "zero": true,
}

// validateVMessTrojan checks the VMess and Trojan credentials and the
// VMess security option engine-independently. VMess here is AEAD only:
// the plan has no alterId field by design — legacy (pre-AEAD) VMess is
// rejected at import (parser) rather than silently upgraded to AEAD,
// which a legacy server cannot authenticate.
func validateVMessTrojan(o Outbound) []error {
	var errs []error
	switch o.Protocol {
	case ProtocolVMess:
		if o.UUID == "" {
			errs = append(errs, fmt.Errorf("outbound %s: vmess needs a uuid", o.ID))
		}
		if !validVMessSecurity[o.Cipher] {
			errs = append(errs, fmt.Errorf("outbound %s: vmess security %q is not one of auto, aes-128-gcm, chacha20-poly1305, none, zero", o.ID, o.Cipher))
		}
	case ProtocolTrojan:
		if o.Password == "" {
			errs = append(errs, fmt.Errorf("outbound %s: trojan needs a password", o.ID))
		}
	}
	return errs
}

// validXHTTPModes whitelists the XHTTP stream modes every engine implements.
var validXHTTPModes = map[string]bool{
	"": true, "auto": true, "packet-up": true, "stream-up": true, "stream-one": true,
}

// xhttpPaddingRange parses an XHTTP padding range: "min-max" or a single
// number. Engines read it as a string, so the check is syntactic plus a
// sanity bound (larger than any plausible MTU is a typo, not a setting).
var xhttpPaddingRange = regexp.MustCompile(`^([0-9]{1,5})(-([0-9]{1,5}))?$`)

// validateXHTTP checks the XHTTP-only transport options engine-independently,
// so a broken combination fails at plan validation instead of surfacing as
// a runtime failure in whichever engine renders it (T009).
func validateXHTTP(o Outbound) []error {
	t := o.Transport
	if t.Type != "xhttp" {
		// The split/tuning fields belong to XHTTP; on another transport
		// they would be silently dropped by every renderer.
		var errs []error
		if t.DownloadAddress != "" || t.DownloadPort != 0 {
			errs = append(errs, fmt.Errorf("outbound %s: downloadSettings needs the xhttp transport, not %q", o.ID, t.Type))
		}
		if t.XmuxMaxConcurrency != 0 || t.XmuxMaxConnections != 0 || t.XmuxMaxReuseTimes != 0 || t.XmuxMaxRequestTimes != 0 {
			errs = append(errs, fmt.Errorf("outbound %s: xmux tuning needs the xhttp transport, not %q", o.ID, t.Type))
		}
		if t.XPaddingBytes != "" {
			errs = append(errs, fmt.Errorf("outbound %s: xPaddingBytes needs the xhttp transport, not %q", o.ID, t.Type))
		}
		return errs
	}
	var errs []error
	bad := func(format string, args ...any) {
		args = append([]any{o.ID}, args...)
		errs = append(errs, fmt.Errorf("outbound %s: xhttp "+format, args...))
	}
	if !validXHTTPModes[t.Mode] {
		bad("mode %q is not one of auto, packet-up, stream-up, stream-one", t.Mode)
	}
	if strings.HasPrefix(o.Flow, "xtls-rprx-vision") && !o.HasVLESSEncryption() {
		// XTLS is available only under TCP+TLS/REALITY — or under
		// VLESS Encryption, which carries the flow on any transport
		// (https://xtls.github.io/en/config/outbounds/vless.html).
		// Without Encryption, vision on XHTTP cannot work; XHTTP's
		// protection against TLS-in-TLS comes from xmux and the
		// up/down split instead (PASS3 deep S3b).
		bad("flow %q cannot be combined with the xhttp transport (Vision needs TCP or VLESS Encryption)", o.Flow)
	}
	if t.DownloadAddress != "" || t.DownloadPort != 0 {
		if t.DownloadAddress == "" || t.DownloadPort == 0 {
			bad("downloadSettings needs both a download address and a download port")
		} else if err := validateServer("outbound "+o.ID+" download", t.DownloadAddress, true); err != nil {
			errs = append(errs, err)
		}
		if t.Mode == "stream-one" {
			// stream-one carries both directions on one connection; a
			// separate downlink contradicts it. stream-up is the
			// two-leg mode (auto+reality degrades to stream-one only
			// without downloadSettings).
			bad("downloadSettings is incompatible with mode stream-one (use stream-up)")
		}
	}
	if t.XmuxMaxConcurrency < 0 || t.XmuxMaxConnections < 0 || t.XmuxMaxReuseTimes < 0 || t.XmuxMaxRequestTimes < 0 {
		bad("xmux values must not be negative")
	}
	if t.XmuxMaxConcurrency > 0 && t.XmuxMaxConnections > 0 {
		bad("xmux maxConcurrency and maxConnections are mutually exclusive")
	}
	if t.XPaddingBytes != "" {
		m := xhttpPaddingRange.FindStringSubmatch(t.XPaddingBytes)
		if m == nil {
			bad("xPaddingBytes %q is not a \"min-max\" range or a single number", t.XPaddingBytes)
		} else {
			lo, _ := strconv.Atoi(m[1])
			hi := lo
			if m[3] != "" {
				hi, _ = strconv.Atoi(m[3])
			}
			if lo > hi {
				bad("xPaddingBytes %q has its lower bound above the upper bound", t.XPaddingBytes)
			}
			if hi > 65535 {
				bad("xPaddingBytes %q exceeds 65535 bytes", t.XPaddingBytes)
			}
		}
	}
	if slices.Contains(o.TLS.ALPN, "h3") && !o.TLS.Enabled && !o.TLS.Reality {
		// Xray dials QUIC for XHTTP only when ALPN is exactly ["h3"] on
		// a TLS stream; without TLS the option does nothing.
		bad("ALPN h3 needs TLS (or REALITY) on the xhttp transport")
	}
	return errs
}

// validate enforces the ECH honesty rules (T024, P13-3/P13-4):
//   - ECH without TLS is meaningless;
//   - ECH and REALITY are incompatible: REALITY owns the ClientHello, an
//     ECH extension on top of it is misconfiguration, not stealth.
//
// QueryServerName is NOT rejected here: sing-box renders it
// (ech.query_server_name, available since 1.13 — below the 1.14.3
// floor) and mihomo renders it (ech-opts.query-server-name). The old
// "not rendered yet" rejection outlived the renderers that made it
// false (PASS3 deep S4). The Xray path, which renders no ECH at all,
// is closed by the FeatureECH capability gate, not by validation.
func (t TLS) validate(what string) []error {
	var errs []error
	// KeyShare is the REALITY key-share knob (PASS3 deep S2): only
	// the two documented values, and only with REALITY — anywhere
	// else it would be a setting no renderer can honour.
	switch t.KeyShare {
	case "", "classical", "hybrid":
	default:
		errs = append(errs, fmt.Errorf("%s: reality key_share %q is not \"classical\" or \"hybrid\"", what, t.KeyShare))
	}
	if t.KeyShare != "" && !t.Reality {
		errs = append(errs, fmt.Errorf("%s: reality key_share needs REALITY", what))
	}
	// The ML-DSA-65 verify key is a REALITY parameter the same way:
	// without REALITY no renderer can honour it (CENSOR-P1). Its shape
	// is checked in ValidateReality, which owns the REALITY errors.
	if t.RealityMLDSA65Verify != "" && !t.Reality {
		errs = append(errs, fmt.Errorf("%s: reality mldsa65Verify needs REALITY", what))
	}
	ech := t.ECH
	if !ech.Enabled {
		return errs
	}
	if !t.Enabled {
		errs = append(errs, fmt.Errorf("%s: ECH is enabled but TLS is not", what))
	}
	if t.Reality {
		errs = append(errs, fmt.Errorf("%s: ECH and REALITY are incompatible", what))
	}
	return errs
}

// hasEncryptedServer reports whether the plan carries a DNS transport a
// passive censor cannot read. ECH without a pinned config fetches the
// ECHConfigList from the DNS HTTPS record; over plaintext or system DNS
// that bootstrap query leaks the target domain before TLS even starts.
func (d DNS) hasEncryptedServer() bool {
	if !d.Enabled {
		return false
	}
	for _, s := range d.Servers {
		switch s.Transport {
		case DNSHTTPS, DNSH3, DNSTLS, DNSQUIC:
			return true
		}
	}
	return false
}

// AmneziaWG parameter bounds, matching the upstream kernel module and
// amneziawg-go: Jc is 1-128 (0 disables junk), junk sizes stay below the
// 1280-byte minimal IPv6 MTU so packets do not fragment, S1/S2 keep
// 148+S1 != 92+S2 so init and response sizes cannot collide, and the four
// magic headers must be distinct so packet types stay distinguishable.
const (
	awgMaxJunkCount = 128
	awgMaxJunkSize  = 1280
	awgMaxS1        = 1132
	awgMaxS2        = 1188
	awgMaxS3        = 1216
	awgMaxS4        = 32
	awgMinMagic     = 5
	awgMaxMagic     = 2147483647
)

// validateAmneziaWG rejects obfuscation parameters an engine would silently
// misapply or drop: every engine derives from the same upstream device, so
// the checks stay engine-independent. I1-I5 get structural CPS validation
// here; the engine stays the authority on unknown tags.
func validateAmneziaWG(id string, a *AmneziaWG) []error {
	var errs []error
	bad := func(format string, args ...any) {
		args = append([]any{id}, args...)
		errs = append(errs, fmt.Errorf("outbound %s: amneziawg "+format, args...))
	}
	if a.Jc < 0 || a.Jc > awgMaxJunkCount {
		bad("jc %d is outside 0-%d", a.Jc, awgMaxJunkCount)
	}
	if a.Jmin < 0 || a.Jmin > awgMaxJunkSize {
		bad("jmin %d is outside 0-%d", a.Jmin, awgMaxJunkSize)
	}
	if a.Jmax < 0 || a.Jmax > awgMaxJunkSize {
		bad("jmax %d is outside 0-%d", a.Jmax, awgMaxJunkSize)
	}
	if a.Jmin > a.Jmax {
		bad("jmin %d exceeds jmax %d", a.Jmin, a.Jmax)
	}
	pads := []struct {
		name string
		v    int
		max  int
	}{
		{"s1", a.S1, awgMaxS1}, {"s2", a.S2, awgMaxS2},
		{"s3", a.S3, awgMaxS3}, {"s4", a.S4, awgMaxS4},
	}
	for _, p := range pads {
		if p.v < 0 || p.v > p.max {
			bad("%s %d is outside 0-%d", p.name, p.v, p.max)
		}
	}
	if a.S1+56 == a.S2 && (a.S1 != 0 || a.S2 != 0) {
		bad("s1+56 must not equal s2, or padded init and response packets collide at %d bytes", a.S2+92)
	}
	type interval struct{ lo, hi int64 }
	headers := [4]interval{}
	names := []string{"h1", "h2", "h3", "h4"}
	values := []string{a.H1, a.H2, a.H3, a.H4}
	// disabled marks headers set to their per-index compatibility value
	// (H1=1, H2=2, H3=3, H4=4): the 3.1 spec defines these as "mechanism
	// off", recommended together with Header Protection. Disabled headers
	// keep the standard WireGuard types, which never overlap.
	disabled := [4]bool{}
	for i, raw := range values {
		if raw == "" {
			continue
		}
		lo, hi, err := parseAmneziaMagic(raw)
		if err != nil {
			bad("%s %q is not a header or header range: %v", names[i], raw, err)
			continue
		}
		if lo == hi && lo == int64(i+1) {
			disabled[i] = true
			continue
		}
		if lo < awgMinMagic || hi > awgMaxMagic {
			bad("%s %q is outside %d-%d", names[i], raw, awgMinMagic, awgMaxMagic)
			continue
		}
		headers[i] = interval{lo, hi}
	}
	for i := 0; i < 4; i++ {
		if values[i] == "" || disabled[i] {
			continue
		}
		for j := i + 1; j < 4; j++ {
			if values[j] == "" || disabled[j] {
				continue
			}
			if headers[i].lo <= headers[j].hi && headers[j].lo <= headers[i].hi {
				bad("%s %q and %s %q overlap: packet types must stay distinguishable",
					names[i], values[i], names[j], values[j])
			}
		}
	}
	// The 3.1 docs also RECOMMEND S1==S2==S3==S4 when RandomTrailers is
	// on (unequal sizes can misclassify the packet type). That stays a
	// recommendation, not an error: the engines accept unequal sizes,
	// and sora's own generator (wgobfusc) deliberately picks distinct
	// sizes that keep S1+56 != S2, which the hard check above enforces.
	//
	// AmneziaWG 3.1: Header Protection needs a genuine 32-byte key, and
	// S1..S4 must be at least 12 bytes each (the ChaCha20 nonce is the
	// first 12 bytes of every Sx prefix). Anything else is a config the
	// engine cannot honor.
	if key := strings.TrimSpace(a.HeaderProtectionKey); key != "" {
		raw, err := decodeAWGKey(key)
		if err != nil || len(raw) != 32 {
			bad("headerprotectionkey is not a 32-byte key (base64 or hex)")
		}
		for _, p := range pads {
			if p.v < 12 {
				bad("headerprotectionkey requires %s >= 12, got %d", p.name, p.v)
			}
		}
	}
	for _, r := range a.awg31Ranges() {
		if r[1] == "" {
			continue
		}
		if _, _, err := parseAWGRangeU16(r[1]); err != nil {
			bad("%s %q is not a range<uint16> (\"a-b\" or \"a\"): %v", r[0], r[1], err)
		}
	}
	// I1..I5 are CPS tag scripts: a malformed script is rejected by the
	// engine at load, so catch it here with the plan context attached.
	for i, raw := range []string{a.I1, a.I2, a.I3, a.I4, a.I5} {
		if raw == "" {
			continue
		}
		if err := validateAWGCPS(raw); err != nil {
			bad("i%d %q is not a valid CPS script: %v", i+1, raw, err)
		}
	}
	errs = append(errs, validateAWGMasquerade(id, a)...)
	// T012: published example parameters are censor-signatured verbatim.
	// docs.amnezia.org itself warns its CPS example "is not an example of
	// a signature. Do not use it as the value". Every client/server pair
	// must run unique generated parameters (see wgobfusc.Generate).
	if name := matchAWGPublicExample(a); name != "" {
		bad("parameters match the published example %q: generate a unique set per server", name)
	}
	return errs
}

// matchAWGPublicExample names the publicly documented AmneziaWG parameter
// set a matches, or "". This is a tripwire, not a wall: it blocks the
// canonical published examples a censor can signature verbatim. It cannot
// enumerate every blog-post config; uniqueness comes from generation.
func matchAWGPublicExample(a *AmneziaWG) string {
	// docs.amnezia.org/documentation/amnezia-wg, CPS section: the syntax
	// demo, explicitly marked "do not use as the value".
	if a.I1 == "<b 0xd100000001><rc 8><t><r 50>" {
		return "docs.amnezia.org CPS syntax demo"
	}
	// The canonical QUIC preset quoted across AmneziaWG 2.0 publications.
	if a.I1 == "<b 0xc700000001><rc 8><t><r 50>" {
		return "AmneziaWG 2.0 canonical QUIC preset"
	}
	// amneziawg-windows configuration docs, worked example.
	if a.Jc == 5 && a.Jmin == 40 && a.Jmax == 70 && a.S1 == 30 && a.S2 == 50 &&
		a.H1 == "2155318676" && a.H2 == "1459039349" &&
		a.H3 == "988890009" && a.H4 == "1862976214" {
		return "amneziawg-windows documentation example"
	}
	return ""
}

// parseAWGRangeU16 parses an AmneziaWG 3.1 range<uint16>: "a-b" or a single
// value "a", with 0 <= a <= b <= 65535.
func parseAWGRangeU16(raw string) (lo, hi uint64, err error) {
	parse := func(s string) (uint64, error) {
		return strconv.ParseUint(strings.TrimSpace(s), 10, 16)
	}
	parts := strings.SplitN(strings.TrimSpace(raw), "-", 2)
	if len(parts) == 1 {
		n, err := parse(parts[0])
		if err != nil {
			return 0, 0, err
		}
		return n, n, nil
	}
	lo, err = parse(parts[0])
	if err != nil {
		return 0, 0, err
	}
	hi, err = parse(parts[1])
	if err != nil {
		return 0, 0, err
	}
	if lo > hi {
		return 0, 0, fmt.Errorf("range %q has its lower bound above the upper bound", raw)
	}
	return lo, hi, nil
}

// decodeAWGKey decodes a 32-byte AmneziaWG key from base64 (standard or
// URL-safe, padded or raw) or hex, the encodings real configs use.
func decodeAWGKey(raw string) ([]byte, error) {
	s := strings.TrimSpace(raw)
	for _, enc := range []*base64.Encoding{
		base64.StdEncoding, base64.RawStdEncoding,
		base64.URLEncoding, base64.RawURLEncoding,
	} {
		if b, err := enc.DecodeString(s); err == nil {
			return b, nil
		}
	}
	if b, err := hex.DecodeString(s); err == nil {
		return b, nil
	}
	return nil, fmt.Errorf("not base64 or hex")
}

// validateAWGMasquerade checks the sing-box-lx id/ip/ib decoy sugar against
// the fork's own rules: the protocol set, the browser set, the domain the
// decoy embeds, and the mutual exclusion with a hand-written I1.
func validateAWGMasquerade(id string, a *AmneziaWG) []error {
	var errs []error
	bad := func(format string, args ...any) {
		args = append([]any{id}, args...)
		errs = append(errs, fmt.Errorf("outbound %s: amneziawg "+format, args...))
	}
	proto, domain, browser := a.MasqueradeProtocol, a.MasqueradeDomain, a.MasqueradeBrowser
	if proto == "" && domain == "" && browser == "" {
		return nil
	}
	if a.I1 != "" && proto != "" {
		bad("id/ip/ib masquerade conflicts with an explicit i1; use one or the other")
	}
	switch proto {
	case "quic", "dns", "stun", "sip":
	case "":
		bad("ip (masquerade protocol) is required when id/ib is set; one of quic|dns|stun|sip")
	default:
		bad("unknown masquerade protocol %q; one of quic|dns|stun|sip", proto)
	}
	switch browser {
	case "", "chrome", "firefox", "curl":
	case "chrome-full":
		// Experimental in the fork and not for client UIs: refuse
		// rather than silently fall back to the generic ClientHello.
		bad("masquerade browser %q is experimental and not for client use; one of chrome|firefox|curl", browser)
	default:
		bad("unknown masquerade browser %q; one of chrome|firefox|curl", browser)
	}
	if browser != "" && proto != "" && proto != "quic" {
		bad("ib (browser) is only meaningful with ip=quic, got ip=%q", proto)
	}
	if proto == "quic" && domain == "" {
		bad("id (masquerade domain) is required for ip=quic (it becomes the ClientHello SNI)")
	}
	if domain != "" {
		if err := validateAWGDomain(domain); err != nil {
			bad("invalid masquerade domain %q: %v", domain, err)
		}
	}
	return errs
}

// validateAWGDomain applies the fork's strict LDH check: the domain lands
// in SIP text and DNS QNAMEs, so this is an injection boundary.
func validateAWGDomain(domain string) error {
	if len(domain) > 253 {
		return fmt.Errorf("longer than 253 bytes")
	}
	name := strings.TrimSuffix(domain, ".")
	if name == "" || strings.HasPrefix(domain, ".") {
		return fmt.Errorf("empty or leading dot")
	}
	for _, label := range strings.Split(name, ".") {
		if len(label) == 0 || len(label) > 63 {
			return fmt.Errorf("label %q is empty or longer than 63 bytes", label)
		}
		if label[0] == '-' || label[len(label)-1] == '-' {
			return fmt.Errorf("label %q has a leading or trailing hyphen", label)
		}
		for i := 0; i < len(label); i++ {
			c := label[i]
			if c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-' || c == '_' {
				continue
			}
			return fmt.Errorf("illegal character %q (only a-z A-Z 0-9 - _ allowed)", string(c))
		}
	}
	return nil
}

// validateAWGCPS checks the structural shape of a CPS decoy script: a
// whitespace-separated sequence of <tag> elements using the tag set the
// engines implement (b/c/t/r/rc/rd). Unknown tags are left to the engine:
// being stricter here than the engine would reject configs the engine
// accepts.
func validateAWGCPS(raw string) error {
	rest := strings.TrimSpace(raw)
	for rest != "" {
		if !strings.HasPrefix(rest, "<") {
			return fmt.Errorf("text outside <...> tags")
		}
		end := strings.IndexByte(rest, '>')
		if end < 0 {
			return fmt.Errorf("unclosed <...> tag")
		}
		tag := strings.TrimSpace(rest[1:end])
		rest = strings.TrimSpace(rest[end+1:])
		fields := strings.Fields(tag)
		if len(fields) == 0 {
			return fmt.Errorf("empty <...> tag")
		}
		switch fields[0] {
		case "b":
			// <b 0xHEX>: static bytes, always even-sized hex.
			if len(fields) != 2 || !strings.HasPrefix(fields[1], "0x") {
				return fmt.Errorf("<b ...> needs one 0x-prefixed hex argument")
			}
			hex := fields[1][2:]
			if len(hex) == 0 || len(hex)%2 != 0 {
				return fmt.Errorf("<b ...> hex must be non-empty and even-sized")
			}
			for i := 0; i < len(hex); i++ {
				c := hex[i]
				if c >= '0' && c <= '9' || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F' {
					continue
				}
				return fmt.Errorf("<b ...> hex has a non-hex character")
			}
		case "c", "t":
			// <c> counter, <t> timestamp: no arguments.
			if len(fields) != 1 {
				return fmt.Errorf("<%s> takes no arguments", fields[0])
			}
		case "r", "rc", "rd":
			// <r N> / <rc N> / <rd N>: N random bytes/chars/digits.
			if len(fields) != 2 {
				return fmt.Errorf("<%s ...> needs one size argument", fields[0])
			}
			n, err := strconv.Atoi(fields[1])
			if err != nil || n < 0 || n > 1000 {
				return fmt.Errorf("<%s ...> size must be 0-1000", fields[0])
			}
		default:
			// Unknown tag: the engine is the authority.
		}
	}
	return nil
}

// parseAmneziaMagic parses a 2.0 magic header: a single number or an "x-y"
// range with x <= y.
func parseAmneziaMagic(raw string) (lo, hi int64, err error) {
	parts := strings.SplitN(raw, "-", 2)
	if len(parts) == 1 {
		n, err := strconv.ParseInt(strings.TrimSpace(parts[0]), 10, 64)
		if err != nil {
			return 0, 0, err
		}
		return n, n, nil
	}
	lo, err = strconv.ParseInt(strings.TrimSpace(parts[0]), 10, 64)
	if err != nil {
		return 0, 0, err
	}
	hi, err = strconv.ParseInt(strings.TrimSpace(parts[1]), 10, 64)
	if err != nil {
		return 0, 0, err
	}
	if lo > hi {
		return 0, 0, fmt.Errorf("range %q has its lower bound above the upper bound", raw)
	}
	return lo, hi, nil
}

// Validate checks the plan as a whole: limits, identifiers, references between
// rules and groups, and the engine-independent rules of every outbound.
func (p *Plan) Validate() error {
	if p == nil {
		return errors.New("plan: nil plan")
	}
	var errs []error
	if strings.TrimSpace(p.SessionID) == "" {
		errs = append(errs, errors.New("plan: empty session id"))
	}
	if len(p.Outbounds) == 0 {
		errs = append(errs, errors.New("plan: no outbounds"))
	}
	if len(p.Outbounds) > MaxOutbounds {
		errs = append(errs, fmt.Errorf("plan: %d outbounds exceeds the limit of %d", len(p.Outbounds), MaxOutbounds))
	}
	if len(p.Groups) > MaxGroups {
		errs = append(errs, fmt.Errorf("plan: %d groups exceeds the limit of %d", len(p.Groups), MaxGroups))
	}
	if len(p.Rules) > MaxRules {
		errs = append(errs, fmt.Errorf("plan: %d rules exceeds the limit of %d", len(p.Rules), MaxRules))
	}

	ids := make(map[string]struct{}, len(p.Outbounds))
	for _, o := range p.Outbounds {
		errs = append(errs, o.Validate())
		if _, dup := ids[o.ID]; dup {
			errs = append(errs, fmt.Errorf("plan: duplicate outbound id %q", o.ID))
		}
		ids[o.ID] = struct{}{}
	}
	// Profiles run alone because combining provider routing with other
	// profiles or groups changes its semantics.
	if slices.ContainsFunc(p.Outbounds, func(o Outbound) bool { return o.Protocol == ProtocolXrayProfile }) &&
		(len(p.Outbounds) > 1 || len(p.Groups) > 0) {
		errs = append(errs, errors.New("plan: an Xray profile runs alone, without other outbounds or groups"))
	}

	// Collect all group names before validating members to allow nested and
	// forward references.
	members := make(map[string][]string, len(p.Groups))
	for _, g := range p.Groups {
		members[g.Name] = g.Outbounds
		if _, clash := ids[g.Name]; clash {
			errs = append(errs, fmt.Errorf("plan: group %q has the id of an outbound", g.Name))
		}
	}
	if (p.LocalProxy.Username == "") != (p.LocalProxy.Password == "") {
		errs = append(errs, errors.New("plan: the local proxy login needs both a username and a password"))
	}
	// Defense in depth for LAN sharing (C7): a listener bound to every
	// interface must never run without a login, whoever built the plan.
	// The pair check above does not catch "no login at all".
	if p.Options.AllowLAN && p.LocalProxy.Enabled && p.LocalProxy.Username == "" && p.LocalProxy.Password == "" {
		errs = append(errs, errors.New("plan: sharing the local proxy on the local network needs a username and a password"))
	}
	if strings.ContainsAny(p.LocalProxy.Username, ":@ \r\n") {
		errs = append(errs, errors.New("plan: the local proxy username contains a separator"))
	}
	names := make(map[string]struct{}, len(p.Groups))
	for _, g := range p.Groups {
		errs = append(errs, g.validate())
		if g.needsProbe() && g.URL == "" && p.Options.TestURL == "" {
			errs = append(errs, fmt.Errorf("plan: group %q measures latency, but the plan has no test url", g.Name))
		}
		errs = append(errs, validateTestURL("group "+g.Name, g.URL))
		if _, dup := names[g.Name]; dup {
			errs = append(errs, fmt.Errorf("plan: duplicate group name %q", g.Name))
		}
		names[g.Name] = struct{}{}
		for _, ref := range g.Outbounds {
			_, isOutbound := ids[ref]
			_, isGroup := members[ref]
			if !isOutbound && !isGroup && !IsBuiltInTarget(ref) {
				errs = append(errs, fmt.Errorf("group %q: unknown outbound %q", g.Name, ref))
			}
		}
		if groupCycle(g.Name, members, map[string]bool{}) {
			errs = append(errs, fmt.Errorf("group %q: contains itself through its members", g.Name))
		}
	}

	for _, r := range p.Rules {
		errs = append(errs, r.validate())
		if r.Target == "" {
			errs = append(errs, fmt.Errorf("rule %s %q: empty target", r.Type, r.Value))
			continue
		}
		_, isOutbound := ids[r.Target]
		_, isGroup := names[r.Target]
		if !isOutbound && !isGroup && !IsBuiltInTarget(r.Target) {
			errs = append(errs, fmt.Errorf("rule %s %q: unknown target %q", r.Type, r.Value, r.Target))
		}
	}

	errs = append(errs, validateChains(p.Outbounds, ids))

	errs = append(errs, p.DNS.validate(), p.Tun.validate(), p.Options.validate())

	// ECH without a pinned config fetches the ECHConfigList from the DNS
	// HTTPS record (P13-3): over a plaintext or system DNS path that
	// bootstrap query leaks the target domain before TLS even starts,
	// which defeats the purpose of hiding the SNI. Fail closed with a
	// message that names the fix.
	for _, o := range p.Outbounds {
		if o.TLS.ECH.Enabled && len(o.TLS.ECH.Config) == 0 && !p.DNS.hasEncryptedServer() {
			errs = append(errs, fmt.Errorf("plan: outbound %s enables ECH without a pinned config, but the plan has no encrypted DNS transport; pin the ECH config or enable encrypted DNS", o.ID))
		}
	}
	return errors.Join(errs...)
}

// MaxChainHops bounds a proxy chain: the entry outbound plus its via links.
// Longer chains multiply failure modes without meaningful privacy gains.
const MaxChainHops = 3

// validateChains checks Via links between outbounds: every link names an
// existing outbound, no outbound links to itself, no cycles, and no chain is
// longer than MaxChainHops.
func validateChains(outbounds []Outbound, ids map[string]struct{}) error {
	via := make(map[string]string, len(outbounds))
	for _, o := range outbounds {
		if o.Via == "" {
			continue
		}
		if o.Protocol == ProtocolDirect || o.Protocol == ProtocolBypass {
			return fmt.Errorf("outbound %s: a %s outbound cannot dial through another", o.ID, o.Protocol)
		}
		if o.Via == o.ID {
			return fmt.Errorf("outbound %s: dials through itself", o.ID)
		}
		if _, ok := ids[o.Via]; !ok {
			return fmt.Errorf("outbound %s: dials through unknown outbound %q", o.ID, o.Via)
		}
		via[o.ID] = o.Via
	}
	for _, o := range outbounds {
		if o.Via == "" {
			continue
		}
		seen := map[string]bool{o.ID: true}
		depth := 1
		for next := o.Via; next != ""; {
			if seen[next] {
				return fmt.Errorf("outbound %s: its chain loops back through %q", o.ID, next)
			}
			seen[next] = true
			depth++
			if depth > MaxChainHops {
				return fmt.Errorf("outbound %s: its chain is longer than %d hops", o.ID, MaxChainHops)
			}
			next = via[next]
		}
	}
	return nil
}

// groupCycle reports whether group reaches itself through nested groups.
func groupCycle(group string, members map[string][]string, visiting map[string]bool) bool {
	if visiting[group] {
		return true
	}
	visiting[group] = true
	defer delete(visiting, group)
	for _, m := range members[group] {
		if _, isGroup := members[m]; isGroup && groupCycle(m, members, visiting) {
			return true
		}
	}
	return false
}

// bypassPosition is a zapret split position: bytes, bytes from the end, or a
// marker with an optional offset.
var bypassPosition = regexp.MustCompile(`^(-?[0-9]{1,4}|(method|host|endhost|sld|midsld|endsld|sniext)([+-][0-9]{1,4})?)$`)

// bypassTamperPosition is a zapret tamper start/cutoff: like bypassPosition
// with an optional leading "n" selecting a data block number instead of a
// byte offset.
var bypassTamperPosition = regexp.MustCompile(`^n?(-?[0-9]{1,4}|(method|host|endhost|sld|midsld|endsld|sniext)([+-][0-9]{1,4})?)$`)

// validOOBData mirrors tpws: one byte, or 0x plus two hex digits.
func validOOBData(v string) bool {
	if len(v) == 1 {
		return true
	}
	if len(v) == 4 && (v[0] == '0' && (v[1] == 'x' || v[1] == 'X')) {
		for _, c := range v[2:] {
			if !('0' <= c && c <= '9' || 'a' <= c && c <= 'f' || 'A' <= c && c <= 'F') {
				return false
			}
		}
		return true
	}
	return false
}

func (s *BypassStrategy) validate(id string) error {
	if s == nil {
		return fmt.Errorf("outbound %s: a bypass outbound needs a strategy", id)
	}
	if len(s.SplitPos) == 0 && s.TLSRecord == "" && s.MSS == "" && len(s.Desync) == 0 && !s.HostCase && !s.DomainCase && !s.MethodEOL &&
		!s.HostDot && !s.HostTab && !s.HostNoSpace && !s.MethodSpace && !s.UnixEOL {
		return fmt.Errorf("outbound %s: the bypass strategy changes nothing", id)
	}
	if len(s.SplitPos) > 8 {
		return fmt.Errorf("outbound %s: more than 8 split positions", id)
	}
	for _, pos := range append(slices.Clone(s.SplitPos), s.TLSRecord) {
		if pos == "midsni" {
			// The registry-level marker (bypass.MidSNIMarker): it names
			// "the middle of the actual SNI", which only the caller who
			// knows the target SNI can resolve. An unresolved marker
			// reaching an executor would be a guess, so it is refused
			// here with the remedy named.
			return fmt.Errorf("outbound %s: split position %q is an unresolved marker: resolve it with bypass.ResolveStrategy against the target SNI before applying the plan", id, pos)
		}
		if pos != "" && !bypassPosition.MatchString(pos) {
			return fmt.Errorf("outbound %s: %q is not a split position", id, pos)
		}
	}
	for _, pos := range []string{s.TamperStart, s.TamperCutoff} {
		if pos != "" && !bypassTamperPosition.MatchString(pos) {
			return fmt.Errorf("outbound %s: %q is not a tamper position", id, pos)
		}
	}
	if s.OOBData != "" && !validOOBData(s.OOBData) {
		return fmt.Errorf("outbound %s: %q is not an out-of-band byte (one character or 0xHEX)", id, s.OOBData)
	}
	if s.OOBData != "" && !s.OOB {
		return fmt.Errorf("outbound %s: an out-of-band byte needs out-of-band", id)
	}
	if s.MSS != "" {
		mss, err := strconv.Atoi(s.MSS)
		if err != nil || mss < 64 || mss > 65495 {
			return fmt.Errorf("outbound %s: %q is not a valid MSS (64-65495)", id, s.MSS)
		}
	}
	for _, scope := range []string{s.DisorderScope, s.OOBScope} {
		if scope != "" && scope != "http" && scope != "tls" {
			return fmt.Errorf("outbound %s: %q is not a protocol scope (http or tls)", id, scope)
		}
	}
	if s.DisorderScope != "" && !s.Disorder {
		return fmt.Errorf("outbound %s: a disorder scope needs disorder", id)
	}
	if s.OOBScope != "" && !s.OOB {
		return fmt.Errorf("outbound %s: an out-of-band scope needs out-of-band", id)
	}
	if (s.Disorder || s.OOB) && len(s.SplitPos) == 0 {
		return fmt.Errorf("outbound %s: disorder and out-of-band bytes need a split position", id)
	}
	if err := validateDesync(id, s); err != nil {
		return err
	}
	return nil
}

// validDesyncModes mirrors desync_mode_from_string of the vendored zapret:
// every --dpi-desync mode the nfqws binary understands.
var validDesyncModes = map[string]bool{
	"fake": true, "fakeknown": true, "rst": true, "rstack": true,
	"synack": true, "syndata": true, "fakeddisorder": true, "disorder": true,
	"fakedsplit": true, "split": true, "multisplit": true, "split2": true,
	"multidisorder": true, "disorder2": true, "hostfakesplit": true,
	"ipfrag2": true, "hopbyhop": true, "destopt": true, "ipfrag1": true,
	"udplen": true, "tamper": true,
}

// validFooling mirrors parse_fooling of the vendored zapret.
var validFooling = map[string]bool{
	"md5sig": true, "ts": true, "badsum": true, "badseq": true,
	"datanoack": true, "hopbyhop": true, "hopbyhop2": true, "none": true,
}

// validFilterL7 mirrors the --filter-l7 values of the vendored zapret.
var validFilterL7 = map[string]bool{
	"http": true, "tls": true, "quic": true, "wireguard": true,
	"dht": true, "discord": true, "stun": true, "unknown": true,
}

// validFakeName keeps fake payload selectors inside the zapret home:
// the "tls"/"quic" built-in keywords or a plain file name, never a path.
var validFakeName = regexp.MustCompile(`^([A-Za-z0-9_.-]+|tls|quic)$`)

// validFilterPorts is a comma-separated list of ports or port ranges.
var validFilterPorts = regexp.MustCompile(`^([0-9]{1,5}(-[0-9]{1,5})?)(,([0-9]{1,5}(-[0-9]{1,5})?))*$`)

func validateDesync(id string, s *BypassStrategy) error {
	if len(s.Desync) > 8 {
		return fmt.Errorf("outbound %s: more than 8 desync methods", id)
	}
	hasFake := false
	for _, m := range s.Desync {
		if !validDesyncModes[m] {
			return fmt.Errorf("outbound %s: %q is not a dpi-desync method", id, m)
		}
		if m == "fake" {
			hasFake = true
		}
	}
	nfqws := len(s.Desync) > 0
	if nfqws {
		// The nfqws renderer (bypass.NFQWSArgs) carries only SplitPos
		// of the legacy tpws fields; every other legacy field set
		// alongside a desync method would be dropped silently when
		// BackendOf routes the strategy to nfqws (S2 seams audit).
		// Refuse the mix, mirroring the nfqws-only checks below:
		// disorder on nfqws is spelled as a desync method
		// (disorder/disorder2), and the HTTP-shaping, OOB, TLS-record,
		// tamper-window and MSS knobs have no NFQWSArgs rendering.
		for _, f := range []struct {
			name string
			set  bool
		}{
			{"disorder", s.Disorder || s.DisorderScope != ""},
			{"oob", s.OOB || s.OOBScope != "" || s.OOBData != ""},
			{"tlsrec", s.TLSRecord != ""},
			{"hostcase", s.HostCase},
			{"domcase", s.DomainCase},
			{"methodeol", s.MethodEOL},
			{"hostdot", s.HostDot},
			{"hosttab", s.HostTab},
			{"hostnospace", s.HostNoSpace},
			{"methodspace", s.MethodSpace},
			{"unixeol", s.UnixEOL},
			{"split-any-protocol", s.SplitAnyProtocol},
			{"tamper-start", s.TamperStart != ""},
			{"tamper-cutoff", s.TamperCutoff != ""},
			{"mss", s.MSS != ""},
		} {
			if f.set {
				return fmt.Errorf("outbound %s: %s is a tpws-only option: a strategy with desync methods runs on nfqws, which does not render it", id, f.name)
			}
		}
	}
	if s.Fooling != "" {
		if !nfqws {
			return fmt.Errorf("outbound %s: fooling needs a desync method (nfqws-only)", id)
		}
		for _, f := range strings.Split(s.Fooling, ",") {
			if !validFooling[f] {
				return fmt.Errorf("outbound %s: %q is not a fooling mode", id, f)
			}
		}
	}
	if s.FakeTLS != "" || s.FakeQUIC != "" {
		if !hasFake {
			return fmt.Errorf("outbound %s: fake payloads need the fake desync method", id)
		}
		for _, fake := range []string{s.FakeTLS, s.FakeQUIC} {
			if fake != "" && !validFakeName.MatchString(fake) {
				return fmt.Errorf("outbound %s: %q is not a fake payload (built-in keyword or file name)", id, fake)
			}
		}
	}
	if s.FakeQUIC != "" && s.FilterUDP == "" {
		return fmt.Errorf("outbound %s: a QUIC fake needs filter-udp (QUIC runs over UDP)", id)
	}
	switch {
	case s.TTL < 0 || s.TTL > 255:
		return fmt.Errorf("outbound %s: fake TTL %d is out of range (1-255)", id, s.TTL)
	case s.TTL > 0 && !hasFake:
		return fmt.Errorf("outbound %s: a fake TTL needs the fake desync method", id)
	case s.TTL > 0 && s.AutoTTL:
		return fmt.Errorf("outbound %s: a fake TTL and autottl are mutually exclusive", id)
	case s.AutoTTL && !hasFake:
		return fmt.Errorf("outbound %s: autottl needs the fake desync method", id)
	}
	if s.AutoTTLDelta != 0 {
		if !s.AutoTTL {
			return fmt.Errorf("outbound %s: an autottl delta needs autottl", id)
		}
		if s.AutoTTLDelta < 1 || s.AutoTTLDelta > 16 {
			return fmt.Errorf("outbound %s: autottl delta %d is out of range (1-16)", id, s.AutoTTLDelta)
		}
	}
	if s.Repeats != 0 {
		if !hasFake {
			return fmt.Errorf("outbound %s: repeats need the fake desync method", id)
		}
		if s.Repeats < 1 || s.Repeats > 16 {
			return fmt.Errorf("outbound %s: repeats %d is out of range (1-16)", id, s.Repeats)
		}
	}
	for _, filter := range []struct {
		name, value string
	}{{"filter-tcp", s.FilterTCP}, {"filter-udp", s.FilterUDP}} {
		if filter.value == "" {
			continue
		}
		if !nfqws {
			return fmt.Errorf("outbound %s: %s needs a desync method (nfqws-only)", id, filter.name)
		}
		if !validFilterPorts.MatchString(filter.value) {
			return fmt.Errorf("outbound %s: %q is not a port list", id, filter.value)
		}
		for _, part := range strings.Split(filter.value, ",") {
			for _, p := range strings.Split(part, "-") {
				n, _ := strconv.Atoi(p)
				if n < 1 || n > 65535 {
					return fmt.Errorf("outbound %s: port %d is out of range (1-65535)", id, n)
				}
			}
		}
	}
	if s.FilterL7 != "" {
		if !nfqws {
			return fmt.Errorf("outbound %s: filter-l7 needs a desync method (nfqws-only)", id)
		}
		for _, l7 := range strings.Split(s.FilterL7, ",") {
			if !validFilterL7[l7] {
				return fmt.Errorf("outbound %s: %q is not a filter-l7 protocol", id, l7)
			}
		}
	}
	return nil
}

// validateHysteria2Tuning checks the bandwidth caps and port-hopping spec of
// a Hysteria2 outbound. Engines pick BBR or Brutal congestion control and
// the hopping behavior from these fields, so malformed values must fail here
// instead of producing a config the engine silently misapplies.
func validateHysteria2Tuning(o Outbound) []error {
	var errs []error
	if o.UpMbps < 0 || o.DownMbps < 0 {
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 bandwidth caps must not be negative", o.ID))
	}
	if o.UpMbps > MaxHy2BandwidthMbps || o.DownMbps > MaxHy2BandwidthMbps {
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 bandwidth caps must not exceed %d Mbps", o.ID, MaxHy2BandwidthMbps))
	}
	// Obfs is a plan-level promise of wire obfuscation: the type must
	// be one the engines implement and its password (credential data,
	// carried in ObfsParam and masked via Secrets) must be present —
	// both hopping engines reject an obfs block without a password
	// at config load (verified on the pins, CENSOR-P3), so accepting
	// it here would defer a plan error to a dead engine start.
	if o.Obfs != "" && !ValidHy2Obfs[o.Obfs] {
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 obfs %q is not salamander or gecko", o.ID, o.Obfs))
	}
	if o.Obfs != "" && o.ObfsParam == "" {
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 obfs %q needs its password", o.ID, o.Obfs))
	}
	if o.Obfs == "" && o.ObfsParam != "" {
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 obfs password without an obfs type does nothing", o.ID))
	}
	if err := validateHopPorts(o.ID, o.HopPorts); err != nil {
		errs = append(errs, err)
	}
	switch {
	case o.HopInterval < 0:
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 hop interval must not be negative", o.ID))
	case o.HopInterval > 0 && o.HopInterval < MinHy2HopIntervalSeconds:
		// Hysteria2 requires at least 5s between hops.
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 hop interval must be at least %ds", o.ID, MinHy2HopIntervalSeconds))
	case o.HopInterval > 0 && o.HopPorts == "":
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 hop interval needs hop ports", o.ID))
	}
	switch {
	case o.HopIntervalMax < 0:
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 hop interval max must not be negative", o.ID))
	case o.HopIntervalMax > 0 && o.HopPorts == "":
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 hop interval max needs hop ports", o.ID))
	case o.HopIntervalMax > 0 && o.HopInterval > 0 && o.HopIntervalMax < o.HopInterval:
		// sing-box renders hop_interval..hop_interval_max as the
		// randomized hop range; an inverted range is a config bug.
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 hop interval max %ds is below the hop interval %ds", o.ID, o.HopIntervalMax, o.HopInterval))
	}
	if o.BBRProfile != "" && !validBBRProfiles[o.BBRProfile] {
		errs = append(errs, fmt.Errorf("outbound %s: hysteria2 bbr profile %q is not standard, conservative or aggressive", o.ID, o.BBRProfile))
	}
	return errs
}

// validBBRProfiles lists the BBR congestion profiles sing-box 1.14
// accepts for Hysteria2 outbounds (bbr_profile).
var validBBRProfiles = map[string]bool{"standard": true, "conservative": true, "aggressive": true}

// validateHopPorts checks a Hysteria2 port-hopping spec such as
// "20000-30000,40000": comma-separated single ports or ascending ranges.
// The parse itself lives in HopPortRanges (quic_defaults.go), the same
// parser the renderers translate from, so validation and rendering
// can never disagree about what a spec means.
func validateHopPorts(id, spec string) error {
	if _, err := HopPortRanges(spec); err != nil {
		return fmt.Errorf("outbound %s: %w", id, err)
	}
	return nil
}

// validateTUICTuning checks the congestion controller, UDP relay mode
// and heartbeat of a TUIC outbound against what the engines implement,
// so an unknown value fails validation instead of silently falling
// back to an engine default. The vocabularies live in
// quic_defaults.go (ValidTUICCongestion / ValidTUICUDPRelayMode);
// mihomo accepts unknown values silently at config load, so this
// gate is the only thing standing between a typo and a silent
// default there (verified on the pins, CENSOR-P3).
func validateTUICTuning(o Outbound) []error {
	var errs []error
	if o.CongestionControl != "" && !ValidTUICCongestion[o.CongestionControl] {
		errs = append(errs, fmt.Errorf("outbound %s: unknown tuic congestion control %q", o.ID, o.CongestionControl))
	}
	if o.UDPRelayMode != "" && !ValidTUICUDPRelayMode[o.UDPRelayMode] {
		errs = append(errs, fmt.Errorf("outbound %s: unknown tuic udp relay mode %q", o.ID, o.UDPRelayMode))
	}
	if o.TUICHeartbeat < 0 || (o.TUICHeartbeat > 0 && o.TUICHeartbeat < MinTUICHeartbeatSeconds) || o.TUICHeartbeat > MaxTUICHeartbeatSeconds {
		errs = append(errs, fmt.Errorf("outbound %s: tuic heartbeat %ds is outside %d-%ds (0 keeps the default)", o.ID, o.TUICHeartbeat, MinTUICHeartbeatSeconds, MaxTUICHeartbeatSeconds))
	}
	return errs
}
