//go:build linux || darwin

package ext

import (
	"time"

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
