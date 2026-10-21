package ext

import (
	"encoding/json"
	"net/netip"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"golang.org/x/net/idna"
	"google.golang.org/protobuf/encoding/protojson"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// Bypass layers: one extension's stored contribution to the core's
// DPI-bypass setup (Anti-DPI seam, contract 1.14).
//
// A Layer is what an extension with bypass.write asks the core to run:
// one global strategy (used for zapret-with-VPN when the user's own
// request carries none) plus per-destination bindings. Layers are DATA,
// never code: they are validated fail-closed at Set time with exactly
// the strategy rules a plan applies, persisted as JSON under the core's
// data directory, and merged into plans by core/control — user rules
// always win over a layer, and a layer from a disabled extension (or
// one that lost bypass.write) is filtered out by the plan-side
// provider, never by this store: the store remembers, the wiring
// decides who is currently trusted.

// Layer limits. A layer is a small routing contribution, not a rules
// database: 256 bindings and 64 KiB of serialized JSON are far beyond
// any panel's honest need and keep a hostile layer from bloating every
// plan build.
const (
	MaxBypassBindings   = 256
	MaxBypassLayerBytes = 64 << 10
	bypassLayersFile    = "bypass-layers.json"
	bypassLayersVersion = 1
)

// MaxBypassMatchBytes caps one binding's match so the plan merge's
// synthetic outbound name ("ext: " + match) can always fit the plan's
// name limit (engine.MaxNameBytes): a match past the cap is refused
// here, honestly at Apply time, instead of producing a plan whose
// outbound name fails plan validation at Connect time (M1). The merge
// additionally shortens over-long names deterministically, so a layer
// that never passed through this store still cannot invalidate a plan.
const MaxBypassMatchBytes = engine.MaxNameBytes - len("ext: ")

// bypassIDNA is the exact IDNA profile core/control's ruleFromProto
// applies to user routing rules (L2): binding matches are
// canonicalized with it at storage time, so a layer match and a user
// rule naming the same host in different case or encoding forms
// compare equal everywhere downstream.
var bypassIDNA = idna.New(idna.MapForLookup(), idna.StrictDomainName(true), idna.ValidateLabels(true), idna.VerifyDNSLength(true), idna.BidiRule())

// layerWriteFile is the write seam of the layer store's persistence
// (the same variable-function pattern the package uses elsewhere for
// test substitution): tests replace it with a failing write to prove
// Set/Delete never let memory diverge from disk (L3).
var layerWriteFile = func(name string, data []byte) error {
	return os.WriteFile(name, data, 0o600) //nolint:gosec // name is the store's own tmp path
}

// CanonicalBypassMatch renders a binding match in the canonical form
// it is stored and compared in: the domain part of a
// domain:/full:/bare-domain match is IDNA-converted exactly as
// ruleFromProto converts user rule destinations (lower-case ASCII /
// punycode). Other forms (tags, addresses, networks) are returned
// unchanged. A match whose domain part does not convert is returned
// unchanged, so ValidateBypassMatch stays the one place that refuses
// it.
func CanonicalBypassMatch(match string) string {
	m := strings.TrimSpace(match)
	for _, prefix := range []string{"domain:", "full:"} {
		if strings.HasPrefix(m, prefix) {
			if ascii, err := bypassIDNA.ToASCII(strings.TrimPrefix(m, prefix)); err == nil {
				return prefix + ascii
			}
			return m
		}
	}
	for _, prefix := range []string{"geosite:", "geoip:", "ruleset:", "process:"} {
		if strings.HasPrefix(m, prefix) {
			return m
		}
	}
	if _, err := netip.ParseAddr(m); err == nil {
		return m
	}
	if _, err := netip.ParsePrefix(m); err == nil {
		return m
	}
	if strings.Contains(m, ":") {
		return m
	}
	if ascii, err := bypassIDNA.ToASCII(m); err == nil {
		return ascii
	}
	return m
}

// matchResolvesMidSNI reports whether a binding match names a
// concrete domain a mid-SNI marker strategy can be resolved against
// at plan merge: a domain:/full: destination or a bare domain (which
// the merge canonicalizes to domain:). Tag destinations
// (geosite:/geoip:/ruleset:), addresses and networks name no single
// SNI hostname, so a marker strategy on them stays refused.
func matchResolvesMidSNI(match string) bool {
	m := CanonicalBypassMatch(match)
	if _, ok := strings.CutPrefix(m, "domain:"); ok {
		return true
	}
	if _, ok := strings.CutPrefix(m, "full:"); ok {
		return true
	}
	for _, prefix := range []string{"geosite:", "geoip:", "ruleset:", "process:"} {
		if strings.HasPrefix(m, prefix) {
			return false
		}
	}
	if _, err := netip.ParseAddr(m); err == nil {
		return false
	}
	if _, err := netip.ParsePrefix(m); err == nil {
		return false
	}
	if strings.Contains(m, ":") {
		return false
	}
	return true
}

// canonicalLayer returns a copy of the layer whose binding matches
// are canonical (see CanonicalBypassMatch): what Set stores is the
// canonical form, never the caller's raw spelling (L2).
func canonicalLayer(layer Layer) Layer {
	out := cloneLayer(layer)
	out.UpdatedAt = layer.UpdatedAt
	for i := range out.Bindings {
		out.Bindings[i].Match = CanonicalBypassMatch(out.Bindings[i].Match)
	}
	return out
}

// Binding binds one destination to a bypass strategy. Match is a
// plan-rule destination (see ValidateBypassMatch).
type Binding struct {
	Match    string
	Strategy *corev1.BypassStrategy
}

// Layer is one extension's stored bypass layer.
type Layer struct {
	// Global is the layer's global strategy, or nil when the layer
	// contributes only bindings.
	Global   *corev1.BypassStrategy
	Bindings []Binding
	// UpdatedAt is stamped by Set; a zero value in the argument is
	// replaced with the store clock.
	UpdatedAt time.Time
}

// IsEmpty reports whether the layer contributes nothing (no global, no
// bindings): applying an empty layer clears the extension's layer.
func (l Layer) IsEmpty() bool { return l.Global == nil && len(l.Bindings) == 0 }

// LayerEntry pairs a layer with the extension that owns it.
type LayerEntry struct {
	ID    string
	Layer Layer
}

// storedBinding / storedLayer are the on-disk JSON shapes. Strategies
// ride as protojson documents so the file stays in the contract's
// snake_case vocabulary and unknown contract fields fail loudly
// instead of being silently dropped by a hand-mirrored struct.
type storedBinding struct {
	Match    string          `json:"match"`
	Strategy json.RawMessage `json:"strategy"`
}

type storedLayer struct {
	Global    json.RawMessage `json:"global,omitempty"`
	Bindings  []storedBinding `json:"bindings,omitempty"`
	UpdatedAt time.Time       `json:"updated_at"`
}

type storedLayersFile struct {
	Version int                    `json:"version"`
	Layers  map[string]storedLayer `json:"layers"`
}

// LayerStore persists bypass layers by extension id under dir. The zero
// value is not usable; build one with NewLayerStore. An empty dir keeps
// layers in memory only (tests).
type LayerStore struct {
	mu     sync.Mutex
	dir    string
	path   string
	layers map[string]Layer
	// Now supplies the clock for UpdatedAt stamps; nil means time.Now.
	Now func() time.Time
}

// NewLayerStore loads the layers file from dir, creating dir if needed.
// A missing file starts empty; a corrupt or foreign-version file is an
// error (fail-closed, like the desync binding store: silently dropping
// layers would change the user's traffic path without a trace).
func NewLayerStore(dir string) (*LayerStore, error) {
	s := &LayerStore{dir: dir, layers: map[string]Layer{}}
	if dir == "" {
		return s, nil
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
			"ext: cannot create the bypass layer directory: %v", err)
	}
	s.path = filepath.Join(dir, bypassLayersFile)
	raw, err := os.ReadFile(s.path) //nolint:gosec // fixed name inside the store dir
	if err != nil {
		if os.IsNotExist(err) {
			return s, nil
		}
		return nil, errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
			"ext: cannot read the bypass layers file: %v", err)
	}
	var f storedLayersFile
	if err := json.Unmarshal(raw, &f); err != nil {
		return nil, errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
			"ext: the bypass layers file is not valid JSON: %v", err)
	}
	if f.Version != bypassLayersVersion {
		return nil, errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
			"ext: the bypass layers file is version %d, this build understands %d: refusing to guess",
			f.Version, bypassLayersVersion)
	}
	for id, sl := range f.Layers {
		layer, err := layerFromStored(sl)
		if err != nil {
			return nil, errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
				"ext: the stored bypass layer of %q is unreadable: %v", id, err)
		}
		// Stored layers were validated at Set time; a hand-edited file
		// must not smuggle an invalid layer past that gate, so loading
		// re-validates and refuses the whole file rather than serving
		// a layer the plan merge would have to distrust.
		if err := validateLayer(layer); err != nil {
			return nil, err
		}
		s.layers[id] = layer
	}
	return s, nil
}

