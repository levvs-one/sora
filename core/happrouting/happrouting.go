// Package happrouting receives provider routing profiles in the Happ
// format: the JSON document the Remnawave panel's HAPP Routing Builder
// produces, transported either as the panel's happRouting subscription
// setting (a base64 string, or the whole happ:// link pasted into the
// field) or as a standalone happ://routing/add/{base64} deep link.
//
// The schema is reconstructed from the panel's open sources
// (remnawave/frontend, src/widgets/dashboard/utils/happ-routing-builder/
// happ-routing-builder.widget.tsx, HappRoutingData, lines 34-63 of the
// indexed revision; export pipeline lines 100-167 and 253-279;
// subscription settings in subscription-tabs.widget.tsx lines 322-412):
//
//	Name            string   profile name
//	GlobalProxy     bool     true: proxy everything except the rules;
//	                         false: direct everything except the rules
//	FakeDNS         bool     Happ-side fake-IP DNS
//	UseChunkFiles   bool     geo data loading optimisation (Happ-internal)
//	RemoteDNSType   string   e.g. "DoH"; RemoteDNSIP (also spelled
//	RemoteDNSIp)    string   resolver address for proxied traffic
//	DomesticDNSType string   e.g. "DoU" (DNS over UDP); DomesticDNSIP /
//	DomesticDNSIp   string   resolver address for direct traffic
//	Geoipurl        string   geoip data URL; Geositeurl likewise
//	LastUpdated     string   builder timestamp (string or number)
//	DirectSites, DirectIp, ProxySites, ProxyIp, BlockSites, BlockIp
//	                []string routing lists; site entries may carry
//	                         geosite:/geoip: prefixes
//	DnsHosts        any      static host overrides (shape not pinned
//	                         down by the sources; kept raw, never applied)
//	DomainStrategy  string   Xray domain strategy
//
// Encoding: the builder JSON-encodes the document (formatJsonData) and
// base64-encodes it for the happRouting field and for
// happ://routing/add/{base64} links / QR codes. The sources do not pin
// the base64 alphabet or padding (the builder uses the browser's
// standard encoder, i.e. standard alphabet with padding), so decoding
// accepts the standard and URL-safe alphabets, padded or raw, while
// encoding always emits the standard padded form.
//
// How the panel hands happRouting to a client that fetches the
// subscription is NOT established by the open backend sources found
// during reconstruction; core/subscription therefore extracts it
// opportunistically from the metadata slots panels use for the sibling
// happAnnounce setting (response header / leading body line) and this
// package stays transport-agnostic.
package happrouting

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/netip"
	"net/url"
	"strings"
)

// Limits bound a provider-controlled document before it can reach the
// plan builder. MaxRules mirrors engine.MaxRules: a converted profile
// must never exceed what a session plan accepts.
const (
	MaxPayloadBytes = 1 << 20
	MaxRules        = 10000
	maxEntryBytes   = 512
)

// ErrInvalid marks a payload that is not a Happ routing document:
// bad base64, bad JSON, or a JSON value that is not the routing object.
// Callers fail the import honestly instead of applying a partial profile.
var ErrInvalid = errors.New("happrouting: invalid routing payload")

// Profile is one parsed Happ routing document. Pointer booleans keep
// "absent" distinct from an explicit false: GlobalProxy=false is a
// routing decision, a missing GlobalProxy is no decision at all.
type Profile struct {
	Name            string
	GlobalProxy     *bool
	FakeDNS         *bool
	UseChunkFiles   *bool
	RemoteDNSType   string
	RemoteDNSIP     string
	DomesticDNSType string
	DomesticDNSIP   string
	GeoIPURL        string
	GeoSiteURL      string
	LastUpdated     string
	DirectSites     []string
	DirectIP        []string
	ProxySites      []string
	ProxyIP         []string
	BlockSites      []string
	BlockIP         []string
	// DNSHosts is the raw DnsHosts value, preserved for the report.
	// Its exact shape is not established by the open sources, so it is
	// never interpreted.
	DNSHosts json.RawMessage
	// DomainStrategy is kept verbatim (an Xray domainStrategy value
	// such as "IPIfNonMatch"); sora's plan has no equivalent knob.
	DomainStrategy string
}

