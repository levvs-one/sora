package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"regexp"
	"sort"
	"strings"

	"github.com/levvs-one/sora-client/core/ext"
)

// This is the existing team trust root from app/lib/src/ext/verifier.dart.
// Verification never accepts a key from the download directory or command line.
const releasePublicKey = "RWQZfr8pZOLhNx/81iyyYi91cZMQTyJece9fX9OWIJoUqMPpN7eCYk/+"

var releaseVersionPattern = regexp.MustCompile(`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$`)
var releaseChecksumPattern = regexp.MustCompile(`^([0-9a-fA-F]{64}) [ *](.+)$`)
var releaseHashPattern = regexp.MustCompile(`^[0-9a-f]{64}$`)

// Field order is part of schema 1's canonical Python/Dart/Go wire format.
type releaseArtifact struct {
	Arch   string `json:"arch"`
	Name   string `json:"name"`
	OS     string `json:"os"`
	SHA256 string `json:"sha256"`
	Size   int64  `json:"size"`
}

type releaseMetadata struct {
	Artifacts []releaseArtifact `json:"artifacts"`
	Schema    int               `json:"schema"`
	Version   string            `json:"version"`
}

type releaseManifest struct {
	payload       []byte
	signature     []byte
	metadataBytes []byte
	metadata      *releaseMetadata
}

func verifyRelease(directory, version, publicKey string) (*releaseManifest, error) {
	if !releaseVersionPattern.MatchString(version) || len(version) > 64 {
		return nil, fmt.Errorf("release: invalid stable version")
	}
	root, err := os.OpenRoot(directory)
	if err != nil {
		return nil, fmt.Errorf("release: %w", err)
	}
	defer func() { _ = root.Close() }()
	payload, err := readReleaseFile(root, "SHA256SUMS", 1024*1024)
	if err != nil {
		return nil, err
	}
	signature, err := readReleaseFile(root, "SHA256SUMS.minisig", 8192)
	if err != nil {
		return nil, err
	}
	if err := ext.VerifyPayload(publicKey, string(signature), "release:v"+version+":SHA256SUMS", payload); err != nil {
		return nil, fmt.Errorf("release: untrusted SHA256SUMS: %w", err)
	}
	manifest := &releaseManifest{payload: payload, signature: signature}
	if _, err := releaseChecksum(payload, "release.json"); err != nil {
		return nil, fmt.Errorf("release: schema 1 metadata is required: %w", err)
	}
	data, err := readReleaseFile(root, "release.json", 1024*1024)
	if err != nil {
		return nil, err
	}
	manifest.metadata, err = parseReleaseMetadata(data, payload, version)
	if err != nil {
		return nil, err
	}
	manifest.metadataBytes = data
	return manifest, nil
}

func (manifest *releaseManifest) verifyArtifactFiles(ctx context.Context, directory string) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	// Schema 1 has fifteen distinct allowed names: Windows, two scripts and
	// twelve Linux packages. Publication requires that complete supported matrix.
	if manifest.metadata == nil || len(manifest.metadata.Artifacts) != 15 {
		return fmt.Errorf("release: full verification requires the complete schema 1 artifact matrix")
	}
	root, err := os.OpenRoot(directory)
	if err != nil {
		return err
	}
	defer func() { _ = root.Close() }()
	expected := map[string]bool{"SHA256SUMS": true, "SHA256SUMS.minisig": true, "release.json": true}
	for _, artifact := range manifest.metadata.Artifacts {
		expected[artifact.Name] = true
		if err := verifyReleaseArtifactFile(ctx, root, artifact); err != nil {
			return err
		}
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	for name, authenticated := range map[string][]byte{
		"SHA256SUMS": manifest.payload, "SHA256SUMS.minisig": manifest.signature, "release.json": manifest.metadataBytes,
	} {
		current, err := readReleaseFile(root, name, int64(len(authenticated)))
		if err != nil || !bytes.Equal(current, authenticated) {
			return fmt.Errorf("release: %s changed after authentication", name)
		}
	}
	entries, err := root.Open(".")
	if err != nil {
		return err
	}
	defer func() { _ = entries.Close() }()
	// Read at most the expected count plus one, even for an attacker-sized dir.
	names, err := entries.Readdirnames(len(expected) + 1)
	if err != nil && !errors.Is(err, io.EOF) {
		return err
	}
	if len(names) != len(expected) {
		return fmt.Errorf("release: snapshot has missing or unlisted files")
	}
	for _, name := range names {
		if !expected[name] {
			return fmt.Errorf("release: snapshot has an unlisted file")
		}
	}
	return ctx.Err()
}

func verifyReleaseArtifactFile(ctx context.Context, root *os.Root, artifact releaseArtifact) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	info, err := root.Lstat(artifact.Name)
	if err != nil {
		return err
	}
	if !info.Mode().IsRegular() || info.Size() != artifact.Size {
		return fmt.Errorf("release: %s is not a regular file of the signed size", artifact.Name)
	}
	file, err := root.Open(artifact.Name)
	if err != nil {
		return err
	}
	defer func() { _ = file.Close() }()
	// NotifyContext otherwise swallows Ctrl+C while a large local hash runs.
	stop := context.AfterFunc(ctx, func() { _ = file.Close() })
	defer stop()
	opened, err := file.Stat()
	if err != nil || !os.SameFile(info, opened) || info.Size() != opened.Size() {
		return fmt.Errorf("release: %s changed while opening", artifact.Name)
	}
	digest := sha256.New()
	count, err := io.Copy(digest, io.LimitReader(file, artifact.Size+1))
	if err := ctx.Err(); err != nil {
		return err
	}
	if err != nil || count != artifact.Size || fmt.Sprintf("%x", digest.Sum(nil)) != artifact.SHA256 {
		return fmt.Errorf("release: %s checksum or size mismatch", artifact.Name)
	}
	after, err := file.Stat()
	if err != nil || after.Size() != info.Size() || !after.ModTime().Equal(info.ModTime()) {
		return fmt.Errorf("release: %s changed while hashing", artifact.Name)
	}
	return nil
}

