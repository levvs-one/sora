package subscription

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

// Device identity storage (C1).
//
// The HWID lives in the core, not in the interface, for one structural
// reason: subscription refreshes — the scheduled auto-updates included
// — run inside the core while the interface is closed, and there is no
// channel for the interface to hand a value to those fetches. A
// Dart-side HWID would silently stop being sent exactly when the user
// is not looking, and a limited provider would start answering 404.
//
// It is also deliberately NOT the interface's installUuid: that value
// is the staged-rollout cohort key, documented as "not a security
// token", and reusing it would weld two unrelated lifecycles together
// (resetting the provider device would reshuffle the update cohort).
//
// The file sits in the owner-only core data directory beside the
// subscription overrides, is written atomically with 0600
// permissions, and its content is never logged.

// deviceRecord is the stored form. Enabled defaults to true: a record
// that predates the field, or a missing record, means the identity is
// sent — otherwise the feature is dead at exactly the providers that
// require it. The user-facing switch writes false explicitly. The
// default is presence-aware (see deviceRecordFile): a plain bool
// would decode a missing field as false and silently opt every
// legacy install out.
//
// VerOS and DeviceModel are the companion platform facts the
// interface supplies through SetDeviceIdentity (contract 1.13): the
// core has no honest source for them itself, so they live here,
// beside the identity they decorate, and Headers fills them in.
// Empty means the platform did not provide the fact; the header is
// then omitted, never fabricated.
type deviceRecord struct {
	HWID        string `json:"hwid"`
	Enabled     bool   `json:"enabled"`
	VerOS       string `json:"ver_os,omitempty"`
	DeviceModel string `json:"device_model,omitempty"`
}

// deviceRecordFile is the decoding form of deviceRecord: Enabled is a
// pointer so loadLocked can tell an explicit false (the user's
// opt-out) from a field the file predates (which means true).
type deviceRecordFile struct {
	HWID        string `json:"hwid"`
	Enabled     *bool  `json:"enabled"`
	VerOS       string `json:"ver_os"`
	DeviceModel string `json:"device_model"`
}

// DeviceStore persists the per-install device identity under
// <dir>/device.json. A nil store (empty data dir) disables the
// identity: every method is safe to call on it and Headers reports
// the zero set, so tests and headless cores send nothing.
type DeviceStore struct {
	dir string
	mu  sync.Mutex
}

// NewDeviceStore creates the store; dir is the core data directory.
// An empty dir yields a nil store (identity disabled).
func NewDeviceStore(dir string) *DeviceStore {
	if dir == "" {
		return nil
	}
	return &DeviceStore{dir: dir}
}

func (s *DeviceStore) path() string { return filepath.Join(s.dir, "device.json") }

// loadLocked reads the record. A missing file yields the zero record.
// A corrupt file is an error the caller must surface without the file
// content: silently regenerating would register a "new device" at
// every limited provider without the user ever choosing a reset.
func (s *DeviceStore) loadLocked() (deviceRecord, error) {
	raw, err := os.ReadFile(s.path())
	if err != nil {
		if os.IsNotExist(err) {
			return deviceRecord{Enabled: true}, nil
		}
		return deviceRecord{}, err
	}
	var file deviceRecordFile
	if err := json.Unmarshal(raw, &file); err != nil {
		return deviceRecord{}, errors.New("subscription: device identity file is corrupt")
	}
	rec := deviceRecord{
		HWID:        file.HWID,
		Enabled:     true, // a record that predates the field means true
		VerOS:       file.VerOS,
		DeviceModel: file.DeviceModel,
	}
	if file.Enabled != nil {
		rec.Enabled = *file.Enabled
	}
	if rec.HWID != "" && !ValidHWID(rec.HWID) {
		return deviceRecord{}, errors.New("subscription: stored device identifier is not valid")
	}
	return rec, nil
}

// saveLocked writes the record atomically, following the override
// store's pattern (0600 temp file + rename, 0700 directory).
func (s *DeviceStore) saveLocked(rec deviceRecord) error {
	if err := os.MkdirAll(s.dir, 0o700); err != nil {
		return err
	}
	raw, err := json.Marshal(rec)
	if err != nil {
		return err
	}
	tmp := s.path() + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, s.path())
}

