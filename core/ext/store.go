package ext

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Sources of an installed extension.
const (
	SourceCatalog  = "catalog"
	SourceSideload = "sideload"
	SourceURL      = "url"
)

// TokenLen is the per-extension token length in bytes.
const TokenLen = 32

// Installed is one extension on disk.
type Installed struct {
	Manifest    Manifest  `json:"manifest"`
	Version     string    `json:"version"`
	Enabled     bool      `json:"enabled"`
	Source      string    `json:"source"`
	InstalledAt time.Time `json:"installed_at"`
	// Granted are the permissions the user accepted.
	Granted []string `json:"granted"`
	// Previous keeps the N-1 version directory name for rollback.
	Previous string `json:"previous,omitempty"`
}

// registryFile is the installed.json inside the extensions directory.
const registryFile = "installed.json"

// Store owns the extension lifecycle on disk.
type Store struct {
	mu        sync.Mutex
	dir       string // <datadir>/extensions
	installed map[string]*Installed
	issuer    *TokenIssuer
}

// OpenStore loads the extension registry from dir, creating it if needed.
func OpenStore(dir string) (*Store, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: no directory for the extension store")
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot create the extension directory: %v", err)
	}
	s := &Store{dir: dir, installed: map[string]*Installed{}, issuer: NewTokenIssuer()}
	raw, err := os.ReadFile(filepath.Join(dir, registryFile)) //nolint:gosec // fixed name inside the store dir
	if err != nil {
		if os.IsNotExist(err) {
			return s, nil
		}
		return nil, errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot read the extension registry: %v", err)
	}
	var reg map[string]*Installed
	if err := json.Unmarshal(raw, &reg); err != nil {
		return nil, errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: the extension registry is corrupt: %v", err)
	}
	for id, inst := range reg {
		if inst == nil {
			continue
		}
		s.installed[id] = inst
	}
	return s, nil
}

// saveLocked persists the registry atomically.
func (s *Store) saveLocked() error {
	raw, err := json.MarshalIndent(s.installed, "", "  ")
	if err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot encode the extension registry: %v", err)
	}
	tmp := filepath.Join(s.dir, registryFile+".tmp")
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot write the extension registry: %v", err)
	}
	if err := os.Rename(tmp, filepath.Join(s.dir, registryFile)); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot replace the extension registry: %v", err)
	}
	return nil
}

// extDir returns the content directory for id@version.
func (s *Store) extDir(id, version string) string {
	return filepath.Join(s.dir, id+"@"+version)
}

// Install verifies pkg and installs it. granted must cover every permission
// in the manifest; the caller is expected to have shown the permission
// prompt (and any re-prompt for widened permissions) before calling.
// For an update it returns the permissions added relative to the previous
// version, so the caller can surface what changed.
func (s *Store) Install(pkg *Package, source string, granted []string) (added []string, err error) {
	if pkg == nil || pkg.Manifest == nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid, "ext: no package")
	}
	if err := pkg.Verify(); err != nil {
		return nil, err
	}
	m := pkg.Manifest
	for _, g := range granted {
		if !IsKnownPermission(g) {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPermissionDenied, "ext: unknown granted permission %q", g)
		}
	}
	// Granted must cover the manifest's permissions.
	need := map[string]bool{}
	for _, p := range m.Permissions {
		need[p] = true
	}
	for _, g := range granted {
		delete(need, g)
	}
	if len(need) > 0 {
		missing := make([]string, 0, len(need))
		for p := range need {
			missing = append(missing, p)
		}
		sort.Strings(missing)
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPermissionDenied,
			"ext: the install does not grant required permissions: %s", strings.Join(missing, ", "))
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	cur, updating := s.installed[m.ID]
	if updating {
		if CompareVersions(m.Version, cur.Version) <= 0 {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyLifecycle,
				"ext: version %s is not newer than installed %s", m.Version, cur.Version)
		}
		added, _ = DiffPermissions(cur.Granted, granted)
	}
	if err := s.extractLocked(m, pkg); err != nil {
		// A failed extract must not leave a half-written version behind:
		// the registry still points at the previous version, and a later
		// retry starts from a clean directory.
		_ = os.RemoveAll(s.extDir(m.ID, m.Version))
		return nil, err
	}
	previous := ""
	enabled := true
	installedAt := time.Now().UTC()
	if updating {
		previous = cur.Version
		enabled = cur.Enabled
		installedAt = cur.InstalledAt
	}
	s.installed[m.ID] = &Installed{
		Manifest:    *m,
		Version:     m.Version,
		Enabled:     enabled,
		Source:      source,
		InstalledAt: installedAt,
		Granted:     append([]string(nil), granted...),
		Previous:    previous,
	}
	if err := s.saveLocked(); err != nil {
		return nil, err
	}
	return added, nil
}

