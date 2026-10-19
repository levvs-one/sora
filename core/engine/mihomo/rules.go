package mihomo

import (
	"fmt"
	"net/url"
	"runtime"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

// ruleTypes maps contract rule types onto the mihomo rule vocabulary.
var ruleTypes = map[engine.RuleType]string{
	engine.RuleDomain:        "DOMAIN",
	engine.RuleDomainSuffix:  "DOMAIN-SUFFIX",
	engine.RuleDomainKeyword: "DOMAIN-KEYWORD",
	engine.RuleIPCIDR:        "IP-CIDR",
	engine.RuleIPSuffix:      "IP-SUFFIX",
	engine.RuleGeoIP:         "GEOIP",
	engine.RuleGeoSite:       "GEOSITE",
	engine.RuleRuleSet:       "RULE-SET",
	engine.RulePort:          "DST-PORT",
	engine.RuleSrcPort:       "SRC-PORT",
	engine.RuleProcess:       "PROCESS-NAME",
	engine.RuleProtocol:      "NETWORK",
}

// ruleProvider is one remote mihomo rule-provider, rendered under
// rule-providers. The contract rule carries no behavior hint, so the
// behavior stays "classical" (domains and IP ranges) and the URL extension
// decides the wire format.
type ruleProvider struct {
	Type     string `yaml:"type"`
	Behavior string `yaml:"behavior"`
	URL      string `yaml:"url"`
	Path     string `yaml:"path"`
	Interval int    `yaml:"interval"`
	Format   string `yaml:"format,omitempty"`
}

// defaultRuleSetInterval refreshes remote rule sets daily, the cadence most
// community clash rule collections use.
const defaultRuleSetInterval = 86400

// buildRules preserves plan order because mihomo evaluates rules from top to
// bottom. It also returns the remote rule-providers the RULE-SET lines
// reference; callers must render them, otherwise the config fails to load.
func buildRules(rules []engine.Rule, byID map[string]string) ([]string, map[string]ruleProvider, error) {
	providers := map[string]ruleProvider{}
	tags := map[string]string{}
	out := make([]string, 0, len(rules)+1)
	for _, r := range rules {
		if r.Type == engine.RuleMatchAll {
			target, err := ruleTarget(r.Target, byID)
			if err != nil {
				return nil, nil, err
			}
			out = append(out, "MATCH,"+target)
			continue
		}
		kind, ok := ruleTypes[r.Type]
		if !ok {
			return nil, nil, fmt.Errorf("mihomo: rule type %q is not supported", r.Type)
		}
		value := r.Value
		if r.Type == engine.RuleRuleSet {
			tag, err := registerRuleProvider(providers, tags, value)
			if err != nil {
				return nil, nil, err
			}
			value = tag
		}
		if r.Type == engine.RuleIPCIDR && strings.Contains(r.Value, ":") {
			kind = "IP-CIDR6"
		}
		target, err := ruleTarget(r.Target, byID)
		if err != nil {
			return nil, nil, err
		}
		line := kind + "," + value + "," + target
		if r.NoResolve && (r.Type == engine.RuleIPCIDR || r.Type == engine.RuleIPSuffix || r.Type == engine.RuleGeoIP) {
			line += ",no-resolve"
		}
		out = append(out, line)
	}
	if len(out) == 0 || !strings.HasPrefix(out[len(out)-1], "MATCH,") {
		out = append(out, "MATCH,DIRECT")
	}
	return out, providers, nil
}

// registerRuleProvider registers a remote rule-provider for a RuleRuleSet
// value and returns its tag. A value must be the provider's https URL,
// mirroring the sing-box renderer; a bare provider name would reference
// nothing because sora never defines local providers. The wire format is
// validated against the URL path so the provider's declared behavior matches
// content mihomo can actually ingest: a sing-box .srs binary or any other
// undecodable payload is rejected at render time instead of failing inside
// the engine at startup.
func registerRuleProvider(providers map[string]ruleProvider, tags map[string]string, value string) (string, error) {
	u, err := url.Parse(value)
	if err != nil || u.Scheme != "https" || u.Host == "" {
		return "", fmt.Errorf("mihomo: rule set %q must be an https URL", value)
	}
	if tag, ok := tags[value]; ok {
		return tag, nil
	}
	tag := "sora-ruleset-" + strconv.Itoa(len(providers)+1)
	format, ext, err := ruleSetFormat(u)
	if err != nil {
		return "", err
	}
	providers[tag] = ruleProvider{
		Type:     "http",
		Behavior: "classical",
		URL:      value,
		Path:     "./rules/" + tag + ext,
		Interval: defaultRuleSetInterval,
		Format:   format,
	}
	tags[value] = tag
	return tag, nil
}

// ruleSetFormat maps the URL path extension onto mihomo's provider format.
// Binary mrs is the compact wire format; yaml and plain text lists fall back
// to their named formats; extensionless links are plain text. The query
// string is stripped first so versioned download links (ads.mrs?v=2) keep
// their format. A .srs link is sing-box's binary rule-set encoding, which
// mihomo cannot parse; rejecting it here is behavior↔content validation —
// emitting format "text" for it would only fail later inside the engine.
func ruleSetFormat(u *url.URL) (format, ext string, err error) {
	switch path := strings.ToLower(u.Path); {
	case strings.HasSuffix(path, ".mrs"):
		return "mrs", ".mrs", nil
	case strings.HasSuffix(path, ".yaml"), strings.HasSuffix(path, ".yml"):
		return "yaml", ".yaml", nil
	case strings.HasSuffix(path, ".srs"):
		return "", "", fmt.Errorf("mihomo: rule set %q is a sing-box binary rule set (.srs); mihomo reads .mrs", u.String())
	default:
		return "text", ".txt", nil
	}
}

// ruleTarget maps a plan target onto the name mihomo knows.
func ruleTarget(target string, byID map[string]string) (string, error) {
	switch target {
	case "direct":
		return "DIRECT", nil
	case "reject":
		return "REJECT", nil
	case "pass":
		return "ACCEPT", nil
	case "dns":
		return "NO-ADAPT", nil
	}
	name, ok := byID[target]
	if !ok {
		return "", fmt.Errorf("mihomo: rule target %q is not an outbound of this plan", target)
	}
	return name, nil
}

// buildDNS renders resolvers. default-nameserver bootstraps resolver hostnames
// and must never use a proxy.
func buildDNS(d engine.DNS, o engine.Options, byID map[string]string) (*dnsConfig, error) {
	out := &dnsConfig{
		Enable:         true,
		IPv6:           &o.IPv6,
		CacheAlgorithm: "lru",
	}
	switch d.Mode {
	case string(engine.DNSFakeIP):
		out.EnhancedMode = "fake-ip"
		out.FakeIPRange = orDefault(d.FakeIPRange, "198.18.0.1/16")
		// The plan owns the filter list; fall back to the shared
		// best-practice defaults (LAN/mDNS, NTP, OS connectivity checks).
		out.FakeIPFilter = orDefaultList(d.FakeIPFilter, engine.DefaultFakeIPFilter)
		if d.FakeIPTTL > 0 {
			ttl := d.FakeIPTTL
			out.FakeIPTTL = &ttl
		}
	default:
		out.EnhancedMode = "redir-host"
	}
	var direct, remote, system, bootstrap []string
	for _, s := range d.Servers {
		addr := s.Address
		if s.Port != 0 && s.Transport != engine.DNSSystem {
			addr = fmt.Sprintf("%s:%d", s.Address, s.Port)
		}
		switch s.Transport {
		case engine.DNSTCP:
			addr = "tcp://" + addr
		case engine.DNSTLS:
			addr = "tls://" + addr
		case engine.DNSHTTPS:
			addr = "https://" + addr + "/dns-query"
		case engine.DNSH3:
			// DoH3: mihomo upgrades an https:// nameserver to HTTP/3
			// when h3=true is present. It forces H3 with no fallback,
			// which is what an explicit h3:// choice means: a failure
			// surfaces instead of silently downgrading to H2.
			addr = "https://" + addr + "/dns-query?h3=true"
		case engine.DNSQUIC:
			addr = "quic://" + addr
		case engine.DNSSystem:
			system = append(system, "system")
		}
		// Corporate MITM proxies break DoT/DoH/DoQ validation; the plan
		// can opt a server out of certificate verification.
		if s.SkipVerify {
			switch s.Transport {
			case engine.DNSTLS, engine.DNSHTTPS, engine.DNSH3, engine.DNSQUIC:
				sep := "?"
				if strings.Contains(addr, "?") {
					sep = "&"
				}
				addr += sep + "skip-cert-verify=true"
			}
		}
		if s.Dialer == "" || s.Dialer == "direct" {
			bootstrap = append(bootstrap, addr)
		} else {
			name, ok := byID[s.Dialer]
			if !ok {
				return nil, fmt.Errorf("mihomo: DNS resolver %q references unknown outbound %q", s.Tag, s.Dialer)
			}
			addr += "#" + name
		}
		if s.ProxyOnly {
			remote = append(remote, addr)
		} else {
			direct = append(direct, addr)
		}
	}
	out.Nameserver = firstNonEmpty(direct, remote, system, []string{"223.5.5.5"})
	// Map proxy-only resolvers to proxy-server-nameserver for proxy
	// hostname resolution.
	out.ProxyServerNameserver = firstNonEmpty(remote, direct, system, []string{"223.5.5.5"})
	out.DefaultNameserver = firstNonEmpty(system, bootstrap, []string{"223.5.5.5"})
	out.DirectNameserver = firstNonEmpty(system, direct)
	if len(d.NameserverPolicy) > 0 {
		out.NameserverPolicy = d.NameserverPolicy
	}
	if len(d.HijackTun) > 0 {
		out.Listen = strings.Join(d.HijackTun, ",")
	}
	return out, nil
}

// buildTun matches the upstream mihomo MTU default (9000): the TUN device
// never touches a wire MTU limit, so larger packets only cut the packet rate
// through the userspace stack. sing-box defaults to 1500 instead (MSS/PMTUD
// safety); both honor an explicitly pinned MTU, which the validator allows
// up to 9000. Windows loopback transfer tests show substantially
// less packet overhead with MIPS. Keep the existing mixed default on other
// platforms.
func buildTun(t engine.Tun, d engine.DNS) *tunConfig {
	stack := orDefault(t.Stack, "mixed")
	if t.Stack == "" && runtime.GOOS == "windows" {
		stack = "mips"
	}
	out := &tunConfig{
		Name:      "sora-tun",
		Type:      "tun",
		Stack:     stack,
		Device:    t.DeviceName,
		MTU:       orDefaultInt(t.MTU, 9000),
		DNSHijack: orDefaultList(d.HijackTun, []string{"any:53"}),
	}
	auto := t.AutoRoute && runtime.GOOS != "linux"
	out.AutoRoute = &auto
	detect := runtime.GOOS != "linux"
	out.AutoDetectInterface = &detect
	strict := t.StrictRoute
	out.StrictRoute = &strict
	addresses := t.Addresses()
	out.Inet4Address = addresses[:1]
	out.Inet6Address = addresses[1:]
	if runtime.GOOS == "linux" {
		// Its IPv6 bound-interface rule exists even with auto-route=false;
		// keep it in Sora's table so crash cleanup can identify it exactly.
		out.IPRoute2TableIndex = 5340
	}

	out.RouteAddress = t.RouteAddressSets
	out.IncludePackage = t.IncludeApps
	out.ExcludePackage = t.ExcludeApps
	return out
}

// findProcessMode enables process lookup only for process rules; Windows lookup
// is slow and otherwise unnecessary.
func findProcessMode(p *engine.Plan) string {
	if p.Options.FindProcess {
		return "strict"
	}
	for _, r := range p.Rules {
		if r.Type == engine.RuleProcess {
			return "strict"
		}
	}
	return "off"
}

func firstNonEmpty(lists ...[]string) []string {
	for _, l := range lists {
		if len(l) > 0 {
			return l
		}
	}
	return nil
}

func orDefaultList(v, fallback []string) []string {
	if len(v) == 0 {
		return fallback
	}
	return v
}
