package engine

import (
	"strings"
	"testing"
)

// CENSOR-P4 review fixes: M2 (required plugin options as catalog
// data), M3 (mihomo option carriage as catalog data, gated at
// selection), L1 (error texts must not double the option key).
// Each test names the review item it pins; removing the gate it
// covers must turn it red.

// M2: a plugin missing a required option fails plan validation with
// the option named — the reviewer's probe (7/7 nil before the fix).
func TestSSPluginRequiredOptions(t *testing.T) {
	mk := func(plugin, opts string) Outbound {
		o := ssPlan("aes-256-gcm", "a-long-enough-password").Outbounds[0]
		o.Plugin, o.PluginOpts = plugin, opts
		return o
	}
	for _, tc := range []struct {
		name, plugin, opts, want string
	}{
		{"shadow-tls no opts", "shadow-tls", "", `"password" is required`},
		{"shadow-tls host only", "shadow-tls", "host=example.com", `"password" is required`},
		{"restls no password", "restls-plugin", "host=example.com", `"password" is required`},
		{"kcptun no opts", "kcptun", "", `"key" is required`},
		{"kcptun tuning only", "kcptun", "mtu=1400;conn=2", `"key" is required`},
		{"obfs-local host only", "obfs-local", "obfs-host=example.com", `"obfs" is required`},
		{"obfs-local no opts", "obfs-local", "", `"obfs" is required`},
		// Satisfied requirements validate cleanly.
		{"shadow-tls ok", "shadow-tls", "host=example.com;password=pw", ""},
		{"restls ok", "restls-plugin", "password=pw", ""},
		{"kcptun ok", "kcptun", "key=k", ""},
		{"obfs-local ok", "obfs-local", "obfs=tls", ""},
		// Plugins without required options stay as they were.
		{"v2ray-plugin bare", "v2ray-plugin", "", ""},
		{"jls bare", "jls-plugin", "", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			err := mk(tc.plugin, tc.opts).Validate()
			if tc.want == "" {
				if err != nil {
					t.Fatalf("Validate = %v, want nil", err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Validate = %v, want error containing %q", err, tc.want)
			}
		})
	}
	// The required-option error names the OPTION, never a value:
	// a secret sitting in another option must not leak into it.
	o := mk("kcptun", "crypt=MARKERSECRET9f2;mtu=1400")
	err := o.Validate()
	if err == nil {
		t.Fatal("kcptun without key must fail validation")
	}
	if strings.Contains(err.Error(), "MARKERSECRET9f2") {
		t.Fatalf("required-option error echoes an option value: %v", err)
	}
}

// M2/M3 catalog-data invariants: Required and MihomoOpts may only
// name options the schema itself declares, mihomo keys must not
// collide (two canonical keys rendering into one map key would
// silently overwrite), and every plugin mihomo carries must state
// its carriage explicitly.
func TestSSPluginCatalogDataInvariants(t *testing.T) {
	for _, spec := range ssPlugins {
		spec := spec
		for _, req := range spec.Required {
			if _, ok := spec.optKind(req); !ok {
				t.Errorf("plugin %s: required option %q is not in the schema", spec.Name, req)
			}
		}
		seenMihomo := map[string]string{}
		for key, mk := range spec.MihomoOpts {
			if _, ok := spec.optKind(key); !ok {
				t.Errorf("plugin %s: MihomoOpts key %q is not in the schema", spec.Name, key)
			}
			if prev, dup := seenMihomo[mk]; dup {
				t.Errorf("plugin %s: options %q and %q both render as mihomo key %q", spec.Name, prev, key, mk)
			}
			seenMihomo[mk] = key
		}
		carriesMihomo := false
		for _, k := range spec.Engines {
			if k == KindMihomo {
				carriesMihomo = true
			}
		}
		if carriesMihomo && spec.MihomoOpts == nil {
			t.Errorf("plugin %s: carried by mihomo but MihomoOpts is nil — carriage must be explicit data", spec.Name)
		}
	}
}

// M3: selection for mihomo refuses a plan whose plugin option has
// no mihomo spelling, naming plugin and option; sing-box (which
// renders the canonical string) is unaffected.
func TestMihomoPluginOptionSelectionGate(t *testing.T) {
	mk := func(plugin, opts string) *Plan {
		p := ssPlan("aes-256-gcm", "a-long-enough-password")
		p.Outbounds[0].Plugin, p.Outbounds[0].PluginOpts = plugin, opts
		return p
	}
	for _, tc := range []struct {
		name, plugin, opts, wantMissing string
	}{
		{"obfs-uri", "obfs-local", "obfs=tls;obfs-uri=/x", "obfs-uri"},
		{"fast-open", "obfs-local", "obfs=tls;fast-open", "fast-open"},
		{"v2ray loglevel", "v2ray-plugin", "host=example.com;loglevel=debug", "loglevel"},
		{"all carried", "obfs-local", "obfs=tls;obfs-host=example.com", ""},
		{"kcptun carried", "kcptun", "key=k;mtu=1400", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			joined := strings.Join(Catalog[KindMihomo].Missing(mk(tc.plugin, tc.opts)), ",")
			if tc.wantMissing == "" {
				if strings.Contains(joined, "no mihomo spelling") {
					t.Fatalf("mihomo must carry this plan, missing=%s", joined)
				}
				return
			}
			if !strings.Contains(joined, tc.wantMissing) || !strings.Contains(joined, "no mihomo spelling") {
				t.Fatalf("mihomo missing must name option %q with the no-spelling reason, got %s", tc.wantMissing, joined)
			}
			// The same plan on sing-box must not gain this refusal.
			if sb := strings.Join(Catalog[KindSingBox].Missing(mk(tc.plugin, tc.opts)), ","); strings.Contains(sb, "no mihomo spelling") {
				t.Fatalf("sing-box must not report a mihomo spelling gap: %s", sb)
			}
		})
	}
}

