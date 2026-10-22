package guard

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/session"
)

func TestStrictOLCRTCUsesOnlyTheServiceAccountForDynamicICE(t *testing.T) {
	policy := session.Settings{StrictKillSwitch: true, OLCRTC: true}
	rules := StrictNftRuleset(987, policy)
	required := "meta skuid 987 accept comment \"sora: olcrtc provider and ICE\""
	if !strings.Contains(rules, required) || strings.Contains(rules, "meta skuid 0 accept") || !strings.Contains(rules, "counter drop comment \"sora: kill switch\"") {
		t.Fatal("carrier exemption widened beyond service UID")
	}
	policy.OLCRTC = false
	if strings.Contains(StrictNftRuleset(987, policy), required) {
		t.Fatal("carrier exemption survived engine change")
	}
}

func TestOLCRTCStrictRecoveryRetainsProviderPolicy(t *testing.T) {
	dir := t.TempDir()
	f := &intentFirewall{}
	first, err := New(Options{DataDir: dir, EnginePorts: []uint16{7890}}, f)
	if err != nil {
		t.Fatal(err)
	}
	if err := first.Apply(t.Context(), session.Settings{StrictKillSwitch: true, OLCRTC: true}); err != nil {
		t.Fatal(err)
	}
	recovered, err := New(Options{DataDir: dir, EnginePorts: []uint16{7890}}, f)
	if err != nil {
		t.Fatal(err)
	}
	if err := recovered.Recover(t.Context()); err != nil {
		t.Fatal(err)
	}
	if !f.policy.OLCRTC {
		t.Fatal("recovery dropped provider traffic policy")
	}
	if err := recovered.Release(t.Context()); err != nil {
		t.Fatal(err)
	}
}
