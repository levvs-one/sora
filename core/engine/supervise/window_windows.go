//go:build windows

package supervise

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"sync"
	"syscall"
	"unsafe"

	"golang.org/x/sys/windows"
)

// HideWindow suppresses the engine console window using the documented field
// for Windows 7 compatibility.
func HideWindow(cmd *exec.Cmd) {
	if cmd.SysProcAttr == nil {
		cmd.SysProcAttr = &syscall.SysProcAttr{}
	}
	cmd.SysProcAttr.HideWindow = true
}

// interrupt cannot signal a hidden Windows console; shutdown kills it after the
// grace period.
func interrupt(*os.Process) error { return errors.ErrUnsupported }

// One non-inheritable job handle belongs to the core process, not one session.
// Associating the parent before CreateProcess avoids the start/assign crash
// window. Children inherit membership, but never the handle keeping them alive.
var engineJob struct {
	once sync.Once
	err  error
}

func startRuntimeProcess(cmd *exec.Cmd) error {
	engineJob.once.Do(func() {
		job, err := windows.CreateJobObject(nil, nil)
		if err != nil {
			engineJob.err = err
			return
		}
		limits := windows.JOBOBJECT_EXTENDED_LIMIT_INFORMATION{}
		limits.BasicLimitInformation.LimitFlags = windows.JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
		if _, err = windows.SetInformationJobObject(job, windows.JobObjectExtendedLimitInformation,
			uintptr(unsafe.Pointer(&limits)), uint32(unsafe.Sizeof(limits))); err == nil {
			err = windows.AssignProcessToJobObject(job, windows.CurrentProcess())
		}
		if err != nil {
			_ = windows.CloseHandle(job)
			engineJob.err = err
		}
		// On success, deliberately retain this anonymous, non-inheritable handle
		// until process exit. Closing it here would terminate the core itself.
	})
	if engineJob.err != nil {
		return fmt.Errorf("contain runtime engine process: %w", engineJob.err)
	}
	return cmd.Start()
}