// M3: the translation itself — typed values, renames, forced
// websocket mode, and named refusals (engine-level view of the
// function the mihomo renderer consumes).
func TestMihomoSSPluginOptsTranslation(t *testing.T) {
	out, err := MihomoSSPluginOpts("obfs-local", "obfs=tls;obfs-host=example.com")
	if err != nil {
		t.Fatal(err)
	}
	if out["mode"] != "tls" || out["host"] != "example.com" || len(out) != 2 {
		t.Fatalf("obfs translation = %v", out)
	}
	out, err = MihomoSSPluginOpts("v2ray-plugin", "host=example.com")
	if err != nil || out["mode"] != "websocket" {
		t.Fatalf("v2ray mode must be forced to websocket: %v, %v", out, err)
	}
	for _, tc := range []struct{ plugin, opts, want string }{
		{"obfs-local", "obfs=tls;obfs-uri=/x", "obfs-uri"},
		{"obfs-local", "obfs=tls;fast-open", "fast-open"},
		{"v2ray-plugin", "bogus=1", "bogus"},
		{"nosuch-plugin", "a=1", "nosuch-plugin"},
	} {
		if _, err := MihomoSSPluginOpts(tc.plugin, tc.opts); err == nil || !strings.Contains(err.Error(), tc.want) {
			t.Errorf("MihomoSSPluginOpts(%q, %q) err = %v, want refusal naming %q", tc.plugin, tc.opts, err, tc.want)
		}
	}
}

// L1: option-value errors must read "option <key> <value> ..." — the
// key must never be immediately doubled by a format string that
// repeats it ("option version version \"9\"").
func TestSSPluginErrorTextsNoDoubledKey(t *testing.T) {
	mk := func(plugin, opts string) error {
		o := ssPlan("aes-256-gcm", "a-long-enough-password").Outbounds[0]
		o.Plugin, o.PluginOpts = plugin, opts
		return o.Validate()
	}
	err := mk("shadow-tls", "password=pw;version=9")
	if err == nil || !strings.Contains(err.Error(), `option version "9" is not 2 or 3`) {
		t.Fatalf("version error = %v", err)
	}
	if strings.Contains(err.Error(), "version version") {
		t.Fatalf("doubled key in error: %v", err)
	}
	err = mk("v2ray-plugin", "mode=quic")
	if err == nil || !strings.Contains(err.Error(), `option mode "quic"`) {
		t.Fatalf("mode error = %v", err)
	}
	if strings.Contains(err.Error(), "mode mode") {
		t.Fatalf("doubled key in error: %v", err)
	}
	err = mk("obfs-local", "obfs=salamander")
	if err == nil || !strings.Contains(err.Error(), `option obfs "salamander" is not http or tls`) {
		t.Fatalf("obfs mode error = %v", err)
	}
}
