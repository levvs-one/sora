package control

// B1 servers audit (round-trip): subscriptions, custom servers, and the
// benchmark resolver, exercised end to end through the real vault and
// the real plan builder — not by reading code.

import (
	"context"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/custom"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	customv1 "github.com/levvs-one/sora-client/core/gen/sora/custom/v1"
	"github.com/levvs-one/sora-client/core/subscription"
)

// TestCustomServersBuildPlans is the CRUD round-trip for every protocol
// the custom-server form accepts: save → read back as an outbound →
// the plan builds and validates → delete → gone from the merged list.
// Before the B1 fix every protocol failed the plan step: the raw
// credential string (bare UUID/password/key) was stored in the vault
// while outboundFromProto demands a credential document.
func TestCustomServersBuildPlans(t *testing.T) {
	const uuid = "123e4567-e89b-12d3-a456-426614174000"
	for _, tc := range []struct {
		name      string
		proto     customv1.CustomProtocol
		cred      string
		wantUUID  string
		wantPass  string
		wantKey   string
		wantMeth  string
		wantSec   string
		wantTrans string
	}{
		{"vless", customv1.CustomProtocol_CUSTOM_PROTOCOL_VLESS, uuid, uuid, "", "", "", "none", "tcp"},
		{"vmess", customv1.CustomProtocol_CUSTOM_PROTOCOL_VMESS, uuid, uuid, "", "", "auto", "none", "tcp"},
		{"trojan", customv1.CustomProtocol_CUSTOM_PROTOCOL_TROJAN, "secret-password", "", "secret-password", "", "", "tls", "tcp"},
		{"shadowsocks", customv1.CustomProtocol_CUSTOM_PROTOCOL_SHADOWSOCKS, "aes-256-gcm:secret-password", "", "secret-password", "", "aes-256-gcm", "none", "tcp"},
		{"wireguard", customv1.CustomProtocol_CUSTOM_PROTOCOL_WIREGUARD, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "", "", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "", "none", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			srv, token := customTestPlane(t)
			c := customImpl(t, srv)
			ctx := context.Background()
			saved, err := c.SaveCustomServer(ctx, &customv1.SaveCustomServerRequest{
				ApiVersion: customVersion(), ControlAuthenticator: token,
				Server: &customv1.CustomServer{Name: "Mine", Protocol: tc.proto, Address: "vpn.example.com", Port: 443, Credentials: tc.cred},
			})
			if err != nil || saved.GetError() != nil {
				t.Fatalf("save: %v %v", err, saved.GetError())
			}
			outs := srv.CustomOutbounds()
			if len(outs) != 1 {
				t.Fatalf("outbounds = %d, want 1", len(outs))
			}
			spec := outs[0]
			if spec.GetSecurity() != tc.wantSec || spec.GetTransport() != tc.wantTrans {
				t.Fatalf("spec security/transport = %q/%q, want %q/%q", spec.GetSecurity(), spec.GetTransport(), tc.wantSec, tc.wantTrans)
			}
			plan, err := planFromProto(&corev1.SessionPlan{
				TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
				Outbounds:  outs,
			}, "sess-b1", srv.secrets)
			if err != nil {
				t.Fatalf("planFromProto: %v", err)
			}
			if err := plan.Validate(); err != nil {
				t.Fatalf("plan.Validate: %v", err)
			}
			o := plan.Outbounds[0]
			if o.UUID != tc.wantUUID || o.Password != tc.wantPass || o.PrivateKey != tc.wantKey || o.Cipher != tc.wantMeth {
				t.Fatalf("outbound credentials = uuid %q password %q key %q cipher %q", o.UUID, o.Password, o.PrivateKey, o.Cipher)
			}
			// The benchmark/chain resolver must see custom servers too.
			found, missing := srv.resolveBenchmarkServers([]string{spec.GetId()})
			if len(found) != 1 || len(missing) != 0 {
				t.Fatalf("benchmark resolve custom: found %d missing %v", len(found), missing)
			}
			if _, err := c.DeleteCustomServer(ctx, &customv1.DeleteCustomServerRequest{
				ApiVersion: customVersion(), ControlAuthenticator: token, Id: saved.GetServer().GetId(),
			}); err != nil {
				t.Fatalf("delete: %v", err)
			}
			if n := len(srv.CustomOutbounds()); n != 0 {
				t.Fatalf("outbounds after delete = %d, want 0", n)
			}
			// A stale plan naming the deleted server fails honestly:
			// its credential reference is gone from the vault.
			if _, err := planFromProto(&corev1.SessionPlan{
				TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
				Outbounds:  []*corev1.OutboundSpec{spec},
			}, "sess-b1", srv.secrets); err == nil {
				t.Fatal("stale plan after custom delete unexpectedly succeeded")
			}
		})
	}
}

