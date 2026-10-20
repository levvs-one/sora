package engine

import (
	"encoding/json"
	"net/netip"
	"strings"
)

// Limits mirror the sora.core.v1 contract. A plan that exceeds them is
// rejected before any engine sees it.
const (
	MaxOutbounds      = 5000
	MaxGroups         = 500
	MaxRules          = 10000
	MaxIDLen          = 128
	MaxNameBytes      = 256
	MaxHeaderCount    = 32
	MaxDNSServers     = 32
	TestURLProduction = "https://www.gstatic.com/generate_204"
)

// Protocol is an outbound protocol name as used in plans.
type Protocol string

// Outbound protocols a plan may hold, named as the control plane names them.
const (
	ProtocolVLESS       Protocol = "vless"
	ProtocolVMess       Protocol = "vmess"
	ProtocolTrojan      Protocol = "trojan"
	ProtocolShadowsocks Protocol = "shadowsocks"
	ProtocolHysteria2   Protocol = "hysteria2"
	ProtocolTUIC        Protocol = "tuic"
	ProtocolWireGuard   Protocol = "wireguard"
	ProtocolSOCKS5      Protocol = "socks5"
	ProtocolHTTP        Protocol = "http"
	ProtocolAnyTLS      Protocol = "anytls"
	// ProtocolBypass reshapes direct TLS and HTTP handshakes with zapret to
	// evade DPI. It requires no server.
	ProtocolBypass Protocol = "bypass"
	// ProtocolXrayProfile runs a provider's full Xray configuration within
	// the session, preserving outbounds, balancers, and routing. Only Xray
	// supports it.
	ProtocolXrayProfile Protocol = "xray-profile"
	ProtocolDirect      Protocol = "direct"
)

// GroupType is how the engine chooses between the members of a group.
type GroupType string

// Strategies the engine uses to pick a member of a group.
const (
	GroupSelect      GroupType = "select"
	GroupURLTest     GroupType = "url-test"
	GroupFallback    GroupType = "fallback"
	GroupLoadBalance GroupType = "load-balance"
)

// ECHConfig holds Encrypted Client Hello (RFC 9849) parameters of an
// outbound. The zero value disables ECH.
type ECHConfig struct {
	// Enabled turns ECH on. Without a pinned Config the engine fetches the
	// ECHConfigList from the server's HTTPS DNS record, so a working
	// (ideally encrypted) DNS path is required for the bootstrap.
	Enabled bool
	// Config pins PEM-encoded ECHConfigList lines, skipping the DNS
	// lookup. Useful where encrypted DNS itself is blocked.
	Config []string
	// QueryServerName overrides the domain used for the ECH DNS query.
	// Rendered by sing-box (ech.query_server_name, available since
	// 1.13 — below the 1.14.3 floor) and by mihomo
	// (ech-opts.query-server-name). The Xray renderer does not emit
	// ECH at all; see FeatureECH.
	QueryServerName string
}

