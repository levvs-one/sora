// Package parser converts links, base64 lists, sing-box/Xray JSON, Clash YAML,
// and WireGuard configs to OutboundSpec. Detection is separate from parsing;
// unsupported or malformed items are reported without failing the entire
// import.
package parser

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"unicode/utf8"

	"gopkg.in/yaml.v3"
)

const (
	// MaxInputSize is the largest payload the parser is willing to inspect.
	MaxInputSize = 16 << 20
	// DefaultMaxItems caps how many outbounds a single import may produce.
	DefaultMaxItems = 20000
)

// Parser sentinel errors support errors.Is and contain no user data, making
// them safe to log.
var (
	ErrEmptySource   = errors.New("parser: empty source")
	ErrInputTooLarge = errors.New("parser: input exceeds 16 MiB")
	ErrUnsupported   = errors.New("parser: unsupported format")
	ErrInvalid       = errors.New("parser: invalid entry")
)

// Format names a subscription payload shape recognised by ImportDetector.
type Format string

// Detected formats do not guarantee that every contained item is parseable.
const (
	FormatUnknown          Format = "unknown"
	FormatSubscription     Format = "https-subscription"
	FormatHTTPSubscription Format = "http-subscription"
	FormatLink             Format = "share-link"
	FormatBase64           Format = "base64-list"
	FormatSIP008           Format = "sip008"
	FormatClash            Format = "clash-yaml"
	FormatSingBox          Format = "sing-box-json"
	FormatXray             Format = "xray-json"
	FormatWireGuard        Format = "wireguard-conf"
	FormatPlainList        Format = "plain-list"
)

// Detection records the detected Format and a short diagnostic Reason.
type Detection struct {
	Format Format
	Reason string
}

// ImportDetector identifies formats without parsing. MaxItems bounds list
// expansion; zero uses DefaultMaxItems. Concurrent use is safe.
type ImportDetector struct{ MaxItems int }

// Detect identifies src's format. Empty or oversized input returns an empty
// Detection; other errors include the best format guess.
func (d ImportDetector) Detect(src []byte) (Detection, error) {
	det, _, err := d.detect(src)
	return det, err
}

// detect is Detect plus the decoded payload for FormatBase64 input, so Parse
// does not have to decode the payload a second time. The decoded bytes are
// nil for every other format.
func (d ImportDetector) detect(src []byte) (Detection, []byte, error) {
	if len(src) == 0 || strings.TrimSpace(string(src)) == "" {
		return Detection{}, nil, ErrEmptySource
	}
	if len(src) > MaxInputSize {
		return Detection{}, nil, ErrInputTooLarge
	}
	s := strings.TrimSpace(string(src))
	low := strings.ToLower(s)
	if strings.HasPrefix(low, "https://") {
		return Detection{Format: FormatSubscription}, nil, nil
	}
	if strings.HasPrefix(low, "http://") {
		return Detection{Format: FormatHTTPSubscription, Reason: "subscriptions require HTTPS"}, nil, nil
	}
	if hasScheme(s) {
		return Detection{Format: FormatLink}, nil, nil
	}
	if strings.HasPrefix(s, "{") || strings.HasPrefix(s, "[") {
		var v any
		if json.Unmarshal([]byte(s), &v) == nil {
			return classifyJSON(v), nil, nil
		}
	}
	if strings.Contains(s, "proxies:") {
		return Detection{Format: FormatClash}, nil, nil
	}
	if looksWG(s) {
		return Detection{Format: FormatWireGuard}, nil, nil
	}
	if b, ok := decodeBase64(s); ok && (hasScheme(string(b)) || looksList(string(b))) {
		return Detection{Format: FormatBase64}, b, nil
	}
	if looksList(s) {
		return Detection{Format: FormatPlainList}, nil, nil
	}
	return Detection{Format: FormatUnknown, Reason: "no supported parser matched"}, nil, ErrUnsupported
}
func hasScheme(s string) bool {
	for _, l := range strings.Fields(s) {
		p := strings.ToLower(strings.TrimSpace(l))
		for _, x := range []string{"vless://", "vmess://", "trojan://", "ss://", "socks://", "socks5://", "http://", "https://", "hysteria2://", "hy2://", "tuic://", "wireguard://", "wg://", "olcrtc://"} {
			if strings.HasPrefix(p, x) {
				return true
			}
		}
	}
	return false
}
func looksList(s string) bool {
	n := 0
	for _, l := range strings.Split(s, "\n") {
		if hasScheme(strings.TrimSpace(l)) {
			n++
		}
	}
	return n > 0
}
func looksWG(s string) bool {
	return strings.Contains(s, "[Interface]") && strings.Contains(s, "[Peer]")
}
func classifyJSON(v any) Detection {
	m, ok := v.(map[string]any)
	if !ok {
		if a, ok := v.([]any); ok && len(a) > 0 {
			if _, ok := a[0].(map[string]any); ok {
				return Detection{Format: FormatXray}
			}
		}
		return Detection{}
	}
	if _, ok := m["outbounds"]; ok {
		return Detection{Format: FormatSingBox}
	}
	if _, ok := m["servers"]; ok {
		return Detection{Format: FormatSIP008}
	}
	if _, ok := m["inbounds"]; ok {
		return Detection{Format: FormatXray}
	}
	return Detection{}
}
func decodeBase64(s string) ([]byte, bool) {
	clean := strings.Map(func(r rune) rune {
		if r == '\r' || r == '\n' || r == ' ' || r == '\t' {
			return -1
		}
		return r
	}, s)
	for _, e := range []*base64.Encoding{base64.StdEncoding, base64.RawStdEncoding, base64.URLEncoding, base64.RawURLEncoding} {
		x := clean
		if n := len(x) % 4; n != 0 {
			x += strings.Repeat("=", 4-n)
		}
		if b, err := e.DecodeString(x); err == nil && utf8.Valid(b) {
			return b, true
		}
	}
	return nil, false
}

