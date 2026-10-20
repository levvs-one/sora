// Manifest v1 schema extension: background workers, net.fetch, and the
// capability contract pointers (theme, network-hook, routing).
//
// The v1 decoder in manifest.go is frozen: it rejects unknown top-level
// fields (DisallowUnknownFields). These optional fields stay additive, so
// manifest_version remains 1 and old manifests parse exactly as before:
//
//   - "background_task": periodic background work (capability "background",
//     permission "background").
//   - "network_hosts": host allowlist for net.fetch (permission "net.fetch").
//   - "theme": theme asset contract (capability "theme", permission
//     "theme.apply"). Asset schema is v0/proposed; only the entry path and
//     the capability/permission cross-checks are enforced.
//   - "network_hook": DPI-bypass module contract (capability "network-hook",
//     permission "net.hooks"). Same enforcement level as "theme".
//   - "routing": routing-rules contract (capability "routing", permission
//     "routing.rules"). Same enforcement level as "theme".
//
// ParseManifestFull is the entry point: it decodes the v1 core and the
// extension keys in one pass (one struct holding both field sets, unknown
// fields still rejected), runs the frozen v1 validation, then validates
// the extension keys against the parsed manifest. Callers that only need
// v1 keep using ParseManifest.
package ext

import (
	"bytes"
	"encoding/json"
	"io"
	"net"
	"regexp"
	"strings"

	"github.com/levvs-one/sora-client/core/errs"
)

// Extension-localization keys for the v2-runtime manifest fields. Stable
// strings, mapped to localized text by the app (same convention as
// manifest.go).
const (
	KeyBackgroundInvalid   errs.Key = "ext.background.invalid"
	KeyNetworkHostsInvalid errs.Key = "ext.network_hosts.invalid"
	KeyNetFetchDenied      errs.Key = "ext.netfetch.denied"
	KeyNetFetchFailed      errs.Key = "ext.netfetch.failed"
	KeyNetFetchPaused      errs.Key = "ext.netfetch.paused"
	KeyWorkerFailed        errs.Key = "ext.worker.failed"
	KeyThemeInvalid        errs.Key = "ext.theme.invalid"
	KeyNetworkHookInvalid  errs.Key = "ext.network_hook.invalid"
	KeyRoutingInvalid      errs.Key = "ext.routing.invalid"
)

// BackgroundTask declares one periodic background task for an extension.
// The declared interval is a wish: the runtime clamps it into
// [MinWorkerInterval, MaxWorkerInterval] (see worker.go).
type BackgroundTask struct {
	// IntervalMinutes is the desired period in whole minutes (1..10080).
	IntervalMinutes int `json:"interval_minutes"`
	// Entry is the worker script inside the package, e.g. "worker.js".
	Entry string `json:"entry"`
}

// ManifestExt holds the optional v2-runtime and capability-contract
// manifest fields. A nil Background and empty NetworkHosts mean "not
// declared"; same for the three capability contracts.
type ManifestExt struct {
	Background   *BackgroundTask `json:"background_task,omitempty"`
	NetworkHosts []string        `json:"network_hosts,omitempty"`
	Theme        *ThemeExt       `json:"theme,omitempty"`
	NetworkHook  *NetworkHookExt `json:"network_hook,omitempty"`
	Routing      *RoutingExt     `json:"routing,omitempty"`
}

// ThemeExt points at the theme asset file (theme contract v0, proposed).
type ThemeExt struct {
	// Entry is the theme descriptor inside the package, e.g. "theme.json".
	Entry string `json:"entry"`
}

// NetworkHookExt points at the DPI-bypass module descriptor (network-hook
// contract v0, proposed).
type NetworkHookExt struct {
	// Entry is the hook descriptor inside the package, e.g. "hook.json".
	Entry string `json:"entry"`
}

// RoutingExt points at the routing-rules file (routing contract v0,
// proposed).
type RoutingExt struct {
	// Entry is the rules file inside the package, e.g. "rules.json".
	Entry string `json:"entry"`
}

var (
	// DNS label: alphanumerics, interior hyphens, 1..63 chars.
	dnsLabelPattern = regexp.MustCompile(`^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$`)
	// Worker script file names: relative .js path, forward slashes only, no
	// traversal. The class is written with the hyphen last so it is
	// unambiguously literal; a backslash is not a member of the class
	// (the zip format mandates '/', and isSafeArchivePath rejects \ anyway).
	scriptNamePattern = regexp.MustCompile(`^[A-Za-z0-9_][A-Za-z0-9_./-]{0,255}\.js$`)
	// Capability-contract asset file names: relative .json path, forward
	// slashes only, no traversal - same unambiguous class as above.
	assetNamePattern = regexp.MustCompile(`^[A-Za-z0-9_][A-Za-z0-9_./-]{0,255}\.json$`)
)

