package control

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"net/netip"
	"runtime"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/ext"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/tune/desync"
)

// The Anti-DPI seam (contract 1.14): extension bypass layers in the
// control plane.
//
// Data flow: an extension with bypass.write stores a layer in the
// shared ext.LayerStore (wired by main: the same store backs the
// ExtensionHost ApplyBypassLayer RPC and this merge). At Connect,
// buildPlan merges the layers of ENABLED extensions that still hold
// bypass.write into the plan (the provider filter below), records a
// provenance for GetBypassState, and the session runs the merged plan.
// Disabling an extension — or revoking its grant — removes its layer
// from the provider, so the next Connect is built without it; a live
// session is never mutated under the user's traffic.
//
// Merge semantics (see mergeBypassBindings and the zapret block in
// planFromProtoLayers):
//   - Global: fills the zapret-with-VPN strategy slot only when the
//     request's own strategy is empty. A user strategy always wins.
//   - Bindings: become bypass outbounds + routing rules in every plan
//     mode planFromProto produces. Both modes it builds (TUN and the
//     local-proxy/application mode) carry rule routing and treat a
//     bypass outbound as a first-class serverless outbound — a
//     serverless plan is exactly a bypass outbound behind the local
//     proxy — so there is no plan mode here where a binding rule
//     could not be honoured, and none is silently dropped for mode
//     reasons. A binding whose destination the plan already routes
//     (user rules, preset rules, or BypassSettings) is skipped: the
//     user wins.

// bypassProvenance records what the layer merge did to one built plan:
// where its global bypass strategy came from, how many bindings it
// carries, and the clock readings GetBypassState needs to decide
// whether a newer layer is still pending.
type bypassProvenance struct {
	// Source is "user", "extension", "core_default" or "none".
	Source string
	// From is the extension id when Source is "extension".
	From string
	// BuiltAt is when the plan was built.
	BuiltAt time.Time
	// NewestLayer is the newest UpdatedAt among the layers the merge
	// considered (zero when there were none).
	NewestLayer time.Time
	// Bindings counts the bindings the merge actually applied.
	Bindings int
}

// SetBypassLayerStore wires the shared extension layer store and the
// enabled+granted check the layer provider filters by. The check is a
// callback because the extension registry lives with the host wiring
// (main), not with the control plane; it must report true only for an
// installed, enabled extension whose granted permissions include
// bypass.write. A nil store disables the merge.
func (s *Server) SetBypassLayerStore(store *ext.LayerStore, enabled func(id string) bool) {
	s.bypassMu.Lock()
	defer s.bypassMu.Unlock()
	s.bypassLayerStore = store
	s.bypassLayerEnabled = enabled
}

// SetBypassCapabilities wires the measured bypass capability source
// behind GetBypassCapabilities/GetBypassState (main builds it from the
// digest-verified engine discovery plus the bypass package's platform
// probe). Without it, capabilities honestly report both backends
// unavailable.
func (s *Server) SetBypassCapabilities(fn func(ctx context.Context) (string, []ext.BackendState, error)) {
	s.bypassMu.Lock()
	defer s.bypassMu.Unlock()
	s.bypassCapsFn = fn
}

// extLayerStore returns the wired layer store, or nil.
func (s *Server) extLayerStore() *ext.LayerStore {
	s.bypassMu.Lock()
	defer s.bypassMu.Unlock()
	return s.bypassLayerStore
}

// bypassLayers is the plan-side layer provider: every stored layer
// whose extension passes the wired enabled+granted check, in store
// order (freshest first). Without a wired check, a wired store's
// layers are all trusted (unit tests, embedded cores); production
// wiring always sets the check.
func (s *Server) bypassLayers() []ext.LayerEntry {
	s.bypassMu.Lock()
	store, enabled := s.bypassLayerStore, s.bypassLayerEnabled
	s.bypassMu.Unlock()
	if store == nil {
		return nil
	}
	entries := store.List()
	if enabled == nil {
		return entries
	}
	out := entries[:0]
	for _, e := range entries {
		if enabled(e.ID) {
			out = append(out, e)
		}
	}
	return out
}

// buildPlan is Connect's plan path: planFromProtoMerged over the
// current layers, with the provenance remembered for GetBypassState. A
// failed build leaves the previous provenance untouched — state keeps
// describing the last plan that was actually built.
func (s *Server) buildPlan(in *corev1.SessionPlan, sessionID string) (*engine.Plan, error) {
	plan, prov, err := planFromProtoMerged(in, sessionID, s.secrets, s.bypassLayers())
	if err != nil {
		return nil, err
	}
	s.bypassMu.Lock()
	s.bypassProv = prov
	s.bypassMu.Unlock()
	return plan, nil
}

