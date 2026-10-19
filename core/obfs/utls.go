package obfs

import (
	"crypto/tls"
	"errors"
	"fmt"
	"net"

	utls "github.com/refraction-networking/utls"
)

// ErrUTLSDisabled is returned when a uTLS operation is requested on a
// profile that selects no fingerprint ("none" or empty).
var ErrUTLSDisabled = errors.New("obfs: uTLS fingerprint disabled in profile")

// FingerprintID maps a profile fingerprint name to the uTLS
// ClientHelloID used for the handshake. It returns ErrUTLSDisabled for
// "none"/"" and an error for unknown names.
func (p Profile) FingerprintID() (utls.ClientHelloID, error) {
	switch normalizeUTLS(p.UTLS) {
	case UTLSChrome:
		return utls.HelloChrome_Auto, nil
	case UTLSFirefox:
		return utls.HelloFirefox_Auto, nil
	case UTLSSafari:
		return utls.HelloSafari_Auto, nil
	case UTLSRandomized:
		return utls.HelloRandomizedALPN, nil
	case "", UTLSNone:
		return utls.ClientHelloID{}, ErrUTLSDisabled
	default:
		return utls.ClientHelloID{}, fmt.Errorf("obfs: unknown UTLS fingerprint %q", p.UTLS)
	}
}

// UTLSConfig converts a crypto/tls Config into its uTLS equivalent,
// copying the fields that describe the endpoint rather than the
// fingerprint (the fingerprint comes from FingerprintID). It returns nil
// when the profile disables uTLS.
//
// The caller must ensure base is non-nil; a nil base yields a config with
// only the defaults.
func (p Profile) UTLSConfig(base *tls.Config) *utls.Config {
	if !p.UTLSEnabled() {
		return nil
	}
	out := &utls.Config{}
	if base == nil {
		return out
	}
	out.ServerName = base.ServerName
	out.InsecureSkipVerify = base.InsecureSkipVerify
	out.RootCAs = base.RootCAs
	out.ClientCAs = base.ClientCAs
	out.NextProtos = base.NextProtos
	out.MinVersion = base.MinVersion
	out.MaxVersion = base.MaxVersion
	out.SessionTicketsDisabled = base.SessionTicketsDisabled
	// Note: Certificates and ClientSessionCache are deliberately not
	// copied: utls uses its own certificate/session types, and client
	// authentication plus session resumption are irrelevant for the
	// short-lived handshakes (probing, DoH, subscription fetch) this
	// package serves.
	return out
}

// NewUTLSConn wraps conn in a uTLS client using the profile's fingerprint.
// The returned connection has not handshaked yet; call Handshake (or let
// the first Read/Write trigger it) as with crypto/tls.
//
// The ServerName must be set on cfg (via UTLSConfig from a base that sets
// it); otherwise the handshake cannot build a valid ClientHello.
func (p Profile) NewUTLSConn(conn net.Conn, cfg *utls.Config) (*utls.UConn, error) {
	id, err := p.FingerprintID()
	if err != nil {
		return nil, err
	}
	if conn == nil {
		return nil, errors.New("obfs: nil conn for uTLS client")
	}
	return utls.UClient(conn, cfg, id), nil
}
