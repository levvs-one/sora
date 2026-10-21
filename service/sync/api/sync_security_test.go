package api

import (
	"context"
	"encoding/json"
	"net"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/sync/discovery"
	"github.com/levvs-one/sora-client/sync/pairing"
	"github.com/levvs-one/sora-client/sync/transport"
)

func syncDevices(t *testing.T) (*Daemon, *Daemon) {
	t.Helper()
	a, err := New(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	b, err := New(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(a.Shutdown)
	t.Cleanup(b.Shutdown)
	if err := a.upsertPeer(b.identity.ID, b.identity.Name, b.identity.PublicKey); err != nil {
		t.Fatal(err)
	}
	return a, b
}

func startIncoming(t *testing.T, a, b *Daemon, self transport.Identity, wrap ...func(net.Conn) net.Conn) (*transport.Conn, <-chan struct{}) {
	t.Helper()
	server, client := net.Pipe()
	t.Cleanup(func() { _ = server.Close(); _ = client.Close() })
	done := make(chan struct{})
	local, err := a.transportSelf()
	if err != nil {
		t.Fatal(err)
	}
	incoming := server
	if len(wrap) != 0 {
		incoming = wrap[0](incoming)
	}
	go func() { defer close(done); a.handleSyncConn(incoming, local) }()
	key, err := (&Peer{IdentityKey: a.identity.PublicKey}).keyBytes()
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	c, err := transport.DialKnown(ctx, client, key, b.identity.priv, self)
	if err != nil {
		t.Fatal(err)
	}
	return c, done
}

func wire(t *testing.T, c *transport.Conn, value any) {
	t.Helper()
	raw, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	if err := c.WriteMsg(raw); err != nil {
		t.Fatal(err)
	}
}

func emptySync(t *testing.T, c *transport.Conn) {
	t.Helper()
	for _, kind := range []string{"hello", "inv", "bye"} {
		wire(t, c, map[string]any{"t": kind, "device": "claimed"})
		if _, err := c.ReadMsg(); err != nil {
			t.Fatal(err)
		}
	}
}

func awaitHandler(t *testing.T, done <-chan struct{}) {
	t.Helper()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("connection handler did not stop")
	}
}

func TestKnownSyncCannotRegisterClaimedDeviceID(t *testing.T) {
	a, b := syncDevices(t)
	self, err := b.transportSelf()
	if err != nil {
		t.Fatal(err)
	}
	self.DeviceID = "unpaired-identity"
	c, done := startIncoming(t, a, b, self)
	defer func() { _ = c.Close() }()
	emptySync(t, c)
	awaitHandler(t, done)
	peers := a.Peers()
	if len(peers) != 1 || peers[0].ID != b.identity.ID {
		t.Fatalf("ordinary sync registered claimed identity: %+v", peers)
	}
}

func TestRevokeCancelsIncomingSync(t *testing.T) {
	a, b := syncDevices(t)
	self, err := b.transportSelf()
	if err != nil {
		t.Fatal(err)
	}
	c, done := startIncoming(t, a, b, self)
	defer func() { _ = c.Close() }()
	wire(t, c, map[string]any{"t": "hello", "device": b.identity.ID})
	if _, err := c.ReadMsg(); err != nil {
		t.Fatal(err)
	}
	if _, err := a.RevokePeer(b.identity.ID); err != nil {
		t.Fatal(err)
	}
	awaitHandler(t, done)
	if len(a.Peers()) != 0 {
		t.Fatal("revoked peer returned")
	}
}

func TestOutgoingSyncUsesRegistryAndHonorsRevocation(t *testing.T) {
	for _, mode := range []string{"claimed-id", "revoke"} {
		t.Run(mode, func(t *testing.T) {
			a, b := syncDevices(t)
			listener, err := net.Listen("tcp", "127.0.0.1:0")
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = listener.Close() }()
			old := resolveDevice
			t.Cleanup(func() { resolveDevice = old })
			resolveDevice = func(context.Context, string, time.Duration) (discovery.Peer, error) {
				return discovery.Peer{Addr: "127.0.0.1", Port: listener.Addr().(*net.TCPAddr).Port}, nil
			}
			result := make(chan error, 1)
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			go func() { _, _, err := a.SyncPeer(ctx, b.identity.ID); result <- err }()
			raw, err := listener.Accept()
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = raw.Close() }()
			self, err := b.transportSelf()
			if err != nil {
				t.Fatal(err)
			}
			self.DeviceID = "unpaired-identity"
			c, err := transport.AcceptKnown(ctx, raw, b.identity.priv, self, func([32]byte) bool { return true })
			if err != nil {
				t.Fatal(err)
			}
			if _, err := c.ReadMsg(); err != nil {
				t.Fatal(err)
			}
			if mode == "revoke" {
				if _, err := a.RevokePeer(b.identity.ID); err != nil {
					t.Fatal(err)
				}
			} else {
				wire(t, c, map[string]any{"t": "hello", "device": self.DeviceID})
				if _, err := c.ReadMsg(); err != nil {
					t.Fatal(err)
				}
				wire(t, c, map[string]any{"t": "inv"})
				if _, err := c.ReadMsg(); err != nil {
					t.Fatal(err)
				}
				wire(t, c, map[string]any{"t": "bye"})
			}
			select {
			case err := <-result:
				if mode == "revoke" && err == nil {
					t.Fatal("revoked outgoing sync succeeded")
				}
				if mode == "claimed-id" {
					if err != nil {
						t.Fatal(err)
					}
					peers := a.Peers()
					if len(peers) != 1 || peers[0].ID != b.identity.ID {
						t.Fatalf("outgoing sync trusted claimed id: %+v", peers)
					}
				}
			case <-time.After(time.Second):
				t.Fatal("outgoing sync did not finish")
			}
		})
	}
}

