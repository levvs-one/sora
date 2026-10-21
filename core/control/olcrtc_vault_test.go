package control

import (
	"context"
	"encoding/json"
	"reflect"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/parser"
)

// TestOlcrtcVaultRoundTrip is the restart test of the OpenLibre
// transport work: a link is imported, its credential document is
// stored, and the plan outbound rebuilt from the document alone
// (plus the proto spec the client kept) must carry the provider,
// the room, the transport and every parameter the link carried —
// the failure IMPORT.md flagged, where only the room and the key
// survived.
func TestOlcrtcVaultRoundTrip(t *testing.T) {
	links := []string{
		`olcrtc://wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01#d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799$DE / olc free sub`,
		`olcrtc://jitsi?datachannel@https://meet.example.org/myroom#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa$RU`,
		`olcrtc://telemost?videochannel<video-w=1080&video-h=1080&video-fps=60&video-codec=tile&video-tile-module=4&video-tile-rs=20>@room-9#0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef$MIMO`,
		`olcrtc://wbstream?vp8channel<vp8-fps=25&vp8-batch=1>@room-2#` + strings.Repeat("b", 64),
	}
	for _, link := range links {
		t.Run(link[:24], func(t *testing.T) {
			result, err := parser.LinkParser{}.Parse([]byte(link))
			if err != nil || len(result.Servers) != 1 {
				t.Fatalf("parse: %v (%d servers)", err, len(result.Servers))
			}
			spec := result.Servers[0]
			doc, err := credentialDocument(spec)
			if err != nil {
				t.Fatal(err)
			}
			// The document itself must name the provider, the room,
			// the transport and every non-default parameter.
			var values map[string]string
			if err := json.Unmarshal(doc, &values); err != nil {
				t.Fatal(err)
			}
			if values["olcrtc_provider"] != spec.Options["olcrtc_provider"] ||
				values["olcrtc_room"] != spec.Options["olcrtc_room"] ||
				values["olcrtc_transport"] != spec.Transport ||
				values["password"] != spec.Password {
				t.Fatalf("document lost identity fields: %s", doc)
			}
			// Restart: rebuild the plan outbound from the stored
			// document and the proto spec, exactly as plan building
			// does after a core restart.
			reference, err := referenceOf(spec)
			if err != nil {
				t.Fatal(err)
			}
			protoSpec := outboundToProto(spec, reference)
			outbound, err := outboundFromProto(0, protoSpec, stubResolver{reference: doc})
			if err != nil {
				t.Fatal(err)
			}
			if outbound.Olcrtc == nil {
				t.Fatalf("rebuilt outbound lost its olcrtc config: %+v", outbound)
			}
			want := &engine.OlcrtcConfig{
				Provider:  spec.Options["olcrtc_provider"],
				Transport: spec.Transport,
				Room:      spec.Options["olcrtc_room"],
			}
			params := map[string]string{}
			for k, v := range spec.Options {
				if strings.HasPrefix(k, "olcrtc_") {
					continue
				}
				params[k] = v
			}
			if len(params) > 0 {
				want.Params = params
			}
			if !reflect.DeepEqual(outbound.Olcrtc, want) {
				t.Fatalf("rebuilt olcrtc = %+v, want %+v", outbound.Olcrtc, want)
			}
			if outbound.Password != spec.Password || outbound.Server != spec.Host || outbound.Port != 0 {
				t.Fatalf("rebuilt outbound = %+v", outbound)
			}
			if err := outbound.Validate(); err != nil {
				t.Fatalf("rebuilt outbound does not validate: %v", err)
			}
			// Identity survives: the same reference is derived, so a
			// re-import after restart overwrites instead of
			// duplicating the entry.
			if again, err := referenceOf(spec); err != nil || again != reference {
				t.Fatalf("reference drifted: %q vs %q (%v)", again, reference, err)
			}
			// The document is deterministic: rebuilding it from the
			// same spec is byte-identical.
			if doc2, err := credentialDocument(spec); err != nil || string(doc2) != string(doc) {
				t.Fatalf("document not deterministic: %v", err)
			}
		})
	}
}

// TestOlcrtcVaultKeepsSubscriptionMeta: the ## block of a
// subscription (name/icon/usage) rides the document too, so the
// metadata an import attached to the server is not dropped by the
// vault even though the engine never reads it.
func TestOlcrtcVaultKeepsSubscriptionMeta(t *testing.T) {
	body := "#name: Free\n\nolcrtc://wbstream?datachannel@abc123xyz#" + strings.Repeat("a", 64) + "$DE\n##name: DE-Backup\n##icon: flag\n##used: 500mb/10gb\n"
	result, err := parser.LinkParser{}.Parse([]byte(body))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("parse: %v (%d servers)", err, len(result.Servers))
	}
	doc, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	var values map[string]string
	if err := json.Unmarshal(doc, &values); err != nil {
		t.Fatal(err)
	}
	var meta map[string]string
	if err := json.Unmarshal([]byte(values["olcrtc_meta"]), &meta); err != nil {
		t.Fatalf("meta not stored as JSON: %v (doc %s)", err, doc)
	}
	if meta["icon"] != "flag" || meta["used"] != "500mb/10gb" {
		t.Fatalf("meta = %v", meta)
	}
}

// TestOlcrtcServerModeRefusedFromVault: a document that smuggles
// mode "srv" produces a plan outbound whose validation refuses it —
// sora never runs an egress, whatever the stored material says.
func TestOlcrtcServerModeRefusedFromVault(t *testing.T) {
	result, err := parser.LinkParser{}.Parse([]byte("olcrtc://jitsi?datachannel@room-1#" + strings.Repeat("c", 64)))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("parse: %v", err)
	}
	spec := result.Servers[0]
	spec.Options["olcrtc_mode"] = "srv"
	doc, err := credentialDocument(spec)
	if err != nil {
		t.Fatal(err)
	}
	outbound, err := outboundFromProto(0, outboundToProto(spec, "ref"), stubResolver{"ref": doc})
	if err != nil {
		t.Fatal(err)
	}
	if outbound.Olcrtc == nil || outbound.Olcrtc.Mode != "srv" {
		t.Fatalf("mode did not survive the vault: %+v", outbound.Olcrtc)
	}
	if err := outbound.Validate(); err == nil || !strings.Contains(err.Error(), "client only") {
		t.Fatalf("srv plan validated: %v", err)
	}
	// The full plan path refuses it with the plan key, not a panic.
	plan := &engine.Plan{SessionID: "s", Outbounds: []engine.Outbound{outbound}}
	if err := plan.Validate(); err == nil {
		t.Fatal("srv plan passed plan validation")
	}
	_ = context.Background()
}