// TLS holds transport security parameters of an outbound.
type TLS struct {
	Enabled     bool
	ServerName  string
	ALPN        []string
	Fingerprint string
	// ECH enables Encrypted Client Hello. Opt-in only: some censors drop
	// ClientHellos carrying the ECH extension, so it must never default on.
	ECH      ECHConfig
	Insecure bool
	Reality  bool
	// RealityPublicKey and other REALITY parameters are public but masked
	// because they identify a server.
	RealityPublicKey string
	RealityShortID   string
	// RealityMLDSA65Verify is the server's ML-DSA-65 verification key
	// (the "pqv" link parameter): base64url, 1952 bytes decoded. When
	// set, the REALITY handshake must carry a valid ML-DSA-65
	// signature over it, which binds the session to the post-quantum
	// server key instead of only the X25519 public key. Only Xray
	// spells it (realitySettings.mldsa65Verify, verified on the
	// pinned 26.10.17 binary by config test and by traffic); the
	// other engines have no field for it — probed on the pins:
	// sing-box rejects the key as unknown, mihomo silently ignores
	// unknown reality-opts keys — so a plan setting it requires
	// FeatureRealityMLDSA65 instead of losing the check silently.
	RealityMLDSA65Verify string
	SpiderX              string
	// KeyShare selects the key share the REALITY ClientHello offers:
	// "" leaves the engine default, "classical" offers X25519 only,
	// "hybrid" offers the X25519MLKEM768 hybrid. REALITY servers on
	// Xray >= 26.9.8 accept only the hybrid share, so against them
	// "classical" (or a default that omits the hybrid) fails the
	// handshake with an opaque verification error (PASS2 deep S3).
	// Two renderers emit it: mihomo as
	// reality-opts.support-x25519mlkem768 (PASS3 deep S2) and
	// sing-box-lx as tls.reality.key_share (CENSOR-P1, verified with
	// `sing-box check` on the pinned lx.22 binary). Xray has no
	// key_share knob — its uTLS parrot decides the offered groups —
	// so a plan setting KeyShare requires FeatureRealityKeyShare and
	// never routes to Xray (CENSOR-P1). Mihomo's own default is
	// MEASURED by wire capture on the pinned 1.19.32 binary
	// (CENSOR-FP): with KeyShare unset its REALITY ClientHello offers
	// NO hybrid group (~590-byte hello), so "" honestly means
	// "engine default" — and on mihomo that default offers no
	// hybrid, never a promise that it does.
	KeyShare string
}

// Transport holds the stream transport of an outbound.
type Transport struct {
	// Type is tcp, ws, grpc, h2, httpupgrade or xhttp.
	Type    string
	Path    string
	Host    string
	Service string
	Headers map[string]string
	// EarlyData caps WebSocket 0-RTT: the first payload bytes ride the
	// handshake instead of waiting for it. Zero disables it; only the
	// ws transport honours it.
	EarlyData int
	// EarlyDataHeaderName names the header that carries the WebSocket
	// early data instead of the default Sec-WebSocket-Protocol. All
	// three engines spell it (sing-box early_data_header_name, Xray
	// earlyDataHeaderName, mihomo early-data-header-name; each render
	// verified against the pinned binary). It is meaningless without
	// EarlyData and validation rejects the stray combination.
	EarlyDataHeaderName string
	// GRPCAuthority overrides the gRPC :authority pseudo-header. Only
	// Xray spells it (grpcSettings.authority, verified on the pin);
	// sing-box and mihomo have no such field and their stacks silently
	// ignore unknown keys, so a plan setting it reports the feature
	// missing on those engines (see catalog MissingFor) and their
	// renderers refuse it instead of dropping it.
	GRPCAuthority string
	// GRPCMultiMode selects Xray's multi-mode gRPC (multiple streams
	// per H2 connection, "gun" multi). Xray-only, like GRPCAuthority.
	GRPCMultiMode bool
	// GRPCUserAgent overrides the gRPC User-Agent. Xray spells it
	// user_agent and mihomo grpc-user-agent (both verified on the
	// pins); sing-box has no spelling, so it is gated there.
	GRPCUserAgent string
	// Mode is the XHTTP mode: auto, packet-up, stream-up or stream-one.
	Mode string
	// DownloadAddress and DownloadPort split the XHTTP downlink onto a
	// separate server, so uplink and downlink can ride different domains.
	// Both must be set together; the fields are ignored by other
	// transports and rejected there by the engines.
	DownloadAddress string
	DownloadPort    uint16
	// Xmux tunes XHTTP connection reuse. MaxConcurrency (streams per
	// connection) and MaxConnections are mutually exclusive. Zero keeps
	// the engine default. The mihomo renderer emits these fields as
	// reuse-settings (PASS3 deep A1) and mihomo claims
	// FeatureXHTTPXmux (verified with `mihomo -t` on the pin,
	// 2026-10-20); the Xray and sing-box renderers do not emit xmux,
	// so a plan setting these fields reports the feature missing on
	// those engines instead of silently dropping the tuning at
	// selection time (see FeatureXHTTPXmux).
	XmuxMaxConcurrency  int
	XmuxMaxConnections  int
	XmuxMaxReuseTimes   int
	XmuxMaxRequestTimes int
	// XPaddingBytes is the random XHTTP padding range, "min-max" or a
	// single number, e.g. "100-1000". The mihomo renderer emits it as
	// x-padding-bytes; the Xray and sing-box renderers do not emit it
	// yet, so on those paths the value is validated here and dropped
	// at render time (same staged state as the xmux fields above).
	XPaddingBytes string
}

