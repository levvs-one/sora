package subscription

// User overrides on top of a subscription. A refresh replaces the provider
// server list; overrides re-apply afterwards so renames, hidden servers,
// extra rules and pinned order survive. Deleting the subscription deletes
// its overrides.

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sync"
)

// Override is the user edit layer for one subscription.
type Override struct {
	// Renames maps server id to display name. Empty value clears a rename.
	Renames map[string]string `json:"renames,omitempty"`
	// Hidden lists server ids the user hid.
	Hidden []string `json:"hidden,omitempty"`
	// ExtraRules are user routing rules bound to the subscription.
	ExtraRules []OverrideRule `json:"extra_rules,omitempty"`
	// PinnedOrder lists server ids first; others keep relative order after.
	PinnedOrder []string `json:"pinned_order,omitempty"`
	// ProviderRouting is the provider-supplied routing layer (C3,
	// Happ happRouting), stored beside the user edits but owned by
	// refreshes: every successful refresh replaces it wholesale, user
	// saves preserve it, and it dies with the subscription. Keeping
	// it apart from ExtraRules is what lets a refresh replace the
	// provider's rules without ever touching the user's.
	ProviderRouting *ProviderRouting `json:"provider_routing,omitempty"`
}

// ProviderRouting is one converted provider routing profile bound to
// a subscription. Rules are in the contract's destination form;
// proxy rules carry the outbound_id sentinel "proxy", which the
// client substitutes with its session proxy target when merging the
// rules into a plan (the same resolution it applies to user rules).
type ProviderRouting struct {
	// Name is the profile name from the provider document.
	Name string `json:"name,omitempty"`
	// Rules are the converted Direct/Proxy/Block rules.
	Rules []OverrideRule `json:"rules,omitempty"`
	// GlobalProxy is the provider's default-traffic decision when
	// the document carried one. Recorded, not applied: see
	// core/happrouting's GlobalProxy note.
	GlobalProxy *bool `json:"global_proxy,omitempty"`
	// RemoteDNS / DomesticDNS are the provider's resolvers verbatim
	// ("DoH https://…"), recorded, not applied: sora's DNS is one
	// user-owned per-session list with no remote/domestic split.
	RemoteDNS    string `json:"remote_dns,omitempty"`
	DomesticDNS  string `json:"domestic_dns,omitempty"`
	Notes        []ProviderNote `json:"notes,omitempty"`
	Skipped      int    `json:"skipped,omitempty"`
}

// ProviderNote records how one field of the provider document was
// handled, mirroring happrouting.Note for storage.
type ProviderNote struct {
	Field   string `json:"field"`
	Applied bool   `json:"applied"`
	Reason  string `json:"reason,omitempty"`
}

// OverrideRule is one user routing rule.
type OverrideRule struct {
	Destination string `json:"destination"`
	OutboundID  string `json:"outbound_id"`
}

// ErrOverrideCorrupt marks an unreadable override file. Callers must log it
// and continue without overrides, never fail the subscription update.
var ErrOverrideCorrupt = errors.New("subscription: override file is corrupt")

var overrideIDPattern = regexp.MustCompile(`^[0-9a-f]{16}$`)

// validOverrideID rejects anything but generated subscription ids, closing
// path traversal through the file name.
func validOverrideID(id string) bool { return overrideIDPattern.MatchString(id) }

// OverrideStore persists overrides as JSON under <dir>/overrides/.
type OverrideStore struct {
	dir string
	mu  sync.Mutex
}

// NewOverrideStore creates the store; dir is the core data directory.
// A nil store (nil *OverrideStore) disables overrides: every method is safe
// to call on it.
func NewOverrideStore(dir string) *OverrideStore {
	if dir == "" {
		return nil
	}
	return &OverrideStore{dir: dir}
}

func (s *OverrideStore) path(id string) (string, error) {
	if s == nil {
		return "", errors.New("subscription: override store disabled")
	}
	if !validOverrideID(id) {
		return "", fmt.Errorf("subscription: bad override id")
	}
	return filepath.Join(s.dir, "overrides", id+".json"), nil
}

// Load returns the stored override. A missing file yields an empty override
// and no error; a corrupt file yields an empty override and
// ErrOverrideCorrupt so the caller can log it and continue.
func (s *OverrideStore) Load(id string) (*Override, error) {
	path, err := s.path(id)
	if err != nil {
		return &Override{}, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	raw, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return &Override{}, nil
		}
		return &Override{}, err
	}
	var o Override
	if err := json.Unmarshal(raw, &o); err != nil {
		return &Override{}, ErrOverrideCorrupt
	}
	return &o, nil
}

// Save stores the override atomically. An empty override removes the file.
func (s *OverrideStore) Save(id string, o *Override) error {
	path, err := s.path(id)
	if err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if o == nil || (len(o.Renames) == 0 && len(o.Hidden) == 0 && len(o.ExtraRules) == 0 && len(o.PinnedOrder) == 0 && o.ProviderRouting == nil) {
		// Report a failed removal like Delete does: a silent failure
		// would keep stale renames, hides and pins applied while the
		// user believes they cleared them.
		if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
			return err
		}
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	raw, err := json.Marshal(o)
	if err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// Delete removes the override file, if any.
func (s *OverrideStore) Delete(id string) error {
	path, err := s.path(id)
	if err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}
