package sync

import (
	"encoding/base64"
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
	UpdatedAt int64  `json:"updated_at"`
	Payload   string `json:"payload"` // base64
	From      string `json:"from,omitempty"`
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
		if !(c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-' || c == '_' || c == '.') {
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
				var sd storedDoc
				if err := json.Unmarshal(raw, &sd); err != nil {
					continue
				}
				payload, err := base64.StdEncoding.DecodeString(sd.Payload)
				if err != nil {
					continue
				}
				hash = HashOf(payload)
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
	payload, err := base64.StdEncoding.DecodeString(sd.Payload)
	if err != nil {
		return Document{}, false
	}
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
		var sd storedDoc
		if err := json.Unmarshal(raw, &sd); err == nil && sd.UpdatedAt >= doc.UpdatedAt {
			return false, nil // stored copy wins (last-write-wins)
		}
	}
	if err := os.MkdirAll(filepath.Dir(p), 0o700); err != nil {
		return false, fmt.Errorf("sync: %w", err)
	}
	raw, err := json.Marshal(storedDoc{
		UpdatedAt: doc.UpdatedAt,
		Payload:   base64.StdEncoding.EncodeToString(doc.Payload),
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
