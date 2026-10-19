package control

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
)

// TokenLen is the control token length in bytes. Connect and Disconnect carry
// raw bytes; any other length is rejected.
const TokenLen = 32

// tokenFile stores the control token in the core data directory with owner-only
// read access for client authentication.
const tokenFile = "control.token"

// Authenticator checks tokens in constant time. The token file's owner-only
// mode is a cross-user barrier only: it does not stop processes running as
// the same user. Same-account callers are distinguished by the transport
// peer credentials (see core/ipc/authlevel.go), not by this file's mode.
type Authenticator struct {
	mu    sync.RWMutex
	token []byte
	// path is the token file Rotate persists to. It is empty for
	// authenticators built directly from a token (tests); rotation then
	// fails closed instead of splitting memory and disk.
	path string
}

// NewAuthenticator returns an authenticator for an existing token. The token is
// copied, so the caller may wipe its own.
func NewAuthenticator(token []byte) (*Authenticator, error) {
	if len(token) != TokenLen {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyUnauthenticated,
			"control: the authenticator must be %d bytes, got %d", TokenLen, len(token))
	}
	return &Authenticator{token: append([]byte(nil), token...)}, nil
}

// LoadOrCreateToken loads the data directory's token or creates it on first
// start. Invalid existing files are rejected to expose corruption and avoid
// disconnecting clients.
func LoadOrCreateToken(dir string) (*Authenticator, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyUnauthenticated,
			"control: no data directory for the authenticator")
	}
	path := filepath.Join(dir, tokenFile)
	raw, err := os.ReadFile(path) //nolint:gosec // a fixed file name inside the data directory of the core
	switch {
	case err == nil:
		token, decodeErr := base64.StdEncoding.DecodeString(strings.TrimSpace(string(raw)))
		if decodeErr != nil || len(token) != TokenLen {
			return nil, errs.Newf(errs.CodeInternal, errs.KeyUnauthenticated,
				"control: the stored authenticator is not readable")
		}
		return &Authenticator{token: append([]byte(nil), token...), path: path}, nil
	case !errors.Is(err, fs.ErrNotExist):
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyUnauthenticated)
	}
	token := make([]byte, TokenLen)
	if _, err := rand.Read(token); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyUnauthenticated)
	}
	encoded := []byte(base64.StdEncoding.EncodeToString(token))
	if err := writeOwnerOnly(path, encoded); err != nil {
		return nil, err
	}
	return &Authenticator{token: append([]byte(nil), token...), path: path}, nil
}

// Verify checks a token in constant time after rejecting an invalid length.
func (a *Authenticator) Verify(presented []byte) bool {
	if a == nil || len(presented) != TokenLen {
		return false
	}
	a.mu.RLock()
	expected := a.token
	a.mu.RUnlock()
	if len(expected) != TokenLen {
		return false
	}
	return subtle.ConstantTimeCompare(presented, expected) == 1
}

// Check returns the catalog error when token verification fails.
func (a *Authenticator) Check(presented []byte) error {
	if a.Verify(presented) {
		return nil
	}
	return errs.Newf(errs.CodeUnauthenticated, errs.KeyUnauthenticated,
		"control: the presented authenticator does not match")
}

// Token returns a copy of the token for Handshake clients admitted by the
// transport.
func (a *Authenticator) Token() []byte {
	a.mu.RLock()
	defer a.mu.RUnlock()
	return append([]byte(nil), a.token...)
}

// Rotate replaces and returns the token without restarting the core. The new
// token is persisted atomically before it takes effect, so a restart keeps
// the rotation and the old token stays invalid. All existing client tokens
// become invalid.
func (a *Authenticator) Rotate() ([]byte, error) {
	fresh := make([]byte, TokenLen)
	if _, err := rand.Read(fresh); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyUnauthenticated)
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	if a.path == "" {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyUnauthenticated,
			"control: the authenticator has no token file to persist the rotation")
	}
	encoded := []byte(base64.StdEncoding.EncodeToString(fresh))
	// Persist before swapping: a failed write leaves the old token valid on
	// disk and in memory, never a split between the two.
	if err := writeOwnerOnly(a.path, encoded); err != nil {
		return nil, err
	}
	a.token = append([]byte(nil), fresh...)
	return append([]byte(nil), fresh...), nil
}

// writeOwnerOnly stores a file that only the owner may read, replacing it
// atomically (temp file, fsync, rename) so a torn write never leaves a
// half-written secret behind.
func writeOwnerOnly(path string, data []byte) error {
	wrap := func(err error) error {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyUnauthenticated)
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), filepath.Base(path)+".tmp-*")
	if err != nil {
		return wrap(err)
	}
	tmpName := tmp.Name()
	defer func() { _ = os.Remove(tmpName) }()
	if err := tmp.Chmod(0o600); err != nil {
		_ = tmp.Close()
		return wrap(err)
	}
	if _, err := tmp.Write(data); err != nil {
		_ = tmp.Close()
		return wrap(err)
	}
	if err := tmp.Sync(); err != nil {
		_ = tmp.Close()
		return wrap(err)
	}
	if err := tmp.Close(); err != nil {
		return wrap(err)
	}
	if err := os.Rename(tmpName, path); err != nil {
		return wrap(err)
	}
	return nil
}
