//go:build linux || darwin

package ext

import "golang.org/x/sys/unix"

func limitWorkerProcess() error {
	// RLIMIT_AS conflicts with Go's virtual heap reservation. RLIMIT_DATA
	// limits committed heap mappings on Linux, where desktop workers run.
	if err := unix.Setrlimit(unix.RLIMIT_DATA, &unix.Rlimit{Cur: WorkerMemoryBytes, Max: WorkerMemoryBytes}); err != nil {
		return err
	}
	return unix.Setrlimit(unix.RLIMIT_CPU, &unix.Rlimit{Cur: WorkerCPUSeconds, Max: WorkerCPUSeconds})
}