func TestStoppedPairingCancelsAcceptedConnection(t *testing.T) {
	for _, stage := range []string{"handshake", "exchange", "expiry"} {
		t.Run(stage, func(t *testing.T) {
			a, err := New(t.TempDir())
			if err != nil {
				t.Fatal(err)
			}
			t.Cleanup(a.Shutdown)
			b, err := New(t.TempDir())
			if err != nil {
				t.Fatal(err)
			}
			t.Cleanup(b.Shutdown)
			qr, _, err := a.StartPairing()
			if err != nil {
				t.Fatal(err)
			}
			inv, err := pairing.Decode(qr)
			if err != nil {
				t.Fatal(err)
			}
			a.mu.Lock()
			s := a.pairing
			a.mu.Unlock()
			server, client := net.Pipe()
			defer func() { _ = server.Close(); _ = client.Close() }()
			self, err := a.transportSelf()
			if err != nil {
				t.Fatal(err)
			}
			done := make(chan struct{})
			go func() { defer close(done); a.handlePairingConn(s, server, self) }()
			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			defer cancel()
			if stage != "handshake" {
				remote, err := b.transportSelf()
				if err != nil {
					t.Fatal(err)
				}
				c, err := transport.Dial(ctx, client, inv, remote)
				if err != nil {
					t.Fatal(err)
				}
				wire(t, c, map[string]any{"t": "hello", "device": b.identity.ID})
				if _, err := c.ReadMsg(); err != nil {
					t.Fatal(err)
				}
			} else {
				if _, err := client.Write([]byte{0}); err != nil {
					t.Fatal(err)
				}
			}
			if stage == "expiry" {
				err = a.stopPairingSession(s)
			} else {
				err = a.StopPairing()
			}
			if err != nil {
				t.Fatal(err)
			}
			awaitHandler(t, done)
			if len(a.Peers()) != 0 {
				t.Fatalf("closed invitation paired a device: %v", a.Peers())
			}
		})
	}
}

// Observing the synchronous pipe pins races at the last protocol write,
// before the handler can refresh the registry.
type observedWrites struct {
	net.Conn
	count  int
	before func(int)
	after  func(int)
}

func (c *observedWrites) Write(p []byte) (int, error) {
	c.count++
	if c.before != nil {
		c.before(c.count)
	}
	n, err := c.Conn.Write(p)
	if c.after != nil {
		c.after(c.count)
	}
	return n, err
}