// MaxNetworkHosts caps the allowlist so a manifest cannot smuggle an
// unbounded match set.
const MaxNetworkHosts = 64

// MaxBackgroundIntervalMinutes is the largest declarable worker interval
// (7 days). Anything above is a manifest error, not a clamp.
const MaxBackgroundIntervalMinutes = 7 * 24 * 60

// ParseManifestFull parses sora-extension.json including the optional
// v2-runtime fields (background_task, network_hosts). The v1 core of the
// document is validated by the frozen ParseManifest; the extension fields
// are validated against the parsed manifest (capability/permission
// cross-checks). Old manifests without the new keys behave exactly as
// before.
// manifestDoc is the single-decode shape of a full manifest: the frozen
// v1 fields plus the v2-runtime extension fields in one struct, so
// ParseManifestFull decodes the document exactly once. (The previous
// implementation unmarshaled into map[string]json.RawMessage, split the
// extension keys out, re-marshaled both halves and decoded each again —
// measured 7635 B/op and 90 allocs for a ~500-byte manifest with extension
// fields, more than half of it re-encoding work.)
type manifestDoc struct {
	Manifest
	ManifestExt
}

func ParseManifestFull(data []byte) (*Manifest, *ManifestExt, error) {
	if len(data) == 0 {
		return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest is empty")
	}
	if len(data) > 1<<20 {
		return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest exceeds 1 MiB")
	}
	var doc manifestDoc
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&doc); err != nil {
		// A mistyped v2-runtime field and a generally malformed document
		// both land here; the split decoder this replaces distinguished
		// them in its messages but with the same key and code.
		return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest is not valid JSON: %v", err)
	}
	// The map-based decoder this replaces (json.Unmarshal) rejected
	// trailing data after the document; a bare Decoder.Decode would
	// silently accept a second value. Keep the strictness: only EOF may
	// follow.
	var extra any
	if err := dec.Decode(&extra); err != io.EOF {
		return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest is not valid JSON: trailing data")
	}
	m := &doc.Manifest
	if err := m.Validate(); err != nil {
		return nil, nil, err
	}
	x := &doc.ManifestExt
	if err := x.Validate(m); err != nil {
		return nil, nil, err
	}
	return m, x, nil
}

// Validate cross-checks the v2-runtime fields against the parsed v1
// manifest: background_task needs the "background" capability and
// permission; network_hosts needs the "net.fetch" permission.
func (x *ManifestExt) Validate(m *Manifest) error {
	if x == nil || m == nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: nil manifest")
	}
	if x.Background != nil {
		if err := x.Background.validate(m); err != nil {
			return err
		}
	}
	if len(x.NetworkHosts) > 0 {
		if !hasPermission(m, "net.fetch") {
			return errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid,
				"ext: network_hosts requires the %q permission", "net.fetch")
		}
		if len(x.NetworkHosts) > MaxNetworkHosts {
			return errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid,
				"ext: network_hosts holds %d entries (max %d)", len(x.NetworkHosts), MaxNetworkHosts)
		}
		seen := map[string]bool{}
		for _, h := range x.NetworkHosts {
			norm, err := normalizeHostPattern(h)
			if err != nil {
				return errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid,
					"ext: bad network_hosts entry %q: %v", h, err)
			}
			if seen[norm] {
				return errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid,
					"ext: duplicate network_hosts entry %q", h)
			}
			seen[norm] = true
		}
	}
	if x.Theme != nil {
		if err := x.Theme.validate(m); err != nil {
			return err
		}
	}
	if x.NetworkHook != nil {
		if err := x.NetworkHook.validate(m); err != nil {
			return err
		}
	}
	if x.Routing != nil {
		if err := x.Routing.validate(m); err != nil {
			return err
		}
	}
	return nil
}

func (b *BackgroundTask) validate(m *Manifest) error {
	if !hasCapability(m, "background") {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			`ext: background_task requires the "background" capability`)
	}
	if !hasPermission(m, "background") {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			`ext: background_task requires the "background" permission`)
	}
	if b.IntervalMinutes < 1 || b.IntervalMinutes > MaxBackgroundIntervalMinutes {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			"ext: background_task interval_minutes must be 1..%d", MaxBackgroundIntervalMinutes)
	}
	if !scriptNamePattern.MatchString(b.Entry) ||
		strings.Contains(b.Entry, "..") ||
		strings.HasPrefix(b.Entry, "/") {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			"ext: background_task entry %q must be a relative .js path without traversal", b.Entry)
	}
	return nil
}

