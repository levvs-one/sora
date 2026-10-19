package ext

import (
	"crypto/ed25519"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/errs"
)

// TeamPublicKey is the minisign public key that signs the team catalog and
// the team-published extensions.
//
// It is intentionally a placeholder: the owner must complete the key
// ceremony (FIX-PLAN.md, section 9) before any team-signed artifact can be
// trusted. Every team-signature check fails closed until then — the same rule
// as packaging/install/install.sh.
const TeamPublicKey = "UNTRUSTED COMMENT: Sora team catalog key — PLACEHOLDER, key ceremony pending\n" +
	"RWRPLACEHOLDERPLACEHOLDERPLACEHOLDERPLACEHOLDERPLACEHOLDER00"

// placeholderMarker detects the un-configured team key.
const placeholderMarker = "PLACEHOLDER"

// SigningConfigured reports whether the team key ceremony is done.
func SigningConfigured() bool {
	return !strings.Contains(TeamPublicKey, placeholderMarker)
}

// ParsePublicKey parses the "<base64>" line of a minisign .pub file and
// returns the key id and the 32-byte ed25519 public key.
func ParsePublicKey(line string) (keyID [8]byte, pub [32]byte, err error) {
	raw, err := base64.StdEncoding.DecodeString(strings.TrimSpace(line))
	if err != nil {
		return keyID, pub, errs.Newf(errs.CodeInvalidArgument, KeySignatureInvalid,
			"ext: the public key is not base64: %v", err)
	}
	// Minisign .pub envelope: "Ed" (signature algorithm) || key id (8) ||
	// ed25519 public key (32) = 42 bytes.
	if len(raw) != 42 || raw[0] != 'E' || raw[1] != 'd' {
		return keyID, pub, errs.Newf(errs.CodeInvalidArgument, KeySignatureInvalid,
			"ext: the public key has a bad envelope (want 42 bytes starting with \"Ed\", got %d)", len(raw))
	}
	copy(keyID[:], raw[2:10])
	copy(pub[:], raw[10:42])
	return keyID, pub, nil
}

// minisignSignature is a parsed .minisig: the raw signature and the exact
// trusted-comment bytes it covers.
type minisignSignature struct {
	sig            [64]byte
	trustedComment []byte
}

// ParseSignature parses a minisign .minisig text (2+ lines).
func ParseSignature(text string) (*minisignSignature, error) {
	lines := strings.Split(strings.ReplaceAll(strings.TrimSpace(text), "\r\n", "\n"), "\n")
	if len(lines) < 2 {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeySignatureInvalid,
			"ext: the signature file is truncated (want at least 2 lines)")
	}
	if !strings.HasPrefix(lines[0], "untrusted comment:") {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeySignatureInvalid,
			"ext: the signature file must start with an \"untrusted comment:\" line")
	}
	raw, err := base64.StdEncoding.DecodeString(strings.TrimSpace(lines[1]))
	if err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeySignatureInvalid,
			"ext: the signature is not base64: %v", err)
	}
	if len(raw) < 65 {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeySignatureInvalid,
			"ext: the signature blob is truncated (got %d bytes)", len(raw))
	}
	var out minisignSignature
	copy(out.sig[:], raw[:64])
	out.trustedComment = append([]byte(nil), raw[64:]...)
	return &out, nil
}

// verifyRaw checks an ed25519 signature over exactly trustedComment.
func verifyRaw(pub [32]byte, sig *minisignSignature) error {
	if !ed25519.Verify(ed25519.PublicKey(pub[:]), sig.trustedComment, sig.sig[:]) {
		return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
			"ext: the signature is not valid for this key")
	}
	return nil
}

// Trusted comment format for packages and the catalog:
//
//	timestamp:<unix-seconds>\tfile:<name>\tsha256:<hex>
//
// The sha256 binds the signature to the exact payload bytes: flipping one
// byte anywhere breaks verification.
const (
	sigFileChecksums = "checksums.txt"
	sigFileCatalog   = "catalog.json"
)

// makeTrustedComment builds the canonical trusted comment.
func makeTrustedComment(timestamp int64, file, shaHex string) []byte {
	return []byte("timestamp:" + strconv.FormatInt(timestamp, 10) + "\tfile:" + file + "\tsha256:" + shaHex)
}

