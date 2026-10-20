package control

import (
	"reflect"
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// minimalPlan is the smallest plan planFromProto accepts.
func minimalPlan() *corev1.SessionPlan {
	return &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
		Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
	}
}

// TestPlanFromProtoRejectsUnimplementedFields: contract fields the core does
// not implement must fail closed instead of being silently dropped.
func TestPlanFromProtoRejectsUnimplementedFields(t *testing.T) {
	for name, mutate := range map[string]func(*corev1.SessionPlan){
		"session_identity": func(in *corev1.SessionPlan) { in.SessionIdentity = "phone-1" },
		"block_private": func(in *corev1.SessionPlan) {
			in.DnsPolicy = &corev1.DnsPolicy{BlockPrivate: true}
		},
	} {
		t.Run(name, func(t *testing.T) {
			in := minimalPlan()
			mutate(in)
			if _, err := planFromProto(in, "s-1", nil); err == nil {
				t.Fatalf("%s must be rejected: the core does not implement it", name)
			}
		})
	}
}

// TestPlanFromProtoAcceptsUnsetUnimplementedFields: the zero values keep
// working — only an explicit request for an unimplemented field fails.
func TestPlanFromProtoAcceptsUnsetUnimplementedFields(t *testing.T) {
	in := minimalPlan()
	in.SessionIdentity = "  "
	in.DnsPolicy = &corev1.DnsPolicy{Servers: []string{"https://1.1.1.1/dns-query"}}
	if _, err := planFromProto(in, "s-1", nil); err != nil {
		t.Fatalf("planFromProto: %v", err)
	}
}

// zapretTestOutbound returns the synthetic zapret outbound of a built plan.
func zapretTestOutbound(t *testing.T, plan *engine.Plan) *engine.Outbound {
	t.Helper()
	for i := range plan.Outbounds {
		if plan.Outbounds[i].ID == zapretDirectOutboundID {
			return &plan.Outbounds[i]
		}
	}
	t.Fatal("no zapret bypass outbound was added")
	return nil
}

// TestPlanFromProtoMapsZapretStrategy: every zapret_strategy field reaches the
// synthetic bypass outbound; none is silently dropped or defaulted.
func TestPlanFromProtoMapsZapretStrategy(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("zapret_with_vpn is Linux-only")
	}
	in := chainTestPlan()
	in.ZapretWithVpn = true
	in.ZapretStrategy = &corev1.BypassStrategy{
		SplitPos: []string{"1", "2"}, Disorder: true, Oob: true,
		TlsRecord: "2", HostCase: true, DomainCase: true, MethodEol: true,
	}
	plan, err := planFromProto(in, "s-1", nil)
	if err != nil {
		t.Fatalf("planFromProto: %v", err)
	}
	zb := zapretTestOutbound(t, plan)
	if zb.Bypass == nil {
		t.Fatal("zapret outbound carries no strategy")
	}
	want := engine.BypassStrategy{
		SplitPos: []string{"1", "2"}, Disorder: true, OOB: true,
		TLSRecord: "2", HostCase: true, DomainCase: true, MethodEOL: true,
	}
	if !reflect.DeepEqual(*zb.Bypass, want) {
		t.Fatalf("zapret strategy = %+v, want %+v", *zb.Bypass, want)
	}
}

// TestPlanFromProtoZapretWithoutStrategyUsesTheDefault: an absent
// strategy is no longer refused — the nfqws executor landed, so the
// core's built-in default (the modern nfqws desync set) is applied at
// plan time and runs at Apply. The full behavior is pinned by
// TestPlanFromProtoZapretWithVPNDefaultStrategy; this keeps the
// no-strategy entry point itself under test.
func TestPlanFromProtoZapretWithoutStrategyUsesTheDefault(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("zapret_with_vpn is Linux-only")
	}
	in := chainTestPlan()
	in.ZapretWithVpn = true
	plan, err := planFromProto(in, "s-1", nil)
	if err != nil {
		t.Fatalf("zapret_with_vpn without a strategy must build the default plan, got %v", err)
	}
	for i := range plan.Outbounds {
		if plan.Outbounds[i].ID == zapretDirectOutboundID && plan.Outbounds[i].Bypass != nil &&
			len(plan.Outbounds[i].Bypass.Desync) > 0 {
			return
		}
	}
	t.Fatal("the plan carries no zapret outbound with the nfqws default strategy")
}