// validate cross-checks one capability contract pointer: the matching
// capability and permission must be declared, and the entry must be a safe
// relative .json path. The asset file's own schema is v0/proposed and is
// NOT validated here — only the pointer is.
func (t *ThemeExt) validate(m *Manifest) error {
	return validateAssetRef("theme", t.Entry, "theme", "theme.apply", KeyThemeInvalid, m)
}

func (n *NetworkHookExt) validate(m *Manifest) error {
	return validateAssetRef("network_hook", n.Entry, "network-hook", "net.hooks", KeyNetworkHookInvalid, m)
}

func (r *RoutingExt) validate(m *Manifest) error {
	return validateAssetRef("routing", r.Entry, "routing", "routing.rules", KeyRoutingInvalid, m)
}

func validateAssetRef(field, entry, capability, permission string, key errs.Key, m *Manifest) error {
	if !hasCapability(m, capability) {
		return errs.Newf(errs.CodeInvalidArgument, key,
			"ext: %s requires the %q capability", field, capability)
	}
	if !hasPermission(m, permission) {
		return errs.Newf(errs.CodeInvalidArgument, key,
			"ext: %s requires the %q permission", field, permission)
	}
	if !isSafeAssetPath(entry) {
		return errs.Newf(errs.CodeInvalidArgument, key,
			"ext: %s entry %q must be a relative .json path without traversal", field, entry)
	}
	return nil
}

// isSafeAssetPath allows only relative .json paths without traversal,
// mirroring the worker script rule (scriptNamePattern) for contract files.
func isSafeAssetPath(entry string) bool {
	return assetNamePattern.MatchString(entry) &&
		!strings.Contains(entry, "..") &&
		!strings.HasPrefix(entry, "/")
}

func hasPermission(m *Manifest, id string) bool {
	for _, p := range m.Permissions {
		if p == id {
			return true
		}
	}
	return false
}

func hasCapability(m *Manifest, id string) bool {
	for _, c := range m.Capabilities {
		if c == id {
			return true
		}
	}
	return false
}

// normalizeHostPattern validates one network_hosts entry and returns its
// canonical form: a lowercase DNS name, or "*." + name for a wildcard. IP
// literals are rejected (the allowlist is DNS names only; a literal IP can
// never match because Fetcher rejects IP hosts up front).
func normalizeHostPattern(entry string) (string, error) {
	e := strings.ToLower(strings.TrimSpace(entry))
	wildcard := false
	if strings.HasPrefix(e, "*.") {
		wildcard = true
		e = e[2:]
	}
	if e == "" || len(e) > 253 {
		return "", errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid, "empty or too long")
	}
	if strings.Contains(e, "*") {
		return "", errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid, `"*" is only allowed as the full leftmost label ("*.example.com")`)
	}
	for _, label := range strings.Split(e, ".") {
		if !dnsLabelPattern.MatchString(label) {
			return "", errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid, "bad DNS label %q", label)
		}
	}
	if isIPLike(e) {
		return "", errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid, "IP literals are not allowed")
	}
	if wildcard {
		return "*." + e, nil
	}
	return e, nil
}

// isIPLike reports whether s looks like an IP address literal, including
// notations net.ParseIP does not understand: decimal ("2130706433"),
// hex ("0x7f000001", "0x7f.1") and octal ("017700000001"). Some system
// resolvers (cgo/glibc inet_aton) still dial such names as IPs, so the
// allowlist policy treats them as IP literals everywhere: they can neither
// be allowlisted nor fetched. All-digit dotted names are not valid public
// DNS names (no numeric TLDs exist), so legitimate hosts are unaffected.
func isIPLike(s string) bool {
	if net.ParseIP(s) != nil {
		return true
	}
	for _, label := range strings.Split(s, ".") {
		low := strings.ToLower(label)
		if len(low) > 2 && strings.HasPrefix(low, "0x") {
			hex := true
			for _, c := range low[2:] {
				if !strings.ContainsRune("0123456789abcdef", c) {
					hex = false
					break
				}
			}
			if hex {
				return true
			}
		}
	}
	nodots := strings.ReplaceAll(s, ".", "")
	if nodots == "" {
		return false
	}
	for _, c := range nodots {
		if c < '0' || c > '9' {
			return false
		}
	}
	return true
}
