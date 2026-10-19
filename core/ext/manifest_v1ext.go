// Manifest v1 schema extension: background workers and net.fetch.
//
// The v1 decoder in manifest.go is frozen: it rejects unknown top-level
// fields (DisallowUnknownFields). These v2-runtime fields stay optional and
// additive, so manifest_version remains 1 and old manifests parse exactly as
// before:
//
//   - "background_task": periodic background work (capability "background",
//     permission "background").
//   - "network_hosts": host allowlist for net.fetch (permission "net.fetch").
//
// ParseManifestFull is the entry point: it splits the v2-runtime keys out of
// the raw JSON, runs the frozen v1 decoder on the remainder, then validates
// the extension keys against the parsed manifest. Callers that only need v1
// keep using ParseManifest.
package ext

import (
	"encoding/json"
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
	KeyWorkerFailed        errs.Key = "ext.worker.failed"
)

// Top-level manifest keys owned by this extension file. ParseManifestFull
// strips these before handing the document to the frozen v1 decoder.
var manifestExtKeys = []string{"background_task", "network_hosts"}

// BackgroundTask declares one periodic background task for an extension.
// The declared interval is a wish: the runtime clamps it into
// [MinWorkerInterval, MaxWorkerInterval] (see worker.go).
type BackgroundTask struct {
	// IntervalMinutes is the desired period in whole minutes (1..10080).
	IntervalMinutes int `json:"interval_minutes"`
	// Entry is the worker script inside the package, e.g. "worker.js".
	Entry string `json:"entry"`
}

// ManifestExt holds the optional v2-runtime manifest fields. A nil
// Background and an empty NetworkHosts mean "not declared".
type ManifestExt struct {
	Background   *BackgroundTask `json:"background_task,omitempty"`
	NetworkHosts []string        `json:"network_hosts,omitempty"`
}

var (
	// DNS label: alphanumerics, interior hyphens, 1..63 chars.
	dnsLabelPattern = regexp.MustCompile(`^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$`)
	// Worker script file names: relative .js path, no traversal.
	scriptNamePattern = regexp.MustCompile(`^[A-Za-z0-9_][A-Za-z0-9_.\-/]{0,255}\.js$`)
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
func ParseManifestFull(data []byte) (*Manifest, *ManifestExt, error) {
	if len(data) == 0 {
		return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest is empty")
	}
	if len(data) > 1<<20 {
		return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest exceeds 1 MiB")
	}
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest is not valid JSON: %v", err)
	}
	extRaw := make(map[string]json.RawMessage, len(manifestExtKeys))
	for _, k := range manifestExtKeys {
		if v, ok := raw[k]; ok {
			extRaw[k] = v
			delete(raw, k)
		}
	}
	base, err := json.Marshal(raw)
	if err != nil {
		return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest is not valid JSON: %v", err)
	}
	m, err := ParseManifest(base)
	if err != nil {
		return nil, nil, err
	}
	var x ManifestExt
	if len(extRaw) > 0 {
		extDoc, err := json.Marshal(extRaw)
		if err != nil {
			return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: the manifest is not valid JSON: %v", err)
		}
		dec := json.NewDecoder(strings.NewReader(string(extDoc)))
		dec.DisallowUnknownFields()
		if err := dec.Decode(&x); err != nil {
			return nil, nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid, "ext: bad v2-runtime manifest fields: %v", err)
		}
	}
	if err := x.Validate(m); err != nil {
		return nil, nil, err
	}
	return m, &x, nil
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
	if isIPLiteral(e) {
		return "", errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid, "IP literals are not allowed")
	}
	if wildcard {
		return "*." + e, nil
	}
	return e, nil
}

// isIPLiteral reports whether s is an IP address literal. The allowlist is
// DNS names only; literals can never match because the Fetcher rejects
// IP-literal hosts up front, so they are refused at manifest validation.
func isIPLiteral(s string) bool {
	return net.ParseIP(s) != nil
}
