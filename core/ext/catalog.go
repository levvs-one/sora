package ext

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"io"
	"math"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Catalog format version.
const CatalogVersion = 1

// maxCatalogBytes bounds the catalog index itself (not the downloads).
const maxCatalogBytes = 4 << 20

// DefaultCatalogURL is where the app looks for the team catalog. The value
// is a placeholder until the team publishes the catalog endpoint.
const DefaultCatalogURL = "https://extensions.sora.example/v1/catalog.json"

// Entry is one extension in the team catalog.
type Entry struct {
	ID           string   `json:"id"`
	Name         string   `json:"name"`
	Version      string   `json:"version"`
	Description  string   `json:"description"`
	Author       string   `json:"author"`
	AuthorID     string   `json:"author_identity"`
	AuthorKey    string   `json:"author_key"`
	IconURL      string   `json:"icon_url"`
	Rating       float64  `json:"rating"`
	RatingsCount int      `json:"ratings_count"`
	Installs     int      `json:"installs"`
	Badges       []string `json:"badges"`
	Categories   []string `json:"categories"`
	// Capabilities mirrors the manifest capability registry (theme,
	// network-hook, routing, ui-panel, background, widget). The store UI
	// filters on these ("Themes", "Bypasses", ...).
	Capabilities []string `json:"capabilities,omitempty"`
	Permissions  []string `json:"permissions"`
	DownloadURL  string   `json:"download_url"`
	Sha256       string   `json:"sha256"`
	Size         int64    `json:"size"`
	MinAppVer    string   `json:"min_app_version"`
	// RolloutFraction stages a version release: 0..1 of installs may see
	// this version as the update candidate. Missing or <=0 means 1 (fully
	// rolled out). The team ramps 0.05 -> 0.25 -> 0.5 -> 1 while watching
	// crash/error telemetry; a bad version is halted with the revocation
	// list, not with a zero fraction. Deterministic per install id, so a
	// device doesn't flap between versions on every catalog sync.
	RolloutFraction float64 `json:"rollout_fraction,omitempty"`
	// Screenshots are https image URLs (<= maxScreenshots) shown on the
	// extension detail page. Optional.
	Screenshots []string `json:"screenshots,omitempty"`
	// Changelog lists recent versions newest-first for the detail page.
	Changelog []ChangelogEntry `json:"changelog,omitempty"`
}

// ChangelogEntry is one released version's notes.
type ChangelogEntry struct {
	Version string `json:"version"`
	Date    string `json:"date"` // RFC3339
	Notes   string `json:"notes"`
}

// Catalog is the parsed, team-signed index.
type Catalog struct {
	Version    int     `json:"catalog_version"`
	UpdatedAt  string  `json:"updated_at"`
	Extensions []Entry `json:"extensions"`
	// MaxAge is how long (seconds) a client may serve this catalog from
	// its offline cache before revalidating. 300..604800; ParseCatalog
	// normalizes a missing value to DefaultCatalogMaxAge. It is the
	// server's promise about staleness: the app shows "cached - <date>"
	// once past it instead of silently serving old data.
	MaxAge int `json:"max_age,omitempty"`
}

// DefaultCatalogMaxAge is the freshness promise when the catalog omits
// max_age: one hour.
const DefaultCatalogMaxAge = 3600

// maxScreenshots bounds the detail-page carousel.
const maxScreenshots = 8

// IsKnownCapability reports whether c is in the manifest capability
// registry (mirrors allowedCapabilities in manifest.go).
func IsKnownCapability(c string) bool {
	switch c {
	case "theme", "network-hook", "routing", "ui-panel", "background", "widget":
		return true
	}
	return false
}

