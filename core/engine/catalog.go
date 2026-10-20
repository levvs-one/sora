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
// Version and BuildTags are PROBED facts (supervise.Prober runs the
// binary and parses its version output and Tags line) — never copied
// from the shipped pins: the AmneziaWG gates in BuildCapabilities key
// off exactly these probed values, so a sing-box build whose probed
// tags lack with_awg is refused an AWG plan however new its version
// looks (CENSOR-P4).
type Availability struct {
	Kind      Kind
	Path      string
	Version   Version
	Usable    bool
	Reason    string
	BuildTags []string
	// Host probe facts (supervise.ProbeHost), stamped by registry
	// discovery — the same host for every engine. HostProbed=false
	// means nobody measured this host; selection then gates only on
	// the binary facts, never on an assumed TUN device or kernel
	// module.
	HostProbed      bool
	TUNDevice       bool
	KernelWireGuard bool
}

// Catalog holds upstream engine capabilities, separate from installed
// Availability. Entries were validated with mihomo v1.19.32 (-t), sing-box
// v1.14.2 (check), sing-box-lx v1.14.3-lx.22 (check and interop traffic),
// and Xray v26.10.17 (run -test and interop traffic).
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
			FeatureXHTTPDownloadSplit: true, FeatureXHTTPXmux: true, FeatureXHTTPPadding: true,
			FeatureAmneziaWG: true, FeaturePrivateControl: true, FeatureChains: true,
			FeatureHy2PortHop: true, FeatureHy2Obfs: true, FeatureDoH3: true, FeatureECH: true,
			// FeatureXHTTPDownloadSplit and FeatureXHTTPXmux are
			// claimed as of the engine bump validation (2026-10-20):
			// the mihomo renderer emits download-settings,
			// reuse-settings and x-padding-bytes in xhttp-opts
			// (PASS3 deep A1), and the pinned 1.19.32 binary accepts
			// the rendered shapes — pinned by
			// mihomo.TestBinaryAcceptsXHTTPDownloadSettings, which
			// runs `mihomo -t` on the real binary. If a future
			// mihomo renames these fields, that test fails before
			// the claims can route plans into a refused config.
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
			FeatureHy2PortHop: true, FeatureHy2Obfs: true, FeatureDoH3: true, FeatureECH: true,
			FeatureRealityKeyShare: true,
			// FeatureH2Headers: the lx http (h2) transport spells a
			// headers map — probed with `sing-box check` on lx.22,
			// which rejects unknown keys (CENSOR-P2 fix).
			FeatureH2Headers: true,
			// Deliberately no FeatureXHTTPDownloadSplit: the lx
			// fork's xhttp transport has no download_settings field
			// at all (probed on lx.22: unknown field, CENSOR-P1).
			// Its xmux and x_padding_bytes claims ride the probed
			// with_xhttp build in BuildCapabilities, exactly like
			// FeatureXHTTP itself — upstream sing-box spells
			// neither, so the static entry claims neither.

		},
	},
	KindXray: {
		Kind: KindXray,
		// Capability floor: the oldest build verified for Hysteria2,
		// XHTTP, and VLESS Encryption rendering. The shipped pin is
		// newer (26.10.17, see packaging/engines/engines.lock);
		// user-supplied builds between the floor and the pin stay
		// usable under the version-aware gates (see
		// xrayPlaintextCutoff).
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
			FeatureXHTTPDownloadSplit: true, FeatureRealityMLDSA65: true,
			FeatureXHTTPXmux: true, FeatureXHTTPPadding: true,
			// FeatureXHTTPXmux and FeatureXHTTPPadding are claimed
			// since CENSOR-P1: the Xray renderer now emits xmux and
			// xPaddingBytes (XHTTP is Xray's own transport; the
			// fields were always in the binary — probed with
			// `xray run -test` on 26.10.17), closing the PASS3
			// deep S1 silent loss where xmux-tuned plans could
			// only route to mihomo.
			// dialerProxy exists since long before the minimum
			// version, so chains need no extra version gate.
			FeatureChains: true,
			// FeatureECH is claimed as of the CENSOR-FP probe
			// (2026-10-20): the renderer now emits echConfigList
			// (the plan's pinned list as one base64 string) and
			// echForceQuery, and a wire capture against the pinned
			// 26.10.17 binary shows the outer SNI becoming the
			// list's public_name — real ECH, not GREASE. The claim
			// is probe-gated like every fingerprint fact: a binary
			// whose probe rejects ECH is refused by ProbeMissing
			// regardless of this expectation. Before the probe, the
			// renderer refused ECH at render time (PASS3 deep S4).
			FeatureECH: true,
			// Deliberately no FeatureRealityKeyShare: Xray has no
			// key-share knob — the chosen parrot decides whether the
			// hybrid group is offered — so a plan pinning the choice
			// reports it missing here instead of losing it silently
			// (S2-C2).
			// Deliberately no FeatureHy2PortHop: Xray's hysteria2
			// outbound cannot hop ports (see FeatureHy2PortHop).
			// Deliberately no FeatureHy2Obfs: Xray's hysteria
			// transport exposes no obfs option (see FeatureHy2Obfs).
			// Deliberately no FeatureDoH3: Xray has no DNS-over-HTTP/3
			// transport (see FeatureDoH3).
		},
	},
}

// xrayPlaintextCutoff is the first Xray release that refuses plaintext
// (no TLS, no REALITY) VLESS/Trojan outbounds at config load instead of
// silently connecting without encryption. The shipped pin (26.10.17, see
// packaging/engines/engines.lock) is past the cutoff — verified on the
// binary: a plaintext VLESS outbound to a public address fails config
// load, so the gate below is live for the shipped build, not just for
// user-supplied ones.
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
// engines and for builds older than the cutoff. Upstream itself allows
// plaintext to private addresses; sora stays stricter and refuses it on
// every address — fail closed, with an actionable message instead of a
// config the engine may or may not accept. Callers pass the probed
// engine version (Availability.Version, Supervisor.Version) — never a
// hardcoded string.
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

