package api

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"log"
	"net"
	"net/netip"
	"time"

	"github.com/levvs-one/sora-client/sync/discovery"
	"github.com/levvs-one/sora-client/sync/pairing"
	syncpkg "github.com/levvs-one/sora-client/sync/sync"
	"github.com/levvs-one/sora-client/sync/transport"
)

// pairingTTL bounds how long a pairing invitation stays open.
const pairingTTL = 5 * time.Minute

// maxPairingConns bounds concurrent pairing handshakes: each burns X25519
// operations, and the port is advertised on the LAN for the whole window.
const maxPairingConns = 4

type pairingSession struct {
	inv        *pairing.Invitation
	epriv      [32]byte
	listener   net.Listener
	advertiser *discovery.Advertiser
	expiresAt  time.Time
	done       chan struct{}
}

// transportSelf builds the transport identity of this device.
func (d *Daemon) transportSelf() (transport.Identity, error) {
	pubRaw, err := base64.RawURLEncoding.DecodeString(d.identity.PublicKey)
	if err != nil || len(pubRaw) != 32 {
		return transport.Identity{}, errors.New("api: bad identity public key")
	}
	var pub [32]byte
	copy(pub[:], pubRaw)
	return transport.Identity{
		DeviceID: d.identity.ID, DeviceName: d.identity.Name, PublicKey: pub,
	}, nil
}

// resolveDevice maps a device id to a dialable LAN address. It defaults to
// mDNS discovery; tests override it because LAN multicast is unavailable in
// sandboxes. The production path is always mDNS: the port for pairing comes
// from the QR, the port for sync comes from the mDNS record.
var resolveDevice = discovery.FindDevice

// lanAddr reports whether addr is a LAN-scoped dial target. mDNS answers
// arrive from the local network but are trivially spoofable there; a spoofed
// answer must not make the daemon dial out to the internet - the Noise_XX
// handshake would then disclose this device's long-term identity key to a
// remote party, which is inherent to the XX pattern and cannot be fixed in
// the transport.
func lanAddr(addr string) bool {
	ip, err := netip.ParseAddr(addr)
	if err != nil {
		return false
	}
	ip = ip.Unmap()
	return ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast()
}

// StartPairing opens a pairing session: a LAN listener plus mDNS
// advertisement. The returned QR payload goes to the joining device.
func (d *Daemon) StartPairing() (qr string, expiresAt int64, err error) {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.pairing != nil {
		return "", 0, errors.New("api: a pairing session is already open")
	}
	inv, epriv, err := pairing.Generate(d.identity.ID)
	if err != nil {
		return "", 0, err
	}
	listener, err := net.Listen("tcp", ":0")
	if err != nil {
		return "", 0, fmt.Errorf("api: %w", err)
	}
	inv.Port = listener.Addr().(*net.TCPAddr).Port
	advertiser, err := discovery.Advertise(d.identity.ID, inv.Port)
	if err != nil {
		_ = listener.Close()
		return "", 0, err
	}
	self, err := d.transportSelf()
	if err != nil {
		_ = advertiser.Close()
		_ = listener.Close()
		return "", 0, err
	}
	s := &pairingSession{
		inv: inv, epriv: epriv,
		listener: listener, advertiser: advertiser,
		expiresAt: time.Now().Add(pairingTTL),
		done:      make(chan struct{}),
	}
	d.pairing = s
	d.wg.Add(1)
	go d.pairingLoop(s, self)
	// Auto-close when the TTL elapses. The watcher stops only its own
	// session: a stale timer must never kill the session that replaced it.
	d.wg.Add(1)
	go func() {
		defer d.wg.Done()
		select {
		case <-time.After(pairingTTL):
			_ = d.stopPairingSession(s)
		case <-s.done:
		case <-d.ctx.Done():
		}
	}()
	return inv.Encode(), s.expiresAt.Unix(), nil
}

// pairingLoop accepts joiners for one pairing session.
func (d *Daemon) pairingLoop(s *pairingSession, self transport.Identity) {
	defer d.wg.Done()
	defer close(s.done)
	sem := make(chan struct{}, maxPairingConns)
	for {
		conn, err := s.listener.Accept()
		if err != nil {
			return
		}
		select {
		case sem <- struct{}{}:
		default:
			_ = conn.Close()
			continue
		}
		d.wg.Add(1)
		go func() {
			defer d.wg.Done()
			defer func() { <-sem }()
			d.handlePairingConn(s, conn, self)
		}()
	}
}