// fullProtoBypass is a BypassStrategy with every one of the 29 contract
// fields set to a distinct, recognizable value.
func fullProtoBypass() *corev1.BypassStrategy {
	return &corev1.BypassStrategy{
		SplitPos: []string{"1", "midsld"}, Disorder: true, DisorderScope: "tls",
		Oob: true, OobScope: "http", TlsRecord: "2",
		HostCase: true, DomainCase: true, MethodEol: true,
		HostDot: true, HostTab: true, HostNoSpace: true, MethodSpace: true,
		UnixEol: true, SplitAnyProtocol: true,
		TamperStart: "n1", TamperCutoff: "10", OobData: "0x41", Mss: "1200",
		Desync: []string{"fake", "split2"}, FakeTls: "tls", FakeQuic: "quic.bin",
		Fooling: "badseq", Ttl: 8, AutoTtl: true, Repeats: 3,
		FilterTcp: "80,443", FilterUdp: "443", FilterL7: "tls,quic",
	}
}

// fullEngineBypass is the engine strategy fullProtoBypass must map to,
// field for field.
func fullEngineBypass() engine.BypassStrategy {
	return engine.BypassStrategy{
		SplitPos: []string{"1", "midsld"}, Disorder: true, DisorderScope: "tls",
		OOB: true, OOBScope: "http", TLSRecord: "2",
		HostCase: true, DomainCase: true, MethodEOL: true,
		HostDot: true, HostTab: true, HostNoSpace: true, MethodSpace: true,
		UnixEOL: true, SplitAnyProtocol: true,
		TamperStart: "n1", TamperCutoff: "10", OOBData: "0x41", MSS: "1200",
		Desync: []string{"fake", "split2"}, FakeTLS: "tls", FakeQUIC: "quic.bin",
		Fooling: "badseq", TTL: 8, AutoTTL: true, Repeats: 3,
		FilterTCP: "80,443", FilterUDP: "443", FilterL7: "tls,quic",
	}
}

// TestBypassStrategyFromProtoMapsEveryField: the contract carries all 29
// engine fields; the conversion must carry every one of them, by name —
// a field dropped here is a strategy knob the UI can set but the core
// silently ignores.
func TestBypassStrategyFromProtoMapsEveryField(t *testing.T) {
	got := bypassStrategyFromProto(fullProtoBypass())
	if want := fullEngineBypass(); !reflect.DeepEqual(got, want) {
		t.Fatalf("bypassStrategyFromProto = %+v, want %+v", got, want)
	}
}

// TestBypassStrategyFromProtoEmptyIsZero: an empty (or absent) contract
// strategy is the zero engine strategy — no field defaults on the way.
func TestBypassStrategyFromProtoEmptyIsZero(t *testing.T) {
	for name, in := range map[string]*corev1.BypassStrategy{
		"empty": {},
		"nil":   nil,
	} {
		if got := bypassStrategyFromProto(in); !reflect.DeepEqual(got, engine.BypassStrategy{}) {
			t.Fatalf("%s: bypassStrategyFromProto = %+v, want the zero strategy", name, got)
		}
	}
}

