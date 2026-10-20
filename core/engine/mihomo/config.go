// Package mihomo drives MetaCubeX/mihomo through its local Clash API. The
// GPL-3.0 engine remains a separate binary for license separation, crash
// isolation, and independent updates. Render produces its YAML configuration.
package mihomo

// Ports and limits used when Sora starts one engine process.
const (
	// MaxConfigBytes bounds the rendered config before it reaches the
	// engine.
	MaxConfigBytes = 8 << 20
)

// Shipped geodata uses geoip.dat and geosite.dat, also read by Xray; these
// sources support automatic updates.
const (
	GeoSiteDefaultURL = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
	GeoIPDefaultURL   = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat"
)

// Runtime holds supervisor-selected values for one engine run, separate from
// the reusable plan.
type Runtime struct {
	// HomeDir is passed as -d. mihomo resolves relative paths against it.
	HomeDir string
	// ControllerAddr is host:port of the loopback controller, e.g.
	// 127.0.0.1:23456.
	ControllerAddr string
	// Secret authorizes controller requests. Sora requires it because all
	// local users can reach loopback ports.
	Secret string
	// MixedPort is the local http+socks listener, opened only when the plan
	// asks for a local proxy.
	MixedPort int
	// TestURL is the default latency probe for groups without one.
	TestURL string
}

// config models mihomo YAML. Unset keys are omitted because some empty values
// are explicit settings upstream.
type config struct {
	MixedPort          int                      `yaml:"mixed-port"`
	AllowLAN           bool                     `yaml:"allow-lan"`
	BindAddress        string                   `yaml:"bind-address,omitempty"`
	Mode               string                   `yaml:"mode"`
	LogLevel           string                   `yaml:"log-level"`
	IPv6               *bool                    `yaml:"ipv6,omitempty"`
	ExternalController string                   `yaml:"external-controller,omitempty"`
	ControllerUnix     string                   `yaml:"external-controller-unix,omitempty"`
	ControllerPipe     string                   `yaml:"external-controller-pipe,omitempty"`
	Authentication     []string                 `yaml:"authentication,omitempty"`
	Secret             string                   `yaml:"secret,omitempty"`
	UnifiedDelay       *bool                    `yaml:"unified-delay,omitempty"`
	TCPConcurrent      *bool                    `yaml:"tcp-concurrent,omitempty"`
	FindProcessMode    string                   `yaml:"find-process-mode,omitempty"`
	GlobalUA           string                   `yaml:"global-ua,omitempty"`
	GeodataMode        *bool                    `yaml:"geodata-mode,omitempty"`
	GeodataLoader      string                   `yaml:"geodata-loader,omitempty"`
	GeoAutoUpdate      *bool                    `yaml:"geo-auto-update,omitempty"`
	GeoUpdateInterval  int                      `yaml:"geo-update-interval,omitempty"`
	GeoX               map[string]string        `yaml:"geox-url,omitempty"`
	Profile            *profile                 `yaml:"profile,omitempty"`
	DNS                *dnsConfig               `yaml:"dns,omitempty"`
	Listeners          []*tunConfig             `yaml:"listeners,omitempty"`
	Proxies            []proxy                  `yaml:"proxies,omitempty"`
	ProxyGroups        []proxyGroup             `yaml:"proxy-groups,omitempty"`
	ProxyProviders     map[string]proxyProvider `yaml:"proxy-providers,omitempty"`
	RuleProviders      map[string]ruleProvider  `yaml:"rule-providers,omitempty"`
	Rules              []string                 `yaml:"rules,omitempty"`
}

// profile keeps user choices across restarts.
type profile struct {
	StoreSelected bool `yaml:"store-selected"`
	StoreFakeIP   bool `yaml:"store-fake-ip"`
}

