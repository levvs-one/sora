// Package pairing builds and parses the QR payloads that bootstrap device
// pairing. A payload carries an ephemeral X25519 public key and a rendezvous
// token; seeing the QR is the only authentication the pairing has, and the
// token confirmation after the Noise handshake binds the encrypted channel
// to that sighting.
package pairing

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"net/url"
	"strconv"
	"strings"

	"golang.org/x/crypto/curve25519"
)

// Scheme is the URI scheme of pairing payloads.
const Scheme = "sora-sync"

// TokenLen is the rendezvous token size in bytes.
const TokenLen = 16

// Invitation is a decoded pairing payload.
type Invitation struct {
	// Version is the payload format version.
	Version int
	// DeviceID identifies the inviting device for mDNS correlation.
	DeviceID string
	// PublicKey is the inviter's ephemeral X25519 public key.
	PublicKey [32]byte
	// Token is the rendezvous token both sides prove knowledge of after
	// the Noise handshake.
	Token [TokenLen]byte
	// Port is the inviter's pairing listener TCP port; the joiner discovers
	// the IP via mDNS and dials ip:port.
	Port int
}

// Generate creates an invitation for deviceID and returns the matching
// ephemeral private key.
func Generate(deviceID string) (*Invitation, [32]byte, error) {
	if strings.TrimSpace(deviceID) == "" {
		return nil, [32]byte{}, errors.New("pairing: empty device id")
	}
	var priv [32]byte
	if _, err := rand.Read(priv[:]); err != nil {
		return nil, [32]byte{}, fmt.Errorf("pairing: %w", err)
	}
	pub, err := curve25519.X25519(priv[:], curve25519.Basepoint)
	if err != nil {
		return nil, [32]byte{}, fmt.Errorf("pairing: %w", err)
	}
	var pubArr [32]byte
	copy(pubArr[:], pub)
	var token [TokenLen]byte
	if _, err := rand.Read(token[:]); err != nil {
		return nil, [32]byte{}, fmt.Errorf("pairing: %w", err)
	}
	return &Invitation{Version: 1, DeviceID: deviceID, PublicKey: pubArr, Token: token}, priv, nil
}

var b64 = base64.RawURLEncoding

// Encode renders the invitation as a QR payload URI.
func (in *Invitation) Encode() string {
	q := url.Values{}
	q.Set("v", "1")
	q.Set("id", in.DeviceID)
	q.Set("pub", b64.EncodeToString(in.PublicKey[:]))
	q.Set("token", b64.EncodeToString(in.Token[:]))
	q.Set("port", strconv.Itoa(in.Port))
	return Scheme + "://pair?" + q.Encode()
}

// Decode parses a QR payload URI. It rejects wrong schemes, versions, and
// malformed fields so a mistyped payload fails fast with a clear error.
func Decode(s string) (*Invitation, error) {
	u, err := url.Parse(strings.TrimSpace(s))
	if err != nil {
		return nil, fmt.Errorf("pairing: not a URI: %w", err)
	}
	if u.Scheme != Scheme || u.Host != "pair" {
		return nil, fmt.Errorf("pairing: not a sora-sync pairing payload")
	}
	q := u.Query()
	if q.Get("v") != "1" {
		return nil, fmt.Errorf("pairing: unsupported version %q", q.Get("v"))
	}
	id := q.Get("id")
	if id == "" || len(id) > 128 {
		return nil, errors.New("pairing: the payload has no device id")
	}
	pub, err := b64.DecodeString(q.Get("pub"))
	if err != nil || len(pub) != 32 {
		return nil, errors.New("pairing: the payload has a bad public key")
	}
	tok, err := b64.DecodeString(q.Get("token"))
	if err != nil || len(tok) != TokenLen {
		return nil, errors.New("pairing: the payload has a bad token")
	}
	port, err := strconv.Atoi(q.Get("port"))
	if err != nil || port <= 0 || port > 65535 {
		return nil, errors.New("pairing: the payload has a bad port")
	}
	in := &Invitation{Version: 1, DeviceID: id, Port: port}
	copy(in.PublicKey[:], pub)
	copy(in.Token[:], tok)
	return in, nil
}
