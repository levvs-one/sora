package custom

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// On-disk layout. One fixed file name means ids never become paths; the
// 0600 mode mirrors the other owner-only core files because the metadata
// sits next to secret references.
const (
	fileName = "servers.json"
	dirMode  = 0o700
	fileMode = 0o600
	// maxFileBytes bounds the metadata file read from disk.
	maxFileBytes = 1 << 20
	// MaxServers bounds the stored server list.
	MaxServers = 256
)

// secretRefFor derives the vault reference for a server's credentials,
// mirroring the subscription naming scheme ("u1_<id>_rec").
func secretRefFor(id string) string { return "custom_" + id + "_cred" }

// Secrets is the subset of the core secret store this package needs. The
// control plane passes its vault; tests pass a fake.
type Secrets interface {
	Get(reference string) ([]byte, error)
	Put(reference string, material []byte) error
	Delete(reference string) error
}

// Server is one user-added server. SecretRef names the vault entry holding
// its credentials; the material itself never lives here and is never
// logged.
type Server struct {
	ID        string
	Name      string
	Protocol  Protocol
	Address   string
	Port      uint16
	SecretRef string
	Created   time.Time
	Updated   time.Time
}

// record is the JSON form of Server.
type record struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Protocol  Protocol  `json:"protocol"`
	Address   string    `json:"address"`
	Port      uint16    `json:"port"`
	SecretRef string    `json:"secret_ref"`
	Created   time.Time `json:"created"`
	Updated   time.Time `json:"updated"`
}

func toRecord(s Server) record {
	return record{
		ID: s.ID, Name: s.Name, Protocol: s.Protocol, Address: s.Address,
		Port: s.Port, SecretRef: s.SecretRef, Created: s.Created, Updated: s.Updated,
	}
}

func fromRecord(r record) Server {
	return Server{
		ID: r.ID, Name: r.Name, Protocol: r.Protocol, Address: r.Address,
		Port: r.Port, SecretRef: r.SecretRef, Created: r.Created, Updated: r.Updated,
	}
}

// Store persists custom servers in dir/custom/servers.json and their
// credentials in the secret vault. It is safe for concurrent use.
type Store struct {
	mu      sync.Mutex
	dir     string
	path    string
	secrets Secrets
	servers map[string]Server
	order   []string
}

// Open loads the store from dir, creating the directory on first use. A
// corrupt file fails closed: silently starting empty would lose the user's
// servers.
func Open(dir string, secrets Secrets) (*Store, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the data directory is empty")
	}
	if err := os.MkdirAll(dir, dirMode); err != nil {
		return nil, errs.Newf(errs.CodeInternal, errs.KeyInternal,
			"custom: cannot create the store directory")
	}
	s := &Store{
		dir:     dir,
		path:    filepath.Join(dir, fileName),
		secrets: secrets,
		servers: make(map[string]Server),
	}
	if err := s.load(); err != nil {
		return nil, err
	}
	return s, nil
}