// TestPlanFromProtoMapsFullOutboundBypass: end to end through
// outboundFromProto, a per-outbound bypass keeps the full tpws field set
// and the full nfqws field set. The two sets are exercised by separate
// strategies because plan validation refuses to mix them (nfqws does
// not render the tpws-only knobs, and ttl excludes auto_ttl).
func TestPlanFromProtoMapsFullOutboundBypass(t *testing.T) {
	tpws := &corev1.BypassStrategy{
		SplitPos: []string{"1", "midsld"}, Disorder: true, DisorderScope: "tls",
		Oob: true, OobScope: "http", TlsRecord: "2",
		HostCase: true, DomainCase: true, MethodEol: true,
		HostDot: true, HostTab: true, HostNoSpace: true, MethodSpace: true,
		UnixEol: true, SplitAnyProtocol: true,
		TamperStart: "n1", TamperCutoff: "10", OobData: "0x41", Mss: "1200",
	}
	wantTPWS := engine.BypassStrategy{
		SplitPos: []string{"1", "midsld"}, Disorder: true, DisorderScope: "tls",
		OOB: true, OOBScope: "http", TLSRecord: "2",
		HostCase: true, DomainCase: true, MethodEOL: true,
		HostDot: true, HostTab: true, HostNoSpace: true, MethodSpace: true,
		UnixEOL: true, SplitAnyProtocol: true,
		TamperStart: "n1", TamperCutoff: "10", OOBData: "0x41", MSS: "1200",
	}
	nfqws := &corev1.BypassStrategy{
		SplitPos: []string{"1"}, Desync: []string{"fake", "split2"},
		FakeTls: "tls", FakeQuic: "quic.bin", Fooling: "badseq",
		Ttl: 8, Repeats: 3,
		FilterTcp: "80,443", FilterUdp: "443", FilterL7: "tls,quic",
	}
	wantNFQWS := engine.BypassStrategy{
		SplitPos: []string{"1"}, Desync: []string{"fake", "split2"},
		FakeTLS: "tls", FakeQUIC: "quic.bin", Fooling: "badseq",
		TTL: 8, Repeats: 3,
		FilterTCP: "80,443", FilterUDP: "443", FilterL7: "tls,quic",
	}
	autoTTL := &corev1.BypassStrategy{
		SplitPos: []string{"1"}, Desync: []string{"fake"}, AutoTtl: true,
		FilterUdp: "443",
	}
	wantAutoTTL := engine.BypassStrategy{
		SplitPos: []string{"1"}, Desync: []string{"fake"}, AutoTTL: true,
		FilterUDP: "443",
	}
	for name, tc := range map[string]struct {
		in   *corev1.BypassStrategy
		want engine.BypassStrategy
	}{
		"tpws":    {tpws, wantTPWS},
		"nfqws":   {nfqws, wantNFQWS},
		"autoTTL": {autoTTL, wantAutoTTL},
	} {
		t.Run(name, func(t *testing.T) {
			in := &corev1.SessionPlan{
				TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
				Outbounds: []*corev1.OutboundSpec{
					{Id: "zapret", Protocol: "bypass", Bypass: tc.in},
				},
				Routes: []*corev1.RoutingRule{{Destination: "geosite:youtube", OutboundId: "zapret"}},
			}
			plan, err := planFromProto(in, "s-1", nil)
			if err != nil {
				t.Fatalf("planFromProto: %v", err)
			}
			got := plan.Outbounds[0].Bypass
			if got == nil {
				t.Fatal("bypass outbound carries no strategy")
			}
			if !reflect.DeepEqual(*got, tc.want) {
				t.Fatalf("outbound bypass = %+v, want %+v", *got, tc.want)
			}
		})
	}
}

// TestPlanFromProtoMapsFullZapretStrategy: the zapret_strategy call site
// uses the same conversion, so the full tpws field set reaches the
// synthetic zapret outbound too.
func TestPlanFromProtoMapsFullZapretStrategy(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("zapret_with_vpn is Linux-only")
	}
	in := chainTestPlan()
	in.ZapretWithVpn = true
	in.ZapretStrategy = &corev1.BypassStrategy{
		SplitPos: []string{"1", "midsld"}, Disorder: true, DisorderScope: "tls",
		Oob: true, OobScope: "http", TlsRecord: "2",
		HostCase: true, DomainCase: true, MethodEol: true,
		HostDot: true, HostTab: true, HostNoSpace: true, MethodSpace: true,
		UnixEol: true, SplitAnyProtocol: true,
		TamperStart: "n1", TamperCutoff: "10", OobData: "0x41", Mss: "1200",
	}
	plan, err := planFromProto(in, "s-1", nil)
	if err != nil {
		t.Fatalf("planFromProto: %v", err)
	}
	zb := zapretTestOutbound(t, plan)
	if zb.Bypass == nil {
		t.Fatal("zapret outbound carries no strategy")
	}
	want := engine.BypassStrategy{
		SplitPos: []string{"1", "midsld"}, Disorder: true, DisorderScope: "tls",
		OOB: true, OOBScope: "http", TLSRecord: "2",
		HostCase: true, DomainCase: true, MethodEOL: true,
		HostDot: true, HostTab: true, HostNoSpace: true, MethodSpace: true,
		UnixEOL: true, SplitAnyProtocol: true,
		TamperStart: "n1", TamperCutoff: "10", OOBData: "0x41", MSS: "1200",
	}
	if !reflect.DeepEqual(*zb.Bypass, want) {
		t.Fatalf("zapret strategy = %+v, want %+v", *zb.Bypass, want)
	}
}
