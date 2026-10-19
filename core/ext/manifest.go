package ext

import (
	"encoding/json"
	"regexp"
	"strings"

	"github.com/levvs-one/sora-client/core/errs"
)

// ManifestVersion is the only manifest version this release understands.
const ManifestVersion = 1

// Extension-localization keys for failures. They are stable strings; the app
// maps them to localized text. They live here (not in core/errs) so the ext
// package stays self-contained.
const (
	KeyManifestInvalid     errs.Key = "ext.manifest.invalid"
	KeyPackageInvalid      errs.Key = "ext.package.invalid"
	KeySignatureInvalid    errs.Key = "ext.signature.invalid"
	KeySigningUnconfigured errs.Key = "ext.signing.unconfigured"
	KeyPermissionDenied    errs.Key = "ext.permission.denied"
	KeyCatalogInvalid      errs.Key = "ext.catalog.invalid"
	KeyLifecycle           errs.Key = "ext.lifecycle.error"
)

// Author identifies who built and signed the extension.
type Author struct {
	// Name is the display name, e.g. "Sora Team" or "Jane Doe".
	Name string `json:"name"`
	// Identity is a verifiable handle, e.g. "github:levvs-one" or an https URL.
	Identity string `json:"identity"`
	// PublicKey is the minisign public key that signed the package
	// (the "<base64>" line of a .pub file). Self-attested for sideloads;
	// for catalog entries the catalog pins the expected key.
	PublicKey string `json:"public_key"`
}

// Panel declares one embeddable UI panel.
type Panel struct {
	// ID is unique within the extension, e.g. "main".
	ID string `json:"id"`
	// Title is the human-readable tab title.
	Title string `json:"title"`
	// Entry is the HTML file inside the package, e.g. "panel.html".
	Entry string `json:"entry"`
}

// Manifest is the parsed sora-extension.json (manifest v1).
type Manifest struct {
	ManifestVersion int             `json:"manifest_version"`
	ID              string          `json:"id"`
	Name            string          `json:"name"`
	Version         string          `json:"version"`
	MinAppVersion   string          `json:"min_app_version"`
	Description     string          `json:"description"`
	Author          Author          `json:"author"`
	Permissions     []string        `json:"permissions"`
	Capabilities    []string        `json:"capabilities"`
	UI              *UIManifest     `json:"ui,omitempty"`
	SettingsSchema  json.RawMessage `json:"settings_schema,omitempty"`
}

// UIManifest declares the extension's UI surface.
type UIManifest struct {
	Panels []Panel `json:"panels"`
}

// Capabilities an extension may declare. A capability is a coarse feature
// area; the fine-grained access control is the permission list.
var allowedCapabilities = map[string]bool{
	"theme":        true, // ships theme assets the user can apply
	"network-hook": true, // contributes DPI-bypass / transport modules
	"routing":      true, // contributes routing rules
	"ui-panel":     true, // embeds panels in the app
	"background":   true, // background tasks (v2 runtime; declared for forward compat)
	"widget":       true, // home-screen widgets (v2 runtime; declared for forward compat)
}

var (
	idPattern      = regexp.MustCompile(`^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$`)
	panelIDPattern = regexp.MustCompile(`^[a-zA-Z0-9_-]{1,64}$`)
	semverPattern  = regexp.MustCompile(`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([-+][0-9A-Za-z.-]+)?$`)
)

// ParseManifest parses and validates sora-extension.json.
func ParseManifest(data []byte) (*Manifest, error) {
	if len(data) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest is empty")
	}
	if len(data) > 1<<20 {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest exceeds 1 MiB")
	}
	var m Manifest
	dec := json.NewDecoder(strings.NewReader(string(data)))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&m); err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest is not valid JSON: %v", err)
	}
	if err := m.Validate(); err != nil {
		return nil, err
	}
	return &m, nil
}

