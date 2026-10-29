package control

import (
	"context"
	"sync"
	"testing"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/hwid"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/subscription"
)

// devicePanel records the device identity each fetch carried.
type devicePanel struct {
	mu   sync.Mutex
	seen []*hwid.Identity
}

func (p *devicePanel) Fetch(_ context.Context, _ string, opts subscription.FetchOptions) (subscription.Result, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.seen = append(p.seen, opts.Device)
	return subscription.Result{Body: []byte(servers("tokyo"))}, nil
}

func (p *devicePanel) last() *hwid.Identity {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.seen[len(p.seen)-1]
}

func TestDeviceIdentityReferenceFitsTheVault(t *testing.T) {
	if err := secret.ValidateReference(deviceIdentityRef); err != nil {
		t.Fatal(err)
	}
}

func TestSavedSubscriptionsSendTheDeviceIdentityUnlessTurnedOff(t *testing.T) {
	p := &devicePanel{}
	srv, _ := bookServer(t, t.TempDir(), p)
	token := srv.auth.Token()
	version := &corev1.ApiVersion{Major: 1}
	ctx := context.Background()

	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc", AutoUpdate: true})
	id := state.GetSettings().GetId()
	identity, err := srv.GetDeviceIdentity(ctx, &corev1.GetDeviceIdentityRequest{ApiVersion: version, ControlAuthenticator: token})
	if err != nil || identity.GetError() != nil {
		t.Fatal(err, identity.GetError())
	}
	sent := p.last()
	if sent == nil || sent.HWID != identity.GetIdentity().GetHwid() || !identity.GetIdentity().GetEnabled() || !hwid.Valid(sent.HWID) {
		t.Fatalf("a new subscription sent %+v, identity %v", sent, identity.GetIdentity())
	}

	off := state.GetSettings()
	off.DeviceIdentityOff = true
	if _, err := srv.subs.save(off); err != nil {
		t.Fatal(err)
	}
	if _, err := srv.subs.refresh(ctx, id); err != nil {
		t.Fatal(err)
	}
	if p.last() != nil {
		t.Fatalf("the subscription turned off still sent %+v", p.last())
	}
	if got := srv.subs.stateLocked(id).GetSettings().GetDeviceIdentityOff(); !got {
		t.Fatal("the state does not show the subscription's choice")
	}

	off.DeviceIdentityOff = false
	if _, err := srv.subs.save(off); err != nil {
		t.Fatal(err)
	}
	if _, err := srv.SetDeviceIdentity(ctx, &corev1.SetDeviceIdentityRequest{ApiVersion: version, ControlAuthenticator: token, Enabled: false}); err != nil {
		t.Fatal(err)
	}
	if _, err := srv.subs.refresh(ctx, id); err != nil {
		t.Fatal(err)
	}
	if p.last() != nil {
		t.Fatalf("the global switch is off but the fetch sent %+v", p.last())
	}
}

func TestDeviceIdentityResetPersistsAcrossRestarts(t *testing.T) {
	dir := t.TempDir()
	srv, store := bookServer(t, dir, &devicePanel{})
	token := srv.auth.Token()
	version := &corev1.ApiVersion{Major: 1}
	ctx := context.Background()

	before, err := srv.GetDeviceIdentity(ctx, &corev1.GetDeviceIdentityRequest{ApiVersion: version, ControlAuthenticator: token})
	if err != nil {
		t.Fatal(err)
	}
	if machine, err := hwid.Machine(); err == nil && before.GetIdentity().GetHwid() != machine {
		t.Fatalf("the default identifier %q is not the one derived from the machine %q", before.GetIdentity().GetHwid(), machine)
	}
	reset, err := srv.SetDeviceIdentity(ctx, &corev1.SetDeviceIdentityRequest{ApiVersion: version, ControlAuthenticator: token, Enabled: true, Regenerate: true})
	if err != nil || reset.GetError() != nil {
		t.Fatal(err, reset.GetError())
	}
	after := reset.GetIdentity().GetHwid()
	if after == before.GetIdentity().GetHwid() || !hwid.Valid(after) || !reset.GetIdentity().GetEnabled() {
		t.Fatalf("reset gave %v after %v", reset.GetIdentity(), before.GetIdentity())
	}
	_ = store.Close()

	again, _ := bookServer(t, dir, &devicePanel{})
	restarted, err := again.GetDeviceIdentity(ctx, &corev1.GetDeviceIdentityRequest{ApiVersion: version, ControlAuthenticator: again.auth.Token()})
	if err != nil || restarted.GetIdentity().GetHwid() != after {
		t.Fatalf("after a restart the identifier is %v, want %q (%v)", restarted.GetIdentity(), after, err)
	}
}

func TestDeviceIdentityNeedsTheControlAuthenticator(t *testing.T) {
	srv, _ := bookServer(t, t.TempDir(), &devicePanel{})
	version := &corev1.ApiVersion{Major: 1}
	if _, err := srv.GetDeviceIdentity(context.Background(), &corev1.GetDeviceIdentityRequest{ApiVersion: version}); err == nil {
		t.Fatal("the identifier was given without the authenticator")
	}
	if _, err := srv.SetDeviceIdentity(context.Background(), &corev1.SetDeviceIdentityRequest{ApiVersion: version, Regenerate: true}); err == nil {
		t.Fatal("the identifier was reset without the authenticator")
	}
}
