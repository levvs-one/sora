package ext

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	extv1 "github.com/levvs-one/sora-client/core/gen/sora/ext/v1"
)

func testStore(t *testing.T) *Store {
	t.Helper()
	s, err := OpenStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func installHello(t *testing.T, s *Store, version string) {
	t.Helper()
	m := testManifest(t)
	m.Version = version
	data := buildPackage(t, m, nil, nil)
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications"}); err != nil {
		t.Fatalf("install failed: %v", err)
	}
}

func TestStoreInstallAndGet(t *testing.T) {
	s := testStore(t)
	installHello(t, s, "1.0.0")
	inst, ok := s.Get("com.example.hello")
	if !ok {
		t.Fatal("not found after install")
	}
	if inst.Version != "1.0.0" || !inst.Enabled {
		t.Fatalf("bad installed state: %+v", inst)
	}
	if dir := s.ContentDir("com.example.hello"); dir == "" {
		t.Fatal("empty content dir")
	}
	if n := len(s.List()); n != 1 {
		t.Fatalf("want 1 installed, got %d", n)
	}
}

func TestStoreInstallRejectsMissingGrant(t *testing.T) {
	s := testStore(t)
	m := testManifest(t)
	data := buildPackage(t, m, nil, nil)
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	// The manifest wants connections.read + notifications; grant only one.
	if _, err := s.Install(pkg, SourceSideload, []string{"notifications"}); err == nil {
		t.Fatal("install must require granting every manifest permission")
	}
}

func TestStoreUpdateReportsAddedPermissions(t *testing.T) {
	s := testStore(t)
	installHello(t, s, "1.0.0")
	m := testManifest(t)
	m.Version = "1.1.0"
	m.Permissions = []string{"connections.read", "notifications", "servers.read"}
	data := buildPackage(t, m, nil, nil)
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	added, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications", "servers.read"})
	if err != nil {
		t.Fatalf("update failed: %v", err)
	}
	if len(added) != 1 || added[0] != "servers.read" {
		t.Fatalf("want added=[servers.read], got %v", added)
	}
	inst, _ := s.Get("com.example.hello")
	if inst.Previous != "1.0.0" {
		t.Fatalf("want previous=1.0.0, got %q", inst.Previous)
	}
}

func TestStoreUpdateRejectsDowngrade(t *testing.T) {
	s := testStore(t)
	installHello(t, s, "2.0.0")
	m := testManifest(t)
	m.Version = "1.9.9"
	data := buildPackage(t, m, nil, nil)
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications"}); err == nil {
		t.Fatal("downgrade must be rejected")
	}
}

func TestStoreRollback(t *testing.T) {
	s := testStore(t)
	installHello(t, s, "1.0.0")
	m := testManifest(t)
	m.Version = "1.1.0"
	data := buildPackage(t, m, nil, nil)
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications"}); err != nil {
		t.Fatal(err)
	}
	if err := s.Rollback("com.example.hello"); err != nil {
		t.Fatalf("rollback failed: %v", err)
	}
	inst, _ := s.Get("com.example.hello")
	if inst.Version != "1.0.0" || inst.Previous != "" {
		t.Fatalf("bad state after rollback: %+v", inst)
	}
	if err := s.Rollback("com.example.hello"); err == nil {
		t.Fatal("second rollback must fail (no previous)")
	}
}

func TestStoreDisableRevokesTokens(t *testing.T) {
	s := testStore(t)
	installHello(t, s, "1.0.0")
	tok, err := s.Issuer().Mint("com.example.hello", []string{"connections.read"})
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := s.Issuer().Verify(tok); !ok {
		t.Fatal("token should verify before disable")
	}
	if err := s.SetEnabled("com.example.hello", false); err != nil {
		t.Fatal(err)
	}
	if _, ok := s.Issuer().Verify(tok); ok {
		t.Fatal("token must be revoked on disable")
	}
}

func TestStoreUninstall(t *testing.T) {
	s := testStore(t)
	installHello(t, s, "1.0.0")
	if err := s.Uninstall("com.example.hello"); err != nil {
		t.Fatal(err)
	}
	if _, ok := s.Get("com.example.hello"); ok {
		t.Fatal("still present after uninstall")
	}
	if err := s.Uninstall("com.example.hello"); err == nil {
		t.Fatal("double uninstall must fail")
	}
}

func TestStoreSettingsValidation(t *testing.T) {
	s := testStore(t)
	m := testManifest(t)
	m.SettingsSchema = json.RawMessage(`{"type":"object","properties":{
		"theme":{"type":"string","enum":["dark","light"],"default":"dark"},
		"refresh":{"type":"integer","minimum":1,"maximum":60,"default":5},
		"show_bytes":{"type":"boolean","default":true}}}`)
	data := buildPackage(t, m, nil, nil)
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications"}); err != nil {
		t.Fatal(err)
	}
	// Defaults are visible before any save.
	got, err := s.GetSettings("com.example.hello")
	if err != nil {
		t.Fatal(err)
	}
	if got["theme"] != "dark" || got["refresh"] != float64(5) {
		t.Fatalf("bad defaults: %v", got)
	}
	// Valid save.
	if err := s.SetSettings("com.example.hello", map[string]any{"theme": "light", "refresh": float64(10)}); err != nil {
		t.Fatalf("valid settings rejected: %v", err)
	}
	// Violations.
	for name, vals := range map[string]map[string]any{
		"bad enum":    {"theme": "neon"},
		"bad type":    {"refresh": "often"},
		"out of max":  {"refresh": float64(999)},
		"unknown key": {"nope": true},
	} {
		if err := s.SetSettings("com.example.hello", vals); err == nil {
			t.Fatalf("expected rejection for %s", name)
		}
	}
}