// TestCustomLegacyRawCredentialsMigrateOnOpen covers vault entries
// written before the credential-document conversion: a raw UUID stored
// by the old SaveCustomServer path must become a credential document
// the first time the store is opened through the control plane, so the
// server starts building plans without being re-saved.
func TestCustomLegacyRawCredentialsMigrateOnOpen(t *testing.T) {
	srv, _ := customTestPlane(t)
	const uuid = "123e4567-e89b-12d3-a456-426614174000"
	legacy, err := custom.Open(filepath.Join(srv.dataDir, "custom"), srv.secrets)
	if err != nil {
		t.Fatal(err)
	}
	stored, err := legacy.Save(custom.Server{
		Name: "Legacy", Protocol: custom.ProtocolVLESS, Address: "vpn.example.com", Port: 443,
	}, []byte(uuid))
	if err != nil {
		t.Fatal(err)
	}
	raw, err := srv.secrets.Get(stored.SecretRef)
	if err != nil || string(raw) != uuid {
		t.Fatalf("precondition: vault holds %q, %v; want the raw legacy string", raw, err)
	}
	outs := srv.CustomOutbounds() // first control-plane open: migration runs
	if len(outs) != 1 {
		t.Fatalf("outbounds = %d, want 1", len(outs))
	}
	migrated, err := srv.secrets.Get(stored.SecretRef)
	if err != nil || !isCredentialDocument(migrated) {
		t.Fatalf("vault after open holds %q, %v; want a credential document", migrated, err)
	}
	plan, err := planFromProto(&corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM, Outbounds: outs,
	}, "sess-b1", srv.secrets)
	if err != nil {
		t.Fatalf("planFromProto after migration: %v", err)
	}
	if plan.Outbounds[0].UUID != uuid {
		t.Fatalf("uuid = %q, want %q", plan.Outbounds[0].UUID, uuid)
	}
}

// TestWireGuardImportsBuildPlans pins the parser→plan round-trip for
// both WireGuard import shapes: the parser labels WireGuard specs with
// transport "udp", which plan validation used to reject outright, so
// no imported WireGuard server could ever connect.
func TestWireGuardImportsBuildPlans(t *testing.T) {
	srv, _ := bookServer(t, t.TempDir(), &panel{body: servers("a")})
	for name, payload := range map[string]string{
		"link": "wireguard://cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk%3D@198.51.100.7:51820" +
			"?publickey=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw%3D&address=10.7.0.2#WG",
		"conf": "[Interface]\nPrivateKey = cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=\nAddress = 10.7.0.2\n\n" +
			"[Peer]\nPublicKey = Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw=\nEndpoint = 198.51.100.7:51820\nAllowedIPs = 0.0.0.0/0\n",
	} {
		t.Run(name, func(t *testing.T) {
			resp, err := srv.ParseImport(context.Background(), &corev1.ParseImportRequest{
				ApiVersion: customVersion(), Payload: []byte(payload),
			})
			if err != nil || resp.GetError() != nil {
				t.Fatalf("ParseImport: %v %v", err, resp.GetError())
			}
			plan, err := planFromProto(resp.GetSessionPlan(), "sess-b1", srv.secrets)
			if err != nil {
				t.Fatalf("planFromProto: %v", err)
			}
			if err := plan.Validate(); err != nil {
				t.Fatalf("plan.Validate: %v", err)
			}
			o := plan.Outbounds[0]
			if o.Transport.Type != "" || o.PrivateKey == "" || len(o.Peers) != 1 {
				t.Fatalf("outbound = transport %q key %q peers %d", o.Transport.Type, o.PrivateKey, len(o.Peers))
			}
		})
	}
}

