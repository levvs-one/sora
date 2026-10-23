package ext

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"
)

func TestWorkerJobOwnerHelper(t *testing.T) {
	binary := os.Getenv("SORA_TEST_JOB_WORKER")
	if binary == "" {
		return
	}
	cmd := exec.CommandContext(t.Context(), binary, "memory")
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stderr, os.Stderr
	worker, err := startWorkerCommand(cmd)
	if err != nil {
		t.Fatal(err)
	}
	defer worker.close()
	defer func() { _ = worker.process.Kill() }()
	// The child is blocked waiting for source, with no CPU use or watchdog.
	if _, err = fmt.Fprintln(os.Stdout, worker.process.Pid); err != nil {
		t.Fatal(err)
	}
	_, _ = io.Copy(io.Discard, os.Stdin)
	_, _ = worker.wait()
}

func TestWorkerDiesWithJobOwner(t *testing.T) {
	binary := filepath.Join(t.TempDir(), "budget-worker.exe")
	build := exec.CommandContext(t.Context(), "go", "build", "-o", binary, "./testdata/budget-worker")
	if output, err := build.CombinedOutput(); err != nil {
		t.Fatalf("build blocked child: %v\n%s", err, output)
	}
	executable, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	owner := exec.CommandContext(t.Context(), executable, "-test.run=^TestWorkerJobOwnerHelper$")
	owner.Env = append(os.Environ(), "SORA_TEST_JOB_WORKER="+binary)
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
	if err = owner.Start(); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = owner.Process.Kill(); _ = owner.Wait() }()
	line, err := bufio.NewReader(output).ReadString('\n')
	if err != nil {
		t.Fatal(err)
	}
	pid, err := strconv.Atoi(strings.TrimSpace(line))
	if err != nil {
		t.Fatal(err)
	}
	child, err := os.FindProcess(pid)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = child.Release() }()
	defer func() { _ = child.Kill() }()
	if err = owner.Process.Kill(); err != nil {
		t.Fatal(err)
	}
	exited := make(chan error, 1)
	go func() { _, err := child.Wait(); exited <- err }()
	select {
	case err := <-exited:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("worker survived core crash while blocked with no CPU use")
	}
}
