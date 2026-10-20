package control

// Obfuscation suite: control-plane handlers for sora.obfs.v1.ObfsControl.
//
// The core keeps one active ObfuscationProfile. ApplyObfsProfile validates
// it against what the installed engines really support (the matrix below
// is read from the renderers in core/engine, not from documentation),
// stores it, and reports which engines can carry it. Every later Connect
// merges the stored profile into the engine plan via MergeObfsProfile.
//
// Seam for the suite: core/obfs (engine-config rendering) consumes
// engine.Plan, and MergeObfsProfile is the single place that maps a
// profile onto that plan. Nothing else in the control plane touches
// obfuscation fields.

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"sort"
	"strings"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
)

// engineObfsCaps is what one engine really supports, verified against its
// renderer: sing-box in core/engine/singbox/render.go (utls + a bare
// fragment switch), Xray in core/engine/xray/render.go (utls, fragment
// outbound with packets/length/interval), mihomo in
// core/engine/mihomo/proxy.go (client-fingerprint and SNI only).
type engineObfsCaps struct {
	engine           string
	utls             bool
	utlsProfiles     []string
	versionedParrots bool
	fragmentation    bool
	fragmentParams   bool
	jitter           bool
	fakeSNI          bool
}

// obfsEngineCapabilities is the honest per-engine matrix. Jitter means the
// engine randomizes the inter-fragment pause: Xray does it inside its
// interval range, sing-box has no pause knob at all, mihomo cannot
// fragment. Fake SNI rides the existing server-name field on all three,
// which is why it needs the caller to know the server tolerates it.
var obfsEngineCapabilities = []engineObfsCaps{
	{
		engine:           "sing-box",
		utls:             true,
		utlsProfiles:     []string{"chrome", "firefox", "edge", "safari", "ios", "android", "360", "qq", "random", "randomized"},
		versionedParrots: false,
		fragmentation:    true,
		fragmentParams:   false,
		jitter:           false,
		fakeSNI:          true,
	},
	{
		engine:           "xray",
		utls:             true,
		utlsProfiles:     []string{"chrome", "firefox", "edge", "safari", "ios", "android", "360", "qq", "random", "randomized"},
		versionedParrots: true,
		fragmentation:    true,
		fragmentParams:   true,
		jitter:           true,
		fakeSNI:          true,
	},
	{
		engine:           "mihomo",
		utls:             true,
		utlsProfiles:     []string{"chrome", "firefox", "safari", "ios", "android", "edge", "360", "qq", "random"},
		versionedParrots: false,
		fragmentation:    false,
		fragmentParams:   false,
		jitter:           false,
		fakeSNI:          true,
	},
}

// utlsCanonicalName maps the wire enum to the fingerprint name the engines
// accept. Empty means UNSPECIFIED: keep the subscription/engine default.
func utlsCanonicalName(p obfsv1.UtlsProfile) string {
	switch p {
	case obfsv1.UtlsProfile_UTLS_PROFILE_CHROME:
		return "chrome"
	case obfsv1.UtlsProfile_UTLS_PROFILE_FIREFOX:
		return "firefox"
	case obfsv1.UtlsProfile_UTLS_PROFILE_SAFARI:
		return "safari"
	case obfsv1.UtlsProfile_UTLS_PROFILE_IOS:
		return "ios"
	case obfsv1.UtlsProfile_UTLS_PROFILE_ANDROID:
		return "android"
	case obfsv1.UtlsProfile_UTLS_PROFILE_EDGE:
		return "edge"
	case obfsv1.UtlsProfile_UTLS_PROFILE_360:
		return "360"
	case obfsv1.UtlsProfile_UTLS_PROFILE_QQ:
		return "qq"
	case obfsv1.UtlsProfile_UTLS_PROFILE_RANDOM:
		return "random"
	case obfsv1.UtlsProfile_UTLS_PROFILE_RANDOMIZED:
		return "randomized"
	default:
		return ""
	}
}

