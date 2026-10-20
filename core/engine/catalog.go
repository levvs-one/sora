package engine

import (
	"errors"
	"fmt"
	"maps"
	"slices"
	"sort"
	"strings"
)

// Availability describes an engine build found on this machine.
type Availability struct {
	Kind      Kind
	Path      string
	Version   Version
	Usable    bool
	Reason    string
	BuildTags []string
}

// Catalog holds upstream engine capabilities, separate from installed
// Availability. Entries were validated with mihomo v1.19.32 (-t), sing-box
// v1.14.2 (check), sing-box-lx v1.14.3-lx.14 capability tags (unit), and
// Xray v26.3.27 (run -test).
var Catalog = map[Kind]Capabilities{
	KindMihomo: {
		Kind:       KindMihomo,
		MinVersion: "1.19.0",
		Protocols: map[Protocol]bool{
			ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
			ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolTUIC: true,
			ProtocolWireGuard: true, ProtocolSOCKS5: true, ProtocolHTTP: true,
			ProtocolAnyTLS: true, ProtocolDirect: true,
		},
		Features: map[Feature]bool{
			FeatureTun: true, FeatureFakeIP: true, FeatureRuleSets: true,
			FeatureProxyProviders: true, FeatureURLTest: true, FeatureLatencyTest: true,
			FeatureHotApply: true, FeatureGeoData: true, FeatureFallbackGroup: true,
			FeatureLoadBalance: true, FeatureXHTTP: true, FeatureVLESSEncrypt: true,
			FeatureAmneziaWG: true, FeaturePrivateControl: true, FeatureChains: true,
			FeatureHy2PortHop: true, FeatureDoH3: true,
			// Deliberately no FeatureXHTTPDownloadSplit/XHTTPXmux: sora's
			// mihomo renderer emits only path/host/mode/headers in
			// xhttp-opts, so a split or xmux-tuned plan routed to mihomo
			// would silently drop the downlink settings. The upstream
			// download-settings/reuse-settings shapes are a backlog
			// render (spec 09-xhttp §3); until it is implemented and
			// verified with mihomo -t, such plans route Xray-only.
		},
	},
	KindSingBox: {
		Kind: KindSingBox,
		// Upstream stable is 1.14.3 (checked 2026-10-20): the 1.15 line
		// is still alpha (1.15.0-alpha.12), so a "1.15.0" floor would
		// gate on a release that does not exist. The renderer needs the
		// DNS and rule-action formats added in 1.12, which 1.14.3 has.
		// 1.15 rewrote TUN around sing-tun's own TCP/IP stack, so the
		// stack option is deprecated there (removed in 1.17); the
		// renderer only emits it for older builds (see MissingFor).
		MinVersion: "1.14.3",
		Protocols: map[Protocol]bool{
			ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
			ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolTUIC: true,
			ProtocolWireGuard: true, ProtocolSOCKS5: true, ProtocolHTTP: true,
			ProtocolAnyTLS: true, ProtocolDirect: true,
		},
		Features: map[Feature]bool{
			FeatureTun: true, FeatureFakeIP: true, FeatureRuleSets: true,
			FeatureURLTest: true, FeatureLatencyTest: true, FeatureGeoData: true,
			FeaturePerAppRouting: true, FeatureTLSFragment: true, FeatureChains: true,
			FeatureHy2PortHop: true, FeatureDoH3: true,
			// Deliberately no FeatureXHTTPDownloadSplit/XHTTPXmux: the
			// lx fork's xhttp transport has neither downlink splitting
			// nor xmux reuse tuning (x_padding_bytes only).
		},
	},
	KindXray: {
		Kind: KindXray,
		// The minimum version is the shipped build verified for
		// Hysteria2, XHTTP, and VLESS Encryption.
		MinVersion: "26.3.27",
		Protocols: map[Protocol]bool{
			ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
			ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolWireGuard: true,
			ProtocolSOCKS5: true, ProtocolHTTP: true, ProtocolDirect: true, ProtocolXrayProfile: true,
		},
		Features: map[Feature]bool{
			// Xray TUN does not install routes; engine/tunroute
			// supplies them on supported platforms (see
			// catalog_*.go).
			FeatureURLTest: true, FeatureLoadBalance: true, FeatureLatencyTest: true,
			FeatureGeoData: true, FeatureTLSFragment: true,
			FeatureXHTTP: true, FeatureVLESSEncrypt: true, FeaturePrivateControl: true,
			FeatureXHTTPDownloadSplit: true,
			// Deliberately no FeatureXHTTPXmux: no renderer emits xmux
			// or x_padding yet — not even Xray's (its xhttp case renders
			// only mode/path/host/downloadSettings). Claiming it routed
			// xmux-tuned plans to a silent loss; until a renderer emits
			// xmux and is verified, such plans honestly report the
			// feature missing on every engine (PASS3 deep S1).
			// dialerProxy exists since long before the minimum
			// version, so chains need no extra version gate.
			FeatureChains: true,
			// Deliberately no FeatureHy2PortHop: Xray's hysteria2
			// outbound cannot hop ports (see FeatureHy2PortHop).
			// Deliberately no FeatureDoH3: Xray has no DNS-over-HTTP/3
			// transport (see FeatureDoH3).
		},
	},
}

