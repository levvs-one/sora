package engine

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"regexp"
	"slices"
	"strconv"
	"strings"
)

// Secrets returns every value of the plan that must never reach a log, an
// event or a diagnostic archive.
func (p *Plan) Secrets() []string {
	if p == nil {
		return nil
	}
	out := make([]string, 0, len(p.Outbounds)*4+1)
	for _, o := range p.Outbounds {
		out = append(out, o.Secrets()...)
	}
	if len(p.LocalProxy.Password) >= 4 {
		out = append(out, p.LocalProxy.Password)
	}
	if x := p.ExtensionProxy; x != nil {
		out = append(out, x.Username, x.Password)
	}
	return out
}

// Secrets lists the secret fields of one outbound. Values shorter than four
// characters are skipped: masking them would destroy ordinary log text.
func (o Outbound) Secrets() []string {
	candidates := []string{o.UUID, o.Password, o.UserID, o.ObfsParam, o.PrivateKey, o.OriginalLink}
	if o.Encryption != "none" {
		candidates = append(candidates, o.Encryption)
	}
	for _, p := range o.Peers {
		candidates = append(candidates, p.PreSharedKey)
	}
	candidates = append(candidates, profileSecrets(o.Profile)...)
	if o.Naive != nil {
		for _, v := range o.Naive.ExtraHeaders {
			candidates = append(candidates, v)
		}
	}
	out := make([]string, 0, len(candidates))
	for _, c := range candidates {
		if len(c) >= 4 {
			out = append(out, c)
		}
	}
	return out
}

// Identifiers returns the server host and host:port for privacy redaction.
// These are not credentials but identify user connections and providers.
func (o Outbound) Identifiers() []string {
	out := make([]string, 0, 6)
	if o.Server != "" {
		out = append(out, o.Server)
		if o.Port != 0 {
			out = append(out, net.JoinHostPort(o.Server, strconv.Itoa(int(o.Port))))
		}
	}
	if o.TLS.ServerName != "" {
		out = append(out, o.TLS.ServerName)
	}
	// REALITY parameters are public but identify the server.
	for _, id := range []string{o.TLS.RealityPublicKey, o.TLS.RealityShortID, o.TLS.SpiderX} {
		if id != "" {
			out = append(out, id)
		}
	}
	if o.OLCRTC != nil {
		out = append(out, o.OLCRTC.Room)
	}
	out = append(out, o.Name)
	return out
}

// Identifiers returns plan server identifiers for redaction alongside Secrets.
func (p *Plan) Identifiers() []string {
	if p == nil {
		return nil
	}
	out := make([]string, 0, len(p.Outbounds)*3)
	for _, o := range p.Outbounds {
		out = append(out, o.Identifiers()...)
	}
	return out
}

// Warnings returns codes for allowed risky settings. Clients localize them; the
// core stores no user-facing text.
func (o Outbound) Warnings() []string {
	var out []string
	if o.TLS.Insecure && o.Protocol != ProtocolDirect {
		out = append(out, "insecure-certificate")
	}
	if o.TLS.Enabled && o.TLS.ServerName == "" && o.Protocol != ProtocolDirect {
		out = append(out, "tls-server-name-missing")
	}
	if o.Transport.Type == "ws" && !o.TLS.Enabled {
		out = append(out, "websocket-without-tls")
	}
	return out
}

// validProtocols whitelists the protocols a plan may hold, so an unknown
// protocol fails validation with a clear error instead of surfacing late at
// eng.Apply.
var validProtocols = map[Protocol]bool{
	ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
	ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolTUIC: true,
	ProtocolWireGuard: true, ProtocolSOCKS5: true, ProtocolHTTP: true,
	ProtocolAnyTLS: true, ProtocolBypass: true, ProtocolByeDPI: true, ProtocolWinws: true, ProtocolXrayProfile: true,
	ProtocolDirect: true, ProtocolOLCRTC: true, ProtocolMieru: true, ProtocolNaive: true,
}

