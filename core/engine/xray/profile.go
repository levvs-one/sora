package xray

import (
	"encoding/json"
	"fmt"
	"slices"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Session-added tags use the "sora-" prefix to avoid provider tag collisions.
const (
	profileDNS    = "sora-dns"
	profileDirect = "sora-direct"
	profileBlock  = "sora-block"
	profileZapret = "sora-zapret"
)

// profileOwned replaces provider listeners, logs, stats, and controllers with
// session settings. Provider outbounds, balancers, observatory, and routing are
// preserved.
var profileOwned = []string{"inbounds", "log", "api", "stats", "metrics", "policy", "remarks", "meta", "reverse"}

// Drop reverse bridges to prevent provider access to local networks. Remove
// file keys recursively to prevent reads or writes with service privileges.
var profileFileKeys = []string{"masterKeyLog", "certificateFile", "keyFile"}

// stripFiles removes the keys of profileFileKeys from a decoded JSON value.
func stripFiles(v any) {
	switch t := v.(type) {
	case obj:
		stripFiles(map[string]any(t))
	case map[string]any:
		for key, child := range t {
			if slices.ContainsFunc(profileFileKeys, func(name string) bool { return strings.EqualFold(key, name) }) {
				delete(t, key)
				continue
			}
			stripFiles(child)
		}
	case []any:
		for _, child := range t {
			stripFiles(child)
		}
	}
}

// renderProfile preserves provider routing after session DNS, ad-block, and
// preset rules. Unmatched traffic uses the provider's first outbound.
func renderProfile(p *engine.Plan, rt supervise.Runtime) ([]byte, error) {
	profile := p.Outbounds[slices.IndexFunc(p.Outbounds, func(o engine.Outbound) bool { return o.Protocol == engine.ProtocolXrayProfile })]
	var cfg obj
	if err := json.Unmarshal(profile.Profile, &cfg); err != nil {
		return nil, fmt.Errorf("xray: profile %s: %w", profile.ID, err)
	}
	// Match the engine's JSON field folding, including Unicode equivalents.
	for key := range cfg {
		if slices.ContainsFunc(profileOwned, func(name string) bool { return strings.EqualFold(key, name) }) {
			delete(cfg, key)
		}
	}
	stripFiles(cfg)
	outbounds, _ := cfg["outbounds"].([]any)
	free := freedomTags(outbounds)
	cfg["outbounds"] = append(outbounds,
		obj{"tag": profileDNS, "protocol": "dns"},
		obj{"tag": profileDirect, "protocol": "freedom"},
		obj{"tag": profileBlock, "protocol": "blackhole"},
	)
	zapret := slices.IndexFunc(p.Outbounds, func(o engine.Outbound) bool { return o.ID == engine.ZapretDirect })
	if zapret >= 0 {
		proxy := p.Outbounds[zapret]
		cfg["outbounds"] = append(cfg["outbounds"].([]any), obj{"tag": profileZapret, "protocol": "socks",
			"settings": obj{"servers": []obj{{"address": proxy.Server, "port": proxy.Port}}}})
	}

	var ours []any
	if p.Tun.Enabled {
		ours = append(ours, obj{"inboundTag": []string{tagTun}, "network": "tcp,udp", "port": "53", "outboundTag": profileDNS})
	}
	for _, rule := range p.Rules {
		var target string
		switch rule.Target {
		case "direct":
			target = profileDirect
		case "reject", "block":
			target = profileBlock
		case engine.ZapretDirect:
			target = profileZapret
		default:
			// Profile-target rules defer to provider routing,
			// including catch-all rules.
			continue
		}
		m, err := match(rule)
		if err != nil {
			return nil, err
		}
		m["outboundTag"] = target
		ours = append(ours, m)
	}
	routing, _ := cfg["routing"].(map[string]any)
	if routing == nil {
		routing = obj{}
	}
	provider, _ := routing["rules"].([]any)
	if zapret >= 0 {
		reshapeDirect(provider, free)
	}
	routing["rules"] = append(ours, provider...)
	cfg["routing"] = routing

	if p.DNS.Enabled {
		r := renderer{plan: p}
		dns, err := r.dns()
		if err != nil {
			return nil, err
		}
		cfg["dns"] = dns
	}
	cfg["inbounds"] = sessionInbounds(p, rt)
	frame(cfg, p, rt)
	raw, err := json.Marshal(cfg)
	if err != nil {
		return nil, err
	}
	if err := validateProfileAssets(raw); err != nil {
		return nil, err
	}
	return raw, nil
}

// freedomTags lists the provider's outbounds that leave the machine directly.
func freedomTags(outbounds []any) []string {
	var tags []string
	for _, item := range outbounds {
		o, _ := item.(map[string]any)
		if protocol, _ := o["protocol"].(string); strings.EqualFold(protocol, "freedom") {
			if tag, _ := o["tag"].(string); tag != "" {
				tags = append(tags, tag)
			}
		}
	}
	return tags
}

// reshapeDirect sends the provider's own direct rules through the DPI proxy.
func reshapeDirect(rules []any, free []string) {
	for _, item := range rules {
		rule, _ := item.(map[string]any)
		if tag, _ := rule["outboundTag"].(string); slices.Contains(free, tag) {
			rule["outboundTag"] = profileZapret
		}
	}
}

// probeProfile prefixes tags and references so profiles share one probe
// configuration. Each local port measures its profile's first, default
// outbound.
func probeProfile(o engine.Outbound, index int) (outbounds []obj, first string, err error) {
	var cfg struct {
		Outbounds []obj `json:"outbounds"`
	}
	if err := json.Unmarshal(o.Profile, &cfg); err != nil || len(cfg.Outbounds) == 0 {
		return nil, "", fmt.Errorf("xray: profile %s has no outbounds", o.ID)
	}
	for _, ob := range cfg.Outbounds {
		stripFiles(ob)
	}
	prefix := "p" + strconv.Itoa(index+1) + "-"
	rename := func(tag string) string { return prefix + tag }
	for i, ob := range cfg.Outbounds {
		tag, _ := ob["tag"].(string)
		if tag == "" {
			tag = "untagged-" + strconv.Itoa(i)
		}
		ob["tag"] = rename(tag)
		if ss, ok := ob["streamSettings"].(map[string]any); ok {
			if so, ok := ss["sockopt"].(map[string]any); ok {
				if dialer, ok := so["dialerProxy"].(string); ok && dialer != "" {
					so["dialerProxy"] = rename(dialer)
				}
			}
		}
		if px, ok := ob["proxySettings"].(map[string]any); ok {
			if tag, ok := px["tag"].(string); ok && tag != "" {
				px["tag"] = rename(tag)
			}
		}
		outbounds = append(outbounds, ob)
	}
	first, _ = cfg.Outbounds[0]["tag"].(string)
	return outbounds, first, nil
}