// load reads the metadata file. A missing file is an empty store.
func (s *Store) load() error {
	raw, err := os.ReadFile(s.path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return errs.Newf(errs.CodeInternal, errs.KeyInternal,
			"custom: cannot read the server list")
	}
	if len(raw) > maxFileBytes {
		return errs.Newf(errs.CodeInternal, errs.KeyInternal,
			"custom: the server list is too large")
	}
	var records []record
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&records); err != nil {
		return errs.Newf(errs.CodeInternal, errs.KeyInternal,
			"custom: the server list is corrupt")
	}
	if len(records) > MaxServers {
		return errs.Newf(errs.CodeInternal, errs.KeyInternal,
			"custom: the server list is too large")
	}
	for _, r := range records {
		// Fail closed on any invalid field: the file is only ever written
		// through the validated Save path, so a bad record means tampering
		// or corruption, and its values must never reach the engine.
		if err := ValidateID(r.ID); err != nil {
			return errs.Newf(errs.CodeInternal, errs.KeyInternal,
				"custom: the server list is corrupt")
		}
		if err := ValidateName(r.Name); err != nil {
			return errs.Newf(errs.CodeInternal, errs.KeyInternal,
				"custom: the server list is corrupt")
		}
		if err := ValidateProtocol(r.Protocol); err != nil {
			return errs.Newf(errs.CodeInternal, errs.KeyInternal,
				"custom: the server list is corrupt")
		}
		if err := ValidateAddress(r.Address); err != nil {
			return errs.Newf(errs.CodeInternal, errs.KeyInternal,
				"custom: the server list is corrupt")
		}
		if err := ValidatePort(uint32(r.Port)); err != nil {
			return errs.Newf(errs.CodeInternal, errs.KeyInternal,
				"custom: the server list is corrupt")
		}
		// The vault reference is derived deterministically from the id; a
		// record pointing anywhere else breaks the package invariant.
		if r.SecretRef != secretRefFor(r.ID) {
			return errs.Newf(errs.CodeInternal, errs.KeyInternal,
				"custom: the server list is corrupt")
		}
		if _, dup := s.servers[r.ID]; dup {
			return errs.Newf(errs.CodeInternal, errs.KeyInternal,
				"custom: the server list is corrupt")
		}
		s.servers[r.ID] = fromRecord(r)
		s.order = append(s.order, r.ID)
	}
	return nil
}

// persist writes the metadata atomically: temp file plus rename keeps
// either the old or the new state after a crash.
func (s *Store) persistLocked() error {
	records := make([]record, 0, len(s.order))
	for _, id := range s.order {
		records = append(records, toRecord(s.servers[id]))
	}
	raw, err := json.Marshal(records)
	if err != nil {
		return errs.Newf(errs.CodeInternal, errs.KeyInternal,
			"custom: cannot encode the server list")
	}
	tmp := s.path + ".tmp"
	if err := os.WriteFile(tmp, raw, fileMode); err != nil {
		return errs.Newf(errs.CodeInternal, errs.KeyInternal,
			"custom: cannot write the server list")
	}
	if err := os.Rename(tmp, s.path); err != nil {
		_ = os.Remove(tmp)
		return errs.Newf(errs.CodeInternal, errs.KeyInternal,
			"custom: cannot write the server list")
	}
	return nil
}

// Save creates a server (empty ID) or updates an existing one. On create,
// credentials are required and the core assigns an id; on update, empty
// credentials keep the stored secret. The returned server never carries
// credential material.
func (s *Store) Save(in Server, credentials []byte) (Server, error) {
	if err := ValidateName(in.Name); err != nil {
		return Server{}, err
	}
	if err := ValidateProtocol(in.Protocol); err != nil {
		return Server{}, err
	}
	if err := ValidateAddress(in.Address); err != nil {
		return Server{}, err
	}
	if err := ValidatePort(uint32(in.Port)); err != nil {
		return Server{}, err
	}
	create := in.ID == ""
	if !create {
		if err := ValidateID(in.ID); err != nil {
			return Server{}, err
		}
	}
	if s.secrets == nil {
		return Server{}, errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
			"custom: the secret store is unavailable")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	var current Server
	if create {
		if len(s.servers) >= MaxServers {
			return Server{}, errs.Newf(errs.CodeResourceExhausted, errs.KeyRequestTooLarge,
				"custom: too many servers")
		}
		id, err := newID(s.servers)
		if err != nil {
			return Server{}, err
		}
		in.ID = id
		current.Created = time.Now().UTC()
	} else {
		var ok bool
		current, ok = s.servers[in.ID]
		if !ok {
			return Server{}, errs.Newf(errs.CodeNotFound, errs.KeyNotFound,
				"custom: the server does not exist")
		}
	}

	if err := ValidateCredentials(credentials, create); err != nil {
		return Server{}, err
	}
	ref := secretRefFor(in.ID)
	var prev []byte // previous material, to roll back a failed persist below
	if len(credentials) > 0 {
		// ValidateReference-equivalent: the id charset is a subset of the
		// vault's, and the total length stays within its 64-byte limit.
		if !create {
			// The update path only reaches here with a stored secret, so
			// the reference exists; snapshot it to undo the vault write if
			// the metadata persist fails. Best effort.
			prev, _ = s.secrets.Get(ref)
		}
		if err := s.secrets.Put(ref, credentials); err != nil {
			return Server{}, err
		}
		current.SecretRef = ref
	} else if current.SecretRef == "" {
		// Update path with no stored secret: cannot happen after a
		// validated create, but fail closed rather than store a
		// credential-less server.
		return Server{}, errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretNotFound,
			"custom: the server has no stored credentials")
	}

	current.ID = in.ID
	current.Name = strings.TrimSpace(in.Name)
	current.Protocol = in.Protocol
	current.Address = strings.TrimSpace(in.Address)
	current.Port = in.Port
	current.Updated = time.Now().UTC()

	s.servers[current.ID] = current
	if create {
		s.order = append(s.order, current.ID)
	}
	if err := s.persistLocked(); err != nil {
		if create {
			delete(s.servers, current.ID)
			s.order = s.order[:len(s.order)-1]
			_ = s.secrets.Delete(ref)
		} else {
			// The vault write already succeeded; put the previous material
			// back so the failed update changes nothing, then reload the
			// metadata so memory matches disk instead of diverging
			// silently.
			if prev != nil {
				_ = s.secrets.Put(ref, prev)
			}
			_ = s.reloadLocked()
		}
		return Server{}, err
	}
	return current, nil
}