// DecodePayload accepts every transport form of a routing profile: a
// full happ://routing/add/{base64} link (percent-encoding tolerated),
// the bare base64 payload from the panel's happRouting field, or the
// raw JSON document. Anything else is ErrInvalid.
func DecodePayload(payload string) (*Profile, error) {
	text := strings.TrimSpace(payload)
	if text == "" {
		return nil, fmt.Errorf("%w: payload is empty", ErrInvalid)
	}
	if len(text) > 2*MaxPayloadBytes {
		return nil, fmt.Errorf("%w: payload is larger than %d bytes", ErrInvalid, MaxPayloadBytes)
	}
	if link, ok := strings.CutPrefix(text, "happ://"); ok {
		rest, found := strings.CutPrefix(link, "routing/add/")
		if !found {
			return nil, fmt.Errorf("%w: not a routing link", ErrInvalid)
		}
		if unescaped, err := url.PathUnescape(rest); err == nil {
			rest = unescaped
		}
		text = strings.TrimSpace(rest)
	}
	if strings.HasPrefix(text, "{") {
		return ParseJSON([]byte(text))
	}
	raw, err := decodeBase64(text)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalid, err)
	}
	return ParseJSON(raw)
}

// decodeBase64 tries the standard and URL-safe alphabets, padded and
// raw: the builder emits the standard padded form, but a payload that
// travelled inside a URL may have been rewritten either way.
func decodeBase64(text string) ([]byte, error) {
	clean := strings.Map(func(r rune) rune {
		if r == ' ' || r == '\t' || r == '\r' || r == '\n' {
			return -1
		}
		return r
	}, text)
	for _, enc := range []*base64.Encoding{
		base64.StdEncoding, base64.RawStdEncoding,
		base64.URLEncoding, base64.RawURLEncoding,
	} {
		if raw, err := enc.DecodeString(clean); err == nil {
			if len(raw) > MaxPayloadBytes {
				return nil, fmt.Errorf("decoded payload is larger than %d bytes", MaxPayloadBytes)
			}
			return raw, nil
		}
	}
	return nil, errors.New("payload is not base64")
}

// ParseJSON parses the routing document itself. Keys match
// case-insensitively (the builder itself tolerates the RemoteDNSIP /
// RemoteDNSIp spelling drift between Happ versions), unknown keys are
// ignored, and a known key with an unusable shape fails the document
// instead of being silently dropped.
func ParseJSON(raw []byte) (*Profile, error) {
	if len(raw) > MaxPayloadBytes {
		return nil, fmt.Errorf("%w: document is larger than %d bytes", ErrInvalid, MaxPayloadBytes)
	}
	var doc map[string]json.RawMessage
	if err := json.Unmarshal(raw, &doc); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalid, err)
	}
	if doc == nil {
		return nil, fmt.Errorf("%w: document is not a JSON object", ErrInvalid)
	}
	// Index keys once, lower-cased: every lookup below is then a map hit
	// instead of a scan, and the IP/Ip spelling variants collapse.
	lower := make(map[string]json.RawMessage, len(doc))
	for key, value := range doc {
		lower[strings.ToLower(key)] = value
	}
	get := func(names ...string) (json.RawMessage, bool) {
		for _, name := range names {
			if value, ok := lower[name]; ok {
				return value, true
			}
		}
		return nil, false
	}
	p := &Profile{}
	var err error
	if p.Name, err = stringField(get, "name"); err != nil {
		return nil, err
	}
	if p.GlobalProxy, err = boolField(get, "globalproxy"); err != nil {
		return nil, err
	}
	if p.FakeDNS, err = boolField(get, "fakedns"); err != nil {
		return nil, err
	}
	if p.UseChunkFiles, err = boolField(get, "usechunkfiles"); err != nil {
		return nil, err
	}
	if p.RemoteDNSType, err = stringField(get, "remotednstype"); err != nil {
		return nil, err
	}
	if p.RemoteDNSIP, err = stringField(get, "remotednsip"); err != nil {
		return nil, err
	}
	if p.DomesticDNSType, err = stringField(get, "domesticdnstype"); err != nil {
		return nil, err
	}
	if p.DomesticDNSIP, err = stringField(get, "domesticdnsip"); err != nil {
		return nil, err
	}
	if p.GeoIPURL, err = stringField(get, "geoipurl"); err != nil {
		return nil, err
	}
	if p.GeoSiteURL, err = stringField(get, "geositeurl"); err != nil {
		return nil, err
	}
	if p.DomainStrategy, err = stringField(get, "domainstrategy"); err != nil {
		return nil, err
	}
	if raw, ok := get("lastupdated"); ok {
		// The builder writes a timestamp; accept a JSON string or
		// number verbatim, anything else is not a timestamp.
		var s string
		if err := json.Unmarshal(raw, &s); err == nil {
			p.LastUpdated = s
		} else {
			var n json.Number
			if err := json.Unmarshal(raw, &n); err != nil {
				return nil, fmt.Errorf("%w: LastUpdated is neither a string nor a number", ErrInvalid)
			}
			p.LastUpdated = n.String()
		}
	}
	lists := []struct {
		key string
		dst *[]string
	}{
		{"directsites", &p.DirectSites}, {"directip", &p.DirectIP},
		{"proxysites", &p.ProxySites}, {"proxyip", &p.ProxyIP},
		{"blocksites", &p.BlockSites}, {"blockip", &p.BlockIP},
	}
	for _, list := range lists {
		if *list.dst, err = listField(get, list.key); err != nil {
			return nil, err
		}
	}
	if raw, ok := get("dnshosts"); ok {
		p.DNSHosts = raw
	}
	return p, nil
}