// canonicalDomainValue renders one domain in the canonical form
// ruleFromProto produces for user rules: IDNA ASCII (lower-case /
// punycode) with the same profile. An unconvertible value falls back
// to its lower-case form, so comparison stays case-insensitive even
// for a value ruleFromProto would have refused outright.
func canonicalDomainValue(v string) string {
	if ascii, err := ruleIDNA.ToASCII(v); err == nil {
		return ascii
	}
	return strings.ToLower(v)
}

// canonicalBypassDestination renders a layer match or a BypassSettings
// entry in the canonical destination form rules are compared in: a
// prefixed destination stays as is, an address or network stays as is,
// and a bare domain becomes its "domain:" form. Domain parts are
// canonicalized (case/IDNA, L2) exactly as ruleFromProto canonicalizes
// user rules, so "domain:EXAMPLE.com" from a layer and a user rule
// for "example.com" compare equal.
func canonicalBypassDestination(match string) string {
	m := strings.TrimSpace(match)
	for _, prefix := range []string{"domain:", "full:"} {
		if strings.HasPrefix(m, prefix) {
			return prefix + canonicalDomainValue(strings.TrimPrefix(m, prefix))
		}
	}
	for _, prefix := range []string{"geosite:", "geoip:", "ruleset:", "process:"} {
		if strings.HasPrefix(m, prefix) {
			return m
		}
	}
	if _, err := netip.ParseAddr(m); err == nil {
		return m
	}
	if _, err := netip.ParsePrefix(m); err == nil {
		return m
	}
	return "domain:" + canonicalDomainValue(m)
}

// bypassDestDomain splits a canonical destination into its prefix
// ("domain:" or "full:") and domain, reporting whether it is a domain
// destination at all.
func bypassDestDomain(dest string) (prefix, domain string, ok bool) {
	for _, p := range []string{"domain:", "full:"} {
		if strings.HasPrefix(dest, p) {
			return p, strings.TrimPrefix(dest, p), true
		}
	}
	return "", "", false
}

// domainSuffixCovered reports whether a canonical binding destination
// is already covered by one of the collected user domain-suffix
// domains: a user "domain:example.com" rule routes sub.example.com
// (and example.com itself), so a binding for it — in either its
// domain: or full: form — would never be reached (L2).
func domainSuffixCovered(suffixes []string, dest string) bool {
	_, dom, ok := bypassDestDomain(dest)
	if !ok {
		return false
	}
	for _, suf := range suffixes {
		if dom == suf || strings.HasSuffix(dom, "."+suf) {
			return true
		}
	}
	return false
}

// extBypassOutboundName names a binding's synthetic outbound. The
// name mirrors the match ("ext: "+match) while it fits the plan's
// name limit; a longer match is shortened deterministically — the
// tail is replaced with a hash suffix of the full match — so the
// merge can never emit a name over engine.MaxNameBytes, whatever a
// layer carries (M1, second line of defence behind the
// ValidateBypassMatch cap in core/ext).
func extBypassOutboundName(match string) string {
	name := "ext: " + match
	if len(name) <= engine.MaxNameBytes {
		return name
	}
	sum := sha256.Sum256([]byte(match))
	suffix := "-" + hex.EncodeToString(sum[:8])
	budget := engine.MaxNameBytes - len("ext: ") - len(suffix)
	truncated := match
	for len(truncated) > budget {
		_, size := utf8.DecodeLastRuneInString(truncated)
		if size <= 0 {
			size = 1
		}
		truncated = truncated[:len(truncated)-size]
	}
	return "ext: " + truncated + suffix
}

// ruleDestination renders a plan rule back into destination form, the
// inverse of ruleFromProto's derivation, for conflict comparison.
func ruleDestination(r engine.Rule) string {
	switch r.Type {
	case engine.RuleDomainSuffix:
		return "domain:" + r.Value
	case engine.RuleDomain:
		return "full:" + r.Value
	case engine.RuleGeoSite:
		return "geosite:" + r.Value
	case engine.RuleGeoIP:
		return "geoip:" + r.Value
	case engine.RuleRuleSet:
		return "ruleset:" + r.Value
	case engine.RuleProcess:
		return "process:" + r.Value
	default:
		return r.Value
	}
}