// xrayPlaintextCutoff is the first Xray release that refuses plaintext
// (no TLS, no REALITY) VLESS/Trojan outbounds at config load instead of
// silently connecting without encryption. The shipped pin (26.3.27, see
// packaging/engines/engines.lock and Catalog[KindXray].MinVersion) predates
// the cutoff, so the gate only bites once the engine is bumped or a
// user-supplied build is selected.
// Upstream policy behind the cut:
// https://xtls.github.io/en/config/inbounds/trojan.html
// ("Trojan must be used with transport-security TLS ...").
var xrayPlaintextCutoff = Version{Raw: "26.7.11", Major: 26, Minor: 7, Patch: 11}

// xrayCutsPlaintext reports whether an Xray build refuses plaintext
// VLESS/Trojan outbounds (see xrayPlaintextCutoff). A zero Version means
// the build is unknown (the legacy Missing contract): fail closed and
// assume the cutoff applies — a rejected plan is fixed explicitly by
// enabling TLS/REALITY, while a rendered config the engine refuses at
// load costs a dead connection with no actionable error.
func xrayCutsPlaintext(v Version) bool {
	return v == Version{} || !v.Less(xrayPlaintextCutoff)
}

// XrayPlaintextMissing lists the plan's VLESS/Trojan outbounds that an
// Xray build of version v refuses at config load: unencrypted (no TLS, no
// REALITY, and — for VLESS — no VLESS Encryption) on builds >=
// xrayPlaintextCutoff. A Trojan outbound is never plaintext here: the xray
// renderer always sets security: tls for Trojan (xray/render.go), so the
// check skips Trojan without an explicit TLS block, matching MissingFor
// (catalog.go). Upstream phrases the prohibition as "without TLS or
// other encryption" (VLESS Encryption counts), so an encrypted VLESS
// outbound is accepted without TLS/REALITY. It is a no-op for other
// engines and for older builds, including the shipped 26.3.27 pin, so
// current behavior is unchanged until the engine is bumped. Callers pass
// the probed engine version (Availability.Version, Supervisor.Version) —
// never a hardcoded string.
func (c Capabilities) XrayPlaintextMissing(p *Plan, v Version) []string {
	if c.Kind != KindXray || !xrayCutsPlaintext(v) {
		return nil
	}
	for _, o := range p.Outbounds {
		if o.Protocol != ProtocolVLESS && o.Protocol != ProtocolTrojan {
			continue
		}
		encrypted := o.TLS.Enabled || o.TLS.Reality ||
			// The xray renderer always sets security: tls for Trojan
			// (xray/render.go), so a Trojan without an explicit TLS
			// block is encrypted by construction — never plaintext,
			// matching MissingFor above.
			o.Protocol == ProtocolTrojan ||
			(o.Protocol == ProtocolVLESS && o.Encryption != "" && o.Encryption != "none")
		if !encrypted {
			return []string{fmt.Sprintf("plaintext %s (Xray %s+ refuses it; enable TLS or REALITY)", o.Protocol, xrayPlaintextCutoff)}
		}
	}
	return nil
}