func (s *LayerStore) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

// Set validates and stores the layer of extension id, stamping
// UpdatedAt, and persists the store. Validation is fail-closed: any
// invalid strategy or match refuses the whole layer and leaves the
// previously stored one untouched.
func (s *LayerStore) Set(id string, layer Layer) error {
	if strings.TrimSpace(id) == "" {
		return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid,
			"ext: a bypass layer needs an extension id")
	}
	// Bindings are stored in canonical form (L2), so validation, the
	// duplicate check and the size accounting all see the stored form.
	layer = canonicalLayer(layer)
	if err := validateLayer(layer); err != nil {
		return err
	}
	stored, err := layerToStored(layer)
	if err != nil {
		return err
	}
	raw, err := json.Marshal(stored)
	if err != nil {
		return errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
			"ext: cannot encode the bypass layer of %q: %v", id, err)
	}
	if len(raw) > MaxBypassLayerBytes {
		return errs.Newf(errs.CodeResourceExhausted, KeyBypassLayerTooLarge,
			"ext: the bypass layer of %q is %d bytes, the limit is %d", id, len(raw), MaxBypassLayerBytes)
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	layer.UpdatedAt = s.now().UTC()
	// Atomicity (L3): mutate a copy of the map, persist THAT, and swap
	// the live state only once the save succeeded — a failed save
	// leaves memory exactly as it was, in step with the disk.
	next := make(map[string]Layer, len(s.layers)+1)
	for k, v := range s.layers {
		next[k] = v
	}
	// Keep the in-memory copy detached from the caller's slices.
	next[id] = cloneLayer(layer)
	if err := s.saveLayersLocked(next); err != nil {
		return err
	}
	s.layers = next
	return nil
}