func stringField(get func(...string) (json.RawMessage, bool), names ...string) (string, error) {
	raw, ok := get(names...)
	if !ok {
		return "", nil
	}
	var s string
	if err := json.Unmarshal(raw, &s); err != nil {
		return "", fmt.Errorf("%w: %s is not a string", ErrInvalid, names[0])
	}
	return strings.TrimSpace(s), nil
}

func boolField(get func(...string) (json.RawMessage, bool), names ...string) (*bool, error) {
	raw, ok := get(names...)
	if !ok {
		return nil, nil
	}
	var b bool
	if err := json.Unmarshal(raw, &b); err == nil {
		return &b, nil
	}
	// Tolerate the string/number spellings form builders emit.
	var s string
	if err := json.Unmarshal(raw, &s); err == nil {
		switch strings.ToLower(strings.TrimSpace(s)) {
		case "true", "1":
			b = true
			return &b, nil
		case "false", "0", "":
			b = false
			return &b, nil
		}
	}
	var n float64
	if err := json.Unmarshal(raw, &n); err == nil {
		b = n != 0
		return &b, nil
	}
	return nil, fmt.Errorf("%w: %s is not a boolean", ErrInvalid, names[0])
}

// listField reads one routing list. The builder emits string arrays
// (its form splits multi-line text into arrays); a single string is
// accepted too, split on newlines and commas the way the form does.
func listField(get func(...string) (json.RawMessage, bool), names ...string) ([]string, error) {
	raw, ok := get(names...)
	if !ok {
		return nil, nil
	}
	var items []string
	if err := json.Unmarshal(raw, &items); err == nil {
		return items, nil
	}
	var single string
	if err := json.Unmarshal(raw, &single); err == nil {
		return strings.FieldsFunc(single, func(r rune) bool {
			return r == '\n' || r == '\r' || r == ','
		}), nil
	}
	return nil, fmt.Errorf("%w: %s is not a list of strings", ErrInvalid, names[0])
}

// EncodeLink renders the profile as a happ://routing/add/{base64} deep
// link in the builder's transport form (standard base64 with padding),
// so a profile sora received can be shared onward byte-compatibly.
func (p *Profile) EncodeLink() (string, error) {
	raw, err := p.MarshalJSON()
	if err != nil {
		return "", err
	}
	return "happ://routing/add/" + base64.StdEncoding.EncodeToString(raw), nil
}

// MarshalJSON renders the profile with the builder's field names and
// capitalisation, so EncodeLink output parses back through any Happ
// routing consumer, not only through DecodePayload.
func (p *Profile) MarshalJSON() ([]byte, error) {
	doc := map[string]any{}
	if p.Name != "" {
		doc["Name"] = p.Name
	}
	if p.GlobalProxy != nil {
		doc["GlobalProxy"] = *p.GlobalProxy
	}
	if p.FakeDNS != nil {
		doc["FakeDNS"] = *p.FakeDNS
	}
	if p.UseChunkFiles != nil {
		doc["UseChunkFiles"] = *p.UseChunkFiles
	}
	if p.RemoteDNSType != "" {
		doc["RemoteDNSType"] = p.RemoteDNSType
	}
	if p.RemoteDNSIP != "" {
		doc["RemoteDNSIP"] = p.RemoteDNSIP
	}
	if p.DomesticDNSType != "" {
		doc["DomesticDNSType"] = p.DomesticDNSType
	}
	if p.DomesticDNSIP != "" {
		doc["DomesticDNSIP"] = p.DomesticDNSIP
	}
	if p.GeoIPURL != "" {
		doc["Geoipurl"] = p.GeoIPURL
	}
	if p.GeoSiteURL != "" {
		doc["Geositeurl"] = p.GeoSiteURL
	}
	if p.LastUpdated != "" {
		doc["LastUpdated"] = p.LastUpdated
	}
	for key, list := range map[string][]string{
		"DirectSites": p.DirectSites, "DirectIp": p.DirectIP,
		"ProxySites": p.ProxySites, "ProxyIp": p.ProxyIP,
		"BlockSites": p.BlockSites, "BlockIp": p.BlockIP,
	} {
		if len(list) > 0 {
			doc[key] = list
		}
	}
	if len(p.DNSHosts) > 0 {
		doc["DnsHosts"] = p.DNSHosts
	}
	if p.DomainStrategy != "" {
		doc["DomainStrategy"] = p.DomainStrategy
	}
	return json.Marshal(doc)
}

