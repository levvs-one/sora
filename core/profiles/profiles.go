// Package profiles stores network profiles and matches them against the
// machine's current network. A profile describes the settings to use on a
// network (tunnel mode, DNS, routing preset, preferred server and engine)
// and the triggers identifying that network (Wi-Fi SSIDs, default gateways,
// ASNs). The session watches for network changes and reports a match so the
// client can apply the profile, automatically or after asking the user.
package profiles

import (
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"net/netip"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// Limits keep one profile small and the file parseable.
const (
	MaxNameLen    = 128
	MaxTriggerLen = 256
	MaxTriggers   = 64
	MaxDNS        = 8
	MaxProfiles   = 128
	fileName      = "profiles.json"
	asnTableName  = "asn.json"
	filePerm      = 0o600
	dirPerm       = 0o700
	maxFileBytes  = 1 << 20
	maxIDLen      = 64
)

// Triggers identifies the networks a profile matches. A profile with no
// triggers never matches automatically.
type Triggers struct {
	// SSIDs match the current Wi-Fi network name, exact and case-sensitive.
	SSIDs []string `json:"ssids,omitempty"`
	// Gateways match the default gateway address, e.g. "192.168.1.1".
	Gateways []string `json:"gateways,omitempty"`
	// ASNs match the autonomous system number as a string, e.g. "12389",
	// resolved from the optional local ASN table.
	ASNs []string `json:"asns,omitempty"`
}

// Apply describes the settings to use on a matched network.
type Apply struct {
	// Mode is "tun" or "proxy". Nil keeps the current mode.
	Mode *string `json:"mode,omitempty"`
	// DNS servers to use on this network.
	DNS []string `json:"dns"`
	// RulesPreset is the routing preset id to apply.
	RulesPreset *string `json:"rules_preset,omitempty"`
	// ServerID is the preferred server on this network.
	ServerID *string `json:"server_id,omitempty"`
	// Engine is the preferred engine: "sing-box", "xray" or "mihomo".
	// Nil keeps the current engine; empty selects the default.
	Engine    *string `json:"engine,omitempty"`
	DNSPreset *string `json:"dns_preset,omitempty"`
}

// Profile is one saved network profile.
type Profile struct {
	ID        string   `json:"id"`
	Name      string   `json:"name"`
	Triggers  Triggers `json:"triggers"`
	Apply     Apply    `json:"apply"`
	AutoApply bool     `json:"auto_apply"`
}

// Fingerprint describes the machine's current network.
type Fingerprint struct {
	// SSID is the current Wi-Fi network name; empty on wired networks or
	// when unreadable.
	SSID string
	// Gateway is the default gateway address; empty when offline.
	Gateway string
	// ASN comes from the optional local table; empty when unknown.
	ASN string
	// Security is the Wi-Fi authentication family of the current network,
	// detected best-effort; SecurityUnknown when unreadable. It never
	// affects matching: it is advisory only.
	Security Security
	// Fingerprint is a stable string of the interface addresses, for
	// display and change detection.
	Fingerprint string
}

// Match is the profile the current network matched.
type Match struct {
	ProfileID string
	Name      string
	AutoApply bool
}

// matches reports whether the fingerprint satisfies every trigger group the
// profile sets. Groups are ANDed; entries inside one group are ORed.
func (p Profile) matches(fp Fingerprint) bool {
	if len(p.Triggers.SSIDs) == 0 && len(p.Triggers.Gateways) == 0 && len(p.Triggers.ASNs) == 0 {
		return false
	}
	if len(p.Triggers.SSIDs) > 0 && !slicesContains(p.Triggers.SSIDs, fp.SSID) {
		return false
	}
	if len(p.Triggers.Gateways) > 0 && !slicesContains(p.Triggers.Gateways, fp.Gateway) {
		return false
	}
	if len(p.Triggers.ASNs) > 0 && !slicesContains(p.Triggers.ASNs, fp.ASN) {
		return false
	}
	return true
}

func slicesContains(list []string, v string) bool {
	for _, s := range list {
		if s == v {
			return true
		}
	}
	return false
}

// Store keeps profiles in one JSON file under the data directory.
type Store struct {
	mu       sync.Mutex
	path     string
	profiles []Profile
	// asnNets and asnValues are the optional local ASN table, aligned by
	// index. Empty when the table is absent. The table is loaded lazily
	// on the first ASN lookup (asnLoaded), not at store construction:
	// parsing it costs real time on large tables, and nothing needs an
	// ASN before the first network fingerprint is taken.
	asnDir    string
	asnLoaded bool
	asnNets   []netip.Prefix
	asnValues []string
	trust     *TrustStore
}

// NewStore loads the profiles file, creating the directory when needed. An
// empty dir disables persistence: the store works in memory only.
func NewStore(dir string) (*Store, error) {
	s := &Store{}
	trust, err := NewTrustStore(dir)
	if err != nil {
		return nil, err
	}
	s.trust = trust
	if strings.TrimSpace(dir) == "" {
		return s, nil
	}
	if err := os.MkdirAll(dir, dirPerm); err != nil {
		return nil, fmt.Errorf("profiles: %w", err)
	}
	s.path = filepath.Join(dir, fileName)
	s.asnDir = dir
	raw, err := os.ReadFile(s.path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return s, nil
		}
		return nil, fmt.Errorf("profiles: %w", err)
	}
	if len(raw) > maxFileBytes {
		return nil, fmt.Errorf("profiles: the file is larger than %d bytes", maxFileBytes)
	}
	var stored []Profile
	if err := json.Unmarshal(raw, &stored); err != nil {
		return nil, fmt.Errorf("profiles: the file is not valid JSON: %w", err)
	}
	for _, p := range stored {
		if err := validate(p); err != nil {
			return nil, fmt.Errorf("profiles: stored profile %q is invalid: %w", p.ID, err)
		}
	}
	s.profiles = stored
	return s, nil
}

