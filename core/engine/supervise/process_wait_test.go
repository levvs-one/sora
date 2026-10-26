package supervise

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestEngineCommandsBoundInheritedOutput(t *testing.T) {
	binary, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	for _, command := range []string{"check", "start"} {
		t.Run(command, func(t *testing.T) {
			directory := t.TempDir()
			t.Cleanup(func() {
				deadline := time.Now().Add(6 * time.Second)
				for time.Now().Before(deadline) {
					if _, err := os.Stat(filepath.Join(directory, "done")); err == nil {
						return
					}
					time.Sleep(20 * time.Millisecond)
				}
				t.Error("finite pipe-holder fixture did not finish")
			})
			spec := Spec{Name: "fixture", Path: binary, Dir: directory, Args: []string{fakeFlag, "probe-inherited", directory}}
			if command == "check" {
				err = Check(t.Context(), spec)
			} else {
				var child *Process
				child, err = Start(t.Context(), spec)
				if err != nil {
					t.Fatal(err)
				}
				t.Cleanup(func() { _ = child.Stop(context.Background(), 0) })
				err = child.Wait(t.Context())
				if !child.Exited() || !errors.Is(child.Err(), exec.ErrWaitDelay) {
					t.Errorf("exited child was not classified after inherited-pipe timeout: %v", child.Err())
				}
			}
			if !errors.Is(err, exec.ErrWaitDelay) || !strings.Contains(err.Error(), "fixture 9.8.7") {
				t.Fatalf("inherited output was not bounded while preserving diagnostics: %v", err)
			}
			if _, err := os.Stat(filepath.Join(directory, "ready")); err != nil {
				t.Fatal("pipe-holder fixture did not start")
			}
		})
	}
}