// ParseCatalog parses catalog JSON without verifying the signature.
func ParseCatalog(data []byte) (*Catalog, error) {
	if len(data) == 0 || len(data) > maxCatalogBytes {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: the catalog has a bad size (%d bytes)", len(data))
	}
	var c Catalog
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&c); err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: the catalog is not valid JSON: %v", err)
	}
	if err := c.Validate(); err != nil {
		return nil, err
	}
	if c.MaxAge == 0 {
		c.MaxAge = DefaultCatalogMaxAge
	}
	return &c, nil
}

// Validate checks the catalog shape and every entry.
func (c *Catalog) Validate() error {
	if c.Version != CatalogVersion {
		return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: unsupported catalog_version %d", c.Version)
	}
	if _, err := time.Parse(time.RFC3339, c.UpdatedAt); err != nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: the catalog updated_at is not RFC3339: %v", err)
	}
	// max_age 0 means "absent": ParseCatalog normalizes it to the default.
	if c.MaxAge != 0 && (c.MaxAge < 300 || c.MaxAge > 604800) {
		return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: catalog max_age %d is outside 300..604800", c.MaxAge)
	}
	seen := map[string]bool{}
	for i, e := range c.Extensions {
		if !idPattern.MatchString(e.ID) {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %d has a bad id %q", i, e.ID)
		}
		if seen[e.ID] {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog lists %q twice", e.ID)
		}
		seen[e.ID] = true
		if !semverPattern.MatchString(e.Version) || !semverPattern.MatchString(e.MinAppVer) {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q has a bad version", e.ID)
		}
		if strings.TrimSpace(e.Name) == "" || strings.TrimSpace(e.Author) == "" {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q needs a name and an author", e.ID)
		}
		if e.Rating < 0 || e.Rating > 5 {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q has a bad rating", e.ID)
		}
		for _, p := range e.Permissions {
			if !IsKnownPermission(p) {
				return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
					"ext: catalog entry %q wants unknown permission %q", e.ID, p)
			}
		}
		for _, b := range e.Badges {
			if !allowedBadges[b] {
				return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
					"ext: catalog entry %q has an unknown badge %q", e.ID, b)
			}
		}
		for _, scheme := range []string{e.DownloadURL, e.IconURL} {
			if scheme != "" && !strings.HasPrefix(scheme, "https://") {
				return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
					"ext: catalog entry %q has a non-https URL", e.ID)
			}
		}
		if len(e.Sha256) != 64 {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q has a bad sha256", e.ID)
		}
		if !isHexDigest(e.Sha256) {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q sha256 is not hex", e.ID)
		}
		if e.Size <= 0 || e.Size > maxPackageBytes {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q has a bad size", e.ID)
		}
		if _, _, err := ParsePublicKey(e.AuthorKey); err != nil {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q has a bad author key: %v", e.ID, err)
		}
		if err := validateEntryExtras(e); err != nil {
			return err
		}
	}
	return nil
}

// validateEntryExtras checks the additive catalog fields: rollout fraction,
// screenshots, changelog and capabilities.
func validateEntryExtras(e Entry) error {
	if math.IsNaN(e.RolloutFraction) || e.RolloutFraction < 0 || e.RolloutFraction > 1 {
		return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: catalog entry %q has a bad rollout_fraction", e.ID)
	}
	if len(e.Screenshots) > maxScreenshots {
		return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: catalog entry %q lists too many screenshots", e.ID)
	}
	for _, u := range e.Screenshots {
		if u == "" || !strings.HasPrefix(u, "https://") {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q has a non-https screenshot", e.ID)
		}
	}
	for i, ch := range e.Changelog {
		if !semverPattern.MatchString(ch.Version) {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q changelog #%d has a bad version", e.ID, i)
		}
		if _, err := time.Parse(time.RFC3339, ch.Date); err != nil {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q changelog #%d has a bad date", e.ID, i)
		}
		if strings.TrimSpace(ch.Notes) == "" || len(ch.Notes) > 2000 {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q changelog #%d has bad notes", e.ID, i)
		}
	}
	for _, c := range e.Capabilities {
		if !IsKnownCapability(c) {
			return errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: catalog entry %q has an unknown capability %q", e.ID, c)
		}
	}
	return nil
}

