// Package transport runs the Noise_XX handshake over TCP and carries framed
// messages on the encrypted channel. After the handshake both sides prove
// knowledge of the rendezvous token from the QR invitation, binding the
// encrypted channel to that sighting and defeating a LAN man-in-the-middle
// that never saw the QR.
package transport

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"strings"
	"sync"
	"time"

	"golang.org/x/crypto/curve25519"

	"github.com/flynn/noise"

	"github.com/levvs-one/sora-client/sync/pairing"
)

// Identity is a device's long-term identity, exchanged over the encrypted
// channel after pairing.
type Identity struct {
	DeviceID   string   `json:"device_id"`
	DeviceName string   `json:"device_name"`
	PublicKey  [32]byte `json:"public_key"`
}

// handshakeTimeout bounds the whole pairing handshake.
const handshakeTimeout = 30 * time.Second

// chunkSize caps one transport message plaintext; larger application
// messages are split across chunks.
const chunkSize = 32 * 1024

// maxMessage caps a reassembled application message.
const maxMessage = 64 << 20

var suite = noise.NewCipherSuite(noise.DH25519, noise.CipherChaChaPoly, noise.HashSHA256)

// Conn is an encrypted channel to a peer. WriteMsg and ReadMsg are safe for
// concurrent use; the two directions use separate cipher states.
type Conn struct {
	net.Conn
	encrypt *noise.CipherState
	decrypt *noise.CipherState
	wmu     sync.Mutex
	rmu     sync.Mutex
	// Peer is the identity the peer presented after the handshake.
	Peer Identity
}

func newState(initiator bool, priv [32]byte) (*noise.HandshakeState, error) {
	pub, err := curve25519.X25519(priv[:], curve25519.Basepoint)
	if err != nil {
		return nil, fmt.Errorf("transport: %w", err)
	}
	return noise.NewHandshakeState(noise.Config{
		CipherSuite:   suite,
		Random:        rand.Reader,
		Pattern:       noise.HandshakeXX,
		Initiator:     initiator,
		StaticKeypair: noise.DHKey{Private: priv[:], Public: pub},
	})
}

// writeFrame sends one Noise handshake message with a 2-byte length prefix.
func writeFrame(conn net.Conn, msg []byte) error {
	if len(msg) > 0xffff {
		return errors.New("transport: handshake message too large")
	}
	var hdr [2]byte
	binary.BigEndian.PutUint16(hdr[:], uint16(len(msg)))
	if _, err := conn.Write(hdr[:]); err != nil {
		return err
	}
	_, err := conn.Write(msg)
	return err
}

// readFrame reads one length-prefixed Noise handshake message.
func readFrame(conn net.Conn) ([]byte, error) {
	var hdr [2]byte
	if _, err := io.ReadFull(conn, hdr[:]); err != nil {
		return nil, err
	}
	msg := make([]byte, binary.BigEndian.Uint16(hdr[:]))
	_, err := io.ReadFull(conn, msg)
	return msg, err
}

// handshakeResult carries the transport keys and the channel binding.
type handshakeResult struct {
	encrypt *noise.CipherState
	decrypt *noise.CipherState
	binding []byte
	peerKey []byte
}

// runHandshake performs the XX exchange and returns the transport cipher
// states. Per the Noise Split convention the initiator encrypts with the
// first state and the responder with the second.
func runHandshake(conn net.Conn, hs *noise.HandshakeState, initiator bool) (*handshakeResult, error) {
	writeMsg := func() (*noise.CipherState, *noise.CipherState, error) {
		msg, cs1, cs2, err := hs.WriteMessage(nil, nil)
		if err != nil {
			return nil, nil, err
		}
		if err := writeFrame(conn, msg); err != nil {
			return nil, nil, err
		}
		return cs1, cs2, nil
	}
	readMsg := func() (*noise.CipherState, *noise.CipherState, error) {
		msg, err := readFrame(conn)
		if err != nil {
			return nil, nil, err
		}
		_, cs1, cs2, err := hs.ReadMessage(nil, msg)
		return cs1, cs2, err
	}
	res := &handshakeResult{}
	var cs1, cs2 *noise.CipherState
	var err error
	if initiator {
		if _, _, err = writeMsg(); err != nil {
			return nil, err
		}
		if _, _, err = readMsg(); err != nil {
			return nil, err
		}
		// The peer's static key arrives encrypted in message 2; check it
		// before sending message 3.
		res.peerKey = hs.PeerStatic()
		if cs1, cs2, err = writeMsg(); err != nil {
			return nil, err
		}
		res.encrypt, res.decrypt = cs1, cs2
	} else {
		if _, _, err = readMsg(); err != nil {
			return nil, err
		}
		if _, _, err = writeMsg(); err != nil {
			return nil, err
		}
		if cs1, cs2, err = readMsg(); err != nil {
			return nil, err
		}
		// The initiator's static key arrives encrypted in message 3.
		res.peerKey = hs.PeerStatic()
		res.encrypt, res.decrypt = cs2, cs1
	}
	if res.encrypt == nil || res.decrypt == nil {
		return nil, errors.New("transport: the handshake did not complete")
	}
	// The channel binding is the final handshake hash.
	res.binding = hs.ChannelBinding()
	return res, nil
}

