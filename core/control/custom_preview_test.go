package control

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/custom"
	"github.com/levvs-one/sora-client/core/engine"
	customv1 "github.com/levvs-one/sora-client/core/gen/sora/custom/v1"
)

func TestCustomPreviewUsesExistingParserWithoutPersisting(t *testing.T) {
	srv, token := customTestPlane(t)
	c := customImpl(t, srv)
	raw, err := os.ReadFile("../parser/testdata/imports.json")
	if err != nil {
		t.Fatal(err)
	}
	var fixtures []struct {
		Name, Input, Protocol string
		Count                 int
	}
	if err := json.Unmarshal(raw, &fixtures); err != nil {
		t.Fatal(err)
	}
	for _, f := range fixtures {
		if f.Count != 1 || f.Protocol == "xray-profile" {
			continue
		}
		t.Run(f.Name, func(t *testing.T) {
			preview, err := c.PreviewCustomServer(context.Background(), &customv1.PreviewCustomServerRequest{
				ApiVersion: customVersion(), ControlAuthenticator: token, Link: f.Input,
			})
			if err != nil || preview.GetError() != nil {
				t.Fatalf("preview: %v %v", err, preview.GetError())
			}
			if preview.GetServer().GetProtocolName() != f.Protocol || preview.GetCredentialDocument() == "" {
				t.Fatal("incomplete preview")
			}
			if preview.GetServer().GetCredentials() != "" {
				t.Fatal("draft credentials belong only in the preview document")
			}
			st, err := c.store()
			if err != nil {
				t.Fatal(err)
			}
			if len(st.List()) != 0 {
				t.Fatal("preview created a server")
			}
			entries, err := os.ReadDir(filepath.Join(srv.dataDir, "custom"))
			if err != nil || len(entries) != 0 {
				t.Fatal("preview persisted metadata")
			}
		})
	}
	for _, input := range []string{"", "bad", "vless://broken", "https://example.com/sub", "vless://x@example.com:443\nvless://x@other.example.com:443"} {
		result, err := c.PreviewCustomServer(context.Background(), &customv1.PreviewCustomServerRequest{ApiVersion: customVersion(), ControlAuthenticator: token, Link: input})
		if err != nil || result.GetError() == nil {
			t.Fatalf("accepted invalid preview %q", input)
		}
	}
	if _, err := c.PreviewCustomServer(context.Background(), &customv1.PreviewCustomServerRequest{ApiVersion: customVersion(), ControlAuthenticator: []byte("invalid")}); status.Code(err) != codes.Unauthenticated {
		t.Fatal("preview lacks authorization")
	}
}

func TestCustomImportedOptionsSurviveSaveEditAndRestart(t *testing.T) {
	srv, token := customTestPlane(t)
	c := customImpl(t, srv)
	ctx := context.Background()
	const link = "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443?security=reality&type=grpc&sni=example.com&pbk=public&sid=abcd&serviceName=vpn#Home"
	preview, err := c.PreviewCustomServer(ctx, &customv1.PreviewCustomServerRequest{ApiVersion: customVersion(), ControlAuthenticator: token, Link: link})
	if err != nil || preview.GetError() != nil {
		t.Fatalf("preview: %v %v", err, preview.GetError())
	}
	in := preview.GetServer()
	in.Credentials = preview.GetCredentialDocument()
	saved, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{ApiVersion: customVersion(), ControlAuthenticator: token, Server: in})
	if err != nil || saved.GetError() != nil {
		t.Fatalf("save: %v %v", err, saved.GetError())
	}
	in = saved.GetServer()
	if in.GetCredentials() != "" || !in.GetHasCredentials() {
		t.Fatal("save leaked credentials")
	}
	in.Name = "Renamed"
	in.Port = 8443
	in.Credentials = `{"uuid":"new-secret"}`
	edited, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{ApiVersion: customVersion(), ControlAuthenticator: token, Server: in})
	if err != nil || edited.GetError() != nil {
		t.Fatalf("edit: %v %v", err, edited.GetError())
	}
	store, err := custom.Open(filepath.Join(srv.dataDir, "custom"), srv.secrets)
	if err != nil {
		t.Fatal(err)
	}
	out, err := outboundFromProto(0, customOutbound(store.List()[0]), srv.secrets)
	if err != nil {
		t.Fatal(err)
	}
	if out.UUID != "new-secret" || !out.TLS.Reality || out.Transport.Type != "grpc" || out.Transport.Service != "vpn" || out.Port != 8443 {
		t.Fatalf("edited plan lost options: %+v", out)
	}
	listed, err := c.ListCustomServers(ctx, &customv1.ListCustomServersRequest{ApiVersion: customVersion(), ControlAuthenticator: token})
	if err != nil || strings.Contains(listed.String(), "new-secret") {
		t.Fatal("list leaked stored secret")
	}
	if listed.GetServers()[0].GetOutbound().GetCredentials().GetReference() == "" {
		t.Fatal("own server cannot build a plan without subscriptions")
	}
	// Pasting a new link must remove old REALITY options, including keys the
	// new link omits; ordinary secret edits above must retain them.
	in = edited.GetServer()
	in.Credentials = `{"uuid":"replacement","security":"none"}`
	in.Security = "none"
	replaced, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{ApiVersion: customVersion(), ControlAuthenticator: token, Server: in, ReplaceCredentials: true})
	if err != nil || replaced.GetError() != nil {
		t.Fatal("replace failed")
	}
	out, err = outboundFromProto(0, srv.CustomOutbounds()[0], srv.secrets)
	if err != nil || out.TLS.Reality || out.PublicKey != "" {
		t.Fatal("replacement retained old options")
	}
}

func TestCustomProtocolsFollowEngineCatalog(t *testing.T) {
	caps := engine.Catalog[engine.KindMihomo]
	caps.Protocols["future-test"] = true
	defer delete(caps.Protocols, "future-test")
	if !slices.Contains(custom.Protocols(), "future-test") {
		t.Fatal("new catalog protocol missing")
	}
	if custom.ValidateProtocol("future-test") != nil {
		t.Fatal("catalog protocol rejected")
	}
	if slices.Contains(custom.Protocols(), "direct") {
		t.Fatal("internal outbound offered as a server")
	}
}