// extractLocked writes the package content to id@version.
func (s *Store) extractLocked(m *Manifest, pkg *Package) error {
	dst := s.extDir(m.ID, m.Version)
	if err := os.MkdirAll(dst, 0o700); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot create the extension directory: %v", err)
	}
	names := make([]string, 0, len(pkg.Files))
	for n := range pkg.Files {
		names = append(names, n)
	}
	sort.Strings(names)
	for _, n := range names {
		target := filepath.Join(dst, filepath.FromSlash(n))
		// Belt and suspenders: the archive paths were validated, but never
		// trust a join without re-checking containment.
		if !strings.HasPrefix(target, dst+string(os.PathSeparator)) {
			return errs.Newf(errs.CodeInternal, KeyPackageInvalid, "ext: unsafe extract path %q", n)
		}
		if err := os.MkdirAll(filepath.Dir(target), 0o700); err != nil {
			return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot create %q: %v", n, err)
		}
		if err := os.WriteFile(target, pkg.Files[n], 0o600); err != nil {
			return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot write %q: %v", n, err)
		}
	}
	return nil
}

// Rollback restores the N-1 version kept at install time.
func (s *Store) Rollback(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	cur, ok := s.installed[id]
	if !ok {
		return errs.Newf(errs.CodeNotFound, KeyLifecycle, "ext: %q is not installed", id)
	}
	if cur.Previous == "" {
		return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: %q has no previous version to roll back to", id)
	}
	prevDir := s.extDir(id, cur.Previous)
	if st, err := os.Stat(prevDir); err != nil || !st.IsDir() {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: the previous version of %q is missing on disk", id)
	}
	// Drop the bad version's directory, keep the previous one.
	if err := os.RemoveAll(s.extDir(id, cur.Version)); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot remove the bad version of %q: %v", id, err)
	}
	cur.Version = cur.Previous
	cur.Previous = ""
	cur.Manifest.Version = cur.Version
	s.issuer.RevokeByExtension(id)
	return s.saveLocked()
}

// SetEnabled enables or disables an extension in one tap. Disabling revokes
// its host tokens immediately: panels lose core access at once.
func (s *Store) SetEnabled(id string, enabled bool) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	cur, ok := s.installed[id]
	if !ok {
		return errs.Newf(errs.CodeNotFound, KeyLifecycle, "ext: %q is not installed", id)
	}
	cur.Enabled = enabled
	if !enabled {
		s.issuer.RevokeByExtension(id)
	}
	return s.saveLocked()
}

// Uninstall removes an extension, its previous version, settings and tokens.
func (s *Store) Uninstall(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	cur, ok := s.installed[id]
	if !ok {
		return errs.Newf(errs.CodeNotFound, KeyLifecycle, "ext: %q is not installed", id)
	}
	for _, v := range []string{cur.Version, cur.Previous} {
		if v == "" {
			continue
		}
		if err := os.RemoveAll(s.extDir(id, v)); err != nil {
			return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot remove %q: %v", id, err)
		}
	}
	if err := os.RemoveAll(s.settingsPath(id)); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot remove the settings of %q: %v", id, err)
	}
	s.issuer.RevokeByExtension(id)
	delete(s.installed, id)
	return s.saveLocked()
}

// List returns a snapshot of installed extensions, sorted by id.
func (s *Store) List() []Installed {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]Installed, 0, len(s.installed))
	for _, inst := range s.installed {
		out = append(out, *inst)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Manifest.ID < out[j].Manifest.ID })
	return out
}

