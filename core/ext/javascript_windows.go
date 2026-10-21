package ext

import (
	"time"
	"unsafe"

	"golang.org/x/sys/windows"
)

func limitWorkerProcess() error {
	job, err := windows.CreateJobObject(nil, nil)
	if err != nil {
		return err
	}
	limits := windows.JOBOBJECT_EXTENDED_LIMIT_INFORMATION{}
	limits.BasicLimitInformation.LimitFlags = windows.JOB_OBJECT_LIMIT_PROCESS_MEMORY | windows.JOB_OBJECT_LIMIT_PROCESS_TIME | windows.JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
	limits.BasicLimitInformation.PerProcessUserTimeLimit = WorkerCPUSeconds * 10000000
	limits.ProcessMemoryLimit = workerOSMemoryBytes
	if _, err = windows.SetInformationJobObject(job, windows.JobObjectExtendedLimitInformation, uintptr(unsafe.Pointer(&limits)), uint32(unsafe.Sizeof(limits))); err != nil {
		_ = windows.CloseHandle(job)
		return err
	}
	// Keep the handle alive until process exit. Closing it kills the worker.
	if err = windows.AssignProcessToJobObject(job, windows.CurrentProcess()); err != nil {
		_ = windows.CloseHandle(job)
		return err
	}
	return nil
}

// processCPUTime is the user and kernel time this process has used.
func processCPUTime() (time.Duration, error) {
	var creation, exit, kernel, user windows.Filetime
	if err := windows.GetProcessTimes(windows.CurrentProcess(), &creation, &exit, &kernel, &user); err != nil {
		return 0, err
	}
	// FILETIME counts 100 ns intervals.
	ticks := func(f windows.Filetime) int64 { return int64(f.HighDateTime)<<32 | int64(f.LowDateTime) }
	return time.Duration((ticks(kernel) + ticks(user)) * 100), nil
}
