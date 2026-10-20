package engine

import (
	"encoding/base64"
	"fmt"
	"net/netip"
	"strings"
)

// REALITY hardening: validation and warnings (T002).
//
// The field data is unambiguous: REALITY has no protocol-level detector in
// the wild, but deployments are classified as proxies through four
// mistakes — no vision (TLS-in-TLS, a detectable signal), stale uTLS,
// SNI↔ASN mismatch, shortId leaks. This file turns the client-checkable
// half of that into plan validation and user-facing warnings.
//
// Warnings (RealityWarnings) never block: they surface in the UI next to
// the server, and the UI may additionally offer a hard block for
// reality-without-vision (see the spec). Errors (ValidateReality) block:
// they name configurations that cannot work or that leak identity.
func (o Outbound) realityDest() string {
	if o.TLS.ServerName != "" {
		return o.TLS.ServerName
	}
	return o.Server
}

// IsVisionFlow reports whether flow is an XTLS vision variant. Vision
// changes what the censor can see inside the TLS stream, so several
// REALITY rules key off it.
func IsVisionFlow(flow string) bool {
	return flow == "xtls-rprx-vision" || flow == "xtls-rprx-vision-udp443"
}

// RealityWarnings returns human-readable warning codes for a REALITY
// outbound. Empty means nothing to warn about. The codes are stable UI
// contract: the app maps each to a localized message.
func (o Outbound) RealityWarnings() []string {
	if !o.TLS.Reality {
		return nil
	}
	var out []string
	transport := o.Transport.Type
	tcpish := transport == "" || transport == "tcp"
	if o.Protocol == ProtocolVLESS && tcpish && !IsVisionFlow(o.Flow) {
		// Without vision the inner TLS handshake is visible inside the
		// outer one: the TLS-in-TLS signal the censor already recognizes.
		out = append(out, "reality-without-vision")
	}
	if transport == "ws" {
		// WebSocket+REALITY is rejected by the Xray renderer; the warning
		// surfaces it earlier, at import/validation time.
		out = append(out, "reality-ws-transport")
	}
	if transport == "xhttp" && IsVisionFlow(o.Flow) && !o.HasVLESSEncryption() {
		// REALITY+XHTTP+vision without VLESS Encryption is not a legal
		// XTLS combination (REALITY is not Encryption); multiplexing
		// there is xmux's job, not vision's. With VLESS Encryption the
		// flow is legal on any transport, so no warning (PASS3 deep S3b).
		out = append(out, "reality-xhttp-vision")
	}
	if dest := o.realityDest(); dest != "" {
		if _, err := netip.ParseAddr(dest); err == nil {
			out = append(out, "reality-dest-ip")
		} else if strings.HasPrefix(dest, "http://") || strings.HasPrefix(dest, "https://") {
			out = append(out, "reality-dest-not-host")
		}
	} else {
		out = append(out, "reality-dest-missing")
	}
	return out
}

// ValidateReality rejects REALITY configurations that cannot work or that
// are malformed in ways the engines would silently misapply. A nil error
// means the cryptographic parameters are well-formed; it says nothing
// about whether the dest is a good decoy (see probe.CheckDest).
func (o Outbound) ValidateReality() error {
	if !o.TLS.Reality {
		return nil
	}
	if o.TLS.RealityPublicKey == "" {
		return fmt.Errorf("outbound %s: REALITY requires a public key", o.ID)
	}
	if !isX25519PublicKey(o.TLS.RealityPublicKey) {
		return fmt.Errorf("outbound %s: REALITY public key is not a 32-byte base64url X25519 key", o.ID)
	}
	if id := o.TLS.RealityShortID; id != "" && !isHexID(id, 8) {
		return fmt.Errorf("outbound %s: REALITY shortId must be hex, at most 8 bytes", o.ID)
	}
	return nil
}

// isX25519PublicKey checks the textual shape of a REALITY public key:
// 43 base64url characters decoding to 32 bytes. It does not (and cannot)
// check that the key belongs to the server — that is established by the
// handshake itself.
func isX25519PublicKey(s string) bool {
	if len(s) != 43 {
		return false
	}
	raw, err := base64.RawURLEncoding.DecodeString(s)
	return err == nil && len(raw) == 32
}

// isHexID checks hex shape with a byte-length cap.
func isHexID(s string, maxBytes int) bool {
	if len(s) == 0 || len(s) > 2*maxBytes || len(s)%2 != 0 {
		return false
	}
	for _, c := range s {
		if !(c >= '0' && c <= '9' || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F') {
			return false
		}
	}
	return true
}
