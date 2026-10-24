package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"

	"github.com/levvs-one/sora-client/core/ext"
)

// This is the existing team trust root from app/lib/src/ext/verifier.dart.
// Verification never accepts a key from the download directory or command line.
const releasePublicKey = "RWQZfr8pZOLhNx/81iyyYi91cZMQTyJece9fX9OWIJoUqMPpN7eCYk/+"

var releaseVersionPattern = regexp.MustCompile(`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$`)

func verifyRelease(directory, version, publicKey string) error {
	if !releaseVersionPattern.MatchString(version) || len(version) > 64 {
		return fmt.Errorf("release: invalid stable version")
	}
	payload, err := readReleaseFile(filepath.Join(directory, "SHA256SUMS"), 1024*1024)
	if err != nil {
		return err
	}
	signature, err := readReleaseFile(filepath.Join(directory, "SHA256SUMS.minisig"), 8192)
	if err != nil {
		return err
	}
	if err := ext.VerifyPayload(publicKey, string(signature), "release:v"+version+":SHA256SUMS", payload); err != nil {
		return fmt.Errorf("release: untrusted SHA256SUMS: %w", err)
	}
	return nil
}

func readReleaseFile(path string, limit int64) ([]byte, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return nil, fmt.Errorf("release: %w", err)
	}
	if !info.Mode().IsRegular() || info.Size() == 0 || info.Size() > limit {
		return nil, fmt.Errorf("release: %s must be a nonempty regular file of at most %d bytes", filepath.Base(path), limit)
	}
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("release: %w", err)
	}
	defer file.Close()
	opened, err := file.Stat()
	if err != nil {
		return nil, err
	}
	if !os.SameFile(info, opened) {
		return nil, fmt.Errorf("release: %s changed while opening", filepath.Base(path))
	}
	data, err := io.ReadAll(io.LimitReader(file, limit+1))
	if err != nil {
		return nil, err
	}
	if len(data) == 0 || int64(len(data)) > limit {
		return nil, fmt.Errorf("release: invalid %s size", filepath.Base(path))
	}
	return data, nil
}
