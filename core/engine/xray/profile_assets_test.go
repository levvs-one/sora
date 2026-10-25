package xray

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestProfileCannotPassExternalAssetPathsToTheEngine(t *testing.T) {
	for name, section := range map[string]map[string]any{
		"routing-domain":           {"routing": map[string]any{"rules": []any{map[string]any{"domain": []string{"ext:../fixture-outside.dat:ZZ"}, "outboundTag": "auto-a"}}}},
		"routing-domain-qualified": {"routing": map[string]any{"rules": []any{map[string]any{"domains": []string{"ext-domain:../../fixture-outside.dat:ZZ"}, "outboundTag": "auto-a"}}}},
		"routing-ip":               {"routing": map[string]any{"rules": []any{map[string]any{"ip": []string{"ext-ip:../fixture-outside.dat:ZZ"}, "outboundTag": "auto-a"}}}},
		"dns-hosts":                {"dns": map[string]any{"hosts": map[string]any{"ext:../fixture-outside.dat:ZZ": "127.0.0.1"}}},
		"dns-domain":               {"dns": map[string]any{"servers": []any{map[string]any{"address": "https://1.1.1.1/dns-query", "domains": []string{"ext:../fixture-outside.dat:ZZ"}}}}},
		"dns-expected-ip":          {"dns": map[string]any{"servers": []any{map[string]any{"address": "https://1.1.1.1/dns-query", "expectedIPs": []string{"ext-ip:../fixture-outside.dat:ZZ"}}}}},
	} {
		t.Run(name, func(t *testing.T) {
			plan := profilePlan(false)
			var cfg map[string]any
			if err := json.Unmarshal(plan.Outbounds[0].Profile, &cfg); err != nil {
				t.Fatal(err)
			}
			for key, value := range section {
				cfg[key] = value
			}
			raw, err := json.Marshal(cfg)
			if err != nil {
				t.Fatal(err)
			}
			plan.Outbounds[0].Profile = raw
			if _, err := Render(plan, supervise.Runtime{LocalPort: 4000}, nil); err == nil {
				t.Fatal("profile with an external asset path was accepted")
			}
			probe, err := RenderProbe(plan.Outbounds, []int{5000})
			if err != nil || strings.Contains(string(probe), "fixture-outside.dat") {
				t.Fatal("latency probe inherited unused provider DNS or routing")
			}
		})
	}
}

func TestProfileAssetProjectionMatchesTheEngineWireFormats(t *testing.T) {
	for _, test := range []struct {
		name, input string
		refused     bool
	}{
		{"routing-csv", `{"routing":{"rules":[{"domain":"full:example.com,ext:../outside.dat:ZZ"}]}}`, true},
		{"routing-regexp-array", `{"routing":{"rules":[{"domain":["regexp:foo,ext:../outside.dat:ZZ"]}]}}`, false},
		{"dns-regexp-array", `{"dns":{"servers":[{"domains":["regexp:foo,ext:../outside.dat:ZZ"]}]}}`, false},
		{"dns-domains-not-stringlist", `{"dns":{"servers":[{"domains":"full:example.com"}]}}`, true},
		{"dns-expected-fallback", `{"dns":{"servers":[{"expectIPs":"ext:../outside.dat:ZZ"}]}}`, true},
		{"dns-expected-empty-fallback", `{"dns":{"servers":[{"expectedIPs":[],"expectIPs":"ext:../outside.dat:ZZ"}]}}`, true},
		{"dns-expected-primary", `{"dns":{"servers":[{"expectedIPs":["ext:../outside.dat:ZZ"],"expectIPs":["geoip:private"]}]}}`, true},
		{"dns-unused-fallback", `{"dns":{"servers":[{"expectedIPs":["geoip:private"],"expectIPs":"ext:../outside.dat:ZZ"}]}}`, false},
		{"dns-unexpected", `{"dns":{"servers":[{"unexpectedIPs":"geoip:private,ext-ip:../outside.dat:ZZ"}]}}`, true},
		{"root-casefold", `{"DNS":{"ſervers":[{"domainſ":["ext:../outside.dat:ZZ"]}]}}`, true},
		{"root-null", `{"DNS":{"hosts":{"ext:../outside.dat:ZZ":"127.0.0.1"}},"dns":null}`, false},
		{"root-merge", `{"DNS":{"hosts":{"ext:../outside.dat:ZZ":"127.0.0.1"}},"dns":{"servers":["1.1.1.1"]}}`, true},
		{"hosts-replaced", `{"dns":{"hosts":{"ext:../outside.dat:ZZ":"127.0.0.1"},"Hosts":{"example.com":"1.1.1.1"}}}`, false},
		{"rules-replaced", `{"routing":{"rules":[{"domain":["ext:../outside.dat:ZZ"]}],"Rules":[{"ip":["geoip:private"]}]}}`, false},
		{"non-string-list", `{"routing":{"rules":[{"sourceIP":{}}]}}`, true},
		{"source-alias", `{"routing":{"rules":[{"ſource":["ext:../outside.dat:ZZ"]}]}}`, true},
		{"source-unused-fallback", `{"routing":{"rules":[{"sourceIP":["geoip:private"],"source":["ext:../outside.dat:ZZ"]}]}}`, false},
		{"source-empty-primary", `{"routing":{"rules":[{"sourceIP":[],"source":["ext:../outside.dat:ZZ"]}]}}`, false},
		{"source-null-primary", `{"routing":{"rules":[{"sourceIP":null,"source":["ext:../outside.dat:ZZ"]}]}}`, true},
		{"local-ip", `{"routing":{"rules":[{"localIP":["ext-ip:../outside.dat:ZZ"]}]}}`, true},
		{"bundled-qualified", `{"routing":{"rules":[{"domains":"ext-domain:geosite.dat:CN@ads","sourceIP":"ext-ip:geoip.dat:!CN"}]}}`, false},
	} {
		t.Run(test.name, func(t *testing.T) {
			if err := validateProfileAssets([]byte(test.input)); (err != nil) != test.refused {
				t.Fatalf("refused=%v, error=%v", test.refused, err)
			}
		})
	}
}