// confirmToken proves knowledge of the rendezvous token on both sides. Each
// side sends HMAC(token, channelBinding) and verifies the peer's; a mismatch
// means the peer never saw the QR.
func confirmToken(c *Conn, binding, token []byte, sendFirst bool) error {
	mac := hmac.New(sha256.New, token)
	mac.Write(binding)
	want := mac.Sum(nil)
	send := func() error { return c.WriteMsg(want) }
	recv := func() error {
		got, err := c.ReadMsg()
		if err != nil {
			return err
		}
		if !hmac.Equal(got, want) {
			return errors.New("transport: the peer did not prove the rendezvous token")
		}
		return nil
	}
	if sendFirst {
		if err := send(); err != nil {
			return err
		}
		return recv()
	}
	if err := recv(); err != nil {
		return err
	}
	return send()
}

// exchangeIdentities swaps long-term device identities over the channel.
func exchangeIdentities(c *Conn, self Identity, sendFirst bool) (Identity, error) {
	selfRaw, err := json.Marshal(self)
	if err != nil {
		return Identity{}, err
	}
	var peerRaw []byte
	if sendFirst {
		if err := c.WriteMsg(selfRaw); err != nil {
			return Identity{}, err
		}
		peerRaw, err = c.ReadMsg()
	} else {
		peerRaw, err = c.ReadMsg()
		if err == nil {
			err = c.WriteMsg(selfRaw)
		}
	}
	if err != nil {
		return Identity{}, err
	}
	var peer Identity
	if err := json.Unmarshal(peerRaw, &peer); err != nil {
		return Identity{}, fmt.Errorf("transport: bad identity: %w", err)
	}
	if strings.TrimSpace(peer.DeviceID) == "" {
		return Identity{}, errors.New("transport: the peer sent no device id")
	}
	return peer, nil
}

// Dial pairs as the joiner: it runs the XX handshake with a fresh ephemeral
// key over netConn, checks the peer is the inviting device, confirms the
// invitation token, and exchanges identities.
func Dial(ctx context.Context, netConn net.Conn, inv *pairing.Invitation, self Identity) (*Conn, error) {
	if inv == nil {
		_ = netConn.Close()
		return nil, errors.New("transport: nil invitation")
	}
	var epriv [32]byte
	if _, err := rand.Read(epriv[:]); err != nil {
		return nil, fmt.Errorf("transport: %w", err)
	}
	check := func(res *handshakeResult) error {
		// The responder's static key must be the invitation's: otherwise
		// this is not the device that showed the QR.
		if !hmac.Equal(res.peerKey, inv.PublicKey[:]) {
			return errors.New("transport: the peer is not the inviting device")
		}
		return nil
	}
	c, err := dial(ctx, netConn, epriv, self, check, &inv.Token, true)
	if err != nil {
		return nil, err
	}
	// The identity the peer presents must name the device the QR named.
	// The key check above authenticates the channel; this keeps the peers
	// registry from recording a device under the wrong id.
	if c.Peer.DeviceID != inv.DeviceID {
		_ = c.Close()
		return nil, errors.New("transport: the peer's device id does not match the invitation")
	}
	return c, nil
}

// Accept pairs as the inviter: it runs the XX handshake with the invitation
// key, confirms the token, and exchanges identities.
func Accept(ctx context.Context, netConn net.Conn, epriv [32]byte, token [pairing.TokenLen]byte, self Identity) (*Conn, error) {
	return accept(ctx, netConn, epriv, self, nil, &token, false)
}

// DialKnown syncs with a paired peer: the XX handshake uses the long-term
// identity keys and the peer's identity key must match.
func DialKnown(ctx context.Context, netConn net.Conn, peerKey [32]byte, selfPriv [32]byte, self Identity) (*Conn, error) {
	check := func(res *handshakeResult) error {
		if !hmac.Equal(res.peerKey, peerKey[:]) {
			return errors.New("transport: the peer's identity key does not match the paired device")
		}
		return nil
	}
	return dial(ctx, netConn, selfPriv, self, check, nil, true)
}

// AcceptKnown accepts a sync from a paired peer. verify maps the peer's
// identity key to a known device; unknown devices are rejected.
func AcceptKnown(ctx context.Context, netConn net.Conn, selfPriv [32]byte, self Identity, verify func(peerKey [32]byte) bool) (*Conn, error) {
	check := func(res *handshakeResult) error {
		var key [32]byte
		copy(key[:], res.peerKey)
		if !verify(key) {
			return errors.New("transport: the peer is not a paired device")
		}
		return nil
	}
	return accept(ctx, netConn, selfPriv, self, check, nil, false)
}