// Validate checks every manifest field against the v1 rules.
func (m *Manifest) Validate() error {
	if m.ManifestVersion != ManifestVersion {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid,
			"ext: unsupported manifest_version %d (want %d)", m.ManifestVersion, ManifestVersion)
	}
	if !idPattern.MatchString(m.ID) {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid,
			"ext: the id %q must be reverse-DNS (e.g. com.example.stats)", m.ID)
	}
	if strings.TrimSpace(m.Name) == "" || len(m.Name) > 80 {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the name must be 1..80 characters")
	}
	if !semverPattern.MatchString(m.Version) {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid,
			"ext: the version %q must be semver (e.g. 1.2.0)", m.Version)
	}
	if !semverPattern.MatchString(m.MinAppVersion) {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid,
			"ext: min_app_version %q must be semver", m.MinAppVersion)
	}
	if len(m.Description) > 2000 {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the description exceeds 2000 characters")
	}
	if strings.TrimSpace(m.Author.Name) == "" || len(m.Author.Name) > 80 {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the author name must be 1..80 characters")
	}
	if strings.TrimSpace(m.Author.Identity) == "" || len(m.Author.Identity) > 160 {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the author identity must be 1..160 characters")
	}
	if strings.TrimSpace(m.Author.PublicKey) == "" {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the author public key is required")
	}
	if _, _, err := ParsePublicKey(m.Author.PublicKey); err != nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the author public key is not a minisign key: %v", err)
	}
	seen := map[string]bool{}
	for _, p := range m.Permissions {
		if !IsKnownPermission(p) {
			return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: unknown permission %q", p)
		}
		if seen[p] {
			return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: duplicate permission %q", p)
		}
		seen[p] = true
	}
	for _, c := range m.Capabilities {
		if !allowedCapabilities[c] {
			return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: unknown capability %q", c)
		}
	}
	if m.UI != nil {
		seenPanels := map[string]bool{}
		for _, p := range m.UI.Panels {
			if !panelIDPattern.MatchString(p.ID) {
				return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: bad panel id %q", p.ID)
			}
			if seenPanels[p.ID] {
				return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: duplicate panel id %q", p.ID)
			}
			seenPanels[p.ID] = true
			if strings.TrimSpace(p.Title) == "" || len(p.Title) > 60 {
				return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: panel %q needs a title of 1..60 characters", p.ID)
			}
			if !isSafeEntry(p.Entry) {
				return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid,
					"ext: panel %q has an unsafe entry %q (must be a relative .html path)", p.ID, p.Entry)
			}
		}
	}
	if len(m.SettingsSchema) > 0 {
		var v any
		if err := json.Unmarshal(m.SettingsSchema, &v); err != nil {
			return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: settings_schema is not valid JSON: %v", err)
		}
		if err := checkSettingsSchema(v); err != nil {
			return err
		}
	}
	return nil
}

// isSafeEntry allows only relative .html paths without traversal.
func isSafeEntry(entry string) bool {
	if entry == "" || len(entry) > 256 {
		return false
	}
	lower := strings.ToLower(entry)
	if !strings.HasSuffix(lower, ".html") {
		return false
	}
	if strings.Contains(entry, "..") || strings.HasPrefix(entry, "/") || strings.HasPrefix(entry, "\\") {
		return false
	}
	for _, part := range strings.Split(entry, "/") {
		if part == "" || part == "." {
			return false
		}
	}
	return true
}

// CompareVersions compares two semver strings: -1, 0, +1.
func CompareVersions(a, b string) int {
	pa, pb := parseSemver(a), parseSemver(b)
	for i := 0; i < 3; i++ {
		if pa[i] != pb[i] {
			if pa[i] < pb[i] {
				return -1
			}
			return 1
		}
	}
	return 0
}

func parseSemver(v string) [3]int {
	var out [3]int
	// Strip pre-release/build metadata for the numeric comparison.
	if i := strings.IndexAny(v, "-+"); i >= 0 {
		v = v[:i]
	}
	parts := strings.Split(v, ".")
	for i := 0; i < 3 && i < len(parts); i++ {
		n := 0
		for _, c := range parts[i] {
			if c < '0' || c > '9' {
				break
			}
			n = n*10 + int(c-'0')
		}
		out[i] = n
	}
	return out
}

// checkSettingsSchema validates the supported JSON-Schema subset used for the
// auto-generated settings form: an object with typed properties.
func checkSettingsSchema(v any) error {
	obj, ok := v.(map[string]any)
	if !ok {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: settings_schema must be a JSON object")
	}
	if t, _ := obj["type"].(string); t != "" && t != "object" {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: settings_schema type must be \"object\"")
	}
	props, _ := obj["properties"].(map[string]any)
	for name, raw := range props {
		if len(name) == 0 || len(name) > 64 {
			return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: bad settings property name %q", name)
		}
		prop, ok := raw.(map[string]any)
		if !ok {
			return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: settings property %q must be an object", name)
		}
		switch t, _ := prop["type"].(string); t {
		case "string", "integer", "number", "boolean":
		case "":
			return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: settings property %q needs a type", name)
		default:
			return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid,
				"ext: settings property %q has unsupported type %q", name, t)
		}
	}
	return nil
}
