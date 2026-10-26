package control

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"google.golang.org/protobuf/encoding/protojson"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestExtensionBypassSourceProfilesBuildValidatedPlans(t *testing.T) {
	for _, name := range []string{"zapret", "byedpi"} {
		raw, err := os.ReadFile(filepath.Join("..", "..", "extensions", "sources", name, "hook.json"))
		if err != nil {
			t.Fatal(err)
		}
		var doc struct {
			Profiles map[string]json.RawMessage `json:"profiles"`
		}
		if err := json.Unmarshal(raw, &doc); err != nil {
			t.Fatal(err)
		}
		if len(doc.Profiles) != 3 {
			t.Fatalf("%s has %d profiles", name, len(doc.Profiles))
		}
		for label, raw := range doc.Profiles {
			t.Run(name+"/"+label, func(t *testing.T) {
				strategy := new(corev1.BypassStrategy)
				if err := protojson.Unmarshal(raw, strategy); err != nil {
					t.Fatal(err)
				}
				in := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
					Outbounds: []*corev1.OutboundSpec{{Id: "zapret", Protocol: "bypass", Bypass: strategy}}}
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
			})
		}
	}
}