// Rule is one converted routing rule in the sora contract's
// destination form (see core/control ruleFromProto): "domain:" /
// "full:" / "geosite:" / "geoip:" prefixes, bare CIDRs and addresses,
// with OutboundID "direct", "reject", or the caller's proxy target.
type Rule struct {
	Destination string `json:"destination"`
	OutboundID  string `json:"outbound_id"`
}

// Note records how one profile field was handled: applied to sora, or
// accepted but not applied, with the reason. Nothing is dropped
// silently: every non-empty field of the source document yields either
// rules or a note.
type Note struct {
	Field   string `json:"field"`
	Applied bool   `json:"applied"`
	Reason  string `json:"reason,omitempty"`
}

// Conversion is the result of mapping a profile onto sora's model.
type Conversion struct {
	// Name is the profile's display name.
	Name string
	// Rules are the converted rules, block first, then direct, then
	// proxy (first match wins in the engines, and a provider block
	// must never be shadowed by a broader direct/proxy entry).
	Rules []Rule
	// GlobalProxy is the profile's default-traffic decision, or nil
	// when the document does not carry one. It is reported, not turned
	// into a rule: the contract has no catch-all RoutingRule form —
	// the session's default target is RoutingOptions.proxy_target,
	// which the client owns. See the GlobalProxy note in Notes.
	GlobalProxy *bool
	// RemoteDNS / DomesticDNS carry the provider's resolvers verbatim
	// (type + address). They are reported, not applied: sora's
	// DnsPolicy is one flat per-session server list owned by the
	// user's settings, with no remote/domestic split and no
	// per-subscription DNS slot in the contract, so forcing provider
	// DNS into a session would silently override the user's choice.
	RemoteDNS   string
	DomesticDNS string
	Notes       []Note
	// Skipped counts list entries that could not be classified at
	// all (neither domain, address, network, nor geo category).
	Skipped int
}

// Built-in sora targets, as used by core/control's plan builder.
const (
	TargetDirect = "direct"
	TargetReject = "reject"
)

