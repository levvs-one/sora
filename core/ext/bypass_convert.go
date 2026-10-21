package ext

import (
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// Conversions between the contract BypassStrategy (sora.core.v1) and the
// engine strategy. The proto→engine direction mirrors
// core/control's bypassStrategyFromProto field for field: the ext package
// may not import core/control (control imports ext), so the conversion
// lives here next to the layer store that validates with it, and the
// drift risk is pinned by the round-trip test
// (TestBypassStrategyConversionRoundTrip) over every field. The contract
// carries no auto_ttl_delta, so an engine strategy's AutoTTLDelta does
// not survive the trip to the wire — it is always zero for strategies
// that come from a genome (core/tune/desync) or a plan request, the only
// producers that reach this converter.

// ProtoToEngineStrategy maps every contract field onto the engine
// strategy. A nil strategy maps to the zero strategy.
func ProtoToEngineStrategy(p *corev1.BypassStrategy) engine.BypassStrategy {
	return engine.BypassStrategy{
		SplitPos:         append([]string(nil), p.GetSplitPos()...),
		Disorder:         p.GetDisorder(),
		DisorderScope:    p.GetDisorderScope(),
		OOB:              p.GetOob(),
		OOBScope:         p.GetOobScope(),
		TLSRecord:        p.GetTlsRecord(),
		HostCase:         p.GetHostCase(),
		DomainCase:       p.GetDomainCase(),
		MethodEOL:        p.GetMethodEol(),
		HostDot:          p.GetHostDot(),
		HostTab:          p.GetHostTab(),
		HostNoSpace:      p.GetHostNoSpace(),
		MethodSpace:      p.GetMethodSpace(),
		UnixEOL:          p.GetUnixEol(),
		SplitAnyProtocol: p.GetSplitAnyProtocol(),
		TamperStart:      p.GetTamperStart(),
		TamperCutoff:     p.GetTamperCutoff(),
		OOBData:          p.GetOobData(),
		MSS:              p.GetMss(),
		Desync:           append([]string(nil), p.GetDesync()...),
		FakeTLS:          p.GetFakeTls(),
		FakeQUIC:         p.GetFakeQuic(),
		Fooling:          p.GetFooling(),
		TTL:              int(p.GetTtl()),
		AutoTTL:          p.GetAutoTtl(),
		Repeats:          int(p.GetRepeats()),
		FilterTCP:        p.GetFilterTcp(),
		FilterUDP:        p.GetFilterUdp(),
		FilterL7:         p.GetFilterL7(),
	}
}

// EngineToProtoStrategy maps an engine strategy onto the contract.
func EngineToProtoStrategy(s engine.BypassStrategy) *corev1.BypassStrategy {
	return &corev1.BypassStrategy{
		SplitPos:         append([]string(nil), s.SplitPos...),
		Disorder:         s.Disorder,
		DisorderScope:    s.DisorderScope,
		Oob:              s.OOB,
		OobScope:         s.OOBScope,
		TlsRecord:        s.TLSRecord,
		HostCase:         s.HostCase,
		DomainCase:       s.DomainCase,
		MethodEol:        s.MethodEOL,
		HostDot:          s.HostDot,
		HostTab:          s.HostTab,
		HostNoSpace:      s.HostNoSpace,
		MethodSpace:      s.MethodSpace,
		UnixEol:          s.UnixEOL,
		SplitAnyProtocol: s.SplitAnyProtocol,
		TamperStart:      s.TamperStart,
		TamperCutoff:     s.TamperCutoff,
		OobData:          s.OOBData,
		Mss:              s.MSS,
		Desync:           append([]string(nil), s.Desync...),
		FakeTls:          s.FakeTLS,
		FakeQuic:         s.FakeQUIC,
		Fooling:          s.Fooling,
		Ttl:              int32(s.TTL), //nolint:gosec // validated to 0..255 before a strategy reaches here
		AutoTtl:          s.AutoTTL,
		Repeats:          int32(s.Repeats), //nolint:gosec // validated to 0..16 before a strategy reaches here
		FilterTcp:        s.FilterTCP,
		FilterUdp:        s.FilterUDP,
		FilterL7:         s.FilterL7,
	}
}

// ValidateBypassStrategy checks one contract strategy with exactly the
// rules a plan applies to a bypass outbound (core/engine strategy
// validation, reached through a probe outbound in core/control's
// planFromProto): a strategy that changes nothing, mixes tpws-only
// knobs into an nfqws strategy, or names an unknown desync method is
// refused. Nil is refused: a binding or a global that is present must
// carry a strategy.
func ValidateBypassStrategy(p *corev1.BypassStrategy) error {
	if p == nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid,
			"ext: a bypass layer entry carries no strategy")
	}
	return validateEngineStrategy(ProtoToEngineStrategy(p))
}

