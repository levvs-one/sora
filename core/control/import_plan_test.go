package control

import (
	"encoding/json"
	"fmt"
	"os"
	"testing"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/parser"
	"github.com/levvs-one/sora-client/core/secret"
)

func TestEveryParserFixtureBuildsAValidatedPlan(t *testing.T) {
	raw, err := os.ReadFile("../parser/testdata/imports.json")
	if err != nil {
		t.Fatal(err)
	}
	var fixtures []struct {
		Name, Input string
		Count       int
	}
	if err := json.Unmarshal(raw, &fixtures); err != nil {
		t.Fatal(err)
	}
	if len(fixtures) == 0 {
		t.Fatal("no import fixtures")
	}
	store, err := secret.Open(t.TempDir(), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = store.Close() })
	for _, fixture := range fixtures {
		t.Run(fixture.Name, func(t *testing.T) {
			result, err := (parser.LinkParser{}).Parse([]byte(fixture.Input))
			if err != nil {
				t.Fatal(err)
			}
			if len(result.Servers) != fixture.Count {
				t.Fatalf("imported %d, want %d: %+v", len(result.Servers), fixture.Count, result.Report)
			}
			// Provider profiles must run alone, so validate each imported server.
			for i, spec := range result.Servers {
				document, err := credentialDocument(spec)
				if err != nil {
					t.Fatal(err)
				}
				reference := fmt.Sprintf("fixture-%d", i)
				if err := store.Put(reference, document); err != nil {
					t.Fatal(err)
				}
				plan, err := planFromProto(&corev1.SessionPlan{
					TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
					Outbounds:  []*corev1.OutboundSpec{outboundToProto(spec, reference)},
				}, "parser-fixture", store)
				if err != nil {
					t.Errorf("server %d (%s, %s): %v", i, spec.Protocol, spec.Transport, err)
					continue
				}
				if err := plan.Validate(); err != nil {
					t.Fatal(err)
				}
			}
		})
	}
}
