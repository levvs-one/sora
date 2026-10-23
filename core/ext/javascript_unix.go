//go:build linux || darwin

package ext

import (
	"errors"
	"os"
	"os/exec"
	"syscall"
	"time"

	"github.com/shirou/gopsutil/v4/process"
	"golang.org/x/sys/unix"
)

func limitWorkerProcess() error {
	// RLIMIT_AS conflicts with Go's virtual heap reservation. RLIMIT_DATA
	// limits committed heap mappings on Linux, where desktop workers run.
	if err := unix.Setrlimit(unix.RLIMIT_DATA, &unix.Rlimit{Cur: workerOSMemoryBytes, Max: workerOSMemoryBytes}); err != nil {
		return err
	}
	return unix.Setrlimit(unix.RLIMIT_CPU, &unix.Rlimit{Cur: WorkerCPUSeconds, Max: WorkerCPUSeconds})
}

// processCPUTime is the user and system time this process has used.
func processCPUTime() (time.Duration, error) {
	var usage unix.Rusage
	if err := unix.Getrusage(unix.RUSAGE_SELF, &usage); err != nil {
		return 0, err
	}
	return time.Duration(usage.Utime.Nano() + usage.Stime.Nano()), nil
}

func startWorkerCommand(cmd *exec.Cmd) (*workerProcess, error) {
	if err := cmd.Start(); err != nil {
		return nil, err
	}
	p := &process.Process{Pid: int32(cmd.Process.Pid)} //nolint:gosec // Unix pid_t is signed 32-bit on Linux and Darwin.
	return &workerProcess{
		process: cmd.Process,
		wait: func() (*os.ProcessState, error) {
			err := cmd.Wait()
			if state := cmd.ProcessState; state != nil {
				if status, ok := state.Sys().(syscall.WaitStatus); ok && status.Signaled() {
					// RLIMIT_CPU accounting is tick-based and can fire just before the
					// user + system times returned by wait reach the nominal limit.
					if status.Signal() == unix.SIGXCPU || (status.Signal() == unix.SIGKILL && state.UserTime()+state.SystemTime() >= WorkerCPUSeconds*time.Second-100*time.Millisecond) {
						err = errWorkerCPUBudget
					}
				}
			}
			return cmd.ProcessState, err
		},
		usage: func() (workerUsage, error) {
			bytes, err := workerMemory(p)
			if errors.Is(err, os.ErrNotExist) || errors.Is(err, unix.ESRCH) {
				return workerUsage{}, nil
			}
			if err != nil {
				return workerUsage{}, err
			}
			cpu, err := p.Times()
			if err != nil {
				return workerUsage{}, err
			}
			return workerUsage{memory: bytes, cpu: time.Duration((cpu.User + cpu.System) * float64(time.Second))}, nil
		},
		close: func() { _ = cmd.Process.Release() },
	}, nil
}