// Get returns the layer of extension id, if one is stored.
func (s *LayerStore) Get(id string) (Layer, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	layer, ok := s.layers[id]
	if !ok {
		return Layer{}, false
	}
	return cloneLayer(layer), true
}

// Delete removes the layer of extension id. Deleting a layer that does
// not exist is not an error.
func (s *LayerStore) Delete(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.layers[id]; !ok {
		return nil
	}
	// Same atomicity discipline as Set (L3): persist the copy first,
	// swap only on success.
	next := make(map[string]Layer, len(s.layers)-1)
	for k, v := range s.layers {
		if k != id {
			next[k] = v
		}
	}
	if err := s.saveLayersLocked(next); err != nil {
		return err
	}
	s.layers = next
	return nil
}

// List returns every stored layer in a deterministic order: most
// recently updated first, ties broken by extension id. Plan merging
// consumes this order (freshest layer wins the global slot and the
// first binding for a destination).
func (s *LayerStore) List() []LayerEntry {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]LayerEntry, 0, len(s.layers))
	for id, layer := range s.layers {
		out = append(out, LayerEntry{ID: id, Layer: cloneLayer(layer)})
	}
	sort.Slice(out, func(i, j int) bool {
		if !out[i].Layer.UpdatedAt.Equal(out[j].Layer.UpdatedAt) {
			return out[i].Layer.UpdatedAt.After(out[j].Layer.UpdatedAt)
		}
		return out[i].ID < out[j].ID
	})
	return out
}

// saveLocked persists the current store state atomically. Callers
// must hold s.mu.
func (s *LayerStore) saveLocked() error { return s.saveLayersLocked(s.layers) }

// saveLayersLocked persists the given layer set atomically, without
// touching s.layers: Set/Delete persist their candidate map through
// here and adopt it only when this returns nil (L3). Callers must
// hold s.mu.
func (s *LayerStore) saveLayersLocked(layers map[string]Layer) error {
	if s.path == "" {
		return nil
	}
	f := storedLayersFile{Version: bypassLayersVersion, Layers: make(map[string]storedLayer, len(layers))}
	for id, layer := range layers {
		stored, err := layerToStored(layer)
		if err != nil {
			return err
		}
		f.Layers[id] = stored
	}
	raw, err := json.MarshalIndent(f, "", "  ")
	if err != nil {
		return errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
			"ext: cannot encode the bypass layers file: %v", err)
	}
	tmp := s.path + ".tmp"
	if err := layerWriteFile(tmp, raw); err != nil {
		return errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
			"ext: cannot write the bypass layers file: %v", err)
	}
	if err := os.Rename(tmp, s.path); err != nil {
		_ = os.Remove(tmp)
		return errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
			"ext: cannot replace the bypass layers file: %v", err)
	}
	return nil
}

