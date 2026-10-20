package control_test

import (
	"context"
	"testing"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

// newDeviceServer builds a control plane at contract 1.13 whose data
// directory holds the device identity store (C1).
func newDeviceServer(t *testing.T) (*control.Server, string) {
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
	dir := t.TempDir()
	server, err := control.New(control.Config{
		Version:       control.Version{Major: 1, Minor: 13, MinSupportedMinor: 1},
		Authenticator: auth,
		Sessions:      manager,
		DataDir:       dir,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return server, dir
}

func deviceVersion() *corev1.ApiVersion {
	return &corev1.ApiVersion{Major: 1, Minor: 13, MinSupportedMinor: 1}
}

// TestDeviceIdentityRPCRoundTrip pins the 1.13 settings surface: a
// fresh store answers enabled with a valid HWID, an opt-out sticks
// and empties the fetch header set, a plain set never regenerates the
// HWID, and a reset returns the NEW identifier.
func TestDeviceIdentityRPCRoundTrip(t *testing.T) {
	server, dir := newDeviceServer(t)
	ctx := context.Background()

	got, err := server.GetDeviceIdentity(ctx, &corev1.GetDeviceIdentityRequest{
		ApiVersion: deviceVersion(), ControlAuthenticator: testToken,
	})
	if err != nil {
		t.Fatalf("GetDeviceIdentity() error = %v", err)
	}
	if got.GetError() != nil {
		t.Fatalf("GetDeviceIdentity() error field = %v", got.GetError())
	}
	if !got.GetEnabled() {
		t.Error("fresh identity: enabled = false, want true (the default)")
	}
	if !subscription.ValidHWID(got.GetHwid()) {
		t.Fatalf("fresh identity: hwid %q is outside the shape providers accept", got.GetHwid())
	}
	first := got.GetHwid()

	// Opt out, with the interface's companion platform facts attached.
	set, err := server.SetDeviceIdentity(ctx, &corev1.SetDeviceIdentityRequest{
		ApiVersion: deviceVersion(), ControlAuthenticator: testToken,
		Enabled: false, VerOs: "6.8.0-test", DeviceModel: "Testbox 3000",
	})
	if err != nil {
		t.Fatalf("SetDeviceIdentity(false) error = %v", err)
	}
	if set.GetError() != nil {
		t.Fatalf("SetDeviceIdentity(false) error field = %v", set.GetError())
	}
	if set.GetEnabled() {
		t.Error("after opt-out: enabled = true, want false")
	}
	if set.GetHwid() != first {
		t.Errorf("opt-out changed the HWID: %q -> %q, want it preserved", first, set.GetHwid())
	}

	// The opt-out collapses the fetch header set to zero, companions
	// included (checked on the store the RPCs wrote to).
	store := subscription.NewDeviceStore(dir)
	headers, err := store.Headers("Linux")
	if err != nil {
		t.Fatalf("Headers() while disabled error = %v", err)
	}
	if headers != (subscription.DeviceHeaders{}) {
		t.Errorf("Headers() while disabled = %+v, want the zero set", headers)
	}

	// Re-enable without reset: same HWID, companions now sent.
	set, err = server.SetDeviceIdentity(ctx, &corev1.SetDeviceIdentityRequest{
		ApiVersion: deviceVersion(), ControlAuthenticator: testToken,
		Enabled: true, VerOs: "6.8.0-test", DeviceModel: "Testbox 3000",
	})
	if err != nil {
		t.Fatalf("SetDeviceIdentity(true) error = %v", err)
	}
	if !set.GetEnabled() || set.GetHwid() != first {
		t.Errorf("re-enable = {hwid:%q enabled:%v}, want {%q true}", set.GetHwid(), set.GetEnabled(), first)
	}
	headers, err = store.Headers("Linux")
	if err != nil {
		t.Fatalf("Headers() error = %v", err)
	}
	if headers.HWID != first || headers.VersionOS != "6.8.0-test" || headers.DeviceModel != "Testbox 3000" {
		t.Errorf("Headers() = %+v, want the stored HWID and companions", headers)
	}

	// Reset: the response carries the NEW, valid, persisted HWID.
	set, err = server.SetDeviceIdentity(ctx, &corev1.SetDeviceIdentityRequest{
		ApiVersion: deviceVersion(), ControlAuthenticator: testToken,
		Enabled: true, Reset_: true, VerOs: "6.8.0-test", DeviceModel: "Testbox 3000",
	})
	if err != nil {
		t.Fatalf("SetDeviceIdentity(reset) error = %v", err)
	}
	if set.GetHwid() == first || !subscription.ValidHWID(set.GetHwid()) {
		t.Errorf("reset hwid = %q, want a new valid identifier (was %q)", set.GetHwid(), first)
	}
	got, err = server.GetDeviceIdentity(ctx, &corev1.GetDeviceIdentityRequest{
		ApiVersion: deviceVersion(), ControlAuthenticator: testToken,
	})
	if err != nil || got.GetHwid() != set.GetHwid() || !got.GetEnabled() {
		t.Errorf("Get after reset = {%q %v}, %v; want the reset identity", got.GetHwid(), got.GetEnabled(), err)
	}

	// An invalid companion value is refused and changes nothing.
	set, err = server.SetDeviceIdentity(ctx, &corev1.SetDeviceIdentityRequest{
		ApiVersion: deviceVersion(), ControlAuthenticator: testToken,
		Enabled: false, VerOs: "bad\nvalue",
	})
	if err != nil {
		t.Fatalf("SetDeviceIdentity(bad ver_os) error = %v", err)
	}
	if set.GetError() == nil {
		t.Fatal("SetDeviceIdentity(bad ver_os) succeeded, want an error in the response")
	}
	got, err = server.GetDeviceIdentity(ctx, &corev1.GetDeviceIdentityRequest{
		ApiVersion: deviceVersion(), ControlAuthenticator: testToken,
	})
	if err != nil || !got.GetEnabled() {
		t.Errorf("after refused set: enabled = %v, %v; want still true", got.GetEnabled(), err)
	}
}

// TestDeviceIdentityRPCRequiresToken: both calls reject a bad token at
// the transport, like the log settings they mirror.
func TestDeviceIdentityRPCRequiresToken(t *testing.T) {
	server, _ := newDeviceServer(t)
	ctx := context.Background()
	if _, err := server.GetDeviceIdentity(ctx, &corev1.GetDeviceIdentityRequest{
		ApiVersion: deviceVersion(), ControlAuthenticator: []byte("wrong"),
	}); err == nil {
		t.Error("GetDeviceIdentity with a bad token succeeded, want a transport error")
	}
	if _, err := server.SetDeviceIdentity(ctx, &corev1.SetDeviceIdentityRequest{
		ApiVersion: deviceVersion(), ControlAuthenticator: []byte("wrong"), Enabled: true,
	}); err == nil {
		t.Error("SetDeviceIdentity with a bad token succeeded, want a transport error")
	}
}
