package engine

import (
	"strings"
	"testing"
)

func chainPlan() *Plan {
	p := validPlan()
	p.Outbounds = append(p.Outbounds,
		Outbound{ID: "c", Name: "C", Protocol: ProtocolShadowsocks, Server: "c.example.com", Port: 8388, Password: "pw", Cipher: "aes-256-gcm"},
	)
	return p
}

func TestChainValidationAcceptsTwoAndThreeHops(t *testing.T) {
	for _, via := range []map[string]string{
		{"a": "b"},                 // two hops
		{"a": "b", "b": "c"},       // three hops
		{"c": "a", "a": "b"},       // three hops, entry last in list
	} {
		plan := chainPlan()
		for i := range plan.Outbounds {
			if v, ok := via[plan.Outbounds[i].ID]; ok {
				plan.Outbounds[i].Via = v
			}
		}
		if err := plan.Validate(); err != nil {
			t.Errorf("chain %v rejected: %v", via, err)
		}
		if !plan.RequiredFeatures()[FeatureChains] {
			t.Errorf("chain %v must require the chains feature", via)
		}
	}
}

func TestChainValidationRejectsBadChains(t *testing.T) {
	cases := []struct {
		name string
		via  map[string]string
		want string
	}{
		{"unknown hop", map[string]string{"a": "ghost"}, "unknown outbound"},
		{"self link", map[string]string{"a": "a"}, "itself"},
		{"two-cycle", map[string]string{"a": "b", "b": "a"}, "loops back"},
		{"three-cycle", map[string]string{"a": "b", "b": "c", "c": "a"}, "loops back"},
		{"four hops", map[string]string{"a": "b", "b": "c"}, "longer than 3 hops"},
		{"direct cannot chain", map[string]string{}, "cannot dial through another"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			plan := chainPlan()
			if tc.name == "four hops" {
				plan.Outbounds = append(plan.Outbounds,
					Outbound{ID: "d", Name: "D", Protocol: ProtocolTrojan, Server: "d.example.com", Port: 443, Password: "pw"})
				plan.Outbounds[2].Via = "d"
			}
			for i := range plan.Outbounds {
				if v, ok := tc.via[plan.Outbounds[i].ID]; ok {
					plan.Outbounds[i].Via = v
				}
			}
			if tc.name == "direct cannot chain" {
				plan.Outbounds = append(plan.Outbounds,
					Outbound{ID: "dir", Name: "dir", Protocol: ProtocolDirect, Via: "a"})
			}
			err := plan.Validate()
			if err == nil {
				t.Fatalf("chain %v must not validate", tc.via)
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Errorf("error should mention %q, got: %v", tc.want, err)
			}
		})
	}
}

func TestChainlessPlanNeedsNoChainsFeature(t *testing.T) {
	if validPlan().RequiredFeatures()[FeatureChains] {
		t.Error("a plan without Via links must not require the chains feature")
	}
}