// dial runs the initiator side with the given key, peer check, and optional
// token confirmation (pairing mode).
func dial(ctx context.Context, netConn net.Conn, priv [32]byte, self Identity,
	check func(*handshakeResult) error, token *[pairing.TokenLen]byte, sendFirst bool) (*Conn, error) {
	hs, err := newState(true, priv)
	if err != nil {
		return nil, fmt.Errorf("transport: %w", err)
	}
	res, err := withDeadline(ctx, netConn, func() (*handshakeResult, error) {
		return runHandshake(netConn, hs, true)
	})
	if err != nil {
		netConn.Close()
		return nil, fmt.Errorf("transport: handshake: %w", err)
	}
	if err := check(res); err != nil {
		netConn.Close()
		return nil, err
	}
	c := &Conn{Conn: netConn, encrypt: res.encrypt, decrypt: res.decrypt}
	if token != nil {
		if err := withDeadlineErr(ctx, netConn, func() error {
			return confirmToken(c, res.binding, token[:], sendFirst)
		}); err != nil {
			netConn.Close()
			return nil, err
		}
	}
	peer, err := withDeadline(ctx, netConn, func() (Identity, error) {
		return exchangeIdentities(c, self, sendFirst)
	})
	if err != nil {
		netConn.Close()
		return nil, err
	}
	c.Peer = peer
	return c, nil
}

// accept runs the responder side with the given key, peer check, and
// optional token confirmation (pairing mode).
func accept(ctx context.Context, netConn net.Conn, priv [32]byte, self Identity,
	check func(*handshakeResult) error, token *[pairing.TokenLen]byte, sendFirst bool) (*Conn, error) {
	hs, err := newState(false, priv)
	if err != nil {
		return nil, fmt.Errorf("transport: %w", err)
	}
	res, err := withDeadline(ctx, netConn, func() (*handshakeResult, error) {
		return runHandshake(netConn, hs, false)
	})
	if err != nil {
		netConn.Close()
		return nil, fmt.Errorf("transport: handshake: %w", err)
	}
	if check != nil {
		if err := check(res); err != nil {
			netConn.Close()
			return nil, err
		}
	}
	c := &Conn{Conn: netConn, encrypt: res.encrypt, decrypt: res.decrypt}
	if token != nil {
		if err := withDeadlineErr(ctx, netConn, func() error {
			return confirmToken(c, res.binding, token[:], sendFirst)
		}); err != nil {
			netConn.Close()
			return nil, err
		}
	}
	peer, err := withDeadline(ctx, netConn, func() (Identity, error) {
		return exchangeIdentities(c, self, sendFirst)
	})
	if err != nil {
		netConn.Close()
		return nil, err
	}
	c.Peer = peer
	return c, nil
}

// withDeadline runs fn with a handshake deadline on the connection.
func withDeadline[T any](ctx context.Context, conn net.Conn, fn func() (T, error)) (T, error) {
	deadline, cancel := context.WithTimeout(ctx, handshakeTimeout)
	defer cancel()
	if d, ok := deadline.Deadline(); ok {
		_ = conn.SetDeadline(d)
		defer conn.SetDeadline(time.Time{})
	}
	type result struct {
		v   T
		err error
	}
	done := make(chan result, 1)
	go func() {
		v, err := fn()
		done <- result{v, err}
	}()
	select {
	case r := <-done:
		return r.v, r.err
	case <-deadline.Done():
		var zero T
		return zero, deadline.Err()
	}
}

// withDeadlineErr runs fn with a handshake deadline on the connection.
func withDeadlineErr(ctx context.Context, conn net.Conn, fn func() error) error {
	_, err := withDeadline(ctx, conn, func() (struct{}, error) {
		return struct{}{}, fn()
	})
	return err
}

// WriteMsg sends one application message, chunked across transport messages.
// Each chunk carries a 1-byte last flag.
func (c *Conn) WriteMsg(p []byte) error {
	c.wmu.Lock()
	defer c.wmu.Unlock()
	if len(p) == 0 {
		return c.writeChunk([]byte{1})
	}
	for len(p) > 0 {
		n := len(p)
		if n > chunkSize {
			n = chunkSize
		}
		chunk := make([]byte, 0, n+1)
		if len(p) == n {
			chunk = append(chunk, 1)
		} else {
			chunk = append(chunk, 0)
		}
		chunk = append(chunk, p[:n]...)
		if err := c.writeChunk(chunk); err != nil {
			return err
		}
		p = p[n:]
	}
	return nil
}

func (c *Conn) writeChunk(plain []byte) error {
	ct, err := c.encrypt.Encrypt(nil, nil, plain)
	if err != nil {
		return err
	}
	return writeFrame(c.Conn, ct)
}

// ReadMsg reads one application message, reassembling chunks.
func (c *Conn) ReadMsg() ([]byte, error) {
	c.rmu.Lock()
	defer c.rmu.Unlock()
	var out []byte
	for {
		frame, err := readFrame(c.Conn)
		if err != nil {
			return nil, err
		}
		plain, err := c.decrypt.Decrypt(nil, nil, frame)
		if err != nil {
			return nil, err
		}
		if len(plain) == 0 {
			return nil, errors.New("transport: empty chunk")
		}
		out = append(out, plain[1:]...)
		if plain[0] == 1 {
			return out, nil
		}
		if len(out) > maxMessage {
			return nil, errors.New("transport: message exceeds 64 MiB")
		}
	}
}
