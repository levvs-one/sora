package control

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// TestHijacksDNSHonorsTheRealRenderConditions locks the honest hijack
// signal: sing-box renders hijack-dns unconditionally and mihomo's TUN
// renders dns-hijack by default, both only when the plan runs a TUN
// (system mode). DNS.HijackTun is nothing in production ever fills, so
// it must not decide.
func TestHijacksDNSHonorsTheRealRenderConditions(t *testing.T) {
	tun := &engine.Plan{Tun: engine.Tun{Enabled: true}}
	for _, tc := range []struct {
		name string
		mode string
		plan *engine.Plan
		want bool
	}{
		{"system mode with TUN is hijacked", "system", tun, true},
		{"application mode never hijacks", "application", tun, false},
		{"system mode without TUN is not hijacked", "system", &engine.Plan{Tun: engine.Tun{Enabled: false}}, false},
		{"nil plan never hijacks", "system", nil, false},
		{"empty tunnel mode is not hijacked", "", tun, false},
	} {
		if got := hijacksDNS(tc.mode, tc.plan); got != tc.want {
			t.Errorf("%s: hijacksDNS(%q) = %v, want %v", tc.name, tc.mode, got, tc.want)
		}
	}
}

// TestHijacksDNSIgnoresTheEmptyHijackTunField is the negative case that
// killed the self-test: an empty DNS.HijackTun in system mode must still
// count as hijacked, or system-resolvers fails spuriously without a kill
// switch.
func TestHijacksDNSIgnoresTheEmptyHijackTunField(t *testing.T) {
	plan := &engine.Plan{Tun: engine.Tun{Enabled: true}, DNS: engine.DNS{}}
	if !hijacksDNS("system", plan) {
		t.Error("system mode with empty DNS.HijackTun must still count as hijacked")
	}
}
