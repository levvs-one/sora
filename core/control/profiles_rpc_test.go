package control_test

import (
	"context"
	"testing"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/profiles"
	"github.com/levvs-one/sora-client/core/session"
)

// newProfileServer builds a control plane with a profile store but no
// secrets, mirroring newTestServer.
func newProfileServer(t *testing.T) *control.Server {
	t.Helper()
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatalf("NewAuthenticator() error = %v", err)
	}
	manager := session.NewManager(session.ManagerConfig{
		TunUp: noAdapter,
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return newStubEngine(), nil
		},
	})
	store, err := profiles.NewStore(t.TempDir())
	if err != nil {
		t.Fatalf("NewStore() error = %v", err)
	}
	server, err := control.New(control.Config{
		Version:       control.Version{Major: 1, Minor: 10, MinSupportedMinor: 1},
		Authenticator: auth,
		Sessions:      manager,
		Profiles:      store,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return server
}

func profileVersion() *corev1.ApiVersion {
	return &corev1.ApiVersion{Major: 1, Minor: 10, MinSupportedMinor: 1}
}

func TestProfileRPCRoundTrip(t *testing.T) {
	s := newProfileServer(t)
	ctx := context.Background()
	auth := &corev1.ListProfilesRequest{ApiVersion: profileVersion(), ControlAuthenticator: testToken}

	list, err := s.ListProfiles(ctx, auth)
	if err != nil {
		t.Fatal(err)
	}
	if len(list.GetProfiles()) != 0 {
		t.Fatalf("fresh store lists %d profiles", len(list.GetProfiles()))
	}

	saved, err := s.SaveProfile(ctx, &corev1.SaveProfileRequest{
		ApiVersion: profileVersion(), ControlAuthenticator: testToken,
		Profile: &corev1.NetworkProfile{
			Name:     "Home",
			Triggers: &corev1.ProfileTriggers{Ssids: []string{"Home_Network"}},
			Apply:    &corev1.ProfileApply{Mode: "tun", Dns: []string{"1.1.1.1"}},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	if saved.GetError() != nil {
		t.Fatalf("save failed: %v", saved.GetError())
	}
	if saved.GetProfile().GetId() == "" {
		t.Fatal("saved profile must get an id")
	}

	list, err = s.ListProfiles(ctx, auth)
	if err != nil {
		t.Fatal(err)
	}
	if len(list.GetProfiles()) != 1 || list.GetProfiles()[0].GetName() != "Home" {
		t.Fatalf("list shows %v", list.GetProfiles())
	}

	if _, err := s.DeleteProfile(ctx, &corev1.DeleteProfileRequest{
		ApiVersion: profileVersion(), ControlAuthenticator: testToken,
		ProfileId: saved.GetProfile().GetId(),
	}); err != nil {
		t.Fatal(err)
	}
	list, err = s.ListProfiles(ctx, auth)
	if err != nil {
		t.Fatal(err)
	}
	if len(list.GetProfiles()) != 0 {
		t.Fatal("delete must remove the profile")
	}
}

func TestSaveProfileRejectsBadInput(t *testing.T) {
	s := newProfileServer(t)
	ctx := context.Background()
	for _, p := range []*corev1.NetworkProfile{
		{Name: ""},
		{Name: "x", Triggers: &corev1.ProfileTriggers{Gateways: []string{"nope"}}},
		{Name: "x", Apply: &corev1.ProfileApply{Mode: "turbo"}},
	} {
		resp, err := s.SaveProfile(ctx, &corev1.SaveProfileRequest{
			ApiVersion: profileVersion(), ControlAuthenticator: testToken, Profile: p,
		})
		if err != nil {
			t.Fatal(err)
		}
		if resp.GetError() == nil {
			t.Errorf("profile %+v must be rejected", p)
		}
	}
}

func TestProfileRPCsNeedAuth(t *testing.T) {
	s := newProfileServer(t)
	ctx := context.Background()
	bad := &corev1.ApiVersion{Major: 1, Minor: 10}
	if _, err := s.ListProfiles(ctx, &corev1.ListProfilesRequest{ApiVersion: bad, ControlAuthenticator: []byte("wrong")}); err == nil {
		t.Fatal("ListProfiles without a token must fail")
	}
	if _, err := s.GetNetworkFingerprint(ctx, &corev1.GetNetworkFingerprintRequest{ApiVersion: bad}); err == nil {
		t.Fatal("GetNetworkFingerprint without a token must fail")
	}
}

func TestGetNetworkFingerprintShape(t *testing.T) {
	s := newProfileServer(t)
	resp, err := s.GetNetworkFingerprint(context.Background(), &corev1.GetNetworkFingerprintRequest{
		ApiVersion: profileVersion(), ControlAuthenticator: testToken,
	})
	if err != nil {
		t.Fatal(err)
	}
	if resp.GetError() != nil {
		t.Fatalf("fingerprint failed: %v", resp.GetError())
	}
	if resp.GetFingerprint() == nil {
		t.Fatal("fingerprint must not be nil")
	}
}