// extBypassOutboundID derives the synthetic outbound id of one layer
// binding: stable for the same (extension, destination) pair, so a
// rebuilt plan names the outbound identically.
func extBypassOutboundID(extensionID, destination string) string {
	sum := sha256.Sum256([]byte(extensionID + "\x00" + destination))
	return "ext-bypass-" + hex.EncodeToString(sum[:6])
}

// mergeBypassBindings weaves layer bindings into the plan: one bypass
// outbound and one routing rule per binding, the rules inserted after
// the user's (and preset) rules and before the final catch-all
// proxy-target rule, preserving first-match semantics. A binding is
// skipped — never an error — when its destination is already routed
// by the plan or listed in BypassSettings (the user wins), when its
// outbound id collides, or when the plan is at its outbound/rule
// limits; plan validation remains the final arbiter for everything
// that is added. Applied bindings are counted into prov.
func mergeBypassBindings(plan *engine.Plan, in *corev1.SessionPlan, layers []ext.LayerEntry, prov *bypassProvenance) {
	if plan == nil || len(layers) == 0 {
		return
	}
	// An Xray profile runs alone (Plan.Validate): weaving in even one
	// binding outbound or rule would invalidate an otherwise valid
	// user plan, so a profile plan takes no bindings at all (M1b).
	for _, o := range plan.Outbounds {
		if o.Protocol == engine.ProtocolXrayProfile {
			return
		}
	}
	existing := make(map[string]bool, len(plan.Rules))
	// suffixDomains collects the domains of user domain-suffix
	// destinations: a binding covered by one is a conflict (L2).
	var suffixDomains []string
	noteExisting := func(dest string) {
		existing[dest] = true
		if prefix, dom, ok := bypassDestDomain(dest); ok && prefix == "domain:" {
			suffixDomains = append(suffixDomains, dom)
		}
	}
	for _, r := range plan.Rules {
		noteExisting(ruleDestination(r))
		if r.Type == engine.RuleDomainKeyword {
			// A keyword rule matches the name anywhere inside a host;
			// a binding for the same name would never be reached for
			// the hosts the user meant, so it counts as routed.
			existing["domain:"+r.Value] = true
			existing["full:"+r.Value] = true
		}
	}
	for _, entry := range in.GetBypassSettings().GetRules() {
		noteExisting(canonicalBypassDestination(entry))
	}
	outboundIDs := make(map[string]bool, len(plan.Outbounds))
	for _, o := range plan.Outbounds {
		outboundIDs[o.ID] = true
	}
	// Insertion point: just before the first catch-all rule (the
	// routing layer's final proxy-target rule, or the user's own
	// catch-all), so bindings never shadow a user rule and never fall
	// behind the rule that matches everything.
	insertAt := len(plan.Rules)
	for i, r := range plan.Rules {
		if r.Type == engine.RuleMatchAll {
			insertAt = i
			break
		}
	}
	var added []engine.Rule
	for _, entry := range layers {
		for _, b := range entry.Layer.Bindings {
			dest := canonicalBypassDestination(b.Match)
			if existing[dest] {
				continue
			}
			// Suffix conflict (L2): a user domain-suffix rule
			// already routes this destination's hosts.
			if domainSuffixCovered(suffixDomains, dest) {
				continue
			}
			if len(plan.Outbounds) >= engine.MaxOutbounds || len(plan.Rules)+len(added) >= engine.MaxRules {
				continue
			}
			id := extBypassOutboundID(entry.ID, dest)
			if outboundIDs[id] {
				continue
			}
			strat := ext.ProtoToEngineStrategy(b.Strategy)
			// Mid-SNI marker: resolve against this binding's
			// domain now, while the target is known (see
			// resolveBindingMarker); unresolvable → skip.
			resolved, rok := resolveBindingMarker(strat, dest)
			if !rok {
				continue
			}
			strat = resolved
			outbound := engine.Outbound{
				ID: id, Name: extBypassOutboundName(b.Match),
				Protocol: engine.ProtocolBypass, Bypass: &strat,
			}
			// The outbound must stand on its own before it may
			// join the plan (M1c, the plan.go probe pattern): a
			// binding whose strategy or name is invalid is
			// skipped, never a reason to fail the user's plan.
			if err := outbound.Validate(); err != nil {
				continue
			}
			rule, err := ruleFromProto(&corev1.RoutingRule{Destination: dest, OutboundId: id})
			if err != nil {
				continue
			}
			plan.Outbounds = append(plan.Outbounds, outbound)
			outboundIDs[id] = true
			existing[dest] = true
			if prefix, dom, ok := bypassDestDomain(dest); ok && prefix == "domain:" {
				suffixDomains = append(suffixDomains, dom)
			}
			added = append(added, rule)
		}
	}
	if len(added) == 0 {
		return
	}
	merged := make([]engine.Rule, 0, len(plan.Rules)+len(added))
	merged = append(merged, plan.Rules[:insertAt]...)
	merged = append(merged, added...)
	merged = append(merged, plan.Rules[insertAt:]...)
	plan.Rules = merged
	if prov != nil {
		prov.Bindings += len(added)
	}
}

