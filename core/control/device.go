package control

import (
	"runtime"

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

// The remaining platform facts from the circle-1 spec are
// deliberately not filled in here:
//
//   - x-ver-os and x-device-model: the core has no honest source for
//     the OS version or the hardware model. They are omitted, not
//     fabricated; the panel treats both as optional decoration.
//   - x-app-version: not a documented Remnawave header, and the core
//     does not know the interface app's version (its own build
//     version must not be relabelled as the app's). If the contract
//     ever carries the app version from the interface, it belongs in
//     DeviceHeaders beside the others, filled by this function.
