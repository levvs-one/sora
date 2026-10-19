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
	// REALITY parameters are public but identify the server (SORA-L9).
	for _, id := range []string{o.TLS.RealityPublicKey, o.TLS.RealityShortID, o.TLS.SpiderX} {
		if id != "" {
			out = append(out, id)
		}
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
	out = append(out, o.shadowsocksWarnings()...)
	return out
}

// Validate checks one outbound on its own, without engine capabilities.
// validProtocols whitelists the protocols a plan may hold, so an unknown
// protocol fails validation with a clear error instead of surfacing late at
// eng.Apply (SORA-L16).
var validProtocols = map[Protocol]bool{
	ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
	ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolTUIC: true,
	ProtocolWireGuard: true, ProtocolSOCKS5: true, ProtocolHTTP: true,
	ProtocolAnyTLS: true, ProtocolBypass: true, ProtocolXrayProfile: true,
	ProtocolDirect: true,
}

// validTransports whitelists the stream transports a plan may hold. "h2" is
// accepted at plan level for sing-box; engines that dropped it (Xray) reject
// it when rendering.
var validTransports = map[string]bool{
	"": true, "tcp": true, "ws": true, "grpc": true,
	"h2": true, "httpupgrade": true, "xhttp": true,
}

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
	serverless := o.Protocol == ProtocolDirect || o.Protocol == ProtocolBypass
	if !serverless && o.Port == 0 {
		errs = append(errs, fmt.Errorf("outbound %s: port must be between 1 and 65535", o.ID))
	}
	if err := validateServer("outbound "+o.ID, o.Server, !serverless); err != nil {
		errs = append(errs, err)
	}
	if o.Protocol == ProtocolBypass {
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
	if o.Amnezia != nil {
		if o.Protocol != ProtocolWireGuard {
			errs = append(errs, fmt.Errorf("outbound %s: AmneziaWG parameters require the wireguard protocol", o.ID))
		} else {
			errs = append(errs, validateAmneziaWG(o.ID, o.Amnezia)...)
		}
	}
	return errors.Join(errs...)
}

// AmneziaWG parameter bounds, matching the upstream kernel module and
// amneziawg-go: Jc is 1-128 (0 disables junk), junk sizes stay below the
// 1280-byte minimal IPv6 MTU so packets do not fragment, S1/S2 keep
// 148+S1 != 92+S2 so init and response sizes cannot collide, and the four
// magic headers must be distinct so packet types stay distinguishable.
const (
	awgMaxJunkCount = 128
	awgMaxJunkSize  = 1280
	awgMaxS1        = 1132
	awgMaxS2        = 1188
	awgMaxS3        = 1216
	awgMaxS4        = 32
	awgMinMagic     = 5
	awgMaxMagic     = 2147483647
)

// validateAmneziaWG rejects obfuscation parameters an engine would silently
// misapply or drop: every engine derives from the same upstream device, so
// the checks stay engine-independent. I1-I5 are CPS tag scripts (engine and
// version specific) and are left to the renderer.
func validateAmneziaWG(id string, a *AmneziaWG) []error {
	var errs []error
	bad := func(format string, args ...any) {
		args = append([]any{id}, args...)
		errs = append(errs, fmt.Errorf("outbound %s: amneziawg "+format, args...))
	}
	if a.Jc < 0 || a.Jc > awgMaxJunkCount {
		bad("jc %d is outside 0-%d", a.Jc, awgMaxJunkCount)
	}
	if a.Jmin < 0 || a.Jmin > awgMaxJunkSize {
		bad("jmin %d is outside 0-%d", a.Jmin, awgMaxJunkSize)
	}
	if a.Jmax < 0 || a.Jmax > awgMaxJunkSize {
		bad("jmax %d is outside 0-%d", a.Jmax, awgMaxJunkSize)
	}
	if a.Jmin > a.Jmax {
		bad("jmin %d exceeds jmax %d", a.Jmin, a.Jmax)
	}
	pads := []struct {
		name string
		v    int
		max  int
	}{
		{"s1", a.S1, awgMaxS1}, {"s2", a.S2, awgMaxS2},
		{"s3", a.S3, awgMaxS3}, {"s4", a.S4, awgMaxS4},
	}
	for _, p := range pads {
		if p.v < 0 || p.v > p.max {
			bad("%s %d is outside 0-%d", p.name, p.v, p.max)
		}
	}
	if a.S1+56 == a.S2 && (a.S1 != 0 || a.S2 != 0) {
		bad("s1+56 must not equal s2, or padded init and response packets collide at %d bytes", a.S2+92)
	}
	type interval struct{ lo, hi int64 }
	headers := [4]interval{}
	names := []string{"h1", "h2", "h3", "h4"}
	values := []string{a.H1, a.H2, a.H3, a.H4}
	for i, raw := range values {
		if raw == "" {
			continue
		}
		lo, hi, err := parseAmneziaMagic(raw)
		if err != nil {
			bad("%s %q is not a header or header range: %v", names[i], raw, err)
			continue
		}
		if lo < awgMinMagic || hi > awgMaxMagic {
			bad("%s %q is outside %d-%d", names[i], raw, awgMinMagic, awgMaxMagic)
			continue
		}
		headers[i] = interval{lo, hi}
	}
	for i := 0; i < 4; i++ {
		if values[i] == "" {
			continue
		}
		for j := i + 1; j < 4; j++ {
			if values[j] == "" {
				continue
			}
			if headers[i].lo <= headers[j].hi && headers[j].lo <= headers[i].hi {
				bad("%s %q and %s %q overlap: packet types must stay distinguishable",
					names[i], values[i], names[j], values[j])
			}
		}
	}
	return errs
}

