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

// TestPlanFromProtoZapretStrategyDefaults: an absent strategy selects the
// core default, not an empty strategy.
func TestPlanFromProtoZapretStrategyDefaults(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("zapret_with_vpn is Linux-only")
	}
	in := chainTestPlan()
	in.ZapretWithVpn = true
	plan, err := planFromProto(in, "s-1", nil)
	if err != nil {
		t.Fatalf("planFromProto: %v", err)
	}
	zb := zapretTestOutbound(t, plan)
	if zb.Bypass == nil || !reflect.DeepEqual(*zb.Bypass, defaultZapretStrategy) {
		t.Fatalf("zapret strategy = %+v, want default %+v", zb.Bypass, defaultZapretStrategy)
	}
}