// validateLayer checks one layer against every Set-time rule except the
// serialized-size limit (checked on the encoded form in Set).
func validateLayer(layer Layer) error {
	if len(layer.Bindings) > MaxBypassBindings {
		return errs.Newf(errs.CodeResourceExhausted, KeyBypassLayerTooLarge,
			"ext: a bypass layer carries %d bindings, the limit is %d", len(layer.Bindings), MaxBypassBindings)
	}
	if layer.Global != nil {
		if err := ValidateBypassStrategy(layer.Global); err != nil {
			return err
		}
	}
	seen := make(map[string]bool, len(layer.Bindings))
	for _, b := range layer.Bindings {
		if err := ValidateBypassMatch(b.Match); err != nil {
			return err
		}
		// Duplicates are judged on the canonical form (L2): two
		// spellings of the same host are one binding.
		canon := CanonicalBypassMatch(b.Match)
		if seen[canon] {
			return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid,
				"ext: the bypass layer repeats the match %q", b.Match)
		}
		seen[canon] = true
		// Binding strategies validate in the scope of their match:
		// the mid-SNI marker is allowed exactly on plain-domain
		// bindings (the global above keeps the plain validation, so
		// a marker global stays refused).
		if err := ValidateBypassBindingStrategy(b.Match, b.Strategy); err != nil {
			return err
		}
	}
	return nil
}

// ValidateBypassMatch checks one binding match against the semantics of
// core/control's checkBypass extended to what the entry must actually
// be: a domain, an address or a network, in plan-rule destination
// grammar. Accepted forms: "domain:<domain>", "full:<domain>",
// "geosite:<tag>", "geoip:<tag>", "ruleset:<tag>", an IP literal, a
// CIDR, or a bare domain (shorthand for "domain:<domain>"). Everything
// else — whitespace, schemes, ports, process names, keywords, empty
// suffixes — is refused, because the plan merge turns the match into a
// routing rule verbatim and a shape it cannot express must fail here,
// at the layer boundary, not inside plan validation.
func ValidateBypassMatch(match string) error {
	invalid := func(format string, args ...any) error {
		return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid, format, args...)
	}
	m := strings.TrimSpace(match)
	if m == "" || m != match {
		return invalid("ext: a bypass match %q is empty or padded", match)
	}
	if strings.ContainsAny(m, " \t\r\n") {
		return invalid("ext: a bypass match %q holds whitespace", match)
	}
	// Length cap (M1): the merge names the binding's outbound
	// "ext: "+match, and plan names are capped at engine.MaxNameBytes.
	// Refusing an over-long match here keeps Apply honest — the layer
	// is rejected whole — instead of letting the merge build a plan
	// that fails validation at Connect.
	if len(m) > MaxBypassMatchBytes {
		return invalid("ext: a bypass match is %d bytes, the limit is %d (the merged outbound name must fit %d bytes)",
			len(m), MaxBypassMatchBytes, engine.MaxNameBytes)
	}
	for _, prefix := range []string{"domain:", "full:"} {
		if strings.HasPrefix(m, prefix) {
			// The domain part is judged in its IDNA-canonical form,
			// the same conversion ruleFromProto applies to user
			// rules (L2): a Unicode or upper-case spelling is valid
			// exactly when its canonical form is.
			ascii, err := bypassIDNA.ToASCII(strings.TrimPrefix(m, prefix))
			if err != nil {
				return invalid("ext: a bypass match %q: %v", match, err)
			}
			if err := validDomainName(ascii); err != nil {
				return invalid("ext: a bypass match %q: %v", match, err)
			}
			return nil
		}
	}
	for _, prefix := range []string{"geosite:", "geoip:", "ruleset:"} {
		if strings.HasPrefix(m, prefix) {
			tag := strings.TrimPrefix(m, prefix)
			if tag == "" || strings.ContainsAny(tag, ":/*") {
				return invalid("ext: a bypass match %q has an empty or invalid tag", match)
			}
			return nil
		}
	}
	if strings.Contains(m, ":") && !strings.Contains(m, "/") {
		// A colon outside a known prefix is a port or a scheme — except
		// an IPv6 literal, which parses as an address.
		if _, err := netip.ParseAddr(m); err == nil {
			return nil
		}
		return invalid("ext: a bypass match %q is not a domain, an address or a network", match)
	}
	if _, err := netip.ParseAddr(m); err == nil {
		return nil
	}
	if _, err := netip.ParsePrefix(m); err == nil {
		return nil
	}
	// A purely numeric name is a port (single label) or a malformed IP
	// literal (several labels), never a domain: refuse it here instead
	// of letting the plan layer reinterpret it as a keyword.
	allNumeric := true
	for _, label := range strings.Split(m, ".") {
		for _, c := range label {
			if c < '0' || c > '9' {
				allNumeric = false
			}
		}
	}
	if allNumeric {
		return invalid("ext: a bypass match %q is not a domain, an address or a network", match)
	}
	ascii, err := bypassIDNA.ToASCII(m)
	if err != nil {
		return invalid("ext: a bypass match %q is not a domain, an address or a network", match)
	}
	if err := validDomainName(ascii); err != nil {
		return invalid("ext: a bypass match %q is not a domain, an address or a network", match)
	}
	return nil
}