// Get returns one installed extension.
func (s *Store) Get(id string) (*Installed, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	inst, ok := s.installed[id]
	if !ok {
		return nil, false
	}
	cp := *inst
	return &cp, true
}

// ContentDir returns the on-disk directory of an installed version, for the
// app to load panels from. Empty when not installed.
func (s *Store) ContentDir(id string) string {
	s.mu.Lock()
	defer s.mu.Unlock()
	inst, ok := s.installed[id]
	if !ok {
		return ""
	}
	return s.extDir(id, inst.Version)
}

// settingsPath is the per-extension settings file.
func (s *Store) settingsPath(id string) string {
	return filepath.Join(s.dir, id+".settings.json")
}

// GetSettings returns the extension's settings (defaults merged from the
// schema when the file is absent).
func (s *Store) GetSettings(id string) (map[string]any, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	inst, ok := s.installed[id]
	if !ok {
		return nil, errs.Newf(errs.CodeNotFound, KeyLifecycle, "ext: %q is not installed", id)
	}
	out := schemaDefaults(inst.Manifest.SettingsSchema)
	raw, err := os.ReadFile(s.settingsPath(id)) //nolint:gosec // fixed suffix inside the store dir
	if err != nil {
		if os.IsNotExist(err) {
			return out, nil
		}
		return nil, errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot read the settings of %q: %v", id, err)
	}
	var stored map[string]any
	if err := json.Unmarshal(raw, &stored); err != nil {
		// Corrupt settings must not brick the extension: fall back to
		// defaults and let the next save repair the file.
		return out, nil
	}
	for k, v := range stored {
		out[k] = v
	}
	return out, nil
}

// SetSettings validates values against the manifest's settings_schema and
// persists them. Unknown keys and type violations are rejected.
func (s *Store) SetSettings(id string, values map[string]any) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	inst, ok := s.installed[id]
	if !ok {
		return errs.Newf(errs.CodeNotFound, KeyLifecycle, "ext: %q is not installed", id)
	}
	if err := validateSettingsValues(inst.Manifest.SettingsSchema, values); err != nil {
		return err
	}
	raw, err := json.MarshalIndent(values, "", "  ")
	if err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot encode the settings of %q: %v", id, err)
	}
	if err := os.WriteFile(s.settingsPath(id), raw, 0o600); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot save the settings of %q: %v", id, err)
	}
	return nil
}

// schemaDefaults extracts "default" values from the settings schema.
func schemaDefaults(schema json.RawMessage) map[string]any {
	out := map[string]any{}
	if len(schema) == 0 {
		return out
	}
	var obj map[string]any
	if err := json.Unmarshal(schema, &obj); err != nil {
		return out
	}
	props, _ := obj["properties"].(map[string]any)
	for name, raw := range props {
		prop, _ := raw.(map[string]any)
		if prop == nil {
			continue
		}
		if d, ok := prop["default"]; ok {
			out[name] = d
		}
	}
	return out
}

// validateSettingsValues checks values against the schema's properties.
func validateSettingsValues(schema json.RawMessage, values map[string]any) error {
	if len(schema) == 0 {
		if len(values) > 0 {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle,
				"ext: this extension has no settings, but %d were given", len(values))
		}
		return nil
	}
	var obj map[string]any
	if err := json.Unmarshal(schema, &obj); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: the settings schema is unreadable")
	}
	props, _ := obj["properties"].(map[string]any)
	for name, v := range values {
		raw, ok := props[name]
		if !ok {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: unknown setting %q", name)
		}
		prop, _ := raw.(map[string]any)
		if prop == nil {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: bad schema for setting %q", name)
		}
		if err := checkValueType(name, prop, v); err != nil {
			return err
		}
	}
	return nil
}

