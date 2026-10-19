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
	// Not rendered yet: it needs sing-box >= 1.13, above our 1.12 minimum.
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
	ECH         ECHConfig
	Insecure    bool
	Reality     bool
	// RealityPublicKey and other REALITY parameters are public but masked
	// because they identify a server.
	RealityPublicKey string
	RealityShortID   string
	SpiderX          string
}

// Transport holds the stream transport of an outbound.
type Transport struct {
	// Type is tcp, ws, grpc, h2, httpupgrade or xhttp.
	Type        string
	Path        string
	Host        string
	Service     string
	Headers     map[string]string
	Prefix      string
	IdleTimeout int
	// EarlyData caps WebSocket 0-RTT: the first payload bytes ride the
	// handshake instead of waiting for it. Zero disables it; only the
	// ws transport honours it.
	EarlyData int
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
	// the engine default. Xray renders xmux, mihomo renders
	// reuse-settings; sing-box cannot honour them (see
	// FeatureXHTTPXmux).
	XmuxMaxConcurrency int
	XmuxMaxConnections int
	XmuxMaxReuseTimes  int
	XmuxMaxRequestTimes int
	// XPaddingBytes is the random XHTTP padding range, "min-max" or a
	// single number, e.g. "100-1000". Xray, mihomo and sing-box-lx all
	// accept the range spelling.
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
	UUID       string
	Password   string
	Cipher     string
	UserID     string
	Flow       string
	Obfs       string
	ObfsParam  string
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
	// CongestionControl selects the TUIC QUIC congestion controller:
	// "bbr" (default), "cubic" or "new_reno". Unknown values are rejected.
	CongestionControl string
	// UDPRelayMode selects the TUIC UDP relay mode: "native" (default)
	// or "quic".
	UDPRelayMode string
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

	// Tags come from subscriptions and drive grouping in the interface.
	Tags         []string
	CountryCode  string
	ProviderID   string
	OriginalLink string
}

// Group is a user-selectable set of outbounds.
type Group struct {
	Name      string
	Type      GroupType
	Outbounds []string
	URL       string
	Interval  int
	Tolerance int
	Lazy      bool
	Hidden    bool
	Icon      string
	Provider  string
	Include   []string
	Exclude   []string
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
	Suffixes   []string
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

// DefaultFakeIPFilter is the plan-level fallback for domains that must get
// real addresses: LAN/mDNS names, NTP, and OS connectivity checks. Renderers
// apply it when DNS.FakeIPFilter is empty.
var DefaultFakeIPFilter = []string{
	"*.lan",
	"*.local",
	"*.home.arpa",
	"*.invalid",
	"localhost",
	"time.*.com",
	"ntp.*.com",
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
	// DisableCookies stops sending Cookie Reply messages; incoming
	// cookies and the rest of the cookie machinery keep working.
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
	LogLevel       string
	Mode           string // rule, global, direct
	UnifiedDelay   bool
	FindProcess    bool
	GeoData        bool
	AllowLAN       bool
	IPv6           bool
	ProfileStorage bool
	TestURL        string
	GeoSiteURL     string
	GeoIPURL       string
	Fragment       Fragment
	// Mux configures multiplexing of REALITY outbounds. The zero value
	// keeps the default: mux on for REALITY, off everywhere else. See
	// mux.go for the policy and the vision↔mux decision.
	Mux MuxOptions
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
