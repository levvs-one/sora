package control

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"slices"
	"testing"

	"google.golang.org/protobuf/encoding/protojson"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
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
					if name == "zapret" && label == "HTTP" && strategy.GetMethodEol() {
						t.Fatal("the default HTTP profile must not add a leading line rejected by strict servers")
					}
					protocol := "bypass"
					if selected.Backend == "winws" {
						protocol = "winws"
					} else if selected.Backend == "byedpi" && platform == "linux" {
						protocol = "byedpi"
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
					switch selected.Backend {
					case "winws":
						if _, err := winws.Args(*plan.Outbounds[0].Bypass); err != nil {
							t.Fatal(err)
						}
					case "byedpi":
						if _, err := bypass.WindowsArgs(*plan.Outbounds[0].Bypass, 12345); err != nil {
							t.Fatal(err)
						}
					}
				})
			}
		}
	}
	if total != 12 {
		t.Fatalf("source profile coverage changed: %d", total)
	}
}

func TestExplicitByeDPIProtocolSurvivesWirePlan(t *testing.T) {
	in := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{{Id: "dpi", Protocol: "byedpi",
			Bypass: &corev1.BypassStrategy{SplitPos: []string{"1"}}}}}
	plan, err := planFromProto(in, "byedpi-fixture", nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := plan.Validate(); err != nil {
		t.Fatal(err)
	}
	if got := plan.Outbounds[0]; got.Protocol != engine.ProtocolByeDPI || got.Bypass == nil {
		t.Fatalf("wire plan lost its explicit ByeDPI backend: %+v", got)
	}
}

type byedpiCapabilityStub struct{ ready bool }

func (b byedpiCapabilityStub) Measure(context.Context, []engine.Outbound, engine.MeasureOptions) (<-chan engine.Measurement, error) {
	panic("capability discovery must not probe")
}

func (b byedpiCapabilityStub) ByeDPIAvailable() bool { return b.ready }

func TestByeDPICapabilityRequiresInstalledHostProxy(t *testing.T) {
	for _, ready := range []bool{false, true} {
		s := &Server{measurer: byedpiCapabilityStub{ready: ready}}
		has := slices.Contains(s.apiVersion().GetCapabilities(), "serverless-bydpi")
		if has != ready {
			t.Fatalf("capability %v, installed proxy %v", has, ready)
		}
	}
}
