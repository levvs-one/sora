package control

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestIPDestinationsBuildValidatedPlans(t *testing.T) {
	for _, tc := range []struct {
		destination, value string
		kind               engine.RuleType
	}{
		{"1.2.3.4", "1.2.3.4/32", engine.RuleIPCIDR},
		{"2001:db8::1", "2001:db8::1/128", engine.RuleIPCIDR},
		{"::1", "::1/128", engine.RuleIPCIDR},
		{"::ffff:192.0.2.1", "::ffff:192.0.2.1/128", engine.RuleIPCIDR},
		{" 1.2.3.4 ", "1.2.3.4/32", engine.RuleIPCIDR},
		{"10.0.0.0/8", "10.0.0.0/8", engine.RuleIPCIDR},
		{"2001:db8::/32", "2001:db8::/32", engine.RuleIPCIDR},
		{"443", "443", engine.RulePort},
	} {
		t.Run(tc.destination, func(t *testing.T) {
			plan, err := planFromProto(&corev1.SessionPlan{
				TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
				Outbounds:  []*corev1.OutboundSpec{{Id: "out", Protocol: "direct"}},
				Routes:     []*corev1.RoutingRule{{Destination: tc.destination, OutboundId: "out"}},
			}, "ip-rules", nil)
			if err != nil {
				t.Fatal(err)
			}
			if err := plan.Validate(); err != nil {
				t.Fatal(err)
			}
			want := engine.Rule{Type: tc.kind, Value: tc.value, Target: "out"}
			if got := plan.Rules[0]; got != want {
				t.Errorf("rule = %+v, want %+v", got, want)
			}
		})
	}
	for _, invalid := range []string{"1.2.3.4/33", "2001:db8::1/129", "bad/24", "fe80::1%eth0"} {
		t.Run(invalid, func(t *testing.T) {
			_, err := planFromProto(&corev1.SessionPlan{
				TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
				Outbounds:  []*corev1.OutboundSpec{{Id: "out", Protocol: "direct"}},
				Routes:     []*corev1.RoutingRule{{Destination: invalid, OutboundId: "out"}},
			}, "ip-rules", nil)
			if err == nil {
				t.Fatal("invalid destination accepted")
			}
		})
	}
}