func TestCatalogValidate(t *testing.T) {
	good := &Catalog{
		Version:   1,
		UpdatedAt: time.Now().UTC().Format(time.RFC3339),
		Extensions: []Entry{{
			ID: "com.example.hello", Name: "Hello", Version: "1.0.0",
			Description: "d", Author: "Example", AuthorID: "github:example",
			AuthorKey: testPubKeyLine(t),
			Rating:    4.5, RatingsCount: 10, Installs: 100,
			Badges: []string{"verified"}, Categories: []string{"tools"},
			Permissions: []string{"notifications"},
			DownloadURL: "https://example.com/hello.soraext",
			Sha256:      "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
			Size:        1024, MinAppVer: "1.9.0",
		}},
	}
	raw, _ := json.Marshal(good)
	if _, err := ParseCatalog(raw); err != nil {
		t.Fatalf("valid catalog rejected: %v", err)
	}
	bad := *good
	bad.Extensions[0].Rating = 7
	raw, _ = json.Marshal(bad)
	if _, err := ParseCatalog(raw); err == nil {
		t.Fatal("rating > 5 must be rejected")
	}
	bad2 := *good
	bad2.Extensions[0].DownloadURL = "http://example.com/hello.soraext"
	raw, _ = json.Marshal(bad2)
	if _, err := ParseCatalog(raw); err == nil {
		t.Fatal("non-https download URL must be rejected")
	}
	bad3 := *good
	bad3.Extensions[0].Badges = []string{"hacker-approved"}
	raw, _ = json.Marshal(bad3)
	if _, err := ParseCatalog(raw); err == nil {
		t.Fatal("unknown badge must be rejected")
	}
}

func TestHostPermissionScoping(t *testing.T) {
	issuer := NewTokenIssuer()
	deps := Deps{
		VerifyControl: func(tok []byte) bool { return string(tok) == "control" },
		ListConnections: func(ctx context.Context) ([]Connection, error) {
			return []Connection{{ID: "1", Process: "curl", Host: "example.com", Up: 10, Down: 20}}, nil
		},
	}
	h := NewHost(issuer, deps)
	ctx := context.Background()

	// Mint requires the control token.
	if _, err := h.MintToken(ctx, mintReq("wrong", "com.example.hello", []string{"connections.read"})); err == nil {
		t.Fatal("mint with a bad control token must fail")
	}
	mintResp, err := h.MintToken(ctx, mintReq("control", "com.example.hello", []string{"connections.read"}))
	if err != nil {
		t.Fatalf("mint failed: %v", err)
	}
	extTok := mintResp.GetExtensionToken()

	// connections.read allows GetConnections.
	conns, err := h.GetConnections(ctx, connReq(extTok))
	if err != nil {
		t.Fatalf("GetConnections failed: %v", err)
	}
	if len(conns.GetConnections()) != 1 || conns.GetConnections()[0].GetProcess() != "curl" {
		t.Fatalf("bad connections: %v", conns)
	}
	// ... but not Notify (no "notifications" grant).
	if _, err := h.Notify(ctx, notifyReq(extTok, "t", "b")); err == nil {
		t.Fatal("Notify without the permission must fail")
	}
	// Unknown token fails.
	if _, err := h.GetConnections(ctx, connReq([]byte("bogus"))); err == nil {
		t.Fatal("bogus token must fail")
	}
	// Revoke kills the token.
	if _, err := h.RevokeToken(ctx, revokeReq("control", extTok)); err != nil {
		t.Fatal(err)
	}
	if _, err := h.GetConnections(ctx, connReq(extTok)); err == nil {
		t.Fatal("revoked token must fail")
	}
	// Revoke requires the control token too.
	mintResp2, err := h.MintToken(ctx, mintReq("control", "com.example.hello", []string{"connections.read"}))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := h.RevokeToken(ctx, revokeReq("wrong", mintResp2.GetExtensionToken())); err == nil {
		t.Fatal("revoke with a bad control token must fail")
	}
}

func TestHostNotifyValidation(t *testing.T) {
	issuer := NewTokenIssuer()
	var gotTitle string
	h := NewHost(issuer, Deps{
		VerifyControl: func(tok []byte) bool { return true },
		Notify: func(ctx context.Context, extID, title, body string) error {
			gotTitle = title
			return nil
		},
	})
	ctx := context.Background()
	mintResp, err := h.MintToken(ctx, mintReq("control", "com.example.hello", []string{"notifications"}))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := h.Notify(ctx, notifyReq(mintResp.GetExtensionToken(), "Hi", "body")); err != nil {
		t.Fatalf("notify failed: %v", err)
	}
	if gotTitle != "Hi" {
		t.Fatalf("notify not delivered: %q", gotTitle)
	}
	if _, err := h.Notify(ctx, notifyReq(mintResp.GetExtensionToken(), "", "body")); err == nil {
		t.Fatal("empty title must be rejected")
	}
}

// --- proto request helpers ---

func mintReq(control, id string, perms []string) *extv1.MintTokenRequest {
	return &extv1.MintTokenRequest{ControlToken: []byte(control), ExtensionId: id, Permissions: perms}
}

func revokeReq(control string, tok []byte) *extv1.RevokeTokenRequest {
	return &extv1.RevokeTokenRequest{ControlToken: []byte(control), ExtensionToken: tok}
}

func connReq(tok []byte) *extv1.GetConnectionsRequest {
	return &extv1.GetConnectionsRequest{ExtensionToken: tok}
}

func notifyReq(tok []byte, title, body string) *extv1.NotifyRequest {
	return &extv1.NotifyRequest{ExtensionToken: tok, Title: title, Body: body}
}