// validTransports includes parser outputs and renderer transport names:
// WireGuard uses udp, mihomo accepts raw, and Xray profiles carry hysteria.
// Each renderer still rejects transports it cannot use for that outbound.
var validTransports = map[string]bool{
	"": true, "tcp": true, "udp": true, "raw": true, "ws": true, "grpc": true,
	"h2": true, "httpupgrade": true, "xhttp": true, "hysteria": true,
}

// Validate checks one outbound before rendering.
func (o Outbound) Validate() error {
	var errs []error
	if o.ID == "" {
		errs = append(errs, errors.New("outbound: empty id"))
	} else if len(o.ID) > MaxIDLen {
		errs = append(errs, fmt.Errorf("outbound %q: id longer than %d bytes", o.ID, MaxIDLen))
	}
	if err := validateDisplayName("outbound "+o.ID, o.Name); err != nil {
		errs = append(errs, err)
	}
	if !validProtocols[o.Protocol] {
		errs = append(errs, fmt.Errorf("outbound %s: unknown protocol %q", o.ID, o.Protocol))
	}
	if !validTransports[o.Transport.Type] {
		errs = append(errs, fmt.Errorf("outbound %s: unknown transport %q", o.ID, o.Transport.Type))
	}
	serverless := o.Protocol == ProtocolDirect || o.Protocol == ProtocolBypass || o.Protocol == ProtocolByeDPI || o.Protocol == ProtocolWinws
	if !serverless && o.Port == 0 {
		errs = append(errs, fmt.Errorf("outbound %s: port must be between 1 and 65535", o.ID))
	}
	if err := validateServer("outbound "+o.ID, o.Server, !serverless); err != nil {
		errs = append(errs, err)
	}
	if o.Protocol == ProtocolOLCRTC {
		errs = append(errs, validateOLCRTC(o))
	}
	if o.Protocol == ProtocolMieru || o.Protocol == ProtocolNaive {
		errs = append(errs, o.validateCommunity())
	}
	if o.Protocol == ProtocolBypass || o.Protocol == ProtocolByeDPI || o.Protocol == ProtocolWinws {
		errs = append(errs, o.Bypass.validate(o.ID))
	}
	if o.Protocol == ProtocolXrayProfile {
		var profile struct {
			Outbounds []json.RawMessage `json:"outbounds"`
		}
		if err := json.Unmarshal(o.Profile, &profile); err != nil || len(profile.Outbounds) == 0 {
			errs = append(errs, fmt.Errorf("outbound %s: the Xray profile has no outbounds", o.ID))
		}
	}
	if len(o.TLS.ALPN) > 8 {
		errs = append(errs, fmt.Errorf("outbound %s: too many ALPN entries", o.ID))
	}
	if len(o.Transport.Headers) > MaxHeaderCount {
		errs = append(errs, fmt.Errorf("outbound %s: more than %d headers", o.ID, MaxHeaderCount))
	}
	for k, v := range o.Transport.Headers {
		if !validHeaderToken(k) || strings.ContainsAny(v, "\r\n") {
			errs = append(errs, fmt.Errorf("outbound %s: header %q is not a safe HTTP header", o.ID, k))
		}
	}
	return errors.Join(errs...)
}

