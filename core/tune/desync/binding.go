package desync

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/profiles"
)

// Bindings: the tuner's memory, keyed by the F5 network.
//
// A winner is only useful bound to the network it won on — strategies
// are ISP-specific, and TSPU relearns them in minutes (see rotate.go).
// The BindingStore persists, per network key, the winning genome, the
// ranked runners-up (the rotation ring's material), which registry
// profile the winner came from, and the registry/gene-pool versions
// it was scored under, so a future format can re-validate instead of
// trusting blindly.
//
// The file is versioned and fail-closed: a corrupt file or a version
// this build does not understand is an ERROR at load, never a silent
// reset — silently forgetting bindings would re-probe a live censor
// on every start, and silently misreading them could bind a strategy
// to the wrong network.

// BindingsVersion versions the on-disk binding format.
const BindingsVersion = 1

// bindingFileName is the store location inside the data directory.
const bindingFileName = "desync/bindings.json"

// Binding is one network's remembered tuning outcome.
type Binding struct {
	// ProfileID is the registry profile the winner came from, or ""
	// when the winner is a mutation/seed known only by its genome ID.
	ProfileID string `json:"profile_id,omitempty"`
	// Winner is the best-scoring genome.
	Winner Params `json:"winner"`
	// Ranked holds the runners-up that scored > 0, best first: the
	// rotation ring rotates through Winner + Ranked. RankedScores is
	// parallel to Ranked (the fitness each runner-up measured).
	Ranked       []Params  `json:"ranked,omitempty"`
	RankedScores []float64 `json:"ranked_scores,omitempty"`
	// Score is the winner's fitness when it won.
	Score float64 `json:"score"`
	// At is when the winner was scored.
	At time.Time `json:"at"`
	// RegistryVersion and GenePoolVersion record the data versions
	// the winner was validated against.
	RegistryVersion int `json:"registry_version"`
	GenePoolVersion int `json:"gene_pool_version"`
}

type bindingFile struct {
	Version int                `json:"version"`
	Entries map[string]Binding `json:"entries"`
}

// BindingStore persists bindings under a data directory. The zero
// value is not usable; build one with NewBindingStore. An empty dir
// keeps bindings in memory only.
type BindingStore struct {
	mu      sync.Mutex
	path    string
	entries map[string]Binding
}

// NewBindingStore loads the bindings file. A missing file starts
// empty; a corrupt or foreign-version file is an error (fail-closed,
// see the package comment above).
func NewBindingStore(dir string) (*BindingStore, error) {
	s := &BindingStore{entries: map[string]Binding{}}
	if dir == "" {
		return s, nil
	}
	if err := os.MkdirAll(filepath.Dir(filepath.Join(dir, bindingFileName)), 0o700); err != nil {
		return nil, fmt.Errorf("desync: %w", err)
	}
	s.path = filepath.Join(dir, bindingFileName)
	raw, err := os.ReadFile(s.path)
	if err != nil {
		if os.IsNotExist(err) {
			return s, nil
		}
		return nil, fmt.Errorf("desync: %w", err)
	}
	var f bindingFile
	if err := json.Unmarshal(raw, &f); err != nil {
		return nil, fmt.Errorf("desync: the bindings file is not valid JSON: %w", err)
	}
	if f.Version != BindingsVersion {
		return nil, fmt.Errorf("desync: the bindings file is version %d, this build understands %d: refusing to guess", f.Version, BindingsVersion)
	}
	// Entries are served only after re-validation (Service.Current
	// re-checks the winner converts and still validates), so load
	// keeps them verbatim: dropping data here would hide corruption
	// the serve path is responsible for refusing.
	for k, b := range f.Entries {
		s.entries[k] = b
	}
	return s, nil
}

// Lookup returns the binding remembered for a network fingerprint.
func (s *BindingStore) Lookup(fp profiles.Fingerprint) (Binding, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	b, ok := s.entries[NetworkKey(fp)]
	return b, ok
}

// Bind records a tuning outcome for a network and persists it. A
// persistence failure is returned (the caller surfaces it as a
// non-fatal cache warning, like package tune does): the winner still
// applies to this session, it just will not survive a restart.
func (s *BindingStore) Bind(fp profiles.Fingerprint, b Binding) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.entries[NetworkKey(fp)] = b
	return s.writeLocked()
}

func (s *BindingStore) writeLocked() error {
	if s.path == "" {
		return nil
	}
	raw, err := json.MarshalIndent(bindingFile{Version: BindingsVersion, Entries: s.entries}, "", "  ")
	if err != nil {
		return fmt.Errorf("desync: %w", err)
	}
	tmp := s.path + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return fmt.Errorf("desync: %w", err)
	}
	if err := os.Rename(tmp, s.path); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("desync: %w", err)
	}
	return nil
}
