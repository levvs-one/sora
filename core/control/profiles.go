package control

// Network profiles. The core stores profiles, fingerprints the current
// network, and reports a ProfileMatched event when a saved profile matches
// after a network change. The client applies the profile by rebuilding the
// session plan from its apply settings.

import (
	"context"
	"slices"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/profiles"
)

// profileStore returns the profile store, or an explicit error when profiles
// are not configured (no data directory).
func (s *Server) profileStore() (*profiles.Store, error) {
	if s.profiles == nil {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyInternal,
			"control: network profiles are not configured")
	}
	return s.profiles, nil
}

// ListProfiles returns the saved network profiles in save order.
func (s *Server) ListProfiles(_ context.Context, req *corev1.ListProfilesRequest) (*corev1.ListProfilesResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	store, err := s.profileStore()
	if err != nil {
		return &corev1.ListProfilesResponse{Error: toWire(err, nil, "")}, nil
	}
	out := &corev1.ListProfilesResponse{}
	for _, p := range store.List() {
		out.Profiles = append(out.Profiles, profileToWire(p))
	}
	return out, nil
}

// SaveProfile validates and stores a profile, assigning an id when empty.
func (s *Server) SaveProfile(_ context.Context, req *corev1.SaveProfileRequest) (*corev1.SaveProfileResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	store, err := s.profileStore()
	if err != nil {
		return &corev1.SaveProfileResponse{Error: toWire(err, nil, "")}, nil
	}
	in := req.GetProfile()
	if in == nil {
		err := errs.Newf(errs.CodeInvalidArgument, errs.KeyInternal,
			"control: the request carries no profile")
		return &corev1.SaveProfileResponse{Error: toWire(err, nil, "")}, nil
	}
	saved, err := store.Save(profileFromWire(in))
	if err != nil {
		cerr := errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyInternal)
		return &corev1.SaveProfileResponse{Error: toWire(cerr, nil, "")}, nil
	}
	return &corev1.SaveProfileResponse{Profile: profileToWire(saved)}, nil
}

// DeleteProfile removes a profile. Unknown ids are not an error.
func (s *Server) DeleteProfile(_ context.Context, req *corev1.DeleteProfileRequest) (*corev1.DeleteProfileResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	store, err := s.profileStore()
	if err != nil {
		return &corev1.DeleteProfileResponse{Error: toWire(err, nil, "")}, nil
	}
	if err := store.Delete(req.GetProfileId()); err != nil {
		cerr := errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
		return &corev1.DeleteProfileResponse{Error: toWire(cerr, nil, "")}, nil
	}
	return &corev1.DeleteProfileResponse{}, nil
}

// GetNetworkFingerprint returns the machine's current network fingerprint for
// profile editing. It needs the control authenticator: the answer describes
// the machine's network.
func (s *Server) GetNetworkFingerprint(_ context.Context, req *corev1.GetNetworkFingerprintRequest) (*corev1.GetNetworkFingerprintResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	fp := profiles.Current()
	if s.profiles != nil {
		fp.ASN = s.profiles.Fingerprint().ASN
	}
	return &corev1.GetNetworkFingerprintResponse{
		Fingerprint: &corev1.NetworkFingerprint{
			Ssid:        fp.SSID,
			Gateway:     fp.Gateway,
			Asn:         fp.ASN,
			Fingerprint: fp.Fingerprint,
		},
	}, nil
}

// profileToWire converts a stored profile to the contract.
func profileToWire(p profiles.Profile) *corev1.NetworkProfile {
	return &corev1.NetworkProfile{
		Id:   p.ID,
		Name: p.Name,
		Triggers: &corev1.ProfileTriggers{
			Ssids:    append([]string(nil), p.Triggers.SSIDs...),
			Gateways: append([]string(nil), p.Triggers.Gateways...),
			Asns:     append([]string(nil), p.Triggers.ASNs...),
		},
		Apply: &corev1.ProfileApply{
			Mode:        p.Apply.Mode,
			Dns:         slices.Clone(p.Apply.DNS),
			RulesPreset: p.Apply.RulesPreset,
			ServerId:    p.Apply.ServerID,
			Engine:      p.Apply.Engine,
			DnsPreset:   p.Apply.DNSPreset,
			DnsSet:      p.Apply.DNS != nil,
		},
		AutoApply: p.AutoApply,
	}
}

// profileFromWire converts the contract to a stored profile. Validation
// happens in Store.Save.
func profileFromWire(in *corev1.NetworkProfile) profiles.Profile {
	p := profiles.Profile{ID: in.GetId(), Name: in.GetName(), AutoApply: in.GetAutoApply()}
	if t := in.GetTriggers(); t != nil {
		p.Triggers = profiles.Triggers{
			SSIDs:    append([]string(nil), t.GetSsids()...),
			Gateways: append([]string(nil), t.GetGateways()...),
			ASNs:     append([]string(nil), t.GetAsns()...),
		}
	}
	if a := in.GetApply(); a != nil {
		p.Apply = profiles.Apply{
			Mode:        a.Mode,
			DNS:         slices.Clone(a.GetDns()),
			RulesPreset: a.RulesPreset,
			ServerID:    a.ServerId,
			Engine:      a.Engine,
			DNSPreset:   a.DnsPreset,
		}
		if a.GetDnsSet() && p.Apply.DNS == nil {
			p.Apply.DNS = []string{}
		}
	}
	return p
}
