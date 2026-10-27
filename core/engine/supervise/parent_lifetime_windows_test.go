package supervise

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"testing"
	"time"
)

// These helpers use only private files and owned inert processes. No engine,
// listener, SCM operation, driver or network interface is opened.
func TestEngineJobChildHelper(t *testing.T) {
	if !slices.Contains(os.Args, "-test.run=^TestEngineJobChildHelper$") {
		return
	}
	raw, err := io.ReadAll(io.LimitReader(os.Stdin, 32<<10))
	if err != nil {
		t.Fatal(err)
	}
	if len(raw) == 0 {
		t.Fatal("missing private fixture directory")
	}
	exe, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	leaf := exec.CommandContext(t.Context(), exe, "-test.run=^TestEngineJobGrandchildHelper$")
	HideWindow(leaf)
	leaf.Env, leaf.Dir, leaf.Stdin, leaf.Stdout, leaf.Stderr = SafeEnv(), string(raw), bytes.NewReader(raw), io.Discard, io.Discard
	if err := leaf.Start(); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = leaf.Process.Kill(); _ = leaf.Wait() }()
	ready := filepath.Join(string(raw), "child.ready")
	// Existence signals readiness, so publish only a fully written, closed PID file.
	if err := os.WriteFile(ready+".pending", []byte(strconv.Itoa(os.Getpid())), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Rename(ready+".pending", ready); err != nil {
		t.Fatal(err)
	}
	// A finite limit also cleans up a failed reproduction if its caller dies.
	time.Sleep(15 * time.Second)
}
func TestEngineJobGrandchildHelper(t *testing.T) {
	if !slices.Contains(os.Args, "-test.run=^TestEngineJobGrandchildHelper$") {
		return
	}
	raw, err := io.ReadAll(io.LimitReader(os.Stdin, 32<<10))
	if err != nil || len(raw) == 0 {
		t.Fatal("missing private fixture directory")
	}
	ready := filepath.Join(string(raw), "grandchild.ready")
	if err := os.WriteFile(ready+".pending", []byte(strconv.Itoa(os.Getpid())), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Rename(ready+".pending", ready); err != nil {
		t.Fatal(err)
	}
	time.Sleep(15 * time.Second)
}

func TestEngineJobOwnerHelper(t *testing.T) {
	dir := os.Getenv("SORA_TEST_ENGINE_JOB_DIR")
	if dir == "" {
		return
	}
	exe, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	var pid int
	if os.Getenv("SORA_TEST_ENGINE_JOB_MODE") == "unmanaged" {
		cmd := exec.CommandContext(t.Context(), exe, "-test.run=^TestEngineJobChildHelper$")
		HideWindow(cmd)
		cmd.Dir, cmd.Env, cmd.Stdin, cmd.Stdout, cmd.Stderr = dir, SafeEnv(), bytes.NewReader([]byte(dir)), io.Discard, io.Discard
		if err := cmd.Start(); err != nil {
			t.Fatal(err)
		}
		defer func() { _ = cmd.Process.Kill(); _ = cmd.Wait() }()
		pid = cmd.Process.Pid
	} else {
		process, err := Start(t.Context(), Spec{Name: "inert lifetime fixture", Path: exe,
			Args: []string{"-test.run=^TestEngineJobChildHelper$"}, Dir: dir, Config: []byte(dir)})
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = process.Stop(context.Background(), 0) }()
		pid = process.PID()
	}
	if _, err := fmt.Fprintln(os.Stdout, pid); err != nil {
		t.Fatal(err)
	}
	_, _ = io.Copy(io.Discard, os.Stdin)
}
func TestWindowsRuntimeEngineDiesWithParent(t *testing.T) {
	for _, mode := range []string{"unmanaged", "managed"} {
		t.Run(mode, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(t.Context(), 20*time.Second)
			defer cancel()
			dir := t.TempDir()
			exe, err := os.Executable()
			if err != nil {
				t.Fatal(err)
			}
			owner := exec.CommandContext(ctx, exe, "-test.run=^TestEngineJobOwnerHelper$")
			HideWindow(owner)
			owner.Env = append(SafeEnv(), "SORA_TEST_ENGINE_JOB_DIR="+dir, "SORA_TEST_ENGINE_JOB_MODE="+mode)
			owner.WaitDelay = time.Second
			input, err := owner.StdinPipe()
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = input.Close() }()
			output, err := owner.StdoutPipe()
			if err != nil {
				t.Fatal(err)
			}
			owner.Stderr = os.Stderr
			if err := owner.Start(); err != nil {
				t.Fatal(err)
			}
			defer func() { _ = owner.Process.Kill(); _ = owner.Wait() }()
			line, err := bufio.NewReader(output).ReadString('\n')
			if err != nil {
				t.Fatal(err)
			}
			pid, err := strconv.Atoi(strings.TrimSpace(line))
			if err != nil {
				t.Fatalf("helper did not return its child PID: %q", line)
			}

			pids := map[string]int{"child": pid}
			deadline := time.Now().Add(10 * time.Second)
			for _, name := range []string{"child", "grandchild"} {
				for {
					raw, err := os.ReadFile(filepath.Join(dir, name+".ready"))
					if err == nil {
						readyPID, err := strconv.Atoi(string(raw))
						if err != nil {
							t.Fatal(err)
						}
						if name == "child" && readyPID != pid {
							t.Fatal("readiness belongs to another process")
						}
						pids[name] = readyPID
						break
					}
					if time.Now().After(deadline) {
						t.Fatalf("inert %s did not signal readiness", name)
					}
					time.Sleep(10 * time.Millisecond)
				}
			}
			exited := map[string]chan error{}
			for name, pid := range pids {
				child, err := os.FindProcess(pid)
				if err != nil {
					t.Fatal(err)
				}
				defer func() { _ = child.Kill() }()
				result := make(chan error, 1)
				exited[name] = result
				go func() { _, err := child.Wait(); result <- err }()
			}
			if err := owner.Process.Kill(); err != nil {
				t.Fatal(err)
			}
			for name, result := range exited {
				select {
				case err := <-result:
					if err != nil {
						t.Fatal(err)
					}
					if mode == "unmanaged" {
						t.Fatalf("positive control already killed the unmanaged %s", name)
					}
				case <-time.After(2 * time.Second):
					if mode == "managed" {
						t.Fatalf("supervised runtime %s survived its parent's forced termination", name)
					}
				}
			}

		})
	}
}
