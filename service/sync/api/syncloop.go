package api

import (
	"context"
	"encoding/base64"
	"fmt"
	"log"
	"net"
	"time"

	"github.com/levvs-one/sora-client/sync/discovery"
	syncpkg "github.com/levvs-one/sora-client/sync/sync"
	"github.com/levvs-one/sora-client/sync/transport"
)

// maxSyncConns bounds concurrent sync handshakes on the persistent listener.
const maxSyncConns = 8

// StartSyncListener opens the persistent listener that paired devices sync
// through, and advertises it on the LAN. It is best-effort: without LAN
// multicast the daemon still serves its API.
func (d *Daemon) StartSyncListener() error {
	listener, err := net.Listen("tcp", ":0")
	if err != nil {
		return fmt.Errorf("api: %w", err)
	}
	d.syncListener = listener
	port := listener.Addr().(*net.TCPAddr).Port
	advertiser, err := discovery.Advertise(d.identity.ID, port)
	if err != nil {
		_ = listener.Close()
		return err
	}
	self, err := d.transportSelf()
	if err != nil {
		_ = advertiser.Close()
		_ = listener.Close()
		return err
	}
	d.wg.Add(1)
	go func() {
		defer d.wg.Done()
		defer func() { _ = advertiser.Close() }()
		defer func() { _ = listener.Close() }()
		// Bound concurrent handshakes: each burns X25519 operations, and
		// this listener is advertised on the LAN permanently.
		sem := make(chan struct{}, maxSyncConns)
		for {
			conn, err := listener.Accept()
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
				d.handleSyncConn(conn, self)
			}()
		}
	}()
	return nil
}

// handleSyncConn serves one incoming sync from a paired device.
func (d *Daemon) handleSyncConn(netConn net.Conn, self transport.Identity) {
	verify := func(peerKey [32]byte) bool {
		_, ok := d.peerKeys()[peerKey]
		return ok
	}
	ctx, cancel := context.WithTimeout(d.ctx, 3*time.Minute)
	defer cancel()
	c, err := transport.AcceptKnown(ctx, netConn, d.identity.priv, self, verify)
	if err != nil {
		return
	}
	defer func() { _ = c.Close() }()
	if _, err := syncpkg.Sync(ctx, c, d.identity.ID, d.store, false); err != nil {
		return
	}
	if err := d.upsertPeer(c.Peer.DeviceID, c.Peer.DeviceName,
		base64.RawURLEncoding.EncodeToString(c.Peer.PublicKey[:])); err != nil {
		log.Printf("sync: save peers registry: %v", err)
	}
}

// SyncPeer finds a paired device on the LAN and syncs with it.
func (d *Daemon) SyncPeer(ctx context.Context, id string) (pulled, pushed []syncpkg.Meta, err error) {
	d.mu.Lock()
	peer, ok := d.peers[id]
	d.mu.Unlock()
	if !ok {
		return nil, nil, fmt.Errorf("api: unknown peer %q", id)
	}
	peerKey, err := peer.keyBytes()
	if err != nil {
		return nil, nil, err
	}
	found, err := resolveDevice(ctx, peer.ID, 20*time.Second)
	if err != nil {
		return nil, nil, err
	}
	if !lanAddr(found.Addr) {
		return nil, nil, fmt.Errorf("api: the discovered peer %q resolved outside the LAN", peer.ID)
	}
	addr := net.JoinHostPort(found.Addr, fmt.Sprint(found.Port))
	dialCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	netConn, err := (&net.Dialer{}).DialContext(dialCtx, "tcp", addr)
	if err != nil {
		return nil, nil, fmt.Errorf("api: cannot reach the peer: %w", err)
	}
	self, err := d.transportSelf()
	if err != nil {
		_ = netConn.Close()
		return nil, nil, err
	}
	c, err := transport.DialKnown(dialCtx, netConn, peerKey, d.identity.priv, self)
	if err != nil {
		return nil, nil, fmt.Errorf("api: sync failed: %w", err)
	}
	defer func() { _ = c.Close() }()
	rep, err := syncpkg.Sync(dialCtx, c, d.identity.ID, d.store, true)
	if err != nil {
		return nil, nil, fmt.Errorf("api: sync failed: %w", err)
	}
	if err := d.upsertPeer(c.Peer.DeviceID, c.Peer.DeviceName,
		base64.RawURLEncoding.EncodeToString(c.Peer.PublicKey[:])); err != nil {
		return nil, nil, fmt.Errorf("api: sync succeeded but the peer registry was not saved: %w", err)
	}
	return rep.Pulled, rep.Pushed, nil
}

// Shutdown stops listeners and waits for in-flight work.
func (d *Daemon) Shutdown() {
	d.cancel()
	_ = d.StopPairing()
	if d.syncListener != nil {
		_ = d.syncListener.Close()
	}
	if d.httpListener != nil {
		_ = d.httpListener.Close()
	}
	d.wg.Wait()
}