// TestImportedProtocolsBuildPlans is the parser round-trip for the
// remaining share-link protocols: import → plan builds and validates.
func TestImportedProtocolsBuildPlans(t *testing.T) {
	srv, _ := bookServer(t, t.TempDir(), &panel{body: servers("a")})
	links := map[string]string{
		"vless":     "vless://123e4567-e89b-12d3-a456-426614174000@h.example.com:443?security=reality&pbk=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&sid=ab12&fp=chrome#x",
		"vmess":     "vmess://123e4567-e89b-12d3-a456-426614174000@h.example.com:443#x",
		"trojan":    "trojan://pass@h.example.com:443?security=tls#x",
		"ss":        "ss://aes-256-gcm:pass@h.example.com:8388#x",
		"socks5":    "socks5://user:pass@h.example.com:1080#x",
		"hysteria2": "hysteria2://pass@h.example.com:443#x",
		"tuic":      "tuic://123e4567-e89b-12d3-a456-426614174000:pass@h.example.com:443#x",
	}
	for name, link := range links {
		t.Run(name, func(t *testing.T) {
			resp, err := srv.ParseImport(context.Background(), &corev1.ParseImportRequest{
				ApiVersion: customVersion(), Payload: []byte(link),
			})
			if err != nil || resp.GetError() != nil {
				t.Fatalf("ParseImport: %v %v", err, resp.GetError())
			}
			plan, err := planFromProto(resp.GetSessionPlan(), "sess-b1", srv.secrets)
			if err != nil {
				t.Fatalf("planFromProto: %v", err)
			}
			if err := plan.Validate(); err != nil {
				t.Fatalf("plan.Validate: %v", err)
			}
		})
	}
}

// TestSIP008SubscriptionImportsEndToEnd is the subscription-level
// regression for the SIP008 parser fix.
func TestSIP008SubscriptionImportsEndToEnd(t *testing.T) {
	body := `{"version":1,"servers":[{"id":"1","remarks":"tokyo-ss","server":"tokyo.example.com","server_port":8388,"password":"pw1","method":"aes-256-gcm"}]}`
	srv, _ := bookServer(t, t.TempDir(), &panel{body: body})
	st := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/sip008"})
	if st.GetLastError() != nil {
		t.Fatalf("state error: %v", st.GetLastError())
	}
	outs := st.GetOutbounds()
	if len(outs) != 1 || outs[0].GetProtocol() != "shadowsocks" || outs[0].GetDisplayName() != "tokyo-ss" {
		t.Fatalf("outbounds = %v", outs)
	}
	plan, err := planFromProto(&corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM, Outbounds: outs,
	}, "sess-b1", srv.secrets)
	if err != nil {
		t.Fatalf("planFromProto: %v", err)
	}
	if plan.Outbounds[0].Password != "pw1" || plan.Outbounds[0].Cipher != "aes-256-gcm" {
		t.Fatalf("outbound = %+v", plan.Outbounds[0])
	}
}

