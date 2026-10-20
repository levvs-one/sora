// Package engine defines the plan-based boundary for mihomo, sing-box, and
// Xray. Callers avoid engine-specific configuration and select engines by
// advertised protocols and features.
package engine

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"
)

// Kind identifies a forwarding engine implementation.
type Kind string

// The engines Sora can run.
const (
	KindMihomo  Kind = "mihomo"
	KindSingBox Kind = "sing-box"
	KindXray    Kind = "xray"
)

// Feature is a capability the control plane may require from an engine.
type Feature string

// Features are provided according to the capability matrix in catalog.go.
const (
	FeatureTun            Feature = "tun"
	FeatureFakeIP         Feature = "fake-ip"
	FeatureRuleSets       Feature = "rule-sets"
	FeatureProxyProviders Feature = "proxy-providers"
	FeatureURLTest        Feature = "url-test"
	FeatureLatencyTest    Feature = "latency-test"
	FeatureHotApply       Feature = "hot-apply"
	FeatureGeoData        Feature = "geodata"
	FeaturePerAppRouting  Feature = "per-app-routing"
	FeatureFallbackGroup  Feature = "fallback-group"
	FeatureLoadBalance    Feature = "load-balance"
	FeatureTLSFragment    Feature = "tls-fragment"
	FeatureXHTTP          Feature = "xhttp"
	// FeatureXHTTPDownloadSplit marks engines that can split the XHTTP
	// downlink onto a separate server. Xray (downloadSettings) and
	// mihomo (download-settings, PASS3 deep A1) claim it; mihomo's
	// claim is verified with `mihomo -t` on the pinned binary
	// (mihomo.TestBinaryAcceptsXHTTPDownloadSettings). sing-box
	// (including the lx fork) has no such option: routing a split plan
	// to it would silently send downloads over the uplink server.
	FeatureXHTTPDownloadSplit Feature = "xhttp-download-split"
	// FeatureXHTTPXmux marks engines that honour XHTTP connection-reuse
	// tuning. All three engines claim it since CENSOR-P1: mihomo
	// renders reuse-settings, Xray renders xmux, sing-box-lx renders
	// xmux — each claim verified against the pinned binary (config
	// check plus, for mihomo, the PASS3 deep A1 render). Before
	// CENSOR-P1 only mihomo rendered the tuning and a plan setting it
	// reported the feature missing on the other two instead of being
	// routed to a silent loss (PASS3 deep S1). A claim belongs in a
	// catalog entry only together with a renderer that emits the
	// tuning AND a binary check.
	FeatureXHTTPXmux Feature = "xhttp-xmux"
	// FeatureXHTTPPadding marks engines that honour the XHTTP
	// padding range (Transport.XPaddingBytes). It is a separate
	// feature from FeatureXHTTPXmux because the fields are
	// independent plan data: a padding-only plan must not demand
	// xmux support, and an xmux-only plan must not demand padding.
	// All three engines claim it since CENSOR-P1 (mihomo
	// x-padding-bytes, Xray xPaddingBytes, sing-box-lx
	// x_padding_bytes; binary-verified on the pins). Before the
	// split, padding rode the xmux gate (S2 seams audit).
	FeatureXHTTPPadding Feature = "xhttp-padding"
	FeatureVLESSEncrypt Feature = "vless-encryption"
	FeatureAmneziaWG    Feature = "amneziawg"
	// FeatureAmneziaWG3 marks engines whose AmneziaWG stack implements
	// the 3.x parameters (header_protection_key, content padding,
	// trailers, ranged timings). sing-box-lx with_awg implements them;
	// mihomo implements them since 1.19.30 (the pin is 1.19.32), so
	// its claim is version-gated in BuildCapabilities — a build older
	// than 1.19.30, or one whose version is unknown, must never be
	// routed a 3.x plan: the parameters would be silently dropped
	// while the UI promises obfuscation (PASS2 deep S1, PASS3).
	FeatureAmneziaWG3 Feature = "amneziawg3"
	// FeatureAmneziaMasquerade marks engines that generate the I1 decoy
	// from the id/ip/ib masquerade sugar (sing-box-lx with_awg). Other
	// engines would silently send no decoy at all.
	FeatureAmneziaMasquerade Feature = "amneziawg-masquerade"
	FeaturePrivateControl    Feature = "private-control"
	// FeatureChains marks engines able to dial one outbound through another
	// (sing-box dialer_proxy, mihomo dialer-proxy, Xray dialerProxy).
	FeatureChains Feature = "chains"
	// FeatureHy2PortHop marks engines whose Hysteria2 outbound supports
	// port hopping (sing-box server_ports, mihomo ports). Xray's hysteria2
	// outbound has no port-hopping support, so a hopping plan must never
	// be routed to it: hopping rendered nowhere would silently pin the
	// client to one port.
	FeatureHy2PortHop Feature = "hy2-port-hop"
	// FeatureDoH3 marks engines whose DNS stack can speak DNS over
	// HTTP/3 (sing-box h3:// servers, mihomo ?h3=true). Xray has no
	// DoH3 transport, so a plan naming an h3:// resolver must never be
	// routed to it: the render would fail the whole session instead.
	FeatureDoH3 Feature = "doh3"
	// FeatureECH marks engines whose renderer actually emits Encrypted
	// Client Hello for an outbound that enables it: sing-box (ech
	// block with pinned config and query_server_name), mihomo
	// (ech-opts with pinned config and query-server-name) and Xray
	// (echConfigList + echForceQuery; the pinned list's format and
	// its wire effect — outer SNI becomes the list's public_name —
	// were verified by capture against the pinned 26.10.17 binary,
	// CENSOR-FP). An engine whose runtime probe rejects ECH is gated
	// by ProbeMissing regardless of this claim.
	FeatureECH Feature = "ech"
	// FeatureRealityMLDSA65 marks engines that verify the REALITY
	// server's ML-DSA-65 signature (realitySettings.mldsa65Verify).
	// Only Xray spells it: probed on the pinned binaries (2026-10-20),
	// sing-box 1.14.3-lx.22 rejects the field as unknown and mihomo
	// 1.19.32 silently ignores unknown reality-opts keys, so routing a
	// plan that pins the key to either would drop a server-
	// authentication check without a trace. Every Xray build that
	// passes the catalog floor (26.3.27) carries the field — the
	// post-quantum REALITY line landed in the 25.9 series — and the
	// shipped pin is verified by config test and traffic
	// (xray.TestBinaryAcceptsMLDSA65Verify,
	// interop.TestRealityMLDSA65ThroughXray).
	FeatureRealityMLDSA65 Feature = "reality-mldsa65"
	// FeatureRealityKeyShare is declared in probecaps.go with the
	// probed-capability records: it marks engines whose renderer
	// spells the REALITY key-share choice and whose binary honours
	// it on the wire (sing-box-lx and mihomo; Xray has no knob).
)