// validDomainName checks a DNS name label by label (ASCII or already
// punycode; IDNA conversion is the plan layer's job, as in
// core/control's ruleFromProto).
func validDomainName(name string) error {
	if name == "" || len(name) > 253 || strings.HasPrefix(name, ".") || strings.HasSuffix(name, ".") {
		return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid,
			"ext: %q is not a domain name", name)
	}
	for _, label := range strings.Split(name, ".") {
		if label == "" || len(label) > 63 || strings.HasPrefix(label, "-") || strings.HasSuffix(label, "-") {
			return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid,
				"ext: %q is not a domain name", name)
		}
		for _, c := range label {
			if !(c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-') {
				return errs.Newf(errs.CodeInvalidArgument, KeyBypassLayerInvalid,
					"ext: %q is not a domain name", name)
			}
		}
	}
	return nil
}

// cloneLayer deep-copies a layer so stored state never aliases caller
// memory (strategies are protobuf values with slices inside).
func cloneLayer(l Layer) Layer {
	out := Layer{UpdatedAt: l.UpdatedAt}
	if l.Global != nil {
		out.Global = cloneStrategy(l.Global)
	}
	if len(l.Bindings) > 0 {
		out.Bindings = make([]Binding, len(l.Bindings))
		for i, b := range l.Bindings {
			out.Bindings[i] = Binding{Match: b.Match, Strategy: cloneStrategy(b.Strategy)}
		}
	}
	return out
}

func cloneStrategy(s *corev1.BypassStrategy) *corev1.BypassStrategy {
	if s == nil {
		return nil
	}
	return EngineToProtoStrategy(ProtoToEngineStrategy(s))
}

func layerToStored(l Layer) (storedLayer, error) {
	out := storedLayer{UpdatedAt: l.UpdatedAt}
	if l.Global != nil {
		raw, err := protojson.Marshal(l.Global)
		if err != nil {
			return storedLayer{}, errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
				"ext: cannot encode a bypass strategy: %v", err)
		}
		out.Global = raw
	}
	for _, b := range l.Bindings {
		raw, err := protojson.Marshal(b.Strategy)
		if err != nil {
			return storedLayer{}, errs.Newf(errs.CodeInternal, KeyBypassLayerStore,
				"ext: cannot encode a bypass strategy: %v", err)
		}
		out.Bindings = append(out.Bindings, storedBinding{Match: b.Match, Strategy: raw})
	}
	return out, nil
}

func layerFromStored(sl storedLayer) (Layer, error) {
	out := Layer{UpdatedAt: sl.UpdatedAt}
	if len(sl.Global) > 0 {
		g := &corev1.BypassStrategy{}
		if err := protojson.Unmarshal(sl.Global, g); err != nil {
			return Layer{}, err
		}
		out.Global = g
	}
	for _, sb := range sl.Bindings {
		st := &corev1.BypassStrategy{}
		if err := protojson.Unmarshal(sb.Strategy, st); err != nil {
			return Layer{}, err
		}
		out.Bindings = append(out.Bindings, Binding{Match: sb.Match, Strategy: st})
	}
	return out, nil
}