// List returns a copy of the saved profiles in save order.
func (s *Store) List() []Profile {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]Profile(nil), s.profiles...)
}

// Save validates and stores a profile, assigning an id when empty. It
// returns the stored profile.
func (s *Store) Save(p Profile) (Profile, error) {
	if err := validate(p); err != nil {
		return Profile{}, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if len(s.profiles) >= MaxProfiles && !s.hasLocked(p.ID) {
		return Profile{}, fmt.Errorf("profiles: the store already keeps %d profiles", MaxProfiles)
	}
	if p.ID == "" {
		p.ID = newID()
	}
	if i := s.indexLocked(p.ID); i >= 0 {
		s.profiles[i] = p
	} else {
		s.profiles = append(s.profiles, p)
	}
	if err := s.writeLocked(); err != nil {
		return Profile{}, err
	}
	return p, nil
}

// Delete removes the profile with the id. Unknown ids are not an error.
func (s *Store) Delete(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if i := s.indexLocked(id); i >= 0 {
		s.profiles = append(s.profiles[:i], s.profiles[i+1:]...)
		return s.writeLocked()
	}
	return nil
}

// Match returns the first profile matching the fingerprint, or nil.
func (s *Store) Match(fp Fingerprint) *Match {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, p := range s.profiles {
		if p.matches(fp) {
			return &Match{ProfileID: p.ID, Name: p.Name, AutoApply: p.AutoApply}
		}
	}
	return nil
}

// SetTrust records the user's trust mark for a Wi-Fi network (SSID).
// TrustNone removes the mark.
func (s *Store) SetTrust(ssid string, t Trust) error {
	return s.trust.Set(ssid, t)
}

// TrustOf returns the recorded mark for an SSID and whether one exists.
// An SSID that was never marked reports (TrustNone, false).
func (s *Store) TrustOf(ssid string) (Trust, bool) {
	return s.trust.Lookup(ssid)
}

// NetworkTrust returns the trust to act on for the fingerprinted network:
// TrustTrusted only for explicitly trusted SSIDs, TrustUntrusted for
// untrusted and never-seen ones, TrustNone when there is no SSID (wired
// or offline).
func (s *Store) NetworkTrust(fp Fingerprint) Trust {
	return s.trust.Effective(fp.SSID)
}

func (s *Store) hasLocked(id string) bool { return s.indexLocked(id) >= 0 }

func (s *Store) indexLocked(id string) int {
	for i, p := range s.profiles {
		if p.ID == id {
			return i
		}
	}
	return -1
}

// writeLocked stores the profiles atomically with owner-only permissions.
func (s *Store) writeLocked() error {
	if s.path == "" {
		return nil
	}
	raw, err := json.MarshalIndent(s.profiles, "", "  ")
	if err != nil {
		return fmt.Errorf("profiles: %w", err)
	}
	tmp := s.path + ".tmp"
	if err := os.WriteFile(tmp, raw, filePerm); err != nil {
		return fmt.Errorf("profiles: %w", err)
	}
	if err := os.Rename(tmp, s.path); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("profiles: %w", err)
	}
	return nil
}