func TestProfileAssetFileNamesAreTheBundledNamesOnly(t *testing.T) {
	for _, filename := range []string{"../outside.dat", "..\\outside.dat", "/outside.dat", "\\\\server\\share\\outside.dat", "custom.dat", "NUL", "NUL.dat", "COM1.dat", "geosite.dat.", "geosite.dat ", "GEOSITE.DAT", "geosite.dat:stream", "%2e%2e%2foutside.dat", "", "geosite.dat/../outside.dat"} {
		if err := checkProfileAssetRefs([]string{"ext:" + filename + ":ZZ"}, "ext:"); err == nil {
			t.Errorf("unapproved filename accepted: %q", filename)
		}
	}
	for _, reference := range []string{"ext:geosite.dat:CN", "ext:geoip.dat:!CN", "domain:example.com", "regexp:^ext:../outside.dat"} {
		if err := checkProfileAssetRefs([]string{reference}, "ext:"); err != nil {
			t.Fatal(err)
		}
	}
	for _, reference := range []string{"ext:geosite.dat", "ext:geosite.dat:", "ext:geosite.dat:CN:extra"} {
		if err := checkProfileAssetRefs([]string{reference}, "ext:"); err == nil {
			t.Fatal("malformed external reference accepted")
		}
	}
}

func TestProfileAssetPolicyDoesNotInspectPasswordsOrLabels(t *testing.T) {
	plan := profilePlan(false)
	var cfg map[string]any
	if err := json.Unmarshal(plan.Outbounds[0].Profile, &cfg); err != nil {
		t.Fatal(err)
	}
	const value = "ext:../fixture-password-or-label:ZZ"
	settings := cfg["outbounds"].([]any)[0].(map[string]any)["settings"].(map[string]any)
	settings["password"] = value
	cfg["metadata"] = map[string]any{"label": value}
	raw, err := json.Marshal(cfg)
	if err != nil {
		t.Fatal(err)
	}
	plan.Outbounds[0].Profile = raw
	output, err := Render(plan, supervise.Runtime{LocalPort: 4000}, nil)
	if err != nil || !strings.Contains(string(output), value) {
		t.Fatal("asset policy rejected or rewrote unrelated provider data")
	}
}

func TestProfileKeepsBundledExternalAssetReferences(t *testing.T) {
	plan := profilePlan(false)
	var cfg map[string]any
	if err := json.Unmarshal(plan.Outbounds[0].Profile, &cfg); err != nil {
		t.Fatal(err)
	}
	cfg["routing"] = map[string]any{"rules": []any{
		map[string]any{"domain": []string{"ext:geosite.dat:CN"}, "outboundTag": "auto-a"},
		map[string]any{"ip": []string{"ext:geoip.dat:CN"}, "outboundTag": "auto-a"},
	}}
	raw, err := json.Marshal(cfg)
	if err != nil {
		t.Fatal(err)
	}
	plan.Outbounds[0].Profile = raw
	if _, err := Render(plan, supervise.Runtime{LocalPort: 4000}, nil); err != nil {
		t.Fatal(err)
	}
}