// BuildCapabilities keeps upstream and downstream builds distinct. A version
// suffix alone cannot prove that an optional transport was compiled in.
func BuildCapabilities(kind Kind, version Version, tags []string) Capabilities {
	caps := Catalog[kind]
	if kind == KindSingBox && strings.HasPrefix(version.PreRelease, "lx.") &&
		!version.Less(Version{Major: 1, Minor: 14, Patch: 3}) {
		caps.Features = maps.Clone(caps.Features)
		caps.Features[FeatureXHTTP] = slices.Contains(tags, "with_xhttp")
		caps.Features[FeatureVLESSEncrypt] = true
		if slices.Contains(tags, "with_awg") {
			caps.Features[FeatureAmneziaWG] = true
			// The fork's AWG stack is amneziawg-go v3.1: it renders the
			// 3.x parameters and the id/ip/ib masquerade sugar.
			caps.Features[FeatureAmneziaWG3] = true
			caps.Features[FeatureAmneziaMasquerade] = true
		}
	}
	return caps
}

// DefaultPreference tries sing-box for low memory use, cross-platform TUN, and
// native Android support, then Xray for XHTTP and VLESS Encryption, then mihomo
// for fallback groups, providers, and routing.
var DefaultPreference = []Kind{KindSingBox, KindXray, KindMihomo}

// PrivatePreference prioritizes controllers inaccessible to other programs.
// mihomo retains counters and connection tracking over a private socket; Xray
// runs without a controller.
var PrivatePreference = []Kind{KindSingBox, KindMihomo, KindXray}

// ErrNoEngine reports that no available engine carries an outbound or a plan.
var ErrNoEngine = errors.New("engine: no available engine carries this")

// Selection is the engine chosen for a plan.
type Selection struct {
	Kind   Kind
	Reason string
	// Rejected lists skipped engines in preference order so clients can
	// explain selection failures.
	Rejected []string
}

// singBoxFloor returns the minimum accepted sing-box version for a probed
// build: 1.15.0 upstream, 1.14.3 for the 1.14-based lx. fork (which
// versions itself as "<base>-lx.<n>"). Raising the upstream pin must not
// reject the shipped fork (packaging/engines/engines.lock pins
// sing-box-lx v1.14.3-lx.14).
func singBoxFloor(v Version) string {
	if strings.HasPrefix(v.PreRelease, "lx.") && !v.Less(Version{Major: 1, Minor: 14, Patch: 3}) {
		return "1.14.3"
	}
	return Catalog[KindSingBox].MinVersion
}

