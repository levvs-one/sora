package subscription

import (
	"crypto/rand"
	"fmt"
	"net/http"
	"regexp"
	"strings"

	"github.com/levvs-one/sora-client/core/errs"
)

// Device identity headers (C1, provider HWID device limits).
//
// Remnawave panels can limit how many devices may use one subscription
// ("HWID device limit", https://docs.rw/docs/features/hwid-device-limit).
// A panel with the limit on answers 404 to a subscription request that
// carries no x-hwid header, so a client that never sends one cannot
// fetch from such providers at all. The standard header set, offered by
// Happ and documented by Remnawave for client developers, is:
//
//	x-hwid:         unique per-install identifier (the only required one)
//	x-device-os:    OS name, e.g. "Linux" (optional)
//	x-ver-os:       OS version (optional)
//	x-device-model: device model (optional)
//	user-agent:     the usual User-Agent
//
// Since panel v3.0.0 the x-hwid value itself is validated against
// ^[a-zA-Z0-9=-]{10,64}$; a value outside that shape is ignored by the
// panel entirely, which is indistinguishable from not sending it.
//
// Sora's HWID is a random per-install identifier, NOT a hardware
// fingerprint: it is generated once from crypto/rand, stored by the
// core (see DeviceStore), and survives restarts and refreshes until
// the user resets it. It is sent only on subscription fetches — the
// primary reference, its fallback, and every redirect hop inside one
// fetch — and nowhere else: it is never logged and never appears in
// error details (the values below are validated without echoing them).
//
// x-app-version from the circle-1 spec is deliberately not part of
// this set: no public Remnawave or Happ source documents it, the panel
// ignores unknown headers, and the core does not know the interface
// app's version (its own build version is a different thing and must
// not be relabelled as the app's).

// hwidPattern is the shape panel v3.0.0+ accepts for x-hwid.
var hwidPattern = regexp.MustCompile(`^[a-zA-Z0-9=-]{10,64}$`)

// MaxDeviceField bounds one optional device header value.
const MaxDeviceField = 128

// DeviceHeaders is the validated device identity attached to one
// subscription fetch. The zero value sends no device headers at all:
// that is what an opt-out produces, and callers must not distinguish
// "disabled" from "unknown" on the wire.
type DeviceHeaders struct {
	// HWID is the stable per-install identifier. Empty sends nothing:
	// the whole set is dropped, because companion fields without the
	// identifier only fingerprint the device for no benefit.
	HWID string
	// DeviceOS is the operating system name ("Linux", "Windows", …),
	// sent as x-device-os. Optional.
	DeviceOS string
	// VersionOS is the operating system version, sent as x-ver-os.
	// Optional; empty when the platform does not honestly know it.
	VersionOS string
	// DeviceModel is the device model, sent as x-device-model.
	// Optional; empty when the platform does not honestly know it.
	DeviceModel string
}

// GenerateHWID returns a fresh random per-install identifier in UUID
// v4 form (36 characters, inside the panel's accepted shape). The
// value carries no hardware information: it names the installation,
// not the machine, and a reset simply generates another one.
func GenerateHWID() (string, error) {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	b[6] = (b[6] & 0x0f) | 0x40 // version 4
	b[8] = (b[8] & 0x3f) | 0x80 // variant 10xxxxxx
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16]), nil
}

// ValidHWID reports whether value has the shape panels accept.
func ValidHWID(value string) bool { return hwidPattern.MatchString(value) }

// validated returns the header set to send, or the zero set when the
// HWID is empty (opt-out / not configured). A present but malformed
// HWID is an error: silently dropping it would make a limited provider
// answer 404 with no explanation the user can act on. Error details
// never include the value itself.
func (d DeviceHeaders) validated() (DeviceHeaders, error) {
	out := DeviceHeaders{
		HWID:        strings.TrimSpace(d.HWID),
		DeviceOS:    strings.TrimSpace(d.DeviceOS),
		VersionOS:   strings.TrimSpace(d.VersionOS),
		DeviceModel: strings.TrimSpace(d.DeviceModel),
	}
	if out.HWID == "" {
		return DeviceHeaders{}, nil
	}
	if !ValidHWID(out.HWID) {
		return DeviceHeaders{}, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the device identifier does not have the shape providers accept")
	}
	for _, field := range []string{out.DeviceOS, out.VersionOS, out.DeviceModel} {
		if err := checkDeviceField(field); err != nil {
			return DeviceHeaders{}, err
		}
	}
	return out, nil
}

// checkDeviceField rejects header-injection shapes in one companion
// value, without echoing the value in the error.
func checkDeviceField(field string) error {
	if len(field) > MaxDeviceField {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: a device header value is longer than %d bytes", MaxDeviceField)
	}
	for _, r := range field {
		if r < 0x20 || r > 0x7e {
			return errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
				"subscription: a device header value may hold printable ASCII only")
		}
	}
	return nil
}

// apply sets the device headers on one request. Every hop of a fetch
// builds a fresh request, so applying here is what carries the set
// across redirects exactly like the User-Agent.
func (d DeviceHeaders) apply(header http.Header) {
	if d.HWID == "" {
		return
	}
	header.Set("x-hwid", d.HWID)
	if d.DeviceOS != "" {
		header.Set("x-device-os", d.DeviceOS)
	}
	if d.VersionOS != "" {
		header.Set("x-ver-os", d.VersionOS)
	}
	if d.DeviceModel != "" {
		header.Set("x-device-model", d.DeviceModel)
	}
}