// proxy models a mihomo entry. Name, type, server, and port are required; empty
// protocol-specific fields are omitted.
type proxy struct {
	Name   string `yaml:"name"`
	Type   string `yaml:"type"`
	Server string `yaml:"server,omitempty"`
	Port   int    `yaml:"port,omitempty"`
	UDP    *bool  `yaml:"udp,omitempty"`
	TFO    *bool  `yaml:"tfo,omitempty"`
	MPTCP  *bool  `yaml:"mptcp,omitempty"`
	IPVer  string `yaml:"ip-version,omitempty"`
	Tag    string `yaml:"tag,omitempty"`
	Dialer string `yaml:"dialer-proxy,omitempty"`

	UUID         string `yaml:"uuid,omitempty"`
	Flow         string `yaml:"flow,omitempty"`
	AlterID      *int   `yaml:"alterId,omitempty"` // required by mihomo for vmess, even when 0
	Cipher       string `yaml:"cipher,omitempty"`
	Password     string `yaml:"password,omitempty"`
	Username     string `yaml:"username,omitempty"`
	Obfs         string `yaml:"obfs,omitempty"`
	ObfsParam    string `yaml:"obfs-param,omitempty"`
	ObfsPassword string `yaml:"obfs-password,omitempty"`
	// SSPlugin selects a Shadowsocks SIP002 obfuscation plugin
	// (v2ray-plugin, ...); SSPluginOpts is its translated option map.
	SSPlugin      string         `yaml:"plugin,omitempty"`
	SSPluginOpts  map[string]any `yaml:"plugin-opts,omitempty"`
	Protocol      string         `yaml:"protocol,omitempty"`
	ProtocolParam string         `yaml:"protocol-param,omitempty"`
	TLS           *bool          `yaml:"tls,omitempty"`

	// Network selects the stream transport. Its options must be nested
	// because mihomo silently ignores unknown flat keys.
	Network    string     `yaml:"network,omitempty"`
	WSOpts     *wsOpts    `yaml:"ws-opts,omitempty"`
	GRPCOpts   *grpcOpts  `yaml:"grpc-opts,omitempty"`
	H2Opts     *h2Opts    `yaml:"h2-opts,omitempty"`
	XHTTPOpts  *xhttpOpts `yaml:"xhttp-opts,omitempty"`
	Encryption string     `yaml:"encryption,omitempty"`

	SNI string `yaml:"sni,omitempty"`
	// ServerName is the "servername" spelling of the TLS server name.
	// mihomo's adapters disagree on the key: vless and vmess read only
	// "servername" and silently drop "sni", while trojan, anytls,
	// hysteria2, tuic and http read only "sni" (adapter option structs
	// of the pinned 1.19.32 source). Emitting the wrong spelling is not
	// an error at load; the handshake just verifies the certificate
	// against the server address and fails, so applyTLS picks the key
	// per protocol.
	ServerName     string   `yaml:"servername,omitempty"`
	SkipCertVerify *bool    `yaml:"skip-cert-verify,omitempty"`
	Fingerprint    string   `yaml:"client-fingerprint,omitempty"`
	ALPN           []string `yaml:"alpn,omitempty"`
	// ECH carries Encrypted Client Hello as ech-opts: the enable
	// toggle, the pinned config (one base64 string) and the DNS query
	// name override. The legacy flat `ech: true` spelling dropped the
	// pinned config and the query name (PASS3 deep S4).
	ECH     *echOpts `yaml:"ech-opts,omitempty"`
	Reality *reality `yaml:"reality-opts,omitempty"`

	// Hysteria2 bandwidth caps ("100 Mbps"): positive values switch the
	// engine from BBR to Brutal congestion control.
	Up   string `yaml:"up,omitempty"`
	Down string `yaml:"down,omitempty"`
	// Hysteria2 port hopping: ranges list ("20000-30000,40000") and the
	// hop interval in seconds (minimum 5).
	Ports       string `yaml:"ports,omitempty"`
	HopInterval int    `yaml:"hop-interval,omitempty"`
	// TUIC v4 pre-shared token; v5 authenticates with uuid+password.
	Token string `yaml:"token,omitempty"`
	// TUIC congestion controller ("bbr", "cubic", "new_reno") and UDP
	// relay mode ("native", "quic").
	CongestionController string `yaml:"congestion-controller,omitempty"`
	UDPRelayMode         string `yaml:"udp-relay-mode,omitempty"`
	// TUIC heartbeat (keepalive) interval in milliseconds; the plan
	// carries seconds (engine plan TUICHeartbeat), the renderer
	// converts from the effective value in quic_defaults.go.
	HeartbeatInterval int `yaml:"heartbeat-interval,omitempty"`

	PrivateKey string          `yaml:"private-key,omitempty"`
	IP         string          `yaml:"ip,omitempty"`
	IPv6       string          `yaml:"ipv6,omitempty"`
	MTU        int             `yaml:"mtu,omitempty"`
	Peers      []wireguardPeer `yaml:"peers,omitempty"`
	Amnezia    map[string]any  `yaml:"amnezia-wg-option,omitempty"`

	PublicKey           string   `yaml:"public-key,omitempty"`
	PreSharedKey        string   `yaml:"pre-shared-key,omitempty"`
	AllowedIPs          []string `yaml:"allowed-ips,omitempty"`
	PersistentKeepalive int      `yaml:"persistent-keepalive,omitempty"`
	Smux                *smux    `yaml:"smux,omitempty"`
}