// resolveBindingMarker resolves a binding strategy's mid-SNI
// marker against the binding's own domain, with exactly the
// semantics the tuner uses (bypass.ResolveStrategy against the
// target SNI — here the binding destination IS the target). The
// marker is sora's own registry marker, not an executor position:
// the vendored zapret parsers (tpws and nfqws alike) accept only
// method/host/endhost/sld/midsld/endsld/sniext, so an unresolved
// marker must never reach a plan. A strategy without the marker
// passes through unchanged; a marker strategy whose destination is
// not a plain domain (or whose resolution fails) reports ok=false
// and the caller skips the binding — the layer store already refuses
// those at Apply, so this is the merge's defence in depth, in the
// same skip-never-fail spirit as the outbound probe (M1c).
func resolveBindingMarker(strat engine.BypassStrategy, dest string) (engine.BypassStrategy, bool) {
	has := strat.TLSRecord == bypass.MidSNIMarker
	for _, pos := range strat.SplitPos {
		if pos == bypass.MidSNIMarker {
			has = true
		}
	}
	if !has {
		return strat, true
	}
	_, dom, ok := bypassDestDomain(dest)
	if !ok {
		return engine.BypassStrategy{}, false
	}
	resolved, rok, err := bypass.ResolveStrategy(strat, dom, 0)
	if err != nil || !rok {
		return engine.BypassStrategy{}, false
	}
	return resolved, true
}

// bypassCapabilities adapts the wired capability source to the host
// dep. Unwired, it reports both backends unavailable with the reason,
// rather than guessing from the OS name.
func (s *Server) bypassCapabilities(ctx context.Context) (string, []ext.BackendState, error) {
	s.bypassMu.Lock()
	fn := s.bypassCapsFn
	s.bypassMu.Unlock()
	if fn == nil {
		reason := "the bypass capability probe is not wired in this core"
		return runtime.GOOS, []ext.BackendState{
			{Kind: "tpws", Available: false, Reason: reason},
			{Kind: "nfqws", Available: false, Reason: reason},
		}, nil
	}
	return fn(ctx)
}

// bypassPlatform reports the executor platform for state answers:
// the capability snapshot's platform when wired, else the OS name.
func (s *Server) bypassPlatform(ctx context.Context) string {
	platform, _, err := s.bypassCapabilities(ctx)
	if err != nil || platform == "" {
		return runtime.GOOS
	}
	return platform
}

// bypassState adapts the last built plan's provenance, the live
// session and the layer store to the host's GetBypassState dep.
func (s *Server) bypassState(ctx context.Context, extensionID string) (*ext.BypassStateInfo, error) {
	info := &ext.BypassStateInfo{
		Platform:     s.bypassPlatform(ctx),
		GlobalSource: "none",
	}
	info.SessionActive = s.sessions.Current() != nil
	// Read the fields directly under the lock: extLayerStore() locks
	// bypassMu itself, and sync.Mutex is not reentrant — calling it
	// here deadlocked GetBypassState (caught by the state test's
	// timeout, fixed before this ever shipped in a build).
	s.bypassMu.Lock()
	prov := s.bypassProv
	s.bypassMu.Unlock()
	// PendingApply: a layer that will change the next plan exists but
	// the last built plan predates it — either any provider layer, or
	// no plan was built at all while layers exist.
	//
	// Only the provider's layers count (L1): bypassLayers already
	// applies the enabled+granted bypass.write filter, and the
	// caller's own layer is part of that list exactly when it passes
	// the same filter as everyone else's. Reading the caller's layer
	// straight from the store here (as this once did) both counted a
	// disabled or ungranted extension's layer as pending — and, when
	// the caller did pass the filter, counted its layer twice.
	pending := func(layers []ext.LayerEntry, builtAt time.Time, hasPlan bool) bool {
		for _, e := range layers {
			if e.Layer.IsEmpty() {
				continue
			}
			if !hasPlan || e.Layer.UpdatedAt.After(builtAt) {
				return true
			}
		}
		return false
	}
	layers := s.bypassLayers()
	if prov == nil {
		info.PendingApply = pending(layers, time.Time{}, false)
		return info, nil
	}
	info.GlobalSource = prov.Source
	info.GlobalFrom = prov.From
	info.BindingsCount = prov.Bindings
	info.PendingApply = pending(layers, prov.BuiltAt, true)
	return info, nil
}

