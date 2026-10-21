// Package api runs the sora-sync daemon: the device identity, paired peers,
// document store, pairing sessions, the mDNS-advertised sync listener, and
// the localhost HTTP control API the app talks to.
package api

import (
	"context"
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"golang.org/x/crypto/curve25519"

	syncpkg "github.com/levvs-one/sora-client/sync/sync"
)

// Identity is this device's long-term identity.
type Identity struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	PublicKey string `json:"public_key"` // base64 rawurl of the X25519 key
	priv      [32]byte
}

// Peer is a paired device.
type Peer struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	IdentityKey string `json:"identity_key"` // base64 rawurl of the X25519 key
	PairedAt    int64  `json:"paired_at"`
	LastSync    int64  `json:"last_sync"`
	ctx         context.Context
	cancel      context.CancelFunc
}

func (p *Peer) keyBytes() ([32]byte, error) {
	var k [32]byte
	raw, err := base64.RawURLEncoding.DecodeString(p.IdentityKey)
	if err != nil || len(raw) != 32 {
		return k, errors.New("api: bad peer identity key")
	}
	copy(k[:], raw)
	return k, nil
}

// Daemon is the sora-sync service.
type Daemon struct {
	dir      string
	identity *Identity
	store    *syncpkg.DirStore

	mu    sync.Mutex
	peers map[string]*Peer // by device id

	pairing *pairingSession

	syncListener net.Listener
	httpListener net.Listener
	token        string

	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup
}

// New creates the daemon, loading or creating the device identity and the
// API token. Nothing listens yet; call Run.
func New(dir string) (*Daemon, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errors.New("api: empty data directory")
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, fmt.Errorf("api: %w", err)
	}
	identity, err := loadIdentity(dir)
	if err != nil {
		return nil, err
	}
	store, err := syncpkg.NewDirStore(filepath.Join(dir, "docs"))
	if err != nil {
		return nil, err
	}
	token, err := loadToken(dir)
	if err != nil {
		return nil, err
	}
	peers, err := loadPeers(dir)
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithCancel(context.Background())
	for _, p := range peers {
		p.ctx, p.cancel = context.WithCancel(ctx)
	}
	return &Daemon{
		dir: dir, identity: identity, store: store,
		peers: peers, token: token,
		ctx: ctx, cancel: cancel,
	}, nil
}

// Identity returns this device's public identity. The private key is never
// exposed.
func (d *Daemon) Identity() Identity {
	c := *d.identity
	c.priv = [32]byte{}
	return c
}

// loadIdentity reads identity.json or creates a fresh identity.
func loadIdentity(dir string) (*Identity, error) {
	path := filepath.Join(dir, "identity.json")
	if raw, err := os.ReadFile(path); err == nil {
		var stored struct {
			ID         string `json:"id"`
			Name       string `json:"name"`
			PrivateKey string `json:"private_key"`
		}
		if err := json.Unmarshal(raw, &stored); err != nil {
			return nil, fmt.Errorf("api: bad identity.json: %w", err)
		}
		privRaw, err := base64.RawURLEncoding.DecodeString(stored.PrivateKey)
		if err != nil || len(privRaw) != 32 || stored.ID == "" {
			return nil, errors.New("api: bad identity.json")
		}
		var priv [32]byte
		copy(priv[:], privRaw)
		pub, err := curve25519.X25519(priv[:], curve25519.Basepoint)
		if err != nil {
			return nil, fmt.Errorf("api: %w", err)
		}
		return &Identity{
			ID: stored.ID, Name: stored.Name,
			PublicKey: base64.RawURLEncoding.EncodeToString(pub),
			priv:      priv,
		}, nil
	}
	var priv [32]byte
	if _, err := rand.Read(priv[:]); err != nil {
		return nil, fmt.Errorf("api: %w", err)
	}
	pub, err := curve25519.X25519(priv[:], curve25519.Basepoint)
	if err != nil {
		return nil, fmt.Errorf("api: %w", err)
	}
	var idBytes [12]byte
	if _, err := rand.Read(idBytes[:]); err != nil {
		return nil, fmt.Errorf("api: %w", err)
	}
	host, _ := os.Hostname()
	name := strings.TrimSpace(host)
	if name == "" {
		name = "sora device"
	}
	identity := &Identity{
		ID:        fmt.Sprintf("%x", idBytes),
		Name:      name,
		PublicKey: base64.RawURLEncoding.EncodeToString(pub),
		priv:      priv,
	}
	stored := struct {
		ID         string `json:"id"`
		Name       string `json:"name"`
		PrivateKey string `json:"private_key"`
	}{
		ID: identity.ID, Name: identity.Name,
		PrivateKey: base64.RawURLEncoding.EncodeToString(priv[:]),
	}
	raw, err := json.Marshal(stored)
	if err != nil {
		return nil, fmt.Errorf("api: %w", err)
	}
	if err := writeFileAtomic(path, raw, 0o600); err != nil {
		return nil, err
	}
	return identity, nil
}