// obfsPresetDefaults expands a preset into field values. Explicit fields
// always win over these; an explicit zero cannot clear a preset's non-zero
// (use UNSPECIFIED for a fully custom profile).
func obfsPresetDefaults(preset obfsv1.ObfsPreset) *obfsv1.ObfuscationProfile {
	switch preset {
	case obfsv1.ObfsPreset_OBFS_PRESET_LIGHT:
		return &obfsv1.ObfuscationProfile{
			Preset:      preset,
			UtlsProfile: obfsv1.UtlsProfile_UTLS_PROFILE_CHROME,
			FragSizes:   []uint32{200},
		}
	case obfsv1.ObfsPreset_OBFS_PRESET_BALANCED:
		return &obfsv1.ObfuscationProfile{
			Preset:      preset,
			UtlsProfile: obfsv1.UtlsProfile_UTLS_PROFILE_CHROME,
			FragSizes:   []uint32{100, 300},
			FragDelayMs: 10,
			JitterMs:    10,
		}
	case obfsv1.ObfsPreset_OBFS_PRESET_AGGRESSIVE:
		return &obfsv1.ObfuscationProfile{
			Preset:      preset,
			UtlsProfile: obfsv1.UtlsProfile_UTLS_PROFILE_RANDOMIZED,
			FragSizes:   []uint32{50, 150},
			FragDelayMs: 20,
			JitterMs:    30,
		}
	default:
		return &obfsv1.ObfuscationProfile{Preset: preset}
	}
}

const (
	maxFragSizes = 16
	maxFragSize  = 16384 // TLS records never exceed this; larger is meaningless.
	maxDelayMs   = 10000 // Beyond 10s the handshake stalls instead of hiding.
)

// fakeSNIPattern accepts dotted hostnames: labels of letters, digits and
// hyphens, 1..63 chars each, 253 total.
var fakeSNIPattern = regexp.MustCompile(`^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)*[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$`)

func invalidObfs(format string, args ...any) error {
	return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest, "control: obfuscation: "+format, args...)
}

// normalizeObfsProfile validates the profile and expands its preset.
// Explicit fields override the preset; OFF must arrive alone and clears
// the suite. It returns the profile as stored.
func normalizeObfsProfile(p *obfsv1.ObfuscationProfile) (*obfsv1.ObfuscationProfile, error) {
	if p == nil {
		return nil, invalidObfs("the request carries no profile")
	}
	switch p.GetPreset() {
	case obfsv1.ObfsPreset_OBFS_PRESET_UNSPECIFIED,
		obfsv1.ObfsPreset_OBFS_PRESET_OFF,
		obfsv1.ObfsPreset_OBFS_PRESET_LIGHT,
		obfsv1.ObfsPreset_OBFS_PRESET_BALANCED,
		obfsv1.ObfsPreset_OBFS_PRESET_AGGRESSIVE:
	default:
		return nil, invalidObfs("unknown preset %d", int32(p.GetPreset()))
	}
	if _, ok := obfsv1.UtlsProfile_name[int32(p.GetUtlsProfile())]; !ok {
		return nil, invalidObfs("unknown uTLS profile %d", int32(p.GetUtlsProfile()))
	}
	if p.GetPreset() == obfsv1.ObfsPreset_OBFS_PRESET_OFF {
		if p.GetUtlsProfile() != obfsv1.UtlsProfile_UTLS_PROFILE_UNSPECIFIED ||
			len(p.GetFragSizes()) > 0 || p.GetFragDelayMs() > 0 ||
			p.GetJitterMs() > 0 || p.GetFakeSni() != "" || p.GetMuxDisabled() {
			return nil, invalidObfs("preset OFF contradicts the other fields; send OFF alone to disable")
		}
		return &obfsv1.ObfuscationProfile{Preset: obfsv1.ObfsPreset_OBFS_PRESET_OFF}, nil
	}
	out := obfsPresetDefaults(p.GetPreset())
	// No preset sets mux_disabled: it is an explicit-only opt-out of the
	// REALITY mux default, carried through verbatim.
	out.MuxDisabled = p.GetMuxDisabled()
	if u := p.GetUtlsProfile(); u != obfsv1.UtlsProfile_UTLS_PROFILE_UNSPECIFIED {
		out.UtlsProfile = u
	}
	if len(p.GetFragSizes()) > 0 {
		if len(p.GetFragSizes()) > maxFragSizes {
			return nil, invalidObfs("frag_sizes carries %d entries, the limit is %d", len(p.GetFragSizes()), maxFragSizes)
		}
		for _, s := range p.GetFragSizes() {
			if s < 1 || s > maxFragSize {
				return nil, invalidObfs("fragment size %d is outside 1..%d", s, maxFragSize)
			}
		}
		out.FragSizes = append([]uint32(nil), p.GetFragSizes()...)
	}
	if d := p.GetFragDelayMs(); d > 0 {
		if d > maxDelayMs {
			return nil, invalidObfs("frag_delay_ms %d exceeds %d", d, maxDelayMs)
		}
		out.FragDelayMs = d
	}
	if j := p.GetJitterMs(); j > 0 {
		if j > maxDelayMs {
			return nil, invalidObfs("jitter_ms %d exceeds %d", j, maxDelayMs)
		}
		out.JitterMs = j
	}
	if len(out.GetFragSizes()) == 0 && (out.GetFragDelayMs() > 0 || out.GetJitterMs() > 0) {
		return nil, invalidObfs("frag_delay_ms/jitter_ms need frag_sizes: a pause without fragments does nothing")
	}
	if out.GetJitterMs() > 0 && out.GetFragDelayMs() == 0 {
		return nil, invalidObfs("jitter_ms needs frag_delay_ms: jitter without a base pause does nothing")
	}
	if sni := p.GetFakeSni(); sni != "" {
		if len(sni) > 253 || !fakeSNIPattern.MatchString(sni) {
			return nil, invalidObfs("fake_sni %q is not a valid hostname", sni)
		}
		out.FakeSni = sni
	}
	if out.GetPreset() == obfsv1.ObfsPreset_OBFS_PRESET_UNSPECIFIED &&
		out.GetUtlsProfile() == obfsv1.UtlsProfile_UTLS_PROFILE_UNSPECIFIED &&
		len(out.GetFragSizes()) == 0 && out.GetFakeSni() == "" && !out.GetMuxDisabled() {
		return nil, invalidObfs("the profile is empty: pick a preset or set a field")
	}
	return out, nil
}