// reloadLocked re-reads the metadata file after a failed persist so the
// in-memory state matches the disk.
func (s *Store) reloadLocked() error {
	keep := s.servers
	keepOrder := s.order
	s.servers = make(map[string]Server)
	s.order = nil
	if err := s.load(); err != nil {
		s.servers = keep
		s.order = keepOrder
		return err
	}
	return nil
}

// Delete removes a server and its credentials. Missing ids and missing
// vault entries succeed for repeatable cleanup.
func (s *Store) Delete(id string) error {
	if err := ValidateID(id); err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	current, ok := s.servers[id]
	if !ok {
		return nil
	}
	// Delete the vault secret before the metadata: a failed vault delete
	// leaves the server (and a retryable delete) instead of an orphaned
	// secret no API call could reach again.
	var prev []byte // snapshot for rollback if the persist fails
	if current.SecretRef != "" {
		if s.secrets == nil {
			return errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
				"custom: the secret store is unavailable")
		}
		prev, _ = s.secrets.Get(current.SecretRef) // best effort
		// The vault's Delete is idempotent on missing references.
		if err := s.secrets.Delete(current.SecretRef); err != nil {
			return err
		}
	}
	idx := -1
	for i, oid := range s.order {
		if oid == id {
			idx = i
			break
		}
	}
	delete(s.servers, id)
	if idx >= 0 {
		s.order = append(s.order[:idx], s.order[idx+1:]...)
	}
	if err := s.persistLocked(); err != nil {
		// Roll back to the on-disk state and restore the secret so the
		// metadata and the vault agree again; the delete stays retryable.
		s.servers[id] = current
		if idx >= 0 {
			s.order = append(s.order, "")
			copy(s.order[idx+1:], s.order[idx:])
			s.order[idx] = id
		}
		if prev != nil {
			_ = s.secrets.Put(current.SecretRef, prev)
		}
		return err
	}
	return nil
}

// Get returns one server by id.
func (s *Store) Get(id string) (Server, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	srv, ok := s.servers[id]
	return srv, ok
}

// List returns all servers in insertion order.
func (s *Store) List() []Server {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]Server, 0, len(s.order))
	for _, id := range s.order {
		out = append(out, s.servers[id])
	}
	return out
}

// newID mints a collision-free 16-hex-character id.
func newID(existing map[string]Server) (string, error) {
	for range 8 {
		var b [8]byte
		if _, err := rand.Read(b[:]); err != nil {
			return "", errs.Newf(errs.CodeInternal, errs.KeyInternal,
				"custom: cannot mint a server id")
		}
		id := hex.EncodeToString(b[:])
		if _, dup := existing[id]; !dup {
			return id, nil
		}
	}
	return "", errs.Newf(errs.CodeInternal, errs.KeyInternal,
		"custom: cannot mint a server id")
}