// loadToken reads the API bearer token or creates it.
func loadToken(dir string) (string, error) {
	path := filepath.Join(dir, "api_token")
	if raw, err := os.ReadFile(path); err == nil {
		token := strings.TrimSpace(string(raw))
		if len(token) >= 32 {
			return token, nil
		}
	}
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", fmt.Errorf("api: %w", err)
	}
	token := base64.RawURLEncoding.EncodeToString(b[:])
	if err := writeFileAtomic(path, []byte(token+"\n"), 0o600); err != nil {
		return "", err
	}
	return token, nil
}

// checkToken compares the Authorization bearer token in constant time.
func (d *Daemon) checkToken(header string) bool {
	token, found := strings.CutPrefix(header, "Bearer ")
	if !found {
		return false
	}
	return subtle.ConstantTimeCompare([]byte(token), []byte(d.token)) == 1
}

// peersFile is peers.json.
func (d *Daemon) peersPath() string { return filepath.Join(d.dir, "peers.json") }

func loadPeers(dir string) (map[string]*Peer, error) {
	peers := map[string]*Peer{}
	raw, err := os.ReadFile(filepath.Join(dir, "peers.json"))
	if err != nil {
		if os.IsNotExist(err) {
			return peers, nil
		}
		return nil, fmt.Errorf("api: %w", err)
	}
	var list []Peer
	if err := json.Unmarshal(raw, &list); err != nil {
		return nil, fmt.Errorf("api: bad peers.json: %w", err)
	}
	for i := range list {
		if list[i].ID == "" {
			continue
		}
		p := list[i]
		peers[p.ID] = &p
	}
	return peers, nil
}

func (d *Daemon) savePeersLocked() error {
	list := make([]Peer, 0, len(d.peers))
	for _, p := range d.peers {
		list = append(list, *p)
	}
	raw, err := json.Marshal(list)
	if err != nil {
		return fmt.Errorf("api: %w", err)
	}
	return writeFileAtomic(d.peersPath(), raw, 0o600)
}

// upsertPeer adds or refreshes a paired device. A fresh pairing is an
// explicit trust decision, so the identity key is replaced when the peer
// presents a new one (e.g. after reinstalling); otherwise the registry
// would keep a stale key and every later sync would fail the key check.
// The registry save error is returned: a pairing the daemon cannot persist
// must not be reported as complete to a caller with a response path.
func (d *Daemon) upsertPeer(id, name, identityKey string) error {
	d.mu.Lock()
	defer d.mu.Unlock()
	return d.upsertPeerLocked(id, name, identityKey)
}

func (d *Daemon) upsertPeerLocked(id, name, identityKey string) error {
	now := time.Now().UnixMilli()
	pairedAt := now
	if old := d.peers[id]; old != nil {
		pairedAt = old.PairedAt
		old.cancel()
	}
	ctx, cancel := context.WithCancel(d.ctx)
	// A fresh record is also a generation token, even when re-pairing the same key.
	d.peers[id] = &Peer{
		ID: id, Name: name, IdentityKey: identityKey,
		PairedAt: pairedAt, LastSync: now, ctx: ctx, cancel: cancel,
	}
	return d.savePeersLocked()
}

// finishSync refreshes metadata only for the exact record authenticated at startup.
func (d *Daemon) finishSync(peer *Peer, name string) error {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.peers[peer.ID] != peer || peer.ctx.Err() != nil {
		return errors.New("api: peer was revoked or re-paired during sync")
	}
	peer.Name = name
	peer.LastSync = time.Now().UnixMilli()
	return d.savePeersLocked()
}

// Peers returns the paired devices.
func (d *Daemon) Peers() []Peer {
	d.mu.Lock()
	defer d.mu.Unlock()
	out := make([]Peer, 0, len(d.peers))
	for _, p := range d.peers {
		out = append(out, *p)
	}
	return out
}

// peerCount returns the number of paired devices without copying the
// registry - the status endpoint polls it on every UI tick and needs
// only the count.
func (d *Daemon) peerCount() int {
	d.mu.Lock()
	defer d.mu.Unlock()
	return len(d.peers)
}

// RevokePeer forgets a paired device; its documents stay. The second
// result reports a registry save failure.
func (d *Daemon) RevokePeer(id string) (bool, error) {
	d.mu.Lock()
	defer d.mu.Unlock()
	peer, ok := d.peers[id]
	if !ok {
		return false, nil
	}
	peer.cancel()
	delete(d.peers, id)
	if err := d.savePeersLocked(); err != nil {
		return true, err
	}
	return true, nil
}

func writeFileAtomic(path string, data []byte, perm os.FileMode) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, perm); err != nil {
		return fmt.Errorf("api: %w", err)
	}
	if err := os.Rename(tmp, path); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("api: %w", err)
	}
	return nil
}