// obfsEnabled reports whether the normalized profile changes anything on
// the wire.
func obfsEnabled(p *obfsv1.ObfuscationProfile) bool {
	return p != nil && p.GetPreset() != obfsv1.ObfsPreset_OBFS_PRESET_OFF &&
		(p.GetUtlsProfile() != obfsv1.UtlsProfile_UTLS_PROFILE_UNSPECIFIED ||
			len(p.GetFragSizes()) > 0 || p.GetFakeSni() != "" || p.GetMuxDisabled())
}

// obfsFeatureUse summarizes which features the profile enables, for the
// compatibility check.
type obfsFeatureUse struct {
	utls          string // canonical name, "" when unset
	fragmentation bool
	delay         bool
	jitter        bool
	fakeSNI       bool
}

func obfsFeatures(p *obfsv1.ObfuscationProfile) obfsFeatureUse {
	return obfsFeatureUse{
		utls:          utlsCanonicalName(p.GetUtlsProfile()),
		fragmentation: len(p.GetFragSizes()) > 0,
		delay:         p.GetFragDelayMs() > 0,
		jitter:        p.GetJitterMs() > 0,
		fakeSNI:       p.GetFakeSni() != "",
	}
}

// obfsMissingFeatures lists the profile features one engine cannot carry,
// using the feature names clients see in warnings.
func obfsMissingFeatures(caps engineObfsCaps, use obfsFeatureUse) []string {
	var missing []string
	if use.utls != "" {
		if !caps.utls {
			missing = append(missing, "uTLS")
		} else if !slices.Contains(caps.utlsProfiles, use.utls) {
			missing = append(missing, "uTLS profile "+use.utls)
		}
	}
	if use.fragmentation && !caps.fragmentation {
		missing = append(missing, "TLS fragmentation")
	}
	if use.delay && !caps.fragmentParams {
		missing = append(missing, "fragment delay")
	}
	if use.jitter && !caps.jitter {
		missing = append(missing, "fragment jitter")
	}
	if use.fakeSNI && !caps.fakeSNI {
		missing = append(missing, "decoy SNI")
	}
	return missing
}

// obfsCompatibleEngines lists the engines able to carry every feature the
// profile enables, with a warning per engine that cannot.
//
// This is the apply-time view. Engine selection at Connect time
// (SelectEngine) is obfuscation-blind — it picks the first preferred
// engine that carries the plan — so a pinned engine can still silently
// drop profile features; obfsEnginePreferenceWarning reconciles that at
// Connect.
func obfsCompatibleEngines(p *obfsv1.ObfuscationProfile) (compatible []string, warnings []string) {
	use := obfsFeatures(p)
	for _, caps := range obfsEngineCapabilities {
		if missing := obfsMissingFeatures(caps, use); len(missing) == 0 {
			compatible = append(compatible, caps.engine)
		} else {
			warnings = append(warnings, caps.engine+": drops "+strings.Join(missing, ", "))
		}
	}
	sort.Strings(compatible)
	if use.fakeSNI {
		warnings = append(warnings,
			"fake_sni replaces the handshake SNI: use it only against servers that do not validate SNI; REALITY outbounds are skipped")
	}
	return compatible, warnings
}