// WireGuardPeer is one WireGuard peer of an outbound.
type WireGuardPeer struct {
	PublicKey           string
	PreSharedKey        string
	Endpoint            string
	AllowedIPs          []string
	PersistentKeepalive int
}

// Outbound is one server the plan can route traffic through.
type Outbound struct {
	ID   string
	Name string

	Protocol  Protocol
	Transport Transport
	TLS       TLS
	// SOCKSUDP enables UDP on a SOCKS5 peer known to support associations.
	SOCKSUDP bool

	Server string
	Port   uint16

	// UUID and the following credential fields must be masked in logs and
	// events.
	UUID     string
	Password string
	Cipher   string
	UserID   string
	Flow     string
	// FlowAuto records that Flow was assigned by plan-level auto-vision
	// (Outbound.ApplyAutoVision) rather than by the import link or the
	// user. Intended UI contract: the app shows an "auto" badge next to
	// the flow when this is true. (The plan proto does not expose the
	// flow yet, so nothing consumes the flag today; it rides every
	// struct copy and is ready for the wire field.) It is only ever set
	// together with Flow by ApplyAutoVision; a manually configured flow
	// always leaves it false.
	FlowAuto  bool
	Obfs      string
	ObfsParam string
	// Plugin and PluginOpts carry a Shadowsocks SIP002 obfuscation plugin
	// (e.g. v2ray-plugin) and its raw option string, verbatim from the
	// import link. When set, Plugin wins over the legacy Obfs/ObfsParam
	// obfs-local mapping. Like the other credential fields, PluginOpts
	// must be masked in logs and events.
	Plugin     string
	PluginOpts string
	PrivateKey string
	PublicKey  string
	ShortID    string
	// Encryption configures VLESS. Empty or "none" disables it; other
	// values use Xray's post-quantum VLESS Encryption.
	Encryption string
	// UpMbps and DownMbps are the client's Hysteria2 bandwidth caps in
	// Mbps (from upmbps/downmbps in the import link). Positive values
	// switch sing-box and mihomo from BBR to Hysteria (Brutal) congestion
	// control; zero means auto (BBR).
	UpMbps   int
	DownMbps int
	// HopPorts is the Hysteria2 port-hopping spec, e.g.
	// "20000-30000,40000" (from mport/ports in the import link). Empty
	// keeps the single Port.
	HopPorts string
	// HopInterval is the Hysteria2 port hop interval in seconds. Zero
	// keeps the engine default (30s); the protocol requires at least 5s.
	HopInterval int
	// HopIntervalMax is the randomized upper bound of the port hop
	// interval in seconds (sing-box 1.14 hop_interval_max; Hysteria
	// 2.8's randomized hop interval). Zero keeps a fixed HopInterval.
	HopIntervalMax int
	// BBRProfile selects the sing-box 1.14 Hysteria2 BBR congestion
	// profile: "standard", "conservative" or "aggressive". Empty keeps
	// the engine default. It applies only while BBR is in charge (no
	// bandwidth caps — caps switch the client to Brutal).
	BBRProfile string
	// CongestionControl selects the TUIC QUIC congestion controller:
	// "bbr" (default), "cubic" or "new_reno". Unknown values are rejected.
	CongestionControl string
	// UDPRelayMode selects the TUIC UDP relay mode: "native" (default)
	// or "quic".
	UDPRelayMode string
	// TUICHeartbeat is the TUIC heartbeat (keepalive) interval in
	// seconds. Zero keeps DefaultTUICHeartbeatSeconds (see
	// quic_defaults.go); renderers emit the effective value on both
	// TUIC engines (sing-box heartbeat duration, mihomo
	// heartbeat-interval in milliseconds) so a session's keepalive
	// never depends on which engine carries it.
	TUICHeartbeat int
	// Token is the TUIC v4 pre-shared token; v5 authenticates with
	// UUID+Password. Like the other credential fields, it must be masked
	// in logs and events.
	Token string

	Peers []WireGuardPeer
	// Amnezia turns a WireGuard outbound into AmneziaWG. Nil is plain
	// WireGuard.
	Amnezia *AmneziaWG
	// Bypass is the strategy of a bypass outbound.
	Bypass *BypassStrategy
	// Via is the id of the outbound this one dials through, forming a proxy
	// chain: traffic enters this outbound and exits the last hop. Empty
	// means a direct connection. Chains need the "chains" engine feature.
	Via string
	// Profile contains a provider's Xray configuration and credentials, so
	// the entire value is secret.
	Profile json.RawMessage
	// Addresses lists WireGuard interface CIDRs, required for the tunnel to
	// carry traffic.
	Addresses []string
}

