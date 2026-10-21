package ext

import (
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
	limits.ProcessMemoryLimit = WorkerMemoryBytes
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