// obfsEnginePreferenceWarning reconciles the stored profile with the
// session's engine preference at Connect time. A pinned engine that cannot
// carry the profile's features would silently drop them: the merge stamps
// the features onto the plan, SelectEngine never looks at them, and the
// apply-time compatible_engines report is long forgotten by the client.
// An empty preference means the core default order, whose graceful
// degradation is documented in the proto, so only an explicit pin warns.
func obfsEnginePreferenceWarning(engines []engine.Kind, p *obfsv1.ObfuscationProfile) string {
	if !obfsEnabled(p) || len(engines) == 0 {
		return ""
	}
	use := obfsFeatures(p)
	for _, caps := range obfsEngineCapabilities {
		if caps.engine != string(engines[0]) {
			continue
		}
		if missing := obfsMissingFeatures(caps, use); len(missing) > 0 {
			return fmt.Sprintf("obfuscation: the preferred engine %q cannot carry %s from the active profile; those defences stay off for this session",
				caps.engine, strings.Join(missing, ", "))
		}
		return ""
	}
	return ""
}

// MergeObfsProfile maps the active obfuscation profile onto the engine
// plan. It is the single place the suite touches plan fields: uTLS goes to
// each TLS outbound's fingerprint (an explicit profile overrides the
// subscription's), fragmentation to the plan options, the decoy SNI to
// each TLS outbound's server name except REALITY ones, where a wrong SNI
// would break the handshake by design, and mux_disabled to the plan's mux
// options — every renderer's REALITY mux goes through engine.RealityMux
// on plan.Options.Mux, so this one stamp honestly disables mux on all
// engines. Nil or disabled profiles are a no-op. The parallel core/obfs
// package consumes engine.Plan, so this is the seam between the control
// plane and the suite's engine rendering.
func MergeObfsProfile(plan *engine.Plan, p *obfsv1.ObfuscationProfile) {
	if plan == nil || !obfsEnabled(p) {
		return
	}
	if p.GetMuxDisabled() {
		plan.Options.Mux.Disabled = true
	}
	if sizes := p.GetFragSizes(); len(sizes) > 0 {
		min, max := sizes[0], sizes[0]
		for _, s := range sizes[1:] {
			if s < min {
				min = s
			}
			if s > max {
				max = s
			}
		}
		plan.Options.Fragment.Enabled = true
		// Xray grammar is a range; sing-box uses only the switch.
		plan.Options.Fragment.Length = fmt.Sprintf("%d-%d", min, max)
		if d := p.GetFragDelayMs(); d > 0 {
			plan.Options.Fragment.Interval = fmt.Sprintf("%d-%d", d, d+p.GetJitterMs())
		}
	}
	fingerprint := utlsCanonicalName(p.GetUtlsProfile())
	fakeSNI := p.GetFakeSni()
	if fingerprint == "" && fakeSNI == "" {
		return
	}
	for i := range plan.Outbounds {
		o := &plan.Outbounds[i]
		if !o.TLS.Enabled {
			continue
		}
		if fingerprint != "" {
			o.TLS.Fingerprint = fingerprint
		}
		if fakeSNI != "" && !o.TLS.Reality {
			o.TLS.ServerName = fakeSNI
		}
	}
}

// ApplyObfsProfile validates the profile, expands its preset, stores it
// as the active profile and reports which engines can carry it. The stored
// profile merges into every later Connect; preset OFF clears it.
func (s *Server) ApplyObfsProfile(_ context.Context, req *obfsv1.ApplyObfsProfileRequest) (*obfsv1.ApplyObfsProfileResponse, error) {
	id := requestID("")
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	normalized, err := normalizeObfsProfile(req.GetProfile())
	if err != nil {
		return &obfsv1.ApplyObfsProfileResponse{Error: toWire(err, nil, id)}, nil
	}
	// OFF disables the suite: there is nothing to be compatible with.
	var compatible []string
	var warnings []string
	if obfsEnabled(normalized) {
		compatible, warnings = obfsCompatibleEngines(normalized)
		if len(compatible) == 0 {
			err := invalidObfs("no installed engine can carry this profile")
			return &obfsv1.ApplyObfsProfileResponse{Error: toWire(err, nil, id)}, nil
		}
	}
	// The mutex covers the file write too: two racing Apply calls must not
	// leave the persisted file holding a different profile than the memory.
	s.obfsMu.Lock()
	defer s.obfsMu.Unlock()
	if err := s.saveObfsProfile(normalized); err != nil {
		err = errs.Newf(errs.CodeInternal, errs.KeyInternal, "control: obfuscation: cannot persist the profile: %v", err)
		return &obfsv1.ApplyObfsProfileResponse{Error: toWire(err, nil, id)}, nil
	}
	s.obfs = normalized
	// A freshly applied profile replaces whatever the startup file held:
	// a corrupt-file warning from NewServer no longer describes reality.
	s.obfsLoadWarning = ""
	return &obfsv1.ApplyObfsProfileResponse{
		Applied:           proto.Clone(normalized).(*obfsv1.ObfuscationProfile),
		CompatibleEngines: compatible,
		Warnings:          warnings,
	}, nil
}