// Group is a user-selectable set of outbounds.
type Group struct {
	Name      string
	Type      GroupType
	Outbounds []string
	// Selected is the member a select group starts on (an outbound id or
	// a nested group name, one of Outbounds). Empty starts on the first
	// member. Every engine honours it at Apply time — sing-box renders it
	// as the selector's default, Xray seeds its selection map from it,
	// and the Clash-API engines apply it through the controller right
	// after start — so a fresh session's effective selection is Selected
	// on all engines (the fast-switch invariant). Meaningful only for
	// GroupSelect; validation rejects it elsewhere.
	Selected  string
	URL       string
	Interval  int
	Tolerance int
	Lazy      bool
	Hidden    bool
	Icon      string
	Provider  string
}

// RuleType is a rule matcher as named in the sora.core.v1 contract.
type RuleType string

// Rule matchers a plan may carry.
const (
	RuleDomain        RuleType = "domain"
	RuleDomainSuffix  RuleType = "domain-suffix"
	RuleDomainKeyword RuleType = "domain-keyword"
	RuleIPCIDR        RuleType = "ip-cidr"
	RuleIPSuffix      RuleType = "ip-suffix"
	RuleGeoIP         RuleType = "geoip"
	RuleGeoSite       RuleType = "geosite"
	RuleRuleSet       RuleType = "rule-set"
	RulePort          RuleType = "port"
	RuleSrcPort       RuleType = "src-port"
	RuleProcess       RuleType = "process"
	RuleProtocol      RuleType = "protocol"
	RuleMatchAll      RuleType = "all"
)

// Rule routes a matching destination to an outbound or a group.
type Rule struct {
	Type      RuleType
	Value     string
	Target    string
	NoResolve bool
}

// DNSTransport is how a DNS server is reached.
type DNSTransport string

// Transports a DNS server of the plan can be reached by. "h3" is DNS over
// HTTPS carried by HTTP/3 (DoH3); engines render it with their own H3
// spelling, never as plain DoH.
const (
	DNSPlain  DNSTransport = "udp"
	DNSTCP    DNSTransport = "tcp"
	DNSTLS    DNSTransport = "tls"
	DNSHTTPS  DNSTransport = "https"
	DNSH3     DNSTransport = "h3"
	DNSQUIC   DNSTransport = "quic"
	DNSSystem DNSTransport = "system"
	DNSFakeIP DNSTransport = "fakeip"
)

