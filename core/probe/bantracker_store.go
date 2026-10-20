package probe

// BanTracker persistence: a core restart must not silently forget
// residual QUIC bans. A ban lasts 420 s and self-renews while packets
// arrive; a restarted core that forgot it would re-dial from a banned
// source port and extend the very ban it was avoiding. The tracker
// therefore snapshots to a small JSON file: the production wiring
// (cmd/sora-core's QUIC probe) loads it before probing and saves it
// after, so a restart inside the ban window resumes with the bans
// intact. Expired entries are dropped at save and at load — the file
// never resurrects a ban whose time has run out.
//
// Failure is honest, never silent: a corrupt file makes
// LoadBanTracker return an error and no tracker, so the caller can
// record "ban state reset: <reason>" in the censorship journal/log
// instead of quietly starting empty. A missing file is not an error
// and not a reset: it is a first run.

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"time"
)

// banTrackerFileVersion is the on-disk format version.
const banTrackerFileVersion = 1

type banTrackerFile struct {
	Version int            `json:"version"`
	SavedAt time.Time      `json:"saved_at"`
	Entries []banFileEntry `json:"entries"`
}

type banFileEntry struct {
	Key   string    `json:"key"` // "localPort->remote", see banKey
	Until time.Time `json:"until"`
}

// Snapshot returns the live (unexpired) bans as key → expiry. Expired
// entries are pruned as a side effect, exactly as Banned prunes them.
func (b *BanTracker) Snapshot() map[string]time.Time {
	b.mu.Lock()
	defer b.mu.Unlock()
	now := b.now()
	out := make(map[string]time.Time, len(b.until))
	for k, until := range b.until {
		if !now.Before(until) {
			delete(b.until, k)
			continue
		}
		out[k] = until
	}
	return out
}

// Restore loads bans from a snapshot, dropping entries that have
// already expired, and returns how many live bans were restored. It
// merges into any existing state; an entry already present keeps the
// later expiry (a ban can only be extended by fresher evidence).
func (b *BanTracker) Restore(snap map[string]time.Time) int {
	b.mu.Lock()
	defer b.mu.Unlock()
	if b.until == nil {
		b.until = map[string]time.Time{}
	}
	now := b.now()
	n := 0
	for k, until := range snap {
		if !now.Before(until) {
			continue
		}
		if cur, ok := b.until[k]; !ok || until.After(cur) {
			b.until[k] = until
		}
		n++
	}
	return n
}

// SaveBanTracker writes the tracker's live bans to path atomically
// (temp file + rename, owner-only permissions: the file reveals which
// remotes the censor banned, which is path metadata).
func SaveBanTracker(path string, b *BanTracker) error {
	snap := b.Snapshot()
	keys := make([]string, 0, len(snap))
	for k := range snap {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	f := banTrackerFile{Version: banTrackerFileVersion, SavedAt: b.now()}
	for _, k := range keys {
		f.Entries = append(f.Entries, banFileEntry{Key: k, Until: snap[k]})
	}
	raw, err := json.Marshal(f)
	if err != nil {
		return fmt.Errorf("probe: encode ban tracker: %w", err)
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return fmt.Errorf("probe: write ban tracker: %w", err)
	}
	if err := os.Rename(tmp, path); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("probe: replace ban tracker: %w", err)
	}
	return nil
}

// LoadBanTracker reads a snapshot written by SaveBanTracker. It
// returns the tracker and the number of live bans restored. A missing
// file yields a fresh tracker, zero and a nil error (first run). A
// corrupt or foreign file yields a nil tracker and an error: the
// caller must surface the reset, not start empty in silence.
func LoadBanTracker(path string) (*BanTracker, int, error) {
	raw, err := os.ReadFile(filepath.Clean(path))
	if errors.Is(err, fs.ErrNotExist) {
		return NewBanTracker(), 0, nil
	}
	if err != nil {
		return nil, 0, fmt.Errorf("probe: read ban tracker: %w", err)
	}
	var f banTrackerFile
	if err := json.Unmarshal(raw, &f); err != nil {
		return nil, 0, fmt.Errorf("probe: ban tracker file is corrupt: %w", err)
	}
	if f.Version != banTrackerFileVersion {
		return nil, 0, fmt.Errorf("probe: ban tracker file version %d is not supported", f.Version)
	}
	snap := make(map[string]time.Time, len(f.Entries))
	for _, e := range f.Entries {
		snap[e.Key] = e.Until
	}
	t := NewBanTracker()
	return t, t.Restore(snap), nil
}