// OutboundSpec describes a parsed server independently of engines. Options
// retains additional fields to avoid silently losing unsupported settings
// during import.
type OutboundSpec struct {
	DisplayProtocol                                                                                 string
	ID, DisplayName, Protocol, Transport, Security                                                  string
	Host                                                                                            string
	Port                                                                                            uint16
	UUID, Password, User, Cipher                                                                    string
	PublicKey, ShortID, SpiderX, ServerName, Fingerprint, Flow, Path, HostHeader, ServiceName, Mode string
	// MLDSA65Verify carries the REALITY post-quantum verification key
	// of a vless link's pqv parameter. It travels through the
	// credential document into engine.TLS.RealityMLDSA65Verify, where
	// plan validation checks its shape and the capability gate routes
	// it to Xray, the only engine that spells it.
	MLDSA65Verify string
	ALPN          []string
	CountryCode   string
	AllowInsecure bool
	// DownloadAddress/DownloadPort carry the XHTTP up/down split from the
	// link's extra= JSON (see applyExtra). They travel
	// through the credential document into engine.Transport, where plan
	// validation and the Xray renderer honour them.
	DownloadAddress string
	DownloadPort    uint16
	// Xmux*/XPaddingBytes carry the XHTTP reuse tuning and padding
	// range from the same extra= JSON (the xmux object and the
	// xPaddingBytes string), travelling the same path into
	// engine.Transport. Range values in the link ("16-32") import as
	// their lower bound: the plan models xmux fields as single ints,
	// so the reduction is deliberate and documented here, never a
	// silent parse accident (CENSOR-P1).
	XmuxMaxConcurrency  int
	XmuxMaxConnections  int
	XmuxMaxReuseTimes   int
	XmuxMaxRequestTimes int
	XPaddingBytes       string
	Options             map[string]string
	Peers               []WireGuardPeer
}

// WireGuardPeer is one WireGuard peer as described by a wg-conf file or a
// wireguard:// link. PersistentKeepalive is measured in seconds.
type WireGuardPeer struct {
	PublicKey, PreSharedKey, Endpoint string
	AllowedIPs, Reserved              []string
	PersistentKeepalive               int
}

// StableKey hashes protocol, endpoint, ID, and user to identify a server across
// imports without exposing IDs.
func (o OutboundSpec) StableKey() string {
	// Identity covers protocol, host, port, UUID, and user. The UUID is a
	// credential for vless/vmess/tuic, but it is intentionally included: on
	// shared endpoints it distinguishes accounts, and re-imports must map
	// to the same entry instead of duplicating it. Passwords are excluded
	// so rotating a password does not orphan the saved entry (and to avoid
	// storing password hashes).
	material := o.Protocol + "\x00" + o.Host + "\x00" + strconv.Itoa(int(o.Port)) + "\x00" + o.UUID + "\x00" + o.User
	// Names distinguish profiles sharing an endpoint. Exclude mutable
	// provider rules so updates preserve saved selections.
	if o.Protocol == "xray-profile" {
		material += "\x00" + o.DisplayName
	}
	// An olcrtc server's identity is provider + transport + room:
	// Host already carries the room, but two providers (or two
	// transports of one provider) can serve the same room id and are
	// different servers. The key, like other passwords, stays out.
	if o.Protocol == "olcrtc" {
		material += "\x00" + o.Options["olcrtc_provider"] + "\x00" + o.Transport
	}
	h := sha256.Sum256([]byte(material))
	return o.Protocol + ":" + o.Host + ":" + strconv.Itoa(int(o.Port)) + ":" + hex.EncodeToString(h[:8])
}
func (o *OutboundSpec) validate() error {
	if o.Protocol == "" {
		return ErrInvalid
	}
	if o.Protocol == "olcrtc" {
		// olcrtc has no host:port endpoint (see olcrtc.go): Host
		// carries the RoomID and Port must stay 0. Validity is the
		// provider/transport registries plus the strict key shape;
		// the room is required for every provider except none, whose
		// connection data the URI cannot express at all.
		if o.Port != 0 || !olcrtcProviders[o.Options["olcrtc_provider"]] || !olcrtcTransports[o.Transport] {
			return ErrInvalid
		}
		if !isHex64(o.Password) {
			return ErrInvalid
		}
		if o.Options["olcrtc_provider"] != "none" && o.Host == "" {
			return ErrInvalid
		}
		return nil
	}
	// uint16 permits only zero as an invalid port here; larger values are
	// rejected during parsing.
	if o.Host == "" || o.Port < 1 {
		return ErrInvalid
	}
	if o.Protocol == "vless" || o.Protocol == "vmess" || o.Protocol == "tuic" {
		if o.UUID != "" && !uuidRE.MatchString(o.UUID) {
			return fmt.Errorf("%w: invalid UUID", ErrInvalid)
		}
	}
	return nil
}

