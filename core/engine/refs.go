package engine

import (
	"errors"
	"fmt"
	"net"
	"slices"
	"strconv"
	"strings"
)

// OutboundByID returns the outbound with the given id.
func (p *Plan) OutboundByID(id string) (Outbound, bool) {
	for _, o := range p.Outbounds {
		if o.ID == id {
			return o, true
		}
	}
	return Outbound{}, false
}

// Protocols returns the set of protocols the plan needs from an engine.
func (p *Plan) Protocols() map[Protocol]bool {
	out := make(map[Protocol]bool, len(p.Outbounds))
	for _, o := range p.Outbounds {
		out[o.Protocol] = true
	}
	return out
}

// RequiredFeatures returns the features the plan asks an engine to provide.
func (p *Plan) RequiredFeatures() map[Feature]bool {
	out := map[Feature]bool{}
	if p.Tun.Enabled {
		out[FeatureTun] = true
	}
	if p.DNS.Mode == string(DNSFakeIP) {
		out[FeatureFakeIP] = true
	}
	for _, s := range p.DNS.Servers {
		if s.Transport == DNSH3 {
			// An explicit h3:// resolver needs an engine with a DoH3
			// transport; without the gate Xray would be selected and
			// fail the render.
			out[FeatureDoH3] = true
			break
		}
	}
	for _, r := range p.Rules {
		if r.Type == RuleRuleSet {
			out[FeatureRuleSets] = true
		}
	}
	for _, g := range p.Groups {
		if g.Provider != "" {
			out[FeatureProxyProviders] = true
		}
		switch g.Type {
		case GroupURLTest:
			out[FeatureURLTest] = true
		case GroupFallback:
			out[FeatureFallbackGroup] = true
		case GroupLoadBalance:
			out[FeatureLoadBalance] = true
		}
	}
	for _, o := range p.Outbounds {
		if o.Transport.Type == "xhttp" {
			out[FeatureXHTTP] = true
			if o.Transport.DownloadAddress != "" {
				out[FeatureXHTTPDownloadSplit] = true
			}
			if o.Transport.XmuxMaxConcurrency > 0 || o.Transport.XmuxMaxConnections > 0 ||
				o.Transport.XmuxMaxReuseTimes > 0 || o.Transport.XmuxMaxRequestTimes > 0 ||
				o.Transport.XPaddingBytes != "" {
				// XPaddingBytes rides the same gate as the xmux
				// fields (S2 seams audit): only the mihomo renderer
				// emits x-padding-bytes, while the Xray and sing-box
				// renderers drop it at render time. A padding-only
				// plan that required nothing would route to those
				// engines and silently lose its padding — the exact
				// silent loss the xmux gate exists to prevent.
				out[FeatureXHTTPXmux] = true
			}
		}
		if o.Encryption != "" && o.Encryption != "none" {
			out[FeatureVLESSEncrypt] = true
		}
		if o.TLS.ECH.Enabled {
			// An engine that does not render ECH would send the SNI
			// in the clear while the plan promises it hidden: route
			// ECH plans only to engines that emit it (PASS3 deep S4).
			out[FeatureECH] = true
		}
		if o.Amnezia != nil {
			out[FeatureAmneziaWG] = true
			if o.Amnezia.UsesAWG31() {
				// Without the gate a 3.x plan could land on an engine
				// build without the 3.x stack (upstream sing-box,
				// mihomo < 1.19.30) and lose its obfuscation silently.
				out[FeatureAmneziaWG3] = true
			}
			if o.Amnezia.UsesMasquerade() {
				out[FeatureAmneziaMasquerade] = true
			}
		}
		if o.Via != "" {
			out[FeatureChains] = true
		}
		if o.Protocol == ProtocolHysteria2 && o.HopPorts != "" {
			// Xray's hysteria2 outbound cannot hop ports; without the
			// feature gate a hopping plan would silently collapse to a
			// single port on Xray.
			out[FeatureHy2PortHop] = true
		}
	}
	if p.Options.Fragment.Enabled {
		out[FeatureTLSFragment] = true
	}
	if p.PrivateControl {
		out[FeaturePrivateControl] = true
	}
	if len(p.Tun.IncludeApps) > 0 || len(p.Tun.ExcludeApps) > 0 {
		out[FeaturePerAppRouting] = true
	}
	return out
}

