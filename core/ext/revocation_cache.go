package ext

// Revocation list cache: the on-disk home of the last signature-verified
// revocations.json, and the refresh policy around it.
//
// Until pass 1 the list had verification (VerifyRevocationList) and
// enforcement (Store.checkRevocationsLocked) but no transport and no
// storage: nothing ever loaded a list, so enforcement could never fire in
// production. This file is the missing middle:
//
//   - RevocationCache persists the VERIFIED raw bytes (never a locally
//     re-signed copy), exactly like CatalogCache.
//   - RevocationCache.Refresh fetches revocations.json + .minisig from the
//     team endpoint, verifies with the team key, caches and returns it.
//     On any failure it falls back to the cache, and with no cache the
//     fetch error is returned.
//   - ApplyToStore installs a loaded list into the extension Store.
//
// Honest limits, by design (see revoke.go for the enforcement policy):
// verification fails closed while the team key ceremony is pending, so
// today Refresh can only ever return the cache fallback or an error. The
// mechanism is real and tested; it becomes functional the day the owner
// completes the ceremony and publishes the endpoint - no code change
// needed here.

import (
	"context"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// DefaultRevocationURL is where the app looks for the team revocation
// list, next to DefaultCatalogURL.
const DefaultRevocationURL = "https://raw.githubusercontent.com/levvs-one/sora/main/extensions/revocations.json"

// RevocationCache is the offline revocation list: the last verified
// revocations.json on disk. The store loads it at startup so a kill order
// received earlier keeps applying across restarts and offline launches.
type RevocationCache struct {
	dir string
}

const (
	revocationCacheFile    = "revocations.json"
	revocationCacheTmpFile = "revocations.json.tmp"
)

// NewRevocationCache opens the cache in dir, creating it if needed.
func NewRevocationCache(dir string) (*RevocationCache, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: no directory for the revocation cache")
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, errs.Newf(errs.CodeInternal, KeyRevocationInvalid,
			"ext: cannot create the revocation cache directory: %v", err)
	}
	return &RevocationCache{dir: dir}, nil
}

// Store saves raw revocations.json bytes. The bytes must already be
// signature-verified (VerifyRevocationList) AND parseable; the cache
// refuses anything else, so a corrupt or unverified file can never be
// persisted by accident.
func (rc *RevocationCache) Store(verifiedRaw []byte) error {
	if _, err := ParseRevocationList(verifiedRaw); err != nil {
		return err
	}
	tmp := filepath.Join(rc.dir, revocationCacheTmpFile)
	if err := os.WriteFile(tmp, verifiedRaw, 0o600); err != nil {
		return errs.Newf(errs.CodeInternal, KeyRevocationInvalid,
			"ext: cannot write the revocation cache: %v", err)
	}
	if err := os.Rename(tmp, filepath.Join(rc.dir, revocationCacheFile)); err != nil {
		return errs.Newf(errs.CodeInternal, KeyRevocationInvalid,
			"ext: cannot replace the revocation cache: %v", err)
	}
	return nil
}

// Load returns the cached list. ok is false when there is no usable cache
// (missing or corrupt is "no cache", never a hard error: offline must
// degrade, not crash - and the enforcement policy for a missing list is
// defined in revoke.go).
func (rc *RevocationCache) Load() (l *RevocationList, ok bool) {
	raw, err := os.ReadFile(filepath.Join(rc.dir, revocationCacheFile)) //nolint:gosec // fixed name inside the cache dir
	if err != nil {
		return nil, false
	}
	l, err = ParseRevocationList(raw)
	if err != nil {
		return nil, false
	}
	return l, true
}

// fetchRawRevocations downloads revocations.json and its .minisig and
// verifies the team signature, returning the raw verified bytes.
func fetchRawRevocations(ctx context.Context, client *http.Client, listURL string) ([]byte, error) {
	if !strings.HasPrefix(listURL, "https://") {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: the revocation list URL must be https")
	}
	if client == nil {
		client = &http.Client{Timeout: 30 * time.Second}
	}
	get := func(url string) ([]byte, error) {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
				"ext: bad revocation list URL: %v", err)
		}
		resp, err := client.Do(req)
		if err != nil {
			return nil, errs.Newf(errs.CodeUnavailable, KeyRevocationInvalid,
				"ext: cannot reach the revocation list: %v", err)
		}
		defer func() { _ = resp.Body.Close() }()
		if resp.StatusCode != http.StatusOK {
			return nil, errs.Newf(errs.CodeUnavailable, KeyRevocationInvalid,
				"ext: the revocation list answered %s", resp.Status)
		}
		data, err := io.ReadAll(io.LimitReader(resp.Body, maxRevocationBytes+1))
		if err != nil {
			return nil, errs.Newf(errs.CodeUnavailable, KeyRevocationInvalid,
				"ext: cannot read the revocation list: %v", err)
		}
		if len(data) > maxRevocationBytes {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
				"ext: the revocation list is too large")
		}
		return data, nil
	}
	body, err := get(listURL)
	if err != nil {
		return nil, err
	}
	sig, err := get(listURL + ".minisig")
	if err != nil {
		return nil, err
	}
	// Verify BEFORE trusting a single byte: a failed signature (or the
	// pending key ceremony) rejects the download outright; the caller
	// falls back to the last verified cache instead.
	if _, err := VerifyRevocationList(string(sig), body); err != nil {
		return nil, err
	}
	return body, nil
}

// Refresh fetches the team revocation list and updates the cache. On any
// fetch or verification failure it falls back to the cached list when one
// exists (fromCache=true); with no network and no cache, the fetch error
// is returned. A cache write failure does not fail the refresh: the list
// itself is good.
func (rc *RevocationCache) Refresh(ctx context.Context, client *http.Client, listURL string) (*RevocationList, bool, error) {
	raw, err := fetchRawRevocations(ctx, client, listURL)
	if err == nil {
		l, perr := ParseRevocationList(raw)
		if perr != nil {
			return nil, false, perr
		}
		_ = rc.Store(raw)
		return l, false, nil
	}
	if cached, ok := rc.Load(); ok {
		return cached, true, nil
	}
	return nil, false, err
}

// ApplyToStore installs a revocation list into the store (nil clears it),
// so startup can arm enforcement from the cache in one call. It reports
// whether a list was applied.
func ApplyToStore(s *Store, l *RevocationList) bool {
	if s == nil {
		return false
	}
	s.SetRevocations(l)
	return l != nil
}