// Validate checks the plan as a whole: limits, identifiers, references between
// rules and groups, and the engine-independent rules of every outbound.
func (p *Plan) Validate() error {
	if p == nil {
		return errors.New("plan: nil plan")
	}
	var errs []error
	if strings.TrimSpace(p.SessionID) == "" {
		errs = append(errs, errors.New("plan: empty session id"))
	}
	if len(p.Outbounds) == 0 {
		errs = append(errs, errors.New("plan: no outbounds"))
	}
	if len(p.Outbounds) > MaxOutbounds {
		errs = append(errs, fmt.Errorf("plan: %d outbounds exceeds the limit of %d", len(p.Outbounds), MaxOutbounds))
	}
	if len(p.Groups) > MaxGroups {
		errs = append(errs, fmt.Errorf("plan: %d groups exceeds the limit of %d", len(p.Groups), MaxGroups))
	}
	if len(p.Rules) > MaxRules {
		errs = append(errs, fmt.Errorf("plan: %d rules exceeds the limit of %d", len(p.Rules), MaxRules))
	}

	ids := make(map[string]struct{}, len(p.Outbounds))
	for _, o := range p.Outbounds {
		errs = append(errs, o.Validate())
		if _, dup := ids[o.ID]; dup {
			errs = append(errs, fmt.Errorf("plan: duplicate outbound id %q", o.ID))
		}
		ids[o.ID] = struct{}{}
	}
	// Profiles run alone because combining provider routing with other
	// profiles or groups changes its semantics.
	if slices.ContainsFunc(p.Outbounds, func(o Outbound) bool { return o.Protocol == ProtocolXrayProfile }) &&
		(len(p.Outbounds) > 1 || len(p.Groups) > 0) {
		errs = append(errs, errors.New("plan: an Xray profile runs alone, without other outbounds or groups"))
	}

	if slices.ContainsFunc(p.Outbounds, func(o Outbound) bool { return o.Protocol == ProtocolByeDPI }) &&
		(len(p.Outbounds) != 1 || len(p.Groups) != 0 || p.ExtensionProxy != nil) {
		errs = append(errs, errors.New("plan: ByeDPI runs alone without VPNs, groups or extension proxies"))
	}

	// A machine-wide packet filter cannot preserve per-outbound ownership.
	if slices.ContainsFunc(p.Outbounds, func(o Outbound) bool { return o.Protocol == ProtocolWinws }) &&
		(len(p.Outbounds) != 1 || len(p.Groups) != 0 || p.ExtensionProxy != nil) {
		errs = append(errs, errors.New("plan: system-wide Winws runs alone without VPNs, groups or extension proxies"))
	}

	// Collect all group names before validating members to allow nested and
	// forward references.
	members := make(map[string][]string, len(p.Groups))
	for _, g := range p.Groups {
		members[g.Name] = g.Outbounds
		if _, clash := ids[g.Name]; clash {
			errs = append(errs, fmt.Errorf("plan: group %q has the id of an outbound", g.Name))
		}
	}
	if (p.LocalProxy.Username == "") != (p.LocalProxy.Password == "") {
		errs = append(errs, errors.New("plan: the local proxy login needs both a username and a password"))
	}
	if strings.ContainsAny(p.LocalProxy.Username, ":@ \r\n") {
		errs = append(errs, errors.New("plan: the local proxy username contains a separator"))
	}
	if x := p.ExtensionProxy; x != nil {
		if x.Port < 1024 || x.Port > 65535 || len(x.Username) < 16 || len(x.Username) > 255 ||
			len(x.Password) < 32 || len(x.Password) > 255 || strings.ContainsAny(x.Username+x.Password, ":@ \r\n") {
			errs = append(errs, errors.New("plan: the extension proxy needs a private port and a strong login"))
		}
		if !p.IsVPNTarget(x.Target) {
			errs = append(errs, errors.New("plan: the extension proxy target must use only VPN outbounds"))
		}
	}
	names := make(map[string]struct{}, len(p.Groups))
	for _, g := range p.Groups {
		errs = append(errs, g.validate())
		if g.needsProbe() && g.URL == "" && p.Options.TestURL == "" {
			errs = append(errs, fmt.Errorf("plan: group %q measures latency, but the plan has no test url", g.Name))
		}
		errs = append(errs, validateTestURL("group "+g.Name, g.URL))
		if _, dup := names[g.Name]; dup {
			errs = append(errs, fmt.Errorf("plan: duplicate group name %q", g.Name))
		}
		names[g.Name] = struct{}{}
		for _, ref := range g.Outbounds {
			_, isOutbound := ids[ref]
			_, isGroup := members[ref]
			if !isOutbound && !isGroup && !IsBuiltInTarget(ref) {
				errs = append(errs, fmt.Errorf("group %q: unknown outbound %q", g.Name, ref))
			}
		}
		if groupCycle(g.Name, members, map[string]bool{}) {
			errs = append(errs, fmt.Errorf("group %q: contains itself through its members", g.Name))
		}
	}

	for _, r := range p.Rules {
		errs = append(errs, r.validate())
		if r.Target == "" {
			errs = append(errs, fmt.Errorf("rule %s %q: empty target", r.Type, r.Value))
			continue
		}
		_, isOutbound := ids[r.Target]
		_, isGroup := names[r.Target]
		if !isOutbound && !isGroup && !IsBuiltInTarget(r.Target) {
			errs = append(errs, fmt.Errorf("rule %s %q: unknown target %q", r.Type, r.Value, r.Target))
		}
	}

	errs = append(errs, p.DNS.validate(), p.Tun.validate(), p.Options.validate())
	errs = append(errs, validateChains(p.Outbounds, ids))
	return errors.Join(errs...)
}

