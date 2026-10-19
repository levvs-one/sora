package supervise

import (
	"bytes"
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// Binary is one engine build on disk that has been probed successfully.
type Binary struct {
	Kind      engine.Kind
	Path      string
	Version   engine.Version
	Goos      string
	Goarch    string
	BuildTags []string
}

// Prober describes how to recognize one engine binary.
type Prober struct {
	Kind engine.Kind
	// Name is the executable name without extension, for example
	// "sing-box".
	Name string
	// EnvVar overrides the discovered binary path. It is read only during
	// discovery, and the binary is still probed.
	EnvVar string
	// Args make the binary print its version, for example ["version"].
	Args []string
	// Pattern matches the first line of the version output. Group 1 is the
	// version; optional groups 2 and 3 are GOOS and GOARCH.
	Pattern *regexp.Regexp
}

// Probe runs version arguments and verifies the binary's identity before use.
func (pr Prober) Probe(ctx context.Context, path string) (Binary, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, path, pr.Args...) //nolint:gosec // path is a discovery candidate and the arguments are literals
	HideWindow(cmd)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out
	if err := cmd.Run(); err != nil {
		return Binary{}, fmt.Errorf("%s: probe failed: %w: %s", pr.Kind, err, strings.TrimSpace(out.String()))
	}
	first, _, _ := strings.Cut(strings.TrimSpace(out.String()), "\n")
	match := pr.Pattern.FindStringSubmatch(strings.TrimSpace(first))
	if match == nil {
		return Binary{}, fmt.Errorf("%s: unexpected version output %q", pr.Kind, first)
	}
	version, err := engine.ParseVersion(match[1])
	if err != nil {
		return Binary{}, err
	}
	b := Binary{Kind: pr.Kind, Path: path, Version: version, Goos: runtime.GOOS, Goarch: runtime.GOARCH}
	for _, line := range strings.Split(out.String(), "\n") {
		if tags, ok := strings.CutPrefix(strings.TrimSpace(line), "Tags:"); ok {
			b.BuildTags = strings.Split(strings.TrimSpace(tags), ",")
		}
	}
	if len(match) > 3 && match[2] != "" && match[3] != "" {
		b.Goos, b.Goarch = match[2], match[3]
	}
	return b, nil
}

// digestsFile is the manifest fetch.sh writes next to the installed engine
// binaries: "<sha256>  <name>" lines (sha256sum format) over the binaries
// themselves, not the download archives.
const digestsFile = "engines.digests"

// DiscoveryOptions tunes engine discovery.
type DiscoveryOptions struct {
	// AllowEnvBin honors the SORA_*_BIN environment overrides. Only set it
	// from an explicit operator flag (--allow-env-bin): the operator takes
	// responsibility for the pointed-at binary. Without it, discovery
	// trusts only the digest-verified engines directory.
	AllowEnvBin bool
}

// Discover checks the environment override (only with
// DiscoveryOptions.AllowEnvBin) and then the engines directory. It never
// consults PATH: a planted binary earlier in PATH must not become the VPN
// engine (SORA-H5). Every candidate from the engines directory must match
// the digest in engines.digests; candidates that fail verification are
// rejected instead of executed.
func (pr Prober) Discover(ctx context.Context, enginesDir string, opts DiscoveryOptions) (Binary, error) {
	type candidate struct {
		path   string
		fromEnv bool
	}
	var candidates []candidate
	if opts.AllowEnvBin {
		if fromEnv := os.Getenv(pr.EnvVar); pr.EnvVar != "" && fromEnv != "" {
			candidates = append(candidates, candidate{path: fromEnv, fromEnv: true})
		}
	}
	file := pr.Name
	if runtime.GOOS == "windows" {
		file += ".exe"
	}
	if enginesDir != "" {
		candidates = append(candidates, candidate{path: filepath.Join(enginesDir, file)})
	}
	if len(candidates) == 0 {
		return Binary{}, fmt.Errorf("%s: no candidate: set %s with --allow-env-bin or install the engine into %q", pr.Kind, pr.EnvVar, enginesDir)
	}
	digests, digestsErr := loadDigests(enginesDir)
	lastErr := errors.New("no candidate")
	for _, c := range candidates {
		info, err := os.Stat(c.path) //nolint:gosec // candidates are the Sora engines dir or an operator-set env var
		if err != nil || info.IsDir() {
			lastErr = fmt.Errorf("%s is not a file", c.path)
			continue
		}
		probed, err := pr.Probe(ctx, c.path)
		if err != nil {
			lastErr = err
			continue
		}
		if err := checkDigest(probed, digests, digestsErr, c.fromEnv); err != nil {
			lastErr = err
			continue
		}
		return probed, nil
	}
	return Binary{}, fmt.Errorf("%s: no usable engine binary (%w); set %s with --allow-env-bin or install it into %q", pr.Kind, lastErr, pr.EnvVar, enginesDir)
}

// checkDigest enforces the digest manifest for engines-directory candidates.
// Environment-override candidates are the operator's explicit trust, but are
// still verified when the manifest knows their binary name.
func checkDigest(b Binary, digests map[string]string, digestsErr error, fromEnv bool) error {
	name := strings.ToLower(strings.TrimSuffix(filepath.Base(b.Path), ".exe"))
	if expected, ok := digests[name]; ok {
		return b.VerifyDigest(expected)
	}
	if fromEnv {
		// The operator explicitly pointed at this binary with
		// --allow-env-bin; no manifest entry to check it against.
		return nil
	}
	if digestsErr != nil {
		return fmt.Errorf("%s: refusing %s: %v", b.Kind, b.Path, digestsErr)
	}
	return fmt.Errorf("%s: refusing %s: no digest for %q in engines.digests", b.Kind, b.Path, name)
}

// loadDigests reads the engines.digests manifest from the engines directory.
// It returns the underlying error so callers can fail closed with context.
func loadDigests(enginesDir string) (map[string]string, error) {
	if enginesDir == "" {
		return nil, errors.New("no engines directory")
	}
	raw, err := os.ReadFile(filepath.Join(enginesDir, digestsFile))
	if err != nil {
		return nil, fmt.Errorf("cannot read engines.digests: %w; refresh the engines with the updater or packaging/engines/fetch.sh", err)
	}
	out := map[string]string{}
	for _, line := range strings.Split(string(raw), "\n") {
		fields := strings.Fields(line)
		if len(fields) < 2 || len(fields[0]) != 64 {
			continue
		}
		out[strings.ToLower(strings.TrimSuffix(fields[1], ".exe"))] = strings.ToLower(fields[0])
	}
	return out, nil
}

// VerifyDigest compares the binary against the checksum the updater recorded.
func (b Binary) VerifyDigest(expected string) error {
	if expected == "" {
		return fmt.Errorf("%s: no expected digest", b.Kind)
	}
	raw, err := os.ReadFile(b.Path)
	if err != nil {
		return fmt.Errorf("%s: read binary: %w", b.Kind, err)
	}
	sum := sha256.Sum256(raw)
	got := hex.EncodeToString(sum[:])
	if subtle.ConstantTimeCompare([]byte(got), []byte(strings.ToLower(strings.TrimSpace(expected)))) != 1 {
		return fmt.Errorf("%s: digest mismatch: got %s", b.Kind, got)
	}
	return nil
}
