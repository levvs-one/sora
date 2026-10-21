package engine

import (
	"encoding/hex"
	"fmt"
	"strings"
)

// OlcrtcConfig carries one OpenLibre olcrtc server: a provider, a
// transport, a room on the provider's SFU and the transport parameters
// of its share link. An olcrtc outbound has no host:port endpoint —
// the provider is reached by room, not by address — so the outbound's
// Server mirrors Room for display and redaction, and Port stays 0.
//
// The configuration rides the credential document (see
// core/control): Provider, Room, Transport and Params are restored
// from it on every plan build, so an imported server survives a core
// restart whole. The encryption key itself is the outbound's Password
// (exactly 64 hex characters, 32 bytes — the OLC2 record-layer PSK).
//
// Sora is a client only: Mode is "" (the link carries no mode) or
// "cnc". A plan asking for the server mode ("srv") is always
// rejected — rendering one would turn the user's machine into an
// egress for strangers.
type OlcrtcConfig struct {
	// Provider is the SFU provider registry name: jitsi, telemost,
	// wbstream or none.
	Provider string
	// Transport is the olcrtc transport name: datachannel,
	// vp8channel, seichannel or videochannel. It lives here, not in
	// Outbound.Transport: that field names stream transports of the
	// proxy protocols and none of its values describe a media
	// channel.
	Transport string
	// Room is the provider room id, verbatim (a jitsi room is a full
	// URL). Empty is valid only for provider none.
	Room string
	// Channel is the optional peer-routing channel id (room.channel
	// in the olcrtc YAML). Share links do not carry it today; the
	// field exists so a stored document can.
	Channel string
	// AuthToken is a pre-issued provider account token (auth.token
	// in the YAML; wbstream's moderator token). Secret: it is masked
	// like a password and never leaves the credential document.
	AuthToken string
	// Mode is "" or "cnc". Anything else — above all "srv" — is
	// rejected by validation, here and again in the sidecar wrapper.
	Mode string
	// Params holds the transport parameters under their share-link
	// (URI) names ("fps", "vp8-batch", "video-codec", ...), exactly
	// as imported. The sidecar renderer translates them to YAML per
	// SPEC §3.2; unknown keys are preserved here for forward
	// compatibility and skipped by the renderer, whose YAML schema
	// is strict.
	Params map[string]string
}

// OlcrtcProviders is the closed provider registry of the olcrtc code,
// mirrored from the parser's registry: the two must agree, because a
// provider the plan accepts but the sidecar does not know would fail
// only after the session started.
var OlcrtcProviders = map[string]bool{
	"jitsi": true, "telemost": true, "wbstream": true, "none": true,
}

// OlcrtcTransports is the closed transport registry of the olcrtc
// code, mirrored like OlcrtcProviders.
var OlcrtcTransports = map[string]bool{
	"datachannel": true, "vp8channel": true, "seichannel": true, "videochannel": true,
}

// IsOlcrtcKey reports whether s is a well-formed olcrtc encryption
// key: exactly 64 hex characters (32 bytes).
func IsOlcrtcKey(s string) bool {
	if len(s) != 64 {
		return false
	}
	raw, err := hex.DecodeString(s)
	return err == nil && len(raw) == 32
}

// validateOlcrtc checks the structural shape of an olcrtc outbound:
// registry membership, key shape, the room rule and the client-only
// mode rule. Provider×transport compatibility and the wbstream token
// rule are connection properties, checked by the sidecar wrapper at
// connect time (core/engine/olcwrap), not here — the same split the
// import layer uses.
func (o Outbound) validateOlcrtc() []error {
	var errs []error
	bad := func(format string, args ...any) {
		errs = append(errs, fmt.Errorf("outbound %s: "+format, append([]any{o.ID}, args...)...))
	}
	if o.Olcrtc == nil {
		bad("olcrtc outbound carries no olcrtc configuration")
		return errs
	}
	c := o.Olcrtc
	if c.Mode != "" && c.Mode != "cnc" {
		// "srv" above all: sora never runs an olcrtc egress.
		bad("olcrtc mode %q is refused: sora is a client only (\"cnc\")", c.Mode)
	}
	if !OlcrtcProviders[c.Provider] {
		bad("unknown olcrtc provider %q", c.Provider)
	}
	if !OlcrtcTransports[c.Transport] {
		bad("unknown olcrtc transport %q", c.Transport)
	}
	if c.Room == "" && c.Provider != "none" {
		bad("olcrtc provider %q needs a room id", c.Provider)
	}
	if c.Provider == "wbstream" && c.Room == "any" {
		bad("olcrtc wbstream room id %q is a placeholder, not a room", c.Room)
	}
	if !IsOlcrtcKey(o.Password) {
		bad("olcrtc encryption key must be exactly 64 hex characters")
	}
	if o.SOCKSUDP {
		// The sidecar listener has no UDP association; promising it
		// here would let a renderer advertise UDP the tunnel cannot
		// carry. The honest labels ride Warnings instead.
		bad("olcrtc carries no UDP: SOCKSUDP must be off")
	}
	if strings.TrimSpace(c.Room) != c.Room || strings.ContainsAny(c.Room, "\r\n\x00") {
		bad("olcrtc room id contains control characters or padding")
	}
	return errs
}

// olcrtcWarnings returns the honest v1 capability labels of an
// olcrtc outbound: the community tunnel is TCP-only and its egress
// dials IPv4 only, and the UI must be able to say so instead of
// presenting the server as a general-purpose one. The codes ride
// Outbound.Warnings, the mechanism every other limitation label
// uses; clients localize them.
func (o Outbound) olcrtcWarnings() []string {
	if o.Protocol != ProtocolOLCRTC {
		return nil
	}
	return []string{"olcrtc-tcp-only", "olcrtc-ipv4-only"}
}
