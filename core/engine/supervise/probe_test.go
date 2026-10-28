package supervise

import (
	"bytes"
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

const fixtureProbeLimit = 64 << 10

func TestProbeBoundsCombinedOutput(t *testing.T) {
	for _, mode := range []string{"probe-small", "probe-exact", "probe-stdout", "probe-stderr", "probe-combined"} {
		t.Run(mode, func(t *testing.T) {
			binary, err := os.Executable()
			if err != nil {
				t.Fatal(err)
			}
			pr := Prober{Kind: engine.KindXray, Args: []string{fakeFlag, mode}, Pattern: regexp.MustCompile(`^fixture ([0-9]+\.[0-9]+\.[0-9]+)$`)}
			build, err := pr.Probe(t.Context(), binary)
			if mode == "probe-small" || mode == "probe-exact" {
				if err != nil || build.Version.String() != "9.8.7" || !slices.Equal(build.BuildTags, []string{"alpha", "beta"}) {
					t.Fatalf("normal version/tags were changed: %v", err)
				}
			} else if err == nil || !strings.Contains(err.Error(), "version output exceeds") {
				t.Fatal("oversized combined version output was not rejected")
			}
		})
	}
}

func TestProbeBoundsInheritedOutputPipe(t *testing.T) {
	binary, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	t.Cleanup(func() {
		deadline := time.Now().Add(6 * time.Second)
		for time.Now().Before(deadline) {
			if _, err := os.Stat(filepath.Join(dir, "done")); err == nil {
				return
			}
			time.Sleep(20 * time.Millisecond)
		}
		t.Error("finite pipe-holder fixture did not close its output")
	})
	pr := Prober{Kind: engine.KindXray, Args: []string{fakeFlag, "probe-inherited", dir}, Pattern: regexp.MustCompile(`^fixture ([0-9]+\.[0-9]+\.[0-9]+)$`)}
	_, err = pr.Probe(t.Context(), binary)
	if !errors.Is(err, exec.ErrWaitDelay) {
		t.Fatalf("an inherited output pipe did not fail with the bounded-wait error: %v", err)
	}
	if _, err := os.Stat(filepath.Join(dir, "ready")); err != nil {
		t.Fatal("pipe-holder fixture did not start")
	}
}

func TestProbeCancellationStillStopsTheChild(t *testing.T) {
	binary, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	pr := Prober{Kind: engine.KindXray, Args: []string{fakeFlag, "probe-stall"}, Pattern: regexp.MustCompile(`^fixture ([0-9]+\.[0-9]+\.[0-9]+)$`)}
	ctx, cancel := context.WithTimeout(t.Context(), 200*time.Millisecond)
	defer cancel()
	started := time.Now()
	if _, err := pr.Probe(ctx, binary); err == nil || time.Since(started) > 3*time.Second {
		t.Fatal("version probing ignored cancellation")
	}
}

func fakeProbe(mode string) int {
	const version = "fixture 9.8.7\nTags:alpha,beta\n"
	switch mode {
	case "probe-inherited":
		cmd := exec.Command(os.Args[0], fakeFlag, "probe-holder", os.Args[3]) //nolint:gosec,noctx // finite self-process fixture with no network or external commands
		HideWindow(cmd)
		cmd.Env = SafeEnv()
		cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
		if err := cmd.Start(); err != nil {
			return 9
		}
		if err := cmd.Process.Release(); err != nil {
			return 9
		}
		_, _ = os.Stdout.WriteString(version)
		return 0
	case "probe-holder":
		if err := os.WriteFile(filepath.Join(os.Args[3], "ready"), nil, 0o600); err != nil {
			return 9
		}
		time.Sleep(3 * time.Second)
		_ = os.Stdout.Close()
		_ = os.Stderr.Close()
		if err := os.WriteFile(filepath.Join(os.Args[3], "done"), nil, 0o600); err != nil {
			return 9
		}
		return 0
	case "probe-stall":
		_, _ = os.Stdout.WriteString(version)
		time.Sleep(5 * time.Second)
		return 0
	}
	size := fixtureProbeLimit + 1
	switch mode {
	case "probe-small":
		size = len(version)
	case "probe-exact":
		size = fixtureProbeLimit
	}
	data := append([]byte(version), bytes.Repeat([]byte(" "), size-len(version))...)
	switch mode {
	case "probe-stderr":
		_, _ = os.Stderr.Write(data)
	case "probe-combined":
		_, _ = os.Stdout.Write(data[:len(data)/2])
		_, _ = os.Stderr.Write(data[len(data)/2:])
	default:
		_, _ = os.Stdout.Write(data)
	}
	return 0
}