// parseAmneziaMagic parses a 2.0 magic header: a single number or an "x-y"
// range with x <= y.
func parseAmneziaMagic(raw string) (lo, hi int64, err error) {
	parts := strings.SplitN(raw, "-", 2)
	if len(parts) == 1 {
		n, err := strconv.ParseInt(strings.TrimSpace(parts[0]), 10, 64)
		if err != nil {
			return 0, 0, err
		}
		return n, n, nil
	}
	lo, err = strconv.ParseInt(strings.TrimSpace(parts[0]), 10, 64)
	if err != nil {
		return 0, 0, err
	}
	hi, err = strconv.ParseInt(strings.TrimSpace(parts[1]), 10, 64)
	if err != nil {
		return 0, 0, err
	}
	if lo > hi {
		return 0, 0, fmt.Errorf("range %q has its lower bound above the upper bound", raw)
	}
	return lo, hi, nil
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
			if !isOutbound && !isGroup && !isBuiltInTarget(ref) {
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
		if !isOutbound && !isGroup && !isBuiltInTarget(r.Target) {
			errs = append(errs, fmt.Errorf("rule %s %q: unknown target %q", r.Type, r.Value, r.Target))
		}
	}

	errs = append(errs, validateChains(p.Outbounds, ids))

	errs = append(errs, p.DNS.validate(), p.Tun.validate(), p.Options.validate())
	return errors.Join(errs...)
}

// MaxChainHops bounds a proxy chain: the entry outbound plus its via links.
// Longer chains multiply failure modes without meaningful privacy gains.
const MaxChainHops = 3

// validateChains checks Via links between outbounds: every link names an
// existing outbound, no outbound links to itself, no cycles, and no chain is
// longer than MaxChainHops.
func validateChains(outbounds []Outbound, ids map[string]struct{}) error {
	via := make(map[string]string, len(outbounds))
	for _, o := range outbounds {
		if o.Via == "" {
			continue
		}
		if o.Protocol == ProtocolDirect || o.Protocol == ProtocolBypass {
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
	if len(s.SplitPos) == 0 && s.TLSRecord == "" && !s.HostCase && !s.DomainCase && !s.MethodEOL &&
		!s.HostDot && !s.HostTab && !s.HostNoSpace && !s.MethodSpace && !s.UnixEOL {
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
	for _, scope := range []string{s.DisorderScope, s.OOBScope} {
		if scope != "" && scope != "http" && scope != "tls" {
			return fmt.Errorf("outbound %s: %q is not a protocol scope (http or tls)", id, scope)
		}
	}
	if s.DisorderScope != "" && !s.Disorder {
		return fmt.Errorf("outbound %s: a disorder scope needs disorder", id)
	}
	if s.OOBScope != "" && !s.OOB {
		return fmt.Errorf("outbound %s: an out-of-band scope needs out-of-band", id)
	}
	if (s.Disorder || s.OOB) && len(s.SplitPos) == 0 {
		return fmt.Errorf("outbound %s: disorder and out-of-band bytes need a split position", id)
	}
	return nil
}