func checkValueType(name string, prop map[string]any, v any) error {
	want, _ := prop["type"].(string)
	switch want {
	case "string":
		s, ok := v.(string)
		if !ok {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q must be a string", name)
		}
		if max, ok := toFloat(prop["maxLength"]); ok && float64(len(s)) > max {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q is too long", name)
		}
		if min, ok := toFloat(prop["minLength"]); ok && float64(len(s)) < min {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q is too short", name)
		}
	case "integer":
		f, ok := toFloat(v)
		if !ok || f != float64(int64(f)) {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q must be an integer", name)
		}
		if err := checkRange(name, prop, f); err != nil {
			return err
		}
	case "number":
		f, ok := toFloat(v)
		if !ok {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q must be a number", name)
		}
		if err := checkRange(name, prop, f); err != nil {
			return err
		}
	case "boolean":
		if _, ok := v.(bool); !ok {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q must be true or false", name)
		}
	default:
		return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q has an unsupported type", name)
	}
	if enum, ok := prop["enum"].([]any); ok {
		found := false
		for _, e := range enum {
			if fmt.Sprintf("%v", e) == fmt.Sprintf("%v", v) {
				found = true
				break
			}
		}
		if !found {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q has a disallowed value", name)
		}
	}
	return nil
}

func checkRange(name string, prop map[string]any, f float64) error {
	if max, ok := toFloat(prop["maximum"]); ok && f > max {
		return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q is too large", name)
	}
	if min, ok := toFloat(prop["minimum"]); ok && f < min {
		return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q is too small", name)
	}
	return nil
}

func toFloat(v any) (float64, bool) {
	switch n := v.(type) {
	case float64:
		return n, true
	case float32:
		return float64(n), true
	case int:
		return float64(n), true
	case int64:
		return float64(n), true
	case json.Number:
		f, err := n.Float64()
		return f, err == nil
	}
	return 0, false
}

// Grant is what a verified token carries.
type Grant struct {
	ExtensionID string
	Permissions map[string]bool
}

// TokenIssuer mints and verifies per-extension tokens scoped to granted
// permissions. Tokens live in memory only: a core restart invalidates them,
// and the app mints fresh ones for enabled extensions at startup.
type TokenIssuer struct {
	mu     sync.Mutex
	tokens map[string]*Grant // base64(token) -> grant
}

// NewTokenIssuer returns an empty issuer.
func NewTokenIssuer() *TokenIssuer {
	return &TokenIssuer{tokens: map[string]*Grant{}}
}

// Mint creates a token for an enabled extension with exactly perms.
func (t *TokenIssuer) Mint(extensionID string, perms []string) (string, error) {
	if strings.TrimSpace(extensionID) == "" {
		return "", errs.Newf(errs.CodeInvalidArgument, KeyPermissionDenied, "ext: empty extension id")
	}
	raw := make([]byte, TokenLen)
	if _, err := rand.Read(raw); err != nil {
		return "", errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot mint a token: %v", err)
	}
	g := &Grant{ExtensionID: extensionID, Permissions: map[string]bool{}}
	for _, p := range perms {
		if !IsKnownPermission(p) {
			return "", errs.Newf(errs.CodeInvalidArgument, KeyPermissionDenied, "ext: unknown permission %q", p)
		}
		g.Permissions[p] = true
	}
	enc := base64.RawStdEncoding.EncodeToString(raw)
	t.mu.Lock()
	t.tokens[enc] = g
	t.mu.Unlock()
	return enc, nil
}

// Verify checks a token and returns its grant. Comparison is constant-time
// over the stored keys to avoid oracle behavior.
func (t *TokenIssuer) Verify(token string) (*Grant, bool) {
	t.mu.Lock()
	defer t.mu.Unlock()
	for k, g := range t.tokens {
		if subtle.ConstantTimeCompare([]byte(k), []byte(token)) == 1 {
			return g, true
		}
	}
	return nil, false
}

// Revoke drops one token.
func (t *TokenIssuer) Revoke(token string) {
	t.mu.Lock()
	defer t.mu.Unlock()
	for k := range t.tokens {
		if subtle.ConstantTimeCompare([]byte(k), []byte(token)) == 1 {
			delete(t.tokens, k)
		}
	}
}

// RevokeByExtension drops every token of an extension (disable/uninstall/
// rollback): one tap cuts core access immediately.
func (t *TokenIssuer) RevokeByExtension(extensionID string) {
	t.mu.Lock()
	defer t.mu.Unlock()
	for k, g := range t.tokens {
		if g.ExtensionID == extensionID {
			delete(t.tokens, k)
		}
	}
}

// Issuer exposes the store's token issuer for the host service wiring.
func (s *Store) Issuer() *TokenIssuer { return s.issuer }