// mihomoAWG3Floor is the first mihomo release whose AmneziaWG stack
// implements the 3.x parameters: v1.19.30 added "support AmneziaWG
// v3.0" and "support AmneziaWG v3.1", v1.19.31 fixed RandomPadding
// Addition and DisableCookies for v3 (release notes; the pin's
// adapter/outbound/wireguard.go carries version, header-protection-
// key, the ranged timings, random-trailers and disable-cookies —
// PASS2 deep S1, read from the pinned source).
var mihomoAWG3Floor = Version{Major: 1, Minor: 19, Patch: 30}

// BuildCapabilities keeps upstream and downstream builds distinct. A version
// suffix alone cannot prove that an optional transport was compiled in.
func BuildCapabilities(kind Kind, version Version, tags []string) Capabilities {
	caps := Catalog[kind]
	if kind == KindMihomo && version != (Version{}) && !version.Less(mihomoAWG3Floor) {
		caps.Features = maps.Clone(caps.Features)
		caps.Features[FeatureAmneziaWG3] = true
	}
	if kind == KindSingBox && strings.HasPrefix(version.PreRelease, "lx.") &&
		!version.Less(Version{Major: 1, Minor: 14, Patch: 3}) {
		caps.Features = maps.Clone(caps.Features)
		caps.Features[FeatureXHTTP] = slices.Contains(tags, "with_xhttp")
		// The lx XHTTP transport also spells xmux and
		// x_padding_bytes (probed on lx.22 with `sing-box check`:
		// both accepted, CENSOR-P1); they exist exactly when the
		// with_xhttp build does, so they share its probed claim.
		caps.Features[FeatureXHTTPXmux] = caps.Features[FeatureXHTTP]
		caps.Features[FeatureXHTTPPadding] = caps.Features[FeatureXHTTP]
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
// sing-box-lx v1.14.3-lx.22).
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
		if avail.HostProbed && p.Tun.Enabled && !avail.TUNDevice {
			// Probed host fact, not an assumption: without a TUN
			// device every engine fails the TUN start opaquely, so
			// the plan is refused here with the cause named. WG/AWG
			// plans do NOT gate on KernelWireGuard: both capable
			// engines serve them from userspace (amneziawg-go),
			// which the probed binary facts above already establish.
			rejected = append(rejected, fmt.Sprintf("%s: host has no TUN device (/dev/net/tun, probed)", kind))
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
		if len(p.DNS.NameserverPolicy) > 0 {
			// PASS3 deep A6: sing-box renders the policy as DNS
			// rules and mihomo as nameserver-policy, but the Xray
			// DNS renderer does not read it at all — a split-DNS
			// plan routed here would silently resolve "direct"
			// domains through the tunnel resolver. Report it
			// missing until the policy is mapped onto Xray DNS
			// server objects with `domains` (spec in
			// PASS3-TRANSPORT.md; needs `xray run -test` on the pin).
			missing = append(missing, "DNS nameserver policy (split DNS)")
		}
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
	if c.Kind == KindSingBox || c.Kind == KindMihomo {
		// gRPC authority and multi-mode are Xray-only spellings
		// (verified on the pinned binaries, CENSOR-P2): sing-box's
		// gRPC transport has neither field and rejects unknown keys,
		// mihomo's grpc-opts has neither and silently ignores unknown
		// YAML keys. Without this gate a plan setting them would lose
		// them silently on either engine; their renderers refuse the
		// same fields as a backstop. The gRPC user agent is narrower:
		// mihomo spells it (grpc-user-agent), sing-box does not.
		for _, o := range p.Outbounds {
			t := o.Transport
			if t.Type != "grpc" {
				continue
			}
			if t.GRPCAuthority != "" || t.GRPCMultiMode {
				missing = append(missing, "gRPC authority/multi-mode (Xray-only)")
				break
			}
		}
		if c.Kind == KindSingBox {
			for _, o := range p.Outbounds {
				if o.Transport.Type == "grpc" && o.Transport.GRPCUserAgent != "" {
					missing = append(missing, "gRPC user-agent")
					break
				}
			}
		}
	}
	// Shadowsocks method and plugin support is per-engine measured
	// data (ss_support.go, ss_plugin.go), not a protocol-level claim:
	// a plan whose cipher or plugin this engine's pinned build does
	// not implement must not be routed here — the engine would refuse
	// the config at load or, worse, silently run without the plugin
	// (CENSOR-P4). One entry per fact, first offender only, mirroring
	// the J1/J2/J3 style above.
	for _, o := range p.Outbounds {
		if o.Protocol != ProtocolShadowsocks {
			continue
		}
		if !SupportsShadowsocksMethod(c.Kind, o.Cipher) {
			missing = append(missing, "shadowsocks method "+normalizeShadowsocksMethod(o.Cipher))
			break
		}
	}
	for _, o := range p.Outbounds {
		if o.Protocol != ProtocolShadowsocks {
			continue
		}
		if o.Plugin != "" && !SupportsSSPlugin(c.Kind, o.Plugin) {
			missing = append(missing, "shadowsocks plugin "+o.Plugin)
			break
		}
		if o.Plugin == "" && o.Obfs != "" && !SupportsSSPlugin(c.Kind, "") {
			missing = append(missing, "shadowsocks obfs (simple-obfs)")
			break
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