// SelectEngine chooses the first available engine supporting the whole plan. It
// returns rejection reasons and missing capabilities for clients.
func SelectEngine(p *Plan, available []Availability, preference []Kind) (Selection, error) {
	if p == nil {
		return Selection{}, fmt.Errorf("engine: nil plan")
	}
	if len(p.Outbounds) == 0 {
		return Selection{}, fmt.Errorf("engine: plan has no outbounds")
	}
	byKind := make(map[Kind]Availability, len(available))
	for _, a := range available {
		byKind[a.Kind] = a
	}
	var rejected []string
	for _, kind := range preference {
		avail, ok := byKind[kind]
		if !ok || !avail.Usable {
			why := "not installed"
			if ok && avail.Reason != "" {
				why = avail.Reason
			}
			rejected = append(rejected, string(kind)+": "+why)
			continue
		}
		caps, ok := Catalog[kind]
		if !ok {
			rejected = append(rejected, string(kind)+": no capability matrix")
			continue
		}
		caps = BuildCapabilities(kind, avail.Version, avail.BuildTags)
		floor := caps.MinVersion
		if kind == KindSingBox {
			floor = singBoxFloor(avail.Version)
		}
		if lowest, err := ParseVersion(floor); err == nil && avail.Version.Less(lowest) {
			rejected = append(rejected, fmt.Sprintf("%s: version %s is older than %s", kind, avail.Version, floor))
			continue
		}
		missing := caps.MissingFor(p, avail.Version)
		missing = append(missing, caps.XrayPlaintextMissing(p, avail.Version)...)
		if len(missing) > 0 {
			rejected = append(rejected, fmt.Sprintf("%s: cannot carry %s", kind, strings.Join(missing, ", ")))
			continue
		}
		return Selection{
			Kind:     kind,
			Reason:   fmt.Sprintf("%s carries %d outbounds and %d groups", kind, len(p.Outbounds), len(p.Groups)),
			Rejected: rejected,
		}, nil
	}
	return Selection{Rejected: rejected}, fmt.Errorf("engine: no engine can carry this plan (%s)", strings.Join(rejected, "; "))
}

// Missing returns sorted protocols and features the engine cannot support.
// Empty means the whole plan is supported.
func (c Capabilities) Missing(p *Plan) []string {
	return c.MissingFor(p, Version{})
}

// MissingFor is Missing against one concrete engine build. A zero version
// keeps the legacy contract: the TUN stack option is assumed honored,
// as on sing-box before 1.15 (including the 1.14-based lx. fork).
func (c Capabilities) MissingFor(p *Plan, v Version) []string {
	var missing []string
	if p.Tun.Enabled && p.Tun.Stack != "" {
		// sing-box 1.15 rewrote TUN around its own TCP/IP stack: the
		// stack option is deprecated there (removed in 1.17) and
		// silently ignored, so an explicit stack would do nothing.
		// Less compares only the numeric triple, so fork builds
		// compare by their base version.
		stackIgnored := c.Kind == KindSingBox && !v.Less(Version{Major: 1, Minor: 15})
		if (c.Kind == KindXray && p.Tun.Stack != "gvisor") ||
			(c.Kind == KindSingBox && (stackIgnored || p.Tun.Stack == "mips")) {
			missing = append(missing, "TUN stack "+p.Tun.Stack)
		}
	}
	if c.Kind == KindXray {
		for _, o := range p.Outbounds {
			if o.TLS.Insecure && !o.TLS.Reality && (o.TLS.Enabled || o.Protocol == ProtocolTrojan || o.Protocol == ProtocolHysteria2) {
				missing = append(missing, "TLS verification disabled (removed by Xray)")
				break
			}
			// Xray refuses these at config load: "REALITY only supports
			// RAW, XHTTP and gRPC for now."
			// https://xtls.github.io/en/config/transport.html
			if o.TLS.Reality && (o.Transport.Type == "ws" || o.Transport.Type == "httpupgrade") {
				missing = append(missing, "REALITY over "+o.Transport.Type+" (Xray supports REALITY only over tcp, xhttp and grpc)")
				break
			}
		}
	}
	if c.Kind == KindSingBox {
		for _, o := range p.Outbounds {
			if a := o.Amnezia; a != nil && (a.J1 != "" || a.J2 != "" || a.J3 != "" || a.Itime != 0) {
				missing = append(missing, "AmneziaWG J1/J2/J3/Itime parameters")
				break
			}
		}
	}
	for proto := range p.Protocols() {
		if !c.SupportsProtocol(proto) {
			missing = append(missing, "protocol "+string(proto))
		}
	}
	for f := range p.RequiredFeatures() {
		if !c.Supports(f) {
			missing = append(missing, "feature "+string(f))
		}
	}
	sort.Strings(missing)
	return missing
}
