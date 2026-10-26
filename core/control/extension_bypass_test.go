package control

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"google.golang.org/protobuf/encoding/protojson"

	"github.com/levvs-one/sora-client/core/engine/winws"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestExtensionBypassSourceProfilesBuildValidatedPlans(t *testing.T) {
	total := 0
	for _, name := range []string{"zapret", "byedpi"} {
		raw, err := os.ReadFile(filepath.Join("..", "..", "extensions", "sources", name, "hook.json"))
		if err != nil {
			t.Fatal(err)
		}
		type variant struct {
			Backend  string                     `json:"backend"`
			Profiles map[string]json.RawMessage `json:"profiles"`
		}
		var doc struct {
			Backend   string                     `json:"backend"`
			Profiles  map[string]json.RawMessage `json:"profiles"`
			Platforms map[string]variant         `json:"platforms"`
		}
		if err := json.Unmarshal(raw, &doc); err != nil {
			t.Fatal(err)
		}
		variants := doc.Platforms
		if variants == nil {
			variants = map[string]variant{"native": {doc.Backend, doc.Profiles}}
		}
		for platform, selected := range variants {
			if len(selected.Profiles) != 3 {
				t.Fatalf("%s/%s has %d profiles", name, platform, len(selected.Profiles))
			}
			for label, raw := range selected.Profiles {
				total++
				t.Run(name+"/"+platform+"/"+label, func(t *testing.T) {
					strategy := new(corev1.BypassStrategy)
					if err := protojson.Unmarshal(raw, strategy); err != nil {
						t.Fatal(err)
					}
					protocol := "bypass"
					if selected.Backend == "winws" {
						protocol = "winws"
					}
					in := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
						Outbounds: []*corev1.OutboundSpec{{Id: "zapret", Protocol: protocol, Bypass: strategy}}}
					plan, err := planFromProto(in, "extension-fixture", nil)
					if err != nil {
						t.Fatal(err)
					}
					if err := plan.Validate(); err != nil {
						t.Fatal(err)
					}
					if plan.Outbounds[0].Bypass == nil {
						t.Fatal("lost bypass strategy")
					}
					if selected.Backend == "winws" {
						if _, err := winws.Args(*plan.Outbounds[0].Bypass); err != nil {
							t.Fatal(err)
						}
					}
				})
			}
		}
	}
	if total != 9 {
		t.Fatalf("source profile coverage changed: %d", total)
	}
}