// TestSubscriptionRefreshDeduplicatesByStableKey pins the book-level
// dedup the B1 audit was asked to verify on the subscriptionBook path
// itself (not just in the parser): a refresh whose payload repeats one
// server must store exactly one outbound and exactly one vault
// credential reference for it.
func TestSubscriptionRefreshDeduplicatesByStableKey(t *testing.T) {
	p := &panel{body: servers("tokyo") + "\n" + servers("tokyo")}
	srv, store := bookServer(t, t.TempDir(), p)
	st := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc"})
	id := st.GetSettings().GetId()
	if len(st.GetOutbounds()) != 1 {
		t.Fatalf("outbounds = %d, want 1 after duplicate payload", len(st.GetOutbounds()))
	}
	refs := srv.subs.records[id].Servers
	if len(refs) != 1 {
		t.Fatalf("stored credential refs = %v, want exactly 1", refs)
	}
	count := 0
	for _, ref := range store.Refs() {
		if strings.HasPrefix(ref, "u1_"+id+"_") && !strings.HasSuffix(ref, "_rec") && !strings.Contains(ref, "_l") {
			count++
		}
	}
	if count != 1 {
		t.Fatalf("vault holds %d server credentials for the subscription, want 1", count)
	}
}

// TestRefreshKeepsServerIDsAcrossRename pins the identity rule the
// client's measurement history hangs off: a provider rename (same
// endpoint, same credential) must NOT change the server id, so
// latency/bandwidth history keyed by id survives a refresh, and the
// benchmark resolver keeps finding the server under the same id.
func TestRefreshKeepsServerIDsAcrossRename(t *testing.T) {
	p := &panel{body: servers("tokyo")}
	srv, _ := bookServer(t, t.TempDir(), p)
	st := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc"})
	id := st.GetSettings().GetId()
	oldID := st.GetOutbounds()[0].GetId()

	p.set("trojan://password-tokyo@tokyo.example.com:443?security=tls#renamed", nil)
	st2, err := srv.subs.refresh(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if st2.GetOutbounds()[0].GetId() != oldID || st2.GetOutbounds()[0].GetDisplayName() != "renamed" {
		t.Fatalf("after rename: id %q name %q, want id %q with the new name",
			st2.GetOutbounds()[0].GetId(), st2.GetOutbounds()[0].GetDisplayName(), oldID)
	}
	found, missing := srv.resolveBenchmarkServers([]string{oldID})
	if len(found) != 1 || len(missing) != 0 {
		t.Fatalf("benchmark resolve after rename: found %d missing %v", len(found), missing)
	}
}

// TestDeleteSubscriptionServerStaleChainPlanFails covers deletion of
// servers in use elsewhere: a chain plan over two subscription servers
// builds while they live; after the subscription is deleted the same
// (stale) plan fails honestly with the missing credential instead of
// crashing or silently connecting, and the subscription's overrides
// (pins/renames — the favourites analogue in the core) die with it.
func TestDeleteSubscriptionServerStaleChainPlanFails(t *testing.T) {
	p := &panel{body: servers("tokyo", "berlin")}
	srv, _ := bookServer(t, t.TempDir(), p)
	st := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc"})
	subID := st.GetSettings().GetId()
	srv.subs.overrides = subscription.NewOverrideStore(t.TempDir())
	specs := st.GetOutbounds()
	if err := srv.subs.overrides.Save(subID, &subscription.Override{
		PinnedOrder: []string{specs[0].GetId()},
		Renames:     map[string]string{specs[0].GetId(): "Fav"},
	}); err != nil {
		t.Fatal(err)
	}
	chainPlan := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  specs,
		Chain:      []string{specs[0].GetId(), specs[1].GetId()},
	}
	if _, err := planFromProto(chainPlan, "sess-b1", srv.secrets); err != nil {
		t.Fatalf("chain plan over live servers: %v", err)
	}
	if err := srv.subs.delete(subID); err != nil {
		t.Fatal(err)
	}
	if _, err := planFromProto(chainPlan, "sess-b1", srv.secrets); err == nil {
		t.Fatal("stale chain plan after subscription delete unexpectedly succeeded")
	}
	o, err := srv.subs.overrides.Load(subID)
	if err != nil {
		t.Fatal(err)
	}
	if len(o.PinnedOrder) != 0 || len(o.Renames) != 0 {
		t.Fatalf("overrides survived the subscription delete: %+v", o)
	}
}