// validateEngineStrategy runs the probe-outbound validation over an
// engine-form strategy (see ValidateBypassStrategy).
func validateEngineStrategy(s engine.BypassStrategy) error {
	probe := engine.Outbound{ID: "bypass-layer", Protocol: engine.ProtocolBypass, Bypass: &s}
	if err := probe.Validate(); err != nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid,
			"ext: the bypass strategy is invalid: %v", err)
	}
	return nil
}

// midSNIMarker spells core/engine/bypass.MidSNIMarker ("midsni"), the
// registry-level split position meaning "the middle of the actual SNI
// hostname". It is deliberately NOT a native executor position:
// parse_posmarker in the vendored zapret sources (tpws.c and nfqws.c
// alike) accepts exactly method/host/endhost/sld/midsld/endsld/
// sniext, and the shipped tpws binary refuses --split-pos=midsni at
// parse time (probed on the Wave-B dist binary) — midsld is a
// different position (the middle of the second-level domain only),
// so the marker is never translated to it. A strategy carrying the
// marker is only ever valid where a concrete target domain exists to
// resolve it against (bypass.ResolveStrategy), which for layers
// means a binding to a plain domain: the plan merge resolves it
// against the binding's domain (core/control mergeBypassBindings).
const midSNIMarker = "midsni"

// strategyHasMidSNI reports whether a contract strategy carries the
// mid-SNI marker in a split position or the TLS-record position —
// the two slots ResolveStrategy resolves.
func strategyHasMidSNI(p *corev1.BypassStrategy) bool {
	for _, pos := range p.GetSplitPos() {
		if pos == midSNIMarker {
			return true
		}
	}
	return p.GetTlsRecord() == midSNIMarker
}

// ValidateBypassBindingStrategy validates one binding's strategy in
// the scope of its match. It is ValidateBypassStrategy plus the
// mid-SNI marker rule: a strategy carrying the marker is accepted
// only when the match names a concrete domain the plan merge can
// resolve the marker against (see matchResolvesMidSNI in
// bypass_layer.go); in that case every other rule is still checked,
// with the marker provisionally replaced by a concrete position —
// the real resolution happens at merge time, against the binding's
// canonical domain. A marker strategy on any other match (and in a
// layer's global, which uses ValidateBypassStrategy) is refused:
// there is no honest target to resolve it against.
func ValidateBypassBindingStrategy(match string, p *corev1.BypassStrategy) error {
	if p == nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid,
			"ext: a bypass layer entry carries no strategy")
	}
	if !strategyHasMidSNI(p) {
		return ValidateBypassStrategy(p)
	}
	if !matchResolvesMidSNI(match) {
		return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid,
			"ext: the bypass strategy uses the %q split marker, which resolves against a concrete domain: "+
				"it is only valid on a binding to a plain domain (domain:/full:/bare), not on %q",
			midSNIMarker, match)
	}
	s := ProtoToEngineStrategy(p)
	for i, pos := range s.SplitPos {
		if pos == midSNIMarker {
			s.SplitPos[i] = "1"
		}
	}
	if s.TLSRecord == midSNIMarker {
		s.TLSRecord = "1"
	}
	return validateEngineStrategy(s)
}

// IsEmptyBypassStrategy reports whether a contract strategy carries no
// field at all (nil included): it shapes nothing, so plan code treats
// it as "no strategy given".
func IsEmptyBypassStrategy(p *corev1.BypassStrategy) bool {
	if p == nil {
		return true
	}
	s := ProtoToEngineStrategy(p)
	return len(s.SplitPos) == 0 && len(s.Desync) == 0 &&
		!s.Disorder && !s.OOB && s.TLSRecord == "" &&
		!s.HostCase && !s.DomainCase && !s.MethodEOL &&
		!s.HostDot && !s.HostTab && !s.HostNoSpace && !s.MethodSpace && !s.UnixEOL &&
		!s.SplitAnyProtocol && s.TamperStart == "" && s.TamperCutoff == "" &&
		s.OOBData == "" && s.MSS == "" && s.FakeTLS == "" && s.FakeQUIC == "" &&
		s.Fooling == "" && s.TTL == 0 && !s.AutoTTL && s.AutoTTLDelta == 0 &&
		s.Repeats == 0 && s.FilterTCP == "" && s.FilterUDP == "" && s.FilterL7 == "" &&
		s.DisorderScope == "" && s.OOBScope == ""
}