// Convert maps the profile onto sora routing rules addressed at
// proxyTarget (an outbound or group id of the caller's plan). An
// empty proxyTarget stores the sentinel "proxy": subscription-bound
// rules are merged into a plan by the client, which substitutes its
// session proxy target for the sentinel, exactly as it resolves the
// proxy target of a user rule.
func (p *Profile) Convert(proxyTarget string) Conversion {
	if proxyTarget == "" {
		proxyTarget = "proxy"
	}
	out := Conversion{Name: p.Name, GlobalProxy: p.GlobalProxy}
	seen := map[Rule]bool{}
	add := func(entries []string, target string) {
		for _, entry := range entries {
			if len(out.Rules) >= MaxRules {
				out.Skipped++
				continue
			}
			destination, ok := destinationOf(entry)
			if !ok {
				out.Skipped++
				continue
			}
			rule := Rule{Destination: destination, OutboundID: target}
			if seen[rule] {
				continue
			}
			seen[rule] = true
			out.Rules = append(out.Rules, rule)
		}
	}
	add(p.BlockSites, TargetReject)
	add(p.BlockIP, TargetReject)
	add(p.DirectSites, TargetDirect)
	add(p.DirectIP, TargetDirect)
	add(p.ProxySites, proxyTarget)
	add(p.ProxyIP, proxyTarget)

	if len(out.Rules) > 0 {
		out.Notes = append(out.Notes, Note{Field: "Direct/Proxy/Block lists", Applied: true})
	}
	if p.GlobalProxy != nil {
		switch {
		case *p.GlobalProxy:
			out.Notes = append(out.Notes, Note{Field: "GlobalProxy", Applied: true,
				Reason: "true matches sora's default: unmatched traffic goes to the proxy target"})
		default:
			out.Notes = append(out.Notes, Note{Field: "GlobalProxy", Applied: false,
				Reason: "false asks for a direct default; sora's plan default is the proxy target and the contract has no catch-all rule form, so the decision is recorded with the profile but not applied"})
		}
	}
	if p.RemoteDNSIP != "" {
		out.RemoteDNS = joinDNS(p.RemoteDNSType, p.RemoteDNSIP)
		out.Notes = append(out.Notes, Note{Field: "RemoteDNS", Applied: false,
			Reason: "recorded with the profile; sora DNS is a single user-owned per-session list with no remote/domestic split"})
	}
	if p.DomesticDNSIP != "" {
		out.DomesticDNS = joinDNS(p.DomesticDNSType, p.DomesticDNSIP)
		out.Notes = append(out.Notes, Note{Field: "DomesticDNS", Applied: false,
			Reason: "recorded with the profile; sora DNS is a single user-owned per-session list with no remote/domestic split"})
	}
	if p.FakeDNS != nil && *p.FakeDNS {
		out.Notes = append(out.Notes, Note{Field: "FakeDNS", Applied: false,
			Reason: "sora's DNS policy has no fake-IP mode; engines resolve real addresses"})
	}
	if len(p.DNSHosts) > 0 {
		out.Notes = append(out.Notes, Note{Field: "DnsHosts", Applied: false,
			Reason: "kept verbatim with the profile; its exact shape is not established by the open sources and sora has no static-hosts slot"})
	}
	if p.DomainStrategy != "" {
		out.Notes = append(out.Notes, Note{Field: "DomainStrategy", Applied: false,
			Reason: "kept with the profile; sora engines choose the domain strategy, the plan contract has no such knob"})
	}
	if p.GeoIPURL != "" || p.GeoSiteURL != "" {
		out.Notes = append(out.Notes, Note{Field: "Geoipurl/Geositeurl", Applied: false,
			Reason: "sora ships its own geo data with the engines and does not download provider geo files; geosite:/geoip: rules still match against the shipped data"})
	}
	if p.UseChunkFiles != nil && *p.UseChunkFiles {
		out.Notes = append(out.Notes, Note{Field: "UseChunkFiles", Applied: false,
			Reason: "a Happ geo-loading optimisation with no sora counterpart; no behavioural effect to reproduce"})
	}
	if out.Skipped > 0 {
		out.Notes = append(out.Notes, Note{Field: "list entries", Applied: false,
			Reason: fmt.Sprintf("%d entries were neither a domain, an address, a network, nor a geo category and were skipped", out.Skipped)})
	}
	return out
}

func joinDNS(typ, ip string) string {
	if typ == "" {
		return ip
	}
	return typ + " " + ip
}

// destinationOf classifies one list entry into the sora contract's
// destination form. The lists are separated into sites and IPs by the
// builder, but classification is by shape, not by which list an entry
// arrived in: providers hand-edit these documents, and a domain in an
// IP list (or the reverse) must still mean what it says.
func destinationOf(entry string) (string, bool) {
	text := strings.TrimSpace(entry)
	if text == "" || len(text) > maxEntryBytes || strings.ContainsAny(text, " \t\r\n") {
		return "", false
	}
	// Already in contract form (the builder's geo entries, or a
	// hand-written domain:/full: rule): keep, normalising the prefix
	// case so "GeoSite:RU" and "geosite:ru" cannot diverge.
	for _, prefix := range []string{"geosite:", "geoip:", "domain:", "full:", "ruleset:"} {
		if len(text) > len(prefix) && strings.EqualFold(text[:len(prefix)], prefix) {
			return prefix + text[len(prefix):], true
		}
	}
	if u, err := url.Parse(text); err == nil && u.Host != "" && (u.Scheme == "http" || u.Scheme == "https") {
		text = u.Hostname()
	}
	text = strings.TrimPrefix(text, "*.")
	if prefix, err := netip.ParsePrefix(text); err == nil {
		return prefix.Masked().String(), true
	}
	if addr, err := netip.ParseAddr(text); err == nil {
		return netip.PrefixFrom(addr, addr.BitLen()).String(), true
	}
	// A bare domain: labels of letters, digits and hyphens with at
	// least one dot (a dotless token is a process name or a keyword
	// in sora's grammar, not something a provider list means as a
	// site). Stored as a suffix rule, the builder's semantics for a
	// listed site.
	if !strings.Contains(text, ".") || strings.HasPrefix(text, ".") || strings.HasSuffix(text, ".") {
		return "", false
	}
	for _, label := range strings.Split(text, ".") {
		if label == "" || len(label) > 63 {
			return "", false
		}
		for _, r := range label {
			if r != '-' && (r < '0' || r > '9') && (r < 'a' || r > 'z') && (r < 'A' || r > 'Z') && r < 0x80 {
				return "", false
			}
		}
	}
	return "domain:" + strings.ToLower(text), true
}