// DNSServer is one resolver of the plan.
type DNSServer struct {
	Tag        string
	Transport  DNSTransport
	Address    string
	Port       uint16
	Dialer     string
	ProxyOnly  bool
	SkipVerify bool // skip TLS verification for DoT/DoH/DoQ upstreams (corporate MITM)
}

// DNS is the resolver setup of the plan.
type DNS struct {
	Enabled          bool
	Mode             string // rule, fakeip, redir-host
	FakeIPRange      string
	FakeIPRange6     string   // IPv6 fake-address pool; rendered only when IPv6 is on
	FakeIPFilter     []string // domains that never receive a fake address
	FakeIPTTL        int      // seconds; 0 leaves the engine default in place
	Servers          []DNSServer
	NameserverPolicy map[string][]string
	DisableCache     bool
	Sniff            bool
	HijackTun        []string
}

// DefaultFakeIPRange is the fake-address pool every engine renders when the
// plan does not pin one (S7): the full RFC 2544 benchmarking range
// 198.18.0.0/15. One shared constant — sing-box, mihomo and the TUN
// preparer can never desync, and mihomo's cache.db invalidation keys off
// the masked pool, so a desync would silently mix stale mappings.
const DefaultFakeIPRange = "198.18.0.0/15"

// DefaultFakeIPRange6 is the IPv6 fake-address pool, rendered only when the
// IPv6 option is on.
const DefaultFakeIPRange6 = "fc00::/18"

// DefaultFakeIPFilter is the plan-level fallback for domains that must get
// real addresses: LAN/mDNS names, NTP, STUN and OS connectivity checks.
// Renderers apply it when DNS.FakeIPFilter is empty.
//
// The list is written in mihomo wildcard syntax, which both renderers
// understand. sing-box has no domain_suffix spelling for interior
// wildcards (ntp.*.com, +.stun.*.*), so the sing-box renderer converts
// those to domain_regex — never silently dropping them (S7): a silent
// drop hands NTP/STUN hosts fake IPs on sing-box while mihomo resolves
// them for real, desyncing the engines and breaking time sync.
//
// time.*.com is expanded into explicit well-known public NTP servers
// (S7: expand interior wildcards into explicit suffixes). The residual
// ntp.*.com keeps exact wildcard semantics via domain_regex on sing-box:
// vendor NTP hosts have no finite well-known list, and over-matching a
// filter entry is harmless (the domain simply resolves for real).
var DefaultFakeIPFilter = []string{
	"*.lan",
	"*.local",
	"*.home.arpa",
	"*.invalid",
	"localhost",
	// NTP, expanded from time.*.com (S7).
	"time.windows.com",
	"time.google.com",
	"time.cloudflare.com",
	"time.apple.com",
	"time.nist.gov",
	"ntp.ubuntu.com",
	"+.pool.ntp.org",
	"ntp.*.com",
	// STUN: a fake IP breaks WebRTC connectivity checks (S7).
	// +.stun.*.* covers stun.<host>.<tld>; the numbered Google hosts use
	// a stun<N> label the wildcard cannot spell, so they are listed
	// explicitly — same expansion principle as the NTP list above.
	"stun.l.google.com",
	"stun1.l.google.com",
	"stun2.l.google.com",
	"stun3.l.google.com",
	"stun4.l.google.com",
	"stun.stunprotocol.org",
	"+.stun.*.*",
	"+.msftconnecttest.com",
	"+.msftncsi.com",
}

// TunDevice names Sora's adapter to avoid collisions and allow startup checks.
const TunDevice = "sora0"

// Tun is the virtual network interface setup of the plan.
type Tun struct {
	IPv4             netip.Prefix
	IPv6             netip.Prefix
	Enabled          bool
	Stack            string // system, gvisor, mixed, mips (mihomo or Xray bridge)
	DeviceName       string
	MTU              int
	StrictRoute      bool
	AutoRoute        bool
	RouteAddressSets []string
	IncludeApps      []string
	ExcludeApps      []string
}

