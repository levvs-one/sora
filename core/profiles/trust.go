package profiles

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

// Trust is the user's trust mark for one Wi-Fi network, keyed by SSID.
// The effective trust of a network the user never marked is untrusted:
// a new network must never be treated as trusted.
type Trust int

const (
	// TrustNone means no mark was ever recorded for the network.
	TrustNone Trust = iota
	// TrustUntrusted marks a network the user does not trust.
	TrustUntrusted
	// TrustTrusted marks a network the user explicitly trusts.
	TrustTrusted
)

// String renders the mark for the store file and diagnostics.
func (t Trust) String() string {
	switch t {
	case TrustTrusted:
		return "trusted"
	case TrustUntrusted:
		return "untrusted"
	default:
		return "none"
	}
}

// parseTrust reads a mark back from the store file.
func parseTrust(s string) (Trust, error) {
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "trusted":
		return TrustTrusted, nil
	case "untrusted":
		return TrustUntrusted, nil
	case "none", "":
		return TrustNone, nil
	default:
		return TrustNone, fmt.Errorf("profiles: unknown trust mark %q", s)
	}
}

const (
	trustFileName = "trust.json"
	trustFileVer  = 1
)

// trustFile is the on-disk shape: SSID to mark name.
type trustFile struct {
	Version int               `json:"version"`
	Marks   map[string]string `json:"marks"`
}

// validateSSID checks a trust-store key the same way SSID triggers are
// checked: non-empty, bounded, no control characters.
func validateSSID(ssid string) error {
	if ssid == "" {
		return errors.New("profiles: the SSID is empty")
	}
	if len(ssid) > MaxTriggerLen {
		return fmt.Errorf("profiles: the SSID is longer than %d bytes", MaxTriggerLen)
	}
	if strings.ContainsAny(ssid, "\r\n\t") {
		return errors.New("profiles: the SSID contains control characters")
	}
	return nil
}

// TrustStore keeps the user's per-SSID trust marks in one JSON file under
// the data directory. An empty dir disables persistence: the store works in
// memory only. A corrupt file fails fast like profiles.json - trust marks
// are authoritative user data, not a heuristic.
type TrustStore struct {
	mu    sync.Mutex
	path  string
	marks map[string]Trust
}

// NewTrustStore loads the trust file, creating the directory when needed.
func NewTrustStore(dir string) (*TrustStore, error) {
	ts := &TrustStore{marks: map[string]Trust{}}
	if strings.TrimSpace(dir) == "" {
		return ts, nil
	}
	if err := os.MkdirAll(dir, dirPerm); err != nil {
		return nil, fmt.Errorf("profiles: %w", err)
	}
	ts.path = filepath.Join(dir, trustFileName)
	raw, err := os.ReadFile(ts.path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return ts, nil
		}
		return nil, fmt.Errorf("profiles: %w", err)
	}
	if len(raw) > maxFileBytes {
		return nil, fmt.Errorf("profiles: the trust file is larger than %d bytes", maxFileBytes)
	}
	var f trustFile
	if err := json.Unmarshal(raw, &f); err != nil {
		return nil, fmt.Errorf("profiles: the trust file is not valid JSON: %w", err)
	}
	if f.Version != trustFileVer {
		return nil, fmt.Errorf("profiles: the trust file has version %d, want %d", f.Version, trustFileVer)
	}
	for ssid, s := range f.Marks {
		if err := validateSSID(ssid); err != nil {
			return nil, fmt.Errorf("profiles: stored trust mark: %w", err)
		}
		t, err := parseTrust(s)
		if err != nil {
			return nil, fmt.Errorf("profiles: stored trust mark for %q: %w", ssid, err)
		}
		if t != TrustNone {
			ts.marks[ssid] = t
		}
	}
	return ts, nil
}

// Set records the trust mark for an SSID. TrustNone removes the mark.
func (ts *TrustStore) Set(ssid string, t Trust) error {
	if err := validateSSID(ssid); err != nil {
		return err
	}
	if t != TrustTrusted && t != TrustUntrusted && t != TrustNone {
		return fmt.Errorf("profiles: unknown trust mark %d", int(t))
	}
	ts.mu.Lock()
	defer ts.mu.Unlock()
	if t == TrustNone {
		delete(ts.marks, ssid)
	} else {
		ts.marks[ssid] = t
	}
	return ts.writeLocked()
}

// Lookup returns the recorded mark and whether one exists. An SSID that was
// never marked reports (TrustNone, false).
func (ts *TrustStore) Lookup(ssid string) (Trust, bool) {
	ts.mu.Lock()
	defer ts.mu.Unlock()
	t, ok := ts.marks[ssid]
	return t, ok
}

// Effective returns the trust to act on. Only an explicitly trusted network
// is trusted; an explicitly untrusted one - and, crucially, one the user
// never marked - is untrusted. A new network defaults to untrusted, never
// to trusted. An empty SSID (wired or offline) carries no per-SSID opinion
// and reports TrustNone.
func (ts *TrustStore) Effective(ssid string) Trust {
	if ssid == "" {
		return TrustNone
	}
	if t, ok := ts.Lookup(ssid); ok {
		return t
	}
	return TrustUntrusted
}

// writeLocked stores the marks atomically with owner-only permissions.
func (ts *TrustStore) writeLocked() error {
	if ts.path == "" {
		return nil
	}
	raw := map[string]string{}
	for ssid, t := range ts.marks {
		raw[ssid] = t.String()
	}
	data, err := json.MarshalIndent(trustFile{Version: trustFileVer, Marks: raw}, "", "  ")
	if err != nil {
		return fmt.Errorf("profiles: %w", err)
	}
	tmp := ts.path + ".tmp"
	if err := os.WriteFile(tmp, data, filePerm); err != nil {
		return fmt.Errorf("profiles: %w", err)
	}
	if err := os.Rename(tmp, ts.path); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("profiles: %w", err)
	}
	return nil
}