// tuneDesyncForExt adapts the control plane's desync tuner to the
// host's TuneDesync dep: same engine vocabulary and the same run core
// as the censor RPC (runDesyncTune), with the winner resolved back to
// a contract strategy.
func (s *Server) tuneDesyncForExt(ctx context.Context, engineName string) (*ext.TuneOutcome, error) {
	engineName = strings.TrimSpace(engineName)
	switch engineName {
	case "":
		engineName = "nfqws"
	case "nfqws", "tpws":
	default:
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: desync engine %q is not \"nfqws\" or \"tpws\"", engineName)
	}
	res, err := s.runDesyncTune(ctx, engineName)
	if err != nil {
		return nil, err
	}
	out := &ext.TuneOutcome{
		WinnerID:       res.WinnerID,
		WinnerDescribe: res.WinnerDescribe,
		Score:          res.Score,
		Attempts:       res.Attempts,
	}
	if res.HasWinner {
		out.Strategy = winnerStrategy(res)
	}
	return out, nil
}

// winnerStrategy resolves a tuner winner to its contract strategy.
// The winner id is either a registry profile id — resolved through
// desync.LookupProfile, with registry markers resolved against the
// blocked canary exactly as the tuner resolved them before probing —
// or a genome id ("d/..."), whose genome the run result already
// carries verbatim (WinnerParams), so no ID parsing is needed. A
// genome with no faithful strategy rendering yields nil: the caller
// reports has_strategy=false and keeps the other fields honest.
func winnerStrategy(res *desyncTuneResult) *corev1.BypassStrategy {
	if prof, ok := desync.LookupProfile(res.WinnerID); ok {
		if params, err := prof.ResolveFor(desync.BlockedCanary.SNI); err == nil {
			if strat, ok := params.BypassStrategy(); ok {
				return ext.EngineToProtoStrategy(strat)
			}
		}
		if strat, ok := prof.Params.BypassStrategy(); ok {
			return ext.EngineToProtoStrategy(strat)
		}
	}
	if strat, ok := res.WinnerParams.BypassStrategy(); ok {
		return ext.EngineToProtoStrategy(strat)
	}
	return nil
}

// watchBypassEvents adapts the live session's journal to the host's
// WatchBypassEvents dep, with the same no-session refusal as the
// WatchEvents dep. Only censorship verdicts and session state changes
// are forwarded: those are the events an Anti-DPI panel acts on. The
// journal produces no strategy-change events today, so the "strategy"
// kind is never synthesized.
func (s *Server) watchBypassEvents(ctx context.Context) (<-chan ext.BypassEvent, error) {
	running := s.sessions.Current()
	if running == nil {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"control: bypass event watch needs an active session")
	}
	live, unsub := running.Journal().Subscribe(64)
	out := make(chan ext.BypassEvent, 64)
	go func() {
		defer close(out)
		defer unsub()
		for {
			select {
			case <-ctx.Done():
				return
			case ev, ok := <-live:
				if !ok {
					return
				}
				bev, keep := bypassEventOf(ev)
				if !keep {
					continue
				}
				select {
				case out <- bev:
				case <-ctx.Done():
					return
				}
			}
		}
	}()
	return out, nil
}

// bypassEventOf translates one journal event into the bypass event
// vocabulary, reporting whether the event is bypass-relevant at all.
func bypassEventOf(ev session.Event) (ext.BypassEvent, bool) {
	switch ev.Kind {
	case session.EventCensor:
		out := ext.BypassEvent{Kind: "censorship", Explanation: ev.Detail, At: ev.At}
		if ev.Censor != nil {
			out.CensorshipKind = ev.Censor.Kind.String()
			out.Explanation = ev.Censor.Explanation
		}
		return out, true
	case session.EventState:
		return ext.BypassEvent{Kind: "session", Explanation: ev.Detail, At: ev.At}, true
	}
	return ext.BypassEvent{}, false
}