// groupCycle reports whether group reaches itself through nested groups.
func groupCycle(group string, members map[string][]string, visiting map[string]bool) bool {
	if visiting[group] {
		return true
	}
	visiting[group] = true
	defer delete(visiting, group)
	for _, m := range members[group] {
		if _, isGroup := members[m]; isGroup && groupCycle(m, members, visiting) {
			return true
		}
	}
	return false
}

// bypassPosition is a zapret split position: bytes, bytes from the end, or a
// marker with an optional offset.
var bypassPosition = regexp.MustCompile(`^(-?[0-9]{1,4}|(method|host|endhost|sld|midsld|endsld|sniext)([+-][0-9]{1,4})?)$`)

func (s *BypassStrategy) validate(id string) error {
	if s == nil {
		return fmt.Errorf("outbound %s: a bypass outbound needs a strategy", id)
	}
	if len(s.SplitPos) == 0 && s.TLSRecord == "" && !s.HostCase && !s.DomainCase && !s.MethodEOL {
		return fmt.Errorf("outbound %s: the bypass strategy changes nothing", id)
	}
	if len(s.SplitPos) > 8 {
		return fmt.Errorf("outbound %s: more than 8 split positions", id)
	}
	for _, pos := range append(slices.Clone(s.SplitPos), s.TLSRecord) {
		if pos != "" && !bypassPosition.MatchString(pos) {
			return fmt.Errorf("outbound %s: %q is not a split position", id, pos)
		}
	}
	if (s.Disorder || s.OOB) && len(s.SplitPos) == 0 {
		return fmt.Errorf("outbound %s: disorder and out-of-band bytes need a split position", id)
	}
	return nil
}

// MaxChainHops bounds an entry and its proxy hops.
const MaxChainHops = 3

func validateChains(outbounds []Outbound, ids map[string]struct{}) error {
	via := make(map[string]string, len(outbounds))
	for _, o := range outbounds {
		if o.Via == "" {
			continue
		}
		if o.Protocol == ProtocolDirect || o.Protocol == ProtocolBypass || o.Protocol == ProtocolByeDPI || o.Protocol == ProtocolWinws {
			return fmt.Errorf("outbound %s: a %s outbound cannot dial through another", o.ID, o.Protocol)
		}
		if o.Via == o.ID {
			return fmt.Errorf("outbound %s: dials through itself", o.ID)
		}
		if _, ok := ids[o.Via]; !ok {
			return fmt.Errorf("outbound %s: dials through unknown outbound %q", o.ID, o.Via)
		}
		via[o.ID] = o.Via
	}
	for _, o := range outbounds {
		if o.Via == "" {
			continue
		}
		seen := map[string]bool{o.ID: true}
		depth := 1
		for next := o.Via; next != ""; {
			if seen[next] {
				return fmt.Errorf("outbound %s: its chain loops back through %q", o.ID, next)
			}
			seen[next] = true
			depth++
			if depth > MaxChainHops {
				return fmt.Errorf("outbound %s: its chain is longer than %d hops", o.ID, MaxChainHops)
			}
			next = via[next]
		}
	}
	return nil
}