func parseReleaseMetadata(data, payload []byte, version string) (*releaseMetadata, error) {
	digest := fmt.Sprintf("%x", sha256.Sum256(data))
	expected, err := releaseChecksum(payload, "release.json")
	if err != nil || digest != expected {
		return nil, fmt.Errorf("release: metadata checksum mismatch")
	}
	var metadata releaseMetadata
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&metadata); err != nil {
		return nil, fmt.Errorf("release: invalid metadata: %w", err)
	}
	if metadata.Schema != 1 || metadata.Version != version || len(metadata.Artifacts) == 0 || len(metadata.Artifacts) > 128 {
		return nil, fmt.Errorf("release: unsupported metadata version or artifact count")
	}
	hashes := map[string]string{"release.json": digest}
	previous := ""
	for _, artifact := range metadata.Artifacts {
		osName, arch := releaseArtifactTarget(artifact.Name, version)
		if artifact.Name <= previous || osName == "" || artifact.OS != osName || artifact.Arch != arch ||
			artifact.Size < 1 || artifact.Size > 2*1024*1024*1024 || !releaseHashPattern.MatchString(artifact.SHA256) {
			return nil, fmt.Errorf("release: invalid artifact metadata")
		}
		previous = artifact.Name
		hashes[artifact.Name] = artifact.SHA256
	}
	canonical, err := json.Marshal(metadata)
	if err != nil || !bytes.Equal(append(canonical, '\n'), data) {
		return nil, fmt.Errorf("release: noncanonical metadata")
	}
	names := make([]string, 0, len(hashes))
	for name := range hashes {
		names = append(names, name)
	}
	sort.Strings(names)
	var checksums strings.Builder
	for _, name := range names {
		fmt.Fprintf(&checksums, "%s  %s\n", hashes[name], name)
	}
	if checksums.String() != string(payload) {
		return nil, fmt.Errorf("release: metadata and checksum manifest disagree")
	}
	return &metadata, nil
}

func releaseChecksum(payload []byte, name string) (string, error) {
	value, count := "", 0
	for _, line := range strings.Split(string(payload), "\n") {
		match := releaseChecksumPattern.FindStringSubmatch(strings.TrimSuffix(line, "\r"))
		if match != nil && match[2] == name {
			value, count = strings.ToLower(match[1]), count+1
		}
	}
	if count != 1 {
		return "", fmt.Errorf("release: missing or duplicate artifact checksum")
	}
	return value, nil
}

func (manifest *releaseManifest) artifactSize(name, target, version string) (int64, error) {
	osName, arch := releaseArtifactTarget(name, version)
	if osName == "" || osName+"/"+arch != target || arch == "any" {
		return 0, fmt.Errorf("release: artifact does not match the requested target")
	}
	if _, err := releaseChecksum(manifest.payload, name); err != nil {
		return 0, err
	}
	if manifest.metadata == nil {
		return 0, fmt.Errorf("release: artifact sizes require schema 1 metadata")
	}
	for _, artifact := range manifest.metadata.Artifacts {
		if artifact.Name == name {
			return artifact.Size, nil
		}
	}
	return 0, fmt.Errorf("release: artifact is not in metadata")
}

func releaseArtifactTarget(name, version string) (string, string) {
	if name == "Sora-Setup-"+version+"-x64.exe" {
		return "windows", "amd64"
	}
	if name == "install.ps1" {
		return "windows", "any"
	}
	if name == "install.sh" {
		return "linux", "any"
	}
	for _, pair := range [][2]string{{"amd64", "x86_64"}, {"arm64", "aarch64"}} {
		for _, pkg := range []string{"sora-core", "sora"} {
			if name == pkg+"_"+version+"_"+pair[0]+".deb" || name == pkg+"-"+version+"-1."+pair[1]+".rpm" ||
				name == pkg+"-"+version+"-1-"+pair[1]+".pkg.tar.zst" {
				return "linux", pair[0]
			}
		}
	}
	return "", ""
}

func readReleaseFile(root *os.Root, name string, limit int64) ([]byte, error) {
	info, err := root.Lstat(name)
	if err != nil {
		return nil, fmt.Errorf("release: %w", err)
	}
	if !info.Mode().IsRegular() || info.Size() == 0 || info.Size() > limit {
		return nil, fmt.Errorf("release: %s must be a nonempty regular file of at most %d bytes", name, limit)
	}
	file, err := root.Open(name)
	if err != nil {
		return nil, fmt.Errorf("release: %w", err)
	}
	defer func() { _ = file.Close() }()
	opened, err := file.Stat()
	if err != nil {
		return nil, err
	}
	if !os.SameFile(info, opened) {
		return nil, fmt.Errorf("release: %s changed while opening", name)
	}
	data, err := io.ReadAll(io.LimitReader(file, limit+1))
	if err != nil {
		return nil, err
	}
	if len(data) == 0 || int64(len(data)) > limit {
		return nil, fmt.Errorf("release: invalid %s size", name)
	}
	return data, nil
}
