package control

import (
	"context"
	"runtime"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/subscription"
)

// Provider device identity (C1, HWID device limits).
//
// The identity lives in the core's DeviceStore (see
// core/subscription/device_store.go for why it cannot live in the
// interface), and both subscription fetch paths — the subscription
// book's refresh (manual, scheduled and expedited alike) and the
// one-off FetchSubscription RPC — take their header set from here, so
// the opt-out is honoured in exactly one place and no other request
// the core makes ever carries the identity.

// deviceOSName names the operating system the way panels expect in
// x-device-os. The core runs on the user's device, so its own OS is
// the honest value. An unlisted OS yields "": the header is omitted
// rather than guessed.
func deviceOSName() string {
	switch runtime.GOOS {
	case "windows":
		return "Windows"
	case "darwin":
		return "macOS"
	case "linux":
		return "Linux"
	case "android":
		return "Android"
	case "ios":
		return "iOS"
	}
	return ""
}

// deviceHeaders returns the device header set for one subscription
// fetch. The zero set means the user opted out (or no data directory
// is configured). A store error is propagated, never swallowed into a
// silent zero set: at a provider with a device limit a fetch without
// the identity fails with a bare 404, and the stored, actionable
// reason must reach the user instead. The error never contains the
// identifier itself.
func (s *Server) deviceHeaders() (subscription.DeviceHeaders, error) {
	if s == nil || s.device == nil {
		return subscription.DeviceHeaders{}, nil
	}
	return s.device.Headers(deviceOSName())
}

// The remaining platform facts from the circle-1 spec:
//
//   - x-ver-os and x-device-model: the core has no honest source for
//     the OS version or the hardware model, so since contract 1.13
//     the interface supplies them through SetDeviceIdentity (only
//     values its platform actually provides; empty omits the header)
//     and the store keeps them beside the identity — see
//     DeviceStore.SetPlatform and Headers. They are never fabricated
//     here.
//   - x-app-version: not a documented Remnawave header, and the core
//     does not know the interface app's version (its own build
//     version must not be relabelled as the app's). If the contract
//     ever carries the app version from the interface, it belongs in
//     DeviceHeaders beside the others, filled by this function.

// deviceStore returns the device identity store, or an explicit error
// when no data directory is configured (the identity is disabled).
func (s *Server) deviceStore() (*subscription.DeviceStore, error) {
	if s.device == nil {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyInternal,
			"control: device identity is not configured")
	}
	return s.device, nil
}

// GetDeviceIdentity returns the stored HWID and whether subscription
// fetches carry it (contract 1.13). Like the log settings, reading
// needs the control authenticator: the identifier is a stable
// per-install value.
func (s *Server) GetDeviceIdentity(_ context.Context, req *corev1.GetDeviceIdentityRequest) (*corev1.GetDeviceIdentityResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	store, err := s.deviceStore()
	if err != nil {
		return &corev1.GetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
	}
	hwid, err := store.HWID()
	if err != nil {
		return &corev1.GetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
	}
	enabled, err := store.Enabled()
	if err != nil {
		return &corev1.GetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
	}
	return &corev1.GetDeviceIdentityResponse{Hwid: hwid, Enabled: enabled}, nil
}

// SetDeviceIdentity records the opt-out choice, the companion
// platform facts the interface supplied, and — when reset is set — a
// fresh HWID (contract 1.13). The response always carries the
// resulting identity: after a reset that is the NEW value, which
// providers count as a new device. A set that changes nothing does
// not regenerate the HWID: SetEnabled and SetPlatform preserve it,
// and only reset replaces it.
func (s *Server) SetDeviceIdentity(_ context.Context, req *corev1.SetDeviceIdentityRequest) (*corev1.SetDeviceIdentityResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	store, err := s.deviceStore()
	if err != nil {
		return &corev1.SetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
	}
	// Companions first: an invalid value fails before anything is
	// recorded, so a rejected set never toggles or resets either.
	if err := store.SetPlatform(req.GetVerOs(), req.GetDeviceModel()); err != nil {
		return &corev1.SetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
	}
	if err := store.SetEnabled(req.GetEnabled()); err != nil {
		return &corev1.SetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
	}
	hwid := ""
	// The wire field is "reset"; protoc-gen-go spells the accessor
	// GetReset_ because Reset is the message's own reset method.
	if req.GetReset_() {
		hwid, err = store.Reset()
		if err != nil {
			return &corev1.SetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
		}
	} else {
		hwid, err = store.HWID()
		if err != nil {
			return &corev1.SetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
		}
	}
	enabled, err := store.Enabled()
	if err != nil {
		return &corev1.SetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
	}
	return &corev1.SetDeviceIdentityResponse{Hwid: hwid, Enabled: enabled}, nil
}