type wsOpts struct {
	Path             string            `yaml:"path,omitempty"`
	Headers          map[string]string `yaml:"headers,omitempty"`
	V2RayHTTPUpgrade bool              `yaml:"v2ray-http-upgrade,omitempty"`
	// MaxEarlyData caps WebSocket 0-RTT: the first payload bytes ride
	// the handshake. Zero disables it.
	MaxEarlyData int `yaml:"max-early-data,omitempty"`
	// EarlyDataHeaderName renames the header carrying the early data
	// (verified accepted by `mihomo -t` on the pin, CENSOR-P2).
	EarlyDataHeaderName string `yaml:"early-data-header-name,omitempty"`
}

type grpcOpts struct {
	ServiceName string `yaml:"grpc-service-name,omitempty"`
	// UserAgent is grpc-user-agent (verified on the pin). Mihomo has
	// no authority or multi-mode key and silently ignores unknown
	// YAML keys, so those plan fields are refused in applyTransport
	// instead of being dropped here.
	UserAgent string `yaml:"grpc-user-agent,omitempty"`
}

type h2Opts struct {
	Host []string `yaml:"host,omitempty"`
	Path string   `yaml:"path,omitempty"`
}

type xhttpOpts struct {
	Path    string            `yaml:"path,omitempty"`
	Host    string            `yaml:"host,omitempty"`
	Mode    string            `yaml:"mode,omitempty"`
	Headers map[string]string `yaml:"headers,omitempty"`
	// XPaddingBytes is x-padding-bytes of the pinned docs: the
	// random padding range attached to each request ("100-1000").
	// The server checks the range, so dropping a pinned range could
	// get requests rejected (PASS3 deep S1/A1).
	XPaddingBytes    string         `yaml:"x-padding-bytes,omitempty"`
	ReuseSettings    *xhttpReuse    `yaml:"reuse-settings,omitempty"`
	DownloadSettings *xhttpDownload `yaml:"download-settings,omitempty"`
}

// xhttpReuse is reuse-settings (aka XMUX) of the pinned docs. All
// values are range strings there ("16-32", "600-900"), so the plan's
// ints render as plain number strings. h-max-reusable-secs and
// h-keep-alive-period have no plan fields and stay unset.
type xhttpReuse struct {
	MaxConcurrency   string `yaml:"max-concurrency,omitempty"`
	MaxConnections   string `yaml:"max-connections,omitempty"`
	CMaxReuseTimes   string `yaml:"c-max-reuse-times,omitempty"`
	HMaxRequestTimes string `yaml:"h-max-request-times,omitempty"`
	HMaxReusableSecs string `yaml:"h-max-reusable-secs,omitempty"`
}

// xhttpDownload is download-settings: the separate downlink leg.
// Items left unset inherit the uplink parameters (pinned docs), so
// only the split address/port and the leg's own reuse-settings are
// rendered.
type xhttpDownload struct {
	Server        string      `yaml:"server,omitempty"`
	Port          int         `yaml:"port,omitempty"`
	ReuseSettings *xhttpReuse `yaml:"reuse-settings,omitempty"`
}

// wireguardPeer is one WireGuard peer.
type wireguardPeer struct {
	Server              string   `yaml:"server"`
	Port                int      `yaml:"port"`
	PublicKey           string   `yaml:"public-key"`
	PreSharedKey        string   `yaml:"pre-shared-key,omitempty"`
	AllowedIPs          []string `yaml:"allowed-ips,omitempty"`
	PersistentKeepalive int      `yaml:"persistent-keepalive,omitempty"`
}

// smux enables multiplexing for one outbound.
type smux struct {
	Enabled        bool   `yaml:"enabled"`
	Protocol       string `yaml:"protocol,omitempty"`
	MaxConnections int    `yaml:"max-connections,omitempty"`
	MinStreams     int    `yaml:"min-streams,omitempty"`
	Padding        bool   `yaml:"padding,omitempty"`
	OnlyTCP        *bool  `yaml:"only-tcp,omitempty"`
}

// reality carries the VLESS Reality parameters of one outbound.
type reality struct {
	PublicKey string `yaml:"public-key,omitempty"`
	ShortID   string `yaml:"short-id,omitempty"`
	// SupportMLKEM768 is reality-opts.support-x25519mlkem768 of the
	// pinned docs. A pointer, so an explicit false (plan KeyShare
	// "classical") renders as false instead of vanishing, and nil
	// (KeyShare unset) omits the key entirely.
	SupportMLKEM768 *bool `yaml:"support-x25519mlkem768,omitempty"`
}

// echOpts is mihomo's ECH block (ech-opts in the pinned docs):
// enable, the pinned ECHConfigList as one base64 string (empty means
// "resolve via DNS"), and the name to use for that DNS resolution.
type echOpts struct {
	Enable          bool   `yaml:"enable"`
	Config          string `yaml:"config,omitempty"`
	QueryServerName string `yaml:"query-server-name,omitempty"`
}