// EffectiveRollout returns the staged-rollout fraction for the entry:
// 1 when the catalog omits it or sets it <= 0 (fully rolled out).
func (e *Entry) EffectiveRollout() float64 {
	if e.RolloutFraction <= 0 {
		return 1
	}
	return e.RolloutFraction
}

// RolloutEligible reports whether installID falls inside the entry's staged
// rollout bucket. The bucket is sha256(installID | entry id | version),
// stable per device: a device that gets the version keeps it, one that
// doesn't won't flap on every catalog sync. installID must be an
// install-scoped random id (not a hardware fingerprint and not the
// advertising id): bucketing needs stability, not identity.
func (e *Entry) RolloutEligible(installID string) bool {
	f := e.EffectiveRollout()
	if f >= 1 {
		return true
	}
	sum := sha256.Sum256([]byte(installID + "\x00" + e.ID + "\x00" + e.Version))
	bucket := binary.BigEndian.Uint64(sum[:8])
	const buckets = 10000
	return bucket%buckets < uint64(f*buckets)
}

// allowedBadges is the closed badge set the team may award.
var allowedBadges = map[string]bool{
	"verified": true, // reviewed and signed by the Sora team
	"top":      true, // top of the week by installs and rating
	"new":      true, // published within the last 30 days
	"staff":    true, // built by the Sora team
}

// fetchRawCatalog downloads catalog.json and its .minisig and verifies the
// team signature, returning the raw verified bytes.
func fetchRawCatalog(ctx context.Context, client *http.Client, catalogURL string) ([]byte, error) {
	if !strings.HasPrefix(catalogURL, "https://") {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: the catalog URL must be https")
	}
	if client == nil {
		client = &http.Client{Timeout: 30 * time.Second}
	}
	get := func(url string) ([]byte, error) {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: bad catalog URL: %v", err)
		}
		resp, err := client.Do(req)
		if err != nil {
			return nil, errs.Newf(errs.CodeUnavailable, KeyCatalogInvalid,
				"ext: cannot reach the catalog: %v", err)
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			return nil, errs.Newf(errs.CodeUnavailable, KeyCatalogInvalid,
				"ext: the catalog answered %s", resp.Status)
		}
		data, err := io.ReadAll(io.LimitReader(resp.Body, maxCatalogBytes+1))
		if err != nil {
			return nil, errs.Newf(errs.CodeUnavailable, KeyCatalogInvalid,
				"ext: cannot read the catalog: %v", err)
		}
		if len(data) > maxCatalogBytes {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
				"ext: the catalog is too large")
		}
		return data, nil
	}
	body, err := get(catalogURL)
	if err != nil {
		return nil, err
	}
	sig, err := get(catalogURL + ".minisig")
	if err != nil {
		return nil, err
	}
	if err := VerifyCatalogSignature(string(sig), body); err != nil {
		return nil, err
	}
	return body, nil
}

// Find returns the catalog entry for id, if present.
func (c *Catalog) Find(id string) *Entry {
	for i := range c.Extensions {
		if c.Extensions[i].ID == id {
			return &c.Extensions[i]
		}
	}
	return nil
}

// CatalogCache is the offline catalog: the last signature-verified
// catalog.json on disk plus when it was fetched. The store UI serves the
// cache when the network or the signature check fails, and says so
// ("cached - <date>") instead of failing or silently serving stale data.
// A cached catalog is never re-signed locally; it was verified when
// stored, and max_age bounds how long the UI treats it as fresh.
type CatalogCache struct {
	dir string
}

const (
	catalogCacheFile = "catalog.json"
	catalogMetaFile  = "catalog.json.meta"
)