var uuidRE = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$`)

// ItemReason identifies a skipped source position and a stable readable reason.
type ItemReason struct {
	Index  int
	Reason string
}

// ImportReport counts all candidate items, including skipped entries, for a
// complete import summary.
type ImportReport struct {
	Imported, SkippedDuplicates, Unsupported, Invalid int
	UnsupportedItems, InvalidItems, DuplicateItems    []ItemReason
}

// ImportResult holds the detected format, validated outbounds, and skipped-item
// report.
type ImportResult struct {
	Format  Format
	Servers []OutboundSpec
	Report  ImportReport
}

// LinkParser parses without mutating src and is safe for concurrent use.
// MaxItems bounds results; zero uses DefaultMaxItems.
type LinkParser struct{ MaxItems int }

func (p LinkParser) limit() int {
	if p.MaxItems <= 0 {
		return DefaultMaxItems
	}
	return p.MaxItems
}

// Parse returns valid outbounds and reports skipped items. Errors indicate an
// unusable whole payload: empty, oversized, or unsupported format.
func (p LinkParser) Parse(src []byte) (ImportResult, error) {
	if len(src) > MaxInputSize {
		return ImportResult{}, ErrInputTooLarge
	}
	d, decoded, e := (ImportDetector{p.limit()}).detect(src)
	if e != nil && d.Format != FormatHTTPSubscription && d.Format != FormatUnknown {
		return ImportResult{Format: d.Format}, e
	}
	if d.Format == FormatHTTPSubscription {
		return ImportResult{Format: d.Format}, ErrUnsupported
	}
	if d.Format == FormatBase64 {
		// detect already decoded the payload to classify it; parse the
		// decoded bytes instead of decoding the raw text a second time.
		return p.parseList(string(decoded), FormatPlainList)
	}
	s := strings.TrimSpace(string(src))
	switch d.Format {
	case FormatSIP008, FormatSingBox, FormatXray:
		return p.parseJSON([]byte(s), d.Format)
	case FormatClash:
		return p.parseYAML([]byte(s))
	case FormatWireGuard:
		return p.parseWG(s)
	}
	return p.parseList(s, d.Format)
}
func (p LinkParser) parseList(s string, f Format) (ImportResult, error) {
	r := ImportResult{Format: f}
	seen := map[string]int{}
	// lastOlcrtc is the index in r.Servers that a "##key: value"
	// subscription block binds to: the nearest preceding olcrtc://
	// line (docs/sub.md). It resets when a non-olcrtc server becomes
	// the nearest preceding line, and a skipped duplicate still counts
	// as the preceding olcrtc line — its block binds to the entry the
	// duplicate deduplicated into.
	lastOlcrtc := -1
	for i, l := range strings.Split(s, "\n") {
		l = strings.TrimSpace(l)
		if l == "" {
			continue
		}
		if strings.HasPrefix(l, "##") {
			if err := applyOLCRTCMeta(&r, lastOlcrtc, l); err != nil {
				r.Report.Invalid++
				r.Report.InvalidItems = append(r.Report.InvalidItems, ItemReason{i, "invalid link fields"})
			}
			continue
		}
		if isSubscriptionMetaLine(l) {
			// Global "#key: value" headers are subscription
			// metadata (read by the subscription layer), not
			// server candidates.
			continue
		}
		if len(r.Servers) >= p.limit() {
			r.Report.Unsupported++
			r.Report.UnsupportedItems = append(r.Report.UnsupportedItems, ItemReason{i, "item limit exceeded"})
			continue
		}
		o, e := parseLink(l)
		if e != nil {
			if errors.Is(e, ErrUnsupported) {
				r.Report.Unsupported++
				r.Report.UnsupportedItems = append(r.Report.UnsupportedItems, ItemReason{i, "unsupported protocol or option"})
			} else {
				r.Report.Invalid++
				r.Report.InvalidItems = append(r.Report.InvalidItems, ItemReason{i, "invalid link fields"})
			}
			continue
		}
		k := o.StableKey()
		if idx, ok := seen[k]; ok {
			r.Report.SkippedDuplicates++
			r.Report.DuplicateItems = append(r.Report.DuplicateItems, ItemReason{i, "duplicate server"})
			if o.Protocol == "olcrtc" {
				lastOlcrtc = idx
			}
			continue
		}
		seen[k] = len(r.Servers)
		r.Servers = append(r.Servers, o)
		r.Report.Imported++
		if o.Protocol == "olcrtc" {
			lastOlcrtc = len(r.Servers) - 1
		} else {
			lastOlcrtc = -1
		}
	}
	if len(r.Servers) == 0 && r.Report.Unsupported == 0 && r.Report.Invalid == 0 {
		return r, ErrUnsupported
	}
	return r, nil
}
func parseLink(raw string) (OutboundSpec, error) {
	// olcrtc links are cut by hand in olcrtc.go: their grammar puts a
	// transport name and a <...> payload where net/url expects a host,
	// and the room may be a full URL of its own. url.Parse would
	// mis-split or reject them (a raw MIMO comment may hold spaces).
	if isOLCRTCLink(raw) {
		return parseOLCRTCLink(raw)
	}
	u, e := url.Parse(strings.TrimSpace(raw))
	if e != nil {
		return OutboundSpec{}, ErrInvalid
	}
	proto := strings.ToLower(u.Scheme)
	if proto == "vmess" {
		return parseVMess(raw, u)
	}
	if proto == "wireguard" || proto == "wg" {
		return parseWireURL(u)
	}
	if !map[string]bool{"vless": true, "trojan": true, "ss": true, "socks": true, "socks5": true, "http": true, "https": true, "hysteria2": true, "hy2": true, "tuic": true}[proto] {
		return OutboundSpec{}, ErrUnsupported
	}
	p, e := parsePort(u.Port())
	if e != nil {
		return OutboundSpec{}, e
	}
	o := OutboundSpec{Protocol: proto, Host: u.Hostname(), Port: p, Transport: "tcp", Security: "none", Options: map[string]string{}}
	if u.User != nil {
		o.User = u.User.Username()
		o.Password, _ = u.User.Password()
	}
	// The query is parsed once and shared by every lookup below:
	// url.URL.Query() re-parses RawQuery on each call, and a link's
	// fields are read through ~20 lookups — on a multi-thousand-link
	// subscription import that re-parsing dominated the whole import.
	q := u.Query()
	for k, v := range q {
		if len(v) > 0 {
			o.Options[k] = v[0]
		}
	}
	// Fail closed on Hysteria2 certificate pinning: pinSHA256 never
	// reaches any engine (no plan field, no renderer), so importing a
	// pinned link today would silently unpin it. The link is skipped
	// and counted as unsupported instead.
	if (proto == "hysteria2" || proto == "hy2") && getq(q, "pinSHA256", "pin_sha256") != "" {
		return OutboundSpec{}, fmt.Errorf("%w: hy2 pinSHA256 certificate pinning is not implemented", ErrUnsupported)
	}
	switch proto {
	case "ss":
		o.Cipher = o.User
		if b, ok := decodeBase64(o.User); ok {
			parts := strings.SplitN(string(b), ":", 2)
			if len(parts) == 2 {
				o.Cipher, o.Password = parts[0], parts[1]
			}
		}
		if o.Password == "" {
			o.Password = getq(q, "password")
		}
		// SIP002 plugin: the combined form "plugin=v2ray-plugin;tls;host=x"
		// or the split form "plugin=v2ray-plugin" + "plugin_opts=tls;host=x".
		// Canonical keys keep the raw "plugin" copy (from the loop above)
		// from leaking into the credential document under two names.
		if opts := getq(q, "plugin_opts", "plugin-opts"); opts != "" {
			o.Options["ss_plugin_opts"] = opts
		}
		if plug := getq(q, "plugin"); plug != "" {
			name, rest, _ := strings.Cut(plug, ";")
			o.Options["ss_plugin"] = strings.TrimSpace(name)
			if o.Options["ss_plugin_opts"] == "" && rest != "" {
				o.Options["ss_plugin_opts"] = rest
			}
		}
	case "tuic":
		o.UUID = o.User
		o.Security = "tls"
	case "trojan", "hysteria2", "hy2":
		// Password-only protocols: the credential is the userinfo
		// username (trojan://<password>@host, hysteria2://<password>@host —
		// the canonical share forms). The generic branch parks the
		// username in UUID and leaves Password empty, so every such
		// link imported without its credential and engines rejected
		// the rendered plan ("unset fields: password") or failed
		// authentication (WAVE-INTEGRATION E2E).
		if o.Password == "" {
			o.Password = o.User
		}
		o.Transport = getq(q, "type", "transport")
		o.Security = getq(q, "security")
	default:
		o.UUID = o.User
		o.Transport = getq(q, "type", "transport")
		o.Security = getq(q, "security")
		if o.Security == "" && proto == "vless" {
			o.Security = "none"
		}
	}
	o.Path = getq(q, "path")
	o.HostHeader = getq(q, "host")
	o.ServiceName = getq(q, "serviceName", "service_name")
	o.Mode = getq(q, "mode")
	o.PublicKey = getq(q, "pbk", "public-key")
	o.ShortID = getq(q, "sid", "short-id")
	o.MLDSA65Verify = getq(q, "pqv", "mldsa65-verify")
	o.SpiderX = getq(q, "spx")
	o.ServerName = getq(q, "sni")
	o.Fingerprint = getq(q, "fp")
	o.Flow = getq(q, "flow")
	o.AllowInsecure = parseBool(getq(q, "allowInsecure", "insecure", "skip-cert-verify"))
	if a := getq(q, "alpn"); a != "" {
		o.ALPN = strings.Split(a, ",")
	}
	for _, k := range []string{"mport", "pinSHA256", "pin_sha256", "obfs", "obfs-password", "obfs_password", "congestion_control", "udp_relay_mode", "heartbeat", "upmbps", "downmbps", "hop-interval", "hopinterval", "hop-interval-max", "hopintervalmax", "bbr-profile", "bbr_profile", "ports", "token"} {
		if v := getq(q, k); v != "" {
			o.Options[k] = v
		}
	}
	// The XHTTP split, xmux tuning and padding ride in the
	// extra=<url-encoded JSON> parameter (de-facto link standard).
	// Garbage there is provider decoration, never an import error:
	// it is ignored, not fatal.
	o.applyExtra(getq(q, "extra"))
	if o.Security == "" {
		// Default security follows protocol semantics: trojan,
		// hysteria2, and HTTPS use TLS; others do not. Empty security
		// would incorrectly enable TLS for plain SOCKS downstream.
		switch proto {
		case "trojan", "hysteria2", "hy2", "https":
			o.Security = "tls"
		default:
			o.Security = "none"
		}
	}
	// Normalize link schemes to engine protocol names.
	o.Protocol = map[string]string{"ss": "shadowsocks", "socks": "socks5", "hy2": "hysteria2", "https": "http"}[proto]
	if o.Protocol == "" {
		o.Protocol = proto
	}
	o.DisplayName = fragmentName(u.Fragment)
	o.CountryCode = countryCode(o.DisplayName)
	return o, o.validate()
}

// extraDownloadSettings is the Xray camelCase shape of the
// downloadSettings object inside a share link's extra=<url-encoded JSON>
// parameter — the de-facto link standard (mihomo's common/convert/v.go).
// Only the recognized fields are read; every other key inside extra
// (session placement, ...) is ignored by the parser.
type extraDownloadSettings struct {
	Address string `json:"address"`
	Port    int    `json:"port"`
}

// extraXmux is the xmux object of the same extra= document. Its
// values are Xray xmux range fields: a JSON number, a numeric
// string, or a "min-max" range string (all three shapes load on the
// pinned Xray, probed CENSOR-P1), so each is kept raw and reduced by
// xmuxRangeValue.
type extraXmux struct {
	MaxConcurrency  json.RawMessage `json:"maxConcurrency"`
	MaxConnections  json.RawMessage `json:"maxConnections"`
	MaxReuseTimes   json.RawMessage `json:"cMaxReuseTimes"`
	MaxRequestTimes json.RawMessage `json:"hMaxRequestTimes"`
}

// xmuxRangeValue reduces one xmux range value to the single int the
// plan models: the lower bound of a range, the value itself for a
// scalar. Unusable values reduce to 0 (engine default).
func xmuxRangeValue(raw json.RawMessage) int {
	if len(raw) == 0 {
		return 0
	}
	var n float64
	if err := json.Unmarshal(raw, &n); err == nil {
		if n < 0 {
			return 0
		}
		return int(n)
	}
	var s string
	if err := json.Unmarshal(raw, &s); err != nil {
		return 0
	}
	if lo, _, found := strings.Cut(s, "-"); found {
		s = lo
	}
	v, err := strconv.Atoi(strings.TrimSpace(s))
	if err != nil || v < 0 {
		return 0
	}
	return v
}

// applyExtra parses the XHTTP data carried by a link's
// extra=<url-encoded JSON> query parameter into the spec: the
// up/down split, the xmux reuse tuning and the padding range. Each
// section applies independently — a missing, malformed, or unusable
// section is ignored without taking the others down: extra is
// provider decoration, and losing it must never fail the import.
// Surviving values are validated again at plan level
// (engine.validateXHTTP); on non-XHTTP transports the split is a
// hard plan error, not a silent drop.
//
// The independence is structural, not aspirational: the document is
// decoded once into raw per-section messages and each section is
// then unmarshalled on its own, so a type error inside one section
// (a port spelled as a string, a padding range spelled as a number,
// an xmux object spelled as a string) fails only that section's
// decode. Decoding the whole document into one typed struct in a
// single Unmarshal — the pre-fix shape — let any one mistyped
// section poison all the others (CENSOR-P1 review T2).
func (o *OutboundSpec) applyExtra(raw string) {
	if raw == "" {
		return
	}
	var sections map[string]json.RawMessage
	if err := json.Unmarshal([]byte(raw), &sections); err != nil {
		return
	}
	if rawDS, ok := sections["downloadSettings"]; ok {
		var ds extraDownloadSettings
		if err := json.Unmarshal(rawDS, &ds); err == nil && ds.Address != "" && ds.Port >= 1 && ds.Port <= 65535 {
			o.DownloadAddress = ds.Address
			o.DownloadPort = uint16(ds.Port)
		}
	}
	if rawXmux, ok := sections["xmux"]; ok {
		var xm extraXmux
		if err := json.Unmarshal(rawXmux, &xm); err == nil {
			o.XmuxMaxConcurrency = xmuxRangeValue(xm.MaxConcurrency)
			o.XmuxMaxConnections = xmuxRangeValue(xm.MaxConnections)
			o.XmuxMaxReuseTimes = xmuxRangeValue(xm.MaxReuseTimes)
			o.XmuxMaxRequestTimes = xmuxRangeValue(xm.MaxRequestTimes)
		}
	}
	if rawPadding, ok := sections["xPaddingBytes"]; ok {
		var padding string
		if err := json.Unmarshal(rawPadding, &padding); err == nil {
			o.XPaddingBytes = padding
		}
	}
}
func parseBool(s string) bool { v, _ := strconv.ParseBool(s); return v }
func parsePort(s string) (uint16, error) {
	n, e := strconv.Atoi(s)
	if e != nil || n < 1 || n > 65535 {
		return 0, ErrInvalid
	}
	return uint16(n), nil
}
func getq(q url.Values, ks ...string) string {
	for _, k := range ks {
		if v := q.Get(k); v != "" {
			return v
		}
	}
	return ""
}
func fragmentName(s string) string {
	v, e := url.QueryUnescape(s)
	if e == nil {
		return v
	}
	return s
}
func countryCode(s string) string {
	r := []rune(s)
	if len(r) >= 2 && r[0] >= 0x1F1E6 && r[0] <= 0x1F1FF && r[1] >= 0x1F1E6 && r[1] <= 0x1F1FF {
		return string(r[:2])
	}
	return ""
}
func parseVMess(raw string, u *url.URL) (OutboundSpec, error) {
	// The classic VMess share link is vmess://<base64 JSON>. url.Parse
	// puts the blob in u.Host (and splits it at any "/" into u.Path), so
	// the payload must be recovered from the raw link text: the former
	// code read u.Opaque/u.Path, which never hold the blob, and the
	// base64 branch was unreachable — every classic VMess link failed
	// validation and was silently dropped from mixed imports
	// (WAVE-INTEGRATION E2E).
	if blob, frag, ok := vmessBlob(raw); ok {
		if b, isB64 := decodeBase64(blob); isB64 {
			var v map[string]any
			if json.Unmarshal(b, &v) == nil {
				if _, classic := v["add"]; classic {
					return mapVMessJSON(v, frag)
				}
				if _, classic := v["id"]; classic {
					return mapVMessJSON(v, frag)
				}
				return mapJSONSpec(v, "vmess")
			}
		}
	}
	if u.Hostname() == "" {
		return OutboundSpec{}, ErrInvalid
	}
	o := OutboundSpec{Protocol: "vmess", Host: u.Hostname(), Transport: "tcp", Security: "auto", Options: map[string]string{}}
	o.Port, _ = parsePort(u.Port())
	if u.User != nil {
		o.UUID = u.User.Username()
		o.Password, _ = u.User.Password()
	}
	q := u.Query()
	for k, v := range q {
		if len(v) > 0 {
			o.Options[k] = v[0]
		}
	}
	o.Transport = getq(q, "type", "transport")
	if o.Transport == "" {
		o.Transport = "tcp"
	}
	if aid := getq(q, "aid", "alterId"); aid != "" && aid != "0" {
		return OutboundSpec{}, fmt.Errorf("%w: vmess alterId %q is legacy pre-AEAD; sora renders AEAD (alterId 0) only", ErrUnsupported, aid)
	}
	o.Security = getq(q, "security")
	if o.Security == "" {
		o.Security = "auto"
	}
	o.DisplayName = fragmentName(u.Fragment)
	return o, o.validate()
}

// vmessBlob extracts the payload of a classic vmess://<base64> link:
// everything after the scheme, minus an optional query and fragment.
// The fragment is returned separately as a fallback display name. ok is
// false when the link has no payload at all (the URL-style form, which
// parseVMess handles from the parsed URL instead).
func vmessBlob(raw string) (blob, frag string, ok bool) {
	s := strings.TrimSpace(raw)
	i := strings.Index(s, "://")
	if i < 0 {
		return "", "", false
	}
	rest := s[i+3:]
	if j := strings.Index(rest, "#"); j >= 0 {
		frag = fragmentName(rest[j+1:])
		rest = rest[:j]
	}
	if j := strings.Index(rest, "?"); j >= 0 {
		rest = rest[:j]
	}
	rest = strings.TrimSpace(rest)
	if rest == "" {
		return "", "", false
	}
	return rest, frag, true
}

// mapVMessJSON maps the classic VMess JSON document (the v2rayN field
// set every provider emits) onto an OutboundSpec. "add"/"id" are the
// dialect markers: the generic JSON mapper reads sing-box-style keys
// (server/uuid) and would leave both empty here.
func mapVMessJSON(m map[string]any, frag string) (OutboundSpec, error) {
	o := OutboundSpec{Protocol: "vmess", Transport: "tcp", Security: "none", Options: map[string]string{}}
	o.Host = stringValue(m["add"])
	if o.Host == "" {
		o.Host = stringValue(m["address"])
	}
	o.Port = portNumber(m["port"])
	o.UUID = stringValue(m["id"])
	o.DisplayName = stringValue(m["ps"])
	if o.DisplayName == "" {
		o.DisplayName = frag
	}
	o.Cipher = stringValue(m["scy"])
	if o.Cipher == "" {
		o.Cipher = "auto"
	}
	// Legacy VMess (alterId > 0) is the pre-AEAD protocol: sora renders
	// AEAD only (alterId 0 on every engine), so importing such a link
	// silently would hand the user a server that can never authenticate
	// while looking imported. Refuse it as unsupported, in the open —
	// the same discipline as the hy2 pinSHA256 refusal above.
	if err := checkVMessAlterID(m["aid"]); err != nil {
		return OutboundSpec{}, err
	}
	if net := stringValue(m["net"]); net != "" {
		o.Transport = net
	}
	switch tls := stringValue(m["tls"]); tls {
	case "":
		// Security stays "none".
	case "tls":
		o.Security = "tls"
	default:
		o.Security = tls
	}
	o.ServerName = stringValue(m["sni"])
	o.HostHeader = stringValue(m["host"])
	o.Path = stringValue(m["path"])
	o.Fingerprint = stringValue(m["fp"])
	if a := stringValue(m["alpn"]); a != "" {
		o.ALPN = strings.Split(a, ",")
	}
	o.AllowInsecure = jsonBool(m["insecure"]) || jsonBool(m["allowInsecure"])
	o.CountryCode = countryCode(o.DisplayName)
	return o, o.validate()
}

// checkVMessAlterID refuses a non-zero VMess alterId in any of its
// loosely typed forms (JSON number, numeric string). Zero, "0" and an
// absent value are AEAD and pass.
func checkVMessAlterID(v any) error {
	if v == nil {
		return nil
	}
	if s, ok := v.(string); ok {
		if s == "" || s == "0" {
			return nil
		}
		return fmt.Errorf("%w: vmess alterId %q is legacy pre-AEAD; sora renders AEAD (alterId 0) only", ErrUnsupported, s)
	}
	if n := number(v); n != 0 {
		return fmt.Errorf("%w: vmess alterId %d is legacy pre-AEAD; sora renders AEAD (alterId 0) only", ErrUnsupported, n)
	}
	return nil
}

// jsonBool reads the loosely typed boolean flags of share-link JSON
// (true, 1, "1", "true" in the wild).
func jsonBool(v any) bool {
	switch x := v.(type) {
	case bool:
		return x
	case float64:
		return x != 0
	case string:
		return x == "1" || strings.EqualFold(x, "true")
	}
	return false
}

func parseWireURL(u *url.URL) (OutboundSpec, error) {
	p, e := parsePort(u.Port())
	if e != nil {
		return OutboundSpec{}, e
	}
	o := OutboundSpec{Protocol: "wireguard", Host: u.Hostname(), Port: p, Transport: "udp", DisplayName: fragmentName(u.Fragment), Options: map[string]string{}}
	q := u.Query()
	for k, v := range q {
		if len(v) > 0 {
			o.Options[k] = v[0]
		}
	}
	if u.User != nil {
		o.Password = u.User.String()
	}
	return o, o.validate()
}
func mapJSONSpec(m map[string]any, fallback string) (OutboundSpec, error) {
	o := OutboundSpec{Protocol: fallback, Transport: "tcp", Options: map[string]string{}}
	if s, ok := m["type"].(string); ok {
		o.Protocol = s
	}
	for _, k := range []string{"server", "address", "host"} {
		if s, ok := m[k].(string); ok && o.Host == "" {
			o.Host = s
		}
	}
	o.Port = portNumber(m["server_port"])
	if o.Port == 0 {
		o.Port = portNumber(m["port"])
	}
	o.UUID = stringValue(m["uuid"])
	o.Password = stringValue(m["password"])
	o.Cipher = stringValue(m["method"])
	o.Transport = stringValue(m["network"])
	if o.Transport == "" {
		o.Transport = stringValue(m["transport"])
	}
	if o.Transport == "" {
		o.Transport = "tcp"
	}
	o.Flow = stringValue(m["flow"])
	o.DisplayName = stringValue(m["tag"])
	o.Security = stringValue(m["security"])
	if o.Protocol == "vmess" {
		// sing-box-shaped VMess documents spell it alter_id; both keys
		// are legacy pre-AEAD when non-zero (see mapVMessJSON).
		if err := checkVMessAlterID(m["aid"]); err != nil {
			return OutboundSpec{}, err
		}
		if err := checkVMessAlterID(m["alter_id"]); err != nil {
			return OutboundSpec{}, err
		}
	}
	for k, v := range m {
		if b, err := json.Marshal(v); err == nil {
			o.Options[k] = string(b)
		}
	}
	return o, o.validate()
}
func stringValue(v any) string {
	if s, ok := v.(string); ok {
		return s
	}
	return ""
}

// portNumber returns zero outside 1..65535 so validation rejects invalid ports
// instead of truncating them.
func portNumber(v any) uint16 {
	n := number(v)
	if n < 1 || n > math.MaxUint16 {
		return 0
	}
	return uint16(n)
}

// number converts JSON number representations to int, returning zero for
// invalid or overflowing values.
func number(v any) int {
	switch n := v.(type) {
	case float64:
		if n < 0 || n > math.MaxInt32 {
			return 0
		}
		return int(n)
	case int:
		return n
	case uint64:
		if n > uint64(math.MaxInt32) {
			return 0
		}
		return int(n)
	case string:
		i, _ := strconv.Atoi(n)
		return i
	}
	return 0
}
func (p LinkParser) parseJSON(b []byte, f Format) (ImportResult, error) {
	var v any
	if json.Unmarshal(b, &v) != nil {
		return ImportResult{Format: f}, ErrInvalid
	}
	items := []any{}
	switch x := v.(type) {
	case []any:
		items = x
	case map[string]any:
		if a, ok := x["outbounds"].([]any); ok {
			items = a
		} else if a, ok := x["servers"].([]any); ok {
			items = a
		} else if a, ok := x["outbound"].([]any); ok {
			items = a
		} else if f == FormatXray {
			items = xrayItems(x)
		} else {
			items = []any{x}
		}
	}
	r := ImportResult{Format: f}
	// Treat full Xray configurations, including Remnawave lists, as
	// separate provider profiles.
	if m, ok := v.(map[string]any); ok && isXrayConfig(m) {
		items = []any{m}
	}
	// Deduplicate by StableKey exactly as parseList does: without it a
	// subscription listing the same endpoint+UUID under two names yields
	// two specs with the same identity (and duplicate UI keys).
	seen := map[string]struct{}{}
	for i, it := range items {
		m, ok := it.(map[string]any)
		if !ok {
			continue
		}
		if isXrayConfig(m) {
			o, e := profileSpec(m)
			if e != nil {
				r.Report.Invalid++
				continue
			}
			k := o.StableKey()
			if _, ok := seen[k]; ok {
				r.Report.SkippedDuplicates++
				r.Report.DuplicateItems = append(r.Report.DuplicateItems, ItemReason{i, "duplicate server"})
				continue
			}
			seen[k] = struct{}{}
			r.Servers = append(r.Servers, o)
			r.Report.Imported++
			continue
		}
		// SIP008 entries carry no "type" field at all: the format
		// itself means Shadowsocks, so it supplies the protocol the
		// generic mapper otherwise requires. Without it every SIP008
		// entry failed validation and a SIP008 subscription imported
		// zero servers (B1 servers audit).
		fallback := ""
		if f == FormatSIP008 {
			fallback = "shadowsocks"
		}
		o, e := mapJSONSpec(m, fallback)
		if e != nil {
			r.Report.Invalid++
			continue
		}
		if o.Protocol == "" {
			r.Report.Unsupported++
			continue
		}
		// SIP008 names the entry "remarks", not the sing-box "tag" the
		// generic mapper reads; keep the provider's name. Its plugin
		// fields use the plain SIP002 names, so map them onto the
		// canonical option keys the credential document copies (the
		// generic Options dump JSON-quotes them under their raw names).
		if o.DisplayName == "" {
			o.DisplayName = stringValue(m["remarks"])
			o.CountryCode = countryCode(o.DisplayName)
		}
		if s, ok := m["plugin"].(string); ok && s != "" {
			o.Options["ss_plugin"] = s
		}
		if s, ok := m["plugin_opts"].(string); ok && s != "" {
			o.Options["ss_plugin_opts"] = s
		}
		k := o.StableKey()
		if _, ok := seen[k]; ok {
			r.Report.SkippedDuplicates++
			r.Report.DuplicateItems = append(r.Report.DuplicateItems, ItemReason{i, "duplicate server"})
			continue
		}
		seen[k] = struct{}{}
		r.Servers = append(r.Servers, o)
		r.Report.Imported++
	}
	return r, nil
}

// isXrayConfig distinguishes full configurations by Xray-shaped outbounds with
// protocol and settings fields.
func isXrayConfig(m map[string]any) bool {
	outs, ok := m["outbounds"].([]any)
	if !ok || len(outs) == 0 {
		return false
	}
	first, ok := outs[0].(map[string]any)
	if !ok {
		return false
	}
	_, hasProtocol := first["protocol"]
	return hasProtocol
}

// profileSpec stores compacted configuration in Options["profile"]. The default
// outbound supplies endpoint, transport, and security for display and
// measurement.
func profileSpec(m map[string]any) (OutboundSpec, error) {
	raw, err := json.Marshal(m)
	if err != nil {
		return OutboundSpec{}, ErrInvalid
	}
	o := OutboundSpec{Protocol: "xray-profile", Options: map[string]string{"profile": string(raw)}}
	o.DisplayName = strings.TrimSpace(stringValue(m["remarks"]))
	for _, it := range m["outbounds"].([]any) {
		ob, ok := it.(map[string]any)
		if !ok {
			continue
		}
		switch stringValue(ob["protocol"]) {
		case "freedom", "blackhole", "dns", "loopback", "":
			continue
		}
		o.Host, o.Port = xrayEndpoint(ob)
		o.DisplayProtocol = stringValue(ob["protocol"])
		if ss, ok := ob["streamSettings"].(map[string]any); ok {
			o.Transport = stringValue(ss["network"])
			o.Security = stringValue(ss["security"])
		}
		break
	}
	if o.Transport == "" {
		o.Transport = "tcp"
	}
	if o.Security == "" {
		o.Security = "none"
	}
	if o.DisplayName == "" {
		o.DisplayName = o.Host
	}
	o.CountryCode = countryCode(o.DisplayName)
	return o, o.validate()
}

// xrayEndpoint reads settings.vnext, settings.servers, or newer flat
// settings.address endpoints.
func xrayEndpoint(ob map[string]any) (string, uint16) {
	settings, _ := ob["settings"].(map[string]any)
	for _, key := range []string{"vnext", "servers", "peers"} {
		if list, ok := settings[key].([]any); ok && len(list) > 0 {
			if first, ok := list[0].(map[string]any); ok {
				host := stringValue(first["address"])
				if host == "" {
					host = stringValue(first["endpoint"])
				}
				return host, portNumber(first["port"])
			}
		}
	}
	return stringValue(settings["address"]), portNumber(settings["port"])
}

func xrayItems(m map[string]any) []any {
	if a, ok := m["outbounds"].([]any); ok {
		return a
	}
	return []any{m}
}
func (p LinkParser) parseYAML(b []byte) (ImportResult, error) {
	var root struct {
		Proxies []map[string]any `yaml:"proxies"`
	}
	if yaml.Unmarshal(b, &root) != nil {
		return ImportResult{Format: FormatClash}, ErrInvalid
	}
	r := ImportResult{Format: FormatClash}
	// Deduplicate by StableKey exactly as parseList does (see parseJSON).
	seen := map[string]struct{}{}
	for i, m := range root.Proxies {
		o, e := mapJSONSpec(m, "")
		if e != nil {
			r.Report.Invalid++
			continue
		}
		o.DisplayName = stringValue(m["name"])
		k := o.StableKey()
		if _, ok := seen[k]; ok {
			r.Report.SkippedDuplicates++
			r.Report.DuplicateItems = append(r.Report.DuplicateItems, ItemReason{i, "duplicate server"})
			continue
		}
		seen[k] = struct{}{}
		r.Servers = append(r.Servers, o)
		r.Report.Imported++
	}
	return r, nil
}
func (p LinkParser) parseWG(s string) (ImportResult, error) {
	o := OutboundSpec{Protocol: "wireguard", Transport: "udp", Options: map[string]string{}}
	section := ""
	var peer WireGuardPeer
	for _, line := range strings.Split(s, "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "[") {
			if section == "[peer]" {
				o.Peers = append(o.Peers, peer)
				peer = WireGuardPeer{}
			}
			section = strings.ToLower(line)
			continue
		}
		kv := strings.SplitN(line, "=", 2)
		if len(kv) != 2 {
			continue
		}
		k := strings.ToLower(strings.TrimSpace(kv[0]))
		v := strings.TrimSpace(kv[1])
		if section == "[interface]" {
			o.Options[k] = v
		}
		if section == "[peer]" {
			switch k {
			case "publickey":
				peer.PublicKey = v
			case "presharedkey":
				peer.PreSharedKey = v
			case "endpoint":
				peer.Endpoint = v
				h, p, e := net.SplitHostPort(v)
				if e == nil {
					o.Host = h
					o.Port, _ = parsePort(p)
				}
			case "allowedips":
				peer.AllowedIPs = strings.Split(v, ",")
			case "persistentkeepalive":
				peer.PersistentKeepalive, _ = strconv.Atoi(v)
			}
		}
	}
	if section == "[peer]" {
		o.Peers = append(o.Peers, peer)
	}
	if e := o.validate(); e != nil {
		return ImportResult{Format: FormatWireGuard}, e
	}
	return ImportResult{Format: FormatWireGuard, Servers: []OutboundSpec{o}, Report: ImportReport{Imported: 1}}, nil
}
