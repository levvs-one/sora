// Package olcrtc chains supervised olcrtc clients with a forwarding engine.
package olcrtc

import (
	"context"
	"debug/buildinfo"
	"encoding/json"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Revision pins the upstream wire implementation, including OLC2 and OLVC v5.
const Revision = "f3ad8fb7c0d0fa981423f83269526fa94077c23d"

// Discover verifies the source identity and the digest recorded at packaging.
// olcrtc has no version flag: every single argument is interpreted as a path.
func Discover(_ context.Context, dir string) (supervise.Binary, error) {
	name := "olcrtc"
	if runtime.GOOS == "windows" {
		name += ".exe"
	}
	candidates := []string{os.Getenv("SORA_OLCRTC_BIN")}
	if dir != "" {
		candidates = append(candidates, filepath.Join(dir, name))
	}
	if path, err := exec.LookPath(name); err == nil {
		candidates = append(candidates, path)
	}
	for _, path := range candidates {
		if path == "" {
			continue
		}
		path, err := filepath.Abs(path)
		if err != nil {
			continue
		}
		info, err := buildinfo.ReadFile(path)
		if err != nil || info.Path != "github.com/openlibrecommunity/olcrtc/cmd/olcrtc" {
			continue
		}
		targetOS, targetArch := "", ""
		for _, setting := range info.Settings {
			switch setting.Key {
			case "GOOS":
				targetOS = setting.Value
			case "GOARCH":
				targetArch = setting.Value
			}
		}
		if targetOS != runtime.GOOS || targetArch != runtime.GOARCH {
			continue
		}
		if runtime.GOOS != "windows" {
			if stat, err := os.Stat(path); err != nil || stat.Mode().Perm()&0111 == 0 { //nolint:gosec // discovery paths come from the service engines directory, PATH or an operator override
				continue
			}
		}
		var manifest struct {
			Revision string
			SHA256   string
		}
		data, err := os.ReadFile(path + ".json") //nolint:gosec // operator-selected engine path
		if err != nil || json.Unmarshal(data, &manifest) != nil || manifest.Revision != Revision {
			continue
		}
		binary := supervise.Binary{Kind: engine.Kind("olcrtc"), Path: path, Version: engine.Version{Raw: Revision}, Goos: runtime.GOOS, Goarch: runtime.GOARCH}
		if binary.VerifyDigest(manifest.SHA256) == nil {
			return binary, nil
		}
	}
	return supervise.Binary{}, errors.New("olcrtc: install the pinned binary and its checksum manifest in the engines directory")
}