// AmneziaWG holds configuration-file obfuscation parameters that must match the
// server. Zero values are omitted to retain engine defaults.
type AmneziaWG struct {
	Jc, Jmin, Jmax int
	S1, S2, S3, S4 int
	// H1..H4 are message type headers: a number, or a range in AmneziaWG
	// 2.0.
	H1, H2, H3, H4 string
	// I1..I5 are the signature packets of AmneziaWG 1.5 and 2.0.
	I1, I2, I3, I4, I5 string
	J1, J2, J3         string
	Itime              int
	// AmneziaWG 3.1 parameters (2026, answer to AI/behavioral DPI). All
	// optional; an untouched 3.1 section keeps 1.x/2.0 behavior. 3.1 needs
	// an engine build with verified 3.1 support (see UsesAWG31): without
	// one, plans using these fields fail engine selection instead of
	// rendering a silently unobfuscated tunnel.
	// HeaderProtectionKey is the 32-byte ChaCha20 key (base64 or hex in
	// configs) hiding low-entropy header fields; it requires S1..S4 >= 12.
	HeaderProtectionKey string
	// ContentPaddingAddition is a range<uint16> ("a-b" or "a"): random
	// bytes added to transport payloads, breaking the 16-byte multiple
	// size pattern WireGuard leaks.
	ContentPaddingAddition string
	// Custom timings, each a range<uint16> ("a-b" or "a"): the engine
	// picks a random value from the range whenever the timer is armed,
	// so sessions stop looking repetitive.
	RekeyAfterTime       string
	RekeyTimeout         string
	RejectAfterTime      string
	KeepaliveTimeout     string
	MaxHandshakeAttempts string
	// RandomTrailers appends random trailers to packets (the 3.1 docs
	// recommend S1==S2==S3==S4 alongside so types stay distinguishable).
	RandomTrailers bool
	// DisableCookies stops sending Cookie Reply messages. The
	// official 3.1 spec stops there (incoming cookies keep working),
	// but the engines' v3 devices read the knob wider — sing-box-lx
	// documents "never send or demand cookie replies" (the
	// under-load mac2 gate), and mihomo's v3 fix line names the same
	// field — so the honest promise is only "this client does not
	// send cookie replies"; whether it also stops demanding them is
	// the engine's semantics, wider than the spec (PASS2 deep A1).
	// It is a client-side knob either way and does not affect
	// client↔server compatibility.
	DisableCookies bool
	// Masquerade* carry the sing-box-lx id/ip/ib decoy sugar: the engine
	// generates the I1 signature packet mimicking the given protocol
	// instead of a hand-written I1 (see FeatureAmneziaMasquerade).
	// Protocol is quic, dns, stun or sip; Domain is the decoy domain
	// (ClientHello SNI, DNS QNAME or SIP host); Browser selects the
	// QUIC decoy's ClientHello fingerprint (chrome, firefox or curl).
	// Setting a protocol is mutually exclusive with I1.
	MasqueradeProtocol string
	MasqueradeDomain   string
	MasqueradeBrowser  string
}

// awg31Ranges lists the AmneziaWG 3.1 fields that carry range<uint16>
// values, for enablement checks and validation loops.
func (a *AmneziaWG) awg31Ranges() [][2]string {
	return [][2]string{
		{"contentpaddingaddition", a.ContentPaddingAddition},
		{"rekeyaftertime", a.RekeyAfterTime},
		{"rekeytimeout", a.RekeyTimeout},
		{"rejectaftertime", a.RejectAfterTime},
		{"keepalivetimeout", a.KeepaliveTimeout},
		{"maxhandshakeattempts", a.MaxHandshakeAttempts},
	}
}