// Capabilities describes the protocols and features supported by an engine
// build.
type Capabilities struct {
	Kind       Kind
	MinVersion string
	Protocols  map[Protocol]bool
	Features   map[Feature]bool
}

// SupportsProtocol reports whether the engine can build an outbound for p.
func (c Capabilities) SupportsProtocol(p Protocol) bool { return c.Protocols[p] }

// Supports reports whether the engine provides f.
func (c Capabilities) Supports(f Feature) bool { return c.Features[f] }

// State describes a managed engine instance.
type State string

// Stopped and Failed are terminal until the engine is started again.
const (
	StateIdle       State = "idle"
	StateStarting   State = "starting"
	StateRunning    State = "running"
	StateApplying   State = "applying"
	StateRecovering State = "recovering"
	StateStopping   State = "stopping"
	StateStopped    State = "stopped"
	StateFailed     State = "failed"
)

// Version is a parsed engine version.
type Version struct {
	Raw        string
	Major      int
	Minor      int
	Patch      int
	PreRelease string
}

// Less reports whether v sorts before other.
func (v Version) Less(other Version) bool {
	if v.Major != other.Major {
		return v.Major < other.Major
	}
	if v.Minor != other.Minor {
		return v.Minor < other.Minor
	}
	return v.Patch < other.Patch
}

func (v Version) String() string { return v.Raw }

// ParseVersion accepts "1.19.32", "v1.19.32" and "v1.19.32-beta.3".
func ParseVersion(raw string) (Version, error) {
	s := strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(raw), "v"))
	if s == "" {
		return Version{}, fmt.Errorf("engine: empty version")
	}
	pre := ""
	if i := strings.IndexAny(s, "-+"); i >= 0 {
		pre, s = s[i+1:], s[:i]
	}
	parts := strings.Split(s, ".")
	if len(parts) != 3 {
		return Version{}, fmt.Errorf("engine: malformed version %q", raw)
	}
	nums := make([]int, 3)
	for i, p := range parts {
		n, err := strconv.Atoi(p)
		if err != nil || n < 0 {
			return Version{}, fmt.Errorf("engine: malformed version %q", raw)
		}
		nums[i] = n
	}
	return Version{
		Raw: strings.TrimSpace(raw), Major: nums[0], Minor: nums[1], Patch: nums[2], PreRelease: pre,
	}, nil
}

// Engine manages a forwarding process. Apply is idempotent and converges to the
// requested plan while minimizing traffic interruptions.
type Engine interface {
	Kind() Kind
	Capabilities() Capabilities
	State() State
	Version() Version

	// Validate reports every problem that would stop this plan from
	// running.
	Validate(ctx context.Context, p *Plan) error
	// Apply starts the engine or moves a running engine to the given plan.
	Apply(ctx context.Context, p *Plan) error
	// Stop shuts the engine down and removes it from the system.
	Stop(ctx context.Context) error
	// Close releases all resources. Close is safe to call after Stop.
	Close() error

	// Groups returns the selectable groups with their live state.
	Groups(ctx context.Context) ([]GroupStatus, error)
	// Select pins target inside a selectable group.
	Select(ctx context.Context, group, target string) error
	// Delay measures one proxy through the engine.
	Delay(ctx context.Context, name, url string, timeout time.Duration) (time.Duration, error)
	// Counters returns traffic counters of the running session.
	Counters(ctx context.Context) (Counters, error)

	// Events returns the engine event bus.
	Events() *EventBus
}
