package ext

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"strconv"
	"strings"

	"aead.dev/minisign"

	"github.com/levvs-one/sora-client/core/errs"
)

// TeamPublicKey verifies the team catalog and revocation list. Its secret
// half signs extensions/catalog.json and extensions/revocations.json with
// `sora-ext sign-file`; the app carries the same key (ext/verifier.dart).
const TeamPublicKey = "RWQZfr8pZOLhNx/81iyyYi91cZMQTyJece9fX9OWIJoUqMPpN7eCYk/+"

// SigningConfigured reports whether a valid team public key is configured.
func SigningConfigured() bool {
	_, _, err := ParsePublicKey(TeamPublicKey)
	return err == nil
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
	var pub minisign.PublicKey
	if err := pub.UnmarshalText([]byte(strings.TrimSpace(pubKeyLine))); err != nil {
		return err
	}
	var sig minisign.Signature
	if err := sig.UnmarshalText([]byte(strings.TrimSpace(sigText))); err != nil {
		return err
	}
	_, name, shaHex, err := parseTrustedComment([]byte(sig.TrustedComment))
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
			"ext: the payload does not match the signed sha256 - the package was modified")
	}
	if !minisign.Verify(pub, payload, []byte(strings.TrimSpace(sigText))) {
		return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid, "ext: invalid minisign payload or trusted-comment signature")
	}
	return nil
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
			"ext: team signing is not configured yet: no team public key is configured. "+
				"The owner must complete the key ceremony (FIX-PLAN.md, section 9) before team-signed artifacts can be trusted.")
	}
	return VerifyPayload(TeamPublicKey, sigText, sigFileCatalog, catalogJSON)
}

// SignPayload signs both the payload and its role, timestamp and digest.
func SignPayload(key minisign.PrivateKey, keyIDComment, file string, timestamp int64, payload []byte) (string, error) {
	if key.Equal(minisign.PrivateKey{}) || timestamp <= 0 || file == "" || strings.ContainsAny(file+keyIDComment, "\r\n\t") {
		return "", errs.Newf(errs.CodeInvalidArgument, KeySignatureInvalid, "ext: invalid signing key or signature metadata")
	}
	sum := sha256.Sum256(payload)
	tc := makeTrustedComment(timestamp, file, hex.EncodeToString(sum[:]))
	return string(minisign.SignWithComments(key, payload, string(tc), keyIDComment)), nil
}
