package control

import (
	"context"
	"encoding/json"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/hwid"
)

// deviceIdentityRef names the vault entry holding the device identity choice.
// It stays out of subscription references, so deleting subscriptions keeps it.
const deviceIdentityRef = "device_identity_v1"

// deviceIdentityRecord is stored only when it differs from the default: on,
// and derived from the machine id.
type deviceIdentityRecord struct {
	Version int  `json:"v"`
	Off     bool `json:"off,omitempty"`
	// ID replaces the derived identifier after a reset, or where the machine
	// has no readable id.
	ID string `json:"id,omitempty"`
}

// deviceIdentity caches the record; the vault is read once per core run.
type deviceIdentity struct {
	mu     sync.Mutex
	loaded bool
	rec    deviceIdentityRecord
}

// loadDeviceIdentityLocked reads the stored choice and settles the identifier.
// The caller holds s.device.mu. A machine
// without a readable id gets a random identifier stored once, so it stays the
// same across restarts.
func (s *Server) loadDeviceIdentityLocked() (deviceIdentityRecord, string, error) {
	d := &s.device
	if !d.loaded {
		rec := deviceIdentityRecord{Version: 1}
		if s.secrets != nil {
			raw, err := s.secrets.Get(deviceIdentityRef)
			switch {
			case err == nil:
				if json.Unmarshal(raw, &rec) != nil || (rec.ID != "" && !hwid.Valid(rec.ID)) {
					rec = deviceIdentityRecord{Version: 1}
				}
			case !isMissingSecret(err):
				return deviceIdentityRecord{}, "", err
			}
		}
		d.rec, d.loaded = rec, true
	}
	if d.rec.ID != "" {
		return d.rec, d.rec.ID, nil
	}
	if id, err := hwid.Machine(); err == nil {
		return d.rec, id, nil
	}
	id, err := hwid.Random()
	if err != nil {
		return deviceIdentityRecord{}, "", errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	next := d.rec
	next.ID = id
	if err := s.storeDeviceIdentityLocked(next); err != nil {
		return deviceIdentityRecord{}, "", err
	}
	return next, id, nil
}

func (s *Server) storeDeviceIdentityLocked(rec deviceIdentityRecord) error {
	if s.secrets != nil {
		if !rec.Off && rec.ID == "" {
			if err := s.secrets.Delete(deviceIdentityRef); err != nil && !isMissingSecret(err) {
				return err
			}
		} else {
			raw, err := json.Marshal(rec)
			if err != nil {
				return errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
			}
			if err := s.secrets.Put(deviceIdentityRef, raw); err != nil {
				return err
			}
		}
	}
	s.device.rec = rec
	return nil
}

func isMissingSecret(err error) bool { return errs.KeyOf(err) == errs.KeySecretNotFound }

// subscriptionDevice is what a saved subscription sends, or nil when the user
// turned the identifier off for this provider or everywhere. A failure to read
// the identifier sends none rather than failing the update.
func (s *Server) subscriptionDevice(off bool) *hwid.Identity {
	if off {
		return nil
	}
	s.device.mu.Lock()
	defer s.device.mu.Unlock()
	rec, id, err := s.loadDeviceIdentityLocked()
	if err != nil || rec.Off {
		return nil
	}
	identity := hwid.For(id)
	return &identity
}

func (s *Server) deviceIdentityState() (*corev1.DeviceIdentity, error) {
	rec, id, err := s.loadDeviceIdentityLocked()
	if err != nil {
		return nil, err
	}
	identity := hwid.For(id)
	return &corev1.DeviceIdentity{
		Hwid: id, Enabled: !rec.Off, Os: identity.OS, OsVersion: identity.OSVersion, Model: identity.Model,
	}, nil
}

// GetDeviceIdentity returns the identifier saved subscriptions send.
func (s *Server) GetDeviceIdentity(_ context.Context, req *corev1.GetDeviceIdentityRequest) (*corev1.GetDeviceIdentityResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	s.device.mu.Lock()
	defer s.device.mu.Unlock()
	state, err := s.deviceIdentityState()
	if err != nil {
		return &corev1.GetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
	}
	return &corev1.GetDeviceIdentityResponse{Identity: state}, nil
}

// SetDeviceIdentity turns the identifier on or off everywhere, or replaces it.
func (s *Server) SetDeviceIdentity(_ context.Context, req *corev1.SetDeviceIdentityRequest) (*corev1.SetDeviceIdentityResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	fail := func(err error) (*corev1.SetDeviceIdentityResponse, error) {
		return &corev1.SetDeviceIdentityResponse{Error: toWire(err, nil, "")}, nil
	}
	if s.secrets == nil {
		return fail(errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
			"control: this core cannot store the device identity"))
	}
	s.device.mu.Lock()
	defer s.device.mu.Unlock()
	rec, _, err := s.loadDeviceIdentityLocked()
	if err != nil {
		return fail(err)
	}
	rec.Off = !req.GetEnabled()
	if req.GetRegenerate() {
		if rec.ID, err = hwid.Random(); err != nil {
			return fail(errs.Wrap(err, errs.CodeInternal, errs.KeyInternal))
		}
	}
	if err := s.storeDeviceIdentityLocked(rec); err != nil {
		return fail(err)
	}
	state, err := s.deviceIdentityState()
	if err != nil {
		return fail(err)
	}
	return &corev1.SetDeviceIdentityResponse{Identity: state}, nil
}