// NewCatalogCache opens the cache in dir, creating it if needed.
func NewCatalogCache(dir string) (*CatalogCache, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: no directory for the catalog cache")
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, errs.Newf(errs.CodeInternal, KeyCatalogInvalid,
			"ext: cannot create the catalog cache directory: %v", err)
	}
	return &CatalogCache{dir: dir}, nil
}

// Store saves raw (already signature-verified and parsed) catalog bytes.
func (cc *CatalogCache) Store(raw []byte) error {
	if _, err := ParseCatalog(raw); err != nil {
		return err
	}
	tmp := filepath.Join(cc.dir, catalogCacheFile+".tmp")
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return errs.Newf(errs.CodeInternal, KeyCatalogInvalid,
			"ext: cannot write the catalog cache: %v", err)
	}
	if err := os.Rename(tmp, filepath.Join(cc.dir, catalogCacheFile)); err != nil {
		return errs.Newf(errs.CodeInternal, KeyCatalogInvalid,
			"ext: cannot replace the catalog cache: %v", err)
	}
	meta := struct {
		FetchedAt string `json:"fetched_at"`
	}{FetchedAt: time.Now().UTC().Format(time.RFC3339)}
	mraw, _ := json.Marshal(meta)
	if err := os.WriteFile(filepath.Join(cc.dir, catalogMetaFile), mraw, 0o600); err != nil {
		return errs.Newf(errs.CodeInternal, KeyCatalogInvalid,
			"ext: cannot write the catalog cache metadata: %v", err)
	}
	return nil
}

// Load returns the cached catalog and when it was fetched. ok is false
// when there is no usable cache (missing or corrupt files are treated as
// no cache, never as a hard error: offline must degrade, not crash).
func (cc *CatalogCache) Load() (c *Catalog, fetchedAt time.Time, ok bool) {
	raw, err := os.ReadFile(filepath.Join(cc.dir, catalogCacheFile)) //nolint:gosec // fixed name inside the cache dir
	if err != nil {
		return nil, time.Time{}, false
	}
	c, err = ParseCatalog(raw)
	if err != nil {
		return nil, time.Time{}, false
	}
	mraw, err := os.ReadFile(filepath.Join(cc.dir, catalogMetaFile)) //nolint:gosec // fixed name inside the cache dir
	if err != nil {
		return nil, time.Time{}, false
	}
	var meta struct {
		FetchedAt string `json:"fetched_at"`
	}
	if err := json.Unmarshal(mraw, &meta); err != nil {
		return nil, time.Time{}, false
	}
	fetchedAt, err = time.Parse(time.RFC3339, meta.FetchedAt)
	if err != nil {
		return nil, time.Time{}, false
	}
	return c, fetchedAt, true
}

// Fresh reports whether a catalog fetched at fetchedAt is still within the
// server's max_age freshness promise.
func Fresh(c *Catalog, fetchedAt time.Time, now time.Time) bool {
	maxAge := c.MaxAge
	if maxAge <= 0 {
		maxAge = DefaultCatalogMaxAge
	}
	return !now.After(fetchedAt.Add(time.Duration(maxAge) * time.Second))
}

// Refresh fetches the team catalog and updates the cache. On any fetch or
// verification failure it falls back to the cached catalog when one exists.
// It returns fromCache=true when the caller must show the "cached" state.
// With no network and no cache, the fetch error is returned.
func (cc *CatalogCache) Refresh(ctx context.Context, client *http.Client, catalogURL string) (*Catalog, bool, time.Time, error) {
	raw, err := fetchRawCatalog(ctx, client, catalogURL)
	if err == nil {
		c, perr := ParseCatalog(raw)
		if perr != nil {
			return nil, false, time.Time{}, perr
		}
		// A cache write failure must not fail the refresh: the catalog
		// itself is good.
		_ = cc.Store(raw)
		return c, false, time.Now().UTC(), nil
	}
	if cached, fetchedAt, ok := cc.Load(); ok {
		return cached, true, fetchedAt, nil
	}
	return nil, false, time.Time{}, err
}