// identityLocked returns the record, generating and persisting the
// HWID on first use.
func (s *DeviceStore) identityLocked() (deviceRecord, error) {
	rec, err := s.loadLocked()
	if err != nil {
		return deviceRecord{}, err
	}
	if rec.HWID == "" {
		hwid, err := GenerateHWID()
		if err != nil {
			return deviceRecord{}, err
		}
		rec.HWID = hwid
		if err := s.saveLocked(rec); err != nil {
			return deviceRecord{}, err
		}
	}
	return rec, nil
}

// HWID returns the stable per-install identifier, generating it on
// first use. It exists for the settings surface (show / reset); the
// fetch path uses Headers instead so the opt-out is honoured in
// exactly one place.
func (s *DeviceStore) HWID() (string, error) {
	if s == nil {
		return "", errors.New("subscription: device identity store disabled")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	rec, err := s.identityLocked()
	if err != nil {
		return "", err
	}
	return rec.HWID, nil
}

// Enabled reports whether the user lets subscription fetches carry
// the device identity. Default (no record yet) is true.
func (s *DeviceStore) Enabled() (bool, error) {
	if s == nil {
		return false, nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	rec, err := s.loadLocked()
	if err != nil {
		return false, err
	}
	return rec.Enabled, nil
}

// SetEnabled records the opt-out choice, generating the identity
// first if needed so enabling later does not change it.
func (s *DeviceStore) SetEnabled(enabled bool) error {
	if s == nil {
		return errors.New("subscription: device identity store disabled")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	rec, err := s.identityLocked()
	if err != nil {
		return err
	}
	rec.Enabled = enabled
	return s.saveLocked(rec)
}

// SetPlatform records the companion platform facts the interface
// supplied (contract 1.13): the OS version and the device model, each
// possibly empty when the platform does not honestly provide it. The
// values are validated with the same rules the fetch path applies, so
// a value the store accepted can never fail a later fetch. The
// identity itself is generated first if needed, exactly as in
// SetEnabled, so storing companions never changes it.
func (s *DeviceStore) SetPlatform(verOS, deviceModel string) error {
	if s == nil {
		return errors.New("subscription: device identity store disabled")
	}
	verOS, deviceModel = strings.TrimSpace(verOS), strings.TrimSpace(deviceModel)
	if err := checkDeviceField(verOS); err != nil {
		return err
	}
	if err := checkDeviceField(deviceModel); err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	rec, err := s.identityLocked()
	if err != nil {
		return err
	}
	rec.VerOS, rec.DeviceModel = verOS, deviceModel
	return s.saveLocked(rec)
}

// Reset replaces the HWID with a fresh one. Providers count the new
// value as a new device; the old value is gone, not archived.
func (s *DeviceStore) Reset() (string, error) {
	if s == nil {
		return "", errors.New("subscription: device identity store disabled")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	rec, err := s.identityLocked()
	if err != nil {
		return "", err
	}
	hwid, err := GenerateHWID()
	if err != nil {
		return "", err
	}
	rec.HWID = hwid
	if err := s.saveLocked(rec); err != nil {
		return "", err
	}
	return rec.HWID, nil
}

// Headers returns the device header set for one subscription fetch,
// with the platform facts the caller honestly knows filled in by the
// caller. The opt-out collapses to the zero set here: when the user
// disabled the identity, nothing — not even the companion fields — is
// sent.
func (s *DeviceStore) Headers(deviceOS string) (DeviceHeaders, error) {
	if s == nil {
		return DeviceHeaders{}, nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	rec, err := s.identityLocked()
	if err != nil {
		return DeviceHeaders{}, err
	}
	if !rec.Enabled {
		return DeviceHeaders{}, nil
	}
	return DeviceHeaders{
		HWID:        rec.HWID,
		DeviceOS:    deviceOS,
		VersionOS:   rec.VerOS,
		DeviceModel: rec.DeviceModel,
	}, nil
}