// GetObfsCapabilities reports what each installed engine really supports.
// It carries no personal data, so any admitted peer may call it.
func (s *Server) GetObfsCapabilities(_ context.Context, req *obfsv1.GetObfsCapabilitiesRequest) (*obfsv1.GetObfsCapabilitiesResponse, error) {
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	out := &obfsv1.GetObfsCapabilitiesResponse{}
	for _, caps := range obfsEngineCapabilities {
		out.Engines = append(out.Engines, &obfsv1.EngineObfsCapabilities{
			Engine:                   caps.engine,
			Utls:                     caps.utls,
			UtlsProfiles:             append([]string(nil), caps.utlsProfiles...),
			SupportsVersionedParrots: caps.versionedParrots,
			Fragmentation:            caps.fragmentation,
			FragmentParams:           caps.fragmentParams,
			Jitter:                   caps.jitter,
			FakeSni:                  caps.fakeSNI,
		})
	}
	return out, nil
}

// activeObfsProfile returns a copy of the stored profile, or nil when the
// suite is disabled.
func (s *Server) activeObfsProfile() *obfsv1.ObfuscationProfile {
	s.obfsMu.Lock()
	defer s.obfsMu.Unlock()
	if !obfsEnabled(s.obfs) {
		return nil
	}
	return proto.Clone(s.obfs).(*obfsv1.ObfuscationProfile)
}

const obfsProfileFile = "obfs_profile.json"

// obfsProfilePath is empty when the core persists nothing.
func (s *Server) obfsProfilePath() string {
	if s.dataDir == "" {
		return ""
	}
	return filepath.Join(s.dataDir, obfsProfileFile)
}

// saveObfsProfile persists the normalized profile atomically; an empty
// path (no data dir) keeps it in memory only.
func (s *Server) saveObfsProfile(p *obfsv1.ObfuscationProfile) error {
	path := s.obfsProfilePath()
	if path == "" {
		return nil
	}
	raw, err := protojson.MarshalOptions{Multiline: true}.Marshal(p)
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), "obfs_profile-*.tmp")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()
	if _, err := tmp.Write(append(raw, '\n')); err != nil {
		_ = tmp.Close()
		_ = os.Remove(tmpName)
		return err
	}
	if err := tmp.Close(); err != nil {
		_ = os.Remove(tmpName)
		return err
	}
	if err := os.Chmod(tmpName, 0o600); err != nil {
		_ = os.Remove(tmpName)
		return err
	}
	if err := os.Rename(tmpName, path); err != nil {
		_ = os.Remove(tmpName)
		return err
	}
	return nil
}

// loadObfsProfile reads the persisted profile. A missing file means the
// suite was never configured; a corrupt or invalid one is reported through
// warn and ignored so a hand-edited file can never break startup. The warn
// messages are self-contained: the server journals them into every later
// session's event stream (until ApplyObfsProfile clears the warning) so
// WatchEvents surfaces the disabled suite.
func loadObfsProfile(path string, warn func(string)) *obfsv1.ObfuscationProfile {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	p := &obfsv1.ObfuscationProfile{}
	if err := protojson.Unmarshal(raw, p); err != nil {
		if warn != nil {
			warn("obfuscation: the stored profile (" + obfsProfileFile + ") is corrupt and was ignored; the suite stays disabled until a profile is applied")
		}
		return nil
	}
	normalized, err := normalizeObfsProfile(p)
	if err != nil {
		if warn != nil {
			warn("obfuscation: the stored profile (" + obfsProfileFile + ") is invalid and was ignored; the suite stays disabled until a profile is applied")
		}
		return nil
	}
	return normalized
}

// Ensure the control server implements the obfuscation service.
var _ obfsv1.ObfsControlServer = (*Server)(nil)
