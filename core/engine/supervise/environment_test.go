package supervise

import (
	"context"
	"os"
	"regexp"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

const envFixtureMode = "environment-version"

var envFixtureKeys = []string{
	"SORA_TEST_SERVICE_SECRET", "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY",
	"http_proxy", "https_proxy", "all_proxy", "no_proxy",
}

func TestEngineCommandsUseFilteredEnvironment(t *testing.T) {
	for _, key := range envFixtureKeys {
		t.Setenv(key, "fixture-parent-value")
	}
	t.Setenv("LANG", "sora-env-fixture")
	binary, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(t.Context(), 10*time.Second)
	defer cancel()
	args := []string{fakeFlag, envFixtureMode}
	t.Run("probe", func(t *testing.T) {
		prober := Prober{Kind: engine.KindXray, Args: args, Pattern: regexp.MustCompile(`^fixture ([0-9]+\.[0-9]+\.[0-9]+)$`)}
		build, err := prober.Probe(ctx, binary)
		if err != nil || build.Version.String() != "9.8.7" {
			t.Fatalf("version command did not preserve the filtered environment: %v", err)
		}
	})
	t.Run("check", func(t *testing.T) {
		if err := Check(ctx, Spec{Name: "fixture", Path: binary, Args: args, Dir: t.TempDir()}); err != nil {
			t.Fatal(err)
		}
	})
	t.Run("start", func(t *testing.T) {
		child, err := Start(ctx, Spec{Name: "fixture", Path: binary, Args: args, Dir: t.TempDir()})
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { _ = child.Stop(context.Background(), 0) })
		if err := child.Wait(ctx); err != nil {
			t.Fatal(err)
		}
	})
}
