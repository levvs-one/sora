package main

import (
	"os"
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
)

func TestStopServiceFlagRejectsCombinations(t *testing.T) {
	dir := t.TempDir()
	for _, args := range [][]string{
		{"-stop-service=false"},
		{"-stop-service", "extra"},
		{"-stop-service", "-version"},
		{"-stop-service", "-install-service"},
		{"-stop-service", "-uninstall-service"},
		{"-stop-service", "-print-token"},
		{"-stop-service", "-data-dir", dir},
		{"-stop-service", "-verify-release", dir, "-release-version", "1.2.3"},
		{"-stop-service", "-prepare-update", "deb", "-release-version", "1.2.3", dir, dir},
	} {
		if err := run(t.Context(), args); errs.CodeOf(err) != errs.CodeInvalidArgument {
			t.Fatalf("%v did not stop before dispatch: %v", args, err)
		}
	}
	entries, err := os.ReadDir(dir)
	if err != nil || len(entries) != 0 {
		t.Fatalf("invalid stopping command created data: %v", err)
	}
}

func TestStopServiceIsNotAvailableOnOtherPlatforms(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("the positive CLI command must not operate on a developer's SCM")
	}
	if err := run(t.Context(), []string{"-stop-service"}); err == nil || errs.CodeOf(err) == errs.CodeInvalidArgument {
		t.Fatalf("stopping command did not reach its platform boundary: %v", err)
	}
}