// awgRangeEnabled reports whether a range<uint16> value ("a-b" or "a")
// enables its mechanism. Per the 3.1 spec, "0", "0-0" and "" disable it.
func awgRangeEnabled(raw string) bool {
	raw = strings.TrimSpace(raw)
	return raw != "" && raw != "0" && raw != "0-0"
}

// UsesAWG31 reports whether any AmneziaWG 3.1 mechanism is enabled. Callers
// use it to demand an engine build with verified 3.1 support: rendering
// 3.1 fields to an engine that ignores them would put plain WireGuard on
// the wire while the UI promises obfuscation.
func (a *AmneziaWG) UsesAWG31() bool {
	if a == nil {
		return false
	}
	if strings.TrimSpace(a.HeaderProtectionKey) != "" || a.RandomTrailers || a.DisableCookies {
		return true
	}
	for _, r := range a.awg31Ranges() {
		if awgRangeEnabled(r[1]) {
			return true
		}
	}
	return false
}

// UsesMasquerade reports whether the id/ip/ib decoy sugar is requested.
// Only sing-box-lx implements it (see FeatureAmneziaMasquerade): other
// engines would silently drop the decoy.
func (a *AmneziaWG) UsesMasquerade() bool {
	return a != nil && (a.MasqueradeProtocol != "" || a.MasqueradeDomain != "" || a.MasqueradeBrowser != "")
}

// BypassStrategy defines zapret handshake shaping. Positions are byte offsets,
// negative from the end, or markers (method, host, endhost, sld, midsld,
// endsld, sniext) with optional +N or -N.
type BypassStrategy struct {
	SplitPos []string
	// Disorder sends the second part of a split first.
	Disorder bool
	// DisorderScope limits disorder to one protocol: "" (both), "http" or
	// "tls". Needs Disorder.
	DisorderScope string
	// OOB sends an out-of-band byte with the split.
	OOB bool
	// OOBScope limits the out-of-band byte to one protocol: "" (both),
	// "http" or "tls". Needs OOB.
	OOBScope string
	// TLSRecord splits the ClientHello into two TLS records at a position.
	TLSRecord string
	// HostCase reshapes HTTP header casing; DomainCase and MethodEOL also
	// reshape plain HTTP requests.
	HostCase   bool
	DomainCase bool
	MethodEOL  bool
	// HostDot adds "." after the Host: name; HostTab and HostNoSpace
	// reshape the space after Host:; MethodSpace adds an extra space
	// after the HTTP method; UnixEOL replaces CRLF with LF in plain
	// HTTP requests.
	HostDot     bool
	HostTab     bool
	HostNoSpace bool
	MethodSpace bool
	UnixEOL     bool
	// SplitAnyProtocol splits every protocol, not only HTTP and TLS.
	SplitAnyProtocol bool
	// TamperStart limits handshake shaping to outbound stream positions at
	// or after this point ("--tamper-start"); TamperCutoff stops shaping
	// after it ("--tamper-cutoff"). Both use the same position syntax as
	// SplitPos, with an optional leading "n" selecting a data block number
	// instead of a byte offset. Shaping only the handshake keeps long-lived
	// connections fast.
	TamperStart  string
	TamperCutoff string
	// OOBData overrides the default 0x00 out-of-band byte: one character or
	// 0xHEX ("--oob-data"). Needs OOB.
	OOBData string
	// MSS clamps the TCP maximum segment size ("--mss"), a plain byte count.
	// Last resort only: unlike the shaping options it throttles every
	// connection the strategy touches, so it must never be a default.
	MSS string
	// Desync lists nfqws --dpi-desync methods in order, e.g. "fake",
	// "split2", "disorder2", "multisplit". Any entry selects the nfqws
	// backend; empty keeps the legacy tpws-compatible SplitPos,
	// Disorder, OOB, TLSRecord and HTTP-shaping fields above. tpws
	// cannot inject packets, so fake-based methods never run on it.
	Desync []string
	// FakeTLS and FakeQUIC name the fake payloads for the fake desync
	// method: "tls"/"quic" keep zapret's built-ins, anything else is a
	// file name under the zapret home directory (packaging/zapret
	// ships files/fake/*.bin there). FakeQUIC needs FilterUDP covering
	// 443; QUIC has no built-in fake, so FakeQUIC should name a file.
	FakeTLS  string
	FakeQUIC string
	// Fooling degrades the fake/disorder packet so the censor's stack
	// drops it while the real server tolerates it: "badseq", "badack",
	// "md5sig", "ts", "badsum", "datanoack". Needs Desync.
	Fooling string
	// TTL fixes the fake packet TTL so it dies before the server;
	// AutoTTL derives it from the path instead
	// (nfqws --dpi-desync-autottl). Mutually exclusive. Need Desync.
	TTL     int
	AutoTTL bool
	// AutoTTLDelta is the safety margin (in hops) the autottl
	// calibration keeps between the fake packet's death and the
	// server: the rendered form is --dpi-desync-autottl=<delta>:<min>-<max>
	// with the window from bypass.FakeTTL (a fake must die after the
	// in-path censor but strictly before the server). Zero keeps
	// zapret's own default autottl. Needs AutoTTL (and with it, fake).
	AutoTTLDelta int
	// Repeats duplicates the fake injection
	// (nfqws --dpi-desync-repeats). Needs Desync.
	Repeats int
	// FilterTCP and FilterUDP select the intercepted ports, e.g.
	// "80,443" and "443". FilterL7 limits desync to application
	// layers, e.g. "tls,quic". Empty filters leave the backend default
	// in place. UDP/QUIC desync needs FilterUDP.
	FilterTCP string
	FilterUDP string
	FilterL7  string
}

