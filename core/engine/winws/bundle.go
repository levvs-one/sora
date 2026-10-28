package winws

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Unmodified classic Zapret v72.13 components. Extensions cannot supply paths,
// binaries or alternate digests.
var componentDigests = map[string]string{
	"winws.exe":       "a14bff1df6234ea555d2e0c61b589f0707c0b12d6c9b7eeccda76012154996e8",
	"WinDivert.dll":   "c1e060ee19444a259b2162f8af0f3fe8c4428a1c6f694dce20de194ac8d7d9a2",
	"WinDivert64.sys": "8da085332782708d8767bcace5327a6ec7283c17cfb85e40b03cd2323a90ddc2",
	"cygwin1.dll":     "103104a52e5293ce418944725df19e2bf81ad9269b9a120d71d39028e821499b",
}

// Discover inspects only the installed bundle and runtime, without starting a
// process or loading/changing a driver service.
func Discover(enginesDir string) string {
	if enginesDir == "" || compatibleHost() != nil {
		return ""
	}
	binary, err := filepath.Abs(filepath.Join(enginesDir, "winws", "winws.exe"))
	if err != nil || verifyComponents(filepath.Dir(binary)) != nil {
		return ""
	}
	return binary
}

func verifyComponents(dir string) error {
	for name, digest := range componentDigests {
		path := filepath.Join(dir, name)
		info, err := os.Lstat(path) //nolint:gosec // dir is host-owned; name comes only from the fixed pinned component set
		if err != nil {
			return fmt.Errorf("winws: component %s: %w", name, err)
		}
		if !info.Mode().IsRegular() {
			return fmt.Errorf("winws: component %s is not a regular file", name)
		}
		if err := (supervise.Binary{Path: path}).VerifyDigest(digest); err != nil {
			return fmt.Errorf("winws: component %s: %w", name, err)
		}
	}
	return nil
}
