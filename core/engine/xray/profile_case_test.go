package xray

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestProfileFileKeyAliasesAreRemovedFromSessionsAndProbes(t *testing.T) {
	for _, key := range []string{
		"masterKeyLog", "MasterKeyLog", "MASTERKEYLOG", "masterkeylog", "maſterKeyLog",
		"certificateFile", "CertificateFile", "CERTIFICATEFILE", "certificatefile",
		"keyFile", "KeyFile", "KEYFILE", "keyfile", "KeyFile",
	} {
		t.Run(key, func(t *testing.T) {
			plan := profilePlan(false)
			var cfg map[string]any
			if err := json.Unmarshal(plan.Outbounds[0].Profile, &cfg); err != nil {
				t.Fatal(err)
			}
			stream := cfg["outbounds"].([]any)[0].(map[string]any)["streamSettings"].(map[string]any)
			stream["tlsSettings"] = map[string]any{key: "/fixture/forbidden-path", "certificates": []any{map[string]any{key: "/fixture/forbidden-path"}}}
			stream["realitySettings"].(map[string]any)[key] = "/fixture/forbidden-path"
			raw, err := json.Marshal(cfg)
			if err != nil {
				t.Fatal(err)
			}
			plan.Outbounds[0].Profile = raw
			session, err := Render(plan, supervise.Runtime{LocalPort: 4000}, nil)
			if err != nil {
				t.Fatal(err)
			}
			outbounds, _, err := probeProfile(plan.Outbounds[0], 0)
			if err != nil {
				t.Fatal(err)
			}
			probe, err := json.Marshal(outbounds)
			if err != nil {
				t.Fatal(err)
			}
			for stage, output := range map[string][]byte{"session": session, "probe": probe} {
				if strings.Contains(string(output), "/fixture/forbidden-path") {
					t.Errorf("%s accepted a prohibited file key alias", stage)
				}
			}
		})
	}
}

func TestProfileOwnedKeyAliasesCannotSurviveSessionRendering(t *testing.T) {
	for _, key := range []string{"Inbounds", "LOG", "Api", "Stats", "Metrics", "Policy", "Remarks", "Meta", "Reverse", "Reverſe", "ſtats"} {
		t.Run(key, func(t *testing.T) {
			plan := profilePlan(false)
			var cfg map[string]any
			if err := json.Unmarshal(plan.Outbounds[0].Profile, &cfg); err != nil {
				t.Fatal(err)
			}
			cfg[key] = "fixture-provider-owned-setting"
			raw, err := json.Marshal(cfg)
			if err != nil {
				t.Fatal(err)
			}
			plan.Outbounds[0].Profile = raw
			output, err := Render(plan, supervise.Runtime{LocalPort: 4000}, nil)
			if err != nil {
				t.Fatal(err)
			}
			if strings.Contains(string(output), "fixture-provider-owned-setting") {
				t.Fatal("provider-owned setting bypassed replacement by a key alias")
			}
		})
	}
}
