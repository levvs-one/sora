package ext

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
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
	Permissions  []string `json:"permissions"`
	DownloadURL  string   `json:"download_url"`
	Sha256       string   `json:"sha256"`
	Size         int64    `json:"size"`
	MinAppVer    string   `json:"min_app_version"`
}

// Catalog is the parsed, team-signed index.
type Catalog struct {
	Version    int     `json:"catalog_version"`
	UpdatedAt  string  `json:"updated_at"`
	Extensions []Entry `json:"extensions"`
}

// ParseCatalog parses catalog JSON without verifying the signature.
func ParseCatalog(data []byte) (*Catalog, error) {
	if len(data) == 0 || len(data) > maxCatalogBytes {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: the catalog has a bad size (%d bytes)", len(data))
	}
	var c Catalog
	dec := json.NewDecoder(strings.NewReader(string(data)))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&c); err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyCatalogInvalid,
			"ext: the catalog is not valid JSON: %v", err)
	}
	if err := c.Validate(); err != nil {
		return nil, err
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
		if _, err := hex.DecodeString(e.Sha256); err != nil {
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
	}
	return nil
}

// allowedBadges is the closed badge set the team may award.
var allowedBadges = map[string]bool{
	"verified": true, // reviewed and signed by the Sora team
	"top":      true, // top of the week by installs and rating
	"new":      true, // published within the last 30 days
	"staff":    true, // built by the Sora team
}

// FetchCatalog downloads catalog.json and its .minisig, verifies the team
// signature, and returns the parsed catalog. client may be nil (a default
// client with a 30s timeout is used). The URL must be https.
func FetchCatalog(ctx context.Context, client *http.Client, catalogURL string) (*Catalog, error) {
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
	return ParseCatalog(body)
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