// Fragment splits proxy TLS ClientHello messages across TCP segments to evade
// SNI matching on a single segment.
type Fragment struct {
	Enabled bool
	// Packets selects Xray segments ("tlshello" or "1-3"); Length sets
	// bytes ("100-200") and Interval sets milliseconds ("10-20"). Engines
	// with only a switch use Enabled.
	Packets  string
	Length   string
	Interval string
}

// Options configures engine-wide plan settings.
type Options struct {
	LogLevel    string
	Mode        string // rule, global, direct
	FindProcess bool
	GeoData     bool
	AllowLAN    bool
	IPv6        bool
	TestURL     string
	GeoSiteURL  string
	GeoIPURL    string
	Fragment    Fragment
	// Mux configures multiplexing of REALITY outbounds. The zero value
	// keeps the default: mux on for REALITY, off everywhere else. See
	// mux.go for the policy and the vision↔mux decision.
	Mux MuxOptions
	// Fingerprint is the session's uTLS fingerprint policy as data:
	// per-protocol profiles, the rotation order for probes, the
	// session default. The zero value is the canonical behaviour
	// (explicit outbound fingerprints win, REALITY gets the engine
	// default). See fingerprint_policy.go.
	Fingerprint FingerprintPolicy
}

// LocalProxy opens a loopback HTTP/SOCKS5 listener only for system proxy mode
// or explicit requests. Other local applications can use it and discover the
// upstream server address.
type LocalProxy struct {
	Enabled bool
	// Username and Password restrict the listener to authenticated
	// applications. System proxies cannot supply a login.
	Username string
	Password string
}

// Plan is a complete, engine-independent description of one session.
type Plan struct {
	SessionID string
	// Engines is the engine preference of this session, best first. Empty
	// uses the core default; a single entry pins that engine.
	Engines []Kind
	// PrivateControl requires Unix sockets, named pipes, or no controller,
	// preventing discovery through listening network ports.
	PrivateControl bool
	LocalProxy     LocalProxy

	Outbounds []Outbound
	Groups    []Group
	Rules     []Rule
	DNS       DNS
	Tun       Tun
	Options   Options
}