func TestFinishingSyncCannotRestoreOrOverwritePeer(t *testing.T) {
	for _, mode := range []string{"revoke", "repair-same-key", "repair-new-key"} {
		t.Run(mode, func(t *testing.T) {
			a, b := syncDevices(t)
			self, err := b.transportSelf()
			if err != nil {
				t.Fatal(err)
			}
			var changeErr error
			newKey := b.identity.PublicKey
			if mode == "repair-new-key" {
				newKey = a.identity.PublicKey
			}
			c, done := startIncoming(t, a, b, self, func(raw net.Conn) net.Conn {
				return &observedWrites{Conn: raw, after: func(n int) {
					if n != 6 {
						return
					}
					if mode == "revoke" {
						_, changeErr = a.RevokePeer(b.identity.ID)
					} else {
						changeErr = a.upsertPeer(b.identity.ID, "new pairing", newKey)
					}
				}}
			})
			defer func() { _ = c.Close() }()
			emptySync(t, c)
			awaitHandler(t, done)
			if changeErr != nil {
				t.Fatal(changeErr)
			}
			peers := a.Peers()
			if mode == "revoke" {
				if len(peers) != 0 {
					t.Fatalf("finishing sync resurrected peer: %+v", peers)
				}
			} else {
				if len(peers) != 1 || peers[0].Name != "new pairing" || peers[0].IdentityKey != newKey {
					t.Fatalf("old sync overwrote new pairing: %+v", peers)
				}
			}
		})
	}
}

func TestPairingRechecksInvitationAtCommit(t *testing.T) {
	for _, mode := range []string{"stop", "expired"} {
		t.Run(mode, func(t *testing.T) {
			a, b := syncDevices(t)
			if _, err := a.RevokePeer(b.identity.ID); err != nil {
				t.Fatal(err)
			}
			qr, _, err := a.StartPairing()
			if err != nil {
				t.Fatal(err)
			}
			inv, err := pairing.Decode(qr)
			if err != nil {
				t.Fatal(err)
			}
			a.mu.Lock()
			s := a.pairing
			a.mu.Unlock()
			server, client := net.Pipe()
			defer func() { _ = server.Close(); _ = client.Close() }()
			var stopErr error
			observed := &observedWrites{Conn: server, after: func(n int) {
				if n != 7 {
					return
				}
				if mode == "stop" {
					stopErr = a.StopPairing()
				} else {
					a.mu.Lock()
					s.expiresAt = time.Now().Add(-time.Second)
					a.mu.Unlock()
				}
			}}
			local, err := a.transportSelf()
			if err != nil {
				t.Fatal(err)
			}
			done := make(chan struct{})
			go func() { defer close(done); a.handlePairingConn(s, observed, local) }()
			self, err := b.transportSelf()
			if err != nil {
				t.Fatal(err)
			}
			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			defer cancel()
			c, err := transport.Dial(ctx, client, inv, self)
			if err != nil {
				t.Fatal(err)
			}
			emptySync(t, c)
			awaitHandler(t, done)
			if stopErr != nil {
				t.Fatal(stopErr)
			}
			if len(a.Peers()) != 0 {
				t.Fatalf("closed invitation committed a peer: %+v", a.Peers())
			}
		})
	}
}

func TestShutdownUnblocksSyncWrite(t *testing.T) {
	a, b := syncDevices(t)
	self, err := b.transportSelf()
	if err != nil {
		t.Fatal(err)
	}
	writing := make(chan struct{})
	c, done := startIncoming(t, a, b, self, func(raw net.Conn) net.Conn {
		return &observedWrites{Conn: raw, before: func(n int) {
			if n == 4 {
				close(writing)
			}
		}}
	})
	defer func() { _ = c.Close() }()
	wire(t, c, map[string]any{"t": "hello", "device": b.identity.ID})
	<-writing
	a.wg.Add(1)
	go func() { defer a.wg.Done(); <-done }()
	stopped := make(chan struct{})
	go func() { a.Shutdown(); close(stopped) }()
	select {
	case <-stopped:
	case <-time.After(time.Second):
		_ = c.Close()
		<-stopped
		t.Fatal("Shutdown hung on a sync write")
	}
}
