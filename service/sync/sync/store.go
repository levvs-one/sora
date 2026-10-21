package sync

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

// DirStore keeps documents as JSON files under dir/<kind>/<name>.json with
// owner-only permissions. Writes are atomic.
type DirStore struct {
	mu  sync.Mutex
	dir string
}

// NewDirStore creates the store, making the directory when needed.
func NewDirStore(dir string) (*DirStore, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, fmt.Errorf("sync: empty store directory")
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, fmt.Errorf("sync: %w", err)
	}
	return &DirStore{dir: dir}, nil
}

type storedDoc struct {
	UpdatedAt int64 `json:"updated_at"`
	// Payload is a []byte so encoding/json base64-encodes it directly:
	// the on-disk form is the exact base64 string a string field held,
	// but neither the writer (EncodeToString copy) nor the reader
	// (string copy + DecodeString copy) pays for an extra full-size
	// copy of the payload. A nil payload must be stored as []byte{}
	// by callers: encoding/json renders a nil []byte as null, not "".
	Payload []byte `json:"payload"` // base64 in JSON
	From    string `json:"from,omitempty"`
	// Hash is the cached hex sha256 of the payload, computed once by Put.
	// Files written before the cache existed have no hash; readers fall
	// back to decoding and hashing the payload.
	Hash string `json:"hash,omitempty"`
}

// safeName rejects path separators and traversal so kind/name can address
// files directly.
func safeName(s string) bool {
	if s == "" || s == "." || s == ".." || len(s) > 128 {
		return false
	}
	for _, c := range s {
		if (c < 'a' || c > 'z') && (c < 'A' || c > 'Z') && (c < '0' || c > '9') && c != '-' && c != '_' && c != '.' {
			return false
		}
	}
	return !strings.Contains(s, "..")
}

func (d *DirStore) path(kind, name string) (string, error) {
	if !safeName(kind) || !safeName(name) {
		return "", fmt.Errorf("sync: unsafe document name %q/%q", kind, name)
	}
	return filepath.Join(d.dir, kind, name+".json"), nil
}

// storedMeta is the subset of storedDoc an inventory scan needs: the
// payload stays on disk, undecided and unhashed, unless the cached hash is
// missing (files written before the cache).
type storedMeta struct {
	UpdatedAt int64  `json:"updated_at"`
	Hash      string `json:"hash,omitempty"`
}

// List returns the metadata of every stored document.
func (d *DirStore) List() []Meta {
	d.mu.Lock()
	defer d.mu.Unlock()
	var out []Meta
	kinds, err := os.ReadDir(d.dir)
	if err != nil {
		return nil
	}
	for _, k := range kinds {
		if !k.IsDir() || !safeName(k.Name()) {
			continue
		}
		files, err := os.ReadDir(filepath.Join(d.dir, k.Name()))
		if err != nil {
			continue
		}
		for _, f := range files {
			if f.IsDir() || !strings.HasSuffix(f.Name(), ".json") {
				continue
			}
			name := strings.TrimSuffix(f.Name(), ".json")
			if !safeName(name) {
				continue
			}
			raw, err := os.ReadFile(filepath.Join(d.dir, k.Name(), f.Name()))
			if err != nil {
				continue
			}
			var sm storedMeta
			if err := json.Unmarshal(raw, &sm); err != nil {
				continue
			}
			hash := sm.Hash
			if hash == "" {
				// Legacy file: decode and hash once, as List used to.
				// storedDoc's []byte payload is already the decoded
				// bytes (encoding/json base64-decodes it).
				var sd storedDoc
				if err := json.Unmarshal(raw, &sd); err != nil {
					continue
				}
				hash = HashOf(sd.Payload)
			}
			out = append(out, Meta{
				Kind: k.Name(), Name: name,
				UpdatedAt: sm.UpdatedAt, Hash: hash,
			})
		}
	}
	return out
}

// Get returns the stored document.
func (d *DirStore) Get(kind, name string) (Document, bool) {
	d.mu.Lock()
	defer d.mu.Unlock()
	p, err := d.path(kind, name)
	if err != nil {
		return Document{}, false
	}
	raw, err := os.ReadFile(p)
	if err != nil {
		return Document{}, false
	}
	var sd storedDoc
	if err := json.Unmarshal(raw, &sd); err != nil {
		return Document{}, false
	}
	payload := sd.Payload
	// Get returns the payload, so the hash is recomputed from it: the
	// Meta.Hash == sha256(payload) invariant (sync.go) must hold for
	// every document Get hands out, even if the on-disk cache was
	// edited or written by an older build. The cache stays only in
	// List(), the one place that never decodes payloads.
	hash := HashOf(payload)
	return Document{
		Meta:    Meta{Kind: kind, Name: name, UpdatedAt: sd.UpdatedAt, Hash: hash},
		Payload: payload,
		From:    sd.From,
	}, true
}

// Put stores the document when it is newer than the stored copy.
func (d *DirStore) Put(doc Document) (bool, error) {
	if !safeName(doc.Kind) || !safeName(doc.Name) {
		return false, fmt.Errorf("sync: unsafe document name %q/%q", doc.Kind, doc.Name)
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	p, err := d.path(doc.Kind, doc.Name)
	if err != nil {
		return false, err
	}
	if raw, err := os.ReadFile(p); err == nil {
		// The last-write-wins check needs only the stored timestamp:
		// unmarshal into storedMeta so the decoder skips the payload
		// instead of materialising a full-size copy of a document that
		// is about to be kept or replaced unread.
		var sm storedMeta
		if err := json.Unmarshal(raw, &sm); err == nil && sm.UpdatedAt >= doc.UpdatedAt {
			return false, nil // stored copy wins (last-write-wins)
		}
	}
	if err := os.MkdirAll(filepath.Dir(p), 0o700); err != nil {
		return false, fmt.Errorf("sync: %w", err)
	}
	payload := doc.Payload
	if payload == nil {
		payload = []byte{} // keep "payload":"" on disk, never null
	}
	raw, err := json.Marshal(storedDoc{
		UpdatedAt: doc.UpdatedAt,
		Payload:   payload,
		From:      doc.From,
		// Cache the hash at write time so reads never decode and hash
		// the payload; computed here rather than trusting doc.Hash.
		Hash: HashOf(doc.Payload),
	})
	if err != nil {
		return false, fmt.Errorf("sync: %w", err)
	}
	tmp := p + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return false, fmt.Errorf("sync: %w", err)
	}
	if err := os.Rename(tmp, p); err != nil {
		_ = os.Remove(tmp)
		return false, fmt.Errorf("sync: %w", err)
	}
	return true, nil
}