// IsBuiltInTarget reports whether a target is provided by the engine
// instead of the plan: it names no outbound and no group, so no plan-defined
// id may shadow it. This is the single source of truth for built-in rule
// targets; control and the engine bridges must use it rather than their own
// copies (A20-18: control/plan.go kept a divergent set and rejected plans
// the engine accepted, while accepting a target no engine could render).
//
// The canonical set is {direct, reject, pass, dns}:
//   - direct: every engine sends the traffic outside the tunnel;
//   - reject: every engine refuses the connection;
//   - dns: DNS-bound traffic — mihomo renders NO-ADAPT, sing-box
//     hijack-dns, xray routes to its DNS outbound;
//   - pass: mihomo-only. Mihomo continues rule matching with the remaining
//     rules (rendered as ACCEPT); sing-box and the xray renderer do not
//     implement it and fail at render time, so a plan targeting pass only
//     runs on mihomo. The xraytun bridge preserves pass rules for the
//     mihomo packet-engine config.
//
// "block" is deliberately NOT a built-in target: no engine renderer maps it
// from a plan rule (xray's profile.go maps "block" only while augmenting a
// provider profile, never from a plan). Accepting it at the control boundary
// only deferred the failure to render time; plans naming it now fail fast
// at validation.
func IsBuiltInTarget(t string) bool {
	switch t {
	case "direct", "reject", "pass", "dns":
		return true
	}
	return false
}

func (g Group) validate() error {
	var errs []error
	errs = append(errs, validateDisplayName("group", g.Name))
	switch g.Type {
	case GroupSelect, GroupURLTest, GroupFallback, GroupLoadBalance:
	default:
		errs = append(errs, fmt.Errorf("group %q: unknown type %q", g.Name, g.Type))
	}
	if len(g.Outbounds) == 0 {
		errs = append(errs, fmt.Errorf("group %q: no members", g.Name))
	}
	if g.Selected != "" {
		if g.Type != GroupSelect {
			errs = append(errs, fmt.Errorf("group %q: a starting member is only meaningful for a select group", g.Name))
		} else if !slices.Contains(g.Outbounds, g.Selected) {
			errs = append(errs, fmt.Errorf("group %q: selected member %q is not one of its members", g.Name, g.Selected))
		}
	}
	if g.Interval < 0 || g.Interval > 86400 {
		errs = append(errs, fmt.Errorf("group %q: interval must be between 0 and 86400 seconds", g.Name))
	}
	return errors.Join(errs...)
}

// needsProbe reports whether the group measures latency by itself.
func (g Group) needsProbe() bool {
	return g.Type == GroupURLTest || g.Type == GroupFallback || g.Type == GroupLoadBalance
}

func (r Rule) validate() error {
	var errs []error
	switch r.Type {
	case RuleDomain, RuleDomainSuffix, RuleDomainKeyword, RuleIPCIDR, RuleIPSuffix,
		RuleGeoIP, RuleGeoSite, RuleRuleSet, RulePort, RuleSrcPort, RuleProcess,
		RuleProtocol, RuleMatchAll:
	default:
		errs = append(errs, fmt.Errorf("rule: unknown type %q", r.Type))
	}
	if r.Type != RuleMatchAll && strings.TrimSpace(r.Value) == "" {
		errs = append(errs, fmt.Errorf("rule %s: empty value", r.Type))
	}
	if strings.ContainsAny(r.Value, "\r\n\t") {
		errs = append(errs, fmt.Errorf("rule %s: value contains control characters", r.Type))
	}
	switch r.Type {
	case RuleIPCIDR:
		if _, _, err := net.ParseCIDR(r.Value); err != nil {
			errs = append(errs, fmt.Errorf("rule ip-cidr: %q is not a CIDR", r.Value))
		}
	case RulePort, RuleSrcPort:
		if _, err := strconv.Atoi(r.Value); err != nil {
			errs = append(errs, fmt.Errorf("rule %s: %q is not a port", r.Type, r.Value))
		}
	}
	return errors.Join(errs...)
}