func (d *Daemon) handlePairingConn(s *pairingSession, netConn net.Conn, self transport.Identity) {
	ctx, cancel := context.WithTimeout(d.ctx, 2*time.Minute)
	defer cancel()
	c, err := transport.Accept(ctx, netConn, s.epriv, s.inv.Token, self)
	if err != nil {
		return
	}
	defer func() { _ = c.Close() }()
	// Run the first sync immediately so the devices converge now. The peer
	// is recorded only after the sync succeeds, like the joiner side does:
	// a device the daemon could not sync with is not a peer, and an
	// ignored upsert error would report a pairing the daemon cannot prove
	// it persisted.
	if _, err := syncpkg.Sync(ctx, c, d.identity.ID, d.store, false); err != nil {
		return
	}
	if err := d.upsertPeer(c.Peer.DeviceID, c.Peer.DeviceName,
		base64.RawURLEncoding.EncodeToString(c.Peer.PublicKey[:])); err != nil {
		log.Printf("sync: save peers registry: %v", err)
	}
}

// stopPairingSession closes s, but only if s is still the active session.
// A stale TTL watcher must never kill the session that replaced s.
func (d *Daemon) stopPairingSession(s *pairingSession) error {
	d.mu.Lock()
	if d.pairing != s {
		d.mu.Unlock()
		return nil
	}
	d.pairing = nil
	d.mu.Unlock()
	_ = s.advertiser.Close()
	return s.listener.Close()
}

// StopPairing closes the active pairing session, if any.
func (d *Daemon) StopPairing() error {
	d.mu.Lock()
	s := d.pairing
	d.mu.Unlock()
	if s == nil {
		return nil
	}
	return d.stopPairingSession(s)
}

// PairingActive reports whether a pairing session is open.
func (d *Daemon) PairingActive() (bool, int64) {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.pairing == nil {
		return false, 0
	}
	return true, d.pairing.expiresAt.Unix()
}

// Join scans a pairing QR payload, finds the inviting device on the LAN,
// pairs, and runs the first sync.
func (d *Daemon) Join(ctx context.Context, qrPayload string) (Peer, error) {
	inv, err := pairing.Decode(qrPayload)
	if err != nil {
		return Peer{}, err
	}
	// The port comes from the QR; only the IP is discovered.
	found, err := resolveDevice(ctx, inv.DeviceID, 20*time.Second)
	if err != nil {
		return Peer{}, err
	}
	if !lanAddr(found.Addr) {
		return Peer{}, fmt.Errorf("api: the discovered device %q resolved outside the LAN", inv.DeviceID)
	}
	addr := net.JoinHostPort(found.Addr, fmt.Sprint(inv.Port))
	dialCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	netConn, err := (&net.Dialer{}).DialContext(dialCtx, "tcp", addr)
	if err != nil {
		return Peer{}, fmt.Errorf("api: cannot reach the inviting device: %w", err)
	}
	self, err := d.transportSelf()
	if err != nil {
		_ = netConn.Close()
		return Peer{}, err
	}
	c, err := transport.Dial(dialCtx, netConn, inv, self)
	if err != nil {
		return Peer{}, fmt.Errorf("api: pairing failed: %w", err)
	}
	defer func() { _ = c.Close() }()
	if _, err := syncpkg.Sync(dialCtx, c, d.identity.ID, d.store, true); err != nil {
		return Peer{}, fmt.Errorf("api: the first sync failed: %w", err)
	}
	peerKey := base64.RawURLEncoding.EncodeToString(c.Peer.PublicKey[:])
	if err := d.upsertPeer(c.Peer.DeviceID, c.Peer.DeviceName, peerKey); err != nil {
		return Peer{}, fmt.Errorf("api: pairing succeeded but the peer registry was not saved: %w", err)
	}
	d.mu.Lock()
	p := *d.peers[c.Peer.DeviceID]
	d.mu.Unlock()
	return p, nil
}