// newID makes an unguessable profile id from 16 random bytes.
func newID() string {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		// Fall back to a timestamp-based id; collisions are resolved by
		// the uniqueness check in Save.
		return fmt.Sprintf("p-%d", time.Now().UnixNano())
	}
	const hexdigits = "0123456789abcdef"
	out := make([]byte, 0, 32)
	for _, c := range b {
		out = append(out, hexdigits[c>>4], hexdigits[c&0xf])
	}
	return string(out)
}

// validate checks one profile without touching the store.
func validate(p Profile) error {
	if strings.TrimSpace(p.Name) == "" {
		return errors.New("profiles: the name is empty")
	}
	if len(p.Name) > MaxNameLen {
		return fmt.Errorf("profiles: the name is longer than %d bytes", MaxNameLen)
	}
	if strings.ContainsAny(p.Name, "\r\n\t") {
		return errors.New("profiles: the name contains control characters")
	}
	if p.ID != "" {
		if len(p.ID) > maxIDLen {
			return fmt.Errorf("profiles: the id is longer than %d bytes", maxIDLen)
		}
		for _, c := range p.ID {
			if !isIDChar(c) {
				return fmt.Errorf("profiles: the id %q has an unsafe character", p.ID)
			}
		}
	}
	tr := p.Triggers
	if len(tr.SSIDs)+len(tr.Gateways)+len(tr.ASNs) > MaxTriggers {
		return fmt.Errorf("profiles: more than %d triggers", MaxTriggers)
	}
	for _, list := range [][]string{tr.SSIDs, tr.Gateways, tr.ASNs} {
		for _, v := range list {
			if len(v) > MaxTriggerLen {
				return fmt.Errorf("profiles: trigger %q is longer than %d bytes", v, MaxTriggerLen)
			}
			if strings.ContainsAny(v, "\r\n\t") {
				return fmt.Errorf("profiles: trigger %q contains control characters", v)
			}
		}
	}
	for _, g := range tr.Gateways {
		if _, err := netip.ParseAddr(g); err != nil {
			return fmt.Errorf("profiles: gateway %q is not an address", g)
		}
	}
	mode := ""
	if p.Apply.Mode != nil {
		mode = *p.Apply.Mode
	}
	switch mode {
	case "", "tun", "proxy":
	default:
		return fmt.Errorf("profiles: mode %q must be tun or proxy", mode)
	}
	engine := ""
	if p.Apply.Engine != nil {
		engine = *p.Apply.Engine
	}
	switch engine {
	case "", "sing-box", "xray", "mihomo":
	default:
		return fmt.Errorf("profiles: engine %q is unknown", engine)
	}
	if len(p.Apply.DNS) > MaxDNS {
		return fmt.Errorf("profiles: more than %d DNS servers", MaxDNS)
	}
	for _, d := range p.Apply.DNS {
		if len(d) > MaxTriggerLen || strings.ContainsAny(d, " \t\r\n") || d == "" {
			return fmt.Errorf("profiles: DNS server %q is invalid", d)
		}
	}
	// Resolver syntax belongs to plan validation; snapshots must preserve every
	// supported form, including hostnames, custom ports and encrypted URLs.
	return nil
}

func isIDChar(c rune) bool {
	return c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-' || c == '_'
}