// parseTrustedComment extracts the timestamp, file name and sha256 from a
// trusted comment, rejecting anything else.
func parseTrustedComment(tc []byte) (timestamp int64, file, shaHex string, err error) {
	parts := strings.Split(string(tc), "\t")
	if len(parts) != 3 {
		return 0, "", "", errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
			"ext: the trusted comment has a bad shape")
	}
	if !strings.HasPrefix(parts[0], "timestamp:") || !strings.HasPrefix(parts[1], "file:") || !strings.HasPrefix(parts[2], "sha256:") {
		return 0, "", "", errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
			"ext: the trusted comment has bad fields")
	}
	ts, err := strconv.ParseInt(strings.TrimPrefix(parts[0], "timestamp:"), 10, 64)
	if err != nil || ts <= 0 {
		return 0, "", "", errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
			"ext: the trusted comment has a bad timestamp")
	}
	shaHex = strings.TrimPrefix(parts[2], "sha256:")
	if len(shaHex) != 64 {
		return 0, "", "", errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
			"ext: the trusted comment has a bad sha256")
	}
	if _, err := hex.DecodeString(shaHex); err != nil {
		return 0, "", "", errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
			"ext: the trusted comment sha256 is not hex: %v", err)
	}
	return ts, strings.TrimPrefix(parts[1], "file:"), shaHex, nil
}

// VerifyPayload verifies that sigText is a minisign signature by pubKeyLine
// for payload, whose role is named by file (e.g. "checksums.txt").
// The check is: parse sig -> trusted comment names file and its sha256 ->
// sha256(payload) matches (constant time) -> ed25519 verifies.
func VerifyPayload(pubKeyLine, sigText string, file string, payload []byte) error {
	_, pub, err := ParsePublicKey(pubKeyLine)
	if err != nil {
		return err
	}
	sig, err := ParseSignature(sigText)
	if err != nil {
		return err
	}
	_, name, shaHex, err := parseTrustedComment(sig.trustedComment)
	if err != nil {
		return err
	}
	if subtle.ConstantTimeCompare([]byte(name), []byte(file)) != 1 {
		return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
			"ext: the signature is for %q, not %q", name, file)
	}
	sum := sha256.Sum256(payload)
	claimed, _ := hex.DecodeString(shaHex)
	if subtle.ConstantTimeCompare(sum[:], claimed) != 1 {
		return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
			"ext: the payload does not match the signed sha256 — the package was modified")
	}
	return verifyRaw(pub, sig)
}

// VerifyPackageSignature verifies the signature.minisig of a .soraext
// against the author's key from the manifest and the checksums.txt bytes.
func VerifyPackageSignature(authorKeyLine, sigText string, checksums []byte) error {
	return VerifyPayload(authorKeyLine, sigText, sigFileChecksums, checksums)
}

// VerifyCatalogSignature verifies a catalog.json.minisig with the team key.
// It fails closed while the key ceremony is pending.
func VerifyCatalogSignature(sigText string, catalogJSON []byte) error {
	if !SigningConfigured() {
		return errs.Newf(errs.CodeUnavailable, KeySigningUnconfigured,
			"ext: team signing is not configured yet: the minisign public key is still a placeholder. "+
				"The owner must complete the key ceremony (FIX-PLAN.md, section 9) before team-signed artifacts can be trusted.")
	}
	return VerifyPayload(TeamPublicKey, sigText, sigFileCatalog, catalogJSON)
}

// SignPayload creates a minisign-format signature text for payload using a
// 64-byte ed25519 seed. It exists for tests and for the reference packager;
// real releases are signed with the offline team/author keys via minisign.
func SignPayload(seed []byte, keyIDComment, file string, timestamp int64, payload []byte) (string, error) {
	if len(seed) != ed25519.SeedSize {
		return "", errs.Newf(errs.CodeInvalidArgument, KeySignatureInvalid,
			"ext: the seed must be %d bytes", ed25519.SeedSize)
	}
	priv := ed25519.NewKeyFromSeed(seed)
	sum := sha256.Sum256(payload)
	tc := makeTrustedComment(timestamp, file, hex.EncodeToString(sum[:]))
	sig := ed25519.Sign(priv, tc)
	blob := append(append([]byte(nil), sig...), tc...)
	var b strings.Builder
	b.WriteString("untrusted comment: " + keyIDComment + "\n")
	b.WriteString(base64.StdEncoding.EncodeToString(blob) + "\n")
	b.WriteString("trusted comment: " + string(tc) + "\n")
	return b.String(), nil
}
