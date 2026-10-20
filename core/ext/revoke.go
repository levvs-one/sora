package ext

// Signed revocation list: the emergency brake for malicious or broken
// extensions.
//
// Format: revocations.json plus revocations.json.minisig (minisign, team
// key - the same trust root as the catalog, and the same fail-closed rule
// while the key ceremony is pending). The trusted comment is
// "timestamp:..\tfile:revocations.json\tsha256:..".
//
//	{
//	  "revocation_version": 1,
//	  "updated_at": "2026-10-20T00:00:00Z",
//	  "expires_at": "2026-10-27T00:00:00Z",
//	  "entries": [
//	    {"id": "com.evil.miner", "versions": "*", "reason": "cryptominer"},
//	    {"id": "com.buggy.sync", "versions": "<=1.2.0", "reason": "deletes user data"}
//	  ]
//	}
//
// Enforcement policy (honest, no theater):
//   - Install/Update of a revoked id@version is refused.
//   - Enabling a revoked extension is refused.
//   - No cached list: installs proceed. The catalog signature is the
//     primary gate; a missing list must not brick installs on first run
//     or before the team publishes one.
//   - Expired cached list: new installs and updates are refused (fail
//     closed - stale intel is worse than none), already-installed
//     extensions keep running. An offline device cannot receive a kill
//     order; pretending otherwise would be theater.
//   - Emergency kill is an entry with "versions": "*". The app re-checks
//     the list on every startup and catalog sync and disables matches;
//     disable revokes the extension's tokens immediately (see Store).

import (
	"encoding/json"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Revocation format version and limits.
const (
	RevocationVersion    = 1
	maxRevocationBytes   = 64 << 10 // 64 KiB is plenty for an id list
	maxRevocationEntries = 4096
)

// KeyRevocationInvalid is the localization key for revocation failures.
const KeyRevocationInvalid errs.Key = "ext.revocation.invalid"

// sigFileRevocations is the trusted-comment file name for the list.
const sigFileRevocations = "revocations.json"

// RevocationEntry revokes some versions of one extension id.
type RevocationEntry struct {
	ID       string `json:"id"`
	Versions string `json:"versions"` // "*", "=1.2.3", "<1.2.3", "<=1.2.3"
	Reason   string `json:"reason"`
}

// RevocationList is a parsed revocations.json.
type RevocationList struct {
	Version   int               `json:"revocation_version"`
	UpdatedAt time.Time         `json:"updated_at"`
	ExpiresAt time.Time         `json:"expires_at"`
	Entries   []RevocationEntry `json:"entries"`
}

// Expired reports whether the list is past expires_at.
func (l *RevocationList) Expired(now time.Time) bool {
	return !l.ExpiresAt.After(now)
}

// IsRevoked reports whether id@version is revoked by the list.
func (l *RevocationList) IsRevoked(id, version string) bool {
	if l == nil {
		return false
	}
	for _, e := range l.Entries {
		if e.ID != id {
			continue
		}
		if versionMatches(e.Versions, version) {
			return true
		}
	}
	return false
}

// versionMatches evaluates the tiny constraint language: "*" matches every
// version; otherwise "=x.y.z", "<x.y.z", "<=x.y.z" compare semver.
func versionMatches(constraint, version string) bool {
	if constraint == "*" {
		return true
	}
	var op, want string
	switch {
	case strings.HasPrefix(constraint, "<="):
		op, want = "<=", constraint[2:]
	case strings.HasPrefix(constraint, "<"):
		op, want = "<", constraint[1:]
	case strings.HasPrefix(constraint, "="):
		op, want = "=", constraint[1:]
	default:
		return false
	}
	cmp := CompareVersions(version, want)
	switch op {
	case "=":
		return cmp == 0
	case "<":
		return cmp < 0
	case "<=":
		return cmp <= 0
	}
	return false
}

// checkVersionConstraint rejects anything outside the tiny language above.
func checkVersionConstraint(c string) error {
	if c == "*" {
		return nil
	}
	rest := c
	for _, p := range []string{"<=", "<", "="} {
		if strings.HasPrefix(rest, p) {
			rest = rest[len(p):]
			break
		}
	}
	if rest == c {
		return errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: bad version constraint %q (want \"*\", \"=x.y.z\", \"<x.y.z\" or \"<=x.y.z\")", c)
	}
	if !semverPattern.MatchString(rest) {
		return errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: bad version %q in constraint %q", rest, c)
	}
	return nil
}

// ParseRevocationList parses and validates revocations.json (no signature
// check; use VerifyRevocationList for the trusted path).
func ParseRevocationList(data []byte) (*RevocationList, error) {
	if len(data) == 0 || len(data) > maxRevocationBytes {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: the revocation list has a bad size (%d bytes)", len(data))
	}
	var l RevocationList
	dec := json.NewDecoder(strings.NewReader(string(data)))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&l); err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: the revocation list is not valid JSON: %v", err)
	}
	if l.Version != RevocationVersion {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: unsupported revocation_version %d (want %d)", l.Version, RevocationVersion)
	}
	if l.UpdatedAt.IsZero() || l.ExpiresAt.IsZero() {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: the revocation list needs updated_at and expires_at")
	}
	if !l.ExpiresAt.After(l.UpdatedAt) {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: the revocation list expires before it was updated")
	}
	if len(l.Entries) > maxRevocationEntries {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
			"ext: the revocation list has too many entries (%d)", len(l.Entries))
	}
	seen := map[string]bool{}
	for i, e := range l.Entries {
		if !idPattern.MatchString(e.ID) {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
				"ext: revocation entry %d has a bad id %q", i, e.ID)
		}
		if err := checkVersionConstraint(e.Versions); err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
				"ext: revocation entry %d (%s): %v", i, e.ID, err)
		}
		if len(e.Reason) > 280 {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
				"ext: revocation entry %d (%s) has too long a reason", i, e.ID)
		}
		key := e.ID + "\x00" + e.Versions
		if seen[key] {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyRevocationInvalid,
				"ext: duplicate revocation entry for %s %s", e.ID, e.Versions)
		}
		seen[key] = true
	}
	return &l, nil
}

// VerifyRevocationList verifies revocations.json.minisig with the team key
// and parses the list. It fails closed while the key ceremony is pending,
// exactly like the catalog signature.
func VerifyRevocationList(sigText string, payload []byte) (*RevocationList, error) {
	if !SigningConfigured() {
		return nil, errs.Newf(errs.CodeUnavailable, KeySigningUnconfigured,
			"ext: team signing is not configured yet: cannot trust a revocation list until the key ceremony is done.")
	}
	if err := VerifyPayload(TeamPublicKey, sigText, sigFileRevocations, payload); err != nil {
		return nil, err
	}
	return ParseRevocationList(payload)
}