// proxyGroup models a selectable group. Interval uses seconds and Timeout uses
// milliseconds, per mihomo.
type proxyGroup struct {
	Name            string   `yaml:"name"`
	Type            string   `yaml:"type"`
	Proxies         []string `yaml:"proxies,omitempty"`
	Use             []string `yaml:"use,omitempty"`
	URL             string   `yaml:"url,omitempty"`
	Interval        int      `yaml:"interval,omitempty"`
	Timeout         int      `yaml:"timeout,omitempty"`
	MaxFailed       int      `yaml:"max-failed-times,omitempty"`
	Tolerance       int      `yaml:"tolerance,omitempty"`
	Lazy            *bool    `yaml:"lazy,omitempty"`
	Hidden          *bool    `yaml:"hidden,omitempty"`
	Icon            string   `yaml:"icon,omitempty"`
	ExpectedStatus  []int    `yaml:"expected-status,omitempty"`
	DefaultSelected string   `yaml:"default-selected,omitempty"`
	Filter          string   `yaml:"filter,omitempty"`
	ExcludeFilter   string   `yaml:"exclude-filter,omitempty"`
	DisableUDP      *bool    `yaml:"disable-udp,omitempty"`
}

// proxyProvider is one subscription source handled by the engine itself.
type proxyProvider struct {
	Type          string          `yaml:"type"`
	URL           string          `yaml:"url,omitempty"`
	Path          string          `yaml:"path,omitempty"`
	Interval      int             `yaml:"interval,omitempty"`
	Proxy         string          `yaml:"proxy,omitempty"`
	SizeLimit     string          `yaml:"size-limit,omitempty"`
	Health        *providerHealth `yaml:"health-check,omitempty"`
	Filter        string          `yaml:"filter,omitempty"`
	ExcludeFilter string          `yaml:"exclude-filter,omitempty"`
	ExcludeType   string          `yaml:"exclude-type,omitempty"`
}

// providerHealth is the health-check block of a proxy provider.
type providerHealth struct {
	Enable   bool   `yaml:"enable"`
	URL      string `yaml:"url,omitempty"`
	Interval int    `yaml:"interval,omitempty"`
	Timeout  int    `yaml:"timeout,omitempty"`
	Lazy     *bool  `yaml:"lazy,omitempty"`
}

// dnsConfig is the mihomo resolver block.
type dnsConfig struct {
	Enable                bool                `yaml:"enable"`
	Listen                string              `yaml:"listen,omitempty"`
	IPv6                  *bool               `yaml:"ipv6,omitempty"`
	EnhancedMode          string              `yaml:"enhanced-mode,omitempty"`
	FakeIPRange           string              `yaml:"fake-ip-range,omitempty"`
	FakeIPFilter          []string            `yaml:"fake-ip-filter,omitempty"`
	FakeIPTTL             *int                `yaml:"fake-ip-ttl,omitempty"`
	CacheAlgorithm        string              `yaml:"cache-algorithm,omitempty"`
	RespectRules          *bool               `yaml:"respect-rules,omitempty"`
	DefaultNameserver     []string            `yaml:"default-nameserver,omitempty"`
	Nameserver            []string            `yaml:"nameserver,omitempty"`
	Fallback              []string            `yaml:"fallback,omitempty"`
	NameserverPolicy      map[string][]string `yaml:"nameserver-policy,omitempty"`
	ProxyServerNameserver []string            `yaml:"proxy-server-nameserver,omitempty"`
	DirectNameserver      []string            `yaml:"direct-nameserver,omitempty"`
}

// tunConfig models the TUN block. Upstream defaults to gvisor; Sora uses mixed
// unless the plan requests system.
type tunConfig struct {
	Name                string   `yaml:"name"`
	Type                string   `yaml:"type"`
	Stack               string   `yaml:"stack,omitempty"`
	Device              string   `yaml:"device,omitempty"`
	MTU                 int      `yaml:"mtu,omitempty"`
	AutoRoute           *bool    `yaml:"auto-route,omitempty"`
	AutoDetectInterface *bool    `yaml:"auto-detect-interface,omitempty"`
	DNSHijack           []string `yaml:"dns-hijack,omitempty"`
	StrictRoute         *bool    `yaml:"strict-route,omitempty"`
	RouteAddress        []string `yaml:"route-address,omitempty"`
	RouteExcludeAddress []string `yaml:"route-exclude-address,omitempty"`
	IncludePackage      []string `yaml:"include-package,omitempty"`
	ExcludePackage      []string `yaml:"exclude-package,omitempty"`
	Inet4Address        []string `yaml:"inet4-address,omitempty"`
	Inet6Address        []string `yaml:"inet6-address,omitempty"`
	IPRoute2TableIndex  int      `yaml:"iproute2-table-index,omitempty"`
}
